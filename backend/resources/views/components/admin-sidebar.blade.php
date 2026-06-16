<!-- resources/views/components/admin-sidebar.blade.php -->
<aside id="admin-sidebar" class="w-64 bg-white border-r border-slate-200/60 flex flex-col justify-between h-screen fixed md:sticky top-0 z-40 shadow-[4px_0_24px_rgba(0,0,0,0.02)] transition-transform duration-300 ease-in-out -translate-x-full md:translate-x-0 shrink-0">
    <div class="space-y-6 p-5 overflow-y-auto h-full">
        <!-- Logo and Title Block -->
        <div class="flex items-center space-x-3 pb-6 border-b border-slate-100">
            <div class="w-10 h-10 rounded-xl bg-white flex items-center justify-center shadow-md shadow-emerald-500/10 border border-slate-100 overflow-hidden shrink-0">
                <img src="{{ asset('images/logo.png') }}" alt="Aswenna Logo" class="w-full h-full object-contain p-1">
            </div>
            <div>
                <h2 class="text-base font-extrabold tracking-tight text-slate-800">Aswenna <span class="text-emerald-700">Admin</span></h2>
                <p class="text-[9px] text-slate-500 font-medium tracking-wide leading-tight">Operational oversight & approvals</p>
            </div>
        </div>

        <!-- Main stats oversight section -->
        <div class="space-y-0.5">
            <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest px-3 block mb-2">Market Oversight</span>
            
            <a href="{{ route('admin.dashboard') }}" class="group flex items-center space-x-3 px-3 py-2 rounded-xl {{ request()->routeIs('admin.dashboard') ? 'bg-emerald-50 text-emerald-700 font-bold shadow-sm' : 'hover:bg-slate-50 text-slate-500 hover:text-slate-800 font-semibold' }} text-xs transition-all">
                <div class="w-7 h-7 rounded-lg bg-emerald-100 flex items-center justify-center text-emerald-600 shadow-inner group-hover:scale-105 transition-transform">
                    <i class="fa-solid fa-chart-pie text-xs"></i>
                </div>
                <span>Overview Dashboard</span>
            </a>
            
            <a href="{{ route('admin.users.roles') }}" class="group flex items-center space-x-3 px-3 py-2 rounded-xl {{ request()->routeIs('admin.users*') ? 'bg-emerald-50 text-emerald-700 font-bold shadow-sm' : 'hover:bg-slate-50 text-slate-500 hover:text-slate-800 font-semibold' }} text-xs transition-all">
                <div class="w-7 h-7 rounded-lg {{ request()->routeIs('admin.users*') ? 'bg-emerald-100 text-emerald-600 shadow-inner' : 'bg-transparent group-hover:bg-white text-slate-400 group-hover:text-emerald-600 group-hover:shadow-sm' }} flex items-center justify-center transition-all">
                    <i class="fa-solid fa-users text-xs"></i>
                </div>
                <span>User Management</span>
            </a>
            
            <a href="{{ route('admin.crops') }}" class="group flex items-center space-x-3 px-3 py-2 rounded-xl {{ request()->routeIs('admin.crops*') ? 'bg-emerald-50 text-emerald-700 font-bold shadow-sm' : 'hover:bg-slate-50 text-slate-500 hover:text-slate-800 font-semibold' }} text-xs transition-all">
                <div class="w-7 h-7 rounded-lg {{ request()->routeIs('admin.crops*') ? 'bg-emerald-100 text-emerald-600 shadow-inner' : 'bg-transparent group-hover:bg-white text-slate-400 group-hover:text-emerald-600 group-hover:shadow-sm' }} flex items-center justify-center transition-all">
                    <i class="fa-solid fa-seedling text-xs"></i>
                </div>
                <span>Crop Varieties</span>
                @if (($pendingCropCount ?? 0) > 0)
                    <span class="ml-auto min-w-5 h-5 px-1 bg-amber-100 text-amber-700 font-bold text-[10px] rounded-full flex items-center justify-center shadow-inner">{{ $pendingCropCount }}</span>
                @endif
            </a>

            <a href="{{ route('admin.crop-rates') }}" class="group flex items-center space-x-3 px-3 py-2 rounded-xl {{ request()->routeIs('admin.crop-rates*') ? 'bg-emerald-50 text-emerald-700 font-bold shadow-sm' : 'hover:bg-slate-50 text-slate-500 hover:text-slate-800 font-semibold' }} text-xs transition-all">
                <div class="w-7 h-7 rounded-lg {{ request()->routeIs('admin.crop-rates*') ? 'bg-emerald-100 text-emerald-600 shadow-inner' : 'bg-transparent group-hover:bg-white text-slate-400 group-hover:text-emerald-600 group-hover:shadow-sm' }} flex items-center justify-center transition-all">
                    <i class="fa-solid fa-arrow-trend-up text-xs"></i>
                </div>
                <span>Crop Rates Oversight</span>
            </a>

            <a href="{{ route('admin.crop-growth-stages') }}" class="group flex items-center space-x-3 px-3 py-2 rounded-xl {{ request()->routeIs('admin.crop-growth-stages*') ? 'bg-emerald-50 text-emerald-700 font-bold shadow-sm' : 'hover:bg-slate-50 text-slate-500 hover:text-slate-800 font-semibold' }} text-xs transition-all">
                <div class="w-7 h-7 rounded-lg {{ request()->routeIs('admin.crop-growth-stages*') ? 'bg-emerald-100 text-emerald-600 shadow-inner' : 'bg-transparent group-hover:bg-white text-slate-400 group-hover:text-emerald-600 group-hover:shadow-sm' }} flex items-center justify-center transition-all">
                    <i class="fa-solid fa-bars-progress text-xs"></i>
                </div>
                <span>Growth Stages</span>
            </a>

            <a href="{{ route('admin.offer-campaigns') }}" class="group flex items-center space-x-3 px-3 py-2 rounded-xl {{ request()->routeIs('admin.offer-campaigns*') ? 'bg-emerald-50 text-emerald-700 font-bold shadow-sm' : 'hover:bg-slate-50 text-slate-500 hover:text-slate-800 font-semibold' }} text-xs transition-all">
                <div class="w-7 h-7 rounded-lg {{ request()->routeIs('admin.offer-campaigns*') ? 'bg-emerald-100 text-emerald-600 shadow-inner' : 'bg-transparent group-hover:bg-white text-slate-400 group-hover:text-emerald-600 group-hover:shadow-sm' }} flex items-center justify-center transition-all">
                    <i class="fa-solid fa-gift text-xs"></i>
                </div>
                <span>Offer Campaigns</span>
            </a>

            <a href="{{ route('admin.user-offer-progress') }}" class="group flex items-center space-x-3 px-3 py-2 rounded-xl {{ request()->routeIs('admin.user-offer-progress*') ? 'bg-emerald-50 text-emerald-700 font-bold shadow-sm' : 'hover:bg-slate-50 text-slate-500 hover:text-slate-800 font-semibold' }} text-xs transition-all">
                <div class="w-7 h-7 rounded-lg {{ request()->routeIs('admin.user-offer-progress*') ? 'bg-emerald-100 text-emerald-600 shadow-inner' : 'bg-transparent group-hover:bg-white text-slate-400 group-hover:text-emerald-600 group-hover:shadow-sm' }} flex items-center justify-center transition-all">
                    <i class="fa-solid fa-spinner text-xs"></i>
                </div>
                <span>User Offer Progress</span>
            </a>
        </div>

        <!-- Finance Oversight -->
        <div class="space-y-0.5 pt-2">
            <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest px-3 block mb-2">Financial Treasury</span>
            
            <a href="{{ route('admin.escrow-commissions') }}" class="group flex items-center space-x-3 px-3 py-2 rounded-xl {{ request()->routeIs('admin.escrow-commissions*') ? 'bg-emerald-50 text-emerald-700 font-bold shadow-sm' : 'hover:bg-slate-50 text-slate-500 hover:text-slate-800 font-semibold' }} text-xs transition-all">
                <div class="w-7 h-7 rounded-lg {{ request()->routeIs('admin.escrow-commissions*') ? 'bg-emerald-100 text-emerald-600 shadow-inner' : 'bg-transparent group-hover:bg-white text-slate-400 group-hover:text-emerald-600 group-hover:shadow-sm' }} flex items-center justify-center transition-all">
                    <i class="fa-solid fa-wallet text-xs"></i>
                </div>
                <span>Escrow & Commissions</span>
            </a>
            
            <a href="{{ route('admin.withdrawals') }}" class="group flex items-center space-x-3 px-3 py-2 rounded-xl {{ request()->routeIs('admin.withdrawals*') ? 'bg-emerald-50 text-emerald-700 font-bold shadow-sm' : 'hover:bg-slate-50 text-slate-500 hover:text-slate-800 font-semibold' }} text-xs transition-all">
                <div class="w-7 h-7 rounded-lg {{ request()->routeIs('admin.withdrawals*') ? 'bg-emerald-100 text-emerald-600 shadow-inner' : 'bg-transparent group-hover:bg-white text-slate-400 group-hover:text-emerald-600 group-hover:shadow-sm' }} flex items-center justify-center transition-all">
                    <i class="fa-solid fa-landmark text-xs"></i>
                </div>
                <span>Withdraw Requests</span>
                <span class="ml-auto px-2 py-0.5 bg-emerald-100 text-emerald-700 font-bold text-[9px] rounded-lg">Active</span>
            </a>
        </div>

       
    </div>

    <!-- Sidebar footer Actions (Logout form) -->
    <div class="p-3 border-t border-slate-100 bg-slate-50/50">
        <form id="admin-logout-form" action="{{ route('admin.logout') }}" method="POST">
            @csrf
            <button type="button" onclick="confirmAdminLogout()" class="group w-full flex items-center space-x-3 px-3 py-2 rounded-xl hover:bg-rose-50 text-slate-500 hover:text-rose-600 font-bold text-xs transition-all border border-transparent hover:border-rose-100">
                <div class="w-7 h-7 rounded-lg bg-slate-100 group-hover:bg-rose-100 flex items-center justify-center text-slate-400 group-hover:text-rose-500 transition-colors">
                    <i class="fa-solid fa-right-from-bracket text-xs"></i>
                </div>
                <span>Logout Console</span>
            </button>
        </form>
    </div>

    <script>
        function confirmAdminLogout() {
            Swal.fire({
                title: 'Confirm Logout',
                text: "Are you sure you want to securely logout from the Aswenna Administration Console?",
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#e11d48',
                cancelButtonColor: '#94a3b8',
                confirmButtonText: 'Yes, logout!',
                customClass: {
                    popup: 'rounded-3xl shadow-2xl border border-slate-100',
                    confirmButton: 'rounded-xl font-bold shadow-md shadow-rose-500/20 px-6 py-2.5',
                    cancelButton: 'rounded-xl font-bold px-6 py-2.5'
                }
            }).then((result) => {
                if (result.isConfirmed) {
                    document.getElementById('admin-logout-form').submit();
                }
            });
        }
    </script>
</aside>
