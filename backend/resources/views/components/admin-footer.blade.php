<!-- resources/views/components/admin-footer.blade.php -->
<footer class="bg-white border-t border-slate-100 py-5 px-8 flex flex-col md:flex-row justify-between items-center text-xs text-slate-500 mt-auto">
    <div class="flex items-center space-x-2">
        <i class="fa-solid fa-shield-halved text-[#2E7D32]"></i>
        <span class="font-semibold text-slate-700">Aswenna Secure Web Console</span>
        <span class="text-slate-400">|</span>
        <span>MVP Admin Dashboard Framework v1.0</span>
    </div>
    <div class="flex items-center space-x-6 mt-4 md:mt-0 font-medium text-slate-400">
        <span>Server Latency: <strong class="text-emerald-600">8.4 ms</strong></span>
        <span>Secure SQL Connection: <strong class="text-emerald-600">Active</strong></span>
        <span>System Time: <strong class="text-slate-600">{{ date('H:i:s T') }}</strong></span>
    </div>
</footer>
