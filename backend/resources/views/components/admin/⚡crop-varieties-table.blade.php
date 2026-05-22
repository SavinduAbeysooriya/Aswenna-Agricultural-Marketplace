<?php

use App\Models\Crop;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;
use Livewire\Component;
use Livewire\Features\SupportFileUploads\WithFileUploads;
use Livewire\WithPagination;

new class extends Component
{
    use WithFileUploads;
    use WithPagination;

    public string $search = '';
    public string $status = 'all';
    public int $perPage = 10;
    public string $pageInput = '1';
    public bool $showCreateModal = false;
    public ?int $editingCropId = null;
    public string $cropname = '';
    public string $editCropname = '';
    public string $editStatus = 'pending';
    public $cropImage;
    public $editCropImage;

    protected array $queryString = [
        'search' => ['except' => ''],
        'status' => ['except' => 'all'],
        'perPage' => ['except' => 10, 'as' => 'per_page'],
        'page' => ['except' => 1],
    ];

    public function rules(): array
    {
        return [
            'cropname' => ['required', 'string', 'max:255'],
            'cropImage' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:4096'],
            'editCropname' => ['required', 'string', 'max:255'],
            'editCropImage' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:4096'],
            'editStatus' => ['required', Rule::in(Crop::STATUSES)],
        ];
    }

    public function updatedSearch(): void
    {
        $this->resetPage();
        $this->pageInput = '1';
    }

    public function updatedStatus(): void
    {
        $this->resetPage();
        $this->pageInput = '1';
    }

    public function updatedPerPage(): void
    {
        $this->perPage = in_array((int) $this->perPage, [10, 25, 50, 100], true) ? (int) $this->perPage : 10;
        $this->resetPage();
        $this->pageInput = '1';
    }

    public function updatedPage($page): void
    {
        $this->pageInput = (string) $page;
    }

    public function openCreateModal(): void
    {
        $this->resetValidation();
        $this->reset(['cropname', 'cropImage']);
        $this->showCreateModal = true;
    }

    public function closeCreateModal(): void
    {
        $this->showCreateModal = false;
        $this->resetValidation();
        $this->reset(['cropname', 'cropImage']);
    }

    public function createCrop(): void
    {
        $this->validateOnly('cropname');
        $this->validateOnly('cropImage');

        Crop::create([
            'cropname' => $this->cropname,
            'image_path' => 'storage/' . $this->cropImage->store('crop-varieties', 'public'),
            'status' => 'approved',
            'added_by' => session('admin_session.user_id') ?? Auth::id(),
        ]);

        $this->closeCreateModal();
        $this->resetPage();
        $this->pageInput = '1';
        $this->dispatch('crop-saved', message: 'Crop variety added and approved.');
    }

    public function openEditModal(int $cropId): void
    {
        $crop = Crop::findOrFail($cropId);

        $this->resetValidation();
        $this->editingCropId = $crop->id;
        $this->editCropname = $crop->cropname;
        $this->editStatus = $crop->status;
        $this->editCropImage = null;
    }

    public function closeEditModal(): void
    {
        $this->editingCropId = null;
        $this->resetValidation();
        $this->reset(['editCropname', 'editStatus', 'editCropImage']);
        $this->editStatus = 'pending';
    }

    public function updateCrop(): void
    {
        $this->validateOnly('editCropname');
        $this->validateOnly('editStatus');

        if ($this->editCropImage) {
            $this->validateOnly('editCropImage');
        }

        $crop = Crop::findOrFail($this->editingCropId);
        $data = [
            'cropname' => $this->editCropname,
            'status' => $this->editStatus,
        ];

        if ($this->editCropImage) {
            $this->deleteStoredCropImage($crop->image_path);
            $data['image_path'] = 'storage/' . $this->editCropImage->store('crop-varieties', 'public');
        }

        $crop->update($data);

        $this->closeEditModal();
        $this->dispatch('crop-saved', message: 'Crop variety updated.');
    }

    public function setCropStatus(int $cropId, string $status): void
    {
        if (!in_array($status, Crop::STATUSES, true)) {
            return;
        }

        Crop::findOrFail($cropId)->update(['status' => $status]);
        $this->dispatch('crop-saved', message: 'Crop marked as ' . ucfirst($status) . '.');
    }

    public function deleteCrop(int $cropId): void
    {
        $crop = Crop::findOrFail($cropId);
        $this->deleteStoredCropImage($crop->image_path);
        $crop->delete();

        $this->dispatch('crop-saved', message: 'Crop variety removed.');
    }

    public function goToTypedPage(): void
    {
        $lastPage = max(1, (int) ceil($this->filteredQuery()->count() / $this->perPage));
        $page = min(max((int) $this->pageInput, 1), $lastPage);
        $this->pageInput = (string) $page;
        $this->setPage($page);
    }

    private function filteredQuery()
    {
        $search = trim($this->search);

        return Crop::query()
            ->with('addedBy:id,full_name,email,role')
            ->when($search !== '', function ($query) use ($search) {
                $query->where(function ($subQuery) use ($search) {
                    $subQuery->where('cropname', 'like', '%' . $search . '%')
                        ->orWhereHas('addedBy', function ($userQuery) use ($search) {
                            $userQuery->where('full_name', 'like', '%' . $search . '%')
                                ->orWhere('email', 'like', '%' . $search . '%')
                                ->orWhere('role', 'like', '%' . $search . '%');
                        });
                });
            })
            ->when($this->status !== 'all', fn ($query) => $query->where('status', $this->status))
            ->orderByRaw("CASE status WHEN 'pending' THEN 1 WHEN 'approved' THEN 2 ELSE 3 END")
            ->latest();
    }

    private function statusCounts()
    {
        return Crop::selectRaw('status, COUNT(*) as total')
            ->groupBy('status')
            ->pluck('total', 'status');
    }

    private function paginationItems(int $currentPage, int $lastPage): array
    {
        if ($lastPage <= 12) {
            return range(1, $lastPage);
        }

        $pages = array_unique(array_merge(
            range(1, min(2, $lastPage)),
            range(max(1, $currentPage - 2), min($lastPage, $currentPage + 2)),
            range(max(1, $lastPage - 4), $lastPage)
        ));

        sort($pages);

        $items = [];
        $previous = null;
        foreach ($pages as $page) {
            if ($previous !== null && $page > $previous + 1) {
                $items[] = '...';
            }
            $items[] = $page;
            $previous = $page;
        }

        return $items;
    }

    private function deleteStoredCropImage(?string $imagePath): void
    {
        if (!$imagePath || !str_starts_with($imagePath, 'storage/crop-varieties/')) {
            return;
        }

        Storage::disk('public')->delete(str_replace('storage/', '', $imagePath));
    }

    public function render()
    {
        $crops = $this->filteredQuery()->paginate($this->perPage);
        $statusCounts = $this->statusCounts();

        return $this->view([
            'crops' => $crops,
            'statusCounts' => $statusCounts,
            'totalCropCount' => Crop::count(),
            'pendingCropCount' => (int) ($statusCounts['pending'] ?? 0),
            'paginationItems' => $this->paginationItems($crops->currentPage(), $crops->lastPage()),
        ]);
    }
};
?>

