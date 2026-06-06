<?php

use Illuminate\Support\Facades\DB;
use Livewire\Component;
use Livewire\WithPagination;

new class extends Component
{
    use WithPagination;

    public int $farmerId;
    public string $search = '';
    public string $landId = 'all';
    public string $disease = 'all';
    public string $pest = 'all';
    public string $pesticide = 'all';
    public string $startDate = '';
    public string $endDate = '';
    public int $perPage = 10;
    public string $pageInput = '1';

    protected array $queryString = [
        'search' => ['except' => ''],
        'landId' => ['except' => 'all', 'as' => 'land_id'],
        'disease' => ['except' => 'all'],
        'pest' => ['except' => 'all'],
        'pesticide' => ['except' => 'all'],
        'startDate' => ['except' => '', 'as' => 'start_date'],
        'endDate' => ['except' => '', 'as' => 'end_date'],
        'perPage' => ['except' => 10, 'as' => 'per_page'],
        'page' => ['except' => 1],
    ];

    public function updatedSearch(): void
    {
        $this->resetPage();
        $this->pageInput = '1';
    }

    public function updatedLandId(): void
    {
        $this->resetPage();
        $this->pageInput = '1';
    }

    public function updatedDisease(): void
    {
        $this->resetPage();
        $this->pageInput = '1';
    }

    public function updatedPest(): void
    {
        $this->resetPage();
        $this->pageInput = '1';
    }

    public function updatedPesticide(): void
    {
        $this->resetPage();
        $this->pageInput = '1';
    }

    public function updatedStartDate(): void
    {
        $this->resetPage();
        $this->pageInput = '1';
    }

    public function updatedEndDate(): void
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

        return DB::table('daily_cultivation_logs')
            ->join('lands', 'daily_cultivation_logs.land_id', '=', 'lands.id')
            ->join('crop_growth_stages', 'daily_cultivation_logs.growth_stage_id', '=', 'crop_growth_stages.id')
            ->where('daily_cultivation_logs.farmer_id', $this->farmerId)
            ->select(
                'daily_cultivation_logs.*',
                'lands.size as land_size',
                'lands.ownership_type as land_ownership',
                'lands.registration_number as land_reg',
                'crop_growth_stages.name as stage_name'
            )
            ->when($search !== '', function ($query) use ($search) {
                $query->where(function ($subQuery) use ($search) {
                    $subQuery->where('daily_cultivation_logs.leaf_appearance', 'like', '%' . $search . '%')
                        ->orWhere('daily_cultivation_logs.disease_name_and_damage', 'like', '%' . $search . '%')
                        ->orWhere('daily_cultivation_logs.pest_name_and_damage', 'like', '%' . $search . '%')
                        ->orWhere('daily_cultivation_logs.notes', 'like', '%' . $search . '%')
                        ->orWhere('daily_cultivation_logs.pesticide_name', 'like', '%' . $search . '%');
                });
            })
            ->when($this->landId !== 'all', fn ($query) => $query->where('daily_cultivation_logs.land_id', $this->landId))
            ->when($this->disease !== 'all', fn ($query) => $query->where('daily_cultivation_logs.disease_detected', $this->disease === 'yes'))
            ->when($this->pest !== 'all', fn ($query) => $query->where('daily_cultivation_logs.pest_detected', $this->pest === 'yes'))
            ->when($this->pesticide !== 'all', fn ($query) => $query->where('daily_cultivation_logs.pesticide_applied', $this->pesticide === 'yes'))
            ->when($this->startDate !== '', fn ($query) => $query->where('daily_cultivation_logs.log_date', '>=', $this->startDate))
            ->when($this->endDate !== '', fn ($query) => $query->where('daily_cultivation_logs.log_date', '<=', $this->endDate))
            ->orderByDesc('daily_cultivation_logs.log_date')
            ->orderByDesc('daily_cultivation_logs.id');
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
        $logs = $this->filteredQuery()->paginate($this->perPage);
        $lands = DB::table('lands')
            ->where('farmer_id', $this->farmerId)
            ->select('id', 'size', 'ownership_type')
            ->get();

        return $this->view([
            'logs' => $logs,
            'lands' => $lands,
            'paginationItems' => $this->paginationItems($logs->currentPage(), $logs->lastPage()),
        ]);
    }
};
?>

