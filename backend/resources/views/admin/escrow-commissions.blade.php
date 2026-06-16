<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Aswenna - Escrow & Commissions</title>
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
    <style>
        .animate-fade-in {
            animation: fadeIn 0.35s ease-out forwards;
        }
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(4px); }
            to { opacity: 1; transform: translateY(0); }
        }
    </style>
</head>
<body class="min-h-screen bg-[#F8FAFC] text-slate-800 antialiased selection:bg-emerald-500/30">
    <div id="sidebar-overlay" class="fixed inset-0 bg-slate-900/20 backdrop-blur-sm z-30 hidden transition-opacity duration-300 opacity-0 md:hidden" aria-hidden="true"></div>

    <div class="flex w-full min-h-screen">
        <x-admin-sidebar :pending-crop-count="$pendingCropCount" />

        <div class="flex-1 flex flex-col min-w-0 min-h-screen">
            <x-admin-header />

            <main class="flex-1 p-4 sm:p-6 md:p-8 overflow-y-auto w-full max-w-[1700px] mx-auto">
                <!-- Header -->
                <section class="mb-8">
                    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
                        <div>
                            <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-slate-100 text-slate-700 text-[11px] font-extrabold uppercase tracking-widest border border-slate-200/50">
                                <i class="fa-solid fa-scale-balanced"></i>
                                Treasury Oversight / Escrow & Commissions
                            </div>
                            <h1 class="mt-3 text-2xl sm:text-3xl font-black tracking-tight text-slate-900 font-poppins">Escrow & Commissions Ledger</h1>
                            <p class="mt-1 text-sm text-slate-500 font-medium">Detailed tracking of system commission collection points and current escrow holding structures.</p>
                        </div>
                    </div>
                </section>

                <!-- System Structure & How it Works Info Card -->
                <section class="mb-8">
                    <div class="bg-gradient-to-r from-emerald-800 to-emerald-950 rounded-3xl p-6 md:p-8 text-white shadow-xl relative overflow-hidden">
                        <div class="absolute top-0 right-0 w-64 h-64 bg-emerald-500/10 rounded-full blur-3xl"></div>
                        <h2 class="text-lg font-extrabold font-poppins mb-4 flex items-center gap-2">
                            <i class="fa-solid fa-circle-info text-emerald-400"></i>
                            Aswenna Platform Commission Architecture
                        </h2>
                        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 text-sm">
                            <div class="bg-white/5 border border-white/10 rounded-2xl p-5 backdrop-blur-sm">
                                <div class="w-8 h-8 rounded-xl bg-emerald-500/20 flex items-center justify-center text-emerald-300 font-black text-sm mb-3">5%</div>
                                <h3 class="font-extrabold mb-1">B2B Harvest Deals</h3>
                                <p class="text-xs text-emerald-100/80 leading-relaxed">System collects 5% commission from the buyer's bid total. Collected funds are logged automatically under bid payments and finalized upon delivery verification.</p>
                            </div>
                            <div class="bg-white/5 border border-white/10 rounded-2xl p-5 backdrop-blur-sm">
                                <div class="w-8 h-8 rounded-xl bg-emerald-500/20 flex items-center justify-center text-emerald-300 font-black text-sm mb-3">5%</div>
                                <h3 class="font-extrabold mb-1">B2C Retail Orders</h3>
                                <p class="text-xs text-emerald-100/80 leading-relaxed">System receives a flat 5% commission from retail store checkout orders. Commission is calculated on product subtotal plus delivery fee collections.</p>
                            </div>
                            <div class="bg-white/5 border border-white/10 rounded-2xl p-5 backdrop-blur-sm">
                                <div class="w-8 h-8 rounded-xl bg-emerald-500/20 flex items-center justify-center text-emerald-300 font-black text-sm mb-3">5%</div>
                                <h3 class="font-extrabold mb-1">Rider Logistics Commissions</h3>
                                <p class="text-xs text-emerald-100/80 leading-relaxed">System takes a 5% commission cut from the logistics partner's delivery fee per dispatch request to support platform map tracking tools.</p>
                            </div>
                        </div>
                    </div>
                </section>

                <!-- Stat Cards -->
                <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
                    <!-- Overall Commissions -->
                    <div class="bg-white border border-slate-100 rounded-3xl p-6 shadow-sm flex flex-col justify-between">
                        <div>
                            <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest block mb-1">Total System Revenue</span>
                            <h3 class="text-2xl font-black text-slate-900 font-poppins">LKR {{ number_format($overallTotal, 2) }}</h3>
                        </div>
                        <div class="mt-4 flex items-center gap-1 text-[11px] text-emerald-600 font-bold">
                            <i class="fa-solid fa-arrow-trend-up"></i>
                            <span>5% fee across all channels</span>
                        </div>
                    </div>

                    <!-- Escrow Funds -->
                    <div class="bg-white border border-slate-100 rounded-3xl p-6 shadow-sm flex flex-col justify-between">
                        <div>
                            <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest block mb-1">Funds Held In Escrow</span>
                            <h3 class="text-2xl font-black text-amber-600 font-poppins">LKR {{ number_format($totalEscrow, 2) }}</h3>
                        </div>
                        <div class="mt-4 flex items-center gap-1.5 text-[11px] text-slate-500 font-bold">
                            <span class="px-1.5 py-0.5 rounded bg-amber-55/10 text-amber-700">Retail: LKR {{ number_format($escrowRetailFunds, 0) }}</span>
                            <span class="px-1.5 py-0.5 rounded bg-amber-55/10 text-amber-700">B2B: LKR {{ number_format($escrowB2BFunds, 0) }}</span>
                        </div>
                    </div>

                    <!-- B2B Commissions -->
                    <div class="bg-white border border-slate-100 rounded-3xl p-6 shadow-sm flex flex-col justify-between">
                        <div>
                            <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest block mb-1">B2B Bulk Deal Share</span>
                            <h3 class="text-2xl font-black text-slate-900 font-poppins">LKR {{ number_format($b2bTotal, 2) }}</h3>
                        </div>
                        <div class="mt-4 text-[11px] text-slate-400 font-semibold">
                            From bulk farmer-buyer deal bids
                        </div>
                    </div>

                    <!-- B2C & Logistics Commissions -->
                    <div class="bg-white border border-slate-100 rounded-3xl p-6 shadow-sm flex flex-col justify-between">
                        <div>
                            <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest block mb-1">B2C Retail & Logistics Share</span>
                            <h3 class="text-2xl font-black text-slate-900 font-poppins">LKR {{ number_format($b2cTotal + $logisticsTotal, 2) }}</h3>
                        </div>
                        <div class="mt-4 text-[11px] text-slate-400 font-semibold">
                            Retail: LKR {{ number_format($b2cTotal, 2) }} | Rider: LKR {{ number_format($logisticsTotal, 2) }}
                        </div>
                    </div>
                </div>

                <!-- Tabs Container -->
                <div class="bg-white border border-slate-100 rounded-3xl shadow-sm overflow-hidden">
                    <div class="px-6 border-b border-slate-100 flex gap-2 bg-slate-50/50 overflow-x-auto">
                        <button type="button" onclick="switchTab('tab-b2b')" id="btn-tab-b2b" class="tab-btn px-5 py-4 text-xs font-extrabold border-b-2 border-emerald-600 text-emerald-700 whitespace-nowrap">
                            <i class="fa-solid fa-wheat-awn mr-1.5"></i> B2B Bulk Bid Commissions
                        </button>
                        <button type="button" onclick="switchTab('tab-b2c')" id="btn-tab-b2c" class="tab-btn px-5 py-4 text-xs font-bold border-b-2 border-transparent text-slate-500 hover:text-slate-900 whitespace-nowrap">
                            <i class="fa-solid fa-basket-shopping mr-1.5"></i> B2C Retail Order Commissions
                        </button>
                        <button type="button" onclick="switchTab('tab-logistics')" id="btn-tab-logistics" class="tab-btn px-5 py-4 text-xs font-bold border-b-2 border-transparent text-slate-500 hover:text-slate-900 whitespace-nowrap">
                            <i class="fa-solid fa-truck-fast mr-1.5"></i> Rider Logistics Commissions
                        </button>
                    </div>

                    <div class="p-6">
                        <!-- PANEL 1: B2B Bulk Bid Commissions -->
                        <div id="tab-b2b" class="tab-content block animate-fade-in">
                            <div class="overflow-x-auto border border-slate-100 rounded-2xl bg-white shadow-inner">
                                <table class="min-w-full divide-y divide-slate-100 text-sm text-left">
                                    <thead class="bg-slate-50 text-xs font-bold uppercase text-slate-400">
                                        <tr>
                                            <th class="px-6 py-4">Deal ID / Reference</th>
                                            <th class="px-6 py-4">Farmer (Seller)</th>
                                            <th class="px-6 py-4">Buyer</th>
                                            <th class="px-6 py-4 text-right">Total Deal Value</th>
                                            <th class="px-6 py-4 text-right">System Commission (5%)</th>
                                            <th class="px-6 py-4 text-right">Farmer Share</th>
                                            <th class="px-6 py-4">Payment Status</th>
                                            <th class="px-6 py-4">Date & Time</th>
                                        </tr>
                                    </thead>
                                    <tbody class="divide-y divide-slate-100 font-semibold text-slate-700">
                                        @forelse ($b2bCommissions as $b2b)
                                            <tr class="hover:bg-slate-50/50 transition">
                                                <td class="px-6 py-4">
                                                    <a href="{{ route('admin.users.profile', $b2b->farmer_id) }}#tab-harvest-listings" class="text-slate-900 hover:text-emerald-700 font-extrabold">
                                                        #BID-PAY-{{ $b2b->id }}
                                                    </a>
                                                    <div class="text-[10px] text-slate-400 font-medium mt-0.5">{{ $b2b->payment_id }}</div>
                                                </td>
                                                <td class="px-6 py-4">
                                                    <a href="{{ route('admin.users.profile', $b2b->farmer_id) }}" class="hover:text-emerald-700">{{ $b2b->farmer_name }}</a>
                                                </td>
                                                <td class="px-6 py-4">
                                                    <a href="{{ route('admin.users.profile', $b2b->buyer_id) }}" class="hover:text-emerald-700">{{ $b2b->buyer_name }}</a>
                                                </td>
                                                <td class="px-6 py-4 text-right text-slate-900">LKR {{ number_format($b2b->total_amount, 2) }}</td>
                                                <td class="px-6 py-4 text-right text-emerald-600 font-black">LKR {{ number_format($b2b->system_commission, 2) }}</td>
                                                <td class="px-6 py-4 text-right text-slate-650">LKR {{ number_format($b2b->farmer_amount, 2) }}</td>
                                                <td class="px-6 py-4">
                                                    <span class="inline-flex items-center px-2 py-0.5 rounded text-[10px] font-black uppercase {{ $b2b->payment_status === 'paid' ? 'bg-emerald-50 text-emerald-700 border border-emerald-100' : 'bg-amber-50 text-amber-700 border border-amber-100' }}">
                                                        {{ $b2b->payment_status }}
                                                    </span>
                                                </td>
                                                <td class="px-6 py-4 text-xs font-medium text-slate-500">
                                                    {{ \Carbon\Carbon::parse($b2b->date_and_time)->format('Y-m-d H:i') }}
                                                </td>
                                            </tr>
                                        @empty
                                            <tr>
                                                <td colspan="8" class="px-6 py-12 text-center text-slate-400">
                                                    <i class="fa-solid fa-wheat-awn text-3xl mb-3 block"></i> No B2B harvest deal payments detected.
                                                </td>
                                            </tr>
                                        @endforelse
                                    </tbody>
                                </table>
                            </div>
                        </div>

                        <!-- PANEL 2: B2C Retail Order Commissions -->
                        <div id="tab-b2c" class="tab-content hidden animate-fade-in">
                            <div class="overflow-x-auto border border-slate-100 rounded-2xl bg-white shadow-inner">
                                <table class="min-w-full divide-y divide-slate-100 text-sm text-left">
                                    <thead class="bg-slate-50 text-xs font-bold uppercase text-slate-400">
                                        <tr>
                                            <th class="px-6 py-4">Order Number</th>
                                            <th class="px-6 py-4">Customer</th>
                                            <th class="px-6 py-4 text-right">Subtotal</th>
                                            <th class="px-6 py-4 text-right">Delivery Fee</th>
                                            <th class="px-6 py-4 text-right">Total Amount</th>
                                            <th class="px-6 py-4 text-right">System Commission (5%)</th>
                                            <th class="px-6 py-4">Order Status</th>
                                            <th class="px-6 py-4">Date Placed</th>
                                        </tr>
                                    </thead>
                                    <tbody class="divide-y divide-slate-100 font-semibold text-slate-700">
                                        @forelse ($b2cCommissions as $b2c)
                                            <tr class="hover:bg-slate-50/50 transition">
                                                <td class="px-6 py-4">
                                                    <a href="{{ route('admin.users.profile', $b2c->id) }}#tab-customer-orders" class="text-slate-900 hover:text-emerald-700 font-extrabold">
                                                        {{ $b2c->order_number }}
                                                    </a>
                                                </td>
                                                <td class="px-6 py-4">{{ $b2c->customer_name }}</td>
                                                <td class="px-6 py-4 text-right">LKR {{ number_format($b2c->subtotal_amount, 2) }}</td>
                                                <td class="px-6 py-4 text-right">LKR {{ number_format($b2c->delivery_fee, 2) }}</td>
                                                <td class="px-6 py-4 text-right text-slate-900 font-bold">LKR {{ number_format($b2c->total_amount, 2) }}</td>
                                                <td class="px-6 py-4 text-right text-emerald-600 font-black">LKR {{ number_format($b2c->system_commission_amount, 2) }}</td>
                                                <td class="px-6 py-4">
                                                    <span class="inline-flex items-center px-2 py-0.5 rounded text-[10px] font-black uppercase {{ $b2c->order_status === 'delivered' ? 'bg-emerald-50 text-emerald-700' : ($b2c->order_status === 'cancelled' ? 'bg-rose-50 text-rose-700' : 'bg-amber-50 text-amber-700') }}">
                                                        {{ $b2c->order_status }}
                                                    </span>
                                                </td>
                                                <td class="px-6 py-4 text-xs font-medium text-slate-500">
                                                    {{ \Carbon\Carbon::parse($b2c->created_at)->format('Y-m-d H:i') }}
                                                </td>
                                            </tr>
                                        @empty
                                            <tr>
                                                <td colspan="8" class="px-6 py-12 text-center text-slate-400">
                                                    <i class="fa-solid fa-basket-shopping text-3xl mb-3 block"></i> No B2C retail store orders detected.
                                                </td>
                                            </tr>
                                        @endforelse
                                    </tbody>
                                </table>
                            </div>
                        </div>

                        <!-- PANEL 3: Rider Logistics Commissions -->
                        <div id="tab-logistics" class="tab-content hidden animate-fade-in">
                            <div class="overflow-x-auto border border-slate-100 rounded-2xl bg-white shadow-inner">
                                <table class="min-w-full divide-y divide-slate-100 text-sm text-left">
                                    <thead class="bg-slate-50 text-xs font-bold uppercase text-slate-400">
                                        <tr>
                                            <th class="px-6 py-4">Request ID</th>
                                            <th class="px-6 py-4">Associated Order</th>
                                            <th class="px-6 py-4">Delivery Partner</th>
                                            <th class="px-6 py-4 text-right">Delivery Fee Charged</th>
                                            <th class="px-6 py-4 text-right">System Logistics Cut (5%)</th>
                                            <th class="px-6 py-4">Request Status</th>
                                            <th class="px-6 py-4">Date Requested</th>
                                        </tr>
                                    </thead>
                                    <tbody class="divide-y divide-slate-100 font-semibold text-slate-700">
                                        @forelse ($logisticsCommissions as $logi)
                                            <tr class="hover:bg-slate-50/50 transition">
                                                <td class="px-6 py-4 font-bold text-slate-900">#REQ-{{ $logi->id }}</td>
                                                <td class="px-6 py-4 font-extrabold text-slate-600">{{ $logi->order_number }}</td>
                                                <td class="px-6 py-4">
                                                    @if ($logi->partner_name)
                                                        {{ $logi->partner_name }}
                                                    @else
                                                        <span class="text-slate-400 font-medium italic">Unassigned / Pending</span>
                                                    @endif
                                                </td>
                                                <td class="px-6 py-4 text-right">LKR {{ number_format($logi->delivery_fee, 2) }}</td>
                                                <td class="px-6 py-4 text-right text-emerald-600 font-black">LKR {{ number_format($logi->system_commission, 2) }}</td>
                                                <td class="px-6 py-4">
                                                    <span class="inline-flex items-center px-2 py-0.5 rounded text-[10px] font-black uppercase {{ $logi->request_status === 'completed' ? 'bg-emerald-50 text-emerald-700' : 'bg-amber-50 text-amber-700' }}">
                                                        {{ $logi->request_status }}
                                                    </span>
                                                </td>
                                                <td class="px-6 py-4 text-xs font-medium text-slate-500">
                                                    {{ \Carbon\Carbon::parse($logi->created_at)->format('Y-m-d H:i') }}
                                                </td>
                                            </tr>
                                        @empty
                                            <tr>
                                                <td colspan="7" class="px-6 py-12 text-center text-slate-400">
                                                    <i class="fa-solid fa-truck-fast text-3xl mb-3 block"></i> No delivery partner logistics requests detected.
                                                </td>
                                            </tr>
                                        @endforelse
                                    </tbody>
                                </table>
                            </div>
                        </div>
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

        function switchTab(tabId) {
            document.querySelectorAll('.tab-content').forEach(el => {
                el.classList.add('hidden');
                el.classList.remove('block');
            });
            const activePanel = document.getElementById(tabId);
            if (activePanel) {
                activePanel.classList.remove('hidden');
                activePanel.classList.add('block');
            }

            document.querySelectorAll('.tab-btn').forEach(btn => {
                btn.classList.remove('border-emerald-600', 'text-emerald-700', 'font-extrabold');
                btn.classList.add('border-transparent', 'text-slate-500', 'font-bold');
            });
            const activeBtn = document.getElementById('btn-' + tabId);
            if (activeBtn) {
                activeBtn.classList.remove('border-transparent', 'text-slate-500', 'font-bold');
                activeBtn.classList.add('border-emerald-600', 'text-emerald-700', 'font-extrabold');
            }
        }
    </script>
</body>
</html>
