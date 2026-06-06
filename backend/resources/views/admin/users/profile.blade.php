<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Aswenna - User Profile ({{ $user->full_name }})</title>
    <link rel="icon" type="image/png" href="{{ asset('images/logo.png') }}">
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;950&family=Poppins:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    @livewireStyles
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
        
        /* Premium custom scrollbar styling for tab container */
        .tab-scroll-container {
            scrollbar-width: none; /* Firefox */
            -ms-overflow-style: none; /* IE 10+ */
            transition: all 0.3s ease;
        }
        .tab-scroll-container::-webkit-scrollbar {
            height: 4px;
            display: none; /* Chrome/Safari/Webkit */
        }
        .tab-scroll-container:hover {
            scrollbar-width: thin;
        }
        .tab-scroll-container:hover::-webkit-scrollbar {
            display: block;
        }
        .tab-scroll-container::-webkit-scrollbar-track {
            background: #f1f5f9;
            border-radius: 4px;
        }
        .tab-scroll-container::-webkit-scrollbar-thumb {
            background: #10b981; /* emerald */
            border-radius: 4px;
        }

        /* Align icons and text horizontally */
        .tab-btn {
            display: inline-flex !important;
            align-items: center;
            justify-content: center;
        }

        /* Default collapsed state for tab text */
        .tab-btn .tab-text {
            display: inline-block;
            max-width: 0;
            opacity: 0;
            overflow: hidden;
            white-space: nowrap;
            transition: max-width 0.35s cubic-bezier(0.4, 0, 0.2, 1), opacity 0.25s ease, margin-left 0.35s ease;
            vertical-align: middle;
        }

        /* Expanded state on hover or active (font-extrabold) */
        .tab-btn:hover .tab-text,
        .tab-btn.font-extrabold .tab-text {
            max-width: 180px;
            opacity: 1;
            margin-left: 6px;
        }
    </style>
