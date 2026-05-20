<!-- resources/views/components/landing-header.blade.php -->
<header x-data="{ mobileMenuOpen: false, scrolled: false }" 
        @scroll.window="scrolled = (window.pageYOffset > 10)"
        :class="scrolled ? 'bg-white/80 backdrop-blur-xl border border-emerald-100/50 shadow-xl shadow-emerald-900/5 py-3 mt-3' : 'bg-white/50 backdrop-blur-md border border-white/40 shadow-lg py-4 mt-5'"
        class="w-[92%] md:w-[95%] max-w-7xl mx-auto flex justify-between items-center sticky top-4 z-50 rounded-[24px] md:rounded-[32px] px-6 md:px-10 transition-all duration-300">
    
    <!-- Branding logo -->
    <a href="/" class="flex items-center space-x-3 group">
        <div class="relative">
            <img src="{{ asset('images/logo.png') }}" alt="Aswenna Logo" class="h-10 w-10 object-contain rounded-2xl shadow-sm border border-white/50 group-hover:scale-105 transition-transform duration-300 bg-white/40">
            <!-- Tiny pulsing green status ring -->
            <span class="absolute -top-1 -right-1 flex h-3 w-3">
                <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                <span class="relative inline-flex rounded-full h-3 w-3 bg-[#4CAF50]"></span>
            </span>
        </div>
        <div>
            <span class="text-xl md:text-2xl font-black tracking-tight text-[#2E7D32] block leading-none font-poppins">Aswenna</span>
            <span class="text-[9px] text-slate-500 font-bold tracking-wider uppercase block mt-0.5">Smart Agri Platform</span>
        </div>
    </a>
    
    <!-- Navigation Links (Desktop) -->
    <nav class="hidden lg:flex items-center space-x-8 text-xs md:text-sm font-bold text-slate-650">
        <a href="{{ route('landing') }}" class="hover:text-[#2E7D32] transition">Home</a>
        <a href="{{ request()->routeIs('landing') ? '#features' : route('landing') . '#features' }}" class="hover:text-[#2E7D32] transition">Features</a>
        <a href="{{ request()->routeIs('landing') ? '#roles' : route('landing') . '#roles' }}" class="hover:text-[#2E7D32] transition">Ecosystem</a>
        <a href="{{ request()->routeIs('landing') ? '#app-showcase' : route('landing') . '#app-showcase' }}" class="hover:text-[#2E7D32] transition">App Previews</a>
        <a href="{{ request()->routeIs('landing') ? '#faq' : route('landing') . '#faq' }}" class="hover:text-[#2E7D32] transition">About</a>
        <a href="{{ request()->routeIs('landing') ? '#contact' : route('landing') . '#contact' }}" class="hover:text-[#2E7D32] transition">Contact</a>
    </nav>
    
    <!-- Header Actions (Desktop) -->
    <div class="hidden lg:flex items-center space-x-3">
        <!-- Direct Admin Portal Button -->
        <a href="{{ route('admin.login') }}" class="px-6 py-2.5 rounded-xl bg-white/60 hover:bg-[#E8F5E9] text-[#2E7D32] border border-white/50 hover:border-emerald-100 font-bold text-xs transition flex items-center space-x-2">
            <i class="fa-solid fa-shield-halved"></i>
            <span>Admin Console</span>
        </a>
        <a href="#download" class="px-6 py-2.5 rounded-xl bg-gradient-to-r from-[#2E7D32] to-[#4CAF50] hover:shadow-lg hover:shadow-emerald-600/20 text-white font-bold text-xs transition-all duration-200">
            Get Started
        </a>
    </div>

    <!-- Hamburger menu trigger (Mobile) -->
    <button @click="mobileMenuOpen = !mobileMenuOpen" class="lg:hidden p-2 text-slate-600 focus:outline-none focus:text-[#2E7D32] transition">
        <i :class="mobileMenuOpen ? 'fa-solid fa-xmark text-xl' : 'fa-solid fa-bars text-xl'"></i>
    </button>

    <!-- Mobile Navigation Drawer (Floating Curved Glassmorphism Card too!) -->
    <div x-show="mobileMenuOpen" 
         x-transition:enter="transition ease-out duration-200"
         x-transition:enter-start="opacity-0 -translate-y-4 scale-95"
         x-transition:enter-end="opacity-100 translate-y-0 scale-100"
         x-transition:leave="transition ease-in duration-150"
         x-transition:leave-start="opacity-100 translate-y-0 scale-100"
         x-transition:leave-end="opacity-0 -translate-y-4 scale-95"
         class="absolute top-[110%] left-0 w-full bg-white/95 backdrop-blur-xl border border-white/60 shadow-2xl rounded-3xl py-6 px-8 flex flex-col space-y-4 z-40 lg:hidden">
        <a href="{{ route('landing') }}" @click="mobileMenuOpen = false" class="text-slate-700 hover:text-[#2E7D32] font-bold text-sm py-1 border-b border-slate-50">Home</a>
        <a href="{{ request()->routeIs('landing') ? '#features' : route('landing') . '#features' }}" @click="mobileMenuOpen = false" class="text-slate-700 hover:text-[#2E7D32] font-bold text-sm py-1 border-b border-slate-50">Features</a>
        <a href="{{ request()->routeIs('landing') ? '#roles' : route('landing') . '#roles' }}" @click="mobileMenuOpen = false" class="text-slate-700 hover:text-[#2E7D32] font-bold text-sm py-1 border-b border-slate-50">Marketplace Ecosystem</a>
        <a href="{{ request()->routeIs('landing') ? '#app-showcase' : route('landing') . '#app-showcase' }}" @click="mobileMenuOpen = false" class="text-slate-700 hover:text-[#2E7D32] font-bold text-sm py-1 border-b border-slate-50">App Preview</a>
        <a href="{{ request()->routeIs('landing') ? '#faq' : route('landing') . '#faq' }}" @click="mobileMenuOpen = false" class="text-slate-700 hover:text-[#2E7D32] font-bold text-sm py-1 border-b border-slate-50">About & FAQ</a>
        <a href="{{ request()->routeIs('landing') ? '#contact' : route('landing') . '#contact' }}" @click="mobileMenuOpen = false" class="text-slate-700 hover:text-[#2E7D32] font-bold text-sm py-1 border-b border-slate-50">Contact</a>
        
        <div class="pt-4 flex flex-col sm:flex-row gap-3">
            <a href="{{ route('admin.login') }}" @click="mobileMenuOpen = false" class="flex-1 text-center px-5 py-3 rounded-2xl bg-[#E8F5E9] text-[#2E7D32] font-bold text-xs flex items-center justify-center space-x-2">
                <i class="fa-solid fa-shield-halved"></i>
                <span>Admin Console</span>
            </a>
            <a href="#download" @click="mobileMenuOpen = false" class="flex-1 text-center px-6 py-3 rounded-2xl bg-gradient-to-r from-[#2E7D32] to-[#4CAF50] text-white font-bold text-xs">
                Get Started
            </a>
        </div>
    </div>
</header>
