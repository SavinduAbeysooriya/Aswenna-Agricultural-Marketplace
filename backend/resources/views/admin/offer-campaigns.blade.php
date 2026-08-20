<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Aswenna - Offer Campaigns & Moderation (ADM-003)</title>
    <link rel="icon" type="image/png" href="{{ asset('images/logo.png') }}">
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;950&family=Poppins:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: {
                        agri: {
                            deep: '#2E7D32',
                            fresh: '#4CAF50',
                            mint: '#E8F5E9',
                            soft: '#F5F7F6',
                            gold: '#D4A017',
                            dark: '#1B5E20'
                        }
                    },
                    fontFamily: {
                        sans: ['Inter', 'sans-serif'],
                        poppins: ['Poppins', 'sans-serif'],
                    }
                }
            }
        }
    </script>
</head>
<body class="min-h-screen bg-[#F8FAFC] text-slate-800 antialiased selection:bg-emerald-500/30">
    <div id="sidebar-overlay" class="fixed inset-0 bg-slate-900/20 backdrop-blur-sm z-30 hidden transition-opacity duration-300 opacity-0 md:hidden" aria-hidden="true"></div>

    <div class="flex w-full min-h-screen">
        <x-admin-sidebar :pending-crop-count="$pendingCropCount" />

        <div class="flex-1 flex flex-col min-w-0 min-h-screen">
            <x-admin-header />

            <main class="flex-1 p-4 sm:p-6 md:p-8 overflow-y-auto w-full max-w-[1700px] mx-auto space-y-6">
                
                @if (session('success'))
                    <div class="p-4 bg-emerald-50 border border-emerald-200 text-emerald-800 rounded-2xl flex items-center justify-between shadow-sm">
                        <div class="flex items-center space-x-3">
                            <i class="fa-solid fa-circle-check text-emerald-600 text-xl"></i>
                            <span class="font-semibold text-sm">{{ session('success') }}</span>
                        </div>
                        <button onclick="this.parentElement.remove()" class="text-emerald-500 hover:text-emerald-700">
                            <i class="fa-solid fa-xmark"></i>
                        </button>
                    </div>
                @endif

                <!-- Page Banner Header -->
                <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4 bg-white p-6 rounded-3xl border border-slate-100 shadow-sm">
                    <div>
                        <div class="inline-flex items-center space-x-2 px-3 py-1 bg-emerald-50 text-emerald-700 text-xs font-semibold rounded-full mb-2 border border-emerald-100">
                            <i class="fa-solid fa-shield-halved"></i>
                            <span>ADM-003 Promotional Moderation</span>
                        </div>
                        <h1 class="text-2xl font-black text-slate-900 font-poppins tracking-tight">Retailer Offer Campaigns Moderation</h1>
                        <p class="text-slate-500 text-sm mt-1">Review, approve, or reject promotional discount campaigns created by registered sellers & retailers.</p>
                    </div>
                </div>

                <!-- Stats Summary -->
                <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                    <div class="bg-white p-5 rounded-2xl border border-slate-100 shadow-sm flex items-center space-x-4">
                        <div class="h-12 w-12 rounded-xl bg-amber-50 border border-amber-100 text-amber-600 flex items-center justify-center text-xl font-bold">
                            <i class="fa-solid fa-clock"></i>
                        </div>
                        <div>
                            <div class="text-xs font-semibold text-slate-400 uppercase tracking-wider">Pending Review</div>
                            <div class="text-2xl font-extrabold text-slate-800">
                                {{ $campaigns->where('status', 'pending_admin_approval')->count() }}
                            </div>
                        </div>
                    </div>

                    <div class="bg-white p-5 rounded-2xl border border-slate-100 shadow-sm flex items-center space-x-4">
                        <div class="h-12 w-12 rounded-xl bg-emerald-50 border border-emerald-100 text-emerald-600 flex items-center justify-center text-xl font-bold">
                            <i class="fa-solid fa-circle-check"></i>
                        </div>
                        <div>
                            <div class="text-xs font-semibold text-slate-400 uppercase tracking-wider">Active Campaigns</div>
                            <div class="text-2xl font-extrabold text-slate-800">
                                {{ $campaigns->where('status', 'active')->count() }}
                            </div>
                        </div>
                    </div>

                    <div class="bg-white p-5 rounded-2xl border border-slate-100 shadow-sm flex items-center space-x-4">
                        <div class="h-12 w-12 rounded-xl bg-blue-50 border border-blue-100 text-blue-600 flex items-center justify-center text-xl font-bold">
                            <i class="fa-solid fa-bullhorn"></i>
                        </div>
                        <div>
                            <div class="text-xs font-semibold text-slate-400 uppercase tracking-wider">Featured Banners</div>
                            <div class="text-2xl font-extrabold text-slate-800">
                                {{ $campaigns->where('status', 'active')->count() }} Active
                            </div>
                        </div>
                    </div>

                    <div class="bg-white p-5 rounded-2xl border border-slate-100 shadow-sm flex items-center space-x-4">
                        <div class="h-12 w-12 rounded-xl bg-slate-50 border border-slate-200 text-slate-600 flex items-center justify-center text-xl font-bold">
                            <i class="fa-solid fa-list-check"></i>
                        </div>
                        <div>
                            <div class="text-xs font-semibold text-slate-400 uppercase tracking-wider">Total Campaigns</div>
                            <div class="text-2xl font-extrabold text-slate-800">
                                {{ $campaigns->count() }}
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Campaigns Moderation Table Card -->
                <div class="bg-white rounded-3xl border border-slate-100 shadow-sm overflow-hidden">
                    <div class="p-5 sm:p-6 border-b border-slate-100 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                        <div>
                            <h2 class="text-lg font-bold text-slate-900 font-poppins">Promotional Discount Campaigns List</h2>
                            <p class="text-xs text-slate-500">Approve retailer flash sales to publish promotional banners on the customer home feed.</p>
                        </div>
                    </div>

                    <div class="overflow-x-auto">
                        <table class="w-full text-left border-collapse">
                            <thead>
                                <tr class="bg-slate-50/80 border-b border-slate-100 text-[11px] font-bold text-slate-400 uppercase tracking-wider">
                                    <th class="py-4 px-6">ID & Campaign Info</th>
                                    <th class="py-4 px-6">Target Category / Audience</th>
                                    <th class="py-4 px-6">Discount & Offer</th>
                                    <th class="py-4 px-6">Validity & Duration</th>
                                    <th class="py-4 px-6">Status Badge</th>
                                    <th class="py-4 px-6 text-right">Moderation Actions</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-slate-100 text-sm">
                                @forelse ($campaigns as $campaign)
                                    <tr class="hover:bg-slate-50/60 transition-colors">
                                        <!-- ID & Title -->
                                        <td class="py-4 px-6">
                                            <div class="font-bold text-slate-900 flex items-center space-x-2">
                                                <span class="px-2 py-0.5 bg-slate-100 text-slate-600 rounded text-xs font-mono font-bold">#CMP-10{{ $campaign->id }}</span>
                                                <span>{{ $campaign->title }}</span>
                                            </div>
                                            <div class="text-xs text-slate-500 mt-1 font-mono">Code: {{ $campaign->code }}</div>
                                            @if($campaign->description)
                                                <div class="text-xs text-slate-400 mt-0.5 line-clamp-1">{{ $campaign->description }}</div>
                                            @endif
                                        </td>

                                        <!-- Target Category -->
                                        <td class="py-4 px-6">
                                            <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700 border border-emerald-100">
                                                <i class="fa-solid fa-carrot mr-1.5 text-emerald-500"></i>
                                                {{ $campaign->target_category ?? 'Fresh Vegetables' }}
                                            </span>
                                            <div class="text-[11px] text-slate-400 mt-1">Role: {{ ucfirst($campaign->applied_user_role ?? 'Customer') }}</div>
                                        </td>

                                        <!-- Discount -->
                                        <td class="py-4 px-6">
                                            <div class="font-extrabold text-emerald-700 text-base">
                                                {{ number_format($campaign->discount_percentage ?? 15, 0) }}% OFF
                                            </div>
                                            @if($campaign->max_discount_amount)
                                                <div class="text-xs text-slate-400">Max LKR {{ number_format($campaign->max_discount_amount, 2) }}</div>
                                            @endif
                                        </td>

                                        <!-- Validity -->
                                        <td class="py-4 px-6">
                                            <div class="text-xs font-semibold text-slate-700">3 Days Flash Sale</div>
                                            <div class="text-[11px] text-slate-400 font-mono mt-0.5">
                                                {{ \Carbon\Carbon::parse($campaign->valid_from)->format('d M Y') }} – {{ \Carbon\Carbon::parse($campaign->valid_until)->format('d M Y') }}
                                            </div>
                                        </td>

                                        <!-- Status Badge -->
                                        <td class="py-4 px-6">
                                            @if ($campaign->status === 'pending_admin_approval')
                                                <span class="inline-flex items-center space-x-1.5 px-3 py-1 rounded-full text-xs font-bold bg-amber-50 text-amber-700 border border-amber-200">
                                                    <span class="h-2 w-2 rounded-full bg-amber-500 animate-pulse"></span>
                                                    <span>Pending Approval</span>
                                                </span>
                                            @elseif ($campaign->status === 'active')
                                                <span class="inline-flex items-center space-x-1.5 px-3 py-1 rounded-full text-xs font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                                                    <span class="h-2 w-2 rounded-full bg-emerald-500"></span>
                                                    <span>Active (Banner Live)</span>
                                                </span>
                                            @elseif ($campaign->status === 'rejected')
                                                <span class="inline-flex items-center space-x-1.5 px-3 py-1 rounded-full text-xs font-bold bg-rose-50 text-rose-700 border border-rose-200">
                                                    <span class="h-2 w-2 rounded-full bg-rose-500"></span>
                                                    <span>Rejected</span>
                                                </span>
                                            @else
                                                <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-slate-100 text-slate-600">
                                                    {{ ucfirst($campaign->status) }}
                                                </span>
                                            @endif
                                        </td>

                                        <!-- Action Buttons -->
                                        <td class="py-4 px-6 text-right">
                                            <div class="flex items-center justify-end space-x-2">
                                                @if ($campaign->status !== 'active')
                                                    <form method="POST" action="{{ route('admin.offer-campaigns.approve', $campaign->id) }}">
                                                        @csrf
                                                        <button type="submit" class="px-3.5 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs rounded-xl shadow-sm hover:shadow transition-all inline-flex items-center space-x-1.5">
                                                            <i class="fa-solid fa-check"></i>
                                                            <span>Approve Campaign</span>
                                                        </button>
                                                    </form>
                                                @endif

                                                @if ($campaign->status !== 'rejected')
                                                    <form method="POST" action="{{ route('admin.offer-campaigns.reject', $campaign->id) }}">
                                                        @csrf
                                                        <button type="submit" class="px-3 py-1.5 bg-rose-50 hover:bg-rose-100 text-rose-700 font-bold text-xs rounded-xl border border-rose-200 transition-all inline-flex items-center space-x-1">
                                                            <i class="fa-solid fa-xmark"></i>
                                                            <span>Reject</span>
                                                        </button>
                                                    </form>
                                                @endif
                                            </div>
                                        </td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="6" class="py-12 text-center text-slate-400">
                                            <i class="fa-solid fa-box-open text-4xl mb-3 text-slate-300"></i>
                                            <p>No offer campaigns registered yet.</p>
                                        </td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>
                </div>

            </main>

            <x-admin-footer />
        </div>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', () => {
            const sidebar = document.getElementById('admin-sidebar');
            const toggleBtn = document.getElementById('mobile-sidebar-toggle');
            const overlay = document.getElementById('sidebar-overlay');

            function toggleSidebar() {
                const isOpen = sidebar.classList.contains('translate-x-0');
                if (isOpen) {
                    sidebar.classList.remove('translate-x-0');
                    sidebar.classList.add('-translate-x-full');
                    overlay.classList.remove('opacity-100');
                    overlay.classList.add('opacity-0');
                    setTimeout(() => overlay.classList.add('hidden'), 300);
                } else {
                    sidebar.classList.remove('-translate-x-full');
                    sidebar.classList.add('translate-x-0');
                    overlay.classList.remove('hidden');
                    setTimeout(() => overlay.classList.add('opacity-100'), 10);
                }
            }

            toggleBtn?.addEventListener('click', toggleSidebar);
            overlay?.addEventListener('click', toggleSidebar);
        });
    </script>
</body>
</html>