</head>
<body class="min-h-screen bg-[#F8FAFC] text-slate-800 antialiased selection:bg-emerald-500/30">
    <div id="sidebar-overlay" class="fixed inset-0 bg-slate-900/20 backdrop-blur-sm z-30 hidden transition-opacity duration-300 opacity-0 md:hidden" aria-hidden="true"></div>

    <div class="flex w-full min-h-screen">
        <!-- Sidebar Component -->
        <x-admin-sidebar :pending-crop-count="$pendingCropCount" />

        <div class="flex-1 flex flex-col min-w-0 min-h-screen">
            <!-- Header Component -->
            <x-admin-header />

            <main class="flex-1 p-4 sm:p-6 md:p-8 overflow-y-auto w-full max-w-[1700px] mx-auto">
                


                <!-- Navigation & Breadcrumbs -->
                <section class="flex flex-col xl:flex-row xl:items-end xl:justify-between gap-4 mb-8">
                    <div>
                        <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-slate-100 text-slate-700 text-[11px] font-extrabold uppercase tracking-widest border border-slate-200/50">
                            <i class="fa-solid fa-user-gear"></i>
                            Console Administration / User Profile
                        </div>
                        <h1 class="mt-3 text-2xl sm:text-3xl font-black tracking-tight text-slate-900 font-poppins">Inspect Profile</h1>
                        <p class="mt-1 text-sm text-slate-500 font-medium max-w-2xl">Detailed system audit, document reviews, transactions history and activities ledger for the selected user.</p>
                    </div>
                    <div class="flex flex-wrap gap-3">
                        @php
                            // Back route logic: dynamic fallback based on first role
                            $backRole = $roles[0] ?? 'farmer';
                        @endphp
                        <a href="{{ route('admin.users.index', $backRole) }}" class="inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-white border border-slate-200 text-slate-600 hover:text-emerald-700 hover:border-emerald-200 text-xs font-bold shadow-sm transition">
                            <i class="fa-solid fa-chevron-left text-[10px]"></i>
                            Back to {{ ucwords(str_replace('_', ' ', $backRole)) }}s
                        </a>
                        <a href="{{ route('admin.users.roles') }}" class="inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-white border border-slate-200 text-slate-600 hover:text-emerald-700 hover:border-emerald-200 text-xs font-bold shadow-sm transition">
                            <i class="fa-solid fa-users"></i>
                            Select Roles
                        </a>
                    </div>
                </section>

                <!-- Grid Layout: Left Column Profile Summary, Right Column Detailed Tabs -->
                <div class="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
                    
                    <!-- Left Column: User Summary & Actions Card -->
                    <div class="lg:col-span-4 space-y-6">
                        
                        <!-- Core Profile Card -->
                        <div class="bg-white border border-slate-100 rounded-3xl p-6 shadow-sm relative overflow-hidden">
                            <div class="absolute top-0 right-0 w-24 h-24 bg-emerald-500/5 rounded-full blur-2xl"></div>
                            
                            <!-- Profile Picture & Primary Badges -->
                            <div class="flex flex-col items-center text-center pb-6 border-b border-slate-100">
                                <div class="w-24 h-24 rounded-3xl bg-slate-50 border-2 border-slate-100 overflow-hidden flex items-center justify-center text-slate-400 font-extrabold text-2xl shadow-inner relative group">
                                    @if ($user->profile_picture_path)
                                        <img src="{{ Str::startsWith($user->profile_picture_path, ['http://', 'https://']) ? $user->profile_picture_path : asset('storage/' . $user->profile_picture_path) }}" alt="{{ $user->full_name }}" class="w-full h-full object-cover">
                                    @else
                                        <span>{{ strtoupper(substr($user->full_name, 0, 2)) }}</span>
                                    @endif
                                </div>
                                
                                <h3 class="mt-4 text-lg font-extrabold text-slate-900 font-poppins flex items-center justify-center gap-1.5">
                                    {{ $user->full_name }}
                                    @if ($user->is_verified)
                                        <span class="inline-flex items-center justify-center text-emerald-500" title="Verified User">
                                            <i class="fa-solid fa-circle-check"></i>
                                        </span>
                                    @endif
                                </h3>
                                <p class="text-xs text-slate-400 font-bold mt-1">UID #US{{ str_pad($user->id, 5, '0', STR_PAD_LEFT) }}</p>
                                
                                <div class="flex flex-wrap justify-center gap-1.5 mt-4">
                                    @foreach ($roles as $role)
                                        <span class="px-2.5 py-0.5 rounded-full text-[9px] font-black uppercase tracking-wider bg-emerald-50 border border-emerald-100 text-emerald-700">
                                            {{ str_replace('_', ' ', $role) }}
                                        </span>
                                    @endforeach
                                </div>
                            </div>
                            
                            <!-- Vital Details Info Block -->
                            <div class="py-6 border-b border-slate-100 space-y-4 text-xs font-semibold">
                                <div class="flex justify-between items-center">
                                    <span class="text-slate-400">Email Address</span>
                                    <span class="text-slate-800 text-right select-all" id="user-email">{{ $user->email ?? 'Not Provided' }}</span>
                                </div>
                                <div class="flex justify-between items-center">
                                    <span class="text-slate-400">National ID</span>
                                    <span class="text-slate-800 text-right select-all">{{ $user->national_id ?? 'Not Provided' }}</span>
                                </div>
                                <div class="flex justify-between items-center">
                                    <span class="text-slate-400">Mobile Phone</span>
                                    <span class="text-slate-800 text-right flex items-center gap-1.5 justify-end">
                                        <a href="tel:{{ $user->phone_number }}" class="hover:text-emerald-700 hover:underline transition duration-200">{{ $user->phone_number }}</a>
                                        @if ($user->phone_verified_at)
                                            <span class="text-emerald-500 inline-flex items-center" title="Phone Verified at {{ \Carbon\Carbon::parse($user->phone_verified_at)->format('M d, Y h:i A') }}">
                                                <i class="fa-solid fa-circle-check"></i>
                                            </span>
                                        @else
                                            <form action="{{ route('admin.users.profile.verify-phone', [$user->id, 1]) }}" method="POST" class="inline-flex items-center">
                                                @csrf
                                                <button type="submit" class="text-slate-300 hover:text-emerald-500 transition duration-200 inline-flex items-center" title="Click to Manually Verify Phone Number">
                                                    <i class="fa-regular fa-circle-check text-xs"></i>
                                                </button>
                                            </form>
                                        @endif
                                    </span>
                                </div>
                                @if ($user->phone_number_2)
                                    <div class="flex justify-between items-center">
                                        <span class="text-slate-400">Secondary Phone</span>
                                        <span class="text-slate-800 text-right flex items-center gap-1.5 justify-end">
                                            <a href="tel:{{ $user->phone_number_2 }}" class="hover:text-emerald-700 hover:underline transition duration-200">{{ $user->phone_number_2 }}</a>
                                            @if ($user->phone_number_2_verified_at)
                                                <span class="text-emerald-500 inline-flex items-center" title="Phone Verified at {{ \Carbon\Carbon::parse($user->phone_number_2_verified_at)->format('M d, Y h:i A') }}">
                                                    <i class="fa-solid fa-circle-check"></i>
                                                </span>
                                            @else
                                                <form action="{{ route('admin.users.profile.verify-phone', [$user->id, 2]) }}" method="POST" class="inline-flex items-center">
                                                    @csrf
                                                    <button type="submit" class="text-slate-300 hover:text-emerald-500 transition duration-200 inline-flex items-center" title="Click to Manually Verify Phone Number">
                                                        <i class="fa-regular fa-circle-check text-xs"></i>
                                                    </button>
                                                </form>
                                            @endif
                                        </span>
                                    </div>
                                @endif
                                <div class="flex justify-between items-start gap-4">
                                    <span class="text-slate-400 shrink-0">Home Address</span>
                                    <span class="text-slate-800 text-right">{{ implode(', ', array_filter([$user->address, $user->city, $user->district, $user->province])) ?: 'Not Provided' }}</span>
                                </div>
                                <div class="flex flex-col gap-2">
                                    <div class="flex justify-between items-center w-full">
                                        <span class="text-slate-400">Geo Location</span>
                                        <span class="text-slate-800 text-right">
                                            @if ($user->latitude && $user->longitude)
                                                {{ $user->latitude }}, {{ $user->longitude }}
                                                <a href="https://www.google.com/maps/search/?api=1&query={{ $user->latitude }},{{ $user->longitude }}" target="_blank" class="ml-1 text-emerald-600 hover:text-emerald-700 transition duration-200"><i class="fa-solid fa-map-location-dot"></i></a>
                                            @else
                                                Not Mapped
                                            @endif
                                        </span>
                                    </div>
                                    @if ($user->latitude && $user->longitude)
                                        <div class="group relative rounded-2xl overflow-hidden border border-slate-200/80 shadow-inner h-48 w-full mt-1 transition-all duration-300 hover:shadow-md hover:border-emerald-300">
                                            <iframe 
                                                class="w-full h-full border-0 rounded-2xl" 
                                                src="https://maps.google.com/maps?q={{ $user->latitude }},{{ $user->longitude }}&z=15&output=embed" 
                                                allowfullscreen="" 
                                                loading="lazy" 
                                                referrerpolicy="no-referrer-when-downgrade">
                                            </iframe>
                                            <!-- Subtle Hover Overlay -->
                                            <div class="absolute top-3 right-3 opacity-0 group-hover:opacity-100 transition-opacity duration-300">
                                                <a href="https://www.google.com/maps/search/?api=1&query={{ $user->latitude }},{{ $user->longitude }}" target="_blank" class="flex items-center gap-1.5 px-3 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-[10px] font-bold shadow-lg transition duration-200">
                                                    <i class="fa-solid fa-arrow-up-right-from-square text-[8px]"></i>
                                                    Open Google Maps
                                                </a>
                                            </div>
                                        </div>
                                    @endif
                                </div>
                                <div class="flex justify-between items-center">
                                    <span class="text-slate-400">Registered On</span>
                                    <span class="text-slate-800 text-right">{{ $user->created_at->format('M d, Y h:i A') }}</span>
                                </div>
                                <div class="flex justify-between items-center">
                                    <span class="text-slate-400">Last Login Time</span>
                                    <span class="text-slate-800 text-right">
                                        @if ($user->last_login_at)
                                            {{ $user->last_login_at->format('M d, Y h:i A') }}
                                        @else
                                            Never Logged In
                                        @endif
                                    </span>
                                </div>
                            </div>

                            <!-- Audit Status Badges -->
                            <div class="pt-6 space-y-4">
                                <div class="flex justify-between items-center">
                                    <span class="text-xs font-bold text-slate-400">System Status</span>
                                    <span class="inline-flex items-center rounded-full border px-2.5 py-0.5 text-[9px] font-black uppercase tracking-wider {{ $user->is_active ? 'bg-emerald-50 text-emerald-700 border-emerald-100' : 'bg-rose-50 text-rose-700 border-rose-100' }}">
                                        {{ $user->is_active ? 'ACTIVE' : 'BANNED' }}
                                    </span>
                                </div>
                                <div class="flex justify-between items-center">
                                    <span class="text-xs font-bold text-slate-400">Verification Gate</span>
                                    <span class="inline-flex items-center rounded-full border px-2.5 py-0.5 text-[9px] font-black uppercase tracking-wider {{ $user->is_verified ? 'bg-emerald-50 text-emerald-700 border-emerald-100' : 'bg-amber-50 text-amber-700 border-amber-100' }}">
                                        {{ $user->is_verified ? 'VERIFIED' : 'UNVERIFIED' }}
                                    </span>
                                </div>
                            </div>
                        </div>

                        <!-- System Administration / Action Forms Card -->
                        <div class="bg-white border border-slate-100 rounded-3xl p-6 shadow-sm space-y-6">
                            <h4 class="text-xs font-black uppercase tracking-widest text-slate-900 font-poppins"><i class="fa-solid fa-shield-halved mr-2 text-emerald-700"></i>Oversight Credentials & Actions</h4>
                            
                            <!-- Toggle Active / Suspend Account form -->
                            <div>
                                <form action="{{ route('admin.users.profile.toggle-active', $user->id) }}" method="POST" id="toggle-active-form">
                                    @csrf
                                    @if ($user->is_active)
                                        <button type="button" onclick="confirmAction('toggle-active-form', 'Deactivate / Ban this user profile? Standard user mobile endpoints will immediately deny access.', 'Yes, Ban Profile', 'warning')" class="w-full inline-flex items-center justify-center gap-2 px-4 py-3 rounded-2xl bg-rose-50 border border-rose-200 text-rose-700 hover:bg-rose-100 hover:border-rose-300 text-xs font-extrabold transition shadow-sm">
                                            <i class="fa-solid fa-user-slash text-sm"></i>
                                            Suspend User Account
                                        </button>
                                    @else
                                        <button type="button" onclick="confirmAction('toggle-active-form', 'Activate / Restore this user profile? The user will be granted full platform access.', 'Yes, Activate Profile', 'success')" class="w-full inline-flex items-center justify-center gap-2 px-4 py-3 rounded-2xl bg-emerald-50 border border-emerald-200 text-emerald-700 hover:bg-emerald-100 hover:border-emerald-300 text-xs font-extrabold transition shadow-sm">
                                            <i class="fa-solid fa-user-check text-sm"></i>
                                            Restore Account Activity
                                        </button>
                                    @endif
                                </form>
                            </div>

                            <!-- Verification Approval/Rejection Panel -->
                            @if (!$user->is_verified)
                                <div class="border-t border-slate-100 pt-6 space-y-4">
                                    <span class="text-[10px] font-black uppercase tracking-widest text-slate-400 block mb-2">Verification Controls</span>
                                    
                                    <form action="{{ route('admin.users.profile.approve', $user->id) }}" method="POST" id="approve-verification-form">
                                        @csrf
                                        <button type="button" onclick="confirmAction('approve-verification-form', 'Approve verification credentials? The user will be flagged as Verified across mobile and web platforms.', 'Yes, Approve Docs', 'success')" class="w-full inline-flex items-center justify-center gap-2 px-4 py-3 rounded-2xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-extrabold transition shadow-md">
                                            <i class="fa-solid fa-circle-check text-sm"></i>
                                            Approve Verification
                                        </button>
                                    </form>

                                    <!-- Rejection Controls -->
                                    <div class="mt-4">
                                        <button type="button" onclick="toggleRejectionBox()" class="w-full inline-flex items-center justify-center gap-2 px-4 py-3 rounded-2xl bg-white border border-slate-200 text-slate-700 hover:bg-slate-50 text-xs font-extrabold transition shadow-sm">
                                            <i class="fa-solid fa-circle-xmark text-sm text-rose-500"></i>
                                            Reject Credentials...
                                        </button>

                                        <div id="rejection-box" class="hidden mt-4 p-4 rounded-2xl bg-slate-50 border border-slate-200 animate-fade-in space-y-3">
                                            <form action="{{ route('admin.users.profile.reject', $user->id) }}" method="POST" id="reject-verification-form">
                                                @csrf
                                                <label for="rejection_reason" class="text-[10px] font-bold text-slate-500 block mb-1">State Reason for Rejection</label>
                                                <textarea name="rejection_reason" id="rejection_reason" rows="3" required class="w-full rounded-xl border border-slate-200 px-3 py-2 text-xs font-medium bg-white focus:outline-none focus:border-rose-400 transition" placeholder="Provide clear reasoning (e.g. Invalid document resolution, expired registration certificate, etc.)"></textarea>
                                                <div class="flex gap-2">
                                                    <button type="submit" class="flex-1 inline-flex items-center justify-center px-3 py-2 rounded-xl bg-rose-600 hover:bg-rose-700 text-white text-xs font-extrabold transition">
                                                        Submit Reject
                                                    </button>
                                                    <button type="button" onclick="toggleRejectionBox()" class="px-3 py-2 rounded-xl bg-white border border-slate-200 text-slate-500 hover:bg-slate-50 text-xs font-bold transition">
                                                        Cancel
                                                    </button>
                                                </div>
                                            </form>
                                        </div>
                                    </div>
                                </div>
                            @endif
                        </div>

                    </div>

                    <!-- Right Column: Interactive Details Tabs -->
                    <div class="lg:col-span-8 space-y-6">
                        
                        <!-- Top Metrics Row -->
                        <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
                            <div class="bg-white border border-slate-100 rounded-2xl p-4 shadow-sm flex flex-col justify-between">
                                <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest">Wallet Funds</span>
                                <strong class="mt-2 block text-lg font-black text-slate-900">
                                    LKR {{ number_format($wallet->balance ?? 0.00, 2) }}
                                </strong>
                            </div>
                            <div class="bg-white border border-slate-100 rounded-2xl p-4 shadow-sm flex flex-col justify-between">
                                <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest font-poppins">Platform Rating</span>
                                <div class="mt-2 flex items-center gap-1">
                                    <strong class="text-lg font-black text-slate-900">{{ number_format($averageRating, 1) }}</strong>
                                    <div class="flex text-[10px] text-amber-400">
                                        @for ($i = 1; $i <= 5; $i++)
                                            @if ($i <= round($averageRating))
                                                <i class="fa-solid fa-star"></i>
                                            @else
                                                <i class="fa-regular fa-star"></i>
                                            @endif
                                        @endfor
                                    </div>
                                </div>
                            </div>
                            <div class="bg-white border border-slate-100 rounded-2xl p-4 shadow-sm flex flex-col justify-between">
                                <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest font-poppins">Total Listings</span>
                                <strong class="mt-2 block text-lg font-black text-slate-900">
                                    {{ count($listings) }} Active Items
                                </strong>
                            </div>
                            <div class="bg-white border border-slate-100 rounded-2xl p-4 shadow-sm flex flex-col justify-between">
                                <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest font-poppins">Activities Ledger</span>
                                <strong class="mt-2 block text-lg font-black text-slate-900">
                                    {{ count($history) }} Records
                                </strong>
                            </div>
                        </div>

                        <!-- Tab Container Card -->
                        <div class="bg-white border border-slate-100 rounded-3xl shadow-sm overflow-hidden min-h-[500px]">
                            
                            <!-- Premium Vanilla JS Tab Controls -->
                            <div class="px-6 border-b border-slate-100 flex gap-1 bg-slate-50/50 overflow-x-auto tab-scroll-container">
                                <button type="button" onclick="switchTab('tab-docs')" id="btn-tab-docs" class="tab-btn px-5 py-4 text-xs font-bold transition-all border-b-2 whitespace-nowrap border-emerald-600 text-emerald-700 font-extrabold" title="Credentials & Audit">
                                    <i class="fa-solid fa-clipboard-check"></i><span class="tab-text">Credentials & Audit</span>
                                </button>
                                @if ($farmerData)
                                    <button type="button" onclick="switchTab('tab-lands')" id="btn-tab-lands" class="tab-btn px-5 py-4 text-xs font-bold transition-all border-b-2 whitespace-nowrap border-transparent text-slate-500 hover:text-slate-900" title="Farming Lands">
                                        <i class="fa-solid fa-map-location-dot"></i><span class="tab-text">Farming Lands</span>
                                    </button>
                                    <button type="button" onclick="switchTab('tab-logs')" id="btn-tab-logs" class="tab-btn px-5 py-4 text-xs font-bold transition-all border-b-2 whitespace-nowrap border-transparent text-slate-500 hover:text-slate-900" title="Daily Cultivation Logs">
                                        <i class="fa-solid fa-seedling"></i><span class="tab-text">Daily Cultivation Logs</span>
                                    </button>
                                    <button type="button" onclick="switchTab('tab-chatbot')" id="btn-tab-chatbot" class="tab-btn px-5 py-4 text-xs font-bold transition-all border-b-2 whitespace-nowrap border-transparent text-slate-500 hover:text-slate-900" title="AI Chat History">
                                        <i class="fa-solid fa-robot"></i><span class="tab-text">AI Chat History</span>
                                    </button>
                                @endif
                                <button type="button" onclick="switchTab('tab-wallet')" id="btn-tab-wallet" class="tab-btn px-5 py-4 text-xs font-bold transition-all border-b-2 whitespace-nowrap border-transparent text-slate-500 hover:text-slate-900" title="Wallet & Finance">
                                    <i class="fa-solid fa-wallet"></i><span class="tab-text">Wallet & Finance</span>
                                </button>
                                <button type="button" onclick="switchTab('tab-marketplace')" id="btn-tab-marketplace" class="tab-btn px-5 py-4 text-xs font-bold transition-all border-b-2 whitespace-nowrap border-transparent text-slate-500 hover:text-slate-900" title="Marketplace listings">
                                    <i class="fa-solid fa-store"></i><span class="tab-text">Marketplace listings</span>
                                </button>
                                <button type="button" onclick="switchTab('tab-reviews')" id="btn-tab-reviews" class="tab-btn px-5 py-4 text-xs font-bold transition-all border-b-2 whitespace-nowrap border-transparent text-slate-500 hover:text-slate-900" title="Ratings & Feedback">
                                    <i class="fa-solid fa-star"></i><span class="tab-text">Ratings & Feedback</span>
                                </button>
                                <button type="button" onclick="switchTab('tab-history')" id="btn-tab-history" class="tab-btn px-5 py-4 text-xs font-bold transition-all border-b-2 whitespace-nowrap border-transparent text-slate-500 hover:text-slate-900" title="Activity History">
                                    <i class="fa-solid fa-clock-rotate-left"></i><span class="tab-text">Activity History</span>
                                </button>
                            </div>

                            <!-- Tab Panels -->
                            <div class="p-6">
                                
                                <!-- PANEL 1: Credentials & Audit -->
                                <div id="tab-docs" class="tab-content block animate-fade-in space-y-8">
                                    
                                    <!-- General Verification Documents -->
                                    <div class="space-y-4">
                                        <h4 class="text-xs font-extrabold text-slate-900 uppercase tracking-wide flex items-center gap-2"><i class="fa-solid fa-id-card text-emerald-600"></i> General Verification Documents</h4>
                                        
                                        @if (count($documents) > 0)
                                            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                                                @foreach ($documents as $doc)
                                                    <div class="border border-slate-100 bg-slate-50/50 rounded-2xl p-4 shadow-sm flex flex-col justify-between">
                                                        <div>
                                                            <div class="flex justify-between items-center">
                                                                <span class="text-[10px] font-black uppercase text-slate-400">{{ str_replace('_', ' ', $doc->document_type) }}</span>
                                                                <div class="flex items-center gap-2">
                                                                    <span class="px-2 py-0.5 rounded-full text-[9px] font-black uppercase tracking-wider {{ $doc->verification_status === 'approved' ? 'bg-emerald-50 text-emerald-700 border-emerald-100' : ($doc->verification_status === 'rejected' ? 'bg-rose-50 text-rose-700 border-rose-100' : 'bg-amber-50 text-amber-700 border-amber-100') }} border">
                                                                        {{ $doc->verification_status }}
                                                                    </span>
                                                                    @if ($doc->verification_status === 'pending')
                                                                        <div class="flex items-center gap-1.5 border-l border-slate-200 pl-2">
                                                                            <!-- Individual Document Approve Button -->
                                                                            <form action="{{ route('admin.users.profile.document.approve', $doc->id) }}" method="POST" id="approve-doc-{{ $doc->id }}" class="inline-flex items-center">
                                                                                @csrf
                                                                                <button type="submit" class="text-slate-300 hover:text-emerald-500 transition duration-200 inline-flex items-center" title="Approve Document">
                                                                                    <i class="fa-solid fa-circle-check text-sm"></i>
                                                                                </button>
                                                                            </form>
                                                                            <!-- Individual Document Reject Button -->
                                                                            <button type="button" onclick="rejectDocument({{ $doc->id }})" class="text-slate-300 hover:text-rose-500 transition duration-200 inline-flex items-center" title="Reject Document">
                                                                                <i class="fa-solid fa-circle-xmark text-sm"></i>
                                                                            </button>
                                                                            <!-- Rejection Form -->
                                                                            <form action="{{ route('admin.users.profile.document.reject', $doc->id) }}" method="POST" id="reject-doc-form-{{ $doc->id }}" class="hidden">
                                                                                @csrf
                                                                                <input type="hidden" name="rejection_reason" id="reject-reason-input-{{ $doc->id }}">
                                                                            </form>
                                                                        </div>
                                                                    @endif
                                                                </div>
                                                            </div>
                                                            @if ($doc->rejection_reason)
                                                                <p class="mt-2 text-xs text-rose-600 font-semibold bg-rose-50/50 p-2.5 rounded-xl border border-rose-100/50"><strong>Rejection Reason:</strong> {{ $doc->rejection_reason }}</p>
                                                            @endif
                                                        </div>
                                                        
                                                        <div class="mt-4 grid grid-cols-2 gap-3">
                                                            @if ($doc->front_image_path)
                                                                <div class="relative rounded-xl overflow-hidden border border-slate-200/60 bg-white aspect-[4/3] group cursor-pointer" onclick="openLightbox('{{ Str::startsWith($doc->front_image_path, ['http://', 'https://']) ? $doc->front_image_path : asset('storage/' . $doc->front_image_path) }}')">
                                                                    <img src="{{ Str::startsWith($doc->front_image_path, ['http://', 'https://']) ? $doc->front_image_path : asset('storage/' . $doc->front_image_path) }}" class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300">
                                                                    <div class="absolute inset-0 bg-slate-900/30 opacity-0 group-hover:opacity-100 flex items-center justify-center text-white text-[10px] font-black transition-opacity"><i class="fa-solid fa-magnifying-glass-plus mr-1"></i> Front</div>
                                                                </div>
                                                            @endif
                                                            @if ($doc->back_image_path)
                                                                <div class="relative rounded-xl overflow-hidden border border-slate-200/60 bg-white aspect-[4/3] group cursor-pointer" onclick="openLightbox('{{ Str::startsWith($doc->back_image_path, ['http://', 'https://']) ? $doc->back_image_path : asset('storage/' . $doc->back_image_path) }}')">
                                                                    <img src="{{ Str::startsWith($doc->back_image_path, ['http://', 'https://']) ? $doc->back_image_path : asset('storage/' . $doc->back_image_path) }}" class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300">
                                                                    <div class="absolute inset-0 bg-slate-900/30 opacity-0 group-hover:opacity-100 flex items-center justify-center text-white text-[10px] font-black transition-opacity"><i class="fa-solid fa-magnifying-glass-plus mr-1"></i> Back</div>
                                                                </div>
                                                            @endif
                                                        </div>
                                                         <div class="mt-3 text-[10px] text-slate-400 font-semibold">
                                                             <div>Uploaded {{ date('M d, Y', strtotime($doc->created_at)) }}</div>
                                                             @if ($doc->verification_status === 'approved' && $doc->verified_at)
                                                                 <div class="text-emerald-600 mt-1 flex items-center gap-1 font-bold">
                                                                     <i class="fa-solid fa-circle-check text-[9px]"></i>
                                                                     Verified at {{ date('M d, Y h:i A', strtotime($doc->verified_at)) }} by {{ $doc->verifier_name ?? 'System' }}
                                                                 </div>
                                                             @endif
                                                         </div>
                                                    </div>
                                                @endforeach
                                            </div>
                                        @else
                                            <div class="border border-dashed border-slate-200 rounded-2xl p-8 text-center text-slate-400">
                                                <i class="fa-solid fa-file-invoice text-2xl"></i>
                                                <p class="mt-2 text-xs font-bold">No General Identity Documents Uploaded</p>
                                            </div>
                                        @endif
                                    </div>

                                    <!-- Farmer Specific Verification Credentials -->
                                    @if ($farmerData)
                                        <div class="border-t border-slate-100 pt-6 space-y-4">
                                            <h4 class="text-xs font-extrabold text-slate-900 uppercase tracking-wide flex items-center gap-2"><i class="fa-solid fa-wheat-awn text-emerald-600"></i> Farmer Verification & Land Details</h4>
                                            
                                            <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                                                <!-- Farming License -->
                                                <div class="border border-slate-100 bg-slate-50/50 rounded-2xl p-4 flex flex-col justify-between">
                                                    <div>
                                                        <span class="text-[10px] font-black uppercase text-slate-400 block">Farming License</span>
                                                        <strong class="text-xs text-slate-800 block mt-1">{{ $farmerData->farming_license_number ?? 'Not Supplied' }}</strong>
                                                    </div>
                                                    @if ($farmerData->farming_license_path)
                                                        <div class="mt-4">
                                                            <a href="{{ Str::startsWith($farmerData->farming_license_path, ['http://', 'https://']) ? $farmerData->farming_license_path : asset('storage/' . $farmerData->farming_license_path) }}" target="_blank" class="inline-flex items-center gap-1 px-3 py-2 rounded-xl bg-emerald-50 hover:bg-emerald-100 text-emerald-700 border border-emerald-100/50 text-[11px] font-black transition">
                                                                <i class="fa-solid fa-file-pdf"></i> View License File
                                                            </a>
                                                        </div>
                                                    @endif
                                                </div>

                                                <!-- Organic Certificate -->
                                                <div class="border border-slate-100 bg-slate-50/50 rounded-2xl p-4 flex flex-col justify-between">
                                                    <div>
                                                        <span class="text-[10px] font-black uppercase text-slate-400 block">Organic Certificate</span>
                                                        <strong class="text-xs text-slate-800 block mt-1">{{ $farmerData->organic_certificate_number ?? 'Not Supplied' }}</strong>
                                                        @if ($farmerData->organic_certificate_expiry)
                                                            <span class="text-[10px] text-slate-400 block mt-1 font-semibold">Expires: {{ $farmerData->organic_certificate_expiry }}</span>
                                                        @endif
                                                    </div>
                                                    @if ($farmerData->organic_certificate_path)
                                                        <div class="mt-4">
                                                            <a href="{{ Str::startsWith($farmerData->organic_certificate_path, ['http://', 'https://']) ? $farmerData->organic_certificate_path : asset('storage/' . $farmerData->organic_certificate_path) }}" target="_blank" class="inline-flex items-center gap-1 px-3 py-2 rounded-xl bg-emerald-50 hover:bg-emerald-100 text-emerald-700 border border-emerald-100/50 text-[11px] font-black transition">
                                                                <i class="fa-solid fa-file-signature"></i> Organic Cert
                                                            </a>
                                                        </div>
                                                    @endif
                                                </div>

                                                <!-- GAP Certificate -->
                                                <div class="border border-slate-100 bg-slate-50/50 rounded-2xl p-4 flex flex-col justify-between">
                                                    <div>
                                                        <span class="text-[10px] font-black uppercase text-slate-400 block">GAP Certificate</span>
                                                        <strong class="text-xs text-slate-800 block mt-1">{{ $farmerData->gap_certificate_number ?? 'Not Supplied' }}</strong>
                                                        @if ($farmerData->gap_certificate_expiry)
                                                            <span class="text-[10px] text-slate-400 block mt-1 font-semibold">Expires: {{ $farmerData->gap_certificate_expiry }}</span>
                                                        @endif
                                                    </div>
                                                    @if ($farmerData->gap_certificate_path)
                                                        <div class="mt-4">
                                                            <a href="{{ Str::startsWith($farmerData->gap_certificate_path, ['http://', 'https://']) ? $farmerData->gap_certificate_path : asset('storage/' . $farmerData->gap_certificate_path) }}" target="_blank" class="inline-flex items-center gap-1 px-3 py-2 rounded-xl bg-emerald-50 hover:bg-emerald-100 text-emerald-700 border border-emerald-100/55 text-[11px] font-black transition">
                                                                <i class="fa-solid fa-certificate"></i> GAP Cert
                                                            </a>
                                                        </div>
                                                    @endif
                                                </div>

                                                <!-- Other Certificates -->
                                                @php
                                                    $otherCertificates = json_decode($farmerData->other_certificates_titles_and_paths ?? '[]', true) ?: [];
                                                @endphp
                                                @if (!empty($otherCertificates))
                                                    @foreach ($otherCertificates as $cert)
                                                        <div class="border border-slate-100 bg-slate-50/50 rounded-2xl p-4 flex flex-col justify-between">
                                                            <div>
                                                                <span class="text-[10px] font-black uppercase text-slate-400 block">Other Certificate</span>
                                                                <strong class="text-xs text-slate-800 block mt-1">{{ $cert['title'] ?? 'Untitled Certificate' }}</strong>
                                                            </div>
                                                            @if (!empty($cert['path']))
                                                                <div class="mt-4">
                                                                    <a href="{{ Str::startsWith($cert['path'], ['http://', 'https://']) ? $cert['path'] : asset('storage/' . $cert['path']) }}" target="_blank" class="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl bg-emerald-50 hover:bg-emerald-100 text-emerald-700 border border-emerald-100/50 text-[11px] font-black transition">
                                                                        <i class="fa-solid fa-file-lines"></i> View Document
                                                                    </a>
                                                                </div>
                                                            @endif
                                                        </div>
                                                    @endforeach
                                                @endif
                                            </div>
                                        </div>
                                    @endif

                                    <!-- Retail Seller Specific Verification Credentials -->
                                    @if ($retailSellerData)
                                        <div class="border-t border-slate-100 pt-6 space-y-4">
                                            <h4 class="text-xs font-extrabold text-slate-900 uppercase tracking-wide flex items-center gap-2"><i class="fa-solid fa-store text-emerald-600"></i> Retailer Business Credentials</h4>
                                            
                                            <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                                                <!-- BR Registry -->
                                                <div class="border border-slate-100 bg-slate-50/50 rounded-2xl p-4 flex flex-col justify-between md:col-span-2">
                                                    <div class="grid grid-cols-2 gap-4">
                                                        <div>
                                                            <span class="text-[10px] font-black uppercase text-slate-400">BR Register Number</span>
                                                            <strong class="text-xs text-slate-800 block mt-1">{{ $retailSellerData->br_number ?? 'Not Provided' }}</strong>
                                                        </div>
                                                        <div>
                                                            <span class="text-[10px] font-black uppercase text-slate-400">Business Registry Type</span>
                                                            <strong class="text-xs text-slate-800 block mt-1 uppercase">{{ str_replace('_', ' ', $retailSellerData->business_type ?? 'Standard') }}</strong>
                                                        </div>
                                                        <div>
                                                            <span class="text-[10px] font-black uppercase text-slate-400">Issue Date</span>
                                                            <span class="text-xs text-slate-800 block mt-1 font-semibold">{{ $retailSellerData->br_issue_date ?? 'N/A' }}</span>
                                                        </div>
                                                        <div>
                                                            <span class="text-[10px] font-black uppercase text-slate-400">Ownership Status</span>
                                                            <span class="text-xs text-slate-800 block mt-1 font-semibold uppercase">{{ $retailSellerData->ownership_type ?? 'N/A' }}</span>
                                                        </div>
                                                    </div>
                                                    @if ($retailSellerData->br_image_path)
                                                        <div class="mt-5">
                                                            <button type="button" onclick="openLightbox('{{ Str::startsWith($retailSellerData->br_image_path, ['http://', 'https://']) ? $retailSellerData->br_image_path : asset('storage/' . $retailSellerData->br_image_path) }}')" class="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-slate-150 hover:bg-slate-200 border border-slate-200/50 text-[11px] font-extrabold transition">
                                                                <i class="fa-solid fa-file-image text-slate-500"></i> View BR Registry Certificate
                                                            </button>
                                                        </div>
                                                    @endif
                                                </div>

                                                <!-- Premise Address & Info -->
                                                <div class="border border-slate-100 bg-slate-50/50 rounded-2xl p-4 flex flex-col justify-between">
                                                    <div>
                                                        <span class="text-[10px] font-black uppercase text-slate-400 block">Retail Premise Location</span>
                                                        <strong class="text-xs text-slate-800 block mt-1">{{ $retailSellerData->shop_address ?? 'No Shop Location Provided' }}</strong>
                                                        @if ($retailSellerData->postal_code)
                                                            <span class="text-[10px] text-slate-400 block mt-1 font-bold">Postal Area: {{ $retailSellerData->postal_code }}</span>
                                                        @endif
                                                    </div>
                                                    @if ($retailSellerData->notes)
                                                        <div class="mt-4 p-2.5 bg-white border border-slate-100 rounded-xl text-[10px] text-slate-500 font-semibold">
                                                            <strong>Note:</strong> {{ $retailSellerData->notes }}
                                                        </div>
                                                    @endif
                                                </div>
                                            </div>

                                            <!-- Shop Premises Photos Gallery -->
                                            @if ($retailSellerData->shop_photos)
                                                @php
                                                    $photos = is_string($retailSellerData->shop_photos) ? json_decode($retailSellerData->shop_photos, true) : $retailSellerData->shop_photos;
                                                @endphp
                                                @if (is_array($photos) && count($photos) > 0)
                                                    <div class="space-y-3">
                                                        <span class="text-[10px] font-black uppercase tracking-wider text-slate-400 block">Premises & Shop Photos</span>
                                                        <div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
                                                            @foreach ($photos as $photo)
                                                                <div class="relative rounded-2xl overflow-hidden border border-slate-200/60 aspect-[4/3] bg-white group cursor-pointer" onclick="openLightbox('{{ Str::startsWith($photo, ['http://', 'https://']) ? $photo : asset('storage/' . $photo) }}')">
                                                                    <img src="{{ Str::startsWith($photo, ['http://', 'https://']) ? $photo : asset('storage/' . $photo) }}" class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300">
                                                                    <div class="absolute inset-0 bg-slate-900/30 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center text-white text-[10px] font-black"><i class="fa-solid fa-expand mr-1"></i> Preview</div>
                                                                </div>
                                                            @endforeach
                                                        </div>
                                                    </div>
                                                @endif
                                            @endif
                                        </div>
                                    @endif

                                    <!-- Delivery Partner Specific Credentials -->
                                    @if ($deliveryPartnerData)
                                        <div class="border-t border-slate-100 pt-6 space-y-6">
                                            <h4 class="text-xs font-extrabold text-slate-900 uppercase tracking-wide flex items-center gap-2"><i class="fa-solid fa-truck-fast text-emerald-600"></i> Delivery Driver & Vehicle Ledger</h4>
                                            
                                            <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                                                
                                                <!-- Vehicle Specs -->
                                                <div class="border border-slate-100 bg-slate-50/50 rounded-2xl p-4 space-y-3">
                                                    <span class="text-[10px] font-black uppercase text-slate-400 block">Registered Vehicle</span>
                                                    <div class="space-y-2 text-xs font-semibold">
                                                        <div class="flex justify-between">
                                                            <span class="text-slate-400">License Plate</span>
                                                            <strong class="text-slate-800">{{ $deliveryPartnerData->registration_number ?? 'Not Provided' }}</strong>
                                                        </div>
                                                        <div class="flex justify-between">
                                                            <span class="text-slate-400">Make & Model</span>
                                                            <span class="text-slate-800">{{ $deliveryPartnerData->vehicle_make }} {{ $deliveryPartnerData->model }} ({{ $deliveryPartnerData->year }})</span>
                                                        </div>
                                                        <div class="flex justify-between">
                                                            <span class="text-slate-400">Class Type</span>
                                                            <span class="text-slate-800 uppercase">{{ $deliveryPartnerData->vehicle_type }}</span>
                                                        </div>
                                                        <div class="flex justify-between">
                                                            <span class="text-slate-400">Max Weight Capacity</span>
                                                            <span class="text-slate-800">{{ $deliveryPartnerData->max_weight ? $deliveryPartnerData->max_weight . ' kg' : 'N/A' }}</span>
                                                        </div>
                                                    </div>
                                                </div>

                                                <!-- License Expiries -->
                                                <div class="border border-slate-100 bg-slate-50/50 rounded-2xl p-4 space-y-3">
                                                    <span class="text-[10px] font-black uppercase text-slate-400 block">Credential Expiry States</span>
                                                    <div class="space-y-2 text-xs font-semibold">
                                                        <div class="flex justify-between">
                                                            <span class="text-slate-400">Driving License</span>
                                                            <span class="text-slate-800">{{ $deliveryPartnerData->driving_license_expiry_date ?? 'N/A' }}</span>
                                                        </div>
                                                        <div class="flex justify-between">
                                                            <span class="text-slate-400">Vehicle Insurance</span>
                                                            <span class="text-slate-800">{{ $deliveryPartnerData->insurance_expiry ?? 'N/A' }}</span>
                                                        </div>
                                                        <div class="flex justify-between">
                                                            <span class="text-slate-400">Revenue License</span>
                                                            <span class="text-slate-800">{{ $deliveryPartnerData->revenue_license_expiry ?? 'N/A' }}</span>
                                                        </div>
                                                    </div>
                                                </div>

                                                <!-- Doc Previews -->
                                                <div class="border border-slate-100 bg-slate-50/50 rounded-2xl p-4 space-y-3 flex flex-col justify-between">
                                                    <span class="text-[10px] font-black uppercase text-slate-400 block">Credential Documents</span>
                                                    <div class="grid grid-cols-2 gap-2 mt-2">
                                                        @if ($deliveryPartnerData->insurance_image_path)
                                                            <button type="button" onclick="openLightbox('{{ Str::startsWith($deliveryPartnerData->insurance_image_path, ['http://', 'https://']) ? $deliveryPartnerData->insurance_image_path : asset('storage/' . $deliveryPartnerData->insurance_image_path) }}')" class="px-2 py-2.5 rounded-xl border border-slate-200 hover:bg-white text-[10px] font-extrabold text-slate-700 transition truncate"><i class="fa-solid fa-shield mr-1 text-slate-400"></i> Insurance</button>
                                                        @endif
                                                        @if ($deliveryPartnerData->revenue_license_image_path)
                                                            <button type="button" onclick="openLightbox('{{ Str::startsWith($deliveryPartnerData->revenue_license_image_path, ['http://', 'https://']) ? $deliveryPartnerData->revenue_license_image_path : asset('storage/' . $deliveryPartnerData->revenue_license_image_path) }}')" class="px-2 py-2.5 rounded-xl border border-slate-200 hover:bg-white text-[10px] font-extrabold text-slate-700 transition truncate"><i class="fa-solid fa-file-invoice mr-1 text-slate-400"></i> Revenue</button>
                                                        @endif
                                                    </div>
                                                </div>
                                            </div>

                                            <!-- Vehicle Photos -->
                                            <div class="space-y-3">
                                                <span class="text-[10px] font-black uppercase tracking-wider text-slate-400 block">Vehicle Photos</span>
                                                <div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
                                                    @if ($deliveryPartnerData->vehicle_front_image)
                                                        <div class="relative rounded-2xl overflow-hidden border border-slate-200/60 aspect-[4/3] bg-white group cursor-pointer" onclick="openLightbox('{{ Str::startsWith($deliveryPartnerData->vehicle_front_image, ['http://', 'https://']) ? $deliveryPartnerData->vehicle_front_image : asset('storage/' . $deliveryPartnerData->vehicle_front_image) }}')">
                                                            <img src="{{ Str::startsWith($deliveryPartnerData->vehicle_front_image, ['http://', 'https://']) ? $deliveryPartnerData->vehicle_front_image : asset('storage/' . $deliveryPartnerData->vehicle_front_image) }}" class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300">
                                                            <div class="absolute inset-0 bg-slate-900/30 opacity-0 group-hover:opacity-100 flex items-center justify-center text-white text-[10px] font-black transition-opacity">Front View</div>
                                                        </div>
                                                    @endif
                                                    @if ($deliveryPartnerData->vehicle_back_image)
                                                        <div class="relative rounded-2xl overflow-hidden border border-slate-200/60 aspect-[4/3] bg-white group cursor-pointer" onclick="openLightbox('{{ Str::startsWith($deliveryPartnerData->vehicle_back_image, ['http://', 'https://']) ? $deliveryPartnerData->vehicle_back_image : asset('storage/' . $deliveryPartnerData->vehicle_back_image) }}')">
                                                            <img src="{{ Str::startsWith($deliveryPartnerData->vehicle_back_image, ['http://', 'https://']) ? $deliveryPartnerData->vehicle_back_image : asset('storage/' . $deliveryPartnerData->vehicle_back_image) }}" class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300">
                                                            <div class="absolute inset-0 bg-slate-900/30 opacity-0 group-hover:opacity-100 flex items-center justify-center text-white text-[10px] font-black transition-opacity">Back View</div>
                                                        </div>
                                                    @endif
                                                </div>
                                            </div>
                                        </div>
                                    @endif
                                </div>

                                @if ($farmerData)
                                    <div id="tab-lands" class="tab-content hidden animate-fade-in space-y-6">
                                         <div class="p-4 bg-emerald-50/40 border border-emerald-100 rounded-2xl flex items-center justify-between text-xs font-semibold">
                                             <div class="flex items-center gap-3">
                                                 <i class="fa-solid fa-map-location-dot text-emerald-600 text-base"></i>
                                                 <div>
                                                     <p class="text-slate-800 font-extrabold">Total Farming Lands Owned</p>
                                                     <p class="text-slate-500 font-medium text-[11px]">System registered land plots managed by the farmer</p>
                                                 </div>
                                             </div>
                                             <strong class="text-lg text-emerald-800 font-black">{{ $farmerData->total_lands }} Lands</strong>
                                         </div>

                                         <!-- Lands List Section -->
                                         @if ($farmerLands && $farmerLands->count() > 0)
                                             <div class="space-y-4">
                                                 <h5 class="text-xs font-extrabold text-slate-800 uppercase tracking-wide flex items-center gap-2">
                                                     <i class="fa-solid fa-map text-emerald-600"></i> Registered Land Plots ({{ $farmerLands->count() }})
                                                 </h5>
                                                 <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                                                     @foreach ($farmerLands as $land)
                                                         <div class="bg-white border border-slate-200/80 rounded-2xl p-4 shadow-sm flex flex-col justify-between hover:shadow-md transition">
                                                             <div>
                                                                 <!-- Header with status and size -->
                                                                 <div class="flex justify-between items-start">
                                                                     <div>
                                                                         <span class="text-[9px] font-black uppercase text-slate-400">Land ID #LND-{{ str_pad($land->id, 4, '0', STR_PAD_LEFT) }}</span>
                                                                         <h6 class="text-sm font-black text-slate-900 mt-0.5">{{ $land->size }} Perches</h6>
                                                                     </div>
                                                                     <div class="flex items-center gap-2">
                                                                         <span class="px-2 py-0.5 rounded-full text-[9px] font-black uppercase tracking-wider border {{ $land->status === 'verified' ? 'bg-emerald-50 text-emerald-700 border-emerald-100' : ($land->status === 'rejected' ? 'bg-rose-50 text-rose-700 border-rose-100' : 'bg-amber-50 text-amber-700 border-amber-100') }}">
                                                                             {{ $land->status }}
                                                                         </span>
                                                                         @if ($land->status === 'pending')
                                                                             <div class="flex items-center gap-1.5 border-l border-slate-200 pl-2">
                                                                                 <!-- Individual Land Approve Button -->
                                                                                 <form action="{{ route('admin.users.profile.land.approve', $land->id) }}" method="POST" id="approve-land-{{ $land->id }}" class="inline-flex items-center">
                                                                                     @csrf
                                                                                     <button type="submit" class="text-slate-300 hover:text-emerald-500 transition duration-200 inline-flex items-center" title="Approve Land">
                                                                                         <i class="fa-solid fa-circle-check text-sm"></i>
                                                                                     </button>
                                                                                 </form>
                                                                                 <!-- Individual Land Reject Button -->
                                                                                 <button type="button" onclick="rejectLand({{ $land->id }})" class="text-slate-300 hover:text-rose-500 transition duration-200 inline-flex items-center" title="Reject Land">
                                                                                     <i class="fa-solid fa-circle-xmark text-sm"></i>
                                                                                 </button>
                                                                                 <!-- Rejection Form -->
                                                                                 <form action="{{ route('admin.users.profile.land.reject', $land->id) }}" method="POST" id="reject-land-form-{{ $land->id }}" class="hidden">
                                                                                     @csrf
                                                                                     <input type="hidden" name="rejected_reason" id="reject-land-reason-input-{{ $land->id }}">
                                                                                 </form>
                                                                             </div>
                                                                         @endif
                                                                     </div>
                                                                 </div>

                                                                 <!-- Details Grid -->
                                                                 <div class="mt-4 grid grid-cols-2 gap-x-4 gap-y-2 text-[11px] font-semibold text-slate-600">
                                                                     <div>
                                                                         <span class="text-slate-400 block text-[9px] uppercase">Ownership</span>
                                                                         <span class="text-slate-800 capitalize">{{ $land->ownership_type }}</span>
                                                                     </div>
                                                                     <div>
                                                                         <span class="text-slate-400 block text-[9px] uppercase">Reg Number</span>
                                                                         <span class="text-slate-800">{{ $land->registration_number ?? 'Not Provided' }}</span>
                                                                     </div>
                                                                     @if($land->latitude && $land->longitude)
                                                                         <div class="col-span-2">
                                                                             <span class="text-slate-400 block text-[9px] uppercase">Coordinates</span>
                                                                             <span class="text-slate-800">
                                                                                 {{ $land->latitude }}, {{ $land->longitude }}
                                                                                 <a href="https://www.google.com/maps/search/?api=1&query={{ $land->latitude }},{{ $land->longitude }}" target="_blank" class="ml-1 text-emerald-600 hover:text-emerald-700 transition">
                                                                                     <i class="fa-solid fa-arrow-up-right-from-square text-[9px]"></i>
                                                                                 </a>
                                                                             </span>
                                                                             <div class="group relative rounded-xl overflow-hidden border border-slate-200 shadow-inner h-28 w-full mt-2 transition-all duration-300 hover:shadow-md hover:border-emerald-300">
                                                                                 <iframe 
                                                                                     class="w-full h-full border-0 rounded-xl" 
                                                                                     src="https://maps.google.com/maps?q={{ $land->latitude }},{{ $land->longitude }}&z=14&output=embed" 
                                                                                     allowfullscreen="" 
                                                                                     loading="lazy" 
                                                                                     referrerpolicy="no-referrer-when-downgrade">
                                                                                 </iframe>
                                                                             </div>
                                                                         </div>
                                                                     @endif
                                                                 </div>

                                                                  <!-- Cultivated Crops Section -->
                                                                  @php
                                                                      $crops = $landCrops->get($land->id) ?: collect();
                                                                  @endphp
                                                                  @if ($crops->isNotEmpty())
                                                                      <div class="mt-4 pt-3 border-t border-slate-100">
                                                                          <span class="text-[9px] font-black uppercase text-slate-400 block mb-2">Cultivated Crops</span>
                                                                          <div class="space-y-2">
                                                                              @foreach ($crops as $crop)
                                                                                  <div class="flex items-start gap-3 p-2 rounded-xl bg-slate-50 border border-slate-100 hover:bg-emerald-50/20 hover:border-emerald-100/50 transition">
                                                                                      <div class="w-10 h-10 rounded-lg bg-white border border-slate-200 overflow-hidden shrink-0 flex items-center justify-center text-slate-400">
                                                                                          @if ($crop->image_path)
                                                                                              @php
                                                                                                  $cropImgUrl = $crop->image_path;
                                                                                                  if (!Str::startsWith($cropImgUrl, ['http://', 'https://'])) {
                                                                                                      if (Str::startsWith($cropImgUrl, 'storage/')) {
                                                                                                          $cropImgUrl = asset($cropImgUrl);
                                                                                                      } else {
                                                                                                          $cropImgUrl = asset('storage/' . $cropImgUrl);
                                                                                                      }
                                                                                                  }
                                                                                              @endphp
                                                                                              <img src="{{ $cropImgUrl }}" alt="{{ $crop->cropname }}" class="w-full h-full object-cover">
                                                                                          @else
                                                                                              <i class="fa-solid fa-seedling text-emerald-600"></i>
                                                                                          @endif
                                                                                      </div>
                                                                                      <div class="min-w-0 flex-1">
                                                                                          <strong class="text-xs font-black text-slate-800 block leading-tight">{{ $crop->cropname }}</strong>
                                                                                          @if ($crop->text)
                                                                                              <p class="text-[10px] font-semibold text-slate-500 mt-0.5 leading-normal" title="{{ $crop->text }}">{{ $crop->text }}</p>
                                                                                          @endif
                                                                                      </div>
                                                                                  </div>
                                                                              @endforeach
                                                                          </div>
                                                                      </div>
                                                                  @endif

                                                                 <!-- Rejection Reason if any -->
                                                                 @if ($land->status === 'rejected' && $land->rejected_reason)
                                                                     <div class="mt-3 p-2 bg-rose-50 border border-rose-100 rounded-xl text-[10px] text-rose-700 font-semibold">
                                                                         <strong>Rejection Reason:</strong> {{ $land->rejected_reason }}
                                                                     </div>
                                                                 @endif

                                                                 <!-- Notes if any -->
                                                                 @if ($land->notes)
                                                                     <div class="mt-3 p-2 bg-slate-50 border border-slate-100 rounded-xl text-[10px] text-slate-500 italic">
                                                                         <strong>Notes:</strong> {{ $land->notes }}
                                                                     </div>
                                                                 @endif

                                                                 <!-- Land Documents if any -->
                                                                 @php
                                                                     $landDocs = json_decode($land->land_documents_paths_and_document_titles ?? '[]', true) ?: [];
                                                                 @endphp
                                                                 @if (!empty($landDocs))
                                                                     <div class="mt-4 pt-3 border-t border-slate-100">
                                                                         <span class="text-[9px] font-black uppercase text-slate-400 block mb-1.5">Documents</span>
                                                                         <div class="flex flex-wrap gap-2">
                                                                             @foreach ($landDocs as $doc)
                                                                                 <a href="{{ Str::startsWith($doc['path'], ['http://', 'https://']) ? $doc['path'] : asset('storage/' . $doc['path']) }}" target="_blank" class="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 border border-slate-200/50 text-[10px] font-bold transition">
                                                                                     <i class="fa-solid fa-file-invoice text-slate-400"></i> {{ $doc['title'] ?? 'Document' }}
                                                                                 </a>
                                                                             @endforeach
                                                                         </div>
                                                                     </div>
                                                                 @endif

                                                                 <!-- Land Images if any -->
                                                                 @php
                                                                     $landImgs = json_decode($land->land_images ?? '[]', true) ?: [];
                                                                 @endphp
                                                                 @if (!empty($landImgs))
                                                                     <div class="mt-4 pt-3 border-t border-slate-100">
                                                                         <span class="text-[9px] font-black uppercase text-slate-400 block mb-1.5">Land Images</span>
                                                                         <div class="flex flex-wrap gap-2">
                                                                             @foreach ($landImgs as $img)
                                                                                 @php
                                                                                     $imgUrl = Str::startsWith($img, ['http://', 'https://']) ? $img : asset('storage/' . $img);
                                                                                 @endphp
                                                                                 <div class="relative w-12 h-12 rounded-xl overflow-hidden border border-slate-200 cursor-pointer group" onclick="openLightbox('{{ $imgUrl }}')">
                                                                                     <img src="{{ $imgUrl }}" class="w-full h-full object-cover group-hover:scale-105 transition">
                                                                                     <div class="absolute inset-0 bg-slate-900/30 opacity-0 group-hover:opacity-100 flex items-center justify-center text-white text-[8px] font-black transition-opacity">
                                                                                         <i class="fa-solid fa-magnifying-glass-plus"></i>
                                                                                     </div>
                                                                                 </div>
                                                                             @endforeach
                                                                         </div>
                                                                     </div>
                                                                 @endif
                                                             </div>
                                                         </div>
                                                     @endforeach
                                                 </div>
                                             </div>
                                         @else
                                             <div class="border border-dashed border-slate-250 rounded-2xl p-12 text-center text-slate-400 bg-slate-50/50">
                                                 <i class="fa-solid fa-map-location-dot text-3xl text-slate-300 animate-pulse"></i>
                                                 <p class="mt-3 text-xs font-bold">No Lands Registered On System</p>
                                                 <p class="mt-1 text-[11px] text-slate-400">The farmer hasn't submitted any land plot records for audit yet.</p>
                                             </div>
                                         @endif
                                     </div>
                                 @endif

                                 @if ($farmerData)
                                     <div id="tab-logs" class="tab-content hidden animate-fade-in space-y-6">
                                         <livewire:admin.daily-cultivation-logs-table :farmer-id="$user->id" />
                                     </div>
                                     <div id="tab-chatbot" class="tab-content hidden animate-fade-in space-y-6">
                                         <livewire:admin.chatbot-history-table :farmer-id="$user->id" />
                                     </div>
                                 @endif

                                 <!-- PANEL 2: Wallet & Finance -->
                                 <div id="tab-wallet" class="tab-content hidden animate-fade-in space-y-6">
                                    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                                        <div class="border border-slate-100 bg-[#FAFBFD] p-5 rounded-2xl shadow-sm">
                                            <span class="text-[10px] font-black uppercase text-slate-400 block">Available Balance</span>
                                            <strong class="mt-3 block text-2xl font-black text-slate-900 font-poppins">LKR {{ number_format($wallet->balance ?? 0.00, 2) }}</strong>
                                        </div>
                                        <div class="border border-slate-100 bg-[#FAFBFD] p-5 rounded-2xl shadow-sm">
                                            <span class="text-[10px] font-black uppercase text-slate-400 block font-poppins">Pending Clearances</span>
                                            <strong class="mt-3 block text-2xl font-black text-slate-600 font-poppins">LKR {{ number_format($wallet->pending_balance ?? 0.00, 2) }}</strong>
                                        </div>
                                        <div class="border border-slate-100 bg-[#FAFBFD] p-5 rounded-2xl shadow-sm">
                                            <span class="text-[10px] font-black uppercase text-slate-400 block font-poppins">Wallet Security Status</span>
                                            <span class="inline-flex mt-3 items-center rounded-full border px-2.5 py-0.5 text-[9px] font-black uppercase tracking-wider {{ ($wallet->is_active ?? true) ? 'bg-emerald-50 text-emerald-700 border-emerald-100' : 'bg-rose-50 text-rose-700 border-rose-100' }}">
                                                {{ ($wallet->is_active ?? true) ? 'ACTIVE / SECURED' : 'LOCKED / SUSPENDED' }}
                                            </span>
                                        </div>
                                    </div>

                                    <!-- Transactions Ledger Table -->
                                    <div class="space-y-3">
                                        <h4 class="text-xs font-extrabold text-slate-900 uppercase tracking-wide flex items-center gap-2"><i class="fa-solid fa-file-invoice-dollar text-emerald-600"></i> Financial Transaction Ledger</h4>
                                        <div class="border border-slate-100 rounded-2xl overflow-hidden shadow-sm">
                                            <table class="min-w-full divide-y divide-slate-100 text-xs text-left">
                                                <thead class="bg-slate-50 font-extrabold uppercase text-slate-400">
                                                    <tr>
                                                        <th class="px-4 py-3">Txn Details</th>
                                                        <th class="px-4 py-3">Type</th>
                                                        <th class="px-4 py-3">Amount</th>
                                                        <th class="px-4 py-3">Reference / Note</th>
                                                        <th class="px-4 py-3">Timestamp</th>
                                                    </tr>
                                                </thead>
                                                <tbody class="divide-y divide-slate-100 font-semibold text-slate-700">
                                                    @forelse ($transactions as $txn)
                                                        @php
                                                            $txnId = 'TXN-' . str_pad($txn->id, 5, '0', STR_PAD_LEFT);
                                                            $isDebit = in_array($txn->transaction_type, ['withdrawal', 'commission'], true);
                                                            $txnColor = $isDebit ? 'text-rose-600' : 'text-emerald-600';
                                                            $txnSign = $isDebit ? '-' : '+';
                                                            $txnTypeLabel = [
                                                                'withdrawal' => 'Withdrawal',
                                                                'refund' => 'Refund',
                                                                'commission' => 'Platform Fee',
                                                                'other' => 'Other / Deposit',
                                                            ][$txn->transaction_type] ?? 'Transaction';
                                                        @endphp
                                                        <tr class="hover:bg-slate-50/50">
                                                            <td class="px-4 py-3 font-extrabold text-slate-900">
                                                                {{ $txnId }}
                                                            </td>
                                                            <td class="px-4 py-3">
                                                                <span class="inline-flex items-center rounded-full px-2 py-0.5 text-[9px] font-black uppercase tracking-wider {{ $isDebit ? 'bg-rose-50 text-rose-700' : 'bg-emerald-50 text-emerald-700' }}">
                                                                    {{ $txnTypeLabel }}
                                                                </span>
                                                            </td>
                                                            <td class="px-4 py-3 font-extrabold {{ $txnColor }}">
                                                                {{ $txnSign }} LKR {{ number_format($txn->amount, 2) }}
                                                            </td>
                                                            <td class="px-4 py-3 max-w-xs truncate" title="{{ $txn->description }}">
                                                                {{ $txn->description }}
                                                            </td>
                                                            <td class="px-4 py-3 text-slate-400 font-medium">
                                                                {{ date('Y-m-d H:i', strtotime($txn->created_at)) }}
                                                            </td>
                                                        </tr>
                                                    @empty
                                                        <tr>
                                                            <td colspan="5" class="px-4 py-8 text-center text-slate-400 font-bold">
                                                                <i class="fa-solid fa-piggy-bank text-xl block mb-2 text-slate-300"></i> No Wallet Transactions Registered
                                                            </td>
                                                        </tr>
                                                    @endforelse
                                                </tbody>
                                            </table>
                                        </div>
                                    </div>
                                </div>

                                <!-- PANEL 3: Marketplace Listings -->
                                <div id="tab-marketplace" class="tab-content hidden animate-fade-in space-y-4">
                                    <h4 class="text-xs font-extrabold text-slate-900 uppercase tracking-wide flex items-center gap-2"><i class="fa-solid fa-boxes-stacked text-emerald-600"></i> Active Store Offerings & Listings</h4>
                                    
                                    @if (count($listings) > 0)
                                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                                            @foreach ($listings as $item)
                                                <div class="border border-slate-100 rounded-2xl p-4 bg-[#FAFBFD]/70 shadow-sm flex items-start gap-4">
                                                    @if (isset($item->image_path) || isset($item->product_image))
                                                        @php
                                                            $imgPath = $item->image_path ?? $item->product_image ?? '';
                                                        @endphp
                                                        <div class="w-16 h-16 rounded-xl border border-slate-200 overflow-hidden shrink-0 bg-white">
                                                            <img src="{{ Str::startsWith($imgPath, ['http://', 'https://']) ? $imgPath : asset('storage/' . $imgPath) }}" class="w-full h-full object-cover">
                                                        </div>
                                                    @else
                                                        <div class="w-16 h-16 rounded-xl bg-slate-100 flex items-center justify-center text-slate-400 text-xs font-extrabold shrink-0 border border-slate-200">
                                                            <i class="fa-solid fa-leaf text-base"></i>
                                                        </div>
                                                    @endif
                                                    <div class="min-w-0 flex-1">
                                                        <div class="flex justify-between items-start gap-2">
                                                            <h5 class="text-xs font-extrabold text-slate-900 truncate">{{ $item->crop_name ?? $item->name ?? 'Crop Variety' }}</h5>
                                                            @if (isset($item->grade))
                                                                <span class="px-2 py-0.5 rounded bg-emerald-50 border border-emerald-100 text-emerald-700 text-[9px] font-black">Grade {{ $item->grade }}</span>
                                                            @endif
                                                        </div>
                                                        <p class="text-[10px] text-slate-400 font-bold mt-0.5">ID: #{{ $item->id }}</p>
                                                        <div class="mt-3 flex items-baseline gap-2">
                                                            <span class="text-xs font-black text-slate-800">LKR {{ number_format($item->price ?? $item->price_per_kg ?? 0, 2) }}</span>
                                                            <span class="text-[10px] text-slate-400 font-bold">/ {{ $item->unit ?? 'kg' }}</span>
                                                        </div>
                                                        <div class="mt-1.5 flex justify-between items-center text-[10px] font-bold text-slate-500">
                                                            <span>Stock: {{ $item->quantity ?? $item->stock ?? 0 }} {{ $item->unit ?? 'kg' }}</span>
                                                            <span class="uppercase tracking-wider text-[9px] px-1.5 py-0.5 rounded {{ ($item->status ?? 'active') === 'active' ? 'bg-emerald-50 text-emerald-600 border border-emerald-100' : 'bg-amber-50 text-amber-600 border border-amber-100' }}">
                                                                {{ $item->status ?? 'Active' }}
                                                            </span>
                                                        </div>
                                                    </div>
                                                </div>
                                            @endforeach
                                        </div>
                                    @else
                                        <div class="border border-dashed border-slate-200 rounded-2xl p-12 text-center text-slate-400">
                                            <i class="fa-solid fa-boxes-packing text-2xl block mb-2 text-slate-300"></i> No Catalog Listings Registered
                                        </div>
                                    @endif
                                </div>

                                <!-- PANEL 4: Ratings & Feedback -->
                                <div id="tab-reviews" class="tab-content hidden animate-fade-in space-y-6">
                                    <div class="flex items-center gap-4 p-4 border border-slate-100 rounded-2xl bg-[#FAFBFD]">
                                        <div class="text-center shrink-0 border-r border-slate-100 pr-6">
                                            <strong class="text-3xl font-black text-slate-900 block font-poppins">{{ number_format($averageRating, 1) }}</strong>
                                            <span class="text-[10px] text-slate-400 uppercase font-black tracking-wider block mt-1">Average Score</span>
                                        </div>
                                        <div class="flex-1 flex flex-col gap-1 text-[11px] font-bold text-slate-500">
                                            <div class="flex items-center gap-2">
                                                <div class="w-12 text-slate-400">Reviews</div>
                                                <div class="flex-1 h-2 rounded-full bg-slate-100 overflow-hidden">
                                                    <div class="h-full bg-emerald-600 rounded-full" style="width: {{ count($reviews) > 0 ? '100%' : '0%' }}"></div>
                                                </div>
                                                <div class="w-8 text-right font-extrabold text-slate-800">{{ count($reviews) }}</div>
                                            </div>
                                        </div>
                                    </div>

                                    <!-- Feedback Feed -->
                                    <div class="space-y-4">
                                        <h4 class="text-xs font-extrabold text-slate-900 uppercase tracking-wide flex items-center gap-2"><i class="fa-solid fa-comments text-emerald-600"></i> Public Customer Feedback Feed</h4>
                                        
                                        @if (count($reviews) > 0)
                                            <div class="divide-y divide-slate-100 border border-slate-100 rounded-2xl overflow-hidden shadow-sm bg-white">
                                                @foreach ($reviews as $rev)
                                                    <div class="p-4 space-y-2.5">
                                                        <div class="flex justify-between items-start">
                                                            <div class="flex items-center gap-3">
                                                                <div class="w-8 h-8 rounded-lg bg-slate-100 overflow-hidden flex items-center justify-center text-xs font-bold text-slate-500">
                                                                    @if (isset($rev->reviewer_avatar) && $rev->reviewer_avatar)
                                                                        <img src="{{ Str::startsWith($rev->reviewer_avatar, ['http://', 'https://']) ? $rev->reviewer_avatar : asset('storage/' . $rev->reviewer_avatar) }}" class="w-full h-full object-cover">
                                                                    @else
                                                                        <span>{{ strtoupper(substr($rev->reviewer_name ?? 'U', 0, 2)) }}</span>
                                                                    @endif
                                                                </div>
                                                                <div>
                                                                    <strong class="text-xs text-slate-800 block">{{ $rev->reviewer_name ?? 'Anonymous User' }}</strong>
                                                                    <span class="text-[9px] text-slate-400 font-bold block mt-0.5">UID #US{{ str_pad($rev->reviewed_by ?? 0, 5, '0', STR_PAD_LEFT) }}</span>
                                                                </div>
                                                            </div>

                                                            <div class="text-right">
                                                                <div class="flex text-[9px] text-amber-400 justify-end">
                                                                    @for ($i = 1; $i <= 5; $i++)
                                                                        @if ($i <= round($rev->ratings ?? $rev->rating ?? 0))
                                                                            <i class="fa-solid fa-star"></i>
                                                                        @else
                                                                            <i class="fa-regular fa-star"></i>
                                                                        @endif
                                                                    @endfor
                                                                </div>
                                                                <span class="text-[9px] text-slate-400 font-semibold block mt-1">Reviewed {{ date('Y-m-d', strtotime($rev->created_at)) }}</span>
                                                            </div>
                                                        </div>
                                                        
                                                        <p class="text-xs text-slate-600 font-medium leading-relaxed bg-[#FAFBFD] p-3 rounded-xl border border-slate-100/50">
                                                            {{ $rev->comment ?? $rev->feedback_comment ?? 'No written comment left by reviewer.' }}
                                                        </p>
                                                    </div>
                                                @endforeach
                                            </div>
                                        @else
                                            <div class="border border-dashed border-slate-200 rounded-2xl p-12 text-center text-slate-400">
                                                <i class="fa-regular fa-comment-dots text-2xl block mb-2 text-slate-300"></i> No Reviews Recorded Yet
                                            </div>
                                        @endif
                                    </div>
                                </div>

                                <!-- PANEL 5: Activity History -->
                                <div id="tab-history" class="tab-content hidden animate-fade-in space-y-4">
                                    <h4 class="text-xs font-extrabold text-slate-900 uppercase tracking-wide flex items-center gap-2"><i class="fa-solid fa-clock-history text-emerald-600"></i> Platform Activity Logs & Orders</h4>
                                    
                                    @if (count($history) > 0)
                                        <div class="border border-slate-100 rounded-2xl overflow-hidden shadow-sm bg-white">
                                            <table class="min-w-full divide-y divide-slate-100 text-xs text-left">
                                                <thead class="bg-slate-50 font-extrabold uppercase text-slate-400">
                                                    <tr>
                                                        <th class="px-4 py-3">Activity ID</th>
                                                        <th class="px-4 py-3">Party Involved</th>
                                                        <th class="px-4 py-3">Details</th>
                                                        <th class="px-4 py-3">Financial Value</th>
                                                        <th class="px-4 py-3">Status</th>
                                                        <th class="px-4 py-3">Timestamp</th>
                                                    </tr>
                                                </thead>
                                                <tbody class="divide-y divide-slate-100 font-semibold text-slate-700">
                                                    @foreach ($history as $act)
                                                        @php
                                                            // Determine column mappings depending on role
                                                            $actId = $act->id;
                                                            $partyName = $act->customer_name ?? $act->seller_name ?? 'Marketplace';
                                                            $details = isset($act->crop_name) ? ($act->crop_name . ' (' . ($act->grade ?? 'N/A') . ')') : 'Order Dispatch';
                                                            $amount = $act->total_price ?? $act->total_amount ?? $act->bid_amount ?? 0;
                                                            $status = $act->status ?? $act->bid_status ?? $act->order_status ?? 'completed';
                                                        @endphp
                                                        <tr class="hover:bg-slate-50/50">
                                                            <td class="px-4 py-3 font-extrabold text-slate-900">#{{ $actId }}</td>
                                                            <td class="px-4 py-3 font-bold">{{ $partyName }}</td>
                                                            <td class="px-4 py-3 text-slate-500 font-medium">{{ $details }}</td>
                                                            <td class="px-4 py-3 font-extrabold">LKR {{ number_format($amount, 2) }}</td>
                                                            <td class="px-4 py-3">
                                                                <span class="inline-flex items-center rounded-full px-2 py-0.5 text-[9px] font-black uppercase tracking-wider bg-emerald-50 text-emerald-700">
                                                                    {{ $status }}
                                                                </span>
                                                            </td>
                                                            <td class="px-4 py-3 text-slate-400 font-medium">{{ date('Y-m-d H:i', strtotime($act->created_at)) }}</td>
                                                        </tr>
                                                    @endforeach
                                                </tbody>
                                            </table>
                                        </div>
                                    @else
                                        <div class="border border-dashed border-slate-200 rounded-2xl p-12 text-center text-slate-400">
                                            <i class="fa-solid fa-timeline text-2xl block mb-2 text-slate-300"></i> No Platform Orders or Activity Logged
                                        </div>
                                    @endif
                                </div>

                            </div>
                        </div>

                    </div>

                </div>
            </main>

            <!-- Footer Component -->
            <x-admin-footer />
        </div>
    </div>

    <!-- Lightbox/Document Preview Modal -->
    <div id="lightbox-modal" class="fixed inset-0 z-[9999] hidden items-center justify-center p-4 bg-slate-950/80 backdrop-blur-sm" onclick="closeLightbox()">
        <div class="relative max-w-4xl max-h-[85vh] bg-white p-2.5 rounded-3xl overflow-hidden border border-slate-100 flex flex-col shadow-2xl" onclick="event.stopPropagation()">
            <button type="button" onclick="closeLightbox()" class="absolute top-4 right-4 w-9 h-9 rounded-full bg-slate-900/50 hover:bg-slate-900/80 text-white flex items-center justify-center transition shadow-lg z-10">
                <i class="fa-solid fa-xmark text-sm"></i>
            </button>
            <div class="flex-1 overflow-auto flex items-center justify-center">
                <img id="lightbox-img" src="" class="max-w-full max-h-[75vh] object-contain rounded-2xl">
            </div>
            <div class="mt-3 text-center text-[11px] font-bold text-slate-500">
                Click anywhere outside or use the button above to close window.
            </div>
        </div>
    </div>

    <script>
        // Responsive sidebar logic
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

        // Tab Switching logic
        function switchTab(tabId) {
            // Hide all tab contents
            document.querySelectorAll('.tab-content').forEach(el => {
                el.classList.add('hidden');
                el.classList.remove('block');
            });
            // Show selected tab content
            const activePanel = document.getElementById(tabId);
            if (activePanel) {
                activePanel.classList.remove('hidden');
                activePanel.classList.add('block');
            }
            
            // Remove active styles from all buttons
            document.querySelectorAll('.tab-btn').forEach(btn => {
                btn.classList.remove('border-emerald-600', 'text-emerald-700', 'font-extrabold');
                btn.classList.add('border-transparent', 'text-slate-500');
            });
            // Add active styles to clicked button
            const activeBtn = document.getElementById('btn-' + tabId);
            if (activeBtn) {
                activeBtn.classList.remove('border-transparent', 'text-slate-500');
                activeBtn.classList.add('border-emerald-600', 'text-emerald-700', 'font-extrabold');
            }

            // Update URL hash without causing a page jump
            history.replaceState(null, null, '#' + tabId);
        }

        // Rejection toggle logic
        function toggleRejectionBox() {
            const box = document.getElementById('rejection-box');
            if (box.classList.contains('hidden')) {
                box.classList.remove('hidden');
            } else {
                box.classList.add('hidden');
            }
        }

        // Action confirmation helper using SweetAlert2
        function confirmAction(formId, text, confirmButtonText, iconType) {
            Swal.fire({
                title: 'Are you sure?',
                text: text,
                icon: iconType,
                showCancelButton: true,
                confirmButtonColor: iconType === 'success' ? '#16a34a' : '#dc2626',
                cancelButtonColor: '#475569',
                confirmButtonText: confirmButtonText,
                cancelButtonText: 'Cancel',
                customClass: {
                    popup: 'rounded-3xl shadow-2xl border border-slate-100'
                }
            }).then((result) => {
                if (result.isConfirmed) {
                    document.getElementById(formId).submit();
                }
            });
        }

        // Lightbox helper logic
        function openLightbox(imageUrl) {
            const modal = document.getElementById('lightbox-modal');
            const img = document.getElementById('lightbox-img');
            img.src = imageUrl;
            modal.classList.remove('hidden');
            modal.classList.add('flex');
            modal.classList.add('animate-fade-in');
        }

        function closeLightbox() {
            const modal = document.getElementById('lightbox-modal');
            modal.classList.add('hidden');
            modal.classList.remove('flex');
        }

        // Individual Document Rejection Helper
        function rejectDocument(docId) {
            Swal.fire({
                title: 'Reject Document',
                input: 'textarea',
                inputLabel: 'Specify the reason for rejection',
                inputPlaceholder: 'e.g. Image blurry, invalid details...',
                showCancelButton: true,
                confirmButtonColor: '#dc2626',
                cancelButtonColor: '#475569',
                confirmButtonText: 'Reject Document',
                cancelButtonText: 'Cancel',
                customClass: {
                    popup: 'rounded-3xl shadow-2xl border border-slate-100'
                },
                inputValidator: (value) => {
                    if (!value || value.trim().length < 4) {
                        return 'Please enter a valid reason (min 4 characters).'
                    }
                }
            }).then((result) => {
                if (result.isConfirmed) {
                    const reason = result.value;
                    document.getElementById('reject-reason-input-' + docId).value = reason;
                    document.getElementById('reject-doc-form-' + docId).submit();
                }
            });
        }

        // Individual Land Rejection Helper
        function rejectLand(landId) {
            Swal.fire({
                title: 'Reject Land Plot',
                input: 'textarea',
                inputLabel: 'Specify the reason for rejection',
                inputPlaceholder: 'e.g. Invalid boundaries, wrong registration document...',
                showCancelButton: true,
                confirmButtonColor: '#dc2626',
                cancelButtonColor: '#475569',
                confirmButtonText: 'Reject Land',
                cancelButtonText: 'Cancel',
                customClass: {
                    popup: 'rounded-3xl shadow-2xl border border-slate-100'
                },
                inputValidator: (value) => {
                    if (!value || value.trim().length < 4) {
                        return 'Please enter a valid reason (min 4 characters).'
                    }
                }
            }).then((result) => {
                if (result.isConfirmed) {
                    const reason = result.value;
                    document.getElementById('reject-land-reason-input-' + landId).value = reason;
                    document.getElementById('reject-land-form-' + landId).submit();
                }
            });
        }
    </script>

    <!-- Toast Notifications Container -->
    <div id="toast-container" class="fixed bottom-6 right-6 z-50 flex flex-col gap-3 max-w-md w-[calc(100%-3rem)] sm:w-96 pointer-events-none"></div>

    <script>
        document.addEventListener('DOMContentLoaded', function() {
            const container = document.getElementById('toast-container');

            function showToast(message, type = 'success') {
                const toast = document.createElement('div');
                toast.className = `pointer-events-auto flex items-start gap-3 p-4 rounded-2xl border shadow-lg transform translate-y-4 opacity-0 transition-all duration-500 ease-out `;
                
                if (type === 'error' || type === 'danger') {
                    // Red Toast
                    toast.className += 'bg-rose-50 border-rose-100 text-rose-800';
                    toast.innerHTML = `
                        <div class="w-6 h-6 rounded-lg bg-rose-500/10 flex items-center justify-center text-rose-600 shrink-0 mt-0.5">
                            <i class="fa-solid fa-circle-xmark"></i>
                        </div>
                        <div class="flex-1 text-xs font-bold leading-relaxed">${message}</div>
                        <button onclick="this.parentElement.remove()" class="text-rose-400 hover:text-rose-600 transition shrink-0 ml-1">
                            <i class="fa-solid fa-xmark"></i>
                        </button>
                    `;
                } else {
                    // Green Toast
                    toast.className += 'bg-emerald-50 border-emerald-100 text-emerald-800';
                    toast.innerHTML = `
                        <div class="w-6 h-6 rounded-lg bg-emerald-500/10 flex items-center justify-center text-emerald-600 shrink-0 mt-0.5">
                            <i class="fa-solid fa-circle-check"></i>
                        </div>
                        <div class="flex-1 text-xs font-bold leading-relaxed">${message}</div>
                        <button onclick="this.parentElement.remove()" class="text-emerald-400 hover:text-emerald-600 transition shrink-0 ml-1">
                            <i class="fa-solid fa-xmark"></i>
                        </button>
                    `;
                }

                container.appendChild(toast);

                // Force layout reflow for animation
                void toast.offsetWidth;

                // Animate In
                toast.classList.remove('translate-y-4', 'opacity-0');
                toast.classList.add('translate-y-0', 'opacity-100');

                // Auto disappear
                setTimeout(() => {
                    toast.classList.add('opacity-0', 'translate-y-2');
                    toast.addEventListener('transitionend', () => {
                        toast.remove();
                    });
                }, 4000); // 4 seconds auto disappear
            }

            // Trigger Laravel flash messages
            @if (session('status'))
                const statusMsg = "{{ session('status') }}";
                const isDanger = /reject|deactivate|ban|suspend|delete|error|fail/i.test(statusMsg);
                showToast(statusMsg, isDanger ? 'error' : 'success');
            @endif

            @if ($errors->any())
                @foreach ($errors->all() as $error)
                    showToast("{{ $error }}", 'error');
                @endforeach
            @endif

            // Auto-scroll hovered tab to be fully visible
            document.querySelectorAll('.tab-btn').forEach(btn => {
                btn.addEventListener('mouseenter', () => {
                    btn.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'center' });
                });
            });

            // Smooth mouse-wheel scrolling for the tab container
            const tabContainer = document.querySelector('.tab-scroll-container');
            if (tabContainer) {
                tabContainer.addEventListener('wheel', (e) => {
                    if (e.deltaY !== 0) {
                        e.preventDefault();
                        tabContainer.scrollLeft += e.deltaY;
                    }
                });
            }

            // Restore tab from URL hash on page load
            const hash = window.location.hash;
            if (hash) {
                const targetTabId = hash.substring(1); // remove '#'
                if (document.getElementById(targetTabId)) {
                    switchTab(targetTabId);
                    // Scroll the active tab button into view
                    const activeBtn = document.getElementById('btn-' + targetTabId);
                    if (activeBtn) {
                        activeBtn.scrollIntoView({ behavior: 'auto', block: 'nearest', inline: 'center' });
                    }
                }
            }
        });
    </script>
</body>
</html>
