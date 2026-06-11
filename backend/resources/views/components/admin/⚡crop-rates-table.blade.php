<?php

use App\Models\CropRate;
use App\Models\Crop;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Livewire\Component;
use Livewire\WithPagination;

new class extends Component
{
    use WithPagination;

    public string $activeTab = 'today'; // 'today' or 'history'
    
    // History filters
    public string $filterCrop = 'all';
    public string $filterBuyer = 'all';
    public string $filterStartDate = '';
    public string $filterEndDate = '';
    
    public int $perPage = 10;
    public string $pageInput = '1';

    // Toggle array for today's crop details
    public array $openCrops = [];

    protected array $queryString = [
        'activeTab' => ['except' => 'today'],
        'filterCrop' => ['except' => 'all'],
        'filterBuyer' => ['except' => 'all'],
        'filterStartDate' => ['except' => ''],
        'filterEndDate' => ['except' => ''],
        'perPage' => ['except' => 10, 'as' => 'per_page'],
        'page' => ['except' => 1],
    ];

    public function updatedActiveTab(): void
    {
        $this->resetPage();
        $this->pageInput = '1';
    }

    public function updatedFilterCrop(): void
    {
        $this->resetPage();
        $this->pageInput = '1';
    }

    public function updatedFilterBuyer(): void
    {
        $this->resetPage();
        $this->pageInput = '1';
    }

    public function updatedFilterStartDate(): void
    {
        $this->resetPage();
        $this->pageInput = '1';
    }

    public function updatedFilterEndDate(): void
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

    public function toggleCrop(int $cropId): void
    {
        $this->openCrops[$cropId] = !($this->openCrops[$cropId] ?? false);
    }

    public function deleteRate(int $id): void
    {
        $rate = CropRate::findOrFail($id);
        $rate->delete();
        $this->dispatch('rate-saved', message: 'Crop rate submission removed successfully.');
    }

    public function goToTypedPage(): void
    {
        $lastPage = max(1, (int) ceil($this->getFilteredHistoryQuery()->count() / $this->perPage));
        $page = min(max((int) $this->pageInput, 1), $lastPage);
        $this->pageInput = (string) $page;
        $this->setPage($page);
    }

    private function getFilteredHistoryQuery()
    {
        return CropRate::query()
            ->with(['buyer', 'crop'])
            ->when($this->filterCrop !== 'all', fn ($query) => $query->where('crop_id', $this->filterCrop))
            ->when($this->filterBuyer !== 'all', fn ($query) => $query->where('buyer_id', $this->filterBuyer))
            ->when($this->filterStartDate !== '', fn ($query) => $query->whereDate('date_and_time', '>=', $this->filterStartDate))
            ->when($this->filterEndDate !== '', fn ($query) => $query->whereDate('date_and_time', '<=', $this->filterEndDate))
            ->orderByDesc('date_and_time');
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
        $today = Carbon::today()->toDateString();

        // 1. Fetch Today's Averages per Crop
        $todayRatesSummary = DB::table('crops')
            ->where('crops.status', 'approved')
            ->leftJoin('crop_rates', function ($join) use ($today) {
                $join->on('crops.id', '=', 'crop_rates.crop_id')
                     ->whereDate('crop_rates.date_and_time', $today);
            })
            ->select(
                'crops.id as crop_id',
                'crops.cropname as crop_name',
                'crops.image_path',
                DB::raw('ROUND(AVG(crop_rates.rate_per_kg_grade_a), 2) as avg_rate_grade_a'),
                DB::raw('ROUND(AVG(crop_rates.rate_per_kg_grade_b), 2) as avg_rate_grade_b'),
                DB::raw('ROUND(AVG(crop_rates.rate_per_kg_grade_c), 2) as avg_rate_grade_c'),
                DB::raw('COUNT(crop_rates.id) as total_submissions')
            )
            ->groupBy('crops.id', 'crops.cropname', 'crops.image_path')
            ->orderBy('crops.cropname')
            ->get();

        // 2. Fetch Today's Detailed Submissions
        $todaySubmissions = DB::table('crop_rates')
            ->join('users', 'crop_rates.buyer_id', '=', 'users.id')
            ->whereDate('crop_rates.date_and_time', $today)
            ->select('crop_rates.*', 'users.full_name as buyer_name')
            ->orderByDesc('crop_rates.created_at')
            ->get()
            ->groupBy('crop_id');

        // 3. Fetch Paginated History
        $history = $this->getFilteredHistoryQuery()->paginate($this->perPage);

        // 4. Filters lists
        $cropsList = Crop::where('status', 'approved')->orderBy('cropname')->get();
        $buyersList = User::whereJsonContains('role', 'buyer')->orderBy('full_name')->get();

        return $this->view([
            'todayRatesSummary' => $todayRatesSummary,
            'todaySubmissions' => $todaySubmissions,
            'history' => $history,
            'cropsList' => $cropsList,
            'buyersList' => $buyersList,
            'paginationItems' => $this->paginationItems($history->currentPage(), $history->lastPage()),
        ]);
    }
};
?>

