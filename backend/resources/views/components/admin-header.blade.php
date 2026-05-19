<!-- resources/views/components/admin-header.blade.php -->
<header class="bg-[#2E7D32] px-6 py-4 flex justify-between items-center text-white sticky top-0 z-40 shadow-md">
    <div class="flex items-center space-x-3">
        <i class="fa-solid fa-shield-halved text-2xl text-emerald-300"></i>
        <div>
            <h2 class="text-lg font-bold tracking-tight">Aswenna Platform Administration Console</h2>
            <p class="text-xs text-emerald-100/90 font-medium">Operational oversight, transaction escrows & yield approvals</p>
        </div>
    </div>
    
    <!-- Admin actions & details -->
    <div class="flex items-center space-x-4">
        <!-- Live status -->
        <span class="hidden md:inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-emerald-800 text-emerald-200 border border-emerald-700/50">
            <span class="w-1.5 h-1.5 bg-emerald-400 rounded-full mr-2 animate-ping"></span>
            <span>Live Sync Active</span>
        </span>
        
        <!-- Profile badge -->
        <div class="flex items-center space-x-3 bg-emerald-900/40 p-1.5 pr-4 rounded-xl border border-emerald-700/30">
            <div class="w-8 h-8 rounded-lg bg-emerald-600 flex items-center justify-center font-bold text-white shadow-inner">
                A
            </div>
            <div class="text-left hidden md:block">
                <span class="text-xs font-bold block text-white">Super Administrator</span>
                <span class="text-[9px] block text-emerald-200 font-semibold uppercase tracking-wider">Level 1 Security</span>
            </div>
        </div>
    </div>
</header>
