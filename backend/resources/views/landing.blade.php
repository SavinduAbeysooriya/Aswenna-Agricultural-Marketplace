<!DOCTYPE html>
<html lang="en" class="scroll-smooth">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Aswenna - Sri Lanka's Smart Agriculture Marketplace</title>
    <!-- Web Favicon using logo.png as requested -->
    <link rel="icon" type="image/png" href="{{ asset('images/logo.png') }}">
    <!-- Tailwind CSS -->
    <script src="https://cdn.tailwindcss.com"></script>
    <!-- Google Fonts: Inter & Poppins -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&family=Poppins:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
    <!-- FontAwesome icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <!-- Alpine.js for lightweight state management -->
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
    
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
        .leaf-glow {
            box-shadow: 0 20px 50px -15px rgba(46, 125, 50, 0.25);
        }
        .gold-glow {
            box-shadow: 0 20px 50px -15px rgba(212, 160, 23, 0.25);
        }
        .organic-blur {
            background: radial-gradient(circle, rgba(232,245,233,0.5) 0%, rgba(255,255,255,0) 70%);
        }
        .custom-scrollbar::-webkit-scrollbar {
            width: 6px;
        }
        .custom-scrollbar::-webkit-scrollbar-track {
            background: #F1F5F9;
        }
        .custom-scrollbar::-webkit-scrollbar-thumb {
            background: #CBD5E1;
            border-radius: 3px;
        }
    </style>
