<?php

use App\Models\OfferGoal;
use App\Models\OfferCampaign;
use Illuminate\Validation\Rule;
use Livewire\Component;
use Livewire\WithPagination;

new class extends Component
{
    use WithPagination;

    // Tabs
    public string $activeTab = 'campaigns';

    // Search and Pagination
    public string $search = '';
    public string $goalSearch = '';
    public int $perPage = 10;
    public string $pageInput = '1';

    // Modals
    public bool $showCampaignModal = false;
    public bool $showGoalModal = false;
    public ?int $editingCampaignId = null;
    public ?int $editingGoalId = null;

    // Campaign Form Fields
    public ?int $offer_goal_id = null;
    public string $title = '';
    public string $code = '';
    public string $description = '';
    public string $type = 'percentage';
    public ?float $discount_percentage = null;
    public ?float $discount_amount = null;
    public ?float $max_discount_amount = null;
    public int $minimum_completion_count = 1;
    public string $valid_from = '';
    public string $valid_until = '';
    public ?int $usage_limit_per_user = null;
    public ?int $total_usage_limit = null;
    public bool $is_active = true;
    public string $applied_user_role = 'customer';

    // Goal Form Fields
    public string $goal_name = '';
    public string $goal_description = '';
    public string $goal_type = 'total_orders';
    public ?float $goal_target_value = null;
    public bool $goal_is_active = true;

    protected array $queryString = [
        'search' => ['except' => ''],
        'goalSearch' => ['except' => ''],
        'activeTab' => ['except' => 'campaigns'],
        'perPage' => ['except' => 10, 'as' => 'per_page'],
    ];

    public function mount()
    {
        $this->resetPage();
    }

    public function updatedActiveTab(): void
    {
        $this->resetPage('campaignsPage');
        $this->resetPage('goalsPage');
        $this->pageInput = '1';
    }

    public function updatedSearch(): void
    {
        $this->resetPage('campaignsPage');
        $this->pageInput = '1';
    }

    public function updatedGoalSearch(): void
    {
        $this->resetPage('goalsPage');
        $this->pageInput = '1';
    }

    public function updatedPerPage(): void
    {
        $this->resetPage('campaignsPage');
        $this->resetPage('goalsPage');
        $this->pageInput = '1';
    }

    // Modal control for Campaigns
    public function openCampaignCreateModal(): void
    {
        $this->resetValidation();
        $this->resetCampaignFields();
        $this->editingCampaignId = null;
        $this->showCampaignModal = true;
    }

    public function openCampaignEditModal(int $id): void
    {
        $this->resetValidation();
        $campaign = OfferCampaign::findOrFail($id);
        $this->editingCampaignId = $campaign->id;
        $this->offer_goal_id = $campaign->offer_goal_id;
        $this->title = $campaign->title;
        $this->code = $campaign->code;
        $this->description = $campaign->description ?? '';
        $this->type = $campaign->type;
        $this->discount_percentage = $campaign->discount_percentage;
        $this->discount_amount = $campaign->discount_amount;
        $this->max_discount_amount = $campaign->max_discount_amount;
        $this->minimum_completion_count = $campaign->minimum_completion_count;
        $this->valid_from = $campaign->valid_from ? $campaign->valid_from->format('Y-m-d\TH:i') : '';
        $this->valid_until = $campaign->valid_until ? $campaign->valid_until->format('Y-m-d\TH:i') : '';
        $this->usage_limit_per_user = $campaign->usage_limit_per_user;
        $this->total_usage_limit = $campaign->total_usage_limit;
        $this->is_active = $campaign->is_active;
        $this->applied_user_role = $campaign->applied_user_role;
        $this->showCampaignModal = true;
    }

    public function saveCampaign(): void
    {
        $rules = [
            'offer_goal_id' => ['required', 'exists:offer_goals,id'],
            'title' => ['required', 'string', 'max:255'],
            'code' => ['required', 'string', 'max:255', Rule::unique('offer_campaigns', 'code')->ignore($this->editingCampaignId)],
            'description' => ['nullable', 'string'],
            'type' => ['required', Rule::in(OfferCampaign::TYPES)],
            'discount_percentage' => ['required_if:type,percentage', 'nullable', 'numeric', 'min:0', 'max:100'],
            'discount_amount' => ['required_if:type,fixed_amount', 'nullable', 'numeric', 'min:0'],
            'max_discount_amount' => ['nullable', 'numeric', 'min:0'],
            'minimum_completion_count' => ['required', 'integer', 'min:1'],
            'valid_from' => ['required', 'date'],
            'valid_until' => ['required', 'date', 'after:valid_from'],
            'usage_limit_per_user' => ['nullable', 'integer', 'min:1'],
            'total_usage_limit' => ['nullable', 'integer', 'min:1'],
            'applied_user_role' => ['required', Rule::in(OfferCampaign::APPLIED_USER_ROLES)],
            'is_active' => ['required', 'boolean'],
        ];

        $validated = $this->validate($rules);

        // Map null fields for types
        if ($this->type === 'percentage') {
            $validated['discount_amount'] = null;
        } elseif ($this->type === 'fixed_amount') {
            $validated['discount_percentage'] = null;
            $validated['max_discount_amount'] = null;
        } else { // free_shipping
            $validated['discount_percentage'] = null;
            $validated['discount_amount'] = null;
            $validated['max_discount_amount'] = null;
        }

        if ($this->editingCampaignId) {
            OfferCampaign::findOrFail($this->editingCampaignId)->update($validated);
            $msg = 'Campaign updated successfully.';
        } else {
            OfferCampaign::create($validated);
            $msg = 'Campaign created successfully.';
        }

        $this->showCampaignModal = false;
        $this->resetCampaignFields();
        $this->dispatch('campaign-saved', message: $msg);
    }

    public function toggleCampaignActive(int $id): void
    {
        $campaign = OfferCampaign::findOrFail($id);
        $campaign->update(['is_active' => !$campaign->is_active]);
        $this->dispatch('campaign-saved', message: 'Campaign active status updated.');
    }

    public function deleteCampaign(int $id): void
    {
        OfferCampaign::findOrFail($id)->delete();
        $this->dispatch('campaign-saved', message: 'Campaign removed.');
    }

    private function resetCampaignFields(): void
    {
        $this->reset([
            'offer_goal_id', 'title', 'code', 'description', 'type', 
            'discount_percentage', 'discount_amount', 'max_discount_amount', 
            'minimum_completion_count', 'valid_from', 'valid_until', 
            'usage_limit_per_user', 'total_usage_limit', 'is_active', 'applied_user_role'
        ]);
        $this->type = 'percentage';
        $this->is_active = true;
        $this->applied_user_role = 'customer';
        $this->minimum_completion_count = 1;
    }

    // Modal control for Goals
    public function openGoalCreateModal(): void
    {
        $this->resetValidation();
        $this->resetGoalFields();
        $this->editingGoalId = null;
        $this->showGoalModal = true;
    }

    public function openGoalEditModal(int $id): void
    {
        $this->resetValidation();
        $goal = OfferGoal::findOrFail($id);
        $this->editingGoalId = $goal->id;
        $this->goal_name = $goal->name;
        $this->goal_description = $goal->description ?? '';
        $this->goal_type = $goal->goal_type;
        $this->goal_target_value = $goal->target_value;
        $this->goal_is_active = $goal->is_active;
        $this->showGoalModal = true;
    }

    public function saveGoal(): void
    {
        $rules = [
            'goal_name' => ['required', 'string', 'max:255'],
            'goal_description' => ['nullable', 'string'],
            'goal_type' => ['required', Rule::in(OfferGoal::GOAL_TYPES)],
            'goal_target_value' => ['required', 'numeric', 'min:0'],
            'goal_is_active' => ['required', 'boolean'],
        ];

        $this->validate($rules);

        $data = [
            'name' => $this->goal_name,
            'description' => $this->goal_description,
            'goal_type' => $this->goal_type,
            'target_value' => $this->goal_target_value,
            'is_active' => $this->goal_is_active,
        ];

        if ($this->editingGoalId) {
            OfferGoal::findOrFail($this->editingGoalId)->update($data);
            $msg = 'Offer Goal updated successfully.';
        } else {
            OfferGoal::create($data);
            $msg = 'Offer Goal created successfully.';
        }

        $this->showGoalModal = false;
        $this->resetGoalFields();
        $this->dispatch('goal-saved', message: $msg);
    }

    public function toggleGoalActive(int $id): void
    {
        $goal = OfferGoal::findOrFail($id);
        $goal->update(['is_active' => !$goal->is_active]);
        $this->dispatch('goal-saved', message: 'Goal active status updated.');
    }

    public function deleteGoal(int $id): void
    {
        OfferGoal::findOrFail($id)->delete();
        $this->dispatch('goal-saved', message: 'Goal and associated campaigns removed.');
    }

    private function resetGoalFields(): void
    {
        $this->reset([
            'goal_name', 'goal_description', 'goal_type', 'goal_target_value', 'goal_is_active'
        ]);
        $this->goal_type = 'total_orders';
        $this->goal_is_active = true;
    }

    public function goToTypedPage(): void
    {
        $currentPageName = $this->activeTab === 'campaigns' ? 'campaignsPage' : 'goalsPage';
        $count = $this->activeTab === 'campaigns' 
            ? $this->filteredCampaignsQuery()->count() 
            : $this->filteredGoalsQuery()->count();
        $lastPage = max(1, (int) ceil($count / $this->perPage));
        $page = min(max((int) $this->pageInput, 1), $lastPage);
        $this->pageInput = (string) $page;
        $this->setPage($page, $currentPageName);
    }

    private function filteredCampaignsQuery()
    {
        $search = trim($this->search);
        return OfferCampaign::query()
            ->with('goal')
            ->when($search !== '', function ($query) use ($search) {
                $query->where(function ($sub) use ($search) {
                    $sub->where('title', 'like', '%' . $search . '%')
                        ->orWhere('code', 'like', '%' . $search . '%')
                        ->orWhere('description', 'like', '%' . $search . '%')
                        ->orWhereHas('goal', function ($g) use ($search) {
                            $g->where('name', 'like', '%' . $search . '%');
                        });
                });
            })
            ->latest();
    }

    private function filteredGoalsQuery()
    {
        $search = trim($this->goalSearch);
        return OfferGoal::query()
            ->when($search !== '', function ($query) use ($search) {
                $query->where(function ($sub) use ($search) {
                    $sub->where('name', 'like', '%' . $search . '%')
                        ->orWhere('description', 'like', '%' . $search . '%')
                        ->orWhere('goal_type', 'like', '%' . $search . '%');
                });
            })
            ->latest();
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
        $campaigns = $this->filteredCampaignsQuery()->paginate($this->perPage, ['*'], 'campaignsPage');
        $goals = $this->filteredGoalsQuery()->paginate($this->perPage, ['*'], 'goalsPage');

        $activeTabItems = $this->activeTab === 'campaigns' ? $campaigns : $goals;

        return $this->view([
            'campaigns' => $campaigns,
            'goals' => $goals,
            'allGoals' => OfferGoal::orderBy('name')->get(),
            'totalCampaignsCount' => OfferCampaign::count(),
            'activeCampaignsCount' => OfferCampaign::where('is_active', true)->count(),
            'totalGoalsCount' => OfferGoal::count(),
            'activeGoalsCount' => OfferGoal::where('is_active', true)->count(),
            'activeTabItems' => $activeTabItems,
            'paginationItems' => $this->paginationItems($activeTabItems->currentPage(), $activeTabItems->lastPage()),
        ]);
    }
};
?>

