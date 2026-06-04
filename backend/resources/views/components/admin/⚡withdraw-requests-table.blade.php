<?php

use App\Models\WithdrawRequest;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Livewire\Component;
use Livewire\WithPagination;

new class extends Component
{
    use WithPagination;

    public string $search = '';
    public string $status = 'all';
    public int $perPage = 10;
    public string $pageInput = '1';

    // Modal state
    public bool $showPayModal = false;
    public bool $showRejectModal = false;
    public bool $showDetailsModal = false;

    // Form inputs
    public ?int $selectedRequestId = null;
    public $selectedRequestDetails = null;
    public string $transactionReference = '';
    public string $adminNote = '';
    public string $rejectionReason = '';

    protected array $queryString = [
        'search' => ['except' => ''],
        'status' => ['except' => 'all'],
        'perPage' => ['except' => 10, 'as' => 'per_page'],
        'page' => ['except' => 1],
    ];

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

    public function setStatusProcessing(int $id): void
    {
        $req = WithdrawRequest::findOrFail($id);
        if ($req->status !== 'pending') {
            $this->dispatch('withdrawal-failed', message: 'Only pending requests can be marked as processing.');
            return;
        }

        $req->update([
            'status' => 'processing',
            'updated_at' => now(),
        ]);

        $this->dispatch('withdrawal-saved', message: 'Withdrawal status updated to processing.');
    }

    public function openPayModal(int $id): void
    {
        $req = WithdrawRequest::findOrFail($id);
        $this->selectedRequestId = $id;
        $this->transactionReference = '';
        $this->adminNote = '';
        $this->showPayModal = true;
    }

    public function openRejectModal(int $id): void
    {
        $req = WithdrawRequest::findOrFail($id);
        $this->selectedRequestId = $id;
        $this->rejectionReason = '';
        $this->adminNote = '';
        $this->showRejectModal = true;
    }

    public function openDetailsModal(int $id): void
    {
        $this->selectedRequestDetails = WithdrawRequest::with(['user', 'reviewedAdmin'])->findOrFail($id);
        $this->showDetailsModal = true;
    }

    public function closeModals(): void
    {
        $this->showPayModal = false;
        $this->showRejectModal = false;
        $this->showDetailsModal = false;
        $this->selectedRequestId = null;
        $this->selectedRequestDetails = null;
        $this->resetValidation();
    }

    public function payRequest(): void
    {
        $this->validate([
            'transactionReference' => 'required|string|max:255',
            'adminNote' => 'nullable|string|max:1000',
        ]);

        $req = WithdrawRequest::findOrFail($this->selectedRequestId);
        if (!in_array($req->status, ['pending', 'processing'])) {
            $this->dispatch('withdrawal-failed', message: 'This request cannot be paid.');
            return;
        }

        DB::beginTransaction();
        try {
            // Update request
            $req->update([
                'status' => 'paid',
                'reviewed_admin_id' => session('admin_session.user_id') ?? Auth::id(),
                'reviewed_at' => now(),
                'paid_at' => now(),
                'transaction_reference' => $this->transactionReference,
                'admin_note' => $this->adminNote,
                'updated_at' => now(),
            ]);

            // Deduct from pending_balance, add to total_withdrawn in wallet
            DB::table('user_wallets')
                ->where('user_id', $req->user_id)
                ->update([
                    'pending_balance' => DB::raw('pending_balance - ' . $req->request_amount),
                    'total_withdrawn' => DB::raw('total_withdrawn + ' . $req->request_amount),
                    'last_updated_at' => now(),
                    'updated_at' => now(),
                ]);

            // Update matching pending transaction
            $tx = DB::table('wallet_transactions')
                ->where('user_id', $req->user_id)
                ->where('transaction_type', 'withdrawal')
                ->where('amount', -$req->request_amount)
                ->where('status', 'pending')
                ->orderBy('created_at', 'desc')
                ->first();

            if ($tx) {
                DB::table('wallet_transactions')
                    ->where('id', $tx->id)
                    ->update([
                        'status' => 'completed',
                        'description' => 'Withdrawal completed. Ref: ' . $this->transactionReference,
                        'updated_at' => now(),
                    ]);
            }

            DB::commit();
            $this->closeModals();
            $this->dispatch('withdrawal-saved', message: 'Withdrawal marked as paid and wallet updated.');
        } catch (\Exception $e) {
            DB::rollBack();
            $this->dispatch('withdrawal-failed', message: 'Failed to complete payout: ' . $e->getMessage());
        }
    }

    public function rejectRequest(): void
    {
        $this->validate([
            'rejectionReason' => 'required|string|max:1000',
            'adminNote' => 'nullable|string|max:1000',
        ]);

        $req = WithdrawRequest::findOrFail($this->selectedRequestId);
        if (!in_array($req->status, ['pending', 'processing'])) {
            $this->dispatch('withdrawal-failed', message: 'This request cannot be rejected.');
            return;
        }

        DB::beginTransaction();
        try {
            // Update request
            $req->update([
                'status' => 'rejected',
                'reviewed_admin_id' => session('admin_session.user_id') ?? Auth::id(),
                'reviewed_at' => now(),
                'rejection_reason' => $this->rejectionReason,
                'admin_note' => $this->adminNote,
                'updated_at' => now(),
            ]);

            // Return funds from pending_balance back to available_balance
            DB::table('user_wallets')
                ->where('user_id', $req->user_id)
                ->update([
                    'available_balance' => DB::raw('available_balance + ' . $req->request_amount),
                    'pending_balance' => DB::raw('pending_balance - ' . $req->request_amount),
                    'last_updated_at' => now(),
                    'updated_at' => now(),
                ]);

            // Update matching pending transaction to failed
            $tx = DB::table('wallet_transactions')
                ->where('user_id', $req->user_id)
                ->where('transaction_type', 'withdrawal')
                ->where('amount', -$req->request_amount)
                ->where('status', 'pending')
                ->orderBy('created_at', 'desc')
                ->first();

            if ($tx) {
                DB::table('wallet_transactions')
                    ->where('id', $tx->id)
                    ->update([
                        'status' => 'failed',
                        'description' => 'Withdrawal rejected: ' . $this->rejectionReason,
                        'updated_at' => now(),
                    ]);
            }

            DB::commit();
            $this->closeModals();
            $this->dispatch('withdrawal-saved', message: 'Withdrawal rejected and funds refunded to wallet.');
        } catch (\Exception $e) {
            DB::rollBack();
            $this->dispatch('withdrawal-failed', message: 'Failed to reject withdrawal: ' . $e->getMessage());
        }
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

        return WithdrawRequest::query()
            ->with(['user'])
            ->when($search !== '', function ($query) use ($search) {
                $query->where(function ($subQuery) use ($search) {
                    $subQuery->where('bank_name', 'like', '%' . $search . '%')
                        ->orWhere('bank_account_holder_name', 'like', '%' . $search . '%')
                        ->orWhere('bank_account_number', 'like', '%' . $search . '%')
                        ->orWhereHas('user', function ($userQuery) use ($search) {
                            $userQuery->where('full_name', 'like', '%' . $search . '%')
                                ->orWhere('email', 'like', '%' . $search . '%');
                        });
                });
            })
            ->when($this->status !== 'all', fn ($query) => $query->where('status', $this->status))
            ->orderByRaw("CASE status WHEN 'pending' THEN 1 WHEN 'processing' THEN 2 WHEN 'paid' THEN 3 ELSE 4 END")
            ->latest();
    }

    private function statusCounts()
    {
        return WithdrawRequest::selectRaw('status, COUNT(*) as total')
            ->groupBy('status')
            ->pluck('total', 'status');
    }

    private function totalAmountPaid()
    {
        return WithdrawRequest::where('status', 'paid')->sum('request_amount');
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
        $withdrawals = $this->filteredQuery()->paginate($this->perPage);
        $statusCounts = $this->statusCounts();

        return $this->view([
            'withdrawals' => $withdrawals,
            'statusCounts' => $statusCounts,
            'totalCount' => WithdrawRequest::count(),
            'totalPaidSum' => $this->totalAmountPaid(),
            'paginationItems' => $this->paginationItems($withdrawals->currentPage(), $withdrawals->lastPage()),
        ]);
    }
};
?>