<div class="space-y-6">
    <!-- Advanced Search & Filter Controls Card -->
    <section class="bg-white border border-slate-100 rounded-2xl shadow-sm overflow-hidden">
        <div class="p-5 sm:p-6 border-b border-slate-100 space-y-4">
            <div class="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
                <div>
                    <h2 class="text-base font-extrabold text-slate-900">Farmer Cultivation Logs</h2>
                    <p class="text-xs text-slate-500 font-medium">Search, filter, and page through daily cultivation logs recorded for this farmer.</p>
                </div>
                <div wire:loading class="text-xs font-extrabold text-emerald-700 bg-emerald-50 border border-emerald-100 rounded-full px-3 py-1">
                    Syncing logs...
                </div>
            </div>

            <!-- Inputs Grid -->
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
                <!-- Search -->
                <div class="relative">
                    <i class="fa-solid fa-magnifying-glass absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 text-sm"></i>
                    <input wire:model.live.debounce.350ms="search" class="w-full rounded-xl border border-slate-200 bg-slate-50 pl-10 pr-4 py-2.5 text-xs font-semibold outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition" placeholder="Search notes, diseases, pesticides...">
                </div>

                <!-- Land Plot Filter -->
                <div>
                    <select wire:model.live="landId" class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-2.5 text-xs font-bold text-slate-700 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition">
                        <option value="all">All Land Plots</option>
                        @foreach ($lands as $land)
                            <option value="{{ $land->id }}">#LND-{{ str_pad($land->id, 4, '0', STR_PAD_LEFT) }} ({{ $land->size }} Perches)</option>
                        @endforeach
                    </select>
                </div>

                <!-- Disease Filter -->
                <div>
                    <select wire:model.live="disease" class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-2.5 text-xs font-bold text-slate-700 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition">
                        <option value="all">Disease: All</option>
                        <option value="yes">Disease Detected</option>
                        <option value="no">No Disease</option>
                    </select>
                </div>

                <!-- Pest Filter -->
                <div>
                    <select wire:model.live="pest" class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-2.5 text-xs font-bold text-slate-700 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition">
                        <option value="all">Pest: All</option>
                        <option value="yes">Pest Detected</option>
                        <option value="no">No Pests</option>
                    </select>
                </div>

                <!-- Pesticide Filter -->
                <div>
                    <select wire:model.live="pesticide" class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-2.5 text-xs font-bold text-slate-700 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition">
                        <option value="all">Pesticide: All</option>
                        <option value="yes">Pesticide Applied</option>
                        <option value="no">No Pesticide</option>
                    </select>
                </div>

                <!-- Start Date -->
                <div>
                    <input type="date" wire:model.live="startDate" class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-2 text-xs font-bold text-slate-700 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition" placeholder="Start Log Date">
                </div>

                <!-- End Date -->
                <div>
                    <input type="date" wire:model.live="endDate" class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-2 text-xs font-bold text-slate-700 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition" placeholder="End Log Date">
                </div>

                <!-- Page Size -->
                <div>
                    <select wire:model.live="perPage" class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-2.5 text-xs font-bold text-slate-700 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition">
                        @foreach ([10, 25, 50, 100] as $size)
                            <option value="{{ $size }}">{{ $size }} logs / page</option>
                        @endforeach
                    </select>
                </div>
            </div>
        </div>

        <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-slate-100">
                <thead class="bg-slate-50">
                    <tr>
                        <th class="px-5 py-3 text-left text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Date & Land ID</th>
                        <th class="px-5 py-3 text-left text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Growth Stage</th>
                        <th class="px-5 py-3 text-left text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Status Check</th>
                        <th class="px-5 py-3 text-left text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Observations & Notes</th>
                    </tr>
                </thead>
                @forelse ($logs as $log)
                    @php
                        $dateStr = date('M d, Y', strtotime($log->log_date));
                        
                        $diseaseName = '';
                        $diseaseDamage = '';
                        if ($log->disease_name_and_damage) {
                            $decoded = json_decode($log->disease_name_and_damage, true);
                            if (json_last_error() === JSON_ERROR_NONE && is_array($decoded)) {
                                $diseaseName = $decoded['name'] ?? '';
                                $diseaseDamage = $decoded['damage'] ?? '';
                            } else {
                                $diseaseName = $log->disease_name_and_damage;
                            }
                        }

                        $pestName = '';
                        $pestDamage = '';
                        if ($log->pest_name_and_damage) {
                            $decoded = json_decode($log->pest_name_and_damage, true);
                            if (json_last_error() === JSON_ERROR_NONE && is_array($decoded)) {
                                $pestName = $decoded['name'] ?? '';
                                $pestDamage = $decoded['damage'] ?? '';
                            } else {
                                $pestName = $log->pest_name_and_damage;
                            }
                        }
                    @endphp
                    <tbody class="divide-y divide-slate-100 bg-white text-xs font-semibold text-slate-700" x-data="{ open: false }" wire:key="log-group-{{ $log->id }}">
                        <tr class="hover:bg-slate-50/50 transition duration-150 align-middle">
                            <!-- Date & Land ID -->
                            <td class="px-5 py-4 whitespace-nowrap min-w-[150px]">
                                <div class="flex items-center gap-2.5">
                                    <!-- Toggle Button -->
                                    <button type="button" @click="open = !open" class="w-5 h-5 rounded-lg border border-slate-200 bg-slate-50 hover:bg-slate-100 hover:border-slate-300 text-slate-400 hover:text-slate-600 flex items-center justify-center transition shrink-0">
                                        <i class="fa-solid fa-chevron-right text-[8px] transition-transform duration-200" :class="open ? 'rotate-90 text-emerald-600' : ''"></i>
                                    </button>
                                    <div>
                                        <strong class="text-slate-900 block font-poppins cursor-pointer hover:text-emerald-700 transition" @click="open = !open">{{ $dateStr }}</strong>
                                        <span class="text-[10px] text-emerald-700 font-extrabold uppercase mt-0.5 block">#LND-{{ str_pad($log->land_id, 4, '0', STR_PAD_LEFT) }}</span>
                                        <span class="text-[9px] text-slate-400 block mt-0.5">{{ $log->land_size }} Perches</span>
                                    </div>
                                </div>
                            </td>

                            <!-- Growth Stage -->
                            <td class="px-5 py-4 whitespace-nowrap min-w-[120px]">
                                <span class="px-2.5 py-1 rounded-lg bg-emerald-50 text-emerald-700 border border-emerald-100 text-[10px] font-extrabold uppercase tracking-wide">
                                    {{ ucwords(str_replace('_', ' ', $log->stage_name)) }}
                                </span>
                            </td>

                            <!-- Status Indicators (Compact Badges) -->
                            <td class="px-5 py-4 whitespace-nowrap min-w-[150px]">
                                <div class="flex flex-wrap gap-1.5 max-w-[180px]">
                                    <!-- Disease -->
                                    @if ($log->disease_detected)
                                        <span class="px-1.5 py-0.5 rounded bg-rose-50 border border-rose-100 text-rose-700 text-[9px] font-black uppercase tracking-wider">Disease</span>
                                    @else
                                        <span class="px-1.5 py-0.5 rounded bg-slate-50 border border-slate-100 text-slate-400 text-[9px] font-black uppercase tracking-wider">No Disease</span>
                                    @endif

                                    <!-- Pest -->
                                    @if ($log->pest_detected)
                                        <span class="px-1.5 py-0.5 rounded bg-rose-50 border border-rose-100 text-rose-700 text-[9px] font-black uppercase tracking-wider">Pest</span>
                                    @else
                                        <span class="px-1.5 py-0.5 rounded bg-slate-50 border border-slate-100 text-slate-400 text-[9px] font-black uppercase tracking-wider">No Pests</span>
                                    @endif

                                    <!-- Pesticide -->
                                    @if ($log->pesticide_applied)
                                        <span class="px-1.5 py-0.5 rounded bg-emerald-50 border border-emerald-100 text-emerald-700 text-[9px] font-black uppercase tracking-wider">Pesticide</span>
                                    @endif
                                </div>
                            </td>

                            <!-- Observations & Notes (Truncated Preview) -->
                            <td class="px-5 py-4 min-w-[200px] max-w-xs">
                                <div class="text-[11px] text-slate-500 cursor-pointer hover:text-slate-800 flex flex-col gap-0.5" @click="open = !open">
                                    @if ($log->notes)
                                        <span class="font-medium italic text-slate-650">"{{ Str::limit($log->notes, 45, '...') }}"</span>
                                    @elseif ($diseaseName || $pestName)
                                        @if ($diseaseName)
                                            <span class="font-semibold text-rose-650">Disease: {{ Str::limit($diseaseName, 30, '...') }}</span>
                                        @endif
                                        @if ($pestName)
                                            <span class="font-semibold text-rose-650">Pest: {{ Str::limit($pestName, 30, '...') }}</span>
                                        @endif
                                    @elseif ($log->leaf_appearance)
                                        <span class="font-semibold text-slate-600">Leaf: {{ Str::limit($log->leaf_appearance, 45, '...') }}</span>
                                    @else
                                        <span class="text-slate-450 italic font-medium">No extra notes recorded.</span>
                                    @endif
                                    
                                    @if ($log->notes || $log->leaf_appearance || $diseaseName || $pestName)
                                        <span class="text-emerald-600 hover:text-emerald-700 font-extrabold text-[9px] mt-0.5 flex items-center gap-1">
                                            <span x-show="!open">See details <i class="fa-solid fa-chevron-down text-[7px]"></i></span>
                                            <span x-show="open" x-cloak>Hide details <i class="fa-solid fa-chevron-up text-[7px]"></i></span>
                                        </span>
                                    @endif
                                </div>
                            </td>

                        </tr>

                        <!-- Expanded details row -->
                        <tr x-show="open" x-cloak class="bg-slate-50/40 border-t border-b border-slate-100/80">
                            <td colspan="4" class="px-5 py-4">
                                <div class="bg-white border border-slate-150/70 rounded-2xl p-4 shadow-sm space-y-3">
                                    <div class="flex items-center justify-between border-b border-slate-100 pb-2.5">
                                        <h6 class="text-[11px] font-black text-slate-800 uppercase tracking-widest flex items-center gap-1.5">
                                            <i class="fa-solid fa-clipboard-list text-emerald-600 text-xs"></i> Detailed Log Observations
                                        </h6>
                                        <span class="text-[9px] text-slate-400 font-extrabold uppercase font-poppins">Log date: {{ $dateStr }}</span>
                                    </div>
                                    
                                    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5 gap-3">
                                        <!-- Leaf State -->
                                        <div class="bg-slate-50/50 rounded-xl p-2.5 border border-slate-100">
                                            <span class="text-slate-400 block text-[8px] uppercase font-black tracking-wider">Leaf State</span>
                                            <p class="text-slate-700 font-extrabold text-[11px] mt-1 leading-normal">{{ $log->leaf_appearance ?? 'N/A' }}</p>
                                        </div>

                                        <!-- Disease details -->
                                        <div class="bg-slate-50/50 rounded-xl p-2.5 border border-slate-100">
                                            <span class="text-slate-400 block text-[8px] uppercase font-black tracking-wider">Disease Details</span>
                                            @if ($log->disease_detected)
                                                <div class="text-rose-700 font-extrabold text-[11px] mt-1 leading-normal flex items-start gap-1">
                                                    <i class="fa-solid fa-triangle-exclamation mt-0.5 shrink-0 text-xs text-rose-500"></i>
                                                    <div>
                                                        @if ($diseaseName)
                                                            <span class="block text-slate-800 font-black leading-tight">{{ $diseaseName }}</span>
                                                        @else
                                                            <span class="block">Detected</span>
                                                        @endif
                                                        @if ($diseaseDamage)
                                                            <div class="text-[10px] text-rose-600 font-bold mt-1 leading-relaxed">
                                                                <span class="text-slate-400 text-[8px] uppercase font-black block tracking-wider">Damage / Symptoms</span>
                                                                <span>{{ $diseaseDamage }}</span>
                                                            </div>
                                                        @elseif (!$diseaseName && $log->disease_name_and_damage)
                                                            <p class="text-[10px] text-rose-600 font-bold mt-1 leading-relaxed">{{ $log->disease_name_and_damage }}</p>
                                                        @endif
                                                    </div>
                                                </div>
                                            @else
                                                <p class="text-emerald-700 font-extrabold text-[11px] mt-1 leading-normal flex items-center gap-1">
                                                    <i class="fa-solid fa-circle-check text-emerald-600 text-xs"></i> Clear / Healthy
                                                </p>
                                            @endif
                                        </div>

                                        <!-- Pest details -->
                                        <div class="bg-slate-50/50 rounded-xl p-2.5 border border-slate-100">
                                            <span class="text-slate-400 block text-[8px] uppercase font-black tracking-wider">Pest Details</span>
                                            @if ($log->pest_detected)
                                                <div class="text-rose-700 font-extrabold text-[11px] mt-1 leading-normal flex items-start gap-1">
                                                    <i class="fa-solid fa-bug mt-0.5 shrink-0 text-xs text-rose-500"></i>
                                                    <div>
                                                        @if ($pestName)
                                                            <span class="block text-slate-800 font-black leading-tight">{{ $pestName }}</span>
                                                        @else
                                                            <span class="block">Detected</span>
                                                        @endif
                                                        @if ($pestDamage)
                                                            <div class="text-[10px] text-rose-600 font-bold mt-1 leading-relaxed">
                                                                <span class="text-slate-400 text-[8px] uppercase font-black block tracking-wider">Damage / Symptoms</span>
                                                                <span>{{ $pestDamage }}</span>
                                                            </div>
                                                        @elseif (!$pestName && $log->pest_name_and_damage)
                                                            <p class="text-[10px] text-rose-600 font-bold mt-1 leading-relaxed">{{ $log->pest_name_and_damage }}</p>
                                                        @endif
                                                    </div>
                                                </div>
                                            @else
                                                <p class="text-emerald-700 font-extrabold text-[11px] mt-1 leading-normal flex items-center gap-1">
                                                    <i class="fa-solid fa-circle-check text-emerald-600 text-xs"></i> Clear / Healthy
                                                </p>
                                            @endif
                                        </div>

                                        <!-- Pesticide Application -->
                                        <div class="bg-slate-50/50 rounded-xl p-2.5 border border-slate-100">
                                            <span class="text-slate-400 block text-[8px] uppercase font-black tracking-wider">Pesticide Application</span>
                                            @if ($log->pesticide_applied)
                                                <div class="text-emerald-800 font-extrabold text-[11px] mt-1 leading-normal flex items-start gap-1">
                                                    <i class="fa-solid fa-flask-vial mt-0.5 shrink-0 text-xs text-emerald-600"></i>
                                                    <div>
                                                        <span>Applied</span>
                                                        <p class="text-[10px] text-emerald-700 font-bold mt-0.5 leading-relaxed">
                                                            {{ $log->pesticide_name ?? 'N/A' }}<br>
                                                            Type: {{ $log->pesticide_type ? ucwords($log->pesticide_type) : 'N/A' }}
                                                        </p>
                                                    </div>
                                                </div>
                                            @else
                                                <p class="text-slate-500 font-extrabold text-[11px] mt-1 leading-normal flex items-center gap-1">
                                                    <i class="fa-solid fa-circle-minus text-slate-400 text-xs"></i> Not Applied
                                                </p>
                                            @endif
                                        </div>

                                        <!-- Notes -->
                                        <div class="bg-slate-50/50 rounded-xl p-2.5 border border-slate-100 xl:col-span-1">
                                            <span class="text-slate-400 block text-[8px] uppercase font-black tracking-wider">Notes</span>
                                            <p class="text-slate-650 italic font-medium text-[11px] mt-1 leading-relaxed">
                                                "{{ $log->notes ?? 'No extra notes recorded.' }}"
                                            </p>
                                        </div>
                                    </div>
                                </div>
                            </td>
                        </tr>
                    </tbody>
                @empty
                    <tbody class="divide-y divide-slate-100 bg-white text-xs font-semibold text-slate-700">
                        <tr>
                            <td colspan="4" class="px-5 py-12 text-center text-slate-400">
                                <div class="mx-auto w-14 h-14 rounded-2xl bg-slate-50 text-slate-300 flex items-center justify-center text-xl">
                                    <i class="fa-solid fa-clipboard-question"></i>
                                </div>
                                <p class="mt-4 text-xs font-bold text-slate-700 uppercase tracking-wide">No Cultivation Logs Logged</p>
                                <p class="mt-1 text-[11px] text-slate-400">No logs found matching your filters for this farmer.</p>
                            </td>
                        </tr>
                    </tbody>
                @endforelse
            </table>
        </div>

        <!-- Pagination Bar -->
        <div class="p-5 sm:p-6 border-t border-slate-100 flex flex-col xl:flex-row xl:items-center xl:justify-between gap-4">
            <p class="text-xs text-slate-500 font-semibold">
                Showing <span class="font-extrabold text-slate-800">{{ $logs->firstItem() ?? 0 }}</span> to <span class="font-extrabold text-slate-800">{{ $logs->lastItem() ?? 0 }}</span> of <span class="font-extrabold text-slate-800">{{ $logs->total() }}</span> cultivation logs
            </p>

            <div class="flex flex-col sm:flex-row sm:items-center gap-3">
                <!-- Direct Page Input -->
                <form wire:submit="goToTypedPage" class="flex items-center gap-2">
                    <label class="text-xs font-bold text-slate-500">Go to</label>
                    <input wire:model="pageInput" type="number" min="1" max="{{ $logs->lastPage() }}" class="w-16 rounded-lg border border-slate-200 px-2.5 py-1.5 text-xs font-extrabold text-slate-700 outline-none focus:border-emerald-400 focus:ring-4 focus:ring-emerald-100">
                    <button class="rounded-lg bg-slate-900 hover:bg-emerald-700 text-white px-3 py-1.5 text-xs font-extrabold transition">Go</button>
                </form>

                <!-- Page Buttons -->
                @if ($logs->hasPages())
                    <div class="flex flex-wrap items-center gap-1.5">
                        <button type="button" wire:click="setPage(1)" @disabled($logs->onFirstPage()) class="px-2.5 py-1.5 rounded-lg border border-slate-200 text-xs font-bold disabled:pointer-events-none disabled:opacity-40 hover:border-emerald-200 hover:text-emerald-700 transition">First</button>
                        <button type="button" wire:click="previousPage" @disabled($logs->onFirstPage()) class="px-2.5 py-1.5 rounded-lg border border-slate-200 text-xs font-bold disabled:pointer-events-none disabled:opacity-40 hover:border-emerald-200 hover:text-emerald-700 transition">Prev</button>
                        @foreach ($paginationItems as $item)
                            @if ($item === '...')
                                <span class="px-1.5 py-1.5 text-xs font-black text-slate-300">...</span>
                            @else
                                <button type="button" wire:click="setPage({{ $item }})" class="min-w-8 text-center px-2.5 py-1.5 rounded-lg border text-xs font-extrabold {{ $item === $logs->currentPage() ? 'bg-emerald-600 border-emerald-600 text-white' : 'border-slate-200 text-slate-600 hover:border-emerald-200 hover:text-emerald-700' }}">{{ $item }}</button>
                            @endif
                        @endforeach
                        <button type="button" wire:click="nextPage" @disabled(!$logs->hasMorePages()) class="px-2.5 py-1.5 rounded-lg border border-slate-200 text-xs font-bold disabled:pointer-events-none disabled:opacity-40 hover:border-emerald-200 hover:text-emerald-700 transition">Next</button>
                        <button type="button" wire:click="setPage({{ $logs->lastPage() }})" @disabled($logs->currentPage() === $logs->lastPage()) class="px-2.5 py-1.5 rounded-lg border border-slate-200 text-xs font-bold disabled:pointer-events-none disabled:opacity-40 hover:border-emerald-200 hover:text-emerald-700 transition">Last</button>
                    </div>
                @endif
            </div>
        </div>
    </section>
