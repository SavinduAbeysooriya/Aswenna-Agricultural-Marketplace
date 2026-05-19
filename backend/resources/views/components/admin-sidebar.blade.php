<!-- resources/views/components/admin-sidebar.blade.php -->
<aside class="w-64 bg-slate-900 text-slate-300 p-5 flex flex-col justify-between min-h-[calc(100vh-68px)] sticky top-[68px] z-30 shadow-lg border-r border-slate-800">
    <div class="space-y-8">
        <!-- Main stats oversight section -->
        <div class="space-y-2">
            <span class="text-[10px] font-bold text-slate-500 uppercase tracking-widest px-3 block">Market Oversight</span>
            
            <a href="#" class="flex items-center space-x-3 px-3 py-3 rounded-xl bg-[#2E7D32] text-white font-bold text-sm transition shadow-md shadow-emerald-950/20">
                <i class="fa-solid fa-chart-pie text-base w-5"></i>
                <span>Overview Dashboard</span>
            </a>
            
            <a href="#" class="flex items-center space-x-3 px-3 py-3 rounded-xl hover:bg-slate-800 text-slate-400 hover:text-white font-semibold text-sm transition">
                <i class="fa-solid fa-users text-base w-5"></i>
                <span>User Management</span>
            </a>
            
            <a href="#" class="flex items-center space-x-3 px-3 py-3 rounded-xl hover:bg-slate-800 text-slate-400 hover:text-white font-semibold text-sm transition">
                <i class="fa-solid fa-circle-check text-base w-5"></i>
                <span>Plantation Approvals</span>
                <span class="ml-auto w-5 h-5 bg-amber-500 text-slate-950 font-bold text-[10px] rounded-full flex items-center justify-center animate-pulse">4</span>
            </a>
        </div>

        <!-- Finance Oversight -->
        <div class="space-y-2">
            <span class="text-[10px] font-bold text-slate-500 uppercase tracking-widest px-3 block">Financial Treasury</span>
            
            <a href="#" class="flex items-center space-x-3 px-3 py-3 rounded-xl hover:bg-slate-800 text-slate-400 hover:text-white font-semibold text-sm transition">
                <i class="fa-solid fa-wallet text-base w-5"></i>
                <span>Escrow & Commissions</span>
            </a>
            
            <a href="#" class="flex items-center space-x-3 px-3 py-3 rounded-xl hover:bg-slate-800 text-slate-400 hover:text-white font-semibold text-sm transition">
                <i class="fa-solid fa-landmark text-base w-5"></i>
                <span>Withdraw Requests</span>
                <span class="ml-auto px-2 py-0.5 bg-emerald-500/20 text-[#4CAF50] font-bold text-[9px] rounded-lg">Active</span>
            </a>
        </div>

        <!-- Audit & Logs -->
        <div class="space-y-2">
            <span class="text-[10px] font-bold text-slate-500 uppercase tracking-widest px-3 block">Audit Trails</span>
            
            <a href="#" class="flex items-center space-x-3 px-3 py-3 rounded-xl hover:bg-slate-800 text-slate-400 hover:text-white font-semibold text-sm transition">
                <i class="fa-solid fa-clock-rotate-left text-base w-5"></i>
                <span>Platform Activity Logs</span>
            </a>
        </div>
    </div>

    <!-- Sidebar footer Actions (Logout form) -->
    <div class="pt-6 border-t border-slate-850">
        <form action="{{ route('admin.logout') }}" method="POST" onsubmit="return confirm('Confirm secure logout from the Aswenna Administration Console?');">
            @csrf
            <button type="submit" class="w-full flex items-center space-x-3 px-3 py-3 rounded-xl hover:bg-rose-950/20 text-rose-400 hover:text-rose-300 font-bold text-sm transition border border-transparent hover:border-rose-900/30">
                <i class="fa-solid fa-right-from-bracket text-base w-5"></i>
                <span>Logout Console</span>
            </button>
        </form>
    </div>
</aside>
