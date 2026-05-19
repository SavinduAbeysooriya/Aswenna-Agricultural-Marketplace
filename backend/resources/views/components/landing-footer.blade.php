<!-- resources/views/components/landing-footer.blade.php -->
<footer id="footer" class="bg-slate-900 text-slate-400 py-16 px-6 md:px-12 border-t border-slate-800 relative overflow-hidden">
    <!-- Leaf watermark illustration -->
    <div class="absolute -bottom-16 -right-16 text-slate-800/10 pointer-events-none">
        <i class="fa-solid fa-leaf text-[220px]"></i>
    </div>

    <div class="max-w-7xl mx-auto grid grid-cols-1 md:grid-cols-4 gap-12 relative z-10">
        <!-- Logo and info -->
        <div class="space-y-4">
            <div class="flex items-center space-x-3 text-white">
                <div class="w-10 h-10 bg-[#2E7D32] rounded-xl flex items-center justify-center">
                    <i class="fa-solid fa-leaf text-lg"></i>
                </div>
                <span class="text-2xl font-extrabold tracking-tight">Aswenna</span>
            </div>
            <p class="text-xs leading-relaxed text-slate-500">
                Sri Lanka's premier direct farmer-to-buyer smart agricultural marketplace ecosystem. Bridging transparency, bidding, and dynamic freight logistics.
            </p>
            <div class="flex items-center space-x-3 pt-2">
                <a href="#" class="w-8 h-8 rounded-lg bg-slate-800 hover:bg-[#2E7D32] text-white flex items-center justify-center transition"><i class="fa-brands fa-facebook-f text-sm"></i></a>
                <a href="#" class="w-8 h-8 rounded-lg bg-slate-800 hover:bg-[#2E7D32] text-white flex items-center justify-center transition"><i class="fa-brands fa-twitter text-sm"></i></a>
                <a href="#" class="w-8 h-8 rounded-lg bg-slate-800 hover:bg-[#2E7D32] text-white flex items-center justify-center transition"><i class="fa-brands fa-instagram text-sm"></i></a>
            </div>
        </div>

        <!-- Links 1 -->
        <div>
            <h4 class="text-sm font-bold text-white uppercase tracking-wider mb-4">Marketplace Options</h4>
            <ul class="space-y-2 text-xs">
                <li><a href="#" class="hover:text-[#4CAF50] transition">Direct Yield Bidding</a></li>
                <li><a href="#" class="hover:text-[#4CAF50] transition">Bulk Buying Storefronts</a></li>
                <li><a href="#" class="hover:text-[#4CAF50] transition">Retailer Fresh Groceries</a></li>
                <li><a href="#" class="hover:text-[#4CAF50] transition">Crop Verification</a></li>
            </ul>
        </div>

        <!-- Links 2 -->
        <div>
            <h4 class="text-sm font-bold text-white uppercase tracking-wider mb-4">Logistics & Payouts</h4>
            <ul class="space-y-2 text-xs">
                <li><a href="#" class="hover:text-[#4CAF50] transition">Smart Dispatch Engine</a></li>
                <li><a href="#" class="hover:text-[#4CAF50] transition">Integrated Driver Route maps</a></li>
                <li><a href="#" class="hover:text-[#4CAF50] transition">Aswenna Wallet Escrow</a></li>
                <li><a href="#" class="hover:text-[#4CAF50] transition">Withdraw requests</a></li>
            </ul>
        </div>

        <!-- Admin Contact info -->
        <div>
            <h4 class="text-sm font-bold text-white uppercase tracking-wider mb-4">Platform Oversight</h4>
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
    <div class="max-w-7xl mx-auto border-t border-slate-800 mt-12 pt-6 flex flex-col md:flex-row justify-between items-center text-xs text-slate-600">
        <span>&copy; {{ date('Y') }} Aswenna Agricultural Marketplace. All Rights Reserved. Development Stage MVP.</span>
        <div class="flex space-x-4 mt-4 md:mt-0">
            <a href="#" class="hover:text-slate-500">Privacy Policy</a>
            <a href="#" class="hover:text-slate-500">Terms of Service</a>
            <a href="{{ route('admin.login') }}" class="text-[#4CAF50] hover:underline font-bold">Admin Portal Login</a>
        </div>
    </div>
</footer>
