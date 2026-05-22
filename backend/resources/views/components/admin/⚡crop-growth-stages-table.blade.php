<?php

use App\Models\CropGrowthStage;
use Illuminate\Validation\Rule;
use Livewire\Component;
use Livewire\WithPagination;

new class extends Component
{
    use WithPagination;

    public string $search = '';
    public int $perPage = 10;
    public string $pageInput = '1';
    public bool $showCreateModal = false;
    public ?int $editingStageId = null;
    public string $name = '';
    public string $editName = '';

    protected array $queryString = [
        'search' => ['except' => ''],
        'perPage' => ['except' => 10, 'as' => 'per_page'],
        'page' => ['except' => 1],
    ];

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255', 'unique:crop_growth_stages,name'],
            'editName' => ['required', 'string', 'max:255', Rule::unique('crop_growth_stages', 'name')->ignore($this->editingStageId)],
        ];
    }

    public function updatedSearch(): void
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
        $this->reset(['name']);
        $this->showCreateModal = true;
    }

    public function closeCreateModal(): void
    {
        $this->showCreateModal = false;
        $this->resetValidation();
        $this->reset(['name']);
    }

    public function createStage(): void
    {
        $this->validateOnly('name');

        CropGrowthStage::create([
            'name' => trim($this->name),
        ]);

        $this->closeCreateModal();
        $this->resetPage();
        $this->pageInput = '1';
        $this->dispatch('stage-saved', message: 'Growth stage added successfully.');
    }

    public function openEditModal(int $stageId): void
    {
        $stage = CropGrowthStage::findOrFail($stageId);

        $this->resetValidation();
        $this->editingStageId = $stage->id;
        $this->editName = $stage->name;
    }

    public function closeEditModal(): void
    {
        $this->editingStageId = null;
        $this->resetValidation();
        $this->reset(['editName']);
    }

    public function updateStage(): void
    {
        $this->validateOnly('editName');

        $stage = CropGrowthStage::findOrFail($this->editingStageId);
        $stage->update([
            'name' => trim($this->editName),
        ]);

        $this->closeEditModal();
        $this->dispatch('stage-saved', message: 'Growth stage updated.');
    }

    public function deleteStage(int $stageId): void
    {
        $stage = CropGrowthStage::findOrFail($stageId);
        $stage->delete();

        $this->dispatch('stage-saved', message: 'Growth stage removed.');
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

        return CropGrowthStage::query()
            ->when($search !== '', function ($query) use ($search) {
                $query->where('name', 'like', '%' . $search . '%');
            })
            ->orderBy('id', 'asc');
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

    public function render()
    {
        $stages = $this->filteredQuery()->paginate($this->perPage);

        // Standard default stages checklist
        $defaultStagesList = [
            'land_preparation', 'sowing_planting', 'germination', 'seedling', 'vegetative_early', 
            'vegetative_mid', 'vegetative_late', 'flowering_bud_formation', 'flowering_full_bloom', 
            'fruit_set', 'fruit_development', 'maturation_ripening', 'harvest_ongoing', 
            'harvest_complete', 'fallow'
        ];
        
        $registeredDefaultCount = CropGrowthStage::whereIn('name', $defaultStagesList)->count();
        $totalCount = CropGrowthStage::count();
        $customCount = max(0, $totalCount - $registeredDefaultCount);

        return $this->view([
            'stages' => $stages,
            'totalStageCount' => $totalCount,
            'defaultStageCount' => $registeredDefaultCount,
            'customStageCount' => $customCount,
            'paginationItems' => $this->paginationItems($stages->currentPage(), $stages->lastPage()),
        ]);
    }
};
?>

