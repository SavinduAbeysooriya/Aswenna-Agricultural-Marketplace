<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Aswenna - Admin Dashboard</title>
    <!-- Favicon -->
    <link rel="icon" type="image/png" href="{{ asset('images/logo.png') }}">
    <!-- Tailwind CSS -->
    <script src="https://cdn.tailwindcss.com"></script>
    <!-- SweetAlert2 for modern premium notifications -->
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <!-- Google Fonts: Inter & Poppins -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;950&family=Poppins:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
    <!-- FontAwesome icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <!-- Chart.js for analytics -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: {
                        agri: {
                            deep: '#2E7D32',
                            fresh: '#4CAF50',
                            mint: '#E8F5E9',
                            soft: '#F5F7F6',
                            gold: '#D4A017',
                            dark: '#1B5E20'
                        }
                    },
                    fontFamily: {
                        sans: ['Inter', 'sans-serif'],
                        poppins: ['Poppins', 'sans-serif'],
                    }
                }
            }
        }
    </script>
</head>
<body class="min-h-screen bg-[#F8FAFC] text-slate-800 antialiased selection:bg-emerald-500/30">

    <!-- Mobile Sidebar Overlay -->
    <div id="sidebar-overlay" class="fixed inset-0 bg-slate-900/20 backdrop-blur-sm z-30 hidden transition-opacity duration-300 opacity-0 md:hidden" aria-hidden="true"></div>
    
    <!-- Main Layout Wrapper -->
    <div class="flex w-full min-h-screen">
        
        <!-- Admin Sidebar Component -->
        <x-admin-sidebar />

        <!-- Right Content Wrapper (Header, Main, Footer) -->
        <div class="flex-1 flex flex-col min-w-0 min-h-screen">
            <!-- Admin Header Component -->
            <x-admin-header />

            <!-- Main Operational Dashboard Panel Content -->
            <main class="flex-1 p-4 sm:p-6 md:p-8 space-y-6 md:space-y-8 overflow-y-auto w-full max-w-[1600px] mx-auto">
            <!-- Alert bar if active -->
            <div class="p-4 bg-white border border-emerald-100 text-slate-700 rounded-2xl text-xs font-semibold flex flex-col sm:flex-row items-start sm:items-center justify-between shadow-sm shadow-emerald-500/5 relative overflow-hidden group">
                <div class="absolute inset-0 bg-gradient-to-r from-emerald-50/50 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500"></div>
                <div class="flex items-center space-x-3 relative z-10">
                    <div class="w-8 h-8 rounded-full bg-emerald-100 flex items-center justify-center text-emerald-600">
                        <i class="fa-solid fa-shield-check text-sm"></i>
                    </div>
                    <span>Secure administrator session verified. Welcome back, Super Administrator.</span>
                </div>
                <span class="text-[10px] text-slate-400 font-bold mt-3 sm:mt-0 relative z-10 bg-slate-100/80 px-2 py-1 rounded-md">IP: {{ request()->ip() }}</span>
            </div>

            <!-- KPI performance indicators -->
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 md:gap-6">
                <!-- KPI 1 -->
                <div class="group bg-white rounded-3xl p-6 border border-slate-100 shadow-[0_2px_10px_-3px_rgba(6,81,237,0.03)] space-y-4 flex flex-col justify-between hover:shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:-translate-y-1 transition-all duration-300 relative overflow-hidden">
                    <div class="absolute -right-6 -top-6 w-24 h-24 bg-emerald-50 rounded-full blur-2xl group-hover:bg-emerald-100 transition-colors duration-500"></div>
                    <div class="flex justify-between items-center relative z-10">
                        <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest">Platform Volume</span>
                        <div class="w-11 h-11 rounded-2xl bg-gradient-to-br from-emerald-50 to-emerald-100/50 text-emerald-600 flex items-center justify-center shadow-inner group-hover:scale-110 transition-transform duration-300">
                            <i class="fa-solid fa-chart-line text-sm"></i>
                        </div>
                    </div>
                    <div class="relative z-10">
                        <h3 class="text-3xl font-black text-slate-800 tracking-tight">LKR 2.45M</h3>
                        <span class="text-[11px] text-emerald-600 font-bold flex items-center mt-2 bg-emerald-50 w-fit px-2 py-0.5 rounded-md">
                            <i class="fa-solid fa-arrow-trend-up mr-1.5"></i> +14.5% this week
                        </span>
                    </div>
                </div>

                <!-- KPI 2 -->
                <div class="group bg-white rounded-3xl p-6 border border-slate-100 shadow-[0_2px_10px_-3px_rgba(6,81,237,0.03)] space-y-4 flex flex-col justify-between hover:shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:-translate-y-1 transition-all duration-300 relative overflow-hidden">
                    <div class="absolute -right-6 -top-6 w-24 h-24 bg-blue-50 rounded-full blur-2xl group-hover:bg-blue-100 transition-colors duration-500"></div>
                    <div class="flex justify-between items-center relative z-10">
                        <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest">Active Farmers</span>
                        <div class="w-11 h-11 rounded-2xl bg-gradient-to-br from-blue-50 to-blue-100/50 text-blue-600 flex items-center justify-center shadow-inner group-hover:scale-110 transition-transform duration-300">
                            <i class="fa-solid fa-wheat-awn text-sm"></i>
                        </div>
                    </div>
                    <div class="relative z-10">
                        <h3 class="text-3xl font-black text-slate-800 tracking-tight">1,240</h3>
                        <span class="text-[11px] text-blue-600 font-bold flex items-center mt-2 bg-blue-50 w-fit px-2 py-0.5 rounded-md">
                            <i class="fa-solid fa-arrow-trend-up mr-1.5"></i> +32 new this week
                        </span>
                    </div>
                </div>

                <!-- KPI 3 -->
                <div class="group bg-white rounded-3xl p-6 border border-slate-100 shadow-[0_2px_10px_-3px_rgba(6,81,237,0.03)] space-y-4 flex flex-col justify-between hover:shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:-translate-y-1 transition-all duration-300 relative overflow-hidden">
                    <div class="absolute -right-6 -top-6 w-24 h-24 bg-indigo-50 rounded-full blur-2xl group-hover:bg-indigo-100 transition-colors duration-500"></div>
                    <div class="flex justify-between items-center relative z-10">
                        <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest">Total Deliveries</span>
                        <div class="w-11 h-11 rounded-2xl bg-gradient-to-br from-indigo-50 to-indigo-100/50 text-indigo-600 flex items-center justify-center shadow-inner group-hover:scale-110 transition-transform duration-300">
                            <i class="fa-solid fa-truck-fast text-sm"></i>
                        </div>
                    </div>
                    <div class="relative z-10">
                        <h3 class="text-3xl font-black text-slate-800 tracking-tight">894</h3>
                        <span class="text-[11px] text-indigo-600 font-bold flex items-center mt-2 bg-indigo-50 w-fit px-2 py-0.5 rounded-md">
                            <i class="fa-solid fa-circle-check mr-1.5"></i> 98.4% success rate
                        </span>
                    </div>
                </div>

                <!-- KPI 4 -->
                <div class="group bg-white rounded-3xl p-6 border border-slate-100 shadow-[0_2px_10px_-3px_rgba(6,81,237,0.03)] space-y-4 flex flex-col justify-between hover:shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:-translate-y-1 transition-all duration-300 relative overflow-hidden">
                    <div class="absolute -right-6 -top-6 w-24 h-24 bg-amber-50 rounded-full blur-2xl group-hover:bg-amber-100 transition-colors duration-500"></div>
                    <div class="flex justify-between items-center relative z-10">
                        <span class="text-[10px] font-extrabold text-slate-400 uppercase tracking-widest">Platform Cut</span>
                        <div class="w-11 h-11 rounded-2xl bg-gradient-to-br from-amber-50 to-amber-100/50 text-amber-600 flex items-center justify-center shadow-inner group-hover:scale-110 transition-transform duration-300">
                            <i class="fa-solid fa-sack-dollar text-sm"></i>
                        </div>
                    </div>
                    <div class="relative z-10">
                        <h3 class="text-3xl font-black text-slate-800 tracking-tight">LKR 184.5k</h3>
                        <span class="text-[11px] text-slate-500 font-bold flex items-center mt-2 bg-slate-50 w-fit px-2 py-0.5 rounded-md">
                            System commissions
                        </span>
                    </div>
                </div>
            </div>

            <!-- Operations Grid -->
            <div class="grid grid-cols-1 xl:grid-cols-2 gap-6 md:gap-8 items-start">
                
                <!-- Plantation Verification Requests -->
                <div class="bg-white rounded-3xl p-5 sm:p-7 border border-slate-100 shadow-[0_2px_10px_-3px_rgba(6,81,237,0.03)] space-y-6">
                    <div class="flex justify-between items-center border-b border-slate-100 pb-5">
                        <div>
                            <h3 class="text-lg font-bold text-slate-800 flex items-center">
                                <div class="w-8 h-8 rounded-lg bg-amber-50 text-amber-500 flex items-center justify-center mr-3 shadow-inner">
                                    <i class="fa-solid fa-hourglass-half text-sm"></i> 
                                </div>
                                Crop Verification Pipeline
                            </h3>
                            <p class="text-[11px] sm:text-xs text-slate-500 mt-1 font-medium">Verifying GAP certificates & crop estimations</p>
                        </div>
                        <span class="px-3 py-1 rounded-full bg-amber-50 text-amber-700 text-[10px] font-extrabold shadow-sm border border-amber-100/50">
                            4 Tasks Left
                        </span>
                    </div>

                    <div class="space-y-4">
                        <!-- Verification Row 1 -->
                        <div id="row-crop-1" class="group p-4 bg-white border border-slate-100 hover:border-emerald-200 shadow-sm rounded-2xl flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 transition-all hover:shadow-md">
                            <div class="space-y-1.5 w-full sm:w-auto">
                                <span class="text-sm font-bold text-slate-800 block">Saman Kumara <span class="text-[10px] text-slate-400 ml-1 font-semibold">#FM1044</span></span>
                                <span class="text-xs text-slate-500 block font-medium">Yield: Nuwara Eliya Carrot • 350 kg • Grade A</span>
                                <span class="inline-flex px-2 py-0.5 rounded bg-emerald-50 text-emerald-700 text-[9px] font-bold uppercase mt-1 border border-emerald-100">GAP Certified</span>
                            </div>
                            <div class="flex space-x-2 w-full sm:w-auto mt-2 sm:mt-0">
                                <button onclick="approveRequest('crop-1')" class="flex-1 sm:flex-initial px-5 py-2.5 bg-gradient-to-b from-emerald-500 to-emerald-600 hover:to-emerald-700 text-white rounded-xl text-[11px] font-bold shadow-md shadow-emerald-500/20 transition-all active:scale-95">Approve</button>
                                <button onclick="rejectRequest('crop-1')" class="flex-1 sm:flex-initial px-5 py-2.5 bg-slate-50 hover:bg-rose-50 text-slate-600 hover:text-rose-600 rounded-xl text-[11px] font-bold transition-all border border-slate-200 hover:border-rose-200 active:scale-95">Reject</button>
                            </div>
                        </div>

                        <!-- Verification Row 2 -->
                        <div id="row-crop-2" class="group p-4 bg-white border border-slate-100 hover:border-emerald-200 shadow-sm rounded-2xl flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 transition-all hover:shadow-md">
                            <div class="space-y-1.5 w-full sm:w-auto">
                                <span class="text-sm font-bold text-slate-800 block">Sunil Perera <span class="text-[10px] text-slate-400 ml-1 font-semibold">#FM1028</span></span>
                                <span class="text-xs text-slate-500 block font-medium">Yield: Keeri Samba Rice • 2,500 kg • Grade A</span>
                                <span class="inline-flex px-2 py-0.5 rounded bg-amber-50 text-amber-700 text-[9px] font-bold uppercase mt-1 border border-amber-100">Organic Cert Pending</span>
                            </div>
                            <div class="flex space-x-2 w-full sm:w-auto mt-2 sm:mt-0">
                                <button onclick="approveRequest('crop-2')" class="flex-1 sm:flex-initial px-5 py-2.5 bg-gradient-to-b from-emerald-500 to-emerald-600 hover:to-emerald-700 text-white rounded-xl text-[11px] font-bold shadow-md shadow-emerald-500/20 transition-all active:scale-95">Approve</button>
                                <button onclick="rejectRequest('crop-2')" class="flex-1 sm:flex-initial px-5 py-2.5 bg-slate-50 hover:bg-rose-50 text-slate-600 hover:text-rose-600 rounded-xl text-[11px] font-bold transition-all border border-slate-200 hover:border-rose-200 active:scale-95">Reject</button>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Financial Volume Chart -->
                <div class="bg-white rounded-3xl p-5 sm:p-7 border border-slate-100 shadow-[0_2px_10px_-3px_rgba(6,81,237,0.03)] space-y-6">
                    <div class="flex justify-between items-center border-b border-slate-100 pb-5">
                        <div>
                            <h3 class="text-lg font-bold text-slate-800 flex items-center">
                                <div class="w-8 h-8 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center mr-3 shadow-inner">
                                    <i class="fa-solid fa-chart-column text-sm"></i>
                                </div>
                                Platform Commission Treasury
                            </h3>
                            <p class="text-[11px] sm:text-xs text-slate-500 mt-1 font-medium">Weekly commission earnings from bidding and dispatches</p>
                        </div>
                    </div>

                    <div class="h-64 w-full flex items-center justify-center relative bg-slate-50/50 rounded-2xl p-4 border border-slate-50">
                        <canvas id="commissionChart" class="max-h-full w-full"></canvas>
                    </div>
                </div>

            </div>
            </main>

            <!-- Admin Footer Component -->
            <x-admin-footer />
        </div>
    </div>

    <!-- Chart rendering and verification approvals logic -->
    <script>
        // Mobile Sidebar Toggle Logic
        document.addEventListener('DOMContentLoaded', () => {
            const sidebar = document.getElementById('admin-sidebar');
            const toggleBtn = document.getElementById('mobile-sidebar-toggle');
            const overlay = document.getElementById('sidebar-overlay');

            function toggleSidebar() {
                const isOpen = sidebar.classList.contains('translate-x-0');
                if (isOpen) {
                    sidebar.classList.remove('translate-x-0');
                    sidebar.classList.add('-translate-x-full');
                    overlay.classList.remove('opacity-100');
                    overlay.classList.add('opacity-0');
                    setTimeout(() => overlay.classList.add('hidden'), 300);
                } else {
                    sidebar.classList.remove('-translate-x-full');
                    sidebar.classList.add('translate-x-0');
                    overlay.classList.remove('hidden');
                    // Small delay to allow display:block to apply before animating opacity
                    setTimeout(() => overlay.classList.add('opacity-100'), 10);
                }
            }

            toggleBtn?.addEventListener('click', toggleSidebar);
            overlay?.addEventListener('click', toggleSidebar);
        });

        // Crop verification pipeline simulation
        function approveRequest(id) {
            const row = document.getElementById(`row-${id}`);
            row.style.opacity = '0.3';
            row.style.transform = 'scale(0.98)';
            setTimeout(() => {
                row.remove();
                Swal.fire({
                    icon: 'success',
                    title: 'Crop Verified',
                    text: 'Crop yield verified and listed in the public marketplace database!',
                    confirmButtonColor: '#10b981', // emerald-500
                    customClass: {
                        popup: 'rounded-3xl shadow-2xl border border-slate-100',
                        confirmButton: 'rounded-xl font-bold shadow-md shadow-emerald-500/20 px-6 py-2.5'
                    }
                });
            }, 400);
        }

        function rejectRequest(id) {
            const row = document.getElementById(`row-${id}`);
            row.style.opacity = '0.3';
            row.style.transform = 'scale(0.98)';
            setTimeout(() => {
                row.remove();
                Swal.fire({
                    icon: 'success', // Reusing success icon for prototype flow
                    title: 'Request Rejected',
                    text: 'Verification request rejected. Feedback dispatched to the farmer.',
                    confirmButtonColor: '#10b981',
                    customClass: {
                        popup: 'rounded-3xl shadow-2xl border border-slate-100',
                        confirmButton: 'rounded-xl font-bold shadow-md shadow-emerald-500/20 px-6 py-2.5'
                    }
                });
            }, 400);
        }

        // Initialize Chart.js on page load
        document.addEventListener("DOMContentLoaded", function() {
            const ctx = document.getElementById('commissionChart').getContext('2d');
            
            // Create gradient for chart line
            let gradient = ctx.createLinearGradient(0, 0, 0, 400);
            gradient.addColorStop(0, 'rgba(16, 185, 129, 0.2)'); // emerald-500
            gradient.addColorStop(1, 'rgba(16, 185, 129, 0)');

            new Chart(ctx, {
                type: 'line',
                data: {
                    labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                    datasets: [{
                        label: 'Commission (LKR)',
                        data: [12000, 19000, 32000, 50000, 42000, 68000, 84500],
                        borderColor: '#10b981', // emerald-500
                        backgroundColor: gradient,
                        borderWidth: 3,
                        fill: true,
                        tension: 0.4,
                        pointRadius: 4,
                        pointBackgroundColor: '#fff',
                        pointBorderColor: '#10b981',
                        pointBorderWidth: 2,
                        pointHoverRadius: 6,
                        pointHoverBackgroundColor: '#10b981',
                        pointHoverBorderColor: '#fff',
                        pointHoverBorderWidth: 2
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { display: false },
                        tooltip: {
                            backgroundColor: 'rgba(15, 23, 42, 0.9)', // slate-900
                            titleFont: { family: 'Inter', size: 12, weight: 'bold' },
                            bodyFont: { family: 'Inter', size: 12 },
                            padding: 12,
                            cornerRadius: 8,
                            displayColors: false,
                            callbacks: {
                                label: function(context) {
                                    return 'LKR ' + context.parsed.y.toLocaleString();
                                }
                            }
                        }
                    },
                    scales: {
                        y: {
                            grid: { 
                                color: '#f1f5f9', // slate-100
                                borderDash: [5, 5] 
                            },
                            ticks: { 
                                font: { family: 'Inter', size: 11, weight: '500' },
                                color: '#94a3b8' // slate-400
                            },
                            border: { display: false }
                        },
                        x: {
                            grid: { display: false },
                            ticks: { 
                                font: { family: 'Inter', size: 11, weight: '500' },
                                color: '#94a3b8' 
                            },
                            border: { display: false }
                        }
                    },
                    interaction: {
                        intersect: false,
                        mode: 'index',
                    },
                }
            });
        });
    </script>
</body>
</html>
