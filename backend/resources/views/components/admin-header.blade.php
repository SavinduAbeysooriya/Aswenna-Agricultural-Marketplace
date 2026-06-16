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
        
        <!-- Profile badge with Dropdown -->
        <div class="relative" id="profile-dropdown-container">
            <div onclick="toggleProfileDropdown(event)" class="flex items-center space-x-3 bg-slate-50 hover:bg-slate-100 transition-colors p-1.5 pr-4 rounded-full border border-slate-200/60 cursor-pointer shadow-sm select-none">
                <div class="w-8 h-8 rounded-full bg-gradient-to-r from-slate-800 to-slate-900 flex items-center justify-center font-bold text-white shadow-inner overflow-hidden">
                    @if(auth()->check() && auth()->user()->profile_picture_path)
                        <img src="{{ asset('storage/' . auth()->user()->profile_picture_path) }}" alt="Avatar" class="w-full h-full object-cover">
                    @elseif(session('admin_session.profile_picture_path'))
                        <img src="{{ asset('storage/' . session('admin_session.profile_picture_path')) }}" alt="Avatar" class="w-full h-full object-cover">
                    @else
                        {{ substr(auth()->check() ? auth()->user()->full_name : session('admin_session.username', 'A'), 0, 1) }}
                    @endif
                </div>
                <div class="text-left hidden md:block">
                    <span class="text-[11px] font-bold block text-slate-800 leading-tight">
                        {{ auth()->check() ? auth()->user()->full_name : session('admin_session.username', 'Super Admin') }}
                    </span>
                    <span class="text-[9px] block text-emerald-600 font-bold uppercase tracking-wider">Lvl 1 Security</span>
                </div>
                <i class="fa-solid fa-chevron-down text-slate-400 text-xs hidden md:block ml-2"></i>
            </div>

            <!-- Dropdown Menu -->
            <div id="profile-dropdown-menu" class="hidden absolute right-0 mt-2.5 w-64 bg-white border border-slate-200/80 rounded-2xl shadow-xl z-50 py-2.5 transition-all duration-200 origin-top-right">
                <!-- User Info -->
                <div class="px-4 py-3 border-b border-slate-100 mb-2 flex items-center space-x-3">
                    <div class="w-10 h-10 rounded-full bg-slate-900 text-white flex items-center justify-center font-bold overflow-hidden shadow-sm">
                        @if(auth()->check() && auth()->user()->profile_picture_path)
                            <img src="{{ asset('storage/' . auth()->user()->profile_picture_path) }}" alt="Avatar" class="w-full h-full object-cover">
                        @elseif(session('admin_session.profile_picture_path'))
                            <img src="{{ asset('storage/' . session('admin_session.profile_picture_path')) }}" alt="Avatar" class="w-full h-full object-cover">
                        @else
                            {{ substr(auth()->check() ? auth()->user()->full_name : session('admin_session.username', 'A'), 0, 1) }}
                        @endif
                    </div>
                    <div>
                        <span class="text-xs font-bold text-slate-800 block leading-tight">
                            {{ auth()->check() ? auth()->user()->full_name : session('admin_session.username', 'Super Admin') }}
                        </span>
                        <span class="text-[9px] text-slate-500 block mt-0.5">
                            {{ auth()->check() ? auth()->user()->email : session('admin_session.email', 'admin@aswenna.lk') }}
                        </span>
                    </div>
                </div>
                <!-- Actions -->
                <a href="{{ route('admin.profile') }}" class="w-full text-left px-4 py-2 text-xs font-semibold text-slate-700 hover:bg-slate-50 hover:text-slate-950 transition-colors flex items-center space-x-2.5">
                    <i class="fa-solid fa-user-gear text-slate-400 text-sm w-4"></i>
                    <span>Manage My Profile</span>
                </a>
                <div class="border-t border-slate-100 my-2"></div>
                <form action="{{ route('admin.logout') }}" method="POST" id="logout-form" class="hidden">
                    @csrf
                </form>
                <button onclick="document.getElementById('logout-form').submit();" class="w-full text-left px-4 py-2 text-xs font-semibold text-rose-600 hover:bg-rose-50/50 hover:text-rose-700 transition-colors flex items-center space-x-2.5">
                    <i class="fa-solid fa-right-from-bracket text-rose-400 text-sm w-4"></i>
                    <span>Log Out Securely</span>
                </button>
            </div>
        </div>
    </div>

    <script>
        function toggleProfileDropdown(event) {
            event.stopPropagation();
            const menu = document.getElementById('profile-dropdown-menu');
            if (menu.classList.contains('hidden')) {
                menu.classList.remove('hidden');
                menu.classList.add('block');
            } else {
                menu.classList.remove('block');
                menu.classList.add('hidden');
            }
        }

        // Close dropdown when clicking outside
        document.addEventListener('click', function(event) {
            const container = document.getElementById('profile-dropdown-container');
            const menu = document.getElementById('profile-dropdown-menu');
            if (container && !container.contains(event.target)) {
                if (menu) {
                    menu.classList.remove('block');
                    menu.classList.add('hidden');
                }
            }
        });
    </script>
</header>
