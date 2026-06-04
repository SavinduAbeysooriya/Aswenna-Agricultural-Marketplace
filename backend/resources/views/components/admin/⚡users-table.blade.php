<?php

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Livewire\Component;
use Livewire\WithPagination;

new class extends Component
{
    use WithPagination;

    public string $role;
    public string $search = '';
    public string $status = 'all'; // all, pending, approved, rejected, inactive
    public int $perPage = 10;
    public string $pageInput = '1';

    // Details/Audit modal states
    public bool $showDetailsModal = false;
    public ?int $selectedUserId = null;
    public $selectedUserDetails = null;
    public $selectedUserDocuments = [];
    public $selectedUserVerificationData = null;
    public string $rejectionReason = '';

    // Expanded Profile parameters
    public string $activeTab = 'verification'; // verification, wallet, performance, history
    public $selectedUserWallet = null;
    public $selectedUserTransactions = [];
    public $selectedUserReviews = [];
    public $selectedUserRating = 0;
    public $selectedUserListings = [];
    public $selectedUserHistory = [];

    public function mount(string $role): void
    {
        $this->role = $role;
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

    public function goToTypedPage(): void
    {
        $lastPage = max(1, (int) ceil($this->filteredQuery()->count() / $this->perPage));
        $page = min(max((int) $this->pageInput, 1), $lastPage);
        $this->pageInput = (string) $page;
        $this->setPage($page);
    }

    // Modal Control
    public function openDetailsModal(int $userId, string $defaultTab = 'verification'): void
    {
        $this->selectedUserId = $userId;
        $this->rejectionReason = '';
        $this->activeTab = $defaultTab;
        
        $user = User::findOrFail($userId);
        $this->selectedUserDetails = $user;

        // 1. Fetch Verification Documents & Specific Data
        $this->selectedUserDocuments = DB::table('user_verification_documents')
            ->where('user_id', $userId)
            ->orderByDesc('created_at')
            ->get();

        if ($this->role === 'farmer') {
            $this->selectedUserVerificationData = DB::table('farmer_verification_data')
                ->where('user_id', $userId)
                ->first();
        } elseif ($this->role === 'retail_seller') {
            $this->selectedUserVerificationData = DB::table('retail_seller_verification_data')
                ->where('user_id', $userId)
                ->first();
        } elseif ($this->role === 'delivery_partner') {
            $this->selectedUserVerificationData = DB::table('delivery_partner_verification_data')
                ->where('user_id', $userId)
                ->first();
        } else {
            $this->selectedUserVerificationData = null;
        }

        // 2. Fetch Wallet & Transactions
        $this->selectedUserWallet = DB::table('user_wallets')->where('user_id', $userId)->first();
        $this->selectedUserTransactions = DB::table('wallet_transactions')
            ->where('user_id', $userId)
            ->orderByDesc('created_at')
            ->limit(10)
            ->get();

        // 3. Fetch Performance & Ratings & Listed Items
        if ($this->role === 'farmer') {
            $this->selectedUserReviews = DB::table('buyer_farmer_reviews')
                ->where('farmer_id', $userId)
                ->join('users', 'buyer_farmer_reviews.reviewed_by', '=', 'users.id')
                ->select('buyer_farmer_reviews.*', 'users.full_name as reviewer_name', 'users.profile_picture_path as reviewer_avatar')
                ->orderByDesc('buyer_farmer_reviews.created_at')
                ->get();
            $this->selectedUserRating = DB::table('buyer_farmer_reviews')->where('farmer_id', $userId)->avg('ratings') ?: 0;
            
            $this->selectedUserListings = DB::table('harvest_listings')
                ->where('farmer_id', $userId)
                ->join('crops', 'harvest_listings.crop_id', '=', 'crops.id')
                ->select('harvest_listings.*', 'crops.cropname as crop_name')
                ->orderByDesc('harvest_listings.created_at')
                ->get();
        } elseif ($this->role === 'retail_seller') {
            $this->selectedUserReviews = DB::table('retailer_customer_delivery_partner_reviews')
                ->where('reviewed_to', $userId)
                ->join('users', 'retailer_customer_delivery_partner_reviews.reviewed_by', '=', 'users.id')
                ->select('retailer_customer_delivery_partner_reviews.*', 'users.full_name as reviewer_name', 'users.profile_picture_path as reviewer_avatar')
                ->orderByDesc('retailer_customer_delivery_partner_reviews.created_at')
                ->get();
            $this->selectedUserRating = DB::table('retailer_customer_delivery_partner_reviews')->where('reviewed_to', $userId)->avg('ratings') ?: 0;
            
            $this->selectedUserListings = DB::table('retailer_products')
                ->where('seller_id', $userId)
                ->join('crops', 'retailer_products.crop_id', '=', 'crops.id')
                ->select('retailer_products.*', 'crops.cropname as crop_name')
                ->orderByDesc('retailer_products.created_at')
                ->get();
        } elseif ($this->role === 'delivery_partner') {
            $this->selectedUserReviews = DB::table('retailer_customer_delivery_partner_reviews')
                ->where('reviewed_to', $userId)
                ->join('users', 'retailer_customer_delivery_partner_reviews.reviewed_by', '=', 'users.id')
                ->select('retailer_customer_delivery_partner_reviews.*', 'users.full_name as reviewer_name', 'users.profile_picture_path as reviewer_avatar')
                ->orderByDesc('retailer_customer_delivery_partner_reviews.created_at')
                ->get();
            $this->selectedUserRating = DB::table('retailer_customer_delivery_partner_reviews')->where('reviewed_to', $userId)->avg('ratings') ?: 0;
            
            $this->selectedUserListings = [];
        } else {
            $this->selectedUserReviews = [];
            $this->selectedUserRating = 0;
            $this->selectedUserListings = [];
        }

        // 4. Fetch History (Dispatches, Purchases, Bids)
        if ($this->role === 'delivery_partner') {
            $this->selectedUserHistory = DB::table('customer_orders')
                ->where('delivery_partner_id', $userId)
                ->join('users as customers', 'customer_orders.customer_id', '=', 'customers.id')
                ->select('customer_orders.*', 'customers.full_name as customer_name')
                ->orderByDesc('customer_orders.created_at')
                ->get();
        } elseif ($this->role === 'customer') {
            $this->selectedUserHistory = DB::table('customer_orders')
                ->where('customer_id', $userId)
                ->join('users as sellers', 'customer_orders.retailer_seller_id', '=', 'sellers.id')
                ->select('customer_orders.*', 'sellers.full_name as seller_name')
                ->orderByDesc('customer_orders.created_at')
                ->get();
        } elseif ($this->role === 'buyer') {
            $this->selectedUserHistory = DB::table('confirmed_bids')
                ->where('confirmed_bids.buyer_id', $userId)
                ->join('harvest_listings', 'confirmed_bids.harvest_listing_id', '=', 'harvest_listings.id')
                ->join('crops', 'harvest_listings.crop_id', '=', 'crops.id')
                ->select('confirmed_bids.*', 'crops.cropname as crop_name', 'harvest_listings.grade')
                ->orderByDesc('confirmed_bids.created_at')
                ->get();
        } else {
            $this->selectedUserHistory = [];
        }

        $this->showDetailsModal = true;
    }

    public function changeTab(string $tab): void
    {
        $this->activeTab = $tab;
    }

    public function closeDetailsModal(): void
    {
        $this->showDetailsModal = false;
        $this->reset([
            'selectedUserId', 'selectedUserDetails', 'selectedUserDocuments', 'selectedUserVerificationData', 'rejectionReason',
            'activeTab', 'selectedUserWallet', 'selectedUserTransactions', 'selectedUserReviews', 'selectedUserRating', 'selectedUserListings', 'selectedUserHistory'
        ]);
    }

    // Action Methods
    public function approveUser(int $userId): void
    {
        $user = User::findOrFail($userId);
        
        DB::transaction(function () use ($user, $userId) {
            $user->update(['is_verified' => true]);

            if ($this->role === 'retail_seller') {
                DB::table('retail_seller_verification_data')
                    ->where('user_id', $userId)
                    ->update([
                        'status' => 'verified',
                        'rejected_reason' => null,
                        'updated_at' => now(),
                    ]);
            } elseif ($this->role === 'delivery_partner') {
                DB::table('delivery_partner_verification_data')
                    ->where('user_id', $userId)
                    ->update([
                        'status' => 'verified',
                        'rejected_reason' => null,
                        'updated_at' => now(),
                    ]);
            } else {
                DB::table('user_verification_documents')
                    ->where('user_id', $userId)
                    ->where('verification_status', 'pending')
                    ->update([
                        'verification_status' => 'approved',
                        'verified_at' => now(),
                        'verified_by' => session('admin_session.user_id') ?? auth()->id(),
                        'updated_at' => now(),
                    ]);
            }
        });

        $this->openDetailsModal($userId, $this->activeTab);
        $this->dispatch('user-saved', message: 'User verification approved successfully.');
    }

    public function rejectUser(int $userId): void
    {
        $this->validate([
            'rejectionReason' => 'required|string|min:4|max:500',
        ]);

        $user = User::findOrFail($userId);

        DB::transaction(function () use ($user, $userId) {
            $user->update(['is_verified' => false]);

            if ($this->role === 'retail_seller') {
                DB::table('retail_seller_verification_data')
                    ->where('user_id', $userId)
                    ->update([
                        'status' => 'rejected',
                        'rejected_reason' => $this->rejectionReason,
                        'updated_at' => now(),
                    ]);
            } elseif ($this->role === 'delivery_partner') {
                DB::table('delivery_partner_verification_data')
                    ->where('user_id', $userId)
                    ->update([
                        'status' => 'rejected',
                        'rejected_reason' => $this->rejectionReason,
                        'updated_at' => now(),
                    ]);
            } else {
                $latestDoc = DB::table('user_verification_documents')
                    ->where('user_id', $userId)
                    ->orderByDesc('created_at')
                    ->first();

                if ($latestDoc) {
                    DB::table('user_verification_documents')
                        ->where('id', $latestDoc->id)
                        ->update([
                            'verification_status' => 'rejected',
                            'rejection_reason' => $this->rejectionReason,
                            'verified_at' => now(),
                            'verified_by' => session('admin_session.user_id') ?? auth()->id(),
                            'updated_at' => now(),
                        ]);
                } else {
                    DB::table('user_verification_documents')->insert([
                        'user_id' => $userId,
                        'document_type' => $this->role === 'farmer' ? 'farming_license' : 'national_id',
                        'front_image_path' => 'placeholder_rejected',
                        'verification_status' => 'rejected',
                        'rejection_reason' => $this->rejectionReason,
                        'verified_at' => now(),
                        'verified_by' => session('admin_session.user_id') ?? auth()->id(),
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                }
            }
        });

        $this->openDetailsModal($userId, $this->activeTab);
        $this->dispatch('user-saved', message: 'User verification rejected with explanation.');
    }

    public function toggleUserActive(int $userId): void
    {
        $user = User::findOrFail($userId);
        $newState = !$user->is_active;
        $user->update(['is_active' => $newState]);

        $statusLabel = $newState ? 'activated' : 'deactivated';
        
        if ($this->selectedUserId === $userId && $this->selectedUserDetails) {
            $this->selectedUserDetails->is_active = $newState;
        }

        $this->dispatch('user-saved', message: "User profile successfully {$statusLabel}.");
    }

    // Queries
    private function filteredQuery()
    {
        $search = trim($this->search);

        return User::query()
            ->whereJsonContains('role', $this->role)
            ->when($search !== '', function ($query) use ($search) {
                $query->where(function ($sub) use ($search) {
                    $sub->where('full_name', 'like', '%' . $search . '%')
                       ->orWhere('email', 'like', '%' . $search . '%')
                       ->orWhere('phone_number', 'like', '%' . $search . '%')
                       ->orWhere('city', 'like', '%' . $search . '%')
                       ->orWhere('district', 'like', '%' . $search . '%');
                });
            })
            ->when($this->status !== 'all', function ($query) {
                if ($this->status === 'inactive') {
                    $query->where('is_active', false);
                } elseif ($this->status === 'approved') {
                    $query->where('is_verified', true)->where('is_active', true);
                } elseif ($this->status === 'pending') {
                    $query->where('is_verified', false)->where('is_active', true)
                        ->where(function ($sub) {
                            if ($this->role === 'retail_seller') {
                                $sub->whereExists(function ($q) {
                                    $q->select(DB::raw(1))
                                      ->from('retail_seller_verification_data')
                                      ->whereColumn('user_id', 'users.id')
                                      ->where('status', 'pending');
                                });
                            } elseif ($this->role === 'delivery_partner') {
                                $sub->whereExists(function ($q) {
                                    $q->select(DB::raw(1))
                                      ->from('delivery_partner_verification_data')
                                      ->whereColumn('user_id', 'users.id')
                                      ->where('status', 'pending');
                                });
                            } else {
                                $sub->whereExists(function ($q) {
                                    $q->select(DB::raw(1))
                                      ->from('user_verification_documents')
                                      ->whereColumn('user_id', 'users.id')
                                      ->where('verification_status', 'pending');
                                })
                                ->orWhere(function ($q) {
                                    if ($this->role === 'farmer') {
                                        $q->whereExists(function ($inner) {
                                            $inner->select(DB::raw(1))
                                                  ->from('farmer_verification_data')
                                                  ->whereColumn('user_id', 'users.id');
                                        })
                                        ->whereNotExists(function ($inner) {
                                            $inner->select(DB::raw(1))
                                                  ->from('user_verification_documents')
                                                  ->whereColumn('user_id', 'users.id')
                                                  ->where('verification_status', 'rejected');
                                        });
                                    }
                                });
                            }
                        });
                } elseif ($this->status === 'rejected') {
                    $query->where('is_verified', false)->where('is_active', true)
                        ->where(function ($sub) {
                            if ($this->role === 'retail_seller') {
                                $sub->whereExists(function ($q) {
                                    $q->select(DB::raw(1))
                                      ->from('retail_seller_verification_data')
                                      ->whereColumn('user_id', 'users.id')
                                      ->where('status', 'rejected');
                                });
                            } elseif ($this->role === 'delivery_partner') {
                                $sub->whereExists(function ($q) {
                                    $q->select(DB::raw(1))
                                      ->from('delivery_partner_verification_data')
                                      ->whereColumn('user_id', 'users.id')
                                      ->where('status', 'rejected');
                                });
                            } else {
                                $sub->whereExists(function ($q) {
                                    $q->select(DB::raw(1))
                                      ->from('user_verification_documents')
                                      ->whereColumn('user_id', 'users.id')
                                      ->where('verification_status', 'rejected');
                                });
                            }
                        });
                }
            })
            ->latest();
    }

    private function getStatusCount(string $statusType): int
    {
        $query = User::query()->whereJsonContains('role', $this->role);
        
        if ($statusType === 'inactive') {
            return $query->where('is_active', false)->count();
        } elseif ($statusType === 'approved') {
            return $query->where('is_verified', true)->where('is_active', true)->count();
        } elseif ($statusType === 'pending') {
            return $query->where('is_verified', false)->where('is_active', true)
                ->where(function ($sub) {
                    if ($this->role === 'retail_seller') {
                        $sub->whereExists(function ($q) {
                            $q->select(DB::raw(1))
                              ->from('retail_seller_verification_data')
                              ->whereColumn('user_id', 'users.id')
                              ->where('status', 'pending');
                        });
                    } elseif ($this->role === 'delivery_partner') {
                        $sub->whereExists(function ($q) {
                            $q->select(DB::raw(1))
                              ->from('delivery_partner_verification_data')
                              ->whereColumn('user_id', 'users.id')
                              ->where('status', 'pending');
                        });
                    } else {
                        $sub->whereExists(function ($q) {
                            $q->select(DB::raw(1))
                              ->from('user_verification_documents')
                              ->whereColumn('user_id', 'users.id')
                              ->where('verification_status', 'pending');
                        })
                        ->orWhere(function ($q) {
                            if ($this->role === 'farmer') {
                                $q->whereExists(function ($inner) {
                                    $inner->select(DB::raw(1))
                                          ->from('farmer_verification_data')
                                          ->whereColumn('user_id', 'users.id');
                                })
                                ->whereNotExists(function ($inner) {
                                    $inner->select(DB::raw(1))
                                          ->from('user_verification_documents')
                                          ->whereColumn('user_id', 'users.id')
                                          ->where('verification_status', 'rejected');
                                });
                            }
                        });
                    }
                })->count();
        } elseif ($statusType === 'rejected') {
            return $query->where('is_verified', false)->where('is_active', true)
                ->where(function ($sub) {
                    if ($this->role === 'retail_seller') {
                        $sub->whereExists(function ($q) {
                            $q->select(DB::raw(1))
                              ->from('retail_seller_verification_data')
                              ->whereColumn('user_id', 'users.id')
                              ->where('status', 'rejected');
                        });
                    } elseif ($this->role === 'delivery_partner') {
                        $sub->whereExists(function ($q) {
                            $q->select(DB::raw(1))
                              ->from('delivery_partner_verification_data')
                              ->whereColumn('user_id', 'users.id')
                              ->where('status', 'rejected');
                        });
                    } else {
                        $sub->whereExists(function ($q) {
                            $q->select(DB::raw(1))
                              ->from('user_verification_documents')
                              ->whereColumn('user_id', 'users.id')
                              ->where('verification_status', 'rejected');
                        });
                    }
                })->count();
        }
        
        return $query->count();
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
        $users = $this->filteredQuery()->paginate($this->perPage);

        return $this->view([
            'users' => $users,
            'totalCount' => User::whereJsonContains('role', $this->role)->count(),
            'pendingCount' => $this->getStatusCount('pending'),
            'approvedCount' => $this->getStatusCount('approved'),
            'rejectedCount' => $this->getStatusCount('rejected'),
            'inactiveCount' => $this->getStatusCount('inactive'),
            'paginationItems' => $this->paginationItems($users->currentPage(), $users->lastPage()),
        ]);
    }
};
?>

@php
    $roleName = ucwords(str_replace('_', ' ', $role));
    $roleTheme = [
        'farmer' => ['bg' => 'bg-emerald-600', 'hover' => 'hover:bg-emerald-700', 'badge' => 'bg-emerald-50 text-emerald-700 border-emerald-100', 'icon' => 'fa-wheat-awn'],
        'retail_seller' => ['bg' => 'bg-blue-600', 'hover' => 'hover:bg-blue-700', 'badge' => 'bg-blue-50 text-blue-700 border-blue-100', 'icon' => 'fa-store'],
        'delivery_partner' => ['bg' => 'bg-indigo-600', 'hover' => 'hover:bg-indigo-700', 'badge' => 'bg-indigo-50 text-indigo-700 border-indigo-100', 'icon' => 'fa-truck-fast'],
        'buyer' => ['bg' => 'bg-violet-600', 'hover' => 'hover:bg-violet-700', 'badge' => 'bg-violet-50 text-violet-700 border-violet-100', 'icon' => 'fa-hand-holding-dollar'],
        'customer' => ['bg' => 'bg-teal-600', 'hover' => 'hover:bg-teal-700', 'badge' => 'bg-teal-50 text-teal-700 border-teal-100', 'icon' => 'fa-cart-shopping'],
        'admin' => ['bg' => 'bg-slate-600', 'hover' => 'hover:bg-slate-700', 'badge' => 'bg-slate-100 text-slate-700 border-slate-200', 'icon' => 'fa-user-shield'],
    ][$role] ?? ['bg' => 'bg-slate-600', 'hover' => 'hover:bg-slate-700', 'badge' => 'bg-slate-100 text-slate-700 border-slate-200', 'icon' => 'fa-users'];
@endphp

<div class="space-y-6">
    <!-- Breadcrumbs / Heading -->
    <section class="flex flex-col xl:flex-row xl:items-end xl:justify-between gap-4">
        <div>
            <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full {{ $roleTheme['badge'] }} text-[11px] font-extrabold uppercase tracking-widest border">
                <i class="fa-solid {{ $roleTheme['icon'] }}"></i>
                {{ $roleName }} Management Console
            </div>
            <h1 class="mt-3 text-2xl sm:text-3xl font-black tracking-tight text-slate-900 font-poppins">{{ $roleName }}s List</h1>
            <p class="mt-1 text-sm text-slate-500 font-medium max-w-2xl">Search, view details, inspect uploaded credentials, and process verification requests for all registered {{ strtolower($roleName) }}s.</p>
        </div>
        <div class="flex flex-col sm:flex-row gap-3">
            <a href="{{ route('admin.users.roles') }}" class="inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-white border border-slate-200 text-slate-600 hover:text-emerald-700 hover:border-emerald-200 text-xs font-bold shadow-sm transition">
                <i class="fa-solid fa-chevron-left text-[10px]"></i>
                Change Role
            </a>
            <a href="{{ route('admin.dashboard') }}" class="inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-white border border-slate-200 text-slate-600 hover:text-emerald-700 hover:border-emerald-200 text-xs font-bold shadow-sm transition">
                <i class="fa-solid fa-arrow-left"></i>
                Dashboard
            </a>
        </div>
    </section>

    <!-- Stats Summary Section -->
    <section class="grid grid-cols-2 lg:grid-cols-5 gap-4">
        <div class="bg-white border border-slate-100 rounded-2xl p-5 shadow-sm">
            <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest">Total Members</span>
            <strong class="mt-2 block text-2xl sm:text-3xl font-black text-slate-900">{{ $totalCount }}</strong>
        </div>
        <div class="bg-white border border-amber-100 rounded-2xl p-5 shadow-sm">
            <span class="text-[10px] font-extrabold text-amber-500 uppercase tracking-widest">Pending Audit</span>
            <strong class="mt-2 block text-2xl sm:text-3xl font-black text-slate-900">{{ $pendingCount }}</strong>
        </div>
        <div class="bg-white border border-emerald-100 rounded-2xl p-5 shadow-sm">
            <span class="text-[10px] font-extrabold text-emerald-600 uppercase tracking-widest">Verified / Active</span>
            <strong class="mt-2 block text-2xl sm:text-3xl font-black text-slate-900">{{ $approvedCount }}</strong>
        </div>
        <div class="bg-white border border-rose-100 rounded-2xl p-5 shadow-sm">
            <span class="text-[10px] font-extrabold text-rose-500 uppercase tracking-widest">Rejected</span>
            <strong class="mt-2 block text-2xl sm:text-3xl font-black text-slate-900">{{ $rejectedCount }}</strong>
        </div>
        <div class="col-span-2 lg:col-span-1 bg-white border border-slate-100 rounded-2xl p-5 shadow-sm">
            <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest">Inactive / Blocked</span>
            <strong class="mt-2 block text-2xl sm:text-3xl font-black text-slate-900">{{ $inactiveCount }}</strong>
        </div>
    </section>

    <!-- Table Section -->
    <section class="bg-white border border-slate-100 rounded-2xl shadow-sm overflow-hidden">
        <div class="p-5 sm:p-6 border-b border-slate-100 space-y-4">
            <!-- Filter Tabs -->
            <div class="flex flex-wrap items-center justify-between gap-4">
                <div class="flex flex-wrap gap-1 bg-slate-100 p-1 rounded-xl">
                    <button type="button" wire:click="$set('status', 'all')" class="px-4 py-2 rounded-lg text-xs font-bold transition {{ $status === 'all' ? 'bg-white text-slate-950 shadow-sm' : 'text-slate-500 hover:text-slate-900' }}">All</button>
                    <button type="button" wire:click="$set('status', 'pending')" class="px-4 py-2 rounded-lg text-xs font-bold transition flex items-center gap-1.5 {{ $status === 'pending' ? 'bg-white text-amber-700 shadow-sm font-extrabold' : 'text-slate-500 hover:text-slate-900' }}">
                        Pending
                        @if ($pendingCount > 0)
                            <span class="bg-amber-100 text-amber-800 text-[9px] font-black px-1.5 py-0.5 rounded-full">{{ $pendingCount }}</span>
                        @endif
                    </button>
                    <button type="button" wire:click="$set('status', 'approved')" class="px-4 py-2 rounded-lg text-xs font-bold transition {{ $status === 'approved' ? 'bg-white text-emerald-700 shadow-sm font-extrabold' : 'text-slate-500 hover:text-slate-900' }}">Approved</button>
                    <button type="button" wire:click="$set('status', 'rejected')" class="px-4 py-2 rounded-lg text-xs font-bold transition {{ $status === 'rejected' ? 'bg-white text-rose-700 shadow-sm font-extrabold' : 'text-slate-500 hover:text-slate-900' }}">Rejected</button>
                    <button type="button" wire:click="$set('status', 'inactive')" class="px-4 py-2 rounded-lg text-xs font-bold transition {{ $status === 'inactive' ? 'bg-white text-slate-700 shadow-sm font-extrabold' : 'text-slate-500 hover:text-slate-900' }}">Inactive</button>
                </div>
                <div wire:loading class="text-[11px] font-extrabold text-emerald-700 bg-emerald-50 border border-emerald-100 rounded-full px-3 py-1">
                    Refreshing Live List...
                </div>
            </div>

            <!-- Search and Per Page -->
            <div class="grid grid-cols-1 md:grid-cols-[minmax(0,1fr)_150px] gap-3">
                <div class="relative">
                    <i class="fa-solid fa-magnifying-glass absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 text-sm"></i>
                    <input wire:model.live.debounce.350ms="search" class="w-full rounded-xl border border-slate-200 bg-slate-50 pl-10 pr-4 py-3 text-sm font-semibold outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition" placeholder="Search by name, email, phone, city, or district...">
                </div>
                <select wire:model.live="perPage" class="rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-bold text-slate-700 outline-none focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-100 transition">
                    @foreach ([10, 25, 50, 100] as $size)
                        <option value="{{ $size }}">{{ $size }} / page</option>
                    @endforeach
                </select>
            </div>
        </div>

        <!-- Table Grid -->
        <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-slate-100">
                <thead class="bg-slate-50">
                    <tr>
                        <th class="px-5 py-3 text-left text-[10px] font-extrabold uppercase tracking-widest text-slate-400">User / Profile</th>
                        <th class="px-5 py-3 text-left text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Contact Details</th>
                        <th class="px-5 py-3 text-left text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Location</th>
                        <th class="px-5 py-3 text-left text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Status</th>
                        <th class="px-5 py-3 text-right text-[10px] font-extrabold uppercase tracking-widest text-slate-400">Actions</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100 bg-white">
                    @forelse ($users as $u)
                        @php
                            $statusBadge = 'bg-slate-50 text-slate-600 border-slate-100';
                            $statusLabel = 'Unverified';
                            
                            if (!$u->is_active) {
                                $statusBadge = 'bg-rose-50 text-rose-700 border-rose-100';
                                $statusLabel = 'Banned';
                            } elseif ($u->is_verified) {
                                $statusBadge = 'bg-emerald-50 text-emerald-700 border-emerald-100';
                                $statusLabel = 'Approved';
                            } else {
                                if ($role === 'retail_seller') {
                                    $statusVal = DB::table('retail_seller_verification_data')->where('user_id', $u->id)->value('status') ?? 'pending';
                                    if ($statusVal === 'pending') {
                                        $statusBadge = 'bg-amber-50 text-amber-700 border-amber-100';
                                        $statusLabel = 'Pending Review';
                                    } elseif ($statusVal === 'rejected') {
                                        $statusBadge = 'bg-rose-50 text-rose-600 border-rose-100';
                                        $statusLabel = 'Rejected';
                                    }
                                } elseif ($role === 'delivery_partner') {
                                    $statusVal = DB::table('delivery_partner_verification_data')->where('user_id', $u->id)->value('status') ?? 'pending';
                                    if ($statusVal === 'pending') {
                                        $statusBadge = 'bg-amber-50 text-amber-700 border-amber-100';
                                        $statusLabel = 'Pending Review';
                                    } elseif ($statusVal === 'rejected') {
                                        $statusBadge = 'bg-rose-50 text-rose-600 border-rose-100';
                                        $statusLabel = 'Rejected';
                                    }
                                } else {
                                    $latestDocStatus = DB::table('user_verification_documents')->where('user_id', $u->id)->orderByDesc('created_at')->value('verification_status');
                                    if ($latestDocStatus === 'pending') {
                                        $statusBadge = 'bg-amber-50 text-amber-700 border-amber-100';
                                        $statusLabel = 'Pending Review';
                                    } elseif ($latestDocStatus === 'rejected') {
                                        $statusBadge = 'bg-rose-50 text-rose-600 border-rose-100';
                                        $statusLabel = 'Rejected';
                                    } elseif ($role === 'farmer') {
                                        if (DB::table('farmer_verification_data')->where('user_id', $u->id)->exists()) {
                                            $statusBadge = 'bg-amber-50 text-amber-700 border-amber-100';
                                            $statusLabel = 'Pending Audit';
                                        }
                                    }
                                }
                            }
                        @endphp
                        <tr class="align-middle hover:bg-slate-50/70 transition" wire:key="user-row-{{ $u->id }}">
                            <td class="px-5 py-4 min-w-[280px]">
                                <div class="flex items-center gap-3">
                                    <a href="{{ route('admin.users.profile', $u->id) }}" class="relative group" title="Click avatar to view profile">
                                        <div class="w-11 h-11 rounded-xl bg-slate-100 border border-slate-200/60 overflow-hidden flex items-center justify-center text-slate-500 font-extrabold text-xs shrink-0 shadow-inner group-hover:scale-105 transition-transform duration-300">
                                            @if ($u->profile_picture_path)
                                                <img src="{{ Str::startsWith($u->profile_picture_path, ['http://', 'https://']) ? $u->profile_picture_path : asset('storage/' . $u->profile_picture_path) }}" alt="{{ $u->full_name }}" class="w-full h-full object-cover">
                                            @else
                                                <span>{{ strtoupper(substr($u->full_name, 0, 2)) }}</span>
                                            @endif
                                        </div>
                                        <span class="absolute inset-0 bg-slate-900/30 opacity-0 group-hover:opacity-100 transition-opacity rounded-xl flex items-center justify-center text-white text-[9px] font-black"><i class="fa-solid fa-eye text-xs"></i></span>
                                    </a>
                                    <div class="min-w-0">
                                        <p class="text-sm font-extrabold text-slate-900 truncate">{{ $u->full_name }}</p>
                                        <p class="text-[10px] text-slate-400 font-bold mt-0.5">UID #US{{ str_pad($u->id, 5, '0', STR_PAD_LEFT) }}</p>
                                    </div>
                                </div>
                            </td>
                            <td class="px-5 py-4 min-w-[240px]">
                                <p class="text-xs font-bold text-slate-800">{{ $u->email ?? 'No Email Address' }}</p>
                                <p class="text-xs text-slate-500 font-semibold mt-1"><i class="fa-solid fa-phone text-[10px] mr-1.5 text-slate-400"></i>{{ $u->phone_number }}</p>
                            </td>
                            <td class="px-5 py-4 min-w-[180px]">
                                <p class="text-xs font-bold text-slate-800">{{ $u->city ?? 'Not Provided' }}</p>
                                <p class="text-[10px] text-slate-400 font-semibold mt-1">{{ $u->district ? $u->district . ', ' : '' }}{{ $u->province ?? '' }}</p>
                            </td>
                            <td class="px-5 py-4 min-w-[140px]">
                                <span class="inline-flex items-center rounded-full border px-2.5 py-0.5 text-[9px] font-black uppercase tracking-wider {{ $statusBadge }}">{{ $statusLabel }}</span>
                                <p class="text-[9px] text-slate-400 font-semibold mt-1.5">Joined {{ $u->created_at->format('M d, Y') }}</p>
                            </td>
                            <td class="px-5 py-4 min-w-[290px]">
                                <div class="flex flex-wrap justify-end gap-2">
                                    <!-- View Profile Icon Button -->
                                    <a href="{{ route('admin.users.profile', $u->id) }}" class="inline-flex items-center gap-1 px-3 py-2 rounded-lg bg-emerald-50 hover:bg-emerald-100 text-emerald-700 text-[11px] font-extrabold border border-emerald-100/55 transition" title="View Wallet, listings, and feedback records">
                                        <i class="fa-solid fa-address-card text-[11px]"></i>
                                        View Profile
                                    </a>

                                    <a href="{{ route('admin.users.profile', $u->id) }}" class="inline-flex items-center gap-1 px-3 py-2 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 text-[11px] font-extrabold transition">
                                        <i class="fa-solid fa-clipboard-check text-[10px]"></i>
                                        Audit Docs
                                    </a>
                                    
                                    @if ($role !== 'admin')
                                        @if ($u->is_active)
                                            <button type="button" wire:confirm="Deactivate / Suspend this user's account?" wire:click="toggleUserActive({{ $u->id }})" class="inline-flex items-center gap-1 px-3 py-2 rounded-lg bg-rose-50 hover:bg-rose-100 text-rose-700 text-[11px] font-extrabold transition">
                                                <i class="fa-solid fa-user-slash text-[10px]"></i>
                                                Ban
                                            </button>
                                        @else
                                            <button type="button" wire:confirm="Re-activate this user's account?" wire:click="toggleUserActive({{ $u->id }})" class="inline-flex items-center gap-1 px-3 py-2 rounded-lg bg-emerald-50 hover:bg-emerald-100 text-emerald-700 text-[11px] font-extrabold transition">
                                                <i class="fa-solid fa-user-check text-[10px]"></i>
                                                Activate
                                            </button>
                                        @endif
                                    @else
                                        @if ($u->id !== session('admin_session.user_id') && $u->id !== auth()->id())
                                            <button type="button" wire:click="toggleUserActive({{ $u->id }})" class="inline-flex items-center gap-1 px-3 py-2 rounded-lg {{ $u->is_active ? 'bg-rose-50 text-rose-700 hover:bg-rose-100' : 'bg-emerald-50 text-emerald-700 hover:bg-emerald-100' }} text-[11px] font-extrabold transition">
                                                <i class="fa-solid {{ $u->is_active ? 'fa-user-slash' : 'fa-user-check' }} text-[10px]"></i>
                                                {{ $u->is_active ? 'Deactivate' : 'Activate' }}
                                            </button>
                                        @endif
                                    @endif
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="5" class="px-5 py-16 text-center">
                                <div class="mx-auto w-14 h-14 rounded-2xl bg-slate-100 text-slate-400 flex items-center justify-center">
                                    <i class="fa-solid fa-users-slash text-xl"></i>
                                </div>
                                <p class="mt-4 text-sm font-extrabold text-slate-700">No {{ strtolower($roleName) }}s Found</p>
                                <p class="mt-1 text-xs text-slate-500 font-medium">Verify if the filters match or try entering another search string.</p>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <!-- Table Footer Pagination -->
        <div class="p-5 sm:p-6 border-t border-slate-100 flex flex-col xl:flex-row xl:items-center xl:justify-between gap-4">
            <p class="text-xs text-slate-500 font-semibold font-poppins">
                Showing <span class="font-extrabold text-slate-800">{{ $users->firstItem() ?? 0 }}</span> to <span class="font-extrabold text-slate-800">{{ $users->lastItem() ?? 0 }}</span> of <span class="font-extrabold text-slate-800">{{ $users->total() }}</span> {{ strtolower($roleName) }}s
            </p>

            <div class="flex flex-col sm:flex-row sm:items-center gap-3">
                <form wire:submit="goToTypedPage" class="flex items-center gap-2">
                    <label class="text-xs font-bold text-slate-500">Go to</label>
                    <input wire:model="pageInput" type="number" min="1" max="{{ $users->lastPage() }}" class="w-16 rounded-lg border border-slate-200 px-2 py-1.5 text-xs font-extrabold text-slate-700 outline-none focus:border-emerald-400 focus:ring-4 focus:ring-emerald-100">
                    <button class="rounded-lg bg-slate-900 hover:bg-emerald-700 text-white px-2.5 py-1.5 text-xs font-extrabold transition">Go</button>
                </form>

                @if ($users->hasPages())
                    <div class="flex flex-wrap items-center gap-2">
                        <button type="button" wire:click="setPage(1)" @disabled($users->onFirstPage()) class="px-2.5 py-1.5 rounded-lg border border-slate-200 text-xs font-bold disabled:pointer-events-none disabled:opacity-40 hover:border-emerald-200 hover:text-emerald-700">First</button>
                        <button type="button" wire:click="previousPage" @disabled($users->onFirstPage()) class="px-2.5 py-1.5 rounded-lg border border-slate-200 text-xs font-bold disabled:pointer-events-none disabled:opacity-40 hover:border-emerald-200 hover:text-emerald-700">Prev</button>
                        @foreach ($paginationItems as $item)
                            @if ($item === '...')
                                <span class="px-1.5 py-1.5 text-xs font-black text-slate-300">...</span>
                            @else
                                <button type="button" wire:click="setPage({{ $item }})" class="min-w-8 text-center px-2.5 py-1.5 rounded-lg border text-xs font-extrabold {{ $item === $users->currentPage() ? 'bg-emerald-600 border-emerald-600 text-white' : 'border-slate-200 text-slate-600 hover:border-emerald-200 hover:text-emerald-700' }}">{{ $item }}</button>
                            @endif
                        @endforeach
                        <button type="button" wire:click="nextPage" @disabled(!$users->hasMorePages()) class="px-2.5 py-1.5 rounded-lg border border-slate-200 text-xs font-bold disabled:pointer-events-none disabled:opacity-40 hover:border-emerald-200 hover:text-emerald-700">Next</button>
                        <button type="button" wire:click="setPage({{ $users->lastPage() }})" @disabled($users->currentPage() === $users->lastPage()) class="px-2.5 py-1.5 rounded-lg border border-slate-200 text-xs font-bold disabled:pointer-events-none disabled:opacity-40 hover:border-emerald-200 hover:text-emerald-700">Last</button>
                    </div>
                @endif
            </div>
        </div>
    </section>

    <!-- Inspection/Audit Modal -->
    @if ($showDetailsModal && $selectedUserDetails)
        @php
            $u = $selectedUserDetails;
        @endphp
        <div class="fixed left-0 top-0 z-[9999] flex h-screen w-screen items-center justify-center p-4 bg-slate-950/60 backdrop-blur-sm" style="inset: 0;" aria-modal="true">
            <div class="relative w-full max-w-4xl bg-white rounded-3xl shadow-2xl border border-slate-100 flex flex-col max-h-[90vh] overflow-hidden" onclick="event.stopPropagation()">
                <!-- Modal Header -->
                <div class="p-6 border-b border-slate-100 flex items-start justify-between gap-4 shrink-0 bg-slate-50/50">
                    <div class="flex items-center gap-3">
                        <div class="w-12 h-12 rounded-2xl bg-white border border-slate-200 flex items-center justify-center font-extrabold text-sm shadow-sm overflow-hidden shrink-0 text-slate-500">
                            @if ($u->profile_picture_path)
                                <img src="{{ Str::startsWith($u->profile_picture_path, ['http://', 'https://']) ? $u->profile_picture_path : asset('storage/' . $u->profile_picture_path) }}" alt="{{ $u->full_name }}" class="w-full h-full object-cover">
                            @else
                                <span>{{ strtoupper(substr($u->full_name, 0, 2)) }}</span>
                            @endif
                        </div>
                        <div>
                            <h2 class="text-base font-extrabold text-slate-900">{{ $u->full_name }}</h2>
                            <p class="text-[11px] text-slate-400 font-bold mt-0.5">
                                UID #US{{ str_pad($u->id, 5, '0', STR_PAD_LEFT) }} • 
                                <span class="text-emerald-700 font-extrabold">{{ $roleName }}</span>
                            </p>
                        </div>
                    </div>
                    <button type="button" wire:click="closeDetailsModal" class="w-9 h-9 rounded-xl bg-white border border-slate-200 hover:bg-slate-50 text-slate-500 transition flex items-center justify-center shadow-sm">
                        <i class="fa-solid fa-xmark text-sm"></i>
                    </button>
                </div>

                <!-- Modal Tabs Selector -->
                <div class="px-6 border-b border-slate-100 flex gap-1 bg-slate-50 shrink-0 overflow-x-auto">
                    <button type="button" wire:click="changeTab('verification')" class="px-4 py-3 text-xs font-bold transition-all border-b-2 whitespace-nowrap {{ $activeTab === 'verification' ? 'border-emerald-600 text-emerald-700 font-extrabold' : 'border-transparent text-slate-500 hover:text-slate-900' }}">
                        <i class="fa-solid fa-clipboard-check mr-1.5"></i> Credentials & Audit
                    </button>
                    <button type="button" wire:click="changeTab('wallet')" class="px-4 py-3 text-xs font-bold transition-all border-b-2 whitespace-nowrap {{ $activeTab === 'wallet' ? 'border-emerald-600 text-emerald-700 font-extrabold' : 'border-transparent text-slate-500 hover:text-slate-900' }}">
                        <i class="fa-solid fa-wallet mr-1.5"></i> Wallet & Finance
                    </button>
                    @if (in_array($role, ['farmer', 'retail_seller', 'delivery_partner'], true))
                        <button type="button" wire:click="changeTab('performance')" class="px-4 py-3 text-xs font-bold transition-all border-b-2 whitespace-nowrap {{ $activeTab === 'performance' ? 'border-emerald-600 text-emerald-700 font-extrabold' : 'border-transparent text-slate-500 hover:text-slate-900' }}">
                            <i class="fa-solid fa-star mr-1.5"></i> Marketplace & Ratings
                        </button>
                    @endif
                    @if (in_array($role, ['delivery_partner', 'customer', 'buyer'], true))
                        <button type="button" wire:click="changeTab('history')" class="px-4 py-3 text-xs font-bold transition-all border-b-2 whitespace-nowrap {{ $activeTab === 'history' ? 'border-emerald-600 text-emerald-700 font-extrabold' : 'border-transparent text-slate-500 hover:text-slate-900' }}">
                            <i class="fa-solid fa-clock-rotate-left mr-1.5"></i> Rides & Activities
                        </button>
                    @endif
                </div>

                <!-- Modal Body -->
                <div class="flex-1 p-6 overflow-y-auto space-y-6">
                    
                    <!-- TAB 1: Credentials & Audit -->
                    @if ($activeTab === 'verification')
                        <!-- General Details Grid -->
                        <div class="bg-slate-50/50 border border-slate-100 rounded-2xl p-5 space-y-4">
                            <h4 class="text-[10px] font-black uppercase tracking-widest text-slate-400"><i class="fa-solid fa-address-card mr-2"></i>Profile Information</h4>
                            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                                <div>
                                    <span class="text-[10px] font-bold text-slate-400 block">Email Address</span>
                                    <strong class="text-xs text-slate-800 block mt-1 break-words">{{ $u->email ?? 'Not Registered' }}</strong>
                                </div>
                                <div>
                                    <span class="text-[10px] font-bold text-slate-400 block">Phone Numbers</span>
                                    <strong class="text-xs text-slate-800 block mt-1">{{ $u->phone_number }} {{ $u->phone_number_2 ? '/ ' . $u->phone_number_2 : '' }}</strong>
                                </div>
                                <div>
                                    <span class="text-[10px] font-bold text-slate-400 block">National Identity Number</span>
                                    <strong class="text-xs text-slate-800 block mt-1">{{ $u->national_id ?? 'Not Provided' }}</strong>
                                </div>
                                <div class="md:col-span-2">
                                    <span class="text-[10px] font-bold text-slate-400 block">Registered Address</span>
                                    <strong class="text-xs text-slate-800 block mt-1">{{ $u->address ?? 'Not Provided' }}, {{ $u->city ?? '' }}, {{ $u->district ?? '' }} ({{ $u->province ?? '' }})</strong>
                                </div>
                                <div>
                                    <span class="text-[10px] font-bold text-slate-400 block">Geo Coordinates</span>
                                    <strong class="text-xs text-slate-800 block mt-1">
                                        @if ($u->latitude && $u->longitude)
                                            {{ $u->latitude }}, {{ $u->longitude }}
                                            <a href="https://www.google.com/maps/search/?api=1&query={{ $u->latitude }},{{ $u->longitude }}" target="_blank" class="ml-1.5 text-emerald-600 hover:text-emerald-700"><i class="fa-solid fa-map-location-dot"></i></a>
                                        @else
                                            Not Available
                                        @endif
                                    </strong>
                                </div>
                            </div>
                        </div>

                        <!-- Role Specific Verifications -->
                        @if ($role === 'farmer' && $selectedUserVerificationData)
                            @php
                                $f = $selectedUserVerificationData;
                            @endphp
                            <div class="space-y-4">
                                <h4 class="text-[10px] font-black uppercase tracking-widest text-slate-400"><i class="fa-solid fa-seedling mr-2"></i>Farming Certificates & Licenses</h4>
                                <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                                    <!-- Farming License -->
                                    <div class="bg-white border border-slate-100 rounded-2xl p-4 shadow-sm flex flex-col justify-between">
                                        <div>
                                            <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">Farming License</span>
                                            <strong class="text-xs text-slate-800 block mt-1">{{ $f->farming_license_number ?? 'No Number Provided' }}</strong>
                                        </div>
                                        @if ($f->farming_license_path)
                                            @php
                                                $licenseUrl = Str::startsWith($f->farming_license_path, ['http://', 'https://']) ? $f->farming_license_path : (Str::startsWith($f->farming_license_path, 'storage/') ? asset($f->farming_license_path) : asset('storage/' . $f->farming_license_path));
                                            @endphp
                                            <div class="mt-4">
                                                <a href="{{ $licenseUrl }}" target="_blank" class="inline-flex items-center gap-1.5 px-3 py-2 rounded-lg bg-emerald-50 hover:bg-emerald-100 text-emerald-700 text-xs font-bold border border-emerald-100 transition">
                                                    <i class="fa-solid fa-file-pdf"></i>
                                                    View License File
                                                </a>
                                            </div>
                                        @else
                                            <span class="text-[10px] text-slate-400 italic block mt-4">No file uploaded</span>
                                        @endif
                                    </div>

                                    <!-- Organic Cert -->
                                    <div class="bg-white border border-slate-100 rounded-2xl p-4 shadow-sm flex flex-col justify-between">
                                        <div>
                                            <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">Organic Certification</span>
                                            <strong class="text-xs text-slate-800 block mt-1">{{ $f->organic_certificate_number ?? 'No Certificate Number' }}</strong>
                                            @if ($f->organic_certificate_expiry)
                                                <span class="text-[10px] text-slate-400 block mt-1">Expiry: {{ $f->organic_certificate_expiry }}</span>
                                            @endif
                                        </div>
                                        @if ($f->organic_certificate_path)
                                            @php
                                                $organicUrl = Str::startsWith($f->organic_certificate_path, ['http://', 'https://']) ? $f->organic_certificate_path : (Str::startsWith($f->organic_certificate_path, 'storage/') ? asset($f->organic_certificate_path) : asset('storage/' . $f->organic_certificate_path));
                                            @endphp
                                            <div class="mt-4">
                                                <a href="{{ $organicUrl }}" target="_blank" class="inline-flex items-center gap-1.5 px-3 py-2 rounded-lg bg-emerald-50 hover:bg-emerald-100 text-emerald-700 text-xs font-bold border border-emerald-100 transition">
                                                    <i class="fa-solid fa-file-pdf"></i>
                                                    View Organic Cert
                                                </a>
                                            </div>
                                        @else
                                            <span class="text-[10px] text-slate-400 italic block mt-4">No file uploaded</span>
                                        @endif
                                    </div>

                                    <!-- GAP Cert -->
                                    <div class="bg-white border border-slate-100 rounded-2xl p-4 shadow-sm flex flex-col justify-between">
                                        <div>
                                            <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">GAP Certification</span>
                                            <strong class="text-xs text-slate-800 block mt-1">{{ $f->gap_certificate_number ?? 'No GAP Number' }}</strong>
                                            @if ($f->gap_certificate_expiry)
                                                <span class="text-[10px] text-slate-400 block mt-1">Expiry: {{ $f->gap_certificate_expiry }}</span>
                                            @endif
                                        </div>
                                        @if ($f->gap_certificate_path)
                                            @php
                                                $gapUrl = Str::startsWith($f->gap_certificate_path, ['http://', 'https://']) ? $f->gap_certificate_path : (Str::startsWith($f->gap_certificate_path, 'storage/') ? asset($f->gap_certificate_path) : asset('storage/' . $f->gap_certificate_path));
                                            @endphp
                                            <div class="mt-4">
                                                <a href="{{ $gapUrl }}" target="_blank" class="inline-flex items-center gap-1.5 px-3 py-2 rounded-lg bg-emerald-50 hover:bg-emerald-100 text-emerald-700 text-xs font-bold border border-emerald-100 transition">
                                                    <i class="fa-solid fa-file-pdf"></i>
                                                    View GAP Cert
                                                </a>
                                            </div>
                                        @else
                                            <span class="text-[10px] text-slate-400 italic block mt-4">No file uploaded</span>
                                        @endif
                                    </div>
                                </div>
                            </div>
                        @endif

                        @if ($role === 'retail_seller' && $selectedUserVerificationData)
                            @php
                                $r = $selectedUserVerificationData;
                                $brUrl = Str::startsWith($r->br_image_path, ['http://', 'https://']) ? $r->br_image_path : (Str::startsWith($r->br_image_path, 'storage/') ? asset($r->br_image_path) : asset('storage/' . $r->br_image_path));
                            @endphp
                            <div class="space-y-4">
                                <h4 class="text-[10px] font-black uppercase tracking-widest text-slate-400"><i class="fa-solid fa-store mr-2"></i>Business Registration & Shop Photos</h4>
                                <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                                    <div class="bg-white border border-slate-100 rounded-2xl p-4 shadow-sm space-y-3">
                                        <div>
                                            <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">BR Number</span>
                                            <strong class="text-xs text-slate-800 block mt-1">{{ $r->br_number ?? 'Not Provided' }}</strong>
                                        </div>
                                        <div>
                                            <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">BR Date Range</span>
                                            <strong class="text-xs text-slate-800 block mt-1">Issue: {{ $r->br_issue_date ?? 'N/A' }}<br>Expiry: {{ $r->br_expiry_date ?? 'N/A' }}</strong>
                                        </div>
                                    </div>

                                    <div class="bg-white border border-slate-100 rounded-2xl p-4 shadow-sm space-y-3">
                                        <div>
                                            <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">Business / Ownership</span>
                                            <strong class="text-xs text-slate-800 block mt-1">Type: {{ ucwords(str_replace('_', ' ', $r->business_type ?? 'N/A')) }}<br>Ownership: {{ ucwords(str_replace('_', ' ', $r->ownership_type ?? 'N/A')) }}</strong>
                                        </div>
                                        <div>
                                            <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">Shop Postal Code</span>
                                            <strong class="text-xs text-slate-800 block mt-1">{{ $r->postal_code ?? 'N/A' }}</strong>
                                        </div>
                                    </div>

                                    <div class="bg-white border border-slate-100 rounded-2xl p-4 shadow-sm flex flex-col justify-between">
                                        <div>
                                            <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">BR Document Image</span>
                                        </div>
                                        @if ($r->br_image_path)
                                            <div class="mt-4">
                                                <a href="{{ $brUrl }}" target="_blank" class="inline-flex items-center gap-1.5 px-3 py-2 rounded-lg bg-blue-50 hover:bg-blue-100 text-blue-700 text-xs font-bold border border-blue-100 transition">
                                                    <i class="fa-solid fa-image"></i>
                                                    Open BR File
                                                </a>
                                            </div>
                                        @else
                                            <span class="text-[10px] text-slate-400 italic block mt-4">No file uploaded</span>
                                        @endif
                                    </div>
                                </div>

                                @if ($r->shop_photos)
                                    @php
                                        $photos = json_decode($r->shop_photos, true) ?: [];
                                    @endphp
                                    @if (count($photos) > 0)
                                        <div class="bg-slate-50/50 border border-slate-100 rounded-2xl p-5 space-y-3">
                                            <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">Shop Premises Gallery</span>
                                            <div class="flex flex-wrap gap-4 mt-2">
                                                @foreach ($photos as $photo)
                                                    @php
                                                        $pUrl = Str::startsWith($photo, ['http://', 'https://']) ? $photo : (Str::startsWith($photo, 'storage/') ? asset($photo) : asset('storage/' . $photo));
                                                    @endphp
                                                    <a href="{{ $pUrl }}" target="_blank" class="w-24 h-24 rounded-xl border border-slate-200 overflow-hidden shadow-sm hover:scale-105 transition-transform">
                                                        <img src="{{ $pUrl }}" alt="Shop photo" class="w-full h-full object-cover">
                                                    </a>
                                                @endforeach
                                            </div>
                                        </div>
                                    @endif
                                @endif
                            </div>
                        @endif

                        @if ($role === 'delivery_partner' && $selectedUserVerificationData)
                            @php
                                $d = $selectedUserVerificationData;
                                $insUrl = Str::startsWith($d->insurance_image_path, ['http://', 'https://']) ? $d->insurance_image_path : (Str::startsWith($d->insurance_image_path, 'storage/') ? asset($d->insurance_image_path) : asset('storage/' . $d->insurance_image_path));
                                $revUrl = Str::startsWith($d->revenue_license_image_path, ['http://', 'https://']) ? $d->revenue_license_image_path : (Str::startsWith($d->revenue_license_image_path, 'storage/') ? asset($d->revenue_license_image_path) : asset('storage/' . $d->revenue_license_image_path));
                            @endphp
                            <div class="space-y-4">
                                <h4 class="text-[10px] font-black uppercase tracking-widest text-slate-400"><i class="fa-solid fa-truck-fast mr-2"></i>Vehicle & License Parameters</h4>
                                <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                                    <div class="bg-white border border-slate-100 rounded-2xl p-4 shadow-sm space-y-3">
                                        <div>
                                            <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">Vehicle Specification</span>
                                            <strong class="text-xs text-slate-800 block mt-1">{{ ucwords(str_replace('_', ' ', $d->vehicle_type ?? 'N/A')) }} • {{ $d->vehicle_make ?? '' }} {{ $d->model ?? '' }} ({{ $d->year ?? '' }})</strong>
                                        </div>
                                        <div>
                                            <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">Color & Max Weight</span>
                                            <strong class="text-xs text-slate-800 block mt-1">Color: {{ $d->color ?? 'N/A' }}<br>Max Capacity: {{ $d->max_weight ?? 'N/A' }} kg</strong>
                                        </div>
                                    </div>

                                    <div class="bg-white border border-slate-100 rounded-2xl p-4 shadow-sm space-y-3">
                                        <div>
                                            <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">Registration Number</span>
                                            <strong class="text-xs text-slate-800 block mt-1">{{ $d->registration_number ?? 'N/A' }}</strong>
                                        </div>
                                        <div>
                                            <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">Driver License Expiry</span>
                                            <strong class="text-xs text-slate-800 block mt-1">{{ $d->driving_license_expiry_date ?? 'N/A' }}</strong>
                                        </div>
                                    </div>

                                    <div class="bg-white border border-slate-100 rounded-2xl p-4 shadow-sm space-y-3">
                                        <div>
                                            <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">Insurance & Revenue Expiry</span>
                                            <strong class="text-xs text-slate-800 block mt-1">Insurance: {{ $d->insurance_expiry ?? 'N/A' }}<br>Revenue: {{ $d->revenue_license_expiry ?? 'N/A' }}</strong>
                                        </div>
                                    </div>
                                </div>

                                <div class="grid grid-cols-1 md:grid-cols-2 gap-6 bg-slate-50/50 border border-slate-100 rounded-2xl p-5">
                                    <div class="flex flex-col justify-between">
                                        <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">Insurance Certificate</span>
                                        @if ($d->insurance_image_path)
                                            <div class="mt-4">
                                                <a href="{{ $insUrl }}" target="_blank" class="inline-flex items-center gap-1.5 px-3 py-2 rounded-lg bg-indigo-50 hover:bg-indigo-100 text-indigo-700 text-xs font-bold border border-indigo-100 transition">
                                                    <i class="fa-solid fa-shield-halved"></i>
                                                    View Insurance Document
                                                </a>
                                            </div>
                                        @else
                                            <span class="text-[10px] text-slate-400 italic mt-4 block">No insurance document uploaded</span>
                                        @endif
                                    </div>

                                    <div class="flex flex-col justify-between">
                                        <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">Revenue License</span>
                                        @if ($d->revenue_license_image_path)
                                            <div class="mt-4">
                                                <a href="{{ $revUrl }}" target="_blank" class="inline-flex items-center gap-1.5 px-3 py-2 rounded-lg bg-indigo-50 hover:bg-indigo-100 text-indigo-700 text-xs font-bold border border-indigo-100 transition">
                                                    <i class="fa-solid fa-passport"></i>
                                                    View Revenue License
                                                </a>
                                            </div>
                                        @else
                                            <span class="text-[10px] text-slate-400 italic mt-4 block">No revenue license uploaded</span>
                                        @endif
                                    </div>
                                </div>
                            </div>
                        @endif

                        @if (in_array($role, ['buyer', 'customer', 'farmer'], true) && count($selectedUserDocuments) > 0)
                            <div class="space-y-4">
                                <h4 class="text-[10px] font-black uppercase tracking-widest text-slate-400"><i class="fa-solid fa-folder-open mr-2"></i>Uploaded Verification Documents</h4>
                                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                                    @foreach ($selectedUserDocuments as $doc)
                                        @php
                                            $fUrl = Str::startsWith($doc->front_image_path, ['http://', 'https://']) ? $doc->front_image_path : (Str::startsWith($doc->front_image_path, 'storage/') ? asset($doc->front_image_path) : asset('storage/' . $doc->front_image_path));
                                            $bUrl = $doc->back_image_path ? (Str::startsWith($doc->back_image_path, ['http://', 'https://']) ? $doc->back_image_path : (Str::startsWith($doc->back_image_path, 'storage/') ? asset($doc->back_image_path) : asset('storage/' . $doc->back_image_path))) : null;
                                            $badgeClass = [
                                                'pending' => 'bg-amber-50 text-amber-700 border-amber-100',
                                                'approved' => 'bg-emerald-50 text-emerald-700 border-emerald-100',
                                                'rejected' => 'bg-rose-50 text-rose-700 border-rose-100',
                                            ][$doc->verification_status] ?? 'bg-slate-50 text-slate-600 border-slate-100';
                                        @endphp
                                        <div class="bg-white border border-slate-100 rounded-3xl p-5 shadow-sm space-y-4">
                                            <div class="flex justify-between items-center">
                                                <div>
                                                    <strong class="text-xs text-slate-800 uppercase tracking-wider block">{{ ucwords(str_replace('_', ' ', $doc->document_type)) }}</strong>
                                                    <span class="text-[9px] text-slate-400 font-semibold block mt-0.5">Uploaded on {{ \Carbon\Carbon::parse($doc->created_at)->format('M d, Y') }}</span>
                                                </div>
                                                <span class="inline-flex items-center rounded-full border px-2 py-0.5 text-[8px] font-black uppercase tracking-wider {{ $badgeClass }}">{{ $doc->verification_status }}</span>
                                            </div>

                                            @if ($doc->front_image_path !== 'placeholder_rejected')
                                                <div class="flex gap-4">
                                                    <a href="{{ $fUrl }}" target="_blank" class="w-1/2 h-28 rounded-xl border border-slate-200 overflow-hidden shadow-inner flex flex-col bg-slate-50 animate-pulse-slow">
                                                        <img src="{{ $fUrl }}" alt="Doc front" class="w-full h-24 object-cover">
                                                        <span class="text-[8px] text-center font-bold uppercase text-slate-400 py-0.5">Front View</span>
                                                    </a>
                                                    @if ($bUrl)
                                                        <a href="{{ $bUrl }}" target="_blank" class="w-1/2 h-28 rounded-xl border border-slate-200 overflow-hidden shadow-inner flex flex-col bg-slate-50">
                                                            <img src="{{ $bUrl }}" alt="Doc back" class="w-full h-24 object-cover">
                                                            <span class="text-[8px] text-center font-bold uppercase text-slate-400 py-0.5">Back View</span>
                                                        </a>
                                                    @endif
                                                </div>
                                            @endif

                                            @if ($doc->rejection_reason)
                                                <div class="p-3 rounded-xl bg-rose-50 text-rose-700 text-xs font-semibold border border-rose-100">
                                                    <strong>Rejection Reason:</strong> {{ $doc->rejection_reason }}
                                                </div>
                                            @endif
                                        </div>
                                    @endforeach
                                </div>
                            </div>
                        @endif

                        @if ($role === 'admin')
                            <div class="bg-slate-50 border border-slate-100 rounded-2xl p-5 text-center">
                                <span class="text-slate-400 text-xs font-semibold"><i class="fa-solid fa-circle-exclamation mr-1.5"></i>Administrators do not go through document verification pipelines.</span>
                            </div>
                        @endif

                        <!-- Active Toggle (Banning) -->
                        @if ($u->id !== session('admin_session.user_id') && $u->id !== auth()->id())
                            <div class="bg-slate-50 border border-slate-100 rounded-2xl p-5 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mt-6">
                                <div>
                                    <strong class="text-xs text-slate-800 block font-bold">Account Access Toggle</strong>
                                    <span class="text-[10px] text-slate-400 font-semibold block mt-0.5">Banned users are locked out of their active sessions and mobile app dashboard.</span>
                                </div>
                                <button type="button" wire:click="toggleUserActive({{ $u->id }})" class="inline-flex items-center gap-1.5 px-4 py-2.5 rounded-xl text-xs font-bold transition border {{ $u->is_active ? 'bg-rose-50 border-rose-100 text-rose-700 hover:bg-rose-100' : 'bg-emerald-50 border-emerald-100 text-emerald-700 hover:bg-emerald-100' }}">
                                    <i class="fa-solid {{ $u->is_active ? 'fa-user-slash' : 'fa-user-check' }}"></i>
                                    {{ $u->is_active ? 'Deactivate / Ban User' : 'Restore / Activate User' }}
                                </button>
                            </div>
                        @endif
                    @endif

                    <!-- TAB 2: Wallet & Finance -->
                    @if ($activeTab === 'wallet')
                        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                            <!-- Wallet Stats Card -->
                            <div class="md:col-span-1 bg-white border border-slate-100 rounded-3xl p-6 shadow-sm space-y-6 relative overflow-hidden flex flex-col justify-between">
                                <div class="absolute -right-6 -top-6 w-24 h-24 bg-emerald-50 rounded-full blur-2xl"></div>
                                <div class="space-y-4">
                                    <span class="text-[10px] font-black text-slate-400 uppercase tracking-widest block"><i class="fa-solid fa-wallet mr-1.5 text-emerald-500"></i>Account Wallet</span>
                                    
                                    @if ($selectedUserWallet)
                                        <div>
                                            <span class="text-[10px] font-bold text-slate-400 block">Available Balance</span>
                                            <strong class="text-3xl font-black text-slate-900 block mt-1 tracking-tight">LKR {{ number_format($selectedUserWallet->available_balance, 2) }}</strong>
                                        </div>
                                        <div class="grid grid-cols-2 gap-2 pt-2">
                                            <div>
                                                <span class="text-[9px] font-bold text-slate-400 block">Pending Balance</span>
                                                <strong class="text-xs text-amber-700 font-bold mt-0.5 block">LKR {{ number_format($selectedUserWallet->pending_balance, 2) }}</strong>
                                            </div>
                                            <div>
                                                <span class="text-[9px] font-bold text-slate-400 block">Lifetime Earnings</span>
                                                <strong class="text-xs text-emerald-700 font-bold mt-0.5 block">LKR {{ number_format($selectedUserWallet->total_earned, 2) }}</strong>
                                            </div>
                                        </div>
                                    @else
                                        <div class="py-4 text-center text-slate-400 text-xs font-semibold">
                                            No active wallet found for this user.
                                        </div>
                                    @endif
                                </div>
                                <div class="pt-4 border-t border-slate-50">
                                    <span class="text-[9px] font-semibold text-slate-400 leading-relaxed block">Commission and withdrawal fees apply according to system treasury policy.</span>
                                </div>
                            </div>

                            <!-- Transactions List -->
                            <div class="md:col-span-2 bg-white border border-slate-100 rounded-3xl p-6 shadow-sm space-y-4">
                                <span class="text-[10px] font-black text-slate-400 uppercase tracking-widest block"><i class="fa-solid fa-list-ol mr-1.5 text-slate-400"></i>Recent Transaction Ledger</span>
                                <div class="overflow-hidden border border-slate-100 rounded-xl">
                                    <table class="min-w-full divide-y divide-slate-100 text-xs">
                                        <thead class="bg-slate-50">
                                            <tr>
                                                <th class="px-4 py-2 text-left font-bold text-slate-400">Ledger Description</th>
                                                <th class="px-4 py-2 text-left font-bold text-slate-400">Type</th>
                                                <th class="px-4 py-2 text-right font-bold text-slate-400">Amount</th>
                                                <th class="px-4 py-2 text-center font-bold text-slate-400">Status</th>
                                            </tr>
                                        </thead>
                                        <tbody class="divide-y divide-slate-100 bg-white">
                                            @forelse ($selectedUserTransactions as $tx)
                                                @php
                                                    $txTypeLabel = [
                                                        'withdrawal' => 'Withdraw',
                                                        'refund' => 'Refund',
                                                        'commission' => 'Platform fee',
                                                        'other' => 'Deposit/Bonus',
                                                    ][$tx->transaction_type] ?? 'Transaction';
                                                    $txColor = in_array($tx->transaction_type, ['withdrawal', 'commission'], true) ? 'text-rose-600 font-semibold' : 'text-emerald-600 font-bold';
                                                    $txSign = in_array($tx->transaction_type, ['withdrawal', 'commission'], true) ? '-' : '+';
                                                    
                                                    $badgeTx = [
                                                        'completed' => 'bg-emerald-50 text-emerald-700',
                                                        'pending' => 'bg-amber-50 text-amber-700',
                                                        'failed' => 'bg-rose-50 text-rose-700',
                                                    ][$tx->status] ?? 'bg-slate-50 text-slate-500';
                                                @endphp
                                                <tr class="hover:bg-slate-50/50">
                                                    <td class="px-4 py-2.5">
                                                        <p class="font-bold text-slate-800">{{ $tx->description }}</p>
                                                        <span class="text-[9px] text-slate-400 font-medium block mt-0.5">{{ \Carbon\Carbon::parse($tx->created_at)->format('M d, Y h:i A') }}</span>
                                                    </td>
                                                    <td class="px-4 py-2.5 font-semibold text-slate-500">{{ $txTypeLabel }}</td>
                                                    <td class="px-4 py-2.5 text-right {{ $txColor }}">{{ $txSign }} LKR {{ number_format($tx->amount, 2) }}</td>
                                                    <td class="px-4 py-2.5 text-center">
                                                        <span class="inline-block px-2 py-0.5 rounded text-[9px] font-extrabold uppercase {{ $badgeTx }}">{{ $tx->status }}</span>
                                                    </td>
                                                </tr>
                                            @empty
                                                <tr>
                                                    <td colspan="4" class="px-4 py-6 text-center text-slate-400 italic">No transaction records found.</td>
                                                </tr>
                                            @endforelse
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>
                    @endif

                    <!-- TAB 3: Marketplace & Performance -->
                    @if ($activeTab === 'performance')
                        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                            <!-- Ratings Overview -->
                            <div class="md:col-span-1 bg-white border border-slate-100 rounded-3xl p-6 shadow-sm flex flex-col justify-between space-y-4">
                                <div class="space-y-3">
                                    <span class="text-[10px] font-black text-slate-400 uppercase tracking-widest block"><i class="fa-solid fa-ranking-star mr-1.5 text-amber-500"></i>Overall Score</span>
                                    <div class="flex items-baseline gap-2">
                                        <strong class="text-4xl font-black text-slate-900 tracking-tight">{{ number_format($selectedUserRating, 1) }}</strong>
                                        <span class="text-xs text-slate-400 font-bold">/ 5.0</span>
                                    </div>
                                    <div class="flex items-center gap-1 text-amber-400">
                                        @for ($i = 1; $i <= 5; $i++)
                                            @if ($i <= round($selectedUserRating))
                                                <i class="fa-solid fa-star text-xs"></i>
                                            @else
                                                <i class="fa-regular fa-star text-xs"></i>
                                            @endif
                                        @endfor
                                        <span class="text-[10px] text-slate-400 font-bold ml-1.5">({{ count($selectedUserReviews) }} reviews)</span>
                                    </div>
                                </div>
                                <div class="pt-4 border-t border-slate-100">
                                    <span class="text-[9px] font-semibold text-slate-400 leading-normal block">Ratings and feedback comments are dynamically posted by verified retail customers and wholesale buyers.</span>
                                </div>
                            </div>

                            <!-- Listings/Products List -->
                            <div class="md:col-span-2 bg-white border border-slate-100 rounded-3xl p-6 shadow-sm space-y-4">
                                <span class="text-[10px] font-black text-slate-400 uppercase tracking-widest block">
                                    <i class="fa-solid fa-boxes-stacked mr-1.5 text-slate-400"></i>
                                    {{ $role === 'farmer' ? 'Active Harvest Yields' : 'Retail Catalog Products' }}
                                </span>
                                <div class="overflow-hidden border border-slate-100 rounded-xl">
                                    <table class="min-w-full divide-y divide-slate-100 text-xs">
                                        <thead class="bg-slate-50">
                                            <tr>
                                                <th class="px-4 py-2 text-left font-bold text-slate-400">Listed Item</th>
                                                <th class="px-4 py-2 text-right font-bold text-slate-400">Price / Unit</th>
                                                <th class="px-4 py-2 text-right font-bold text-slate-400">Stock / Qty</th>
                                                <th class="px-4 py-2 text-center font-bold text-slate-400">Status</th>
                                            </tr>
                                        </thead>
                                        <tbody class="divide-y divide-slate-100 bg-white">
                                            @forelse ($selectedUserListings as $item)
                                                @php
                                                    $itemStatus = $item->status ?? 'active';
                                                    $itemBadge = [
                                                        'active' => 'bg-emerald-50 text-emerald-700',
                                                        'pending_approval' => 'bg-amber-50 text-amber-700',
                                                        'out_of_stock' => 'bg-rose-50 text-rose-700',
                                                        'inactive' => 'bg-slate-50 text-slate-500',
                                                    ][$itemStatus] ?? 'bg-slate-50 text-slate-500';
                                                    $unit = $item->unit_type ?? ($item->unit ?? 'kg');
                                                @endphp
                                                <tr class="hover:bg-slate-50/50">
                                                    <td class="px-4 py-2.5">
                                                        <p class="font-bold text-slate-800">{{ $item->product_name ?? ($item->crop_name ?? 'Market item') }}</p>
                                                        <span class="text-[9px] text-slate-400 font-medium block mt-0.5">Grade {{ $item->grade }} • {{ $item->crop_name ?? 'Agricultural Crop' }}</span>
                                                    </td>
                                                    <td class="px-4 py-2.5 text-right font-extrabold text-slate-700">LKR {{ number_format($item->price_per_unit, 2) }}</td>
                                                    <td class="px-4 py-2.5 text-right font-semibold text-slate-600">{{ number_format($item->stock_quantity ?? ($item->available_quantity ?? 0), 2) }} {{ $unit }}</td>
                                                    <td class="px-4 py-2.5 text-center">
                                                        <span class="inline-block px-2 py-0.5 rounded text-[9px] font-extrabold uppercase {{ $itemBadge }}">{{ $itemStatus }}</span>
                                                    </td>
                                                </tr>
                                            @empty
                                                <tr>
                                                    <td colspan="4" class="px-4 py-6 text-center text-slate-400 italic">No listed items found.</td>
                                                </tr>
                                            @endforelse
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>

                        <!-- Feedback Comments List -->
                        <div class="bg-white border border-slate-100 rounded-3xl p-6 shadow-sm space-y-4">
                            <span class="text-[10px] font-black text-slate-400 uppercase tracking-widest block"><i class="fa-solid fa-comments mr-1.5 text-slate-400"></i>Audited Feedback Reviews</span>
                            <div class="space-y-4">
                                @forelse ($selectedUserReviews as $rev)
                                    <div class="p-4 bg-slate-50/50 border border-slate-100 rounded-2xl flex items-start gap-4">
                                        <div class="w-9 h-9 rounded-full bg-slate-200 flex items-center justify-center font-bold text-xs shrink-0 overflow-hidden shadow-inner">
                                            @if ($rev->reviewer_avatar)
                                                <img src="{{ Str::startsWith($rev->reviewer_avatar, ['http://', 'https://']) ? $rev->reviewer_avatar : asset('storage/' . $rev->reviewer_avatar) }}" class="w-full h-full object-cover">
                                            @else
                                                <span>{{ strtoupper(substr($rev->reviewer_name ?? 'C', 0, 2)) }}</span>
                                            @endif
                                        </div>
                                        <div class="space-y-1 flex-1 min-w-0">
                                            <div class="flex items-center justify-between">
                                                <strong class="text-xs font-bold text-slate-800">{{ $rev->reviewer_name }}</strong>
                                                <div class="flex items-center text-amber-400 text-[10px]">
                                                    @for ($i = 1; $i <= 5; $i++)
                                                        @if ($i <= $rev->ratings)
                                                            <i class="fa-solid fa-star"></i>
                                                        @else
                                                            <i class="fa-regular fa-star"></i>
                                                        @endif
                                                    @endfor
                                                </div>
                                            </div>
                                            <p class="text-xs text-slate-600 font-medium leading-relaxed mt-1">{{ $rev->feedback }}</p>
                                            <span class="text-[9px] text-slate-400 font-bold block mt-1.5">{{ \Carbon\Carbon::parse($rev->created_at)->diffForHumans() }}</span>
                                        </div>
                                    </div>
                                @empty
                                    <div class="py-6 text-center text-slate-400 italic text-xs">No feedback reviews have been registered.</div>
                                @endforelse
                            </div>
                        </div>
                    @endif

                    <!-- TAB 4: History & Activity -->
                    @if ($activeTab === 'history')
                        <div class="bg-white border border-slate-100 rounded-3xl p-6 shadow-sm space-y-4">
                            <span class="text-[10px] font-black text-slate-400 uppercase tracking-widest block"><i class="fa-solid fa-history mr-1.5 text-slate-400"></i>Consolidated Operational Activity History</span>
                            <div class="overflow-hidden border border-slate-100 rounded-xl">
                                <table class="min-w-full divide-y divide-slate-100 text-xs">
                                    <thead class="bg-slate-50">
                                        <tr>
                                            <th class="px-4 py-2.5 text-left font-bold text-slate-400">Reference / Activity</th>
                                            <th class="px-4 py-2.5 text-left font-bold text-slate-400">{{ $role === 'delivery_partner' ? 'Customer' : ($role === 'customer' ? 'Seller' : 'Crop Yield') }}</th>
                                            <th class="px-4 py-2.5 text-right font-bold text-slate-400">Transaction Value</th>
                                            <th class="px-4 py-2.5 text-center font-bold text-slate-400">Status</th>
                                        </tr>
                                    </thead>
                                    <tbody class="divide-y divide-slate-100 bg-white">
                                        @forelse ($selectedUserHistory as $hist)
                                            @php
                                                $refNum = $hist->order_number ?? ('BID #CB' . str_pad($hist->id, 4, '0', STR_PAD_LEFT));
                                                $destName = $hist->customer_name ?? ($hist->seller_name ?? ($hist->crop_name ?? 'Market Deal'));
                                                $amountVal = $hist->total_amount ?? ($hist->total_amount ?? 0);
                                                
                                                $statusTxt = $hist->order_status ?? ($hist->payment_status ?? 'completed');
                                                $histBadge = [
                                                    'completed' => 'bg-emerald-50 text-emerald-700',
                                                    'delivered' => 'bg-emerald-50 text-emerald-700',
                                                    'paid' => 'bg-emerald-50 text-emerald-700',
                                                    'pending' => 'bg-amber-50 text-amber-700',
                                                    'processing' => 'bg-blue-50 text-blue-700',
                                                    'cancelled' => 'bg-rose-50 text-rose-700',
                                                ][$statusTxt] ?? 'bg-slate-50 text-slate-500';
                                            @endphp
                                            <tr class="hover:bg-slate-50/50">
                                                <td class="px-4 py-3">
                                                    <strong class="font-extrabold text-slate-800 block">{{ $refNum }}</strong>
                                                    <span class="text-[9px] text-slate-400 font-medium block mt-0.5">Recorded: {{ \Carbon\Carbon::parse($hist->created_at)->format('M d, Y h:i A') }}</span>
                                                </td>
                                                <td class="px-4 py-3 font-semibold text-slate-600">{{ $destName }}</td>
                                                <td class="px-4 py-3 text-right font-extrabold text-slate-800">LKR {{ number_format($amountVal, 2) }}</td>
                                                <td class="px-4 py-3 text-center">
                                                    <span class="inline-block px-2 py-0.5 rounded text-[9px] font-black uppercase tracking-wider {{ $histBadge }}">{{ $statusTxt }}</span>
                                                </td>
                                            </tr>
                                        @empty
                                            <tr>
                                                <td colspan="4" class="px-4 py-8 text-center text-slate-400 italic">No operational logs exist for this user.</td>
                                            </tr>
                                        @endforelse
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    @endif

                </div>

                <!-- Modal Footer Actions (Verification Approval/Rejection) -->
                @if ($role !== 'admin')
                    <div class="p-6 border-t border-slate-100 flex flex-col md:flex-row gap-4 shrink-0 bg-slate-50/50">
                        @if (!$u->is_verified)
                            <!-- Approve Action -->
                            <div class="w-full md:w-1/3">
                                <button type="button" wire:confirm="Approve this user's verification?" wire:click="approveUser({{ $u->id }})" class="w-full inline-flex items-center justify-center gap-2 px-4 py-3 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-extrabold shadow-md shadow-emerald-500/20 transition">
                                    <i class="fa-solid fa-certificate"></i>
                                    Verify & Approve User
                                </button>
                            </div>

                            <!-- Reject Action Form -->
                            <div class="w-full md:w-2/3 flex flex-col md:flex-row gap-3 items-stretch">
                                <div class="flex-1">
                                    <input wire:model="rejectionReason" type="text" class="w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-xs font-semibold text-slate-800 outline-none focus:border-rose-400 focus:ring-4 focus:ring-rose-100 transition" placeholder="Explain verification rejection reason...">
                                    @error('rejectionReason') <span class="text-[10px] font-bold text-rose-600 block mt-1.5">{{ $message }}</span> @enderror
                                </div>
                                <button type="button" wire:click="rejectUser({{ $u->id }})" class="inline-flex items-center justify-center gap-1.5 px-5 py-3 rounded-xl bg-rose-600 hover:bg-rose-700 text-white text-xs font-extrabold shadow-md shadow-rose-500/10 transition shrink-0">
                                    <i class="fa-solid fa-triangle-exclamation"></i>
                                    Reject
                                </button>
                            </div>
                        @else
                            <!-- Revoke Verification Form -->
                            <div class="w-full flex items-center justify-between p-4 bg-emerald-50/50 border border-emerald-100/50 rounded-2xl">
                                <div class="flex items-center gap-2 text-emerald-800 text-xs font-bold">
                                    <i class="fa-solid fa-circle-check text-emerald-600 text-sm"></i>
                                    This user is currently verified & approved.
                                </div>
                                <div class="flex gap-2 items-center flex-1 max-w-md justify-end ml-4">
                                    <input wire:model="rejectionReason" type="text" class="flex-1 rounded-xl border border-slate-200 bg-white px-3 py-2 text-xs font-semibold text-slate-800 outline-none focus:border-rose-400 focus:ring-4 focus:ring-rose-100 transition" placeholder="Reason to revoke / reject...">
                                    <button type="button" wire:click="rejectUser({{ $u->id }})" class="px-4 py-2 rounded-xl bg-rose-600 hover:bg-rose-700 text-white text-xs font-bold transition shrink-0">
                                        Revoke Status
                                    </button>
                                </div>
                            </div>
                        @endif
                    </div>
                @else
                    <div class="p-6 border-t border-slate-100 flex justify-end shrink-0 bg-slate-50/50">
                        <button type="button" wire:click="closeDetailsModal" class="px-5 py-2.5 rounded-xl bg-slate-900 hover:bg-slate-800 text-white text-xs font-bold transition">
                            Done
                        </button>
                    </div>
                @endif
            </div>
        </div>
    @endif
</div>