<div class="space-y-6">
    <!-- Header Block -->
    <section class="flex flex-col xl:flex-row xl:items-end xl:justify-between gap-4">
        <div>
            <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-50 border border-emerald-100 text-emerald-700 text-[11px] font-extrabold uppercase tracking-widest">
                <i class="fa-solid fa-gift"></i>
                Promotional Oversight
            </div>
            <h1 class="mt-3 text-2xl sm:text-3xl font-black tracking-tight text-slate-900 font-poppins">Campaigns & Rewards</h1>
            <p class="mt-1 text-sm text-slate-500 font-medium max-w-2xl">Create and manage targeted user reward milestones, offer criteria, and discount coupons seamlessly.</p>
        </div>
        <div class="flex flex-col sm:flex-row gap-3">
            @if ($activeTab === 'campaigns')
                <button type="button" wire:click="openCampaignCreateModal" class="inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-extrabold shadow-md shadow-emerald-500/20 transition">
                    <i class="fa-solid fa-plus"></i>
                    New Campaign
                </button>
            @else
                <button type="button" wire:click="openGoalCreateModal" class="inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-extrabold shadow-md shadow-emerald-500/20 transition">
                    <i class="fa-solid fa-plus"></i>
                    New Goal
                </button>
            @endif
            <a href="{{ route('admin.dashboard') }}" class="inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-white border border-slate-200 text-slate-600 hover:text-emerald-700 hover:border-emerald-200 text-xs font-bold shadow-sm transition">
                <i class="fa-solid fa-arrow-left"></i>
                Dashboard
            </a>
        </div>
    </section>

    <!-- Metrics Cards -->
    <section class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        <div class="bg-white border border-slate-100 rounded-2xl p-5 shadow-sm flex items-center justify-between">
            <div>
                <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest">Total Campaigns</span>
                <strong class="mt-2 block text-3xl font-black text-slate-900 font-poppins">{{ $totalCampaignsCount }}</strong>
            </div>
            <div class="w-12 h-12 bg-emerald-50 text-emerald-700 rounded-xl flex items-center justify-center text-lg">
                <i class="fa-solid fa-tags"></i>
            </div>
        </div>
        <div class="bg-white border border-emerald-100 rounded-2xl p-5 shadow-sm flex items-center justify-between">
            <div>
                <span class="text-[10px] font-extrabold text-emerald-600 uppercase tracking-widest">Active Campaigns</span>
                <strong class="mt-2 block text-3xl font-black text-emerald-700 font-poppins">{{ $activeCampaignsCount }}</strong>
            </div>
            <div class="w-12 h-12 bg-emerald-50 text-emerald-700 rounded-xl flex items-center justify-center text-lg">
                <i class="fa-solid fa-circle-check"></i>
            </div>
        </div>
        <div class="bg-white border border-slate-100 rounded-2xl p-5 shadow-sm flex items-center justify-between">
            <div>
                <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest">Goal Milestones</span>
                <strong class="mt-2 block text-3xl font-black text-slate-900 font-poppins">{{ $totalGoalsCount }}</strong>
            </div>
            <div class="w-12 h-12 bg-indigo-50 text-indigo-700 rounded-xl flex items-center justify-center text-lg">
                <i class="fa-solid fa-bullseye"></i>
            </div>
        </div>
        <div class="bg-white border border-indigo-100 rounded-2xl p-5 shadow-sm flex items-center justify-between">
            <div>
                <span class="text-[10px] font-extrabold text-indigo-600 uppercase tracking-widest">Active Goals</span>
                <strong class="mt-2 block text-3xl font-black text-indigo-700 font-poppins">{{ $activeGoalsCount }}</strong>
            </div>
            <div class="w-12 h-12 bg-indigo-50 text-indigo-700 rounded-xl flex items-center justify-center text-lg">
                <i class="fa-solid fa-chart-line"></i>
            </div>
        </div>
    </section>

    <!-- Tabbed Navigation -->
    <div class="border-b border-slate-200">
        <nav class="flex space-x-6" aria-label="Tabs">
            <button type="button" wire:click="$set('activeTab', 'campaigns')" class="pb-4 px-1 border-b-2 font-poppins text-sm font-extrabold transition-all {{ $activeTab === 'campaigns' ? 'border-emerald-600 text-emerald-700' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300' }}">
                Offer Campaigns
            </button>
            <button type="button" wire:click="$set('activeTab', 'goals')" class="pb-4 px-1 border-b-2 font-poppins text-sm font-extrabold transition-all {{ $activeTab === 'goals' ? 'border-emerald-600 text-emerald-700' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300' }}">
                Offer Goals
            </button>
        </nav>
    </div>

    <!-- Data Panel -->
    <section class="bg-white border border-slate-100 rounded-2xl shadow-sm overflow-hidden">
        <div class="p-5 sm:p-6 border-b border-slate-100 space-y-4">
            <div class="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
                <div>
                    <h2 class="text-base font-extrabold text-slate-900 font-poppins">
                        {{ $activeTab === 'campaigns' ? 'Reward Campaign Catalog' : 'Goal Milestones Catalog' }}
                    </h2>
                    <p class="text-xs text-slate-500 font-medium">All adjustments happen instantly via Livewire. Search and paginate securely.</p>
                </div>
                <div wire:loading class="text-xs font-extrabold text-emerald-700 bg-emerald-50 border border-emerald-100 rounded-full px-3 py-1">
                    Syncing...
                </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-[minmax(0,1fr)_150px] gap-3">
                <div class="relative">
                    <i class="fa-solid fa-magnifying-glass absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 text-sm"></i>
                    @if ($activeTab === 'campaigns')
                        <input wire:model.live.debounce.350ms="search" class="w-full rounded-xl border border-slate-200 bg-slate-50 pl-10 pr-4 py-3 text-sm font-semibold outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition" placeholder="Search campaign title, code, description, or goal">
                    @else
                        <input wire:model.live.debounce.350ms="goalSearch" class="w-full rounded-xl border border-slate-200 bg-slate-50 pl-10 pr-4 py-3 text-sm font-semibold outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition" placeholder="Search goal name, type, description">
                    @endif
                </div>
                <select wire:model.live="perPage" class="rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-bold text-slate-700 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition">
                    @foreach ([10, 25, 50, 100] as $size)
                        <option value="{{ $size }}">{{ $size }} / page</option>
                    @endforeach
                </select>
            </div>
        </div>

        <div class="overflow-x-auto">
            @if ($activeTab === 'campaigns')
                <!-- CAMPAIGNS TABLE -->
                <table class="min-w-full divide-y divide-slate-100">
                    <thead class="bg-slate-50">
                        <tr>
                            <th class="px-5 py-3 text-left text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Campaign</th>
                            <th class="px-5 py-3 text-left text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Reward Criteria</th>
                            <th class="px-5 py-3 text-left text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Target Segment</th>
                            <th class="px-5 py-3 text-left text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Validity</th>
                            <th class="px-5 py-3 text-left text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Status</th>
                            <th class="px-5 py-3 text-right text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Actions</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100 bg-white">
                        @forelse ($activeTabItems as $campaign)
                            <tr class="align-middle hover:bg-slate-50/70 transition" wire:key="campaign-row-{{ $campaign->id }}">
                                <td class="px-5 py-4 min-w-[280px]">
                                    <div class="flex items-center gap-3">
                                        <div class="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-700 border border-emerald-100 flex items-center justify-center shrink-0">
                                            <i class="fa-solid fa-tag text-sm"></i>
                                        </div>
                                        <div>
                                            <p class="text-sm font-extrabold text-slate-900">{{ $campaign->title }}</p>
                                            <div class="flex items-center gap-2 mt-1">
                                                <span class="px-2 py-0.5 rounded bg-slate-100 border border-slate-200 text-[10px] font-mono font-bold text-slate-600">{{ $campaign->code }}</span>
                                                <span class="text-[10px] text-slate-400">Goal: {{ $campaign->goal->name ?? 'No Goal Linked' }}</span>
                                            </div>
                                        </div>
                                    </div>
                                </td>
                                <td class="px-5 py-4 min-w-[200px]">
                                    @if ($campaign->type === 'percentage')
                                        <p class="text-xs font-extrabold text-emerald-700 bg-emerald-50 border border-emerald-100 rounded-lg px-2.5 py-1 inline-block">
                                            {{ floatval($campaign->discount_percentage) }}% Off
                                        </p>
                                        @if ($campaign->max_discount_amount)
                                            <p class="text-[10px] text-slate-400 mt-1 font-semibold">Max Cap: LKR {{ number_format($campaign->max_discount_amount, 2) }}</p>
                                        @endif
                                    @elseif ($campaign->type === 'fixed_amount')
                                        <p class="text-xs font-extrabold text-slate-800 bg-slate-100 border border-slate-200 rounded-lg px-2.5 py-1 inline-block">
                                            LKR {{ number_format($campaign->discount_amount, 2) }} Off
                                        </p>
                                    @else
                                        <p class="text-xs font-extrabold text-blue-700 bg-blue-50 border border-blue-100 rounded-lg px-2.5 py-1 inline-block">
                                            Free Shipping
                                        </p>
                                    @endif
                                    <p class="text-[10px] text-slate-500 font-semibold mt-1">Min Completions: {{ $campaign->minimum_completion_count }}</p>
                                </td>
                                <td class="px-5 py-4 min-w-[150px]">
                                    <span class="inline-flex items-center rounded-lg bg-emerald-50 border border-emerald-100 px-2.5 py-1 text-[10px] font-extrabold text-emerald-700 uppercase tracking-wider">
                                        {{ str_replace('_', ' ', $campaign->applied_user_role) }}
                                    </span>
                                    @if ($campaign->total_usage_limit)
                                        <p class="text-[10px] text-slate-400 font-semibold mt-1">Limit: {{ $campaign->total_usage_limit }} (Per User: {{ $campaign->usage_limit_per_user ?? '∞' }})</p>
                                    @endif
                                </td>
                                <td class="px-5 py-4 min-w-[200px]">
                                    <p class="text-xs font-semibold text-slate-700">From: {{ $campaign->valid_from->format('M d, Y H:i') }}</p>
                                    <p class="text-xs font-semibold text-slate-500 mt-0.5">Until: {{ $campaign->valid_until->format('M d, Y H:i') }}</p>
                                    @if ($campaign->valid_until->isPast())
                                        <span class="text-[9px] font-extrabold text-rose-600 bg-rose-50 border border-rose-100 px-1.5 py-0.5 rounded uppercase tracking-wider mt-1 inline-block">Expired</span>
                                    @endif
                                </td>
                                <td class="px-5 py-4 min-w-[100px]">
                                    <button type="button" wire:click="toggleCampaignActive({{ $campaign->id }})" class="inline-flex items-center rounded-full border px-2.5 py-0.5 text-[10px] font-extrabold uppercase tracking-wider transition-all {{ $campaign->is_active ? 'bg-emerald-50 text-emerald-700 border-emerald-100 hover:bg-emerald-100' : 'bg-slate-50 text-slate-400 border-slate-200 hover:bg-slate-100' }}">
                                        {{ $campaign->is_active ? 'Active' : 'Inactive' }}
                                    </button>
                                </td>
                                <td class="px-5 py-4 min-w-[200px] text-right">
                                    <div class="flex items-center justify-end gap-2">
                                        <button type="button" wire:click="openCampaignEditModal({{ $campaign->id }})" class="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 text-[11px] font-extrabold transition">
                                            <i class="fa-solid fa-pen text-[9px]"></i> Edit
                                        </button>
                                        <button type="button" wire:click="$dispatch('confirm-campaign-delete', { campaignId: {{ $campaign->id }}, title: @js($campaign->title) })" class="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-lg bg-slate-50 hover:bg-rose-50 border border-slate-100 hover:border-rose-100 text-slate-500 hover:text-rose-700 text-[11px] font-extrabold transition">
                                            <i class="fa-solid fa-trash text-[9px]"></i> Delete
                                        </button>
                                    </div>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="6" class="px-5 py-12 text-center">
                                    <div class="mx-auto w-12 h-12 rounded-2xl bg-slate-100 text-slate-400 flex items-center justify-center">
                                        <i class="fa-solid fa-magnifying-glass"></i>
                                    </div>
                                    <p class="mt-4 text-sm font-extrabold text-slate-700 font-poppins">No campaigns found</p>
                                    <p class="mt-1 text-xs text-slate-500 font-medium">Reset your filters or add a new campaign to begin.</p>
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            @else
                <!-- GOALS TABLE -->
                <table class="min-w-full divide-y divide-slate-100">
                    <thead class="bg-slate-50">
                        <tr>
                            <th class="px-5 py-3 text-left text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Goal Milestone</th>
                            <th class="px-5 py-3 text-left text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Goal Type</th>
                            <th class="px-5 py-3 text-left text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Target Requirement</th>
                            <th class="px-5 py-3 text-left text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Status</th>
                            <th class="px-5 py-3 text-right text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Actions</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100 bg-white">
                        @forelse ($activeTabItems as $goal)
                            <tr class="align-middle hover:bg-slate-50/70 transition" wire:key="goal-row-{{ $goal->id }}">
                                <td class="px-5 py-4 min-w-[280px]">
                                    <div class="flex items-center gap-3">
                                        <div class="w-10 h-10 rounded-xl bg-indigo-50 text-indigo-700 border border-indigo-100 flex items-center justify-center shrink-0">
                                            <i class="fa-solid fa-bullseye text-sm"></i>
                                        </div>
                                        <div>
                                            <p class="text-sm font-extrabold text-slate-900">{{ $goal->name }}</p>
                                            <p class="text-xs text-slate-400 mt-1 line-clamp-1 max-w-sm">{{ $goal->description ?? 'No description provided.' }}</p>
                                        </div>
                                    </div>
                                </td>
                                <td class="px-5 py-4 min-w-[180px]">
                                    <span class="inline-flex items-center rounded-lg bg-slate-100 border border-slate-200 px-2.5 py-1 text-[10px] font-mono font-extrabold text-slate-600">
                                        {{ $goal->goal_type }}
                                    </span>
                                </td>
                                <td class="px-5 py-4 min-w-[180px]">
                                    <p class="text-sm font-black text-slate-800">{{ floatval($goal->target_value) }}</p>
                                    <p class="text-[10px] text-slate-400 font-semibold mt-0.5">Threshold units required</p>
                                </td>
                                <td class="px-5 py-4 min-w-[100px]">
                                    <button type="button" wire:click="toggleGoalActive({{ $goal->id }})" class="inline-flex items-center rounded-full border px-2.5 py-0.5 text-[10px] font-extrabold uppercase tracking-wider transition-all {{ $goal->is_active ? 'bg-emerald-50 text-emerald-700 border-emerald-100 hover:bg-emerald-100' : 'bg-slate-50 text-slate-400 border-slate-200 hover:bg-slate-100' }}">
                                        {{ $goal->is_active ? 'Active' : 'Inactive' }}
                                    </button>
                                </td>
                                <td class="px-5 py-4 min-w-[200px] text-right">
                                    <div class="flex items-center justify-end gap-2">
                                        <button type="button" wire:click="openGoalEditModal({{ $goal->id }})" class="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 text-[11px] font-extrabold transition">
                                            <i class="fa-solid fa-pen text-[9px]"></i> Edit
                                        </button>
                                        <button type="button" wire:click="$dispatch('confirm-goal-delete', { goalId: {{ $goal->id }}, name: @js($goal->name) })" class="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-lg bg-slate-50 hover:bg-rose-50 border border-slate-100 hover:border-rose-100 text-slate-500 hover:text-rose-700 text-[11px] font-extrabold transition">
                                            <i class="fa-solid fa-trash text-[9px]"></i> Delete
                                        </button>
                                    </div>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="5" class="px-5 py-12 text-center">
                                    <div class="mx-auto w-12 h-12 rounded-2xl bg-slate-100 text-slate-400 flex items-center justify-center">
                                        <i class="fa-solid fa-magnifying-glass"></i>
                                    </div>
                                    <p class="mt-4 text-sm font-extrabold text-slate-700 font-poppins">No goals found</p>
                                    <p class="mt-1 text-xs text-slate-500 font-medium">Reset your filters or add a new goal milestone to begin.</p>
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            @endif
        </div>

        <!-- Pagination Footer -->
        <div class="p-5 sm:p-6 border-t border-slate-100 flex flex-col xl:flex-row xl:items-center xl:justify-between gap-4">
            <p class="text-xs text-slate-500 font-semibold">
                Showing <span class="font-extrabold text-slate-800">{{ $activeTabItems->firstItem() ?? 0 }}</span> to <span class="font-extrabold text-slate-800">{{ $activeTabItems->lastItem() ?? 0 }}</span> of <span class="font-extrabold text-slate-800">{{ $activeTabItems->total() }}</span> records
            </p>

            <div class="flex flex-col sm:flex-row sm:items-center gap-3">
                <form wire:submit="goToTypedPage" class="flex items-center gap-2">
                    <label class="text-xs font-bold text-slate-500">Go to</label>
                    <input wire:model="pageInput" type="number" min="1" max="{{ $activeTabItems->lastPage() }}" class="w-20 rounded-lg border border-slate-200 px-3 py-2 text-xs font-extrabold text-slate-700 outline-none focus:border-emerald-400 focus:ring-4 focus:ring-emerald-100">
                    <button class="rounded-lg bg-slate-900 hover:bg-emerald-700 text-white px-3 py-2 text-xs font-extrabold transition">Go</button>
                </form>

                @if ($activeTabItems->hasPages())
                    <div class="flex flex-wrap items-center gap-2">
                        <button type="button" wire:click="setPage(1, '{{ $activeTab === 'campaigns' ? 'campaignsPage' : 'goalsPage' }}')" @disabled($activeTabItems->onFirstPage()) class="px-3 py-2 rounded-lg border border-slate-200 text-xs font-bold disabled:pointer-events-none disabled:opacity-40 hover:border-emerald-200 hover:text-emerald-700">First</button>
                        <button type="button" wire:click="previousPage('{{ $activeTab === 'campaigns' ? 'campaignsPage' : 'goalsPage' }}')" @disabled($activeTabItems->onFirstPage()) class="px-3 py-2 rounded-lg border border-slate-200 text-xs font-bold disabled:pointer-events-none disabled:opacity-40 hover:border-emerald-200 hover:text-emerald-700">Prev</button>
                        @foreach ($paginationItems as $item)
                            @if ($item === '...')
                                <span class="px-2 py-2 text-xs font-black text-slate-300">...</span>
                            @else
                                <button type="button" wire:click="setPage({{ $item }}, '{{ $activeTab === 'campaigns' ? 'campaignsPage' : 'goalsPage' }}')" class="min-w-9 text-center px-3 py-2 rounded-lg border text-xs font-extrabold {{ $item === $activeTabItems->currentPage() ? 'bg-emerald-600 border-emerald-600 text-white' : 'border-slate-200 text-slate-600 hover:border-emerald-200 hover:text-emerald-700' }}">{{ $item }}</button>
                            @endif
                        @endforeach
                        <button type="button" wire:click="nextPage('{{ $activeTab === 'campaigns' ? 'campaignsPage' : 'goalsPage' }}')" @disabled(!$activeTabItems->hasMorePages()) class="px-3 py-2 rounded-lg border border-slate-200 text-xs font-bold disabled:pointer-events-none disabled:opacity-40 hover:border-emerald-200 hover:text-emerald-700">Next</button>
                        <button type="button" wire:click="setPage({{ $activeTabItems->lastPage() }}, '{{ $activeTab === 'campaigns' ? 'campaignsPage' : 'goalsPage' }}')" @disabled($activeTabItems->currentPage() === $activeTabItems->lastPage()) class="px-3 py-2 rounded-lg border border-slate-200 text-xs font-bold disabled:pointer-events-none disabled:opacity-40 hover:border-emerald-200 hover:text-emerald-700">Last</button>
                    </div>
                @endif
            </div>
        </div>
    </section>

    <!-- CAMPAIGN MODAL -->
    @if ($showCampaignModal)
        <div class="fixed left-0 top-0 z-[9999] flex h-screen w-screen items-center justify-center p-4" style="inset: 0; width: 100vw; height: 100vh;" aria-modal="true">
            <button type="button" wire:click="$set('showCampaignModal', false)" class="absolute inset-0 h-full w-full bg-slate-950/60 backdrop-blur-sm"></button>
            <div class="relative w-full max-w-2xl bg-white rounded-2xl shadow-2xl border border-slate-100 overflow-hidden">
                <div class="p-5 border-b border-slate-100 flex items-start justify-between gap-4">
                    <div>
                        <h2 class="text-lg font-extrabold text-slate-900 font-poppins">{{ $editingCampaignId ? 'Edit Campaign' : 'Create Campaign' }}</h2>
                        <p class="text-xs text-slate-500 font-semibold mt-1">Configure user promotion campaign mapping and rewards.</p>
                    </div>
                    <button type="button" wire:click="$set('showCampaignModal', false)" class="w-9 h-9 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-500 transition">
                        <i class="fa-solid fa-xmark"></i>
                    </button>
                </div>
                <form wire:submit="saveCampaign" class="p-5 space-y-4 max-h-[75vh] overflow-y-auto">
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <!-- Goal Selection -->
                        <div class="md:col-span-2">
                            <label class="block text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-2 font-poppins">Linked Offer Goal Milestone</label>
                            <select wire:model="offer_goal_id" required class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-semibold text-slate-700 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition">
                                <option value="">Select a goal</option>
                                @foreach ($allGoals as $g)
                                    <option value="{{ $g->id }}">{{ $g->name }} ({{ $g->goal_type }})</option>
                                @endforeach
                            </select>
                            @error('offer_goal_id') <p class="mt-2 text-xs font-bold text-rose-600">{{ $message }}</p> @enderror
                        </div>

                        <!-- Title -->
                        <div>
                            <label class="block text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-2 font-poppins">Campaign Title</label>
                            <input wire:model="title" required maxlength="255" class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-semibold text-slate-800 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition" placeholder="e.g. Farmer Harvest Boost">
                            @error('title') <p class="mt-2 text-xs font-bold text-rose-600">{{ $message }}</p> @enderror
                        </div>

                        <!-- Code -->
                        <div>
                            <label class="block text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-2 font-poppins">Promo Code (Unique)</label>
                            <input wire:model="code" required maxlength="255" class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-semibold text-slate-800 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition" placeholder="e.g. HARVEST20">
                            @error('code') <p class="mt-2 text-xs font-bold text-rose-600">{{ $message }}</p> @enderror
                        </div>

                        <!-- Description -->
                        <div class="md:col-span-2">
                            <label class="block text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-2 font-poppins">Campaign Description</label>
                            <textarea wire:model="description" rows="2" class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-semibold text-slate-800 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition" placeholder="Provide a brief explanation of how to unlock this campaign..."></textarea>
                            @error('description') <p class="mt-2 text-xs font-bold text-rose-600">{{ $message }}</p> @enderror
                        </div>

                        <!-- Type -->
                        <div>
                            <label class="block text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-2 font-poppins">Reward Type</label>
                            <select wire:model.live="type" required class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-semibold text-slate-700 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition">
                                <option value="percentage">Percentage Discount</option>
                                <option value="fixed_amount">Fixed Amount Discount</option>
                                <option value="free_shipping">Free Shipping</option>
                            </select>
                            @error('type') <p class="mt-2 text-xs font-bold text-rose-600">{{ $message }}</p> @enderror
                        </div>

                        <!-- Target Segment -->
                        <div>
                            <label class="block text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-2 font-poppins">Applied User Role</label>
                            <select wire:model="applied_user_role" required class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-semibold text-slate-700 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition">
                                @foreach (\App\Models\OfferCampaign::APPLIED_USER_ROLES as $role)
                                    <option value="{{ $role }}">{{ ucwords(str_replace('_', ' ', $role)) }}</option>
                                @endforeach
                            </select>
                            @error('applied_user_role') <p class="mt-2 text-xs font-bold text-rose-600">{{ $message }}</p> @enderror
                        </div>

                        <!-- Reward Fields (Dynamic) -->
                        @if ($type === 'percentage')
                            <div>
                                <label class="block text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-2 font-poppins">Discount Percentage (%)</label>
                                <input wire:model="discount_percentage" type="number" step="0.01" min="0" max="100" required class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-semibold text-slate-800 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition" placeholder="e.g. 15.00">
                                @error('discount_percentage') <p class="mt-2 text-xs font-bold text-rose-600">{{ $message }}</p> @enderror
                            </div>
                            <div>
                                <label class="block text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-2 font-poppins">Maximum Discount Limit (LKR)</label>
                                <input wire:model="max_discount_amount" type="number" step="0.01" min="0" class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-semibold text-slate-800 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition" placeholder="e.g. 2000.00 (Optional)">
                                @error('max_discount_amount') <p class="mt-2 text-xs font-bold text-rose-600">{{ $message }}</p> @enderror
                            </div>
                        @elseif ($type === 'fixed_amount')
                            <div>
                                <label class="block text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-2 font-poppins">Discount Amount (LKR)</label>
                                <input wire:model="discount_amount" type="number" step="0.01" min="0" required class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-semibold text-slate-800 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition" placeholder="e.g. 500.00">
                                @error('discount_amount') <p class="mt-2 text-xs font-bold text-rose-600">{{ $message }}</p> @enderror
                            </div>
                        @endif

                        <!-- Min completion count -->
                        <div>
                            <label class="block text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-2 font-poppins">Min Completion Count to Unlock</label>
                            <input wire:model="minimum_completion_count" type="number" min="1" required class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-semibold text-slate-800 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition" placeholder="e.g. 1">
                            @error('minimum_completion_count') <p class="mt-2 text-xs font-bold text-rose-600">{{ $message }}</p> @enderror
                        </div>

                        <!-- Active boolean -->
                        <div>
                            <label class="block text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-2 font-poppins">Active Status</label>
                            <select wire:model="is_active" required class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-semibold text-slate-700 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition">
                                <option value="1">Active</option>
                                <option value="0">Inactive</option>
                            </select>
                            @error('is_active') <p class="mt-2 text-xs font-bold text-rose-600">{{ $message }}</p> @enderror
                        </div>

                        <!-- Usage Limits -->
                        <div>
                            <label class="block text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-2 font-poppins">Usage Limit Per User</label>
                            <input wire:model="usage_limit_per_user" type="number" min="1" class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-semibold text-slate-800 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition" placeholder="e.g. 1 (Optional)">
                            @error('usage_limit_per_user') <p class="mt-2 text-xs font-bold text-rose-600">{{ $message }}</p> @enderror
                        </div>
                        <div>
                            <label class="block text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-2 font-poppins">Total Usage Limit</label>
                            <input wire:model="total_usage_limit" type="number" min="1" class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-semibold text-slate-800 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition" placeholder="e.g. 500 (Optional)">
                            @error('total_usage_limit') <p class="mt-2 text-xs font-bold text-rose-600">{{ $message }}</p> @enderror
                        </div>

                        <!-- Validity Dates -->
                        <div>
                            <label class="block text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-2 font-poppins">Valid From</label>
                            <input wire:model="valid_from" type="datetime-local" required class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-semibold text-slate-800 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition">
                            @error('valid_from') <p class="mt-2 text-xs font-bold text-rose-600">{{ $message }}</p> @enderror
                        </div>
                        <div>
                            <label class="block text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-2 font-poppins">Valid Until</label>
                            <input wire:model="valid_until" type="datetime-local" required class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-semibold text-slate-800 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition">
                            @error('valid_until') <p class="mt-2 text-xs font-bold text-rose-600">{{ $message }}</p> @enderror
                        </div>
                    </div>

                    <button type="submit" wire:loading.attr="disabled" class="mt-4 w-full inline-flex items-center justify-center gap-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 disabled:opacity-60 text-white px-4 py-3 text-sm font-extrabold shadow-md shadow-emerald-500/20 transition">
                        <i class="fa-solid fa-floppy-disk"></i>
                        Save Campaign
                    </button>
                </form>
            </div>
        </div>
    @endif

    <!-- GOAL MODAL -->
    @if ($showGoalModal)
        <div class="fixed left-0 top-0 z-[9999] flex h-screen w-screen items-center justify-center p-4" style="inset: 0; width: 100vw; height: 100vh;" aria-modal="true">
            <button type="button" wire:click="$set('showGoalModal', false)" class="absolute inset-0 h-full w-full bg-slate-950/60 backdrop-blur-sm"></button>
            <div class="relative w-full max-w-lg bg-white rounded-2xl shadow-2xl border border-slate-100 overflow-hidden">
                <div class="p-5 border-b border-slate-100 flex items-start justify-between gap-4">
                    <div>
                        <h2 class="text-lg font-extrabold text-slate-900 font-poppins">{{ $editingGoalId ? 'Edit Goal' : 'Create Goal' }}</h2>
                        <p class="text-xs text-slate-500 font-semibold mt-1">Configure target goal requirements for campaigns.</p>
                    </div>
                    <button type="button" wire:click="$set('showGoalModal', false)" class="w-9 h-9 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-500 transition">
                        <i class="fa-solid fa-xmark"></i>
                    </button>
                </div>
                <form wire:submit="saveGoal" class="p-5 space-y-4">
                    <!-- Name -->
                    <div>
                        <label class="block text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-2 font-poppins">Goal Name</label>
                        <input wire:model="goal_name" required maxlength="255" class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-semibold text-slate-800 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition" placeholder="e.g. Farmer Five Sales Target">
                        @error('goal_name') <p class="mt-2 text-xs font-bold text-rose-600">{{ $message }}</p> @enderror
                    </div>

                    <!-- Description -->
                    <div>
                        <label class="block text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-2 font-poppins">Goal Description</label>
                        <textarea wire:model="goal_description" rows="2" class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-semibold text-slate-800 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition" placeholder="e.g. Reward farmers who achieve a target of 5 successful completed sales."></textarea>
                        @error('goal_description') <p class="mt-2 text-xs font-bold text-rose-600">{{ $message }}</p> @enderror
                    </div>

                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        <!-- Goal Type -->
                        <div>
                            <label class="block text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-2 font-poppins">Goal Metric Type</label>
                            <select wire:model="goal_type" required class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-semibold text-slate-700 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition">
                                @foreach (\App\Models\OfferGoal::GOAL_TYPES as $gType)
                                    <option value="{{ $gType }}">{{ ucwords(str_replace('_', ' ', $gType)) }}</option>
                                @endforeach
                            </select>
                            @error('goal_type') <p class="mt-2 text-xs font-bold text-rose-600">{{ $message }}</p> @enderror
                        </div>

                        <!-- Target Value -->
                        <div>
                            <label class="block text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-2 font-poppins">Target Value</label>
                            <input wire:model="goal_target_value" type="number" step="0.01" min="0" required class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-semibold text-slate-800 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition" placeholder="e.g. 5.00">
                            @error('goal_target_value') <p class="mt-2 text-xs font-bold text-rose-600">{{ $message }}</p> @enderror
                        </div>
                    </div>

                    <!-- Active status -->
                    <div>
                        <label class="block text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-2 font-poppins">Active Status</label>
                        <select wire:model="goal_is_active" required class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-semibold text-slate-700 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition">
                            <option value="1">Active</option>
                            <option value="0">Inactive</option>
                        </select>
                        @error('goal_is_active') <p class="mt-2 text-xs font-bold text-rose-600">{{ $message }}</p> @enderror
                    </div>

                    <button type="submit" wire:loading.attr="disabled" class="w-full inline-flex items-center justify-center gap-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 disabled:opacity-60 text-white px-4 py-3 text-sm font-extrabold shadow-md shadow-emerald-500/20 transition">
                        <i class="fa-solid fa-floppy-disk"></i>
                        Save Goal
                    </button>
                </form>
            </div>
        </div>
    @endif
</div>