<div class="space-y-6">
    <!-- Header Block -->
    <section class="flex flex-col xl:flex-row xl:items-end xl:justify-between gap-4">
        <div>
            <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-50 border border-emerald-100 text-emerald-700 text-[11px] font-extrabold uppercase tracking-widest">
                <i class="fa-solid fa-arrow-trend-up"></i>
                Market Intelligence Engine
            </div>
            <h1 class="mt-3 text-2xl sm:text-3xl font-black tracking-tight text-slate-900 font-poppins">Crop Rates Oversight</h1>
            <p class="mt-1 text-sm text-slate-500 font-medium max-w-3xl">Monitor daily crop rates submitted by wholesale buyers, inspect today's average Grade prices, view submissions history, and purge erroneous entries.</p>
        </div>
        <div class="flex flex-col sm:flex-row gap-3">
            <a href="{{ route('admin.dashboard') }}" class="inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-white border border-slate-200 text-slate-600 hover:text-emerald-700 hover:border-emerald-200 text-xs font-bold shadow-sm transition">
                <i class="fa-solid fa-arrow-left"></i>
                Dashboard
            </a>
        </div>
    </section>

    <!-- Tab Selection Header -->
    <div class="flex border-b border-slate-200 gap-2 shrink-0 overflow-x-auto">
        <button type="button" wire:click="$set('activeTab', 'today')" class="px-5 py-3 text-xs font-bold transition-all border-b-2 whitespace-nowrap flex items-center gap-2 {{ $activeTab === 'today' ? 'border-emerald-600 text-emerald-700 font-extrabold' : 'border-transparent text-slate-500 hover:text-slate-900' }}">
            <i class="fa-solid fa-calendar-day"></i> Today's Market Averages
        </button>
        <button type="button" wire:click="$set('activeTab', 'history')" class="px-5 py-3 text-xs font-bold transition-all border-b-2 whitespace-nowrap flex items-center gap-2 {{ $activeTab === 'history' ? 'border-emerald-600 text-emerald-700 font-extrabold' : 'border-transparent text-slate-500 hover:text-slate-900' }}">
            <i class="fa-solid fa-clock-rotate-left"></i> Historical Submissions Log
        </button>
    </div>

    <!-- TAB 1: Today's Market Averages -->
    @if ($activeTab === 'today')
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            @forelse ($todayRatesSummary as $crop)
                @php
                    $cropImg = $crop->image_path ? (Str::startsWith($crop->image_path, ['http://', 'https://']) ? $crop->image_path : asset('storage/' . $crop->image_path)) : null;
                    $isOpen = $openCrops[$crop->crop_id] ?? false;
                @endphp
                <div class="bg-white border border-slate-100 rounded-3xl p-5 shadow-sm space-y-4 hover:shadow-md transition duration-300">
                    <!-- Crop Header -->
                    <div class="flex items-center gap-3">
                        <div class="w-12 h-12 rounded-2xl bg-emerald-50/50 border border-emerald-100 flex items-center justify-center shrink-0 overflow-hidden">
                            @if ($cropImg)
                                <img src="{{ $cropImg }}" alt="{{ $crop->crop_name }}" class="w-full h-full object-cover">
                            @else
                                <i class="fa-solid fa-wheat-awn text-emerald-600 text-lg"></i>
                            @endif
                        </div>
                        <div class="flex-1 min-w-0">
                            <h3 class="text-sm font-black text-slate-800 font-poppins truncate">{{ $crop->crop_name }}</h3>
                            <span class="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-[9px] font-bold uppercase tracking-wider {{ $crop->total_submissions > 0 ? 'bg-emerald-50 text-emerald-700' : 'bg-slate-50 text-slate-500' }}">
                                <i class="fa-solid fa-users text-[8px]"></i>
                                {{ $crop->total_submissions }} {{ Str::plural('Submission', $crop->total_submissions) }} Today
                            </span>
                        </div>
                    </div>

                    <!-- Grades Rates Grid -->
                    <div class="grid grid-cols-3 gap-3 bg-slate-50 p-3.5 rounded-2xl border border-slate-100/60 text-center">
                        <div>
                            <span class="text-[9px] font-extrabold uppercase text-slate-400 block tracking-wider">Grade A</span>
                            @if ($crop->avg_rate_grade_a)
                                <strong class="text-emerald-700 font-black text-xs block mt-1">LKR {{ number_format($crop->avg_rate_grade_a, 2) }}</strong>
                            @else
                                <span class="text-[10px] text-slate-400 italic block mt-1 font-semibold">No Rate</span>
                            @endif
                        </div>
                        <div class="border-l border-r border-slate-200/50">
                            <span class="text-[9px] font-extrabold uppercase text-slate-400 block tracking-wider">Grade B</span>
                            @if ($crop->avg_rate_grade_b)
                                <strong class="text-amber-700 font-black text-xs block mt-1">LKR {{ number_format($crop->avg_rate_grade_b, 2) }}</strong>
                            @else
                                <span class="text-[10px] text-slate-400 italic block mt-1 font-semibold">No Rate</span>
                            @endif
                        </div>
                        <div>
                            <span class="text-[9px] font-extrabold uppercase text-slate-400 block tracking-wider">Grade C</span>
                            @if ($crop->avg_rate_grade_c)
                                <strong class="text-slate-800 font-black text-xs block mt-1">LKR {{ number_format($crop->avg_rate_grade_c, 2) }}</strong>
                            @else
                                <span class="text-[10px] text-slate-400 italic block mt-1 font-semibold">No Rate</span>
                            @endif
                        </div>
                    </div>

                    <!-- Toggle Button & Details -->
                    @if ($crop->total_submissions > 0)
                        <div>
                            <button type="button" wire:click="toggleCrop({{ $crop->crop_id }})" class="w-full inline-flex items-center justify-between px-3 py-2 rounded-xl bg-slate-50 hover:bg-slate-100 text-[10px] font-extrabold text-slate-600 transition border border-slate-100">
                                <span>{{ $isOpen ? 'Hide' : 'Show' }} Today's Individual Submissions</span>
                                <i class="fa-solid {{ $isOpen ? 'fa-chevron-up' : 'fa-chevron-down' }} text-[8px] text-slate-400"></i>
                            </button>

                            @if ($isOpen)
                                <div class="mt-3 overflow-x-auto border border-slate-100 rounded-2xl shadow-inner">
                                    <table class="min-w-full divide-y divide-slate-100 text-xs text-left">
                                        <thead class="bg-slate-50/70 font-extrabold uppercase text-slate-400 text-[9px] tracking-wider">
                                            <tr>
                                                <th class="px-3 py-2">Buyer</th>
                                                <th class="px-3 py-2 text-right">Grade A</th>
                                                <th class="px-3 py-2 text-right">Grade B</th>
                                                <th class="px-3 py-2 text-right">Grade C</th>
                                                <th class="px-3 py-2 text-center">Quantities</th>
                                                <th class="px-3 py-2 text-center">Grades</th>
                                                <th class="px-3 py-2 text-right">Actions</th>
                                            </tr>
                                        </thead>
                                        <tbody class="divide-y divide-slate-100 font-semibold text-slate-700 bg-white">
                                            @foreach ($todaySubmissions[$crop->crop_id] ?? [] as $sub)
                                                <tr class="hover:bg-slate-50/50">
                                                    <td class="px-3 py-2 font-black text-slate-900 max-w-[120px] truncate" title="{{ $sub->buyer_name }}">{{ $sub->buyer_name }}</td>
                                                    <td class="px-3 py-2 text-right text-emerald-600 font-black">
                                                        {{ $sub->rate_per_kg_grade_a ? 'LKR ' . number_format($sub->rate_per_kg_grade_a, 2) : '-' }}
                                                    </td>
                                                    <td class="px-3 py-2 text-right text-amber-700 font-bold">
                                                        {{ $sub->rate_per_kg_grade_b ? 'LKR ' . number_format($sub->rate_per_kg_grade_b, 2) : '-' }}
                                                    </td>
                                                    <td class="px-3 py-2 text-right text-slate-800">
                                                        {{ $sub->rate_per_kg_grade_c ? 'LKR ' . number_format($sub->rate_per_kg_grade_c, 2) : '-' }}
                                                    </td>
                                                    <td class="px-3 py-2 text-center text-[10px] text-slate-500 font-medium">
                                                        {{ $sub->min_qty_required ? number_format($sub->min_qty_required, 0) : '0' }} - {{ $sub->max_qty_required ? number_format($sub->max_qty_required, 0) : '∞' }} kg
                                                    </td>
                                                    <td class="px-3 py-2 text-center">
                                                        <span class="inline-block px-1.5 py-0.5 rounded text-[8px] font-black uppercase bg-slate-100 border border-slate-200/50 text-slate-600">{{ $sub->accepted_grade ?? 'All' }}</span>
                                                    </td>
                                                    <td class="px-3 py-2 text-right">
                                                        <button type="button" x-on:click="$dispatch('confirm-rate-delete', { rateId: {{ $sub->id }} })" class="text-rose-500 hover:text-rose-700 transition p-1" title="Delete Submission">
                                                            <i class="fa-solid fa-trash text-[10px]"></i>
                                                        </button>
                                                    </td>
                                                </tr>
                                            @endforeach
                                        </tbody>
                                    </table>
                                </div>
                            @endif
                        </div>
                    @else
                        <div class="py-4 text-center border border-dashed border-slate-200 bg-slate-50/50 rounded-2xl text-[10px] font-bold text-slate-400">
                            <i class="fa-solid fa-circle-exclamation text-xs text-slate-300 block mb-1"></i>
                            No submissions recorded for {{ $crop->crop_name }} today
                        </div>
                    @endif
                </div>
            @empty
                <div class="col-span-2 border border-dashed border-slate-200 rounded-3xl p-12 text-center text-slate-400 bg-slate-50/50">
                    <i class="fa-solid fa-wheat-awn text-3xl text-slate-300 animate-pulse mb-3 block"></i>
                    <p class="text-xs font-bold">No Crops Registered</p>
                    <p class="text-[11px] text-slate-400 mt-1">Please register and approve crop varieties first to enable submissions oversight.</p>
                </div>
            @endforelse
        </div>
    @endif

    <!-- TAB 2: Historical Submissions Log -->
    @if ($activeTab === 'history')
        <section class="bg-white border border-slate-100 rounded-2xl shadow-sm overflow-hidden">
            <!-- Filter Bar -->
            <div class="p-5 sm:p-6 border-b border-slate-100 space-y-4">
                <div>
                    <h2 class="text-base font-extrabold text-slate-900">Historical Rates Database</h2>
                    <p class="text-xs text-slate-500 font-medium">Verify submissions records, track price fluctuation logs, and filter records by buyer profile, crop variety, or date parameters.</p>
                </div>

                <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-3">
                    <div class="flex flex-col gap-1">
                        <label class="text-[9px] font-extrabold uppercase tracking-wider text-slate-400">Crop Variety</label>
                        <select wire:model.live="filterCrop" class="rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-xs font-bold text-slate-700 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition">
                            <option value="all">All Crops</option>
                            @foreach ($cropsList as $crop)
                                <option value="{{ $crop->id }}">{{ $crop->cropname }}</option>
                            @endforeach
                        </select>
                    </div>

                    <div class="flex flex-col gap-1">
                        <label class="text-[9px] font-extrabold uppercase tracking-wider text-slate-400">Wholesale Buyer</label>
                        <select wire:model.live="filterBuyer" class="rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-xs font-bold text-slate-700 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition">
                            <option value="all">All Buyers</option>
                            @foreach ($buyersList as $buyer)
                                <option value="{{ $buyer->id }}">{{ $buyer->full_name }}</option>
                            @endforeach
                        </select>
                    </div>

                    <div class="flex flex-col gap-1">
                        <label class="text-[9px] font-extrabold uppercase tracking-wider text-slate-400">From Date</label>
                        <input type="date" wire:model.live="filterStartDate" class="rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-xs font-bold text-slate-700 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition">
                    </div>

                    <div class="flex flex-col gap-1">
                        <label class="text-[9px] font-extrabold uppercase tracking-wider text-slate-400">To Date</label>
                        <input type="date" wire:model.live="filterEndDate" class="rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-xs font-bold text-slate-700 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition">
                    </div>

                    <div class="flex flex-col gap-1">
                        <label class="text-[9px] font-extrabold uppercase tracking-wider text-slate-400">Per Page</label>
                        <select wire:model.live="perPage" class="rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-xs font-bold text-slate-700 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition">
                            @foreach ([10, 25, 50, 100] as $size)
                                <option value="{{ $size }}">{{ $size }} / page</option>
                            @endforeach
                        </select>
                    </div>
                </div>
            </div>

            <!-- Table Block -->
            <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-slate-100 text-xs text-left">
                    <thead class="bg-slate-50 font-extrabold uppercase text-slate-400 text-[10px] tracking-wider">
                        <tr>
                            <th class="px-5 py-3">Timestamp</th>
                            <th class="px-5 py-3">Buyer Profile</th>
                            <th class="px-5 py-3">Crop Variety</th>
                            <th class="px-5 py-3 text-right">Grade A Rate</th>
                            <th class="px-5 py-3 text-right">Grade B Rate</th>
                            <th class="px-5 py-3 text-right">Grade C Rate</th>
                            <th class="px-5 py-3 text-center">Quantities Required</th>
                            <th class="px-5 py-3 text-center">Grades Accepted</th>
                            <th class="px-5 py-3 text-right">Actions</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100 font-semibold text-slate-700 bg-white">
                        @forelse ($history as $h)
                            <tr class="hover:bg-slate-50/50 transition duration-150">
                                <td class="px-5 py-4 text-slate-400 font-medium whitespace-nowrap">
                                    {{ $h->date_and_time->format('Y-m-d H:i') }}
                                </td>
                                <td class="px-5 py-4">
                                    <div class="font-extrabold text-slate-900">{{ $h->buyer->full_name ?? 'N/A' }}</div>
                                    <div class="text-[10px] text-slate-400 font-bold mt-0.5">{{ $h->buyer->email ?? '' }}</div>
                                </td>
                                <td class="px-5 py-4">
                                    <span class="font-bold text-slate-800">{{ $h->crop->cropname ?? 'Deleted Crop' }}</span>
                                </td>
                                <td class="px-5 py-4 text-right text-emerald-600 font-black">
                                    {{ $h->rate_per_kg_grade_a ? 'LKR ' . number_format($h->rate_per_kg_grade_a, 2) : '-' }}
                                </td>
                                <td class="px-5 py-4 text-right text-amber-700 font-bold">
                                    {{ $h->rate_per_kg_grade_b ? 'LKR ' . number_format($h->rate_per_kg_grade_b, 2) : '-' }}
                                </td>
                                <td class="px-5 py-4 text-right text-slate-800">
                                    {{ $h->rate_per_kg_grade_c ? 'LKR ' . number_format($h->rate_per_kg_grade_c, 2) : '-' }}
                                </td>
                                <td class="px-5 py-4 text-center text-slate-500 font-medium">
                                    {{ $h->min_qty_required ? number_format($h->min_qty_required, 0) : '0' }} - {{ $h->max_qty_required ? number_format($h->max_qty_required, 0) : '∞' }} kg
                                </td>
                                <td class="px-5 py-4 text-center">
                                    <span class="inline-block px-2 py-0.5 rounded text-[9px] font-black uppercase bg-slate-100 border border-slate-200/50 text-slate-600">{{ $h->accepted_grade ?? 'All' }}</span>
                                </td>
                                <td class="px-5 py-4 text-right">
                                    <button type="button" x-on:click="$dispatch('confirm-rate-delete', { rateId: {{ $h->id }} })" class="inline-flex items-center justify-center w-7 h-7 rounded-lg bg-rose-50 text-rose-600 hover:bg-rose-100 transition" title="Delete Submission">
                                        <i class="fa-solid fa-trash text-xs"></i>
                                    </button>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="9" class="px-5 py-12 text-center text-slate-400 font-bold">
                                    <i class="fa-solid fa-circle-exclamation text-2xl block mb-2 text-slate-300"></i> No Historical Rates Submissions Match Filters
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>

            <!-- Pagination Block -->
            <div class="p-5 sm:p-6 border-t border-slate-100 flex flex-col xl:flex-row xl:items-center xl:justify-between gap-4">
                <p class="text-xs text-slate-500 font-semibold">
                    Showing <span class="font-extrabold text-slate-800">{{ $history->firstItem() ?? 0 }}</span> to <span class="font-extrabold text-slate-800">{{ $history->lastItem() ?? 0 }}</span> of <span class="font-extrabold text-slate-800">{{ $history->total() }}</span> records
                </p>

                <div class="flex flex-col sm:flex-row sm:items-center gap-3">
                    <form wire:submit="goToTypedPage" class="flex items-center gap-2">
                        <label class="text-xs font-bold text-slate-500 font-poppins">Go to</label>
                        <input wire:model="pageInput" type="number" min="1" max="{{ $history->lastPage() }}" class="w-16 rounded-lg border border-slate-200 px-2.5 py-1.5 text-xs font-extrabold text-slate-700 outline-none focus:border-emerald-400 focus:ring-4 focus:ring-emerald-100">
                        <button class="rounded-lg bg-slate-900 hover:bg-emerald-700 text-white px-2.5 py-1.5 text-xs font-extrabold transition">Go</button>
                    </form>

                    @if ($history->hasPages())
                        <div class="flex flex-wrap items-center gap-2">
                            <button type="button" wire:click="setPage(1)" @disabled($history->onFirstPage()) class="px-2.5 py-1.5 rounded-lg border border-slate-200 text-xs font-bold disabled:pointer-events-none disabled:opacity-40 hover:border-emerald-200 hover:text-emerald-700">First</button>
                            <button type="button" wire:click="previousPage" @disabled($history->onFirstPage()) class="px-2.5 py-1.5 rounded-lg border border-slate-200 text-xs font-bold disabled:pointer-events-none disabled:opacity-40 hover:border-emerald-200 hover:text-emerald-700">Prev</button>
                            @foreach ($paginationItems as $item)
                                @if ($item === '...')
                                    <span class="px-1.5 py-1.5 text-xs font-black text-slate-300">...</span>
                                @else
                                    <button type="button" wire:click="setPage({{ $item }})" class="min-w-8 text-center px-2.5 py-1.5 rounded-lg border text-xs font-extrabold {{ $item === $history->currentPage() ? 'bg-emerald-600 border-emerald-600 text-white' : 'border-slate-200 text-slate-600 hover:border-emerald-200 hover:text-emerald-700' }}">{{ $item }}</button>
                                @endif
                            @endforeach
                            <button type="button" wire:click="nextPage" @disabled(!$history->hasMorePages()) class="px-2.5 py-1.5 rounded-lg border border-slate-200 text-xs font-bold disabled:pointer-events-none disabled:opacity-40 hover:border-emerald-200 hover:text-emerald-700">Next</button>
                            <button type="button" wire:click="setPage({{ $history->lastPage() }})" @disabled($history->currentPage() === $history->lastPage()) class="px-2.5 py-1.5 rounded-lg border border-slate-200 text-xs font-bold disabled:pointer-events-none disabled:opacity-40 hover:border-emerald-200 hover:text-emerald-700">Last</button>
                        </div>
                    @endif
                </div>
            </div>
        </section>
    @endif
</div>