<div class="space-y-6">
    <section class="flex flex-col xl:flex-row xl:items-end xl:justify-between gap-4">
        <div>
            <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-50 border border-emerald-100 text-emerald-700 text-[11px] font-extrabold uppercase tracking-widest">
                <i class="fa-solid fa-bars-progress"></i>
                Crop Stages Management
            </div>
            <h1 class="mt-3 text-2xl sm:text-3xl font-black tracking-tight text-slate-900 font-poppins">Crop Growth Stages</h1>
            <p class="mt-1 text-sm text-slate-500 font-medium max-w-2xl">Create, modify, and search the different physiological growth stages for tracking cultivation history.</p>
        </div>
        <div class="flex flex-col sm:flex-row gap-3">
            <button type="button" wire:click="openCreateModal" class="inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-extrabold shadow-md shadow-emerald-500/20 transition">
                <i class="fa-solid fa-plus"></i>
                Add Growth Stage
            </button>
            <a href="{{ route('admin.crops') }}" class="inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-white border border-slate-200 text-slate-600 hover:text-emerald-700 hover:border-emerald-200 text-xs font-bold shadow-sm transition">
                <i class="fa-solid fa-seedling"></i>
                Crop Varieties
            </a>
        </div>
    </section>

    <section class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-4">
        <div class="bg-white border border-slate-100 rounded-2xl p-5 shadow-sm flex items-center justify-between">
            <div>
                <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest">Total Stages</span>
                <strong class="mt-2 block text-3xl font-black text-slate-900 font-poppins">{{ $totalStageCount }}</strong>
            </div>
            <div class="w-12 h-12 bg-slate-50 text-slate-600 rounded-xl flex items-center justify-center text-lg">
                <i class="fa-solid fa-layer-group"></i>
            </div>
        </div>
        <div class="bg-white border border-emerald-100 rounded-2xl p-5 shadow-sm flex items-center justify-between">
            <div>
                <span class="text-[10px] font-extrabold text-emerald-600 uppercase tracking-widest">Default Stages</span>
                <strong class="mt-2 block text-3xl font-black text-emerald-700 font-poppins">{{ $defaultStageCount }} <span class="text-xs font-medium text-slate-400">/ 15</span></strong>
            </div>
            <div class="w-12 h-12 bg-emerald-50 text-emerald-700 rounded-xl flex items-center justify-center text-lg">
                <i class="fa-solid fa-star-of-life"></i>
            </div>
        </div>
        <div class="bg-white border border-amber-100 rounded-2xl p-5 shadow-sm flex items-center justify-between">
            <div>
                <span class="text-[10px] font-extrabold text-amber-600 uppercase tracking-widest">Custom Stages</span>
                <strong class="mt-2 block text-3xl font-black text-amber-700 font-poppins">{{ $customStageCount }}</strong>
            </div>
            <div class="w-12 h-12 bg-amber-50 text-amber-700 rounded-xl flex items-center justify-center text-lg">
                <i class="fa-solid fa-sliders"></i>
            </div>
        </div>
    </section>

    <section class="bg-white border border-slate-100 rounded-2xl shadow-sm overflow-hidden">
        <div class="p-5 sm:p-6 border-b border-slate-100 space-y-4">
            <div class="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
                <div>
                    <h2 class="text-base font-extrabold text-slate-900 font-poppins">Registered Growth Stages</h2>
                    <p class="text-xs text-slate-500 font-medium">All changes occur in real-time. Use search to filter standard key names.</p>
                </div>
                <div wire:loading class="text-xs font-extrabold text-emerald-700 bg-emerald-50 border border-emerald-100 rounded-full px-3 py-1">
                    Syncing...
                </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-[minmax(0,1fr)_150px] gap-3">
                <div class="relative">
                    <i class="fa-solid fa-magnifying-glass absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 text-sm"></i>
                    <input wire:model.live.debounce.350ms="search" class="w-full rounded-xl border border-slate-200 bg-slate-50 pl-10 pr-4 py-3 text-sm font-semibold outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition" placeholder="Search stage keys or friendly names">
                </div>
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
                        <th class="px-5 py-3 text-left text-[10px] font-extrabold uppercase tracking-widest text-slate-400">ID</th>
                        <th class="px-5 py-3 text-left text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Stage Name</th>
                        <th class="px-5 py-3 text-left text-[10px] font-extrabold uppercase tracking-widest text-slate-400">System Tag</th>
                        <th class="px-5 py-3 text-left text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Created At</th>
                        <th class="px-5 py-3 text-right text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100 bg-white">
                    @forelse ($stages as $stage)
                        @php
                            $isDefault = in_array($stage->name, [
                                'land_preparation', 'sowing_planting', 'germination', 'seedling', 'vegetative_early', 
                                'vegetative_mid', 'vegetative_late', 'flowering_bud_formation', 'flowering_full_bloom', 
                                'fruit_set', 'fruit_development', 'maturation_ripening', 'harvest_ongoing', 
                                'harvest_complete', 'fallow'
                            ]);
                        @endphp
                        <tr class="align-middle hover:bg-slate-50/70 transition" wire:key="stage-row-{{ $stage->id }}">
                            <td class="px-5 py-4">
                                <span class="text-[11px] text-slate-400 font-bold">#GS{{ str_pad($stage->id, 4, '0', STR_PAD_LEFT) }}</span>
                            </td>
                            <td class="px-5 py-4">
                                <div class="flex items-center gap-3">
                                    <div class="w-8 h-8 rounded-lg bg-emerald-50 border border-emerald-100 text-emerald-600 flex items-center justify-center text-xs shrink-0">
                                        <i class="fa-solid fa-leaf"></i>
                                    </div>
                                    <div>
                                        <span class="text-sm font-extrabold text-slate-900">{{ ucwords(str_replace('_', ' ', $stage->name)) }}</span>
                                    </div>
                                </div>
                            </td>
                            <td class="px-5 py-4">
                                <span class="inline-flex items-center rounded-lg bg-slate-100 border border-slate-200 px-2.5 py-1 text-[11px] font-extrabold text-slate-600 font-mono">{{ $stage->name }}</span>
                            </td>
                            <td class="px-5 py-4">
                                <p class="text-xs font-semibold text-slate-600">{{ $stage->created_at ? $stage->created_at->format('M d, Y h:i A') : 'System Default' }}</p>
                                <p class="text-[11px] text-slate-400 font-medium mt-0.5">{{ $stage->created_at ? $stage->created_at->diffForHumans() : '' }}</p>
                            </td>
                            <td class="px-5 py-4">
                                <div class="flex items-center justify-end gap-2">
                                    <button type="button" wire:click="openEditModal({{ $stage->id }})" class="inline-flex items-center gap-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 px-3 py-2 text-[11px] font-extrabold transition">
                                        <i class="fa-solid fa-pen"></i>
                                        Edit
                                    </button>
                                    @if ($isDefault)
                                        <span class="inline-flex items-center gap-1 text-slate-400 px-3 py-2 text-[11px] font-bold" title="Default stages cannot be removed to prevent system corruption.">
                                            <i class="fa-solid fa-lock text-[9px]"></i> Protected
                                        </span>
                                    @else
                                        <button type="button" wire:click="$dispatch('confirm-stage-delete', { stageId: {{ $stage->id }}, stageName: @js($stage->name) })" class="inline-flex items-center gap-1.5 rounded-lg bg-slate-50 hover:bg-rose-50 text-slate-500 hover:text-rose-700 px-3 py-2 text-[11px] font-extrabold transition border border-slate-100 hover:border-rose-100">
                                            <i class="fa-solid fa-trash"></i>
                                            Remove
                                        </button>
                                    @endif
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="5" class="px-5 py-12 text-center">
                                <div class="mx-auto w-14 h-14 rounded-2xl bg-slate-100 text-slate-400 flex items-center justify-center">
                                    <i class="fa-solid fa-magnifying-glass"></i>
                                </div>
                                <p class="mt-4 text-sm font-extrabold text-slate-700 font-poppins">No stages found</p>
                                <p class="mt-1 text-xs text-slate-500 font-medium">Adjust the filters or insert a new crop growth stage.</p>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <div class="p-5 sm:p-6 border-t border-slate-100 flex flex-col xl:flex-row xl:items-center xl:justify-between gap-4">
            <p class="text-xs text-slate-500 font-semibold">
                Showing <span class="font-extrabold text-slate-800">{{ $stages->firstItem() ?? 0 }}</span> to <span class="font-extrabold text-slate-800">{{ $stages->lastItem() ?? 0 }}</span> of <span class="font-extrabold text-slate-800">{{ $stages->total() }}</span> stages
            </p>

            <div class="flex flex-col sm:flex-row sm:items-center gap-3">
                <form wire:submit="goToTypedPage" class="flex items-center gap-2">
                    <label class="text-xs font-bold text-slate-500">Go to</label>
                    <input wire:model="pageInput" type="number" min="1" max="{{ $stages->lastPage() }}" class="w-20 rounded-lg border border-slate-200 px-3 py-2 text-xs font-extrabold text-slate-700 outline-none focus:border-emerald-400 focus:ring-4 focus:ring-emerald-100">
                    <button class="rounded-lg bg-slate-900 hover:bg-emerald-700 text-white px-3 py-2 text-xs font-extrabold transition">Go</button>
                </form>

                @if ($stages->hasPages())
                    <div class="flex flex-wrap items-center gap-2">
                        <button type="button" wire:click="setPage(1)" @disabled($stages->onFirstPage()) class="px-3 py-2 rounded-lg border border-slate-200 text-xs font-bold disabled:pointer-events-none disabled:opacity-40 hover:border-emerald-200 hover:text-emerald-700">First</button>
                        <button type="button" wire:click="previousPage" @disabled($stages->onFirstPage()) class="px-3 py-2 rounded-lg border border-slate-200 text-xs font-bold disabled:pointer-events-none disabled:opacity-40 hover:border-emerald-200 hover:text-emerald-700">Prev</button>
                        @foreach ($paginationItems as $item)
                            @if ($item === '...')
                                <span class="px-2 py-2 text-xs font-black text-slate-300">...</span>
                            @else
                                <button type="button" wire:click="setPage({{ $item }})" class="min-w-9 text-center px-3 py-2 rounded-lg border text-xs font-extrabold {{ $item === $stages->currentPage() ? 'bg-emerald-600 border-emerald-600 text-white' : 'border-slate-200 text-slate-600 hover:border-emerald-200 hover:text-emerald-700' }}">{{ $item }}</button>
                            @endif
                        @endforeach
                        <button type="button" wire:click="nextPage" @disabled(!$stages->hasMorePages()) class="px-3 py-2 rounded-lg border border-slate-200 text-xs font-bold disabled:pointer-events-none disabled:opacity-40 hover:border-emerald-200 hover:text-emerald-700">Next</button>
                        <button type="button" wire:click="setPage({{ $stages->lastPage() }})" @disabled($stages->currentPage() === $stages->lastPage()) class="px-3 py-2 rounded-lg border border-slate-200 text-xs font-bold disabled:pointer-events-none disabled:opacity-40 hover:border-emerald-200 hover:text-emerald-700">Last</button>
                    </div>
                @endif
            </div>
        </div>
    </section>

    @if ($showCreateModal)
        <div class="fixed left-0 top-0 z-[9999] flex h-screen w-screen items-center justify-center p-4" style="inset: 0; width: 100vw; height: 100vh;" aria-modal="true">
            <button type="button" wire:click="closeCreateModal" class="absolute inset-0 h-full w-full bg-slate-950/60 backdrop-blur-sm"></button>
            <div class="relative w-full max-w-lg bg-white rounded-2xl shadow-2xl border border-slate-100 overflow-hidden animate-in fade-in zoom-in-95 duration-200">
                <div class="p-5 border-b border-slate-100 flex items-start justify-between gap-4">
                    <div>
                        <h2 class="text-lg font-extrabold text-slate-900 font-poppins">Add Growth Stage</h2>
                        <p class="text-xs text-slate-500 font-semibold mt-1 font-sans">Introduce new custom physiological growth steps.</p>
                    </div>
                    <button type="button" wire:click="closeCreateModal" class="w-9 h-9 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-500 transition">
                        <i class="fa-solid fa-xmark"></i>
                    </button>
                </div>
                <form wire:submit="createStage" class="p-5 space-y-4">
                    <div>
                        <label class="block text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-2 font-poppins">Growth Stage Key Name</label>
                        <input wire:model="name" required maxlength="255" class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-semibold text-slate-800 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition" placeholder="Example: vegetative_early or seedling">
                        <p class="mt-2 text-[10px] text-slate-400 font-medium">Use lowercase words separated by underscores (e.g. land_preparation) to match system API formatting.</p>
                        @error('name') <p class="mt-2 text-xs font-bold text-rose-600">{{ $message }}</p> @enderror
                    </div>
                    <button type="submit" wire:loading.attr="disabled" class="w-full inline-flex items-center justify-center gap-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 disabled:opacity-60 text-white px-4 py-3 text-sm font-extrabold shadow-md shadow-emerald-500/20 transition">
                        <i class="fa-solid fa-floppy-disk"></i>
                        Save Growth Stage
                    </button>
                </form>
            </div>
        </div>
    @endif

    @if ($editingStageId)
        <div class="fixed left-0 top-0 z-[9999] flex h-screen w-screen items-center justify-center p-4" style="inset: 0; width: 100vw; height: 100vh;" aria-modal="true">
            <button type="button" wire:click="closeEditModal" class="absolute inset-0 h-full w-full bg-slate-950/60 backdrop-blur-sm"></button>
            <div class="relative w-full max-w-lg bg-white rounded-2xl shadow-2xl border border-slate-100 overflow-hidden animate-in fade-in zoom-in-95 duration-200">
                <div class="p-5 border-b border-slate-100 flex items-start justify-between gap-4">
                    <div>
                        <h2 class="text-lg font-extrabold text-slate-900 font-poppins">Edit Growth Stage</h2>
                        <p class="text-xs text-slate-500 font-semibold mt-1 font-sans">Update stage keys safely. Ensure changes are verified across client applications.</p>
                    </div>
                    <button type="button" wire:click="closeEditModal" class="w-9 h-9 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-500 transition">
                        <i class="fa-solid fa-xmark"></i>
                    </button>
                </div>
                <form wire:submit="updateStage" class="p-5 space-y-4">
                    <div>
                        <label class="block text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-2 font-poppins">Growth Stage Key Name</label>
                        <input wire:model="editName" required maxlength="255" class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-semibold text-slate-800 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition">
                        <p class="mt-2 text-[10px] text-slate-400 font-medium">Updating this stage might affect existing cultivation entries using this stage key.</p>
                        @error('editName') <p class="mt-2 text-xs font-bold text-rose-600">{{ $message }}</p> @enderror
                    </div>
                    <button type="submit" wire:loading.attr="disabled" class="w-full inline-flex items-center justify-center gap-2 rounded-xl bg-slate-900 hover:bg-emerald-700 disabled:opacity-60 text-white px-4 py-3 text-sm font-extrabold transition">
                        <i class="fa-solid fa-floppy-disk"></i>
                        Update Growth Stage
                    </button>
                </form>
            </div>
        </div>
    @endif
</div>