<div class="space-y-6">
    <!-- Header Block -->
    <section class="flex flex-col xl:flex-row xl:items-end xl:justify-between gap-4">
        <div>
            <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-50 border border-emerald-100 text-emerald-700 text-[11px] font-extrabold uppercase tracking-widest">
                <i class="fa-solid fa-landmark"></i>
                Treasury Payout Pipeline
            </div>
            <h1 class="mt-3 text-2xl sm:text-3xl font-black tracking-tight text-slate-900 font-poppins">Withdrawal Requests</h1>
            <p class="mt-1 text-sm text-slate-500 font-medium max-w-2xl">Review, manage, approve, process, and record payouts to Aswenna delivery partner bank accounts.</p>
        </div>
        <div class="flex flex-col sm:flex-row gap-3">
            <a href="{{ route('admin.dashboard') }}" class="inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-white border border-slate-200 text-slate-600 hover:text-emerald-700 hover:border-emerald-200 text-xs font-bold shadow-sm transition">
                <i class="fa-solid fa-arrow-left"></i>
                Dashboard
            </a>
        </div>
    </section>

    <!-- KPI Summary Block -->
    <section class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        <div class="bg-white border border-slate-100 rounded-2xl p-5 shadow-sm">
            <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest">All Requests</span>
            <strong class="mt-2 block text-3xl font-black text-slate-900">{{ $totalCount }}</strong>
        </div>
        <div class="bg-white border border-amber-100 rounded-2xl p-5 shadow-sm">
            <span class="text-[10px] font-extrabold text-amber-500 uppercase tracking-widest">Pending Review</span>
            <strong class="mt-2 block text-3xl font-black text-slate-900">{{ $statusCounts['pending'] ?? 0 }}</strong>
        </div>
        <div class="bg-white border border-blue-100 rounded-2xl p-5 shadow-sm">
            <span class="text-[10px] font-extrabold text-blue-600 uppercase tracking-widest">Processing</span>
            <strong class="mt-2 block text-3xl font-black text-slate-900">{{ $statusCounts['processing'] ?? 0 }}</strong>
        </div>
        <div class="bg-white border border-emerald-100 rounded-2xl p-5 shadow-sm">
            <span class="text-[10px] font-extrabold text-emerald-600 uppercase tracking-widest">Total Payouts Paid</span>
            <strong class="mt-2 block text-3xl font-black text-emerald-800">LKR {{ number_format($totalPaidSum, 2) }}</strong>
        </div>
    </section>

    <!-- Table & Filters Block -->
    <section class="bg-white border border-slate-100 rounded-2xl shadow-sm overflow-hidden">
        <div class="p-5 sm:p-6 border-b border-slate-100 space-y-4">
            <div class="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
                <div>
                    <h2 class="text-base font-extrabold text-slate-900">Withdrawal Operations</h2>
                    <p class="text-xs text-slate-500 font-medium">Verify bank account details and record transaction reference codes upon wire transfer.</p>
                </div>
                <div wire:loading class="text-xs font-extrabold text-emerald-700 bg-emerald-50 border border-emerald-100 rounded-full px-3 py-1">
                    Syncing...
                </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-[minmax(0,1fr)_180px_150px] gap-3">
                <div class="relative">
                    <i class="fa-solid fa-magnifying-glass absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 text-sm"></i>
                    <input wire:model.live.debounce.350ms="search" class="w-full rounded-xl border border-slate-200 bg-slate-50 pl-10 pr-4 py-3 text-sm font-semibold outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition" placeholder="Search partner name, email, bank details">
                </div>
                <select wire:model.live="status" class="rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-bold text-slate-700 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition">
                    <option value="all">All statuses</option>
                    <option value="pending">Pending</option>
                    <option value="processing">Processing</option>
                    <option value="paid">Paid</option>
                    <option value="rejected">Rejected</option>
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
                        <th class="px-5 py-3 text-left text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Partner Details</th>
                        <th class="px-5 py-3 text-left text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Bank Details</th>
                        <th class="px-5 py-3 text-left text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Request Amount</th>
                        <th class="px-5 py-3 text-left text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Status</th>
                        <th class="px-5 py-3 text-right text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100 bg-white">
                    @forelse ($withdrawals as $withdraw)
                        @php
                            $statusClass = [
                                'pending' => 'bg-amber-50 text-amber-700 border-amber-100',
                                'processing' => 'bg-blue-50 text-blue-700 border-blue-100',
                                'paid' => 'bg-emerald-50 text-emerald-700 border-emerald-100',
                                'rejected' => 'bg-rose-50 text-rose-700 border-rose-100',
                            ][$withdraw->status] ?? 'bg-slate-50 text-slate-600 border-slate-100';
                        @endphp
                        <tr class="align-middle hover:bg-slate-50/70 transition" wire:key="withdraw-row-{{ $withdraw->id }}">
                            <td class="px-5 py-4 min-w-[280px]">
                                <div class="flex items-center gap-3">
                                    <div class="w-10 h-10 rounded-full bg-slate-100 flex items-center justify-center text-slate-500 overflow-hidden shrink-0">
                                        <i class="fa-solid fa-user-circle text-2xl text-slate-400"></i>
                                    </div>
                                    <div class="min-w-0">
                                        <p class="text-sm font-extrabold text-slate-900">{{ $withdraw->user->full_name ?? 'Delivery Partner' }}</p>
                                        <p class="text-[11px] text-slate-500 font-semibold">{{ $withdraw->user->email ?? 'No email available' }}</p>
                                        <p class="text-[10px] text-slate-400 font-bold mt-0.5">#WR{{ str_pad($withdraw->id, 4, '0', STR_PAD_LEFT) }}</p>
                                    </div>
                                </div>
                            </td>
                            <td class="px-5 py-4 min-w-[300px]">
                                <p class="text-xs font-bold text-slate-800">{{ $withdraw->bank_name }}</p>
                                <p class="text-[11px] text-slate-500 font-semibold">Branch: {{ $withdraw->bank_branch }}</p>
                                <p class="text-[11px] text-slate-800 font-bold mt-1">Holder: {{ $withdraw->bank_account_holder_name }}</p>
                                <p class="text-xs font-black text-slate-900 mt-0.5">{{ $withdraw->bank_account_number }}</p>
                            </td>
                            <td class="px-5 py-4 min-w-[150px]">
                                <strong class="text-sm font-black text-slate-900">LKR {{ number_format($withdraw->request_amount, 2) }}</strong>
                                <p class="text-[11px] text-slate-400 font-medium mt-1">{{ $withdraw->created_at->format('M d, Y h:i A') }}</p>
                            </td>
                            <td class="px-5 py-4 min-w-[120px]">
                                <span class="inline-flex items-center rounded-full border px-2.5 py-0.5 text-[9px] font-extrabold uppercase tracking-wider {{ $statusClass }}">{{ $withdraw->status }}</span>
                                <p class="text-[10px] text-slate-400 font-semibold mt-1.5">{{ $withdraw->updated_at->diffForHumans() }}</p>
                            </td>
                            <td class="px-5 py-4 min-w-[280px]">
                                <div class="flex flex-wrap justify-end gap-2">
                                    @if ($withdraw->status === 'pending')
                                        <button type="button" wire:click="setStatusProcessing({{ $withdraw->id }})" wire:confirm="Mark this request as processing?" class="inline-flex items-center gap-1.5 rounded-lg bg-blue-50 text-blue-700 hover:bg-blue-100 px-3 py-2 text-[11px] font-extrabold transition">
                                            <i class="fa-solid fa-spinner"></i>
                                            Process
                                        </button>
                                    @endif
                                    @if (in_array($withdraw->status, ['pending', 'processing']))
                                        <button type="button" wire:click="openPayModal({{ $withdraw->id }})" class="inline-flex items-center gap-1.5 rounded-lg bg-emerald-600 text-white hover:bg-emerald-700 px-3 py-2 text-[11px] font-extrabold transition shadow-sm">
                                            <i class="fa-solid fa-money-bill-transfer"></i>
                                            Mark Paid
                                        </button>
                                        <button type="button" wire:click="openRejectModal({{ $withdraw->id }})" class="inline-flex items-center gap-1.5 rounded-lg bg-rose-50 text-rose-700 hover:bg-rose-100 px-3 py-2 text-[11px] font-extrabold transition">
                                            <i class="fa-solid fa-xmark"></i>
                                            Reject
                                        </button>
                                    @endif
                                    <button type="button" wire:click="openDetailsModal({{ $withdraw->id }})" class="inline-flex items-center gap-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 px-3 py-2 text-[11px] font-extrabold transition">
                                        <i class="fa-solid fa-info-circle"></i>
                                        Details
                                    </button>
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="5" class="px-5 py-12 text-center">
                                <div class="mx-auto w-14 h-14 rounded-2xl bg-slate-100 text-slate-400 flex items-center justify-center">
                                    <i class="fa-solid fa-magnifying-glass"></i>
                                </div>
                                <p class="mt-4 text-sm font-extrabold text-slate-700">No withdrawal requests found</p>
                                <p class="mt-1 text-xs text-slate-500 font-medium">Adjust filters or search query.</p>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <!-- Pagination Block -->
        <div class="p-5 sm:p-6 border-t border-slate-100 flex flex-col xl:flex-row xl:items-center xl:justify-between gap-4">
            <p class="text-xs text-slate-500 font-semibold">
                Showing <span class="font-extrabold text-slate-800">{{ $withdrawals->firstItem() ?? 0 }}</span> to <span class="font-extrabold text-slate-800">{{ $withdrawals->lastItem() ?? 0 }}</span> of <span class="font-extrabold text-slate-800">{{ $withdrawals->total() }}</span> requests
            </p>

            <div class="flex flex-col sm:flex-row sm:items-center gap-3">
                <form wire:submit="goToTypedPage" class="flex items-center gap-2">
                    <label class="text-xs font-bold text-slate-500">Go to</label>
                    <input wire:model="pageInput" type="number" min="1" max="{{ $withdrawals->lastPage() }}" class="w-20 rounded-lg border border-slate-200 px-3 py-2 text-xs font-extrabold text-slate-700 outline-none focus:border-emerald-400 focus:ring-4 focus:ring-emerald-100">
                    <button class="rounded-lg bg-slate-900 hover:bg-emerald-700 text-white px-3 py-2 text-xs font-extrabold transition">Go</button>
                </form>

                @if ($withdrawals->hasPages())
                    <div class="flex flex-wrap items-center gap-2">
                        <button type="button" wire:click="setPage(1)" @disabled($withdrawals->onFirstPage()) class="px-3 py-2 rounded-lg border border-slate-200 text-xs font-bold disabled:pointer-events-none disabled:opacity-40 hover:border-emerald-200 hover:text-emerald-700">First</button>
                        <button type="button" wire:click="previousPage" @disabled($withdrawals->onFirstPage()) class="px-3 py-2 rounded-lg border border-slate-200 text-xs font-bold disabled:pointer-events-none disabled:opacity-40 hover:border-emerald-200 hover:text-emerald-700">Prev</button>
                        @foreach ($paginationItems as $item)
                            @if ($item === '...')
                                <span class="px-2 py-2 text-xs font-black text-slate-300">...</span>
                            @else
                                <button type="button" wire:click="setPage({{ $item }})" class="min-w-9 text-center px-3 py-2 rounded-lg border text-xs font-extrabold {{ $item === $withdrawals->currentPage() ? 'bg-emerald-600 border-emerald-600 text-white' : 'border-slate-200 text-slate-600 hover:border-emerald-200 hover:text-emerald-700' }}">{{ $item }}</button>
                            @endif
                        @endforeach
                        <button type="button" wire:click="nextPage" @disabled(!$withdrawals->hasMorePages()) class="px-3 py-2 rounded-lg border border-slate-200 text-xs font-bold disabled:pointer-events-none disabled:opacity-40 hover:border-emerald-200 hover:text-emerald-700">Next</button>
                        <button type="button" wire:click="setPage({{ $withdrawals->lastPage() }})" @disabled($withdrawals->currentPage() === $withdrawals->lastPage()) class="px-3 py-2 rounded-lg border border-slate-200 text-xs font-bold disabled:pointer-events-none disabled:opacity-40 hover:border-emerald-200 hover:text-emerald-700">Last</button>
                    </div>
                @endif
            </div>
        </div>
    </section>

    <!-- Modals -->

    <!-- Pay Modal -->
    @if ($showPayModal)
        <div class="fixed left-0 top-0 z-[9999] flex h-screen w-screen items-center justify-center p-4 bg-slate-950/60 backdrop-blur-sm" aria-modal="true">
            <div class="relative w-full max-w-lg bg-white rounded-2xl shadow-2xl border border-slate-100 overflow-hidden">
                <div class="p-5 border-b border-slate-100 flex items-start justify-between gap-4">
                    <div>
                        <h2 class="text-lg font-extrabold text-slate-900">Mark Payout as Completed</h2>
                        <p class="text-xs text-slate-500 font-semibold mt-1">Enter bank transaction details to complete the withdrawal request.</p>
                    </div>
                    <button type="button" wire:click="closeModals" class="w-9 h-9 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-500 transition">
                        <i class="fa-solid fa-xmark"></i>
                    </button>
                </div>
                <form wire:submit="payRequest" class="p-5 space-y-4">
                    <div>
                        <label class="block text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-2">Bank Transaction Reference (Invoice/Ref #)</label>
                        <input wire:model="transactionReference" required maxlength="255" class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-semibold text-slate-800 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition" placeholder="Example: TXN104928503">
                        @error('transactionReference') <p class="mt-2 text-xs font-bold text-rose-600">{{ $message }}</p> @enderror
                    </div>
                    <div>
                        <label class="block text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-2">Admin note (Optional)</label>
                        <textarea wire:model="adminNote" maxlength="1000" rows="3" class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-semibold text-slate-800 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition" placeholder="Example: Payout processed via commercial bank online transfer."></textarea>
                        @error('adminNote') <p class="mt-2 text-xs font-bold text-rose-600">{{ $message }}</p> @enderror
                    </div>
                    <button type="submit" wire:loading.attr="disabled" class="w-full inline-flex items-center justify-center gap-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 disabled:opacity-60 text-white px-4 py-3 text-sm font-extrabold shadow-md shadow-emerald-500/20 transition">
                        <i class="fa-solid fa-circle-check"></i>
                        Confirm Payout Completed
                    </button>
                </form>
            </div>
        </div>
    @endif

    <!-- Reject Modal -->
    @if ($showRejectModal)
        <div class="fixed left-0 top-0 z-[9999] flex h-screen w-screen items-center justify-center p-4 bg-slate-950/60 backdrop-blur-sm" aria-modal="true">
            <div class="relative w-full max-w-lg bg-white rounded-2xl shadow-2xl border border-slate-100 overflow-hidden">
                <div class="p-5 border-b border-slate-100 flex items-start justify-between gap-4">
                    <div>
                        <h2 class="text-lg font-extrabold text-slate-900">Reject Withdrawal Request</h2>
                        <p class="text-xs text-slate-500 font-semibold mt-1">Provide a reason for rejection. Funds will be refunded to the partner's wallet.</p>
                    </div>
                    <button type="button" wire:click="closeModals" class="w-9 h-9 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-500 transition">
                        <i class="fa-solid fa-xmark"></i>
                    </button>
                </div>
                <form wire:submit="rejectRequest" class="p-5 space-y-4">
                    <div>
                        <label class="block text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-2">Rejection Reason</label>
                        <input wire:model="rejectionReason" required maxlength="255" class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-semibold text-slate-800 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition" placeholder="Example: Account details do not match bank records.">
                        @error('rejectionReason') <p class="mt-2 text-xs font-bold text-rose-600">{{ $message }}</p> @enderror
                    </div>
                    <div>
                        <label class="block text-[10px] font-extrabold uppercase tracking-widest text-slate-400 mb-2">Admin note (Optional)</label>
                        <textarea wire:model="adminNote" maxlength="1000" rows="3" class="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-semibold text-slate-800 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition" placeholder="Example: Rejection due to input mismatch. Contact support."></textarea>
                        @error('adminNote') <p class="mt-2 text-xs font-bold text-rose-600">{{ $message }}</p> @enderror
                    </div>
                    <button type="submit" wire:loading.attr="disabled" class="w-full inline-flex items-center justify-center gap-2 rounded-xl bg-rose-600 hover:bg-rose-700 disabled:opacity-60 text-white px-4 py-3 text-sm font-extrabold shadow-md shadow-rose-500/20 transition">
                        <i class="fa-solid fa-ban"></i>
                        Confirm Rejection
                    </button>
                </form>
            </div>
        </div>
    @endif

    <!-- Details Modal -->
    @if ($showDetailsModal && $selectedRequestDetails)
        <div class="fixed left-0 top-0 z-[9999] flex h-screen w-screen items-center justify-center p-4 bg-slate-950/60 backdrop-blur-sm" aria-modal="true">
            <div class="relative w-full max-w-xl bg-white rounded-3xl shadow-2xl border border-slate-100 overflow-hidden">
                <div class="p-6 border-b border-slate-100 flex items-start justify-between gap-4">
                    <div>
                        <span class="px-2 py-0.5 text-[9px] font-extrabold uppercase tracking-wider rounded bg-slate-100 text-slate-700 border border-slate-200">Audit details</span>
                        <h2 class="text-lg font-black text-slate-900 mt-2">Request Audit Trail</h2>
                    </div>
                    <button type="button" wire:click="closeModals" class="w-9 h-9 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-500 transition">
                        <i class="fa-solid fa-xmark"></i>
                    </button>
                </div>
                <div class="p-6 space-y-6 max-h-[70vh] overflow-y-auto">
                    <!-- Status Header -->
                    <div class="p-4 rounded-2xl bg-slate-50/70 border border-slate-100 flex items-center justify-between">
                        <div>
                            <span class="text-[9px] font-extrabold text-slate-400 uppercase tracking-wider block">Request ID</span>
                            <span class="text-sm font-black text-slate-800">#WR{{ str_pad($selectedRequestDetails->id, 4, '0', STR_PAD_LEFT) }}</span>
                        </div>
                        <div class="text-right">
                            <span class="text-[9px] font-extrabold text-slate-400 uppercase tracking-wider block mb-1">State</span>
                            @php
                                $statusClass = [
                                    'pending' => 'bg-amber-50 text-amber-700 border-amber-100',
                                    'processing' => 'bg-blue-50 text-blue-700 border-blue-100',
                                    'paid' => 'bg-emerald-50 text-emerald-700 border-emerald-100',
                                    'rejected' => 'bg-rose-50 text-rose-700 border-rose-100',
                                ][$selectedRequestDetails->status] ?? 'bg-slate-50 text-slate-600 border-slate-100';
                            @endphp
                            <span class="inline-flex items-center rounded-full border px-3 py-0.5 text-[9px] font-extrabold uppercase tracking-wider {{ $statusClass }}">{{ $selectedRequestDetails->status }}</span>
                        </div>
                    </div>

                    <!-- Details Grid -->
                    <div class="grid grid-cols-2 gap-4">
                        <div>
                            <span class="text-[9px] font-extrabold text-slate-400 uppercase tracking-wider block">Delivery Partner</span>
                            <span class="text-xs font-bold text-slate-800">{{ $selectedRequestDetails->user->full_name ?? 'N/A' }}</span>
                        </div>
                        <div>
                            <span class="text-[9px] font-extrabold text-slate-400 uppercase tracking-wider block">Payout Amount</span>
                            <span class="text-xs font-black text-slate-900">LKR {{ number_format($selectedRequestDetails->request_amount, 2) }}</span>
                        </div>
                        <div>
                            <span class="text-[9px] font-extrabold text-slate-400 uppercase tracking-wider block">Bank Name</span>
                            <span class="text-xs font-bold text-slate-800">{{ $selectedRequestDetails->bank_name }}</span>
                        </div>
                        <div>
                            <span class="text-[9px] font-extrabold text-slate-400 uppercase tracking-wider block">Bank Branch</span>
                            <span class="text-xs font-bold text-slate-800">{{ $selectedRequestDetails->bank_branch }}</span>
                        </div>
                        <div>
                            <span class="text-[9px] font-extrabold text-slate-400 uppercase tracking-wider block">Account Holder Name</span>
                            <span class="text-xs font-bold text-slate-800">{{ $selectedRequestDetails->bank_account_holder_name }}</span>
                        </div>
                        <div>
                            <span class="text-[9px] font-extrabold text-slate-400 uppercase tracking-wider block">Account Number</span>
                            <span class="text-xs font-black text-slate-900">{{ $selectedRequestDetails->bank_account_number }}</span>
                        </div>
                        <div>
                            <span class="text-[9px] font-extrabold text-slate-400 uppercase tracking-wider block">Requested At</span>
                            <span class="text-xs font-semibold text-slate-600">{{ $selectedRequestDetails->created_at->format('M d, Y h:i A') }}</span>
                        </div>
                        <div>
                            <span class="text-[9px] font-extrabold text-slate-400 uppercase tracking-wider block">Request IP</span>
                            <span class="text-xs font-semibold text-slate-600">{{ $selectedRequestDetails->requested_ip ?? 'N/A' }}</span>
                        </div>
                    </div>

                    <!-- Audit Review Fields -->
                    @if ($selectedRequestDetails->status === 'paid' || $selectedRequestDetails->status === 'rejected')
                        <div class="border-t border-slate-100 pt-4 space-y-4">
                            <h3 class="text-xs font-extrabold text-slate-800 uppercase tracking-wider">Review Audit Details</h3>
                            <div class="grid grid-cols-2 gap-4">
                                <div>
                                    <span class="text-[9px] font-extrabold text-slate-400 uppercase tracking-wider block">Reviewed By</span>
                                    <span class="text-xs font-bold text-slate-800">{{ $selectedRequestDetails->reviewedAdmin->full_name ?? 'Admin' }}</span>
                                </div>
                                <div>
                                    <span class="text-[9px] font-extrabold text-slate-400 uppercase tracking-wider block">Reviewed At</span>
                                    <span class="text-xs font-semibold text-slate-600">{{ $selectedRequestDetails->reviewed_at ? $selectedRequestDetails->reviewed_at->format('M d, Y h:i A') : 'N/A' }}</span>
                                </div>
                                @if ($selectedRequestDetails->status === 'paid')
                                    <div>
                                        <span class="text-[9px] font-extrabold text-slate-400 uppercase tracking-wider block">Paid At</span>
                                        <span class="text-xs font-semibold text-slate-600">{{ $selectedRequestDetails->paid_at ? $selectedRequestDetails->paid_at->format('M d, Y h:i A') : 'N/A' }}</span>
                                    </div>
                                    <div>
                                        <span class="text-[9px] font-extrabold text-slate-400 uppercase tracking-wider block">Transaction Ref #</span>
                                        <span class="text-xs font-black text-emerald-800">{{ $selectedRequestDetails->transaction_reference }}</span>
                                    </div>
                                @endif
                            </div>
                            
                            @if ($selectedRequestDetails->status === 'rejected' && $selectedRequestDetails->rejection_reason)
                                <div>
                                    <span class="text-[9px] font-extrabold text-rose-500 uppercase tracking-wider block">Rejection Reason</span>
                                    <p class="text-xs font-semibold text-rose-800 bg-rose-50 border border-rose-100 rounded-xl p-3 mt-1.5">{{ $selectedRequestDetails->rejection_reason }}</p>
                                </div>
                            @endif

                            @if ($selectedRequestDetails->admin_note)
                                <div>
                                    <span class="text-[9px] font-extrabold text-slate-400 uppercase tracking-wider block">Admin Review Note</span>
                                    <p class="text-xs font-semibold text-slate-700 bg-slate-50 border border-slate-100 rounded-xl p-3 mt-1.5">{{ $selectedRequestDetails->admin_note }}</p>
                                </div>
                            @endif
                        </div>
                    @endif
                </div>
                <div class="p-6 border-t border-slate-100 bg-slate-50/50 flex justify-end">
                    <button type="button" wire:click="closeModals" class="px-5 py-2.5 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-xs font-bold transition">Close</button>
                </div>
            </div>
        </div>
    @endif
</div>
