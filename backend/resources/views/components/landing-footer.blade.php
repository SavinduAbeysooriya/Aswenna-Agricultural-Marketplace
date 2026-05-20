<!-- resources/views/components/landing-footer.blade.php -->
<footer id="footer" class="bg-slate-900 text-slate-400 py-16 px-6 md:px-12 relative mt-auto">
    <!-- Beautiful organic wave top border decoration -->
    <div class="absolute top-0 left-0 w-full overflow-hidden leading-none transform -translate-y-1 z-10">
        <svg viewBox="0 0 1200 120" preserveAspectRatio="none" class="relative block w-full h-8 text-slate-50 fill-current">
            <path d="M321.39,56.44c58-10.79,114.16-30.13,172-41.86,82.39-16.72,168.19-17.73,250.45-.39C823.78,31,906.67,72,985.66,92.83c70.05,18.48,146.53,26.09,214.34,3V0H0V27.35A600.21,600.21,0,0,0,321.39,56.44Z"></path>
        </svg>
    </div>

    <!-- Watermark container to safely clip overflow without clipping the top wave -->
    <div class="absolute inset-0 overflow-hidden pointer-events-none z-0">
        <!-- Leaf pattern background texture watermark -->
        <div class="absolute -bottom-16 -right-16 text-slate-800/20 pointer-events-none">
            <i class="fa-solid fa-leaf text-[240px]"></i>
        </div>
    </div>

    <div class="max-w-7xl mx-auto grid grid-cols-1 lg:grid-cols-4 gap-12 relative z-10 pt-4">
        <!-- Logo and info -->
        <div class="space-y-4">
            <div class="flex items-center space-x-3 text-white">
                <img src="{{ asset('images/logo.png') }}" alt="Aswenna Logo" class="h-10 w-10 object-contain rounded-xl shadow-sm border border-slate-800">
                <span class="text-2xl font-black tracking-tight">Aswenna</span>
            </div>
            <p class="text-xs leading-relaxed text-slate-500">
                Sri Lanka's premier direct farmer-to-buyer smart agricultural marketplace ecosystem. Bridging transparency, bidding, and dynamic freight logistics.
            </p>
            
            <!-- Newsletter Sign up -->
            <div class="pt-4 space-y-2">
                <h4 class="text-xs font-bold text-white uppercase tracking-wider">Marketplace Newsletter</h4>
                <form onsubmit="event.preventDefault(); alert('Subscribed successfully!');" class="flex gap-2">
                    <input type="email" required placeholder="Enter email" class="w-full bg-slate-800 border border-slate-700 text-xs px-3 py-2 rounded-lg text-slate-300 focus:outline-none focus:border-[#4CAF50]">
                    <button type="submit" class="px-3 bg-gradient-to-r from-[#2E7D32] to-[#4CAF50] text-white rounded-lg text-xs font-bold hover:shadow-lg hover:shadow-emerald-600/10 transition"><i class="fa-solid fa-paper-plane"></i></button>
                </form>
            </div>
        </div>

        <!-- Links 1 -->
        <div>
            <h4 class="text-sm font-bold text-white uppercase tracking-wider mb-4 border-l-2 border-[#4CAF50] pl-2">Marketplace Options</h4>
            <ul class="space-y-2 text-xs">
                <li><a href="#features" class="hover:text-[#4CAF50] transition">Direct Yield Bidding</a></li>
                <li><a href="#features" class="hover:text-[#4CAF50] transition">Bulk Buying Storefronts</a></li>
                <li><a href="#features" class="hover:text-[#4CAF50] transition">Retailer Fresh Groceries</a></li>
                <li><a href="#features" class="hover:text-[#4CAF50] transition">Crop Verification</a></li>
            </ul>
        </div>

        <!-- Links 2 -->
        <div>
            <h4 class="text-sm font-bold text-white uppercase tracking-wider mb-4 border-l-2 border-[#4CAF50] pl-2">Logistics & Payouts</h4>
            <ul class="space-y-2 text-xs">
                <li><a href="#features" class="hover:text-[#4CAF50] transition">Smart Dispatch Engine</a></li>
                <li><a href="#features" class="hover:text-[#4CAF50] transition">Integrated Driver Route maps</a></li>
                <li><a href="#features" class="hover:text-[#4CAF50] transition">Aswenna Wallet Escrow</a></li>
                <li><a href="#features" class="hover:text-[#4CAF50] transition">Withdraw requests</a></li>
            </ul>
        </div>

        <!-- Admin Contact info -->
        <div>
            <h4 class="text-sm font-bold text-white uppercase tracking-wider mb-4 border-l-2 border-[#4CAF50] pl-2">Platform Oversight</h4>
            <ul class="space-y-2 text-xs text-slate-500">
                <li class="flex items-center space-x-2">
                    <i class="fa-solid fa-envelope text-[#4CAF50]"></i>
                    <span>support@aswenna.lk</span>
                </li>
                <li class="flex items-center space-x-2">
                    <i class="fa-solid fa-phone text-[#4CAF50]"></i>
                    <span>+94 (11) 234-5678</span>
                </li>
                <li class="flex items-center space-x-2">
                    <i class="fa-solid fa-location-dot text-[#4CAF50]"></i>
                    <span>Colombo, Sri Lanka</span>
                </li>
            </ul>
        </div>
    </div>

    <!-- Copyright -->
    <div class="max-w-7xl mx-auto border-t border-slate-800 mt-12 pt-6 flex flex-col md:flex-row justify-between items-center text-xs text-slate-600 relative z-10">
        <span>&copy; {{ date('Y') }} Aswenna Agricultural Marketplace. All Rights Reserved. Development Stage MVP.</span>
        <div class="flex space-x-4 mt-4 md:mt-0">
            <a href="#" class="hover:text-slate-500">Privacy Policy</a>
            <a href="#" class="hover:text-slate-500">Terms of Service</a>
            <a href="{{ route('admin.login') }}" class="text-[#4CAF50] hover:underline font-bold">Admin Portal Login</a>
        </div>
    </div>
</footer>
