<!-- resources/views/components/admin-header.blade.php -->
<header class="bg-white/80 backdrop-blur-xl border-b border-slate-200/60 px-4 sm:px-6 py-3.5 flex justify-between items-center sticky top-0 z-50 shadow-sm transition-all duration-300">
    <div class="flex items-center space-x-3 sm:space-x-4">
        <!-- Mobile Sidebar Toggle -->
        <button id="mobile-sidebar-toggle" class="md:hidden p-2 -ml-2 rounded-xl text-slate-500 hover:bg-slate-100 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 transition-colors" aria-label="Toggle Sidebar">
            <i class="fa-solid fa-bars text-lg"></i>
        </button>
    </div>
    
    <!-- Admin actions & details -->
    <div class="flex items-center space-x-3 sm:space-x-5">
        <!-- Live status -->
        <span class="hidden lg:inline-flex items-center px-3 py-1.5 rounded-full text-[11px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-100 shadow-sm">
            <span class="relative flex h-2 w-2 mr-2">
                <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                <span class="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
            </span>
            Live Sync
        </span>
        
        <!-- Profile badge -->
        <div class="flex items-center space-x-3 bg-slate-50 hover:bg-slate-100 transition-colors p-1.5 pr-4 rounded-full border border-slate-200/60 cursor-pointer shadow-sm">
            <div class="w-8 h-8 rounded-full bg-gradient-to-r from-slate-800 to-slate-900 flex items-center justify-center font-bold text-white shadow-inner">
                A
            </div>
            <div class="text-left hidden md:block">
                <span class="text-[11px] font-bold block text-slate-800 leading-tight">Super Admin</span>
                <span class="text-[9px] block text-emerald-600 font-bold uppercase tracking-wider">Lvl 1 Security</span>
            </div>
            <i class="fa-solid fa-chevron-down text-slate-400 text-xs hidden md:block ml-2"></i>
        </div>
    </div>
</header>