<div class="space-y-6">
    <section class="flex flex-col xl:flex-row xl:items-end xl:justify-between gap-4">
        <div>
            <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-50 border border-emerald-100 text-emerald-700 text-[11px] font-extrabold uppercase tracking-widest">
                <i class="fa-solid fa-seedling"></i>
                Live crop approvals
            </div>
            <h1 class="mt-3 text-2xl sm:text-3xl font-black tracking-tight text-slate-900 font-poppins">Crop Varieties</h1>
            <p class="mt-1 text-sm text-slate-500 font-medium max-w-2xl">Search, filter, approve, reject, upload images, and paginate without refreshing the admin page.</p>
        </div>
        <div class="flex flex-col sm:flex-row gap-3">
            <button type="button" wire:click="openCreateModal" class="inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-extrabold shadow-md shadow-emerald-500/20 transition">
                <i class="fa-solid fa-plus"></i>
                Add Crop
            </button>
            <a href="{{ route('admin.dashboard') }}" class="inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-white border border-slate-200 text-slate-600 hover:text-emerald-700 hover:border-emerald-200 text-xs font-bold shadow-sm transition">
                <i class="fa-solid fa-arrow-left"></i>
                Dashboard
            </a>
        </div>
    </section>

    <section class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        <div class="bg-white border border-slate-100 rounded-2xl p-5 shadow-sm">
            <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest">All Crops</span>
            <strong class="mt-2 block text-3xl font-black text-slate-900">{{ $totalCropCount }}</strong>
        </div>
        <div class="bg-white border border-amber-100 rounded-2xl p-5 shadow-sm">
            <span class="text-[10px] font-extrabold text-amber-500 uppercase tracking-widest">Pending</span>
            <strong class="mt-2 block text-3xl font-black text-slate-900">{{ $statusCounts['pending'] ?? 0 }}</strong>
        </div>
        <div class="bg-white border border-emerald-100 rounded-2xl p-5 shadow-sm">
            <span class="text-[10px] font-extrabold text-emerald-600 uppercase tracking-widest">Approved</span>
            <strong class="mt-2 block text-3xl font-black text-slate-900">{{ $statusCounts['approved'] ?? 0 }}</strong>
        </div>
        <div class="bg-white border border-rose-100 rounded-2xl p-5 shadow-sm">
            <span class="text-[10px] font-extrabold text-rose-500 uppercase tracking-widest">Rejected</span>
            <strong class="mt-2 block text-3xl font-black text-slate-900">{{ $statusCounts['rejected'] ?? 0 }}</strong>
        </div>
    </section>

    <section class="bg-white border border-slate-100 rounded-2xl shadow-sm overflow-hidden">
        <div class="p-5 sm:p-6 border-b border-slate-100 space-y-4">
            <div class="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
                <div>
                    <h2 class="text-base font-extrabold text-slate-900">All Crops</h2>
                    <p class="text-xs text-slate-500 font-medium">All controls are Livewire powered, so only this panel updates.</p>
                </div>
                <div wire:loading class="text-xs font-extrabold text-emerald-700 bg-emerald-50 border border-emerald-100 rounded-full px-3 py-1">
                    Syncing...
                </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-[minmax(0,1fr)_180px_150px] gap-3">
                <div class="relative">
                    <i class="fa-solid fa-magnifying-glass absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 text-sm"></i>
                    <input wire:model.live.debounce.350ms="search" class="w-full rounded-xl border border-slate-200 bg-slate-50 pl-10 pr-4 py-3 text-sm font-semibold outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition" placeholder="Search crop, added by, role, email">
                </div>
                <select wire:model.live="status" class="rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-bold text-slate-700 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition">
                    <option value="all">All statuses</option>
                    @foreach (\App\Models\Crop::STATUSES as $cropStatus)
                        <option value="{{ $cropStatus }}">{{ ucfirst($cropStatus) }}</option>
                    @endforeach
                </select>
                <select wire:model.live="perPage" class="rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-bold text-slate-700 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition">
                    @foreach ([10, 25, 50, 100] as $size)
                        <option value="{{ $size }}">{{ $size }} / page</option>
                    @endforeach
                </select>
            </div>
        </div>

        <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-slate-100">
                <thead class="bg-slate-50">
                    <tr>
                        <th class="px-5 py-3 text-left text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Crop</th>
                        <th class="px-5 py-3 text-left text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Status</th>
                        <th class="px-5 py-3 text-left text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Added By</th>
                        <th class="px-5 py-3 text-right text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100 bg-white">
                    @forelse ($crops as $crop)
                        @php
                            $addedRoles = $crop->addedBy?->role;
                            if (is_string($addedRoles)) {
                                $decodedRoles = json_decode($addedRoles, true);
                                $addedRoles = is_array($decodedRoles) ? $decodedRoles : [$addedRoles];
                            }
                            $addedRoleLabel = is_array($addedRoles) && count($addedRoles) ? collect($addedRoles)->map(fn ($role) => ucwords(str_replace('_', ' ', $role)))->join(', ') : 'Admin';
                            $statusClass = [
                                'pending' => 'bg-amber-50 text-amber-700 border-amber-100',
                                'approved' => 'bg-emerald-50 text-emerald-700 border-emerald-100',
                                'rejected' => 'bg-rose-50 text-rose-700 border-rose-100',
                            ][$crop->status] ?? 'bg-slate-50 text-slate-600 border-slate-100';
                        @endphp
                        <tr class="align-middle hover:bg-slate-50/70 transition" wire:key="crop-row-{{ $crop->id }}">
                            <td class="px-5 py-4 min-w-[320px]">
                                <div class="flex items-center gap-4">
                                    <div class="w-16 h-16 rounded-xl bg-emerald-50 border border-emerald-100 flex items-center justify-center text-emerald-600 overflow-hidden shrink-0">
                                        @if ($crop->image_path)
                                            <img src="{{ \Illuminate\Support\Str::startsWith($crop->image_path, ['http://', 'https://']) ? $crop->image_path : asset($crop->image_path) }}" alt="{{ $crop->cropname }}" class="w-full h-full object-cover">
                                        @else
                                            <i class="fa-solid fa-leaf"></i>
                                        @endif
                                    </div>
                                    <div class="min-w-0">
                                        <p class="text-sm font-extrabold text-slate-900">{{ $crop->cropname }}</p>
                                        <p class="text-[11px] text-slate-400 font-bold mt-1">#CR{{ str_pad($crop->id, 4, '0', STR_PAD_LEFT) }}</p>
                                    </div>
                                </div>
                            </td>
                            <td class="px-5 py-4 min-w-[150px]">
                                <span class="inline-flex items-center rounded-full border px-3 py-1 text-[10px] font-extrabold uppercase tracking-wider {{ $statusClass }}">{{ $crop->status }}</span>
                                <p class="text-[11px] text-slate-400 font-semibold mt-2">{{ $crop->updated_at->diffForHumans() }}</p>
                            </td>
                            <td class="px-5 py-4 min-w-[240px]">
                                <p class="text-sm font-extrabold text-slate-800">{{ $crop->addedBy->full_name ?? 'System Admin' }}</p>
                                <p class="text-[11px] text-emerald-700 font-extrabold mt-1">{{ $addedRoleLabel }}</p>
                                <p class="text-[11px] text-slate-500 font-semibold mt-1">{{ $crop->addedBy->email ?? 'No email available' }}</p>
                                <p class="text-[11px] text-slate-400 font-medium mt-1">{{ $crop->created_at->format('M d, Y h:i A') }}</p>
                            </td>
                            <td class="px-5 py-4 min-w-[300px]">
                                <div class="flex flex-wrap justify-end gap-2">
                                    @if ($crop->status !== 'approved')
                                        <button type="button" wire:click="setCropStatus({{ $crop->id }}, 'approved')" wire:confirm="Approve this crop?" class="inline-flex items-center gap-1.5 rounded-lg bg-emerald-50 text-emerald-700 hover:bg-emerald-100 px-3 py-2 text-[11px] font-extrabold transition">
                                            <i class="fa-solid fa-check"></i>
                                            Approved
                                        </button>
                                    @endif
                                    @if ($crop->status !== 'rejected')
                                        <button type="button" wire:click="setCropStatus({{ $crop->id }}, 'rejected')" wire:confirm="Reject this crop?" class="inline-flex items-center gap-1.5 rounded-lg bg-rose-50 text-rose-700 hover:bg-rose-100 px-3 py-2 text-[11px] font-extrabold transition">
                                            <i class="fa-solid fa-xmark"></i>
                                            Rejected
                                        </button>
                                    @endif
                                    <button type="button" wire:click="openEditModal({{ $crop->id }})" class="inline-flex items-center gap-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 px-3 py-2 text-[11px] font-extrabold transition">
                                        <i class="fa-solid fa-pen"></i>
                                        Edit
                                    </button>
                                    <button type="button" wire:click="$dispatch('confirm-crop-delete', { cropId: {{ $crop->id }}, cropName: @js($crop->cropname) })" class="inline-flex items-center gap-1.5 rounded-lg bg-slate-50 hover:bg-rose-50 text-slate-500 hover:text-rose-700 px-3 py-2 text-[11px] font-extrabold transition border border-slate-100 hover:border-rose-100">
                                        <i class="fa-solid fa-trash"></i>
                                        Remove
                                    </button>
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="4" class="px-5 py-12 text-center">
                                <div class="mx-auto w-14 h-14 rounded-2xl bg-slate-100 text-slate-400 flex items-center justify-center">
                                    <i class="fa-solid fa-magnifying-glass"></i>
                                </div>
                                <p class="mt-4 text-sm font-extrabold text-slate-700">No crops found</p>
                                <p class="mt-1 text-xs text-slate-500 font-medium">Adjust the live filters or add a new crop variety.</p>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <div class="p-5 sm:p-6 border-t border-slate-100 flex flex-col xl:flex-row xl:items-center xl:justify-between gap-4">
            <p class="text-xs text-slate-500 font-semibold">
                Showing <span class="font-extrabold text-slate-800">{{ $crops->firstItem() ?? 0 }}</span> to <span class="font-extrabold text-slate-800">{{ $crops->lastItem() ?? 0 }}</span> of <span class="font-extrabold text-slate-800">{{ $crops->total() }}</span> crops
            </p>

            <div class="flex flex-col sm:flex-row sm:items-center gap-3">
                <form wire:submit="goToTypedPage" class="flex items-center gap-2">
                    <label class="text-xs font-bold text-slate-500">Go to</label>
                    <input wire:model="pageInput" type="number" min="1" max="{{ $crops->lastPage() }}" class="w-20 rounded-lg border border-slate-200 px-3 py-2 text-xs font-extrabold text-slate-700 outline-none focus:border-emerald-400 focus:ring-4 focus:ring-emerald-100">
                    <button class="rounded-lg bg-slate-900 hover:bg-emerald-700 text-white px-3 py-2 text-xs font-extrabold transition">Go</button>
                </form>

                @if ($crops->hasPages())
                    <div class="flex flex-wrap items-center gap-2">
                        <button type="button" wire:click="setPage(1)" @disabled($crops->onFirstPage()) class="px-3 py-2 rounded-lg border border-slate-200 text-xs font-bold disabled:pointer-events-none disabled:opacity-40 hover:border-emerald-200 hover:text-emerald-700">First</button>
                        <button type="button" wire:click="previousPage" @disabled($crops->onFirstPage()) class="px-3 py-2 rounded-lg border border-slate-200 text-xs font-bold disabled:pointer-events-none disabled:opacity-40 hover:border-emerald-200 hover:text-emerald-700">Prev</button>
                        @foreach ($paginationItems as $item)
                            @if ($item === '...')
                                <span class="px-2 py-2 text-xs font-black text-slate-300">...</span>
                            @else
                                <button type="button" wire:click="setPage({{ $item }})" class="min-w-9 text-center px-3 py-2 rounded-lg border text-xs font-extrabold {{ $item === $crops->currentPage() ? 'bg-emerald-600 border-emerald-600 text-white' : 'border-slate-200 text-slate-600 hover:border-emerald-200 hover:text-emerald-700' }}">{{ $item }}</button>
                            @endif
                        @endforeach
                        <button type="button" wire:click="nextPage" @disabled(!$crops->hasMorePages()) class="px-3 py-2 rounded-lg border border-slate-200 text-xs font-bold disabled:pointer-events-none disabled:opacity-40 hover:border-emerald-200 hover:text-emerald-700">Next</button>
                        <button type="button" wire:click="setPage({{ $crops->lastPage() }})" @disabled($crops->currentPage() === $crops->lastPage()) class="px-3 py-2 rounded-lg border border-slate-200 text-xs font-bold disabled:pointer-events-none disabled:opacity-40 hover:border-emerald-200 hover:text-emerald-700">Last</button>
                    </div>
                @endif
            </div>
        </div>
    </section>

    @if ($showCreateModal)
        <div class="fixed left-0 top-0 z-[9999] flex h-screen w-screen items-center justify-center p-4" style="inset: 0; width: 100vw; height: 100vh;" aria-modal="true">
            <button type="button" wire:click="closeCreateModal" class="absolute inset-0 h-full w-full bg-slate-950/60 backdrop-blur-sm"></button>
            <div class="relative w-full max-w-lg bg-white rounded-2xl shadow-2xl border border-slate-100 overflow-hidden">
                <div class="p-5 border-b border-slate-100 flex items-start justify-between gap-4">
                    <div>
                        <h2 class="text-lg font-extrabold text-slate-900">Add Crop Variety</h2>
                        <p class="text-xs text-slate-500 font-semibold mt-1">Admin-created crops are saved as approved.</p>
                    </div>
                    <button type="button" wire:click="closeCreateModal" class="w-9 h-9 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-500 transition">
                        <i class="fa-solid fa-xmark"></i>
                    </button>
                </div>
                <form wire:submit="createCrop" class="p-5 space-y-4">
                    <div>
                        <label class="block text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-2">Crop variety name</label>
                        <input wire:model="cropname" required maxlength="255" class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-semibold text-slate-800 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition" placeholder="Example: Keeri Samba Rice">
                        @error('cropname') <p class="mt-2 text-xs font-bold text-rose-600">{{ $message }}</p> @enderror
                    </div>
                    <div>
                        <label class="block text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-2">Upload crop image</label>
                        <input wire:model="cropImage" type="file" required accept="image/png,image/jpeg,image/webp" class="w-full rounded-xl border border-dashed border-emerald-200 bg-emerald-50/50 px-4 py-3 text-sm font-semibold text-slate-700 file:mr-4 file:rounded-lg file:border-0 file:bg-emerald-600 file:px-3 file:py-2 file:text-xs file:font-extrabold file:text-white hover:file:bg-emerald-700 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition">
                        <p class="mt-2 text-[11px] font-semibold text-slate-400">JPG, PNG, or WebP up to 4 MB.</p>
                        @error('cropImage') <p class="mt-2 text-xs font-bold text-rose-600">{{ $message }}</p> @enderror
                    </div>
                    <button type="submit" wire:loading.attr="disabled" class="w-full inline-flex items-center justify-center gap-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 disabled:opacity-60 text-white px-4 py-3 text-sm font-extrabold shadow-md shadow-emerald-500/20 transition">
                        <i class="fa-solid fa-floppy-disk"></i>
                        Save Crop
                    </button>
                </form>
            </div>
        </div>
    @endif

    @if ($editingCropId)
        <div class="fixed left-0 top-0 z-[9999] flex h-screen w-screen items-center justify-center p-4" style="inset: 0; width: 100vw; height: 100vh;" aria-modal="true">
            <button type="button" wire:click="closeEditModal" class="absolute inset-0 h-full w-full bg-slate-950/60 backdrop-blur-sm"></button>
            <div class="relative w-full max-w-lg bg-white rounded-2xl shadow-2xl border border-slate-100 overflow-hidden">
                <div class="p-5 border-b border-slate-100 flex items-start justify-between gap-4">
                    <div>
                        <h2 class="text-lg font-extrabold text-slate-900">Edit Crop Variety</h2>
                        <p class="text-xs text-slate-500 font-semibold mt-1">Updates happen through Livewire without a page refresh.</p>
                    </div>
                    <button type="button" wire:click="closeEditModal" class="w-9 h-9 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-500 transition">
                        <i class="fa-solid fa-xmark"></i>
                    </button>
                </div>
                <form wire:submit="updateCrop" class="p-5 space-y-4">
                    <div>
                        <label class="block text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-2">Crop variety name</label>
                        <input wire:model="editCropname" required maxlength="255" class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-semibold text-slate-800 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition">
                        @error('editCropname') <p class="mt-2 text-xs font-bold text-rose-600">{{ $message }}</p> @enderror
                    </div>
                    <div>
                        <label class="block text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-2">Replace image</label>
                        <input wire:model="editCropImage" type="file" accept="image/png,image/jpeg,image/webp" class="w-full rounded-xl border border-dashed border-slate-200 bg-slate-50 px-4 py-3 text-sm font-semibold text-slate-700 file:mr-4 file:rounded-lg file:border-0 file:bg-slate-900 file:px-3 file:py-2 file:text-xs file:font-extrabold file:text-white hover:file:bg-emerald-700 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition">
                        <p class="mt-2 text-[11px] font-semibold text-slate-400">Leave empty to keep the current image.</p>
                        @error('editCropImage') <p class="mt-2 text-xs font-bold text-rose-600">{{ $message }}</p> @enderror
                    </div>
                    <div>
                        <label class="block text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-2">Approval status</label>
                        <select wire:model="editStatus" class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-bold text-slate-700 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition">
                            @foreach (\App\Models\Crop::STATUSES as $cropStatus)
                                <option value="{{ $cropStatus }}">{{ ucfirst($cropStatus) }}</option>
                            @endforeach
                        </select>
                        @error('editStatus') <p class="mt-2 text-xs font-bold text-rose-600">{{ $message }}</p> @enderror
                    </div>
                    <button type="submit" wire:loading.attr="disabled" class="w-full inline-flex items-center justify-center gap-2 rounded-xl bg-slate-900 hover:bg-emerald-700 disabled:opacity-60 text-white px-4 py-3 text-sm font-extrabold transition">
                        <i class="fa-solid fa-floppy-disk"></i>
                        Update Crop
                    </button>
                </form>
            </div>
        </div>
    @endif
</div>
