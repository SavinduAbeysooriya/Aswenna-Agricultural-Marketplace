<!-- resources/views/components/admin-footer.blade.php -->
<footer class="bg-white/80 backdrop-blur-xl border-t border-slate-200/60 py-4 px-4 sm:px-8 flex flex-col md:flex-row justify-between items-center text-[10px] sm:text-xs text-slate-500 mt-auto transition-all duration-300">
    <div class="flex items-center space-x-2.5">
        <div class="w-6 h-6 rounded bg-emerald-50 flex items-center justify-center text-emerald-600 shadow-inner">
            <i class="fa-solid fa-shield-halved text-[10px]"></i>
        </div>
        <span class="font-bold text-slate-700 tracking-tight">Aswenna Secure Web Console</span>
        <span class="text-slate-300 hidden sm:inline">|</span>
        <span class="hidden sm:inline font-medium">MVP Framework v2.0</span>
    </div>
    
    <div class="flex flex-wrap justify-center items-center gap-x-4 gap-y-2 mt-4 md:mt-0 font-medium text-slate-400">
        <span class="flex items-center bg-slate-50 px-2.5 py-1 rounded-md border border-slate-100">
            <i class="fa-solid fa-bolt text-amber-500 mr-1.5 text-[9px]"></i> 
            Latency: <strong class="text-slate-700 ml-1">8.4 ms</strong>
        </span>
        <span class="flex items-center bg-emerald-50 px-2.5 py-1 rounded-md border border-emerald-100 text-emerald-700">
            <i class="fa-solid fa-database mr-1.5 text-[9px]"></i> 
            SQL: <strong class="ml-1">Active</strong>
        </span>
        <span class="flex items-center bg-slate-50 px-2.5 py-1 rounded-md border border-slate-100">
            <i class="fa-solid fa-clock mr-1.5 text-[9px] text-slate-400"></i> 
            Time: <strong class="text-slate-700 ml-1">{{ date('H:i:s T') }}</strong>
        </span>
    </div>
</footer>
