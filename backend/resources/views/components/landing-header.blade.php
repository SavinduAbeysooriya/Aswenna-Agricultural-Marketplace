<!-- resources/views/components/landing-header.blade.php -->
<header class="w-full bg-white/80 backdrop-blur-md border-b border-emerald-50 py-4 px-6 md:px-12 flex justify-between items-center sticky top-0 z-50 shadow-sm">
    <div class="flex items-center space-x-3">
        <div class="w-10 h-10 bg-[#2E7D32] rounded-xl flex items-center justify-center text-white shadow-md shadow-emerald-700/20">
            <i class="fa-solid fa-leaf text-lg"></i>
        </div>
        <div>
            <span class="text-2xl font-extrabold tracking-tight text-[#2E7D32] block leading-none">Aswenna</span>
            <span class="text-[10px] text-slate-500 font-medium tracking-wide">Direct Agri Marketplace Platform</span>
        </div>
    </div>
    
    <!-- Navigation Links -->
    <nav class="hidden md:flex items-center space-x-8 text-sm font-semibold text-slate-600">
        <a href="#hero" class="hover:text-[#2E7D32] transition">Home</a>
        <a href="#about" class="hover:text-[#2E7D32] transition">Direct Trade</a>
        <a href="#features" class="hover:text-[#2E7D32] transition">Features</a>
        <a href="#statistics" class="hover:text-[#2E7D32] transition">Platform Stats</a>
    </nav>

    <!-- Header Actions -->
    <div class="flex items-center space-x-4">
        <!-- Direct Admin Portal Button -->
        <a href="{{ route('admin.login') }}" class="px-5 py-2.5 rounded-xl bg-[#E8F5E9] hover:bg-[#C8E6C9] text-[#2E7D32] font-bold text-sm transition flex items-center space-x-2">
            <i class="fa-solid fa-shield-halved"></i>
            <span>Admin Console</span>
        </a>
    </div>
</header>