</div>

<!-- Modal script helper using SweetAlert2 -->
<script>
    function showLogDetailsModal(log) {
        const formatDetails = (data) => {
            if (typeof data === 'object' && data !== null) {
                let html = `<strong class="text-slate-800 text-[12px] block">${data.name || 'Detected'}</strong>`;
                if (data.damage) {
                    html += `
                        <div class="mt-1.5 pt-1.5 border-t border-slate-100">
                            <span class="text-slate-400 text-[9px] uppercase font-black block tracking-wider">Damage / Symptoms</span>
                            <span class="text-rose-700 font-semibold mt-0.5 block">${data.damage}</span>
                        </div>
                    `;
                }
                return html;
            }
            return data;
        };

        Swal.fire({
            title: `<span class="font-poppins text-lg font-black text-emerald-800">Log Details - ${log.date}</span>`,
            html: `
                <div class="text-left font-sans text-xs space-y-4 pt-3 text-slate-700">
                    <div class="grid grid-cols-2 gap-4 border-b border-slate-100 pb-3 font-semibold">
                        <div>
                            <span class="text-slate-400 block text-[9px] uppercase">Land Plot</span>
                            <span class="text-slate-800 block mt-0.5">${log.land}</span>
                        </div>
                        <div>
                            <span class="text-slate-400 block text-[9px] uppercase">Growth Stage</span>
                            <span class="text-slate-800 block mt-0.5">${log.stage}</span>
                        </div>
                    </div>
                    
                    <div class="space-y-3">
                        <div>
                            <span class="text-slate-400 block text-[9px] uppercase font-bold">Leaf Appearance & Health</span>
                            <p class="mt-1 p-2.5 bg-slate-50 border border-slate-100 rounded-xl font-medium leading-relaxed">${log.leaf}</p>
                        </div>
                        
                        <div>
                            <span class="text-slate-400 block text-[9px] uppercase font-bold">Disease Diagnostics</span>
                            <div class="mt-1 p-2.5 bg-slate-50 border border-slate-100 rounded-xl font-medium leading-relaxed ${log.disease !== 'Clear' ? 'text-rose-700 border-rose-100 bg-rose-50/20' : ''}">
                                ${formatDetails(log.disease)}
                            </div>
                        </div>

                        <div>
                            <span class="text-slate-400 block text-[9px] uppercase font-bold">Pest Diagnostics</span>
                            <div class="mt-1 p-2.5 bg-slate-50 border border-slate-100 rounded-xl font-medium leading-relaxed ${log.pest !== 'Clear' ? 'text-rose-700 border-rose-100 bg-rose-50/20' : ''}">
                                ${formatDetails(log.pest)}
                            </div>
                        </div>

                        <div>
                            <span class="text-slate-400 block text-[9px] uppercase font-bold">Pesticide Applications</span>
                            <p class="mt-1 p-2.5 bg-slate-50 border border-slate-100 rounded-xl font-medium leading-relaxed ${log.pesticide !== 'Not Applied' ? 'text-emerald-800 border-emerald-100 bg-emerald-50/20' : ''}">${log.pesticide}</p>
                        </div>

                        <div>
                            <span class="text-slate-400 block text-[9px] uppercase font-bold">General Observations / Notes</span>
                            <p class="mt-1 p-2.5 bg-slate-50 border border-slate-100 rounded-xl font-medium italic leading-relaxed text-slate-650">"${log.notes}"</p>
                        </div>
                    </div>
                </div>
            `,
            showConfirmButton: true,
            confirmButtonColor: '#059669',
            confirmButtonText: 'Dismiss Info',
            customClass: {
                popup: 'rounded-3xl shadow-2xl border border-slate-100 max-w-lg w-full',
                confirmButton: 'rounded-xl font-bold shadow-md shadow-emerald-500/20 px-8 py-3 text-xs uppercase'
            }
        });
    }
</script>