</head>
<body class="min-h-screen bg-slate-50 text-slate-800 antialiased overflow-x-hidden font-sans">

    <!-- Premium Header Component -->
    <x-landing-header />

    <!-- HERO SECTION -->
    <section id="hero" class="relative py-12 lg:py-24 px-6 md:px-12 max-w-7xl mx-auto overflow-hidden">
        <!-- Floating organic gradient blobs -->
        <div class="absolute -top-40 -left-40 w-[500px] h-[500px] organic-blur pointer-events-none -z-10"></div>
        <div class="absolute top-20 -right-40 w-[500px] h-[500px] organic-blur pointer-events-none -z-10"></div>

        <!-- Floating Leaf items in background -->
        <div class="absolute top-10 left-10 text-emerald-100/40 pointer-events-none animate-bounce -z-10"><i class="fa-solid fa-leaf text-5xl"></i></div>
        <div class="absolute bottom-20 right-10 text-emerald-100/30 pointer-events-none animate-bounce [animation-delay:1s] -z-10"><i class="fa-solid fa-seedling text-4xl"></i></div>

        <div class="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center relative z-10">
            <!-- Hero Left: Text & CTAs (7 cols) -->
            <div class="lg:col-span-7 space-y-8 text-center lg:text-left">
                <div class="inline-flex items-center space-x-2.5 px-4 py-2 rounded-full bg-emerald-100/70 border border-emerald-200/50 text-agri-dark font-bold text-xs uppercase tracking-wider">
                    <i class="fa-solid fa-wheat-awn animate-pulse text-base text-[#2E7D32]"></i>
                    <span>Connecting Sri Lankan Growers & Buyers Directly</span>
                </div>
                
                <h1 class="text-4xl md:text-6xl font-black font-poppins tracking-tight text-slate-900 leading-tight">
                    Sri Lanka’s Smart <br class="hidden md:inline">
                    <span class="text-[#2E7D32] bg-gradient-to-r from-agri-deep to-agri-fresh bg-clip-text text-transparent">Agriculture Marketplace</span>
                </h1>
                
                <p class="text-base md:text-lg text-slate-500 max-w-2xl mx-auto lg:mx-0 leading-relaxed font-medium">
                    A premium tech-driven agriculture ecosystem connecting farmers, commercial bulk buyers, retail stores, delivery partners, and customers islandwide. Get real-time bidding, GAP crop audits, and automatic dispatch logistics.
                </p>

                <!-- Action CTAs -->
                <div class="flex flex-col sm:flex-row justify-center lg:justify-start items-center gap-4 pt-2">
                    <a href="#download" class="w-full sm:w-auto px-8 py-4 bg-gradient-to-r from-agri-deep to-agri-fresh text-white rounded-2xl font-bold hover:shadow-xl hover:shadow-emerald-600/20 active:scale-[0.98] transition flex items-center justify-center space-x-3">
                        <i class="fa-solid fa-mobile-screen-button text-lg"></i>
                        <span>Download App</span>
                    </a>
                    <a href="#roles" class="w-full sm:w-auto px-8 py-4 bg-white border border-slate-200 text-slate-700 rounded-2xl font-bold hover:bg-slate-50 transition flex items-center justify-center space-x-2 shadow-sm">
                        <span>Explore Marketplace</span>
                        <i class="fa-solid fa-arrow-right text-xs"></i>
                    </a>
                </div>

                <!-- PlayStore and AppStore Badges -->
                <div class="flex flex-wrap justify-center lg:justify-start items-center gap-4 pt-4">
                    <a href="#" class="h-10 hover:opacity-85 transition"><img src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg" alt="Google Play Store" class="h-full"></a>
                    <a href="#" class="h-10 hover:opacity-85 transition"><img src="https://upload.wikimedia.org/wikipedia/commons/3/3c/Download_on_the_App_Store_Badge.svg" alt="App Store" class="h-full"></a>
                </div>

                <!-- Trust Indicators -->
                <div class="pt-8 border-t border-slate-200/60 max-w-lg mx-auto lg:mx-0 grid grid-cols-3 gap-4 text-center lg:text-left">
                    <div>
                        <span class="text-2xl font-extrabold text-[#2E7D32] block">1,000+</span>
                        <span class="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Verified Farmers</span>
                    </div>
                    <div>
                        <span class="text-2xl font-extrabold text-[#2E7D32] block">5,000+</span>
                        <span class="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Direct Orders</span>
                    </div>
                    <div>
                        <span class="text-2xl font-extrabold text-[#D4A017] block">Fast Route</span>
                        <span class="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Islandwide Courier</span>
                    </div>
                </div>
            </div>

            <!-- Hero Right: 3D-Like floating cards and crop mockups (5 cols) -->
            <div class="lg:col-span-5 flex justify-center relative">
                <div class="relative w-full max-w-[420px] aspect-square rounded-[48px] bg-white border border-emerald-50 shadow-2xl p-6 leaf-glow flex items-center justify-center overflow-hidden">
                    <!-- Tech grids background -->
                    <div class="absolute inset-0 bg-[linear-gradient(to_right,#f1f5f9_1px,transparent_1px),linear-gradient(to_bottom,#f1f5f9_1px,transparent_1px)] bg-[size:3rem_3rem] [mask-image:radial-gradient(ellipse_60%_50%_at_50%_0%,#000_70%,transparent_100%)] opacity-60"></div>
                    
                    <!-- Decorative Logo in centerpiece -->
                    <div class="relative z-10 flex flex-col items-center text-center space-y-4">
                        <img src="{{ asset('images/logo.png') }}" alt="Aswenna Marketplace" class="w-32 h-32 object-contain animate-pulse rounded-3xl shadow-lg border border-slate-100">
                        <h4 class="text-lg font-black text-slate-800 tracking-tight leading-none">Aswenna Direct Trade</h4>
                        <span class="text-[10px] px-2.5 py-1 rounded bg-[#E8F5E9] text-[#2E7D32] font-bold uppercase tracking-wider border border-emerald-100">Smart Gateway V1.0</span>
                    </div>

                    <!-- Floating crop yield preview cards -->
                    <div class="absolute top-6 left-6 bg-white/90 backdrop-blur border border-emerald-100 p-3 rounded-2xl shadow-md flex items-center space-x-2 animate-bounce">
                        <i class="fa-solid fa-wheat-awn text-agri-fresh text-lg"></i>
                        <div class="text-left">
                            <span class="text-[10px] block text-slate-400 font-bold uppercase leading-none">Keeri Samba</span>
                            <span class="text-xs font-extrabold text-slate-800">LKR 210/kg</span>
                        </div>
                    </div>

                    <div class="absolute bottom-10 right-6 bg-white/90 backdrop-blur border border-emerald-100 p-3 rounded-2xl shadow-md flex items-center space-x-2 animate-bounce [animation-delay:0.5s]">
                        <i class="fa-solid fa-carrot text-[#D4A017] text-lg"></i>
                        <div class="text-left">
                            <span class="text-[10px] block text-slate-400 font-bold uppercase leading-none">Carrot</span>
                            <span class="text-xs font-extrabold text-slate-800">LKR 240/kg</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- PARTNER/TRUST SECTION -->
    <section id="partners" class="bg-white border-y border-slate-100 py-10 px-6 overflow-hidden">
        <div class="max-w-7xl mx-auto flex flex-col items-center space-y-6 text-center">
            <span class="text-xs font-bold text-slate-400 uppercase tracking-widest">Trusted by Modern Agriculture Communities</span>
            <!-- Logo slider -->
            <div class="w-full overflow-hidden relative">
                <div class="flex items-center space-x-12 animate-[marquee_20s_linear_infinite] whitespace-nowrap justify-center opacity-65 font-poppins text-sm font-bold text-slate-400">
                    <span class="flex items-center space-x-2"><i class="fa-solid fa-tractor text-[#2E7D32]"></i> <span>Sri Lanka Agrarian Council</span></span>
                    <span class="flex items-center space-x-2"><i class="fa-solid fa-seedling text-[#2E7D32]"></i> <span>Ceylon Farmers Association</span></span>
                    <span class="flex items-center space-x-2"><i class="fa-solid fa-globe text-[#2E7D32]"></i> <span>GAP Sri Lanka Audit</span></span>
                    <span class="flex items-center space-x-2"><i class="fa-solid fa-truck-ramp-box text-[#2E7D32]"></i> <span>Lanka Agri Logistics Co</span></span>
                </div>
            </div>
        </div>
    </section>

    <!-- FEATURES SECTION -->
    <section id="features" class="py-20 px-6 md:px-12 max-w-7xl mx-auto">
        <div class="text-center max-w-2xl mx-auto mb-16 space-y-4">
            <div class="inline-flex items-center space-x-2 px-3 py-1 rounded-full bg-emerald-100/50 text-[#2E7D32] font-bold text-xs uppercase tracking-wide">
                <i class="fa-solid fa-cube"></i>
                <span>Platform Capabilities</span>
            </div>
            <h2 class="text-3xl md:text-4xl font-extrabold font-poppins text-slate-900 tracking-tight">Core Smart Features</h2>
            <p class="text-sm text-slate-500 font-medium leading-relaxed">
                Aswenna combines state-of-the-art SaaS logistics with local organic knowledge to optimize yield trading from fields to cities.
            </p>
        </div>

        <!-- Features Grid (8 features) -->
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            <!-- Feature 1 -->
            <div class="bg-white rounded-3xl p-6 border border-slate-100 shadow-sm hover:shadow-lg hover:border-emerald-100 transition-all duration-300 group flex flex-col justify-between">
                <div class="space-y-4">
                    <div class="w-12 h-12 rounded-2xl bg-emerald-50 text-agri-deep flex items-center justify-center text-xl group-hover:scale-110 group-hover:bg-[#E8F5E9] transition-all duration-300">
                        <i class="fa-solid fa-store"></i>
                    </div>
                    <h3 class="text-base font-bold text-slate-800">Smart Crop Marketplace</h3>
                    <p class="text-xs text-slate-400 font-medium leading-relaxed">Direct bid listings for freshly harvested bulk yields. Avoid middlemen fees instantly.</p>
                </div>
                <div class="pt-4 border-t border-slate-50 mt-4 text-[10px] font-bold text-[#2E7D32]">Learn More <i class="fa-solid fa-arrow-right ml-1"></i></div>
            </div>

            <!-- Feature 2 -->
            <div class="bg-white rounded-3xl p-6 border border-slate-100 shadow-sm hover:shadow-lg hover:border-emerald-100 transition-all duration-300 group flex flex-col justify-between">
                <div class="space-y-4">
                    <div class="w-12 h-12 rounded-2xl bg-emerald-50 text-agri-deep flex items-center justify-center text-xl group-hover:scale-110 group-hover:bg-[#E8F5E9] transition-all duration-300">
                        <i class="fa-solid fa-map-location-dot"></i>
                    </div>
                    <h3 class="text-base font-bold text-slate-800">Real-Time Order Tracking</h3>
                    <p class="text-xs text-slate-400 font-medium leading-relaxed">Watch dispatches live. Real-time courier mapping keeps buyers updated on status.</p>
                </div>
                <div class="pt-4 border-t border-slate-50 mt-4 text-[10px] font-bold text-[#2E7D32]">Learn More <i class="fa-solid fa-arrow-right ml-1"></i></div>
            </div>

            <!-- Feature 3 -->
            <div class="bg-white rounded-3xl p-6 border border-slate-100 shadow-sm hover:shadow-lg hover:border-emerald-100 transition-all duration-300 group flex flex-col justify-between">
                <div class="space-y-4">
                    <div class="w-12 h-12 rounded-2xl bg-emerald-50 text-agri-deep flex items-center justify-center text-xl group-hover:scale-110 group-hover:bg-[#E8F5E9] transition-all duration-300">
                        <i class="fa-solid fa-chart-simple"></i>
                    </div>
                    <h3 class="text-base font-bold text-slate-800">Farmer Analytics</h3>
                    <p class="text-xs text-slate-400 font-medium leading-relaxed">Daily and monthly yield metrics. Track income, withdrawals, and crop values easily.</p>
                </div>
                <div class="pt-4 border-t border-slate-50 mt-4 text-[10px] font-bold text-[#2E7D32]">Learn More <i class="fa-solid fa-arrow-right ml-1"></i></div>
            </div>

            <!-- Feature 4 -->
            <div class="bg-white rounded-3xl p-6 border border-slate-100 shadow-sm hover:shadow-lg hover:border-emerald-100 transition-all duration-300 group flex flex-col justify-between">
                <div class="space-y-4">
                    <div class="w-12 h-12 rounded-2xl bg-emerald-50 text-agri-deep flex items-center justify-center text-xl group-hover:scale-110 group-hover:bg-[#E8F5E9] transition-all duration-300">
                        <i class="fa-solid fa-wallet"></i>
                    </div>
                    <h3 class="text-base font-bold text-slate-800">Secure Payments</h3>
                    <p class="text-xs text-slate-400 font-medium leading-relaxed">Safe Escrow balances keep trades locked until items are inspected on pickup.</p>
                </div>
                <div class="pt-4 border-t border-slate-50 mt-4 text-[10px] font-bold text-[#2E7D32]">Learn More <i class="fa-solid fa-arrow-right ml-1"></i></div>
            </div>

            <!-- Feature 5 -->
            <div class="bg-white rounded-3xl p-6 border border-slate-100 shadow-sm hover:shadow-lg hover:border-emerald-100 transition-all duration-300 group flex flex-col justify-between">
                <div class="space-y-4">
                    <div class="w-12 h-12 rounded-2xl bg-emerald-50 text-agri-deep flex items-center justify-center text-xl group-hover:scale-110 group-hover:bg-[#E8F5E9] transition-all duration-300">
                        <i class="fa-solid fa-truck-fast"></i>
                    </div>
                    <h3 class="text-base font-bold text-slate-800">Delivery Partner System</h3>
                    <p class="text-xs text-slate-400 font-medium leading-relaxed">Integrated driver dispatching. Automatic routing optimized for rural roads.</p>
                </div>
                <div class="pt-4 border-t border-slate-50 mt-4 text-[10px] font-bold text-[#2E7D32]">Learn More <i class="fa-solid fa-arrow-right ml-1"></i></div>
            </div>

            <!-- Feature 6 -->
            <div class="bg-white rounded-3xl p-6 border border-slate-100 shadow-sm hover:shadow-lg hover:border-emerald-100 transition-all duration-300 group flex flex-col justify-between">
                <div class="space-y-4">
                    <div class="w-12 h-12 rounded-2xl bg-emerald-50 text-agri-deep flex items-center justify-center text-xl group-hover:scale-110 group-hover:bg-[#E8F5E9] transition-all duration-300">
                        <i class="fa-solid fa-boxes-stacked"></i>
                    </div>
                    <h3 class="text-base font-bold text-slate-800">Retail Seller Inventory</h3>
                    <p class="text-xs text-slate-400 font-medium leading-relaxed">Dedicated storefront portals. Set discounts, track stock levels, and review metrics.</p>
                </div>
                <div class="pt-4 border-t border-slate-50 mt-4 text-[10px] font-bold text-[#2E7D32]">Learn More <i class="fa-solid fa-arrow-right ml-1"></i></div>
            </div>

            <!-- Feature 7 -->
            <div class="bg-white rounded-3xl p-6 border border-slate-100 shadow-sm hover:shadow-lg hover:border-emerald-100 transition-all duration-300 group flex flex-col justify-between">
                <div class="space-y-4">
                    <div class="w-12 h-12 rounded-2xl bg-emerald-50 text-agri-deep flex items-center justify-center text-xl group-hover:scale-110 group-hover:bg-[#E8F5E9] transition-all duration-300">
                        <i class="fa-solid fa-robot"></i>
                    </div>
                    <h3 class="text-base font-bold text-slate-800">AI Agriculture Insights</h3>
                    <p class="text-xs text-slate-400 font-medium leading-relaxed">Aswenna AI advisor gives instant advice on plantation diseases and crop yields.</p>
                </div>
                <div class="pt-4 border-t border-slate-50 mt-4 text-[10px] font-bold text-[#2E7D32]">Learn More <i class="fa-solid fa-arrow-right ml-1"></i></div>
            </div>

            <!-- Feature 8 -->
            <div class="bg-white rounded-3xl p-6 border border-slate-100 shadow-sm hover:shadow-lg hover:border-emerald-100 transition-all duration-300 group flex flex-col justify-between">
                <div class="space-y-4">
                    <div class="w-12 h-12 rounded-2xl bg-emerald-50 text-agri-deep flex items-center justify-center text-xl group-hover:scale-110 group-hover:bg-[#E8F5E9] transition-all duration-300">
                        <i class="fa-solid fa-mobile-button"></i>
                    </div>
                    <h3 class="text-base font-bold text-slate-800">Easy Mobile Experience</h3>
                    <p class="text-xs text-slate-400 font-medium leading-relaxed">Designed with premium modern Flutter interfaces. Extremely lightweight and fast.</p>
                </div>
                <div class="pt-4 border-t border-slate-50 mt-4 text-[10px] font-bold text-[#2E7D32]">Learn More <i class="fa-solid fa-arrow-right ml-1"></i></div>
            </div>
        </div>
    </section>

    <!-- ROLE-BASED ECOSYSTEM SECTION -->
    <section id="roles" class="py-20 bg-white border-y border-slate-100 px-6 md:px-12" x-data="{ activeTab: 'farmers' }">
        <div class="max-w-7xl mx-auto">
            <div class="text-center max-w-2xl mx-auto mb-16 space-y-4">
                <span class="text-xs font-bold text-slate-400 uppercase tracking-widest">Interactive Ecosystem</span>
                <h2 class="text-3xl md:text-4xl font-extrabold font-poppins text-slate-900 tracking-tight">Tailored Role Experiences</h2>
                <p class="text-sm text-slate-500 font-medium leading-relaxed">
                    Select a marketplace role profile below to preview custom features and operational dashboard frameworks.
                </p>
            </div>

            <!-- Custom Tab Selector Buttons -->
            <div class="flex flex-wrap justify-center gap-3 mb-12">
                <button @click="activeTab = 'farmers'" :class="activeTab === 'farmers' ? 'bg-[#2E7D32] text-white shadow-md' : 'bg-slate-50 text-slate-600 hover:bg-slate-100'" class="px-6 py-3 rounded-2xl font-bold text-sm transition">
                    <i class="fa-solid fa-wheat-awn mr-2"></i> Farmers & Growers
                </button>
                <button @click="activeTab = 'buyers'" :class="activeTab === 'buyers' ? 'bg-[#2E7D32] text-white shadow-md' : 'bg-slate-50 text-slate-600 hover:bg-slate-100'" class="px-6 py-3 rounded-2xl font-bold text-sm transition">
                    <i class="fa-solid fa-shop mr-2"></i> Bulk Commercial Buyers
                </button>
                <button @click="activeTab = 'retailers'" :class="activeTab === 'retailers' ? 'bg-[#2E7D32] text-white shadow-md' : 'bg-slate-50 text-slate-600 hover:bg-slate-100'" class="px-6 py-3 rounded-2xl font-bold text-sm transition">
                    <i class="fa-solid fa-store mr-2"></i> Retail Sellers
                </button>
                <button @click="activeTab = 'couriers'" :class="activeTab === 'couriers' ? 'bg-[#2E7D32] text-white shadow-md' : 'bg-slate-50 text-slate-600 hover:bg-slate-100'" class="px-6 py-3 rounded-2xl font-bold text-sm transition">
                    <i class="fa-solid fa-truck-fast mr-2"></i> Delivery Partners
                </button>
            </div>

            <!-- Tab Content Screens -->
            <div class="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
                
                <!-- Tab text content (6 cols) -->
                <div class="lg:col-span-6 space-y-6">
                    
                    <!-- Farmer tab details -->
                    <div x-show="activeTab === 'farmers'" class="space-y-6" x-transition:enter="transition ease-out duration-200" x-transition:enter-start="opacity-0 translate-y-4">
                        <div class="inline-flex px-3 py-1 rounded-lg bg-emerald-50 border border-emerald-100 text-[#2E7D32] text-xs font-bold uppercase tracking-wider">GAP Verified Production</div>
                        <h3 class="text-2xl font-extrabold font-poppins text-slate-800">Optimize Your Crop Income</h3>
                        <p class="text-sm text-slate-500 leading-relaxed font-medium">Farmers can easily list their harvested yields for immediate auction or bulk sales. Verify plantations, check bid progression, and trace payouts secure in escrow accounts.</p>
                        <ul class="space-y-3 text-xs font-bold text-slate-600">
                            <li class="flex items-center space-x-2"><i class="fa-solid fa-circle-check text-agri-fresh"></i> <span>List yields directly from fields in minutes</span></li>
                            <li class="flex items-center space-x-2"><i class="fa-solid fa-circle-check text-agri-fresh"></i> <span>Secure bid auctions with commercial mills</span></li>
                            <li class="flex items-center space-x-2"><i class="fa-solid fa-circle-check text-agri-fresh"></i> <span>Track wallet earnings and withdrawals</span></li>
                        </ul>
                    </div>

                    <!-- Buyer tab details -->
                    <div x-show="activeTab === 'buyers'" class="space-y-6" x-transition:enter="transition ease-out duration-200" x-transition:enter-start="opacity-0 translate-y-4">
                        <div class="inline-flex px-3 py-1 rounded-lg bg-emerald-50 border border-emerald-100 text-[#2E7D32] text-xs font-bold uppercase tracking-wider">Bulk Procurement</div>
                        <h3 class="text-2xl font-extrabold font-poppins text-slate-800">Source Directly from Trusted Fields</h3>
                        <p class="text-sm text-slate-500 leading-relaxed font-medium">Commercial buyers, mills, and exporters can source crops directly. Review GAP certificates, bid on yield contracts, and enjoy seamless dispatch integrations.</p>
                        <ul class="space-y-3 text-xs font-bold text-slate-600">
                            <li class="flex items-center space-x-2"><i class="fa-solid fa-circle-check text-agri-fresh"></i> <span>Bid on fresh yields before harvesting</span></li>
                            <li class="flex items-center space-x-2"><i class="fa-solid fa-circle-check text-agri-fresh"></i> <span>Automatic GAP and organic certificate review</span></li>
                            <li class="flex items-center space-x-2"><i class="fa-solid fa-circle-check text-agri-fresh"></i> <span>Direct invoice generation for accounting</span></li>
                        </ul>
                    </div>

                    <!-- Retailers tab details -->
                    <div x-show="activeTab === 'retailers'" class="space-y-6" x-transition:enter="transition ease-out duration-200" x-transition:enter-start="opacity-0 translate-y-4">
                        <div class="inline-flex px-3 py-1 rounded-lg bg-emerald-50 border border-emerald-100 text-[#2E7D32] text-xs font-bold uppercase tracking-wider">Storefront Operations</div>
                        <h3 class="text-2xl font-extrabold font-poppins text-slate-800">Manage Fresh Stock Flawlessly</h3>
                        <p class="text-sm text-slate-500 leading-relaxed font-medium">Grocery stores and retail marts can operate online catalogs, set custom discount tiers, manage store products, and organize dispatches for local clients.</p>
                        <ul class="space-y-3 text-xs font-bold text-slate-600">
                            <li class="flex items-center space-x-2"><i class="fa-solid fa-circle-check text-agri-fresh"></i> <span>Custom online mart catalog builders</span></li>
                            <li class="flex items-center space-x-2"><i class="fa-solid fa-circle-check text-agri-fresh"></i> <span>Automated low-stock notification parameters</span></li>
                            <li class="flex items-center space-x-2"><i class="fa-solid fa-circle-check text-agri-fresh"></i> <span>Interactive promo and offer goal builder</span></li>
                        </ul>
                    </div>

                    <!-- Couriers tab details -->
                    <div x-show="activeTab === 'couriers'" class="space-y-6" x-transition:enter="transition ease-out duration-200" x-transition:enter-start="opacity-0 translate-y-4">
                        <div class="inline-flex px-3 py-1 rounded-lg bg-emerald-50 border border-emerald-100 text-[#2E7D32] text-xs font-bold uppercase tracking-wider">Logistics Dispatch</div>
                        <h3 class="text-2xl font-extrabold font-poppins text-slate-800">Optimize Rural Routes</h3>
                        <p class="text-sm text-slate-500 leading-relaxed font-medium">Courier drivers and logistics companies can accept delivery requests, optimize routes using direct maps, check wallet commissions, and confirm tasks upon secure QR scans.</p>
                        <ul class="space-y-3 text-xs font-bold text-slate-600">
                            <li class="flex items-center space-x-2"><i class="fa-solid fa-circle-check text-agri-fresh"></i> <span>Smart pathing system to bypass rural obstacles</span></li>
                            <li class="flex items-center space-x-2"><i class="fa-solid fa-circle-check text-agri-fresh"></i> <span>Instant commission dispatches directly to wallet</span></li>
                            <li class="flex items-center space-x-2"><i class="fa-solid fa-circle-check text-agri-fresh"></i> <span>Easy QR verification on pickup and delivery</span></li>
                        </ul>
                    </div>

                </div>

                <!-- Tab visual mockups (6 cols) -->
                <div class="lg:col-span-6 flex justify-center">
                    <div class="relative w-full max-w-[360px] aspect-[9/16] bg-slate-900 rounded-[44px] shadow-2xl p-3 border-4 border-slate-850 flex items-center justify-center overflow-hidden">
                        <!-- Camera notch -->
                        <div class="absolute top-0 left-1/2 transform -translate-x-1/2 w-32 h-6 bg-slate-850 rounded-b-2xl z-20 flex items-center justify-center">
                            <div class="w-3 h-3 rounded-full bg-slate-900 mr-2"></div>
                            <div class="w-10 h-1 bg-slate-900 rounded-full"></div>
                        </div>

                        <!-- Device viewport content -->
                        <div class="w-full h-full bg-slate-50 rounded-[36px] overflow-hidden flex flex-col justify-between relative pt-8 p-4 font-sans text-xs">
                            <!-- Custom mockup components depending on Alpine role state -->
                            <div class="flex justify-between items-center pb-2 border-b border-slate-100">
                                <span class="font-extrabold text-[#2E7D32]">Aswenna Mart</span>
                                <span class="px-2 py-0.5 rounded bg-emerald-100 text-emerald-800 text-[8px] font-bold uppercase tracking-wider" x-text="activeTab">farmers</span>
                            </div>

                            <div class="flex-1 flex flex-col justify-center items-center py-4 space-y-3 text-center">
                                <i class="fa-solid fa-laptop-code text-5xl text-slate-300"></i>
                                <span class="font-bold text-slate-800 leading-none">Interactive Preview Area</span>
                                <p class="text-[10px] text-slate-400">Sign in to the Aswenna app to utilize the custom features designed for this profile.</p>
                            </div>

                            <div class="pt-2 border-t border-slate-100 flex justify-between items-center text-[10px] font-bold text-slate-400">
                                <span><i class="fa-solid fa-house"></i> Home</span>
                                <span><i class="fa-solid fa-chart-simple"></i> Stats</span>
                                <span><i class="fa-solid fa-wallet"></i> Wallet</span>
                            </div>
                        </div>
                    </div>
                </div>

            </div>
        </div>
    </section>

    <!-- APP SHOWCASE SECTION -->
    <section id="app-showcase" class="py-20 px-6 md:px-12 max-w-7xl mx-auto" x-data="{ activeSlide: 1 }">
        <div class="text-center max-w-2xl mx-auto mb-16 space-y-4">
            <span class="text-xs font-bold text-slate-400 uppercase tracking-widest font-poppins">Premium Mobile Showcase</span>
            <h2 class="text-3xl md:text-4xl font-extrabold font-poppins text-slate-900 tracking-tight">Beautiful App Previews</h2>
            <p class="text-sm text-slate-500 font-medium leading-relaxed">Take a look inside the modern, minimal design framework built to ensure accessible operations.</p>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
            
            <!-- App Details Links (5 cols) -->
            <div class="lg:col-span-5 space-y-3">
                <button @click="activeSlide = 1" :class="activeSlide === 1 ? 'border-l-4 border-[#2E7D32] bg-emerald-50/50 pl-4' : 'border-l-4 border-slate-200 pl-4 hover:border-slate-350'" class="w-full text-left py-3 transition duration-200">
                    <span class="text-sm font-bold text-slate-800 block">Direct Crop Bidding Portal</span>
                    <span class="text-xs text-slate-400 block mt-1">Trace active farmer harvest listings, check bidding caps, and execute safe transactions.</span>
                </button>
                <button @click="activeSlide = 2" :class="activeSlide === 2 ? 'border-l-4 border-[#2E7D32] bg-emerald-50/50 pl-4' : 'border-l-4 border-slate-200 pl-4 hover:border-slate-350'" class="w-full text-left py-3 transition duration-200">
                    <span class="text-sm font-bold text-slate-800 block">Live Courier Route Maps</span>
                    <span class="text-xs text-slate-400 block mt-1">Real-time status updates showing assigns, pickups, route coordinates, and arrivals.</span>
                </button>
                <button @click="activeSlide = 3" :class="activeSlide === 3 ? 'border-l-4 border-[#2E7D32] bg-emerald-50/50 pl-4' : 'border-l-4 border-slate-200 pl-4 hover:border-slate-350'" class="w-full text-left py-3 transition duration-200">
                    <span class="text-sm font-bold text-slate-800 block">Comprehensive Farmer Wallet</span>
                    <span class="text-xs text-slate-400 block mt-1">Review active balances, earnings, withdrawal timelines, and transaction histories.</span>
                </button>
            </div>

            <!-- Phone mockup display slider (7 cols) -->
            <div class="lg:col-span-7 flex justify-center">
                <div class="relative w-full max-w-[340px] aspect-[9/16] bg-slate-900 rounded-[44px] shadow-2xl p-3 border-4 border-slate-850 flex items-center justify-center overflow-hidden">
                    
                    <!-- Viewport Mockup Area -->
                    <div class="w-full h-full bg-slate-50 rounded-[36px] overflow-hidden flex flex-col justify-between relative pt-8 p-4 font-sans text-xs">
                        
                        <!-- Slide 1: Crop Bidding Portal -->
                        <div x-show="activeSlide === 1" class="flex-1 flex flex-col justify-between" x-transition:enter="transition ease-out duration-300" x-transition:enter-start="opacity-0 translate-x-4">
                            <div class="space-y-3">
                                <span class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Active Bids</span>
                                <h4 class="text-sm font-bold text-slate-800 leading-none">Fresh Nuwara Eliya Carrot</h4>
                                <span class="inline-flex px-2 py-0.5 rounded bg-emerald-100 text-emerald-800 text-[8px] font-bold uppercase">Auction Active</span>
                                
                                <div class="bg-white p-3 rounded-2xl border border-slate-100 space-y-2 mt-2">
                                    <div class="flex justify-between text-[10px]">
                                        <span class="text-slate-400">Current Bid</span>
                                        <span class="font-extrabold text-[#2E7D32]">LKR 240/kg</span>
                                    </div>
                                    <div class="flex justify-between text-[10px]">
                                        <span class="text-slate-400">Available Quantity</span>
                                        <span class="font-bold text-slate-800">350 kg</span>
                                    </div>
                                </div>
                            </div>
                            <button class="w-full py-3 bg-[#2E7D32] text-white rounded-xl font-bold text-[10px]">Place Custom Bid</button>
                        </div>

                        <!-- Slide 2: Courier Route Maps -->
                        <div x-show="activeSlide === 2" class="flex-1 flex flex-col justify-between" x-transition:enter="transition ease-out duration-300" x-transition:enter-start="opacity-0 translate-x-4">
                            <div class="space-y-3">
                                <span class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Courier Dispatch</span>
                                <h4 class="text-sm font-bold text-slate-800 leading-none">Route Tracking: #ORD892</h4>
                                <span class="inline-flex px-2 py-0.5 rounded bg-amber-100 text-amber-800 text-[8px] font-bold uppercase">On The Way</span>
                                
                                <div class="bg-white p-3 rounded-2xl border border-slate-100 space-y-2 mt-2">
                                    <div class="flex justify-between text-[10px]">
                                        <span class="text-slate-400">Current Location</span>
                                        <span class="font-bold text-slate-800">Kandy Road, Kiribathgoda</span>
                                    </div>
                                    <div class="flex justify-between text-[10px]">
                                        <span class="text-slate-400">ETA</span>
                                        <span class="font-bold text-[#2E7D32]">45 mins</span>
                                    </div>
                                </div>
                            </div>
                            <button class="w-full py-3 bg-slate-900 text-white rounded-xl font-bold text-[10px]">Contact Delivery Partner</button>
                        </div>

                        <!-- Slide 3: Comprehensive Farmer Wallet -->
                        <div x-show="activeSlide === 3" class="flex-1 flex flex-col justify-between" x-transition:enter="transition ease-out duration-300" x-transition:enter-start="opacity-0 translate-x-4">
                            <div class="space-y-3">
                                <span class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Active Wallet Balance</span>
                                <h4 class="text-sm font-bold text-slate-800 leading-none">Earnings Treasury Overview</h4>
                                <span class="inline-flex px-2 py-0.5 rounded bg-emerald-100 text-emerald-800 text-[8px] font-bold uppercase">Escrow Secure</span>
                                
                                <div class="bg-white p-3 rounded-2xl border border-slate-100 space-y-2 mt-2">
                                    <div class="flex justify-between text-[10px]">
                                        <span class="text-slate-400">Available Balance</span>
                                        <span class="font-extrabold text-[#2E7D32]">LKR 84,500</span>
                                    </div>
                                    <div class="flex justify-between text-[10px]">
                                        <span class="text-slate-400">Pending Balance</span>
                                        <span class="font-bold text-slate-800">LKR 12,000</span>
                                    </div>
                                </div>
                            </div>
                            <button class="w-full py-3 bg-[#D4A017] text-slate-950 rounded-xl font-bold text-[10px]">Request Fast Withdrawal</button>
                        </div>

                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- HOW IT WORKS SECTION -->
    <section id="process" class="py-20 bg-white border-y border-slate-100 px-6 md:px-12">
        <div class="max-w-7xl mx-auto">
            <div class="text-center max-w-2xl mx-auto mb-16 space-y-4">
                <span class="text-xs font-bold text-slate-400 uppercase tracking-widest">Quick Start Timeline</span>
                <h2 class="text-3xl md:text-4xl font-extrabold font-poppins text-slate-900 tracking-tight">How It Works</h2>
                <p class="text-sm text-slate-500 font-medium leading-relaxed">Follow these simple steps to begin trading directly on our smart agricultural marketplace platform.</p>
            </div>

            <!-- Steps Grid -->
            <div class="grid grid-cols-1 md:grid-cols-5 gap-8 relative">
                
                <!-- Step 1 -->
                <div class="text-center space-y-4 relative group">
                    <div class="w-12 h-12 rounded-full bg-[#E8F5E9] text-[#2E7D32] flex items-center justify-center font-extrabold text-base mx-auto shadow-inner group-hover:scale-105 transition-transform duration-200">1</div>
                    <h4 class="text-sm font-bold text-slate-800">Register</h4>
                    <p class="text-[11px] text-slate-400 leading-relaxed max-w-xs mx-auto">Install the app and verify your mobile number securely.</p>
                </div>

                <!-- Step 2 -->
                <div class="text-center space-y-4 relative group">
                    <div class="w-12 h-12 rounded-full bg-[#E8F5E9] text-[#2E7D32] flex items-center justify-center font-extrabold text-base mx-auto shadow-inner group-hover:scale-105 transition-transform duration-200">2</div>
                    <h4 class="text-sm font-bold text-slate-800">Choose Your Role</h4>
                    <p class="text-[11px] text-slate-400 leading-relaxed max-w-xs mx-auto">Select Farmer, Bulk Buyer, Retailer, or Courier profile.</p>
                </div>

                <!-- Step 3 -->
                <div class="text-center space-y-4 relative group">
                    <div class="w-12 h-12 rounded-full bg-[#E8F5E9] text-[#2E7D32] flex items-center justify-center font-extrabold text-base mx-auto shadow-inner group-hover:scale-105 transition-transform duration-200">3</div>
                    <h4 class="text-sm font-bold text-slate-800">Buy or Sell</h4>
                    <p class="text-[11px] text-slate-400 leading-relaxed max-w-xs mx-auto">List yields directly or place bids on verified crop contracts.</p>
                </div>

                <!-- Step 4 -->
                <div class="text-center space-y-4 relative group">
                    <div class="w-12 h-12 rounded-full bg-[#E8F5E9] text-[#2E7D32] flex items-center justify-center font-extrabold text-base mx-auto shadow-inner group-hover:scale-105 transition-transform duration-200">4</div>
                    <h4 class="text-sm font-bold text-slate-800">Track Orders</h4>
                    <p class="text-[11px] text-slate-400 leading-relaxed max-w-xs mx-auto">Verify live dispatches using our integrated courier partner routes.</p>
                </div>

                <!-- Step 5 -->
                <div class="text-center space-y-4 relative group">
                    <div class="w-12 h-12 rounded-full bg-[#D4A017]/10 text-[#D4A017] flex items-center justify-center font-extrabold text-base mx-auto shadow-inner group-hover:scale-105 transition-transform duration-200">5</div>
                    <h4 class="text-sm font-bold text-slate-800">Grow Your Business</h4>
                    <p class="text-[11px] text-slate-400 leading-relaxed max-w-xs mx-auto">Check metrics and optimize your yields using AI insights.</p>
                </div>

            </div>
        </div>
    </section>

    <!-- STATISTICS SECTION -->
    <section id="statistics" class="py-16 bg-slate-900 text-white px-6 md:px-12 relative overflow-hidden">
        <!-- Leaves graphics in background -->
        <div class="absolute -top-12 -left-12 text-slate-800/20 pointer-events-none z-0"><i class="fa-solid fa-leaf text-9xl"></i></div>
        
        <div class="max-w-7xl mx-auto grid grid-cols-2 lg:grid-cols-4 gap-8 text-center relative z-10">
            <div class="space-y-2">
                <span class="text-3xl md:text-5xl font-black block font-poppins text-agri-fresh">1,240+</span>
                <span class="text-[10px] font-bold text-slate-450 uppercase tracking-widest block">Farmers Registered</span>
            </div>
            <div class="space-y-2">
                <span class="text-3xl md:text-5xl font-black block font-poppins text-white">4,890+</span>
                <span class="text-[10px] font-bold text-slate-450 uppercase tracking-widest block">Crops Listed</span>
            </div>
            <div class="space-y-2">
                <span class="text-3xl md:text-5xl font-black block font-poppins text-agri-fresh">894+</span>
                <span class="text-[10px] font-bold text-slate-450 uppercase tracking-widest block">Deliveries Completed</span>
            </div>
            <div class="space-y-2">
                <span class="text-3xl md:text-5xl font-black block font-poppins text-[#D4A017]">99.8%</span>
                <span class="text-[10px] font-bold text-slate-455 uppercase tracking-widest block">Happy Customers</span>
            </div>
        </div>
    </section>

    <!-- DOWNLOAD APP SECTION -->
    <section id="download" class="py-20 px-6 md:px-12 max-w-7xl mx-auto">
        <div class="bg-gradient-to-tr from-slate-900 to-[#1B5E20] rounded-3xl p-8 md:p-12 text-white relative overflow-hidden flex flex-col lg:flex-row justify-between items-center gap-12 border border-emerald-800/40 shadow-2xl">
            <!-- Background blurs -->
            <div class="absolute -top-32 -left-32 w-64 h-64 bg-emerald-500/10 rounded-full blur-3xl pointer-events-none"></div>

            <div class="space-y-6 max-w-xl text-center lg:text-left relative z-10">
                <h3 class="text-3xl md:text-5xl font-black font-poppins leading-tight">Take Sri Lankan Agriculture Everywhere</h3>
                <p class="text-sm text-emerald-100/80 leading-relaxed font-medium">Download the Aswenna Mobile App today to register your profile, auction crops, review order dispatches, and enjoy smart direct trading guarantees.</p>
                
                <div class="flex flex-wrap justify-center lg:justify-start gap-4">
                    <a href="#" class="h-12 hover:opacity-85 transition"><img src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg" alt="Play Store" class="h-full"></a>
                    <a href="#" class="h-12 hover:opacity-85 transition"><img src="https://upload.wikimedia.org/wikipedia/commons/3/3c/Download_on_the_App_Store_Badge.svg" alt="App Store" class="h-full"></a>
                </div>
            </div>

            <!-- QR Code Placeholder and floating Mockup -->
            <div class="bg-white/10 backdrop-blur-md p-6 rounded-3xl border border-white/10 flex flex-col items-center text-center space-y-4 max-w-[240px] relative z-10">
                <div class="w-36 h-36 bg-white rounded-2xl p-2 flex items-center justify-center shadow-inner">
                    <!-- Simulated QR code icon -->
                    <i class="fa-solid fa-qrcode text-[100px] text-slate-800"></i>
                </div>
                <div>
                    <span class="text-xs font-bold block">Scan to Install</span>
                    <span class="text-[9px] text-emerald-200 font-medium mt-1 block">Compatible with Android & iOS</span>
                </div>
            </div>
        </div>
    </section>

    <!-- TESTIMONIALS SECTION -->
    <section id="testimonials" class="py-20 bg-white border-y border-slate-100 px-6 md:px-12" x-data="{ activeIndex: 0, items: [
        { quote: 'Aswenna completely changed my life. I avoided middlemen commission fees and sold my Nuwara Eliya carrots directly to commercial mills. My income increased by 40%!', author: 'Saman Kumara', role: 'Carrot Farmer (Nuwara Eliya)' },
        { quote: ' sourcing keeri samba rice has never been so seamless. We can review GAP certification credentials online, place bulk bids, and watch dispatches live.', author: 'Sunil Perera', role: 'Keeri Samba Mills Exporters' },
        { quote: 'We manage grocery mart inventory directly on the app, set promotional offers, and utilize local delivery partners. Incredible UI and flawless operations.', author: 'Agro Retail Mart', role: 'Grocery Retail Seller' }
    ]}">
        <div class="max-w-7xl mx-auto">
            <div class="text-center max-w-2xl mx-auto mb-16 space-y-4">
                <span class="text-xs font-bold text-slate-400 uppercase tracking-widest font-poppins">Customer Validation</span>
                <h2 class="text-3xl md:text-4xl font-extrabold font-poppins text-slate-900 tracking-tight">Ecosystem Feedback</h2>
                <p class="text-sm text-slate-500 font-medium leading-relaxed">Here is what registered growers, commercial exporters, and retail shops say about Aswenna.</p>
            </div>

            <!-- Testimonial Slider card -->
            <div class="max-w-3xl mx-auto bg-slate-50 rounded-3xl p-8 border border-slate-100 shadow-sm relative text-center space-y-6">
                <!-- Quote icon decoration -->
                <i class="fa-solid fa-quote-left text-5xl text-[#E8F5E9] block mx-auto"></i>

                <!-- Active Quote -->
                <p class="text-sm md:text-base text-slate-650 leading-relaxed font-semibold italic" x-text="items[activeIndex].quote"></p>
                
                <div class="space-y-1">
                    <span class="text-sm font-extrabold text-slate-800 block" x-text="items[activeIndex].author"></span>
                    <span class="text-[11px] font-bold text-[#2E7D32] uppercase tracking-wider block" x-text="items[activeIndex].role"></span>
                </div>

                <!-- Navigation Dot Triggers -->
                <div class="flex justify-center space-x-2 pt-4">
                    <template x-for="(item, index) in items" :key="index">
                        <button @click="activeIndex = index" :class="activeIndex === index ? 'w-6 bg-[#2E7D32]' : 'w-2 bg-slate-350'" class="h-2 rounded-full transition-all duration-300"></button>
                    </template>
                </div>
            </div>
        </div>
    </section>

    <!-- FAQ SECTION -->
    <section id="faq" class="py-20 px-6 md:px-12 max-w-7xl mx-auto" x-data="{ openFaq: 0 }">
        <div class="text-center max-w-2xl mx-auto mb-16 space-y-4">
            <span class="text-xs font-bold text-slate-400 uppercase tracking-widest font-poppins">About & FAQ</span>
            <h2 class="text-3xl md:text-4xl font-extrabold font-poppins text-slate-900 tracking-tight">Common Questions</h2>
            <p class="text-sm text-slate-500 font-medium leading-relaxed">Here are quick, transparent answers to frequent operations queries.</p>
        </div>

        <div class="max-w-3xl mx-auto space-y-4">
            <!-- FAQ 1 -->
            <div class="bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden">
                <button @click="openFaq = (openFaq === 1 ? 0 : 1)" class="w-full p-5 text-left font-bold text-slate-800 text-sm flex justify-between items-center focus:outline-none">
                    <span>How does Aswenna work?</span>
                    <i :class="openFaq === 1 ? 'fa-solid fa-minus text-[#2E7D32]' : 'fa-solid fa-plus text-slate-400'"></i>
                </button>
                <div x-show="openFaq === 1" class="p-5 pt-0 text-xs text-slate-500 leading-relaxed font-semibold border-t border-slate-50" x-transition>
                    Aswenna is a unified digital platform. Farmers list crops directly, commercial buyers place bids, local retail marts operate storefront catalogs, and courier partners execute dispatches utilizing optimized route mapping.
                </div>
            </div>

            <!-- FAQ 2 -->
            <div class="bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden">
                <button @click="openFaq = (openFaq === 2 ? 0 : 2)" class="w-full p-5 text-left font-bold text-slate-800 text-sm flex justify-between items-center focus:outline-none">
                    <span>How do farmers sell products?</span>
                    <i :class="openFaq === 2 ? 'fa-solid fa-minus text-[#2E7D32]' : 'fa-solid fa-plus text-slate-400'"></i>
                </button>
                <div x-show="openFaq === 2" class="p-5 pt-0 text-xs text-slate-500 leading-relaxed font-semibold border-t border-slate-50" x-transition>
                    Farmers list their crops including quantity, standard grade options (Grade A/B/C), expected price details, and certificates. Verified GAP growers can trigger auction bids for commercial bulk purchases.
                </div>
            </div>

            <!-- FAQ 3 -->
            <div class="bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden">
                <button @click="openFaq = (openFaq === 3 ? 0 : 3)" class="w-full p-5 text-left font-bold text-slate-800 text-sm flex justify-between items-center focus:outline-none">
                    <span>How are deliveries managed?</span>
                    <i :class="openFaq === 3 ? 'fa-solid fa-minus text-[#2E7D32]' : 'fa-solid fa-plus text-slate-400'"></i>
                </button>
                <div x-show="openFaq === 3" class="p-5 pt-0 text-xs text-slate-500 leading-relaxed font-semibold border-t border-slate-50" x-transition>
                    When a buyer checks out fresh products or accepts bids, our automatic dispatch engine assigns the task to a verified delivery courier. Couriers complete tasks securely via direct QR codes upon handoff.
                </div>
            </div>

            <!-- FAQ 4 -->
            <div class="bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden">
                <button @click="openFaq = (openFaq === 4 ? 0 : 4)" class="w-full p-5 text-left font-bold text-slate-800 text-sm flex justify-between items-center focus:outline-none">
                    <span>Is payment secure?</span>
                    <i :class="openFaq === 4 ? 'fa-solid fa-minus text-[#2E7D32]' : 'fa-solid fa-plus text-slate-400'"></i>
                </button>
                <div x-show="openFaq === 4" class="p-5 pt-0 text-xs text-slate-500 leading-relaxed font-semibold border-t border-slate-50" x-transition>
                    Yes. All payments utilize the Aswenna Wallet Escrow guarantee. Balances are safely locked until items are inspected, preventing fraud and securing agricultural trade parameters.
                </div>
            </div>
        </div>
    </section>

    <!-- CONTACT SECTION -->
    <section id="contact" class="py-20 px-6 md:px-12 max-w-7xl mx-auto">
        <div class="bg-white rounded-[32px] border border-slate-100 shadow-xl overflow-hidden grid grid-cols-1 lg:grid-cols-12">
            <!-- Contact info card (5 cols) -->
            <div class="lg:col-span-5 bg-slate-900 text-white p-8 md:p-12 space-y-8 relative overflow-hidden flex flex-col justify-between">
                <div class="space-y-6">
                    <h3 class="text-2xl font-extrabold font-poppins">Get In Touch</h3>
                    <p class="text-xs text-slate-450 leading-relaxed font-medium">Have inquiries regarding direct auctions, store setups, or courier verifications? Complete the form to contact security operations.</p>
                </div>
                <div class="space-y-4 text-xs font-bold text-slate-350">
                    <div class="flex items-center space-x-3">
                        <i class="fa-solid fa-envelope text-[#4CAF50] text-base"></i>
                        <span>support@aswenna.lk</span>
                    </div>
                    <div class="flex items-center space-x-3">
                        <i class="fa-solid fa-phone text-[#4CAF50] text-base"></i>
                        <span>+94 (11) 234-5678</span>
                    </div>
                    <div class="flex items-center space-x-3">
                        <i class="fa-solid fa-location-dot text-[#4CAF50] text-base"></i>
                        <span>Colombo, Sri Lanka</span>
                    </div>
                </div>
                <div class="flex items-center space-x-3 pt-4">
                    <a href="#" class="w-8 h-8 rounded-lg bg-slate-800 hover:bg-[#2E7D32] text-white flex items-center justify-center transition"><i class="fa-brands fa-facebook-f text-sm"></i></a>
                    <a href="#" class="w-8 h-8 rounded-lg bg-slate-800 hover:bg-[#2E7D32] text-white flex items-center justify-center transition"><i class="fa-brands fa-twitter text-sm"></i></a>
                    <a href="#" class="w-8 h-8 rounded-lg bg-slate-800 hover:bg-[#2E7D32] text-white flex items-center justify-center transition"><i class="fa-brands fa-instagram text-sm"></i></a>
                </div>
            </div>

            <!-- Form card (7 cols) -->
            <div class="lg:col-span-7 p-8 md:p-12 space-y-6">
                <h4 class="text-lg font-bold text-slate-800">Send Us a Message</h4>
                <form onsubmit="event.preventDefault(); alert('Inquiry submitted successfully!');" class="space-y-4">
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        <div class="space-y-1">
                            <label class="block text-[10px] font-bold text-slate-400 uppercase tracking-wider">Your Name</label>
                            <input type="text" required placeholder="John Doe" class="w-full bg-slate-50 border border-slate-200 text-xs px-4 py-3 rounded-xl focus:outline-none focus:border-[#2E7D32] focus:bg-white transition text-slate-800 font-semibold">
                        </div>
                        <div class="space-y-1">
                            <label class="block text-[10px] font-bold text-slate-400 uppercase tracking-wider">Email Address</label>
                            <input type="email" required placeholder="john@example.com" class="w-full bg-slate-50 border border-slate-200 text-xs px-4 py-3 rounded-xl focus:outline-none focus:border-[#2E7D32] focus:bg-white transition text-slate-800 font-semibold">
                        </div>
                    </div>
                    <div class="space-y-1">
                        <label class="block text-[10px] font-bold text-slate-400 uppercase tracking-wider">Message Description</label>
                        <textarea rows="4" required placeholder="How can we assist you?" class="w-full bg-slate-50 border border-slate-200 text-xs px-4 py-3 rounded-xl focus:outline-none focus:border-[#2E7D32] focus:bg-white transition text-slate-800 font-semibold resize-none"></textarea>
                    </div>
                    <button type="submit" class="w-full py-4 bg-gradient-to-r from-[#2E7D32] to-[#4CAF50] text-white rounded-xl font-bold text-xs hover:shadow-lg hover:shadow-emerald-600/20 transition duration-200">Submit Message Inquiries</button>
                </form>
            </div>
        </div>
    </section>

    <!-- Premium Footer Component -->
    <x-landing-footer />

</body>
</html>
