<!DOCTYPE html>
<html lang="en" class="scroll-smooth">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Aswenna - Sri Lanka's Premium Agri Marketplace Platform</title>
    <!-- Tailwind CSS -->
    <script src="https://cdn.tailwindcss.com"></script>
    <!-- Google Fonts: Inter -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
    <!-- FontAwesome icons -->
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
                    }
                }
            }
        }
    </script>
    <style>
        .leaf-glow {
            box-shadow: 0 20px 40px -15px rgba(46, 125, 50, 0.25);
        }
        .organic-blur {
            background: radial-gradient(circle, rgba(232,245,233,0.6) 0%, rgba(255,255,255,0) 70%);
        }
    </style>
</head>
<body class="min-h-screen bg-slate-50 text-slate-800 antialiased overflow-x-hidden">

    <!-- Landing Header Component -->
    <x-landing-header />

    <!-- Hero Section -->
    <section id="hero" class="relative py-20 lg:py-32 px-6 md:px-12 max-w-7xl mx-auto overflow-hidden">
        <!-- Background Blurs -->
        <div class="absolute -top-40 -left-40 w-96 h-96 organic-blur pointer-events-none"></div>
        <div class="absolute top-20 -right-40 w-96 h-96 organic-blur pointer-events-none"></div>

        <div class="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center relative z-10">
            <!-- Hero text content (7 cols) -->
            <div class="lg:col-span-7 space-y-8 text-center lg:text-left">
                <div class="inline-flex items-center space-x-2 px-3.5 py-1.5 rounded-full bg-emerald-100 text-agri-dark font-bold text-xs uppercase tracking-wider">
                    <i class="fa-solid fa-circle-check animate-pulse"></i>
                    <span>Direct Trading Ecosystem</span>
                </div>
                
                <h1 class="text-4xl md:text-6xl font-extrabold tracking-tight text-slate-900 leading-tight">
                    Bridging the Gap Between <span class="text-agri-deep">Sri Lankan Farmers</span> & Buyers
                </h1>
                
                <p class="text-lg text-slate-500 max-w-2xl mx-auto lg:mx-0 leading-relaxed font-medium">
                    Aswenna is a premium, secure direct-to-market platform connecting growers, commercial buyers, retail sellers, and delivery partners across Sri Lanka. Transparent bidding, verified yields, and automated routes.
                </p>

                <div class="flex flex-col sm:flex-row justify-center lg:justify-start items-center gap-4">
                    <a href="{{ route('admin.login') }}" class="w-full sm:w-auto px-8 py-4 bg-gradient-to-r from-agri-deep to-agri-fresh text-white rounded-2xl font-bold hover:shadow-xl hover:shadow-emerald-600/20 active:scale-[0.98] transition flex items-center justify-center space-x-3">
                        <i class="fa-solid fa-shield-halved text-lg"></i>
                        <span>Access Administrator Portal</span>
                    </a>
                    <a href="#features" class="w-full sm:w-auto px-8 py-4 bg-white border border-slate-200 text-slate-700 rounded-2xl font-bold hover:bg-slate-50 transition flex items-center justify-center space-x-2">
                        <span>Learn More</span>
                        <i class="fa-solid fa-arrow-down text-sm"></i>
                    </a>
                </div>

                <!-- Farmer Trust tags -->
                <div class="pt-6 border-t border-slate-200 max-w-lg mx-auto lg:mx-0 flex justify-between items-center text-xs font-semibold text-slate-400">
                    <span class="flex items-center"><i class="fa-solid fa-user-check text-agri-fresh mr-1.5 text-base"></i> Verified Growers</span>
                    <span class="flex items-center"><i class="fa-solid fa-shield text-agri-fresh mr-1.5 text-base"></i> Secured Escrow</span>
                    <span class="flex items-center"><i class="fa-solid fa-map-location-dot text-agri-fresh mr-1.5 text-base"></i> Islandwide Routes</span>
                </div>
            </div>

            <!-- Graphic illustration column (5 cols) -->
            <div class="lg:col-span-5 flex justify-center">
                <div class="relative w-full max-w-[380px] aspect-square bg-white border border-emerald-50 rounded-[44px] shadow-2xl p-8 leaf-glow flex items-center justify-center">
                    <!-- Background shapes -->
                    <div class="absolute -top-4 -left-4 w-12 h-12 bg-emerald-100 text-agri-deep rounded-full flex items-center justify-center shadow-md">
                        <i class="fa-solid fa-seedling text-lg"></i>
                    </div>
                    <div class="absolute -bottom-4 -right-4 w-16 h-16 bg-amber-50 text-agri-gold rounded-full flex items-center justify-center shadow-md">
                        <i class="fa-solid fa-wheat-awn text-xl animate-pulse"></i>
                    </div>
                    <!-- Central graphic -->
                    <div class="flex flex-col items-center justify-center space-y-4">
                        <i class="fa-solid fa-tractor text-[120px] text-agri-deep"></i>
                        <span class="text-xs font-bold text-slate-400 uppercase tracking-widest">Aswenna Platform Graphic</span>
                        <div class="flex space-x-2">
                            <span class="w-2.5 h-2.5 bg-agri-fresh rounded-full animate-bounce"></span>
                            <span class="w-2.5 h-2.5 bg-agri-fresh rounded-full animate-bounce [animation-delay:0.2s]"></span>
                            <span class="w-2.5 h-2.5 bg-agri-fresh rounded-full animate-bounce [animation-delay:0.4s]"></span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Platform Stats / Counters -->
    <section id="statistics" class="bg-white border-y border-slate-100 py-16 px-6 md:px-12 relative overflow-hidden">
        <div class="max-w-7xl mx-auto grid grid-cols-2 md:grid-cols-4 gap-8 text-center relative z-10">
            <div class="space-y-2">
                <h3 class="text-3xl md:text-5xl font-extrabold text-slate-800">1,240+</h3>
                <span class="text-xs font-bold text-slate-400 uppercase tracking-widest block">Active Sri Lankan Farmers</span>
            </div>
            <div class="space-y-2">
                <h3 class="text-3xl md:text-5xl font-extrabold text-agri-deep">LKR 2.4M</h3>
                <span class="text-xs font-bold text-slate-400 uppercase tracking-widest block">Market Trade Volume</span>
            </div>
            <div class="space-y-2">
                <h3 class="text-3xl md:text-5xl font-extrabold text-slate-800">890+</h3>
                <span class="text-xs font-bold text-slate-400 uppercase tracking-widest block">Logistics Dispatches</span>
            </div>
            <div class="space-y-2">
                <h3 class="text-3xl md:text-5xl font-extrabold text-agri-deep">100%</h3>
                <span class="text-xs font-bold text-slate-400 uppercase tracking-widest block">Escrow Guard Guarantee</span>
            </div>
        </div>
    </section>

    <!-- App / Web Splitting Explanation -->
    <section id="about" class="py-20 px-6 md:px-12 max-w-7xl mx-auto">
        <div class="text-center max-w-2xl mx-auto mb-16 space-y-4">
            <h2 class="text-3xl md:text-4xl font-extrabold text-slate-900 tracking-tight">One Ecosystem, Dual Access Portals</h2>
            <p class="text-sm text-slate-500 font-medium leading-relaxed">
                To maximize usability, our direct trading marketplace operates through specialized frontends optimized for specific user categories.
            </p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-8 items-stretch">
            <!-- Mobile App Box (Farmers & Trades) -->
            <div class="bg-white rounded-3xl p-8 border border-slate-100 shadow-sm flex flex-col justify-between hover:shadow-md transition">
                <div class="space-y-6">
                    <div class="w-12 h-12 bg-emerald-50 text-agri-deep rounded-2xl flex items-center justify-center text-xl shadow-inner">
                        <i class="fa-solid fa-mobile-screen-button"></i>
                    </div>
                    <div class="space-y-2">
                        <h3 class="text-xl font-bold text-slate-800">Standard Aswenna Mobile App</h3>
                        <p class="text-sm text-slate-500 leading-relaxed font-medium">
                            Tailored for mobile-first marketplace participants. A lightweight, beautiful application enabling day-to-day agricultural trade operations anywhere.
                        </p>
                    </div>
                    <ul class="space-y-2 text-xs font-bold text-slate-600">
                        <li class="flex items-center space-x-2"><i class="fa-solid fa-circle-check text-agri-fresh"></i> <span>Farmers (Sell Crops & Track Bids)</span></li>
                        <li class="flex items-center space-x-2"><i class="fa-solid fa-circle-check text-agri-fresh"></i> <span>Bulk Buyers (Purchase harvests)</span></li>
                        <li class="flex items-center space-x-2"><i class="fa-solid fa-circle-check text-agri-fresh"></i> <span>Retail Sellers (Manage store listings)</span></li>
                        <li class="flex items-center space-x-2"><i class="fa-solid fa-circle-check text-agri-fresh"></i> <span>Delivery Partners (Dispatch routing)</span></li>
                        <li class="flex items-center space-x-2"><i class="fa-solid fa-circle-check text-agri-fresh"></i> <span>Customers (Instant fresh grocery checkout)</span></li>
                    </ul>
                </div>
                <div class="pt-8 text-xs font-semibold text-slate-400 flex items-center space-x-1.5 border-t border-slate-100 mt-6">
                    <i class="fa-brands fa-google-play"></i>
                    <span>Google Play Store</span>
                    <span class="text-slate-300">•</span>
                    <i class="fa-brands fa-apple"></i>
                    <span>Apple App Store</span>
                </div>
            </div>

            <!-- Web Admin Portal Box (Admin Only) -->
            <div class="bg-gradient-to-tr from-slate-900 to-slate-950 text-slate-350 rounded-3xl p-8 border border-slate-800 shadow-xl flex flex-col justify-between">
                <div class="space-y-6">
                    <div class="w-12 h-12 bg-[#2E7D32] text-white rounded-2xl flex items-center justify-center text-xl shadow-inner shadow-black/35">
                        <i class="fa-solid fa-shield-halved"></i>
                    </div>
                    <div class="space-y-2">
                        <h3 class="text-xl font-bold text-white">Central Operations Web Console</h3>
                        <p class="text-sm text-slate-400 leading-relaxed font-medium">
                            Reserved exclusively for system administrators. Because administrative oversight involves intensive data tables, organic verifications, commission treasury checks, and document auditing, it is built exclusively as a high-fidelity web dashboard.
                        </p>
                    </div>
                    <ul class="space-y-2 text-xs font-bold text-slate-300">
                        <li class="flex items-center space-x-2"><i class="fa-solid fa-shield-check text-[#4CAF50]"></i> <span>Plantation GAP & Organic Certifications Audit</span></li>
                        <li class="flex items-center space-x-2"><i class="fa-solid fa-shield-check text-[#4CAF50]"></i> <span>Escrow Treasury Withdraw Requests Dispatch</span></li>
                        <li class="flex items-center space-x-2"><i class="fa-solid fa-shield-check text-[#4CAF50]"></i> <span>Platform-wide User Account Audit & Governance</span></li>
                        <li class="flex items-center space-x-2"><i class="fa-solid fa-shield-check text-[#4CAF50]"></i> <span>Weekly Commissions Volume analytics</span></li>
                    </ul>
                </div>
                <div class="pt-6 border-t border-slate-800 mt-6">
                    <a href="{{ route('admin.login') }}" class="w-full py-3 bg-[#2E7D32] hover:bg-emerald-700 text-white rounded-xl font-bold text-xs flex items-center justify-center space-x-2 transition shadow-md shadow-black/30">
                        <i class="fa-solid fa-right-to-bracket"></i>
                        <span>Access Central Web Console</span>
                    </a>
                </div>
            </div>
        </div>
    </section>

    <!-- Landing Footer Component -->
    <x-landing-footer />

</body>
</html>
