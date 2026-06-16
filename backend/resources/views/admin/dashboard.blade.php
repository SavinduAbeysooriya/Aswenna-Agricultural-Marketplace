<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Aswenna - Admin Dashboard</title>
    <!-- CSRF Token -->
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <!-- Favicon -->
    <link rel="icon" type="image/png" href="{{ asset('images/logo.png') }}">
    <!-- Tailwind CSS -->
    <script src="https://cdn.tailwindcss.com"></script>
    <!-- SweetAlert2 for modern premium notifications -->
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <!-- Google Fonts: Inter & Poppins -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;950&family=Poppins:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
    <!-- FontAwesome icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <!-- Chart.js for analytics -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
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

    <!-- Mobile Sidebar Overlay -->
    <div id="sidebar-overlay" class="fixed inset-0 bg-slate-900/20 backdrop-blur-sm z-30 hidden transition-opacity duration-300 opacity-0 md:hidden" aria-hidden="true"></div>
    
    <!-- Main Layout Wrapper -->
    <div class="flex w-full min-h-screen">
        
        <!-- Admin Sidebar Component -->
        <x-admin-sidebar />

        <!-- Right Content Wrapper (Header, Main, Footer) -->
        <div class="flex-1 flex flex-col min-w-0 min-h-screen">
            <!-- Admin Header Component -->
            <x-admin-header />

            <!-- Main Operational Dashboard Panel Content -->
            <main class="flex-1 p-4 sm:p-6 md:p-8 space-y-6 md:space-y-8 overflow-y-auto w-full max-w-[1600px] mx-auto">
            
            <!-- Navigation Tabs -->
            <div class="flex items-center space-x-2 border-b border-slate-200 pb-px overflow-x-auto scrollbar-none">
                <button onclick="switchTab('overview')" id="tab-btn-overview" class="tab-btn px-5 py-3 text-xs sm:text-sm font-extrabold text-emerald-600 border-b-2 border-emerald-500 transition-all whitespace-nowrap">Marketplace Overview</button>
                <button onclick="switchTab('cultivation')" id="tab-btn-cultivation" class="tab-btn px-5 py-3 text-xs sm:text-sm font-extrabold text-slate-500 hover:text-slate-700 transition-all border-b-2 border-transparent whitespace-nowrap">Cultivation & Lands</button>
                <button onclick="switchTab('retail')" id="tab-btn-retail" class="tab-btn px-5 py-3 text-xs sm:text-sm font-extrabold text-slate-500 hover:text-slate-700 transition-all border-b-2 border-transparent whitespace-nowrap">B2C Retail & Logistics</button>
                <button onclick="switchTab('treasury')" id="tab-btn-treasury" class="tab-btn px-5 py-3 text-xs sm:text-sm font-extrabold text-slate-500 hover:text-slate-700 transition-all border-b-2 border-transparent whitespace-nowrap">Treasury & Campaigns</button>
                <button onclick="switchTab('support')" id="tab-btn-support" class="tab-btn px-5 py-3 text-xs sm:text-sm font-extrabold text-slate-500 hover:text-slate-700 transition-all border-b-2 border-transparent whitespace-nowrap">AI Support Gate</button>
            </div>

            <!-- Tab 1: Overview -->
            <div id="tab-pane-overview" class="tab-pane space-y-6 md:space-y-8">
                <!-- Alert bar if active -->
                <div class="p-4 bg-white border border-emerald-100 text-slate-700 rounded-2xl text-xs font-semibold flex flex-col sm:flex-row items-start sm:items-center justify-between shadow-sm shadow-emerald-500/5 relative overflow-hidden group">
                    <div class="absolute inset-0 bg-gradient-to-r from-emerald-50/50 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500"></div>
                    <div class="flex items-center space-x-3 relative z-10">
                        <div class="w-8 h-8 rounded-full bg-emerald-100 flex items-center justify-center text-emerald-600">
                            <i class="fa-solid fa-shield-check text-sm"></i>
                        </div>
                        <span>Secure administrator session verified. Welcome back, Super Administrator.</span>
                    </div>
                    <span class="text-[10px] text-slate-400 font-bold mt-3 sm:mt-0 relative z-10 bg-slate-100/80 px-2 py-1 rounded-md">IP: {{ request()->ip() }}</span>
                </div>

                <!-- KPI performance indicators -->
                <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 md:gap-6">
                    <!-- KPI 1 -->
                    <div class="group bg-white rounded-3xl p-6 border border-slate-100 shadow-[0_2px_10px_-3px_rgba(6,81,237,0.03)] space-y-4 flex flex-col justify-between hover:shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:-translate-y-1 transition-all duration-300 relative overflow-hidden">
                        <div class="absolute -right-6 -top-6 w-24 h-24 bg-emerald-50 rounded-full blur-2xl group-hover:bg-emerald-100 transition-colors duration-500"></div>
                        <div class="flex justify-between items-center relative z-10">
                            <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest">Platform Volume</span>
                            <div class="w-11 h-11 rounded-2xl bg-gradient-to-br from-emerald-50 to-emerald-100/50 text-emerald-600 flex items-center justify-center shadow-inner group-hover:scale-110 transition-transform duration-300">
                                <i class="fa-solid fa-chart-line text-sm"></i>
                            </div>
                        </div>
                        <div class="relative z-10">
                            <h3 id="kpi-volume-value" class="text-3xl font-black text-slate-800 tracking-tight">
                                @if($totalVolume >= 1000000)
                                    LKR {{ number_format($totalVolume / 1000000, 2) }}M
                                @elseif($totalVolume >= 1000)
                                    LKR {{ number_format($totalVolume / 1000, 1) }}k
                                @else
                                    LKR {{ number_format($totalVolume, 2) }}
                                @endif
                            </h3>
                            <span id="kpi-volume-trend" class="text-[11px] {{ $volumeTrend >= 0 ? 'text-emerald-600 bg-emerald-50' : 'text-rose-600 bg-rose-50' }} font-bold flex items-center mt-2 w-fit px-2 py-0.5 rounded-md">
                                <i class="fa-solid {{ $volumeTrend >= 0 ? 'fa-arrow-trend-up' : 'fa-arrow-trend-down' }} mr-1.5"></i> 
                                {{ $volumeTrend >= 0 ? '+' : '' }}{{ number_format($volumeTrend, 1) }}% this week
                            </span>
                        </div>
                    </div>

                    <!-- KPI 2 -->
                    <div class="group bg-white rounded-3xl p-6 border border-slate-100 shadow-[0_2px_10px_-3px_rgba(6,81,237,0.03)] space-y-4 flex flex-col justify-between hover:shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:-translate-y-1 transition-all duration-300 relative overflow-hidden">
                        <div class="absolute -right-6 -top-6 w-24 h-24 bg-blue-50 rounded-full blur-2xl group-hover:bg-blue-100 transition-colors duration-500"></div>
                        <div class="flex justify-between items-center relative z-10">
                            <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest">Active Farmers</span>
                            <div class="w-11 h-11 rounded-2xl bg-gradient-to-br from-blue-50 to-blue-100/50 text-blue-600 flex items-center justify-center shadow-inner group-hover:scale-110 transition-transform duration-300">
                                <i class="fa-solid fa-wheat-awn text-sm"></i>
                            </div>
                        </div>
                        <div class="relative z-10">
                            <h3 id="kpi-farmers-value" class="text-3xl font-black text-slate-800 tracking-tight">{{ number_format($totalFarmers) }}</h3>
                            <span id="kpi-farmers-trend" class="text-[11px] text-blue-600 font-bold flex items-center mt-2 bg-blue-50 w-fit px-2 py-0.5 rounded-md">
                                <i class="fa-solid fa-arrow-trend-up mr-1.5"></i> +{{ number_format($newFarmersThisWeek) }} new this week
                            </span>
                        </div>
                    </div>

                    <!-- KPI 3 -->
                    <div class="group bg-white rounded-3xl p-6 border border-slate-100 shadow-[0_2px_10px_-3px_rgba(6,81,237,0.03)] space-y-4 flex flex-col justify-between hover:shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:-translate-y-1 transition-all duration-300 relative overflow-hidden">
                        <div class="absolute -right-6 -top-6 w-24 h-24 bg-indigo-50 rounded-full blur-2xl group-hover:bg-indigo-100 transition-colors duration-500"></div>
                        <div class="flex justify-between items-center relative z-10">
                            <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest">Total Deliveries</span>
                            <div class="w-11 h-11 rounded-2xl bg-gradient-to-br from-indigo-50 to-indigo-100/50 text-indigo-600 flex items-center justify-center shadow-inner group-hover:scale-110 transition-transform duration-300">
                                <i class="fa-solid fa-truck-fast text-sm"></i>
                            </div>
                        </div>
                        <div class="relative z-10">
                            <h3 id="kpi-deliveries-value" class="text-3xl font-black text-slate-800 tracking-tight">{{ number_format($totalDeliveries) }}</h3>
                            <span id="kpi-deliveries-trend" class="text-[11px] text-indigo-600 font-bold flex items-center mt-2 bg-indigo-50 w-fit px-2 py-0.5 rounded-md">
                                <i class="fa-solid fa-circle-check mr-1.5"></i> {{ number_format($deliverySuccessRate, 1) }}% success rate
                            </span>
                        </div>
                    </div>

                    <!-- KPI 4 -->
                    <div class="group bg-white rounded-3xl p-6 border border-slate-100 shadow-[0_2px_10px_-3px_rgba(6,81,237,0.03)] space-y-4 flex flex-col justify-between hover:shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:-translate-y-1 transition-all duration-300 relative overflow-hidden">
                        <div class="absolute -right-6 -top-6 w-24 h-24 bg-amber-50 rounded-full blur-2xl group-hover:bg-amber-100 transition-colors duration-500"></div>
                        <div class="flex justify-between items-center relative z-10">
                            <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest">Platform Cut</span>
                            <div class="w-11 h-11 rounded-2xl bg-gradient-to-br from-amber-50 to-amber-100/50 text-amber-600 flex items-center justify-center shadow-inner group-hover:scale-110 transition-transform duration-300">
                                <i class="fa-solid fa-sack-dollar text-sm"></i>
                            </div>
                        </div>
                        <div class="relative z-10">
                            <h3 id="kpi-cut-value" class="text-3xl font-black text-slate-800 tracking-tight">
                                @if($totalCommissions >= 1000000)
                                    LKR {{ number_format($totalCommissions / 1000000, 2) }}M
                                @elseif($totalCommissions >= 1000)
                                    LKR {{ number_format($totalCommissions / 1000, 1) }}k
                                @else
                                    LKR {{ number_format($totalCommissions, 2) }}
                                @endif
                            </h3>
                            <span class="text-[11px] text-slate-500 font-bold flex items-center mt-2 bg-slate-50 w-fit px-2 py-0.5 rounded-md">
                                System commissions
                            </span>
                        </div>
                    </div>
                </div>

                <!-- Operations Grid -->
                <div class="grid grid-cols-1 xl:grid-cols-2 gap-6 md:gap-8 items-start">
                    
                    <!-- Plantation Verification Requests -->
                    <div class="bg-white rounded-3xl p-5 sm:p-7 border border-slate-100 shadow-[0_2px_10px_-3px_rgba(6,81,237,0.03)] space-y-6">
                        <div class="flex justify-between items-center border-b border-slate-100 pb-5">
                            <div>
                                <h3 class="text-lg font-bold text-slate-800 flex items-center">
                                    <div class="w-8 h-8 rounded-lg bg-amber-50 text-amber-500 flex items-center justify-center mr-3 shadow-inner">
                                        <i class="fa-solid fa-hourglass-half text-sm"></i> 
                                    </div>
                                    Crop Verification Pipeline
                                </h3>
                                <p class="text-[11px] sm:text-xs text-slate-500 mt-1 font-medium">Verifying GAP certificates & crop estimations</p>
                            </div>
                            <span id="pipeline-task-count" class="px-3 py-1 rounded-full bg-amber-50 text-amber-700 text-[10px] font-extrabold shadow-sm border border-amber-100/50">
                                {{ $pendingListingsCount }} Tasks Left
                            </span>
                        </div>

                        <div id="pipeline-container" class="space-y-4">
                            @forelse($pendingListings as $listing)
                            <div id="row-crop-{{ $listing->id }}" class="group p-4 bg-white border border-slate-100 hover:border-emerald-200 shadow-sm rounded-2xl flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 transition-all hover:shadow-md">
                                <div class="space-y-1.5 w-full sm:w-auto">
                                    <span class="text-sm font-bold text-slate-800 block">{{ $listing->farmer_name }} <span class="text-[10px] text-slate-400 ml-1 font-semibold">{{ $listing->farmer_phone }}</span></span>
                                    <span class="text-xs text-slate-500 block font-medium">Yield: {{ $listing->crop_name }} • {{ number_format($listing->available_quantity) }} {{ $listing->unit }} • Grade {{ $listing->grade }}</span>
                                    <span class="inline-flex px-2 py-0.5 rounded bg-emerald-50 text-emerald-700 text-[9px] font-bold uppercase mt-1 border border-emerald-100">Rate: LKR {{ number_format($listing->price_per_unit, 2) }} / {{ $listing->unit }}</span>
                                </div>
                                <div class="flex space-x-2 w-full sm:w-auto mt-2 sm:mt-0">
                                    <button onclick="approveListing({{ $listing->id }})" class="flex-1 sm:flex-initial px-5 py-2.5 bg-gradient-to-b from-emerald-500 to-emerald-600 hover:to-emerald-700 text-white rounded-xl text-[11px] font-bold shadow-md shadow-emerald-500/20 transition-all active:scale-95">Approve</button>
                                    <button onclick="rejectListing({{ $listing->id }})" class="flex-1 sm:flex-initial px-5 py-2.5 bg-slate-50 hover:bg-rose-50 text-slate-600 hover:text-rose-600 rounded-xl text-[11px] font-bold transition-all border border-slate-200 hover:border-rose-200 active:scale-95">Reject</button>
                                </div>
                            </div>
                            @empty
                            <div class="flex flex-col items-center justify-center py-8 text-slate-400 space-y-2">
                                <div class="w-12 h-12 rounded-full bg-slate-50 flex items-center justify-center text-slate-300">
                                    <i class="fa-solid fa-clipboard-check text-xl"></i>
                                </div>
                                <p class="text-xs font-semibold">No pending verification requests</p>
                            </div>
                            @endforelse
                        </div>
                    </div>

                    <!-- Financial Volume Chart -->
                    <div class="bg-white rounded-3xl p-5 sm:p-7 border border-slate-100 shadow-[0_2px_10px_-3px_rgba(6,81,237,0.03)] space-y-6">
                        <div class="flex justify-between items-center border-b border-slate-100 pb-5">
                            <div>
                                <h3 class="text-lg font-bold text-slate-800 flex items-center">
                                    <div class="w-8 h-8 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center mr-3 shadow-inner">
                                        <i class="fa-solid fa-chart-column text-sm"></i>
                                    </div>
                                    Platform Commission Treasury
                                </h3>
                                <p class="text-[11px] sm:text-xs text-slate-500 mt-1 font-medium">Weekly commission earnings from bidding and dispatches</p>
                            </div>
                        </div>

                        <div class="h-64 w-full flex items-center justify-center relative bg-slate-50/50 rounded-2xl p-4 border border-slate-50">
                            <canvas id="commissionChart" class="max-h-full w-full"></canvas>
                        </div>
                    </div>
                </div>

                <!-- Grid columns for activities and partner verifications -->
                <div class="grid grid-cols-1 xl:grid-cols-2 gap-6 md:gap-8 items-start">
                    
                    <!-- System Activity Audit Ledger -->
                    <div class="bg-white rounded-3xl p-5 sm:p-7 border border-slate-100 shadow-[0_2px_10px_-3px_rgba(6,81,237,0.03)] space-y-6">
                        <div class="flex justify-between items-center border-b border-slate-100 pb-5">
                            <div>
                                <h3 class="text-lg font-bold text-slate-800 flex items-center">
                                    <div class="w-8 h-8 rounded-lg bg-indigo-50 text-indigo-600 flex items-center justify-center mr-3 shadow-inner">
                                        <i class="fa-solid fa-list-check text-sm"></i>
                                    </div>
                                    System Activity Ledger
                                </h3>
                                <p class="text-[11px] sm:text-xs text-slate-500 mt-1 font-medium">Real-time platform activity and audit timeline</p>
                            </div>
                            <span class="w-2.5 h-2.5 bg-emerald-500 rounded-full animate-pulse shadow-[0_0_8px_#10b981]"></span>
                        </div>

                        <div id="activity-timeline-container" class="relative pl-6 border-l border-slate-100/80 space-y-6 ml-3">
                            @forelse($activities as $activity)
                            <div class="relative group">
                                <div class="absolute -left-[30px] top-1.5 w-3 h-3 rounded-full border-2 border-white shadow-sm flex items-center justify-center
                                    @if($activity->type === 'registration') bg-sky-500
                                    @elseif($activity->type === 'harvest') bg-amber-500
                                    @elseif($activity->type === 'order') bg-indigo-500
                                    @elseif($activity->type === 'payment') bg-emerald-500
                                    @else bg-slate-500
                                    @endif
                                "></div>
                                
                                <div class="space-y-1">
                                    <p class="text-xs sm:text-sm font-semibold text-slate-700 leading-tight">{{ $activity->title }}</p>
                                    <span class="text-[10px] text-slate-400 font-bold block">{{ \Carbon\Carbon::parse($activity->created_at)->diffForHumans() }}</span>
                                </div>
                            </div>
                            @empty
                            <div class="flex flex-col items-center justify-center py-8 text-slate-400 space-y-2">
                                <p class="text-xs font-semibold">No platform activity registered yet</p>
                            </div>
                            @endforelse
                        </div>
                    </div>

                    <!-- Pending Partner Verification Queue -->
                    <div class="bg-white rounded-3xl p-5 sm:p-7 border border-slate-100 shadow-[0_2px_10px_-3px_rgba(6,81,237,0.03)] space-y-6">
                        <div class="flex justify-between items-center border-b border-slate-100 pb-5">
                            <div>
                                <h3 class="text-lg font-bold text-slate-800 flex items-center">
                                    <div class="w-8 h-8 rounded-lg bg-rose-50 text-rose-500 flex items-center justify-center mr-3 shadow-inner">
                                        <i class="fa-solid fa-user-shield text-sm"></i>
                                    </div>
                                    Verification Gate Queue
                                </h3>
                                <p class="text-[11px] sm:text-xs text-slate-500 mt-1 font-medium">Verify pending partner registrations and documents</p>
                            </div>
                        </div>

                        <div id="verification-queue-container" class="space-y-4">
                            @forelse($verifications as $ver)
                            <div class="group p-4 bg-slate-50/50 border border-slate-100 hover:border-rose-100 hover:bg-rose-50/10 rounded-2xl flex items-center justify-between transition-all">
                                <div class="flex items-center space-x-3">
                                    <div class="w-10 h-10 rounded-xl bg-white text-slate-600 border border-slate-100 flex items-center justify-center shadow-sm group-hover:scale-105 transition-all">
                                        <i class="fa-solid fa-{{ $ver->icon }} text-xs"></i>
                                    </div>
                                    <div>
                                        <span class="text-xs sm:text-sm font-bold text-slate-800 block">{{ $ver->full_name }}</span>
                                        <span class="text-[10px] text-slate-500 font-bold block mt-0.5">{{ $ver->description }}</span>
                                    </div>
                                </div>
                                <a href="{{ route('admin.users.profile', $ver->id) }}" class="px-4 py-2 bg-white hover:bg-slate-50 text-slate-700 rounded-xl text-[10px] font-bold transition-all border border-slate-200 shadow-sm active:scale-95">
                                    Verify Profile
                                </a>
                            </div>
                            @empty
                            <div class="flex flex-col items-center justify-center py-8 text-slate-400 space-y-2">
                                <div class="w-12 h-12 rounded-full bg-slate-50 flex items-center justify-center text-slate-300">
                                    <i class="fa-solid fa-circle-check text-xl"></i>
                                </div>
                                <p class="text-xs font-semibold">No pending partner verification requests</p>
                            </div>
                            @endforelse
                        </div>
                    </div>
                </div>
            </div>

            <!-- Tab 2: Cultivation & Lands -->
            <div id="tab-pane-cultivation" class="tab-pane hidden space-y-6 md:space-y-8">
                <!-- Cultivation Stats Row -->
                <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 md:gap-6">
                    <div class="bg-white rounded-3xl p-6 border border-slate-100 shadow-sm">
                        <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest">Total Registered Lands</span>
                        <h3 id="cult-lands-count" class="text-3xl font-black text-slate-800 tracking-tight mt-2">{{ number_format($totalLands) }}</h3>
                    </div>
                    <div class="bg-white rounded-3xl p-6 border border-slate-100 shadow-sm">
                        <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest">Average Land Size</span>
                        <h3 id="cult-avg-size" class="text-3xl font-black text-slate-800 tracking-tight mt-2">{{ number_format($avgLandSize, 2) }} Acres</h3>
                    </div>
                    <div class="bg-white rounded-3xl p-6 border border-slate-100 shadow-sm">
                        <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest">Active Land Crops</span>
                        <h3 id="cult-crops-count" class="text-3xl font-black text-slate-800 tracking-tight mt-2">{{ number_format($totalLandCrops) }}</h3>
                    </div>
                </div>

                <!-- Cultivation Logs Ledger -->
                <div class="bg-white rounded-3xl p-5 sm:p-7 border border-slate-100 shadow-sm space-y-6">
                    <h3 class="text-lg font-bold text-slate-800 flex items-center">
                        <div class="w-8 h-8 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center mr-3 shadow-inner">
                            <i class="fa-solid fa-leaf text-sm"></i>
                        </div>
                        Latest Farm Cultivation Logs
                    </h3>
                    <div id="cultivation-logs-container" class="space-y-4">
                        @forelse($cultivationLogs as $log)
                        <div class="p-4 bg-slate-50 border border-slate-100 rounded-2xl space-y-2">
                            <div class="flex justify-between items-start">
                                <div>
                                    <span class="text-xs font-bold text-slate-800 block">{{ $log->farmer_name }}</span>
                                    <span class="text-[10px] text-slate-500 block">Land Ref: {{ $log->registration_number }}</span>
                                </div>
                                <span class="px-2 py-0.5 bg-emerald-50 text-emerald-700 text-[9px] font-bold uppercase border border-emerald-100 rounded">Stage: {{ str_replace('_', ' ', $log->stage_name) }}</span>
                            </div>
                            <p class="text-xs text-slate-600 font-medium leading-relaxed bg-white p-3 rounded-xl border border-slate-100/50">{{ $log->notes }}</p>
                            <span class="text-[9px] text-slate-400 font-bold block">{{ \Carbon\Carbon::parse($log->created_at)->diffForHumans() }}</span>
                        </div>
                        @empty
                        <div class="flex flex-col items-center justify-center py-8 text-slate-400">
                            <p class="text-xs font-semibold">No cultivation logs logged recently</p>
                        </div>
                        @endforelse
                    </div>
                </div>
            </div>

            <!-- Tab 3: B2C Retail & Logistics -->
            <div id="tab-pane-retail" class="tab-pane hidden space-y-6 md:space-y-8">
                <!-- Retail Stats -->
                <div class="grid grid-cols-1 sm:grid-cols-4 gap-4 md:gap-6">
                    <div class="bg-white rounded-3xl p-6 border border-slate-100 shadow-sm">
                        <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest">Total Retail Products</span>
                        <h3 id="retail-products-count" class="text-3xl font-black text-slate-800 tracking-tight mt-2">{{ number_format($totalProducts) }}</h3>
                    </div>
                    <div class="bg-white rounded-3xl p-6 border border-slate-100 shadow-sm">
                        <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest">Active Store Products</span>
                        <h3 id="retail-active-count" class="text-3xl font-black text-slate-800 tracking-tight mt-2">{{ number_format($activeProducts) }}</h3>
                    </div>
                    <div class="bg-white rounded-3xl p-6 border border-slate-100 shadow-sm">
                        <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest">B2C Orders Placed</span>
                        <h3 id="retail-orders-count" class="text-3xl font-black text-slate-800 tracking-tight mt-2">{{ number_format($totalRetailOrders) }}</h3>
                    </div>
                    <div class="bg-white rounded-3xl p-6 border border-slate-100 shadow-sm">
                        <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest">Logistics Success Rate</span>
                        <h3 id="retail-delivery-success" class="text-3xl font-black text-slate-800 tracking-tight mt-2">{{ number_format($deliverySuccessRate, 1) }}%</h3>
                    </div>
                </div>

                <!-- Recent B2C Orders Table -->
                <div class="bg-white rounded-3xl p-5 sm:p-7 border border-slate-100 shadow-sm space-y-6">
                    <h3 class="text-lg font-bold text-slate-800 flex items-center">
                        <div class="w-8 h-8 rounded-lg bg-indigo-50 text-indigo-600 flex items-center justify-center mr-3 shadow-inner">
                            <i class="fa-solid fa-basket-shopping text-sm"></i>
                        </div>
                        Recent B2C Retail Orders Ledger
                    </h3>
                    <div class="overflow-x-auto">
                        <table class="w-full text-left border-collapse">
                            <thead>
                                <tr class="border-b border-slate-100 text-[10px] font-extrabold text-slate-400 uppercase tracking-wider">
                                    <th class="pb-3">Order Number</th>
                                    <th class="pb-3">Customer</th>
                                    <th class="pb-3">Retail Seller</th>
                                    <th class="pb-3">Amount</th>
                                    <th class="pb-3">Payment</th>
                                    <th class="pb-3">Status</th>
                                </tr>
                            </thead>
                            <tbody id="retail-orders-table-body" class="divide-y divide-slate-50 text-xs font-semibold text-slate-700">
                                @forelse($recentRetailOrders as $order)
                                <tr>
                                    <td class="py-3.5">{{ $order->order_number }}</td>
                                    <td class="py-3.5">{{ $order->customer_name }}</td>
                                    <td class="py-3.5">{{ $order->seller_name }}</td>
                                    <td class="py-3.5">LKR {{ number_format($order->total_amount, 2) }}</td>
                                    <td class="py-3.5">
                                        <span class="px-2 py-0.5 text-[10px] rounded font-bold uppercase 
                                            @if($order->payment_status === 'paid') bg-emerald-50 text-emerald-700 border border-emerald-100
                                            @else bg-amber-50 text-amber-700 border border-amber-100
                                            @endif
                                        ">{{ $order->payment_status }}</span>
                                    </td>
                                    <td class="py-3.5">
                                        <span class="px-2 py-0.5 text-[10px] rounded font-bold uppercase bg-slate-100 text-slate-700 border border-slate-200">
                                            {{ $order->order_status }}
                                        </span>
                                    </td>
                                </tr>
                                @empty
                                <tr>
                                    <td colspan="6" class="py-6 text-center text-slate-400">No B2C orders registered in the system</td>
                                </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>
                </div>

                <!-- Logistics & Delivery Tracking -->
                <div class="bg-white rounded-3xl p-5 sm:p-7 border border-slate-100 shadow-sm space-y-6">
                    <h3 class="text-lg font-bold text-slate-800 flex items-center">
                        <div class="w-8 h-8 rounded-lg bg-sky-50 text-sky-600 flex items-center justify-center mr-3 shadow-inner">
                            <i class="fa-solid fa-truck-ramp-box text-sm"></i>
                        </div>
                        Active Delivery Tracking Log
                    </h3>
                    <div id="logistics-tracking-container" class="space-y-4">
                        @forelse($deliveryTrackingLogs as $track)
                        <div class="flex items-start justify-between p-4 bg-slate-50 border border-slate-100 rounded-2xl">
                            <div class="space-y-1.5">
                                <span class="text-xs font-bold text-slate-800 block">Dispatch Ref: {{ $track->order_number }}</span>
                                <span class="text-xs text-slate-600 block font-medium">Driver: {{ $track->partner_name }} • Info: {{ $track->tracking_note }}</span>
                                <span class="text-[9px] text-slate-400 font-bold block">{{ \Carbon\Carbon::parse($track->tracked_at)->diffForHumans() }}</span>
                            </div>
                            <span class="px-2 py-0.5 bg-sky-50 text-sky-700 border border-sky-100 text-[10px] font-extrabold uppercase rounded">{{ $track->status }}</span>
                        </div>
                        @empty
                        <div class="flex flex-col items-center justify-center py-8 text-slate-400">
                            <p class="text-xs font-semibold">No dispatches currently tracked</p>
                        </div>
                        @endforelse
                    </div>
                </div>
            </div>

            <!-- Tab 4: Treasury & Campaigns -->
            <div id="tab-pane-treasury" class="tab-pane hidden space-y-6 md:space-y-8">
                <!-- Treasury Stats -->
                <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 md:gap-6">
                    <div class="bg-white rounded-3xl p-6 border border-slate-100 shadow-sm">
                        <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest">Pending Withdrawal Requests</span>
                        <h3 id="treas-withdraw-count" class="text-3xl font-black text-slate-800 tracking-tight mt-2">{{ number_format($pendingWithdrawRequestsCount) }} Requests</h3>
                    </div>
                    <div class="bg-white rounded-3xl p-6 border border-slate-100 shadow-sm">
                        <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest">Total Pending Amount</span>
                        <h3 id="treas-withdraw-sum" class="text-3xl font-black text-slate-800 tracking-tight mt-2">LKR {{ number_format($pendingWithdrawRequestsSum, 2) }}</h3>
                    </div>
                    <div class="bg-white rounded-3xl p-6 border border-slate-100 shadow-sm">
                        <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest">Active Offer Campaigns</span>
                        <h3 id="treas-campaigns-count" class="text-3xl font-black text-slate-800 tracking-tight mt-2">{{ number_format($activeCampaigns) }} Active</h3>
                    </div>
                </div>

                <!-- Pending Withdraw Requests Queue -->
                <div class="grid grid-cols-1 xl:grid-cols-2 gap-6 md:gap-8 items-start">
                    
                    <!-- Withdraw Requests list -->
                    <div class="bg-white rounded-3xl p-5 sm:p-7 border border-slate-100 shadow-sm space-y-6">
                        <h3 class="text-lg font-bold text-slate-800 flex items-center">
                            <div class="w-8 h-8 rounded-lg bg-rose-50 text-rose-600 flex items-center justify-center mr-3 shadow-inner">
                                <i class="fa-solid fa-building-columns text-sm"></i>
                            </div>
                            Withdrawal Settlement Pipeline
                        </h3>
                        <div id="withdrawals-list-container" class="space-y-4">
                            @forelse($withdrawRequestsList as $wr)
                            <div class="p-4 bg-slate-50 border border-slate-100 rounded-2xl flex items-center justify-between">
                                <div>
                                    <span class="text-xs font-bold text-slate-800 block">{{ $wr->full_name }}</span>
                                    <span class="text-[10px] text-slate-500 font-bold block mt-0.5">{{ $wr->bank_name }} • A/C {{ $wr->bank_account_number }}</span>
                                    <span class="text-[9px] text-slate-400 font-bold block mt-1">{{ \Carbon\Carbon::parse($wr->created_at)->diffForHumans() }}</span>
                                </div>
                                <div class="text-right space-y-1.5">
                                    <span class="text-xs font-bold text-slate-800 block">LKR {{ number_format($wr->request_amount, 2) }}</span>
                                    <span class="px-2 py-0.5 text-[9px] font-bold uppercase rounded border
                                        @if($wr->status === 'pending') bg-amber-50 text-amber-700 border-amber-100
                                        @elseif($wr->status === 'approved') bg-emerald-50 text-emerald-700 border-emerald-100
                                        @else bg-rose-50 text-rose-700 border-rose-100
                                        @endif
                                    ">{{ $wr->status }}</span>
                                </div>
                            </div>
                            @empty
                            <div class="flex flex-col items-center justify-center py-8 text-slate-400">
                                <p class="text-xs font-semibold">No pending withdrawal requests</p>
                            </div>
                            @endforelse
                        </div>
                    </div>

                    <!-- Recent Wallet Transaction History -->
                    <div class="bg-white rounded-3xl p-5 sm:p-7 border border-slate-100 shadow-sm space-y-6">
                        <h3 class="text-lg font-bold text-slate-800 flex items-center">
                            <div class="w-8 h-8 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center mr-3 shadow-inner">
                                <i class="fa-solid fa-money-bill-transfer text-sm"></i>
                            </div>
                            Recent Wallet Transactions Audit
                        </h3>
                        <div id="transactions-list-container" class="space-y-4">
                            @forelse($recentTransactionsList as $tx)
                            <div class="p-4 bg-slate-50 border border-slate-100 rounded-2xl flex items-center justify-between">
                                <div class="space-y-0.5">
                                    <span class="text-xs font-bold text-slate-800 block">{{ $tx->full_name }}</span>
                                    <span class="text-[10px] text-slate-500 font-bold block">{{ $tx->description }}</span>
                                    <span class="text-[9px] text-slate-400 font-bold block">{{ \Carbon\Carbon::parse($tx->created_at)->diffForHumans() }}</span>
                                </div>
                                <div class="text-right">
                                    <span class="text-xs font-bold block 
                                        @if($tx->transaction_type === 'deposit' || $tx->transaction_type === 'refund') text-emerald-600
                                        @else text-slate-800
                                        @endif
                                    ">
                                        @if($tx->transaction_type === 'deposit' || $tx->transaction_type === 'refund') + @else - @endif
                                        LKR {{ number_format($tx->amount, 2) }}
                                    </span>
                                </div>
                            </div>
                            @empty
                            <div class="flex flex-col items-center justify-center py-8 text-slate-400">
                                <p class="text-xs font-semibold">No wallet transactions registered</p>
                            </div>
                            @endforelse
                        </div>
                    </div>
                </div>

                <!-- Campaigns Progress Section -->
                <div class="bg-white rounded-3xl p-5 sm:p-7 border border-slate-100 shadow-sm space-y-6">
                    <h3 class="text-lg font-bold text-slate-800 flex items-center">
                        <div class="w-8 h-8 rounded-lg bg-amber-50 text-amber-500 flex items-center justify-center mr-3 shadow-inner">
                            <i class="fa-solid fa-gift text-sm"></i>
                        </div>
                        Offers Campaigns & Goal Progressions
                    </h3>
                    <div id="offers-progress-container" class="space-y-4">
                        @forelse($recentOfferProgress as $op)
                        <div class="p-4 bg-slate-50 border border-slate-100 rounded-2xl flex items-center justify-between">
                            <div>
                                <span class="text-xs font-bold text-slate-800 block">{{ $op->user_name }}</span>
                                <span class="text-xs text-slate-500 font-bold block">{{ $op->campaign_title }}</span>
                            </div>
                            <span class="px-2.5 py-1 text-[10px] font-extrabold uppercase rounded-full
                                @if($op->is_completed) bg-emerald-50 text-emerald-700 border border-emerald-100
                                @else bg-amber-50 text-amber-700 border border-amber-100
                                @endif
                            ">
                                @if($op->is_completed) Goal Fulfilled @else In Progress @endif
                            </span>
                        </div>
                        @empty
                        <div class="flex flex-col items-center justify-center py-8 text-slate-400">
                            <p class="text-xs font-semibold">No campaign progressions logged</p>
                        </div>
                        @endforelse
                    </div>
                </div>
            </div>

            <!-- Tab 5: AI Support Gate -->
            <div id="tab-pane-support" class="tab-pane hidden space-y-6 md:space-y-8">
                <!-- Support Stats -->
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 md:gap-6">
                    <div class="bg-white rounded-3xl p-6 border border-slate-100 shadow-sm">
                        <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest">Total Chatbot Inquiry Sessions</span>
                        <h3 id="supp-bot-count" class="text-3xl font-black text-slate-800 tracking-tight mt-2">{{ number_format($totalChatbotSessions) }} Sessions</h3>
                    </div>
                    <div class="bg-white rounded-3xl p-6 border border-slate-100 shadow-sm">
                        <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest">Active Chat Messages Exchanged</span>
                        <h3 id="supp-chats-count" class="text-3xl font-black text-slate-800 tracking-tight mt-2">{{ number_format($totalChats) }} Messages</h3>
                    </div>
                </div>

                <!-- Recent Chatbot Q&A Log Streams -->
                <div class="bg-white rounded-3xl p-5 sm:p-7 border border-slate-100 shadow-sm space-y-6">
                    <h3 class="text-lg font-bold text-slate-800 flex items-center">
                        <div class="w-8 h-8 rounded-lg bg-indigo-50 text-indigo-600 flex items-center justify-center mr-3 shadow-inner">
                            <i class="fa-solid fa-robot text-sm"></i>
                        </div>
                        Aswenna AI Chatbot Q&A Stream
                    </h3>
                    <div id="chatbot-logs-container" class="space-y-5">
                        @forelse($recentChatbotLogs as $cbl)
                        <div class="p-4 bg-slate-50 border border-slate-100 rounded-2xl space-y-3">
                            <div class="flex justify-between items-center border-b border-slate-100 pb-2">
                                <span class="text-xs font-extrabold text-slate-600">User: {{ $cbl->user_name ?? 'Guest Visitor' }}</span>
                                <span class="text-[9px] text-slate-400 font-bold">{{ \Carbon\Carbon::parse($cbl->created_at)->diffForHumans() }}</span>
                            </div>
                            <div class="space-y-2 text-xs font-semibold">
                                <div class="flex items-start space-x-2 text-slate-700 bg-white p-3 rounded-xl border border-slate-100/50">
                                    <i class="fa-solid fa-circle-question text-amber-500 mt-0.5"></i>
                                    <p class="leading-relaxed">"{{ $cbl->message }}"</p>
                                </div>
                                <div class="flex items-start space-x-2 text-emerald-700 bg-emerald-50/30 p-3 rounded-xl border border-emerald-100/30">
                                    <i class="fa-solid fa-microchip-ai text-emerald-600 mt-0.5"></i>
                                    <p class="leading-relaxed">"${{ $cbl->response }}"</p>
                                </div>
                            </div>
                        </div>
                        @empty
                        <div class="flex flex-col items-center justify-center py-8 text-slate-400">
                            <p class="text-xs font-semibold">No chatbot interaction logs found</p>
                        </div>
                        @endforelse
                    </div>
                </div>
            </div>
            </main>

            <!-- Admin Footer Component -->
            <x-admin-footer />
        </div>
    </div>

    <!-- Chart rendering and verification approvals logic -->
    <script>
        // Tab switching logic
        function switchTab(tabId) {
            // Hide all tab panes
            document.querySelectorAll('.tab-pane').forEach(pane => {
                pane.classList.add('hidden');
            });
            // Show selected tab pane
            const activePane = document.getElementById(`tab-pane-${tabId}`);
            if (activePane) {
                activePane.classList.remove('hidden');
            }

            // Reset all tab button styles
            document.querySelectorAll('.tab-btn').forEach(btn => {
                btn.className = 'tab-btn px-5 py-3 text-xs sm:text-sm font-extrabold text-slate-500 hover:text-slate-700 transition-all border-b-2 border-transparent whitespace-nowrap';
            });
            // Apply active styles to selected button
            const activeBtn = document.getElementById(`tab-btn-${tabId}`);
            if (activeBtn) {
                activeBtn.className = 'tab-btn px-5 py-3 text-xs sm:text-sm font-extrabold text-emerald-600 border-b-2 border-emerald-500 transition-all whitespace-nowrap';
            }
        }

        // Mobile Sidebar Toggle Logic
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
                    // Small delay to allow display:block to apply before animating opacity
                    setTimeout(() => overlay.classList.add('opacity-100'), 10);
                }
            }

            toggleBtn?.addEventListener('click', toggleSidebar);
            overlay?.addEventListener('click', toggleSidebar);
        });

        // Crop verification pipeline handlers
        function approveListing(id) {
            const row = document.getElementById(`row-crop-${id}`);
            row.style.opacity = '0.3';
            row.style.transform = 'scale(0.98)';
            
            fetch(`/admin/users/profile/harvest-listing/${id}/status`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
                    'Accept': 'application/json'
                },
                body: JSON.stringify({
                    status: 'active'
                })
            })
            .then(response => {
                if (response.ok) {
                    row.remove();
                    Swal.fire({
                        icon: 'success',
                        title: 'Harvest Approved',
                        text: 'The harvest yield listing has been approved and published to the marketplace!',
                        confirmButtonColor: '#10b981',
                        customClass: {
                            popup: 'rounded-3xl shadow-2xl border border-slate-100',
                            confirmButton: 'rounded-xl font-bold shadow-md shadow-emerald-500/20 px-6 py-2.5'
                        }
                    });
                } else {
                    row.style.opacity = '1';
                    row.style.transform = 'none';
                    Swal.fire({
                        icon: 'error',
                        title: 'Error',
                        text: 'Failed to approve the listing. Please try again.',
                        confirmButtonColor: '#10b981'
                    });
                }
            })
            .catch(error => {
                row.style.opacity = '1';
                row.style.transform = 'none';
                console.error(error);
            });
        }

        function rejectListing(id) {
            Swal.fire({
                title: 'Reject Listing',
                text: 'Please enter the reason for rejecting this harvest listing:',
                input: 'text',
                inputPlaceholder: 'Reason for rejection...',
                showCancelButton: true,
                confirmButtonColor: '#e11d48',
                cancelButtonColor: '#94a3b8',
                confirmButtonText: 'Reject Listing',
                customClass: {
                    popup: 'rounded-3xl shadow-2xl border border-slate-100',
                    confirmButton: 'rounded-xl font-bold px-6 py-2.5',
                    cancelButton: 'rounded-xl font-bold px-6 py-2.5'
                }
            }).then((result) => {
                if (result.isConfirmed) {
                    if (!result.value || result.value.trim().length < 4) {
                        Swal.fire({
                            icon: 'warning',
                            title: 'Validation Failed',
                            text: 'Rejection reason must be at least 4 characters long.',
                            confirmButtonColor: '#10b981'
                        });
                        return;
                    }

                    const row = document.getElementById(`row-crop-${id}`);
                    row.style.opacity = '0.3';
                    row.style.transform = 'scale(0.98)';

                    fetch(`/admin/users/profile/harvest-listing/${id}/status`, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
                            'Accept': 'application/json'
                        },
                        body: JSON.stringify({
                            status: 'rejected',
                            reject_reason: result.value
                        })
                    })
                    .then(response => {
                        if (response.ok) {
                            row.remove();
                            Swal.fire({
                                icon: 'success',
                                title: 'Listing Rejected',
                                text: 'The listing was rejected and the farmer notified.',
                                confirmButtonColor: '#10b981',
                                customClass: {
                                    popup: 'rounded-3xl shadow-2xl border border-slate-100',
                                    confirmButton: 'rounded-xl font-bold shadow-md shadow-emerald-500/20 px-6 py-2.5'
                                }
                            });
                        } else {
                            row.style.opacity = '1';
                            row.style.transform = 'none';
                            Swal.fire({
                                icon: 'error',
                                title: 'Error',
                                text: 'Failed to reject the listing. Please try again.',
                                confirmButtonColor: '#10b981'
                            });
                        }
                    })
                    .catch(error => {
                        row.style.opacity = '1';
                        row.style.transform = 'none';
                        console.error(error);
                    });
                }
            });
        }

        // Global chart variable
        let commissionChart = null;

        // Initialize Chart.js on page load
        document.addEventListener("DOMContentLoaded", function() {
            const ctx = document.getElementById('commissionChart').getContext('2d');
            
            // Create gradient for chart line
            let gradient = ctx.createLinearGradient(0, 0, 0, 400);
            gradient.addColorStop(0, 'rgba(16, 185, 129, 0.2)'); // emerald-500
            gradient.addColorStop(1, 'rgba(16, 185, 129, 0)');

            commissionChart = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: {!! json_encode($chartLabels) !!},
                    datasets: [{
                        label: 'Commission (LKR)',
                        data: {!! json_encode($chartData) !!},
                        borderColor: '#10b981', // emerald-500
                        backgroundColor: gradient,
                        borderWidth: 3,
                        fill: true,
                        tension: 0.4,
                        pointRadius: 4,
                        pointBackgroundColor: '#fff',
                        pointBorderColor: '#10b981',
                        pointBorderWidth: 2,
                        pointHoverRadius: 6,
                        pointHoverBackgroundColor: '#10b981',
                        pointHoverBorderColor: '#fff',
                        pointHoverBorderWidth: 2
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { display: false },
                        tooltip: {
                            backgroundColor: 'rgba(15, 23, 42, 0.9)', // slate-900
                            titleFont: { family: 'Inter', size: 12, weight: 'bold' },
                            bodyFont: { family: 'Inter', size: 12 },
                            padding: 12,
                            cornerRadius: 8,
                            displayColors: false,
                            callbacks: {
                                label: function(context) {
                                    return 'LKR ' + context.parsed.y.toLocaleString();
                                }
                            }
                        }
                    },
                    scales: {
                        y: {
                            grid: { 
                                color: '#f1f5f9', // slate-100
                                borderDash: [5, 5] 
                            },
                            ticks: { 
                                font: { family: 'Inter', size: 11, weight: '500' },
                                color: '#94a3b8' // slate-400
                            },
                            border: { display: false }
                        },
                        x: {
                            grid: { display: false },
                            ticks: { 
                                font: { family: 'Inter', size: 11, weight: '500' },
                                color: '#94a3b8' 
                            },
                            border: { display: false }
                        }
                    },
                    interaction: {
                        intersect: false,
                        mode: 'index',
                    },
                }
            });

            // Start auto polling for dashboard stats (every 15 seconds)
            setInterval(fetchLatestStats, 15000);
        });

        // Fetch latest statistics and update dashboard dynamically
        function fetchLatestStats() {
            fetch('/admin/dashboard/stats', {
                headers: {
                    'Accept': 'application/json'
                }
            })
            .then(response => {
                if (response.ok) return response.json();
                throw new Error('Network response not ok.');
            })
            .then(data => {
                // Update KPI 1 (Platform Volume)
                const volVal = document.getElementById('kpi-volume-value');
                if (data.totalVolume >= 1000000) {
                    volVal.innerText = 'LKR ' + (data.totalVolume / 1000000).toFixed(2) + 'M';
                } else if (data.totalVolume >= 1000) {
                    volVal.innerText = 'LKR ' + (data.totalVolume / 1000).toFixed(1) + 'k';
                } else {
                    volVal.innerText = 'LKR ' + data.totalVolume.toLocaleString();
                }

                const volTrend = document.getElementById('kpi-volume-trend');
                volTrend.className = `text-[11px] ${data.volumeTrend >= 0 ? 'text-emerald-600 bg-emerald-50' : 'text-rose-600 bg-rose-50'} font-bold flex items-center mt-2 w-fit px-2 py-0.5 rounded-md`;
                volTrend.innerHTML = `<i class="fa-solid ${data.volumeTrend >= 0 ? 'fa-arrow-trend-up' : 'fa-arrow-trend-down'} mr-1.5"></i> ${data.volumeTrend >= 0 ? '+' : ''}${data.volumeTrend.toFixed(1)}% this week`;

                // Update KPI 2 (Active Farmers)
                document.getElementById('kpi-farmers-value').innerText = data.totalFarmers.toLocaleString();
                document.getElementById('kpi-farmers-trend').innerHTML = `<i class="fa-solid fa-arrow-trend-up mr-1.5"></i> +${data.newFarmersThisWeek} new this week`;

                // Update KPI 3 (Total Deliveries)
                document.getElementById('kpi-deliveries-value').innerText = data.totalDeliveries.toLocaleString();
                document.getElementById('kpi-deliveries-trend').innerHTML = `<i class="fa-solid fa-circle-check mr-1.5"></i> ${data.deliverySuccessRate.toFixed(1)}% success rate`;

                // Update KPI 4 (Platform Cut)
                const cutVal = document.getElementById('kpi-cut-value');
                if (data.totalCommissions >= 1000000) {
                    cutVal.innerText = 'LKR ' + (data.totalCommissions / 1000000).toFixed(2) + 'M';
                } else if (data.totalCommissions >= 1000) {
                    cutVal.innerText = 'LKR ' + (data.totalCommissions / 1000).toFixed(1) + 'k';
                } else {
                    cutVal.innerText = 'LKR ' + data.totalCommissions.toLocaleString();
                }

                // Update Crop Verification Pipeline Count
                document.getElementById('pipeline-task-count').innerText = `${data.pendingListingsCount} Tasks Left`;

                // Update Crop Verification Pipeline Container Rows
                const container = document.getElementById('pipeline-container');
                if (data.pendingListings.length === 0) {
                    container.innerHTML = `
                        <div class="flex flex-col items-center justify-center py-8 text-slate-400 space-y-2">
                            <div class="w-12 h-12 rounded-full bg-slate-50 flex items-center justify-center text-slate-300">
                                <i class="fa-solid fa-clipboard-check text-xl"></i>
                            </div>
                            <p class="text-xs font-semibold">No pending verification requests</p>
                        </div>
                    `;
                } else {
                    // Update only if row counts change to avoid screen flicker during active interactions
                    let existingRows = container.querySelectorAll('[id^="row-crop-"]');
                    if (existingRows.length !== data.pendingListings.length) {
                        let html = '';
                        data.pendingListings.forEach(listing => {
                            html += `
                                <div id="row-crop-${listing.id}" class="group p-4 bg-white border border-slate-100 hover:border-emerald-200 shadow-sm rounded-2xl flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 transition-all hover:shadow-md">
                                    <div class="space-y-1.5 w-full sm:w-auto">
                                        <span class="text-sm font-bold text-slate-800 block">${listing.farmer_name} <span class="text-[10px] text-slate-400 ml-1 font-semibold">${listing.farmer_phone}</span></span>
                                        <span class="text-xs text-slate-500 block font-medium">Yield: ${listing.crop_name} • ${parseFloat(listing.available_quantity).toLocaleString()} ${listing.unit} • Grade ${listing.grade}</span>
                                        <span class="inline-flex px-2 py-0.5 rounded bg-emerald-50 text-emerald-700 text-[9px] font-bold uppercase mt-1 border border-emerald-100">Rate: LKR ${parseFloat(listing.price_per_unit).toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2})} / ${listing.unit}</span>
                                    </div>
                                    <div class="flex space-x-2 w-full sm:w-auto mt-2 sm:mt-0">
                                        <button onclick="approveListing(${listing.id})" class="flex-1 sm:flex-initial px-5 py-2.5 bg-gradient-to-b from-emerald-500 to-emerald-600 hover:to-emerald-700 text-white rounded-xl text-[11px] font-bold shadow-md shadow-emerald-500/20 transition-all active:scale-95">Approve</button>
                                        <button onclick="rejectListing(${listing.id})" class="flex-1 sm:flex-initial px-5 py-2.5 bg-slate-50 hover:bg-rose-50 text-slate-600 hover:text-rose-600 rounded-xl text-[11px] font-bold transition-all border border-slate-200 hover:border-rose-200 active:scale-95">Reject</button>
                                    </div>
                                </div>
                            `;
                        });
                        container.innerHTML = html;
                    }
                }

                // Update System Activity Ledger
                const activityContainer = document.getElementById('activity-timeline-container');
                if (data.activities.length === 0) {
                    activityContainer.innerHTML = `
                        <div class="flex flex-col items-center justify-center py-8 text-slate-400 space-y-2">
                            <p class="text-xs font-semibold">No platform activity registered yet</p>
                        </div>
                    `;
                } else {
                    let html = '';
                    data.activities.forEach(act => {
                        let dotColor = 'bg-slate-500';
                        if (act.type === 'registration') dotColor = 'bg-sky-500';
                        else if (act.type === 'harvest') dotColor = 'bg-amber-500';
                        else if (act.type === 'order') dotColor = 'bg-indigo-500';
                        else if (act.type === 'payment') dotColor = 'bg-emerald-500';

                        let dateStr = new Date(act.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

                        html += `
                            <div class="relative group">
                                <div class="absolute -left-[30px] top-1.5 w-3 h-3 rounded-full border-2 border-white shadow-sm flex items-center justify-center ${dotColor}"></div>
                                <div class="space-y-1">
                                    <p class="text-xs sm:text-sm font-semibold text-slate-700 leading-tight">${act.title}</p>
                                    <span class="text-[10px] text-slate-400 font-bold block">${dateStr}</span>
                                </div>
                            </div>
                        `;
                    });
                    activityContainer.innerHTML = html;
                }

                // Update Verification Gate Queue
                const verContainer = document.getElementById('verification-queue-container');
                if (data.verifications.length === 0) {
                    verContainer.innerHTML = `
                        <div class="flex flex-col items-center justify-center py-8 text-slate-400 space-y-2">
                            <div class="w-12 h-12 rounded-full bg-slate-50 flex items-center justify-center text-slate-300">
                                <i class="fa-solid fa-circle-check text-xl"></i>
                            </div>
                            <p class="text-xs font-semibold">No pending partner verification requests</p>
                        </div>
                    `;
                } else {
                    let html = '';
                    data.verifications.forEach(ver => {
                        html += `
                            <div class="group p-4 bg-slate-50/50 border border-slate-100 hover:border-rose-100 hover:bg-rose-50/10 rounded-2xl flex items-center justify-between transition-all">
                                <div class="flex items-center space-x-3">
                                    <div class="w-10 h-10 rounded-xl bg-white text-slate-600 border border-slate-100 flex items-center justify-center shadow-sm group-hover:scale-105 transition-all">
                                        <i class="fa-solid fa-${ver.icon} text-xs"></i>
                                    </div>
                                    <div>
                                        <span class="text-xs sm:text-sm font-bold text-slate-800 block">${ver.full_name}</span>
                                        <span class="text-[10px] text-slate-500 font-bold block mt-0.5">${ver.description}</span>
                                    </div>
                                </div>
                                <a href="/admin/users/profile/${ver.id}" class="px-4 py-2 bg-white hover:bg-slate-50 text-slate-700 rounded-xl text-[10px] font-bold transition-all border border-slate-200 shadow-sm active:scale-95">
                                    Verify Profile
                                </a>
                            </div>
                        `;
                    });
                    verContainer.innerHTML = html;
                }

                // --- Tab 2: Cultivation & Lands updates ---
                document.getElementById('cult-lands-count').innerText = data.totalLands.toLocaleString();
                document.getElementById('cult-avg-size').innerText = parseFloat(data.avgLandSize).toFixed(2) + ' Acres';
                document.getElementById('cult-crops-count').innerText = data.totalLandCrops.toLocaleString();

                const cultivationLogsContainer = document.getElementById('cultivation-logs-container');
                if (data.cultivationLogs.length === 0) {
                    cultivationLogsContainer.innerHTML = `
                        <div class="flex flex-col items-center justify-center py-8 text-slate-400">
                            <p class="text-xs font-semibold">No cultivation logs logged recently</p>
                        </div>
                    `;
                } else {
                    let html = '';
                    data.cultivationLogs.forEach(log => {
                        html += `
                        <div class="p-4 bg-slate-50 border border-slate-100 rounded-2xl space-y-2">
                            <div class="flex justify-between items-start">
                                <div>
                                    <span class="text-xs font-bold text-slate-800 block">${log.farmer_name}</span>
                                    <span class="text-[10px] text-slate-500 block">Land Ref: ${log.registration_number}</span>
                                </div>
                                <span class="px-2 py-0.5 bg-emerald-50 text-emerald-700 text-[9px] font-bold uppercase border border-emerald-100 rounded">Stage: ${log.stage_name.replace(/_/g, ' ')}</span>
                            </div>
                            <p class="text-xs text-slate-600 font-medium leading-relaxed bg-white p-3 rounded-xl border border-slate-100/50">${log.notes}</p>
                            <span class="text-[9px] text-slate-400 font-bold block">${timeAgo(log.created_at)}</span>
                        </div>
                        `;
                    });
                    cultivationLogsContainer.innerHTML = html;
                }

                // --- Tab 3: B2C Retail & Logistics updates ---
                document.getElementById('retail-products-count').innerText = data.totalProducts.toLocaleString();
                document.getElementById('retail-active-count').innerText = data.activeProducts.toLocaleString();
                document.getElementById('retail-orders-count').innerText = data.totalRetailOrders.toLocaleString();
                document.getElementById('retail-delivery-success').innerText = parseFloat(data.deliverySuccessRate).toFixed(1) + '%';

                const retailOrdersTableBody = document.getElementById('retail-orders-table-body');
                if (data.recentRetailOrders.length === 0) {
                    retailOrdersTableBody.innerHTML = `
                        <tr>
                            <td colspan="6" class="py-6 text-center text-slate-400">No B2C orders registered in the system</td>
                        </tr>
                    `;
                } else {
                    let html = '';
                    data.recentRetailOrders.forEach(order => {
                        const isPaid = order.payment_status === 'paid';
                        html += `
                        <tr>
                            <td class="py-3.5">${order.order_number}</td>
                            <td class="py-3.5">${order.customer_name}</td>
                            <td class="py-3.5">${order.seller_name}</td>
                            <td class="py-3.5">LKR ${parseFloat(order.total_amount).toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2})}</td>
                            <td class="py-3.5">
                                <span class="px-2 py-0.5 text-[10px] rounded font-bold uppercase ${isPaid ? 'bg-emerald-50 text-emerald-700 border border-emerald-100' : 'bg-amber-50 text-amber-700 border border-amber-100'}">${order.payment_status}</span>
                            </td>
                            <td class="py-3.5">
                                <span class="px-2 py-0.5 text-[10px] rounded font-bold uppercase bg-slate-100 text-slate-700 border border-slate-200">
                                    ${order.order_status}
                                </span>
                            </td>
                        </tr>
                        `;
                    });
                    retailOrdersTableBody.innerHTML = html;
                }

                const logisticsTrackingContainer = document.getElementById('logistics-tracking-container');
                if (data.deliveryTrackingLogs.length === 0) {
                    logisticsTrackingContainer.innerHTML = `
                        <div class="flex flex-col items-center justify-center py-8 text-slate-400">
                            <p class="text-xs font-semibold">No dispatches currently tracked</p>
                        </div>
                    `;
                } else {
                    let html = '';
                    data.deliveryTrackingLogs.forEach(track => {
                        html += `
                        <div class="flex items-start justify-between p-4 bg-slate-50 border border-slate-100 rounded-2xl">
                            <div class="space-y-1.5">
                                <span class="text-xs font-bold text-slate-800 block">Dispatch Ref: ${track.order_number}</span>
                                <span class="text-xs text-slate-600 block font-medium">Driver: ${track.partner_name} • Info: ${track.tracking_note}</span>
                                <span class="text-[9px] text-slate-400 font-bold block">${timeAgo(track.tracked_at)}</span>
                            </div>
                            <span class="px-2 py-0.5 bg-sky-50 text-sky-700 border border-sky-100 text-[10px] font-extrabold uppercase rounded">${track.status}</span>
                        </div>
                        `;
                    });
                    logisticsTrackingContainer.innerHTML = html;
                }

                // --- Tab 4: Treasury & Campaigns updates ---
                document.getElementById('treas-withdraw-count').innerText = data.pendingWithdrawRequestsCount.toLocaleString() + ' Requests';
                document.getElementById('treas-withdraw-sum').innerText = 'LKR ' + parseFloat(data.pendingWithdrawRequestsSum).toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2});
                document.getElementById('treas-campaigns-count').innerText = data.activeCampaigns.toLocaleString() + ' Active';

                const withdrawalsListContainer = document.getElementById('withdrawals-list-container');
                if (data.withdrawRequestsList.length === 0) {
                    withdrawalsListContainer.innerHTML = `
                        <div class="flex flex-col items-center justify-center py-8 text-slate-400">
                            <p class="text-xs font-semibold">No pending withdrawal requests</p>
                        </div>
                    `;
                } else {
                    let html = '';
                    data.withdrawRequestsList.forEach(wr => {
                        let statusClass = 'bg-rose-50 text-rose-700 border-rose-100';
                        if (wr.status === 'pending') statusClass = 'bg-amber-50 text-amber-700 border-amber-100';
                        else if (wr.status === 'approved') statusClass = 'bg-emerald-50 text-emerald-700 border-emerald-100';

                        html += `
                        <div class="p-4 bg-slate-50 border border-slate-100 rounded-2xl flex items-center justify-between">
                            <div>
                                <span class="text-xs font-bold text-slate-800 block">${wr.full_name}</span>
                                <span class="text-[10px] text-slate-500 font-bold block mt-0.5">${wr.bank_name} • A/C ${wr.bank_account_number}</span>
                                <span class="text-[9px] text-slate-400 font-bold block mt-1">${timeAgo(wr.created_at)}</span>
                            </div>
                            <div class="text-right space-y-1.5">
                                <span class="text-xs font-bold text-slate-800 block">LKR ${parseFloat(wr.request_amount).toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2})}</span>
                                <span class="px-2 py-0.5 text-[9px] font-bold uppercase rounded border ${statusClass}">${wr.status}</span>
                            </div>
                        </div>
                        `;
                    });
                    withdrawalsListContainer.innerHTML = html;
                }

                const transactionsListContainer = document.getElementById('transactions-list-container');
                if (data.recentTransactionsList.length === 0) {
                    transactionsListContainer.innerHTML = `
                        <div class="flex flex-col items-center justify-center py-8 text-slate-400">
                            <p class="text-xs font-semibold">No wallet transactions registered</p>
                        </div>
                    `;
                } else {
                    let html = '';
                    data.recentTransactionsList.forEach(tx => {
                        const isPositive = tx.transaction_type === 'deposit' || tx.transaction_type === 'refund';
                        html += `
                        <div class="p-4 bg-slate-50 border border-slate-100 rounded-2xl flex items-center justify-between">
                            <div class="space-y-0.5">
                                <span class="text-xs font-bold text-slate-800 block">${tx.full_name}</span>
                                <span class="text-[10px] text-slate-500 font-bold block">${tx.description}</span>
                                <span class="text-[9px] text-slate-400 font-bold block">${timeAgo(tx.created_at)}</span>
                            </div>
                            <div class="text-right">
                                <span class="text-xs font-bold block ${isPositive ? 'text-emerald-600' : 'text-slate-800'}">
                                    ${isPositive ? '+' : '-'} LKR ${parseFloat(tx.amount).toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2})}
                                </span>
                            </div>
                        </div>
                        `;
                    });
                    transactionsListContainer.innerHTML = html;
                }

                const offersProgressContainer = document.getElementById('offers-progress-container');
                if (data.recentOfferProgress.length === 0) {
                    offersProgressContainer.innerHTML = `
                        <div class="flex flex-col items-center justify-center py-8 text-slate-400">
                            <p class="text-xs font-semibold">No campaign progressions logged</p>
                        </div>
                    `;
                } else {
                    let html = '';
                    data.recentOfferProgress.forEach(op => {
                        html += `
                        <div class="p-4 bg-slate-50 border border-slate-100 rounded-2xl flex items-center justify-between">
                            <div>
                                <span class="text-xs font-bold text-slate-800 block">${op.user_name}</span>
                                <span class="text-xs text-slate-500 font-bold block">${op.campaign_title}</span>
                            </div>
                            <span class="px-2.5 py-1 text-[10px] font-extrabold uppercase rounded-full ${op.is_completed ? 'bg-emerald-50 text-emerald-700 border border-emerald-100' : 'bg-amber-50 text-amber-700 border border-amber-100'}">
                                ${op.is_completed ? 'Goal Fulfilled' : 'In Progress'}
                            </span>
                        </div>
                        `;
                    });
                    offersProgressContainer.innerHTML = html;
                }

                // --- Tab 5: AI Support Gate updates ---
                document.getElementById('supp-bot-count').innerText = data.totalChatbotSessions.toLocaleString() + ' Sessions';
                document.getElementById('supp-chats-count').innerText = data.totalChats.toLocaleString() + ' Messages';

                const chatbotLogsContainer = document.getElementById('chatbot-logs-container');
                if (data.recentChatbotLogs.length === 0) {
                    chatbotLogsContainer.innerHTML = `
                        <div class="flex flex-col items-center justify-center py-8 text-slate-400">
                            <p class="text-xs font-semibold">No chatbot interaction logs found</p>
                        </div>
                    `;
                } else {
                    let html = '';
                    data.recentChatbotLogs.forEach(cbl => {
                        html += `
                        <div class="p-4 bg-slate-50 border border-slate-100 rounded-2xl space-y-3">
                            <div class="flex justify-between items-center border-b border-slate-100 pb-2">
                                <span class="text-xs font-extrabold text-slate-600">User: ${cbl.user_name || 'Guest Visitor'}</span>
                                <span class="text-[9px] text-slate-400 font-bold">${timeAgo(cbl.created_at)}</span>
                            </div>
                            <div class="space-y-2 text-xs font-semibold">
                                <div class="flex items-start space-x-2 text-slate-700 bg-white p-3 rounded-xl border border-slate-100/50">
                                    <i class="fa-solid fa-circle-question text-amber-500 mt-0.5"></i>
                                    <p class="leading-relaxed">"${cbl.message}"</p>
                                </div>
                                <div class="flex items-start space-x-2 text-emerald-700 bg-emerald-50/30 p-3 rounded-xl border border-emerald-100/30">
                                    <i class="fa-solid fa-microchip-ai text-emerald-600 mt-0.5"></i>
                                    <p class="leading-relaxed">${cbl.response}</p>
                                </div>
                            </div>
                        </div>
                        `;
                    });
                    chatbotLogsContainer.innerHTML = html;
                }

                // Update Chart.js treasury data
                if (commissionChart) {
                    commissionChart.data.labels = data.chartLabels;
                    commissionChart.data.datasets[0].data = data.chartData;
                    commissionChart.update();
                }
            })
            .catch(err => console.error('Error fetching dashboard stats:', err));
        }

        // Relative time formatter helper
        function timeAgo(dateString) {
            if (!dateString) return '';
            const date = new Date(dateString);
            const now = new Date();
            const seconds = Math.floor((now - date) / 1000);
            if (isNaN(seconds)) return dateString;
            if (seconds < 0) return 'Just now';
            if (seconds < 60) return 'Just now';
            const minutes = Math.floor(seconds / 60);
            if (minutes < 60) return `${minutes}m ago`;
            const hours = Math.floor(minutes / 60);
            if (hours < 24) return `${hours}h ago`;
            const days = Math.floor(hours / 24);
            return `${days}d ago`;
        }
    </script>
</body>
</html>
