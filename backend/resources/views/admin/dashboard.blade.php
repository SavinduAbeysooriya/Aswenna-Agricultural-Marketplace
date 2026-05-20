<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Aswenna - Admin Dashboard</title>
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
<body class="min-h-screen bg-slate-50 text-slate-800 antialiased flex flex-col justify-between">

    <!-- Admin Header Component -->
    <x-admin-header />

    <div class="flex-1 flex flex-col md:flex-row w-full">
        <!-- Admin Sidebar Component -->
        <x-admin-sidebar />

        <!-- Main Operational Dashboard Panel Content -->
        <main class="flex-1 p-6 md:p-8 space-y-6 overflow-y-auto">
            <!-- Alert bar if active -->
            <div class="p-4 bg-emerald-50 border border-emerald-100 text-agri-dark rounded-2xl text-xs font-semibold flex items-center justify-between shadow-sm">
                <div class="flex items-center space-x-2">
                    <i class="fa-solid fa-circle-check text-base animate-pulse"></i>
                    <span>Secure administrator session verified. Welcome back, Super Administrator.</span>
                </div>
                <span class="text-[10px] text-slate-400 font-bold">Session IP: {{ request()->ip() }}</span>
            </div>

            <!-- KPI performance indicators -->
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
                <!-- KPI 1 -->
                <div class="bg-white rounded-3xl p-5 border border-slate-100 shadow-sm space-y-3 flex flex-col justify-between hover:shadow-md transition">
                    <div class="flex justify-between items-center">
                        <span class="text-xs font-bold text-slate-400 uppercase tracking-wider">Platform Volume</span>
                        <div class="w-10 h-10 rounded-xl bg-emerald-50 text-[#2E7D32] flex items-center justify-center shadow-inner">
                            <i class="fa-solid fa-chart-line text-sm"></i>
                        </div>
                    </div>
                    <div>
                        <h3 class="text-2xl font-black text-slate-800">LKR 2.45M</h3>
                        <span class="text-[10px] text-emerald-600 font-bold flex items-center mt-1">
                            <i class="fa-solid fa-arrow-up mr-1"></i> +14.5% this week
                        </span>
                    </div>
                </div>

                <!-- KPI 2 -->
                <div class="bg-white rounded-3xl p-5 border border-slate-100 shadow-sm space-y-3 flex flex-col justify-between hover:shadow-md transition">
                    <div class="flex justify-between items-center">
                        <span class="text-xs font-bold text-slate-400 uppercase tracking-wider">Active Farmers</span>
                        <div class="w-10 h-10 rounded-xl bg-emerald-50 text-[#2E7D32] flex items-center justify-center shadow-inner">
                            <i class="fa-solid fa-wheat-awn text-sm"></i>
                        </div>
                    </div>
                    <div>
                        <h3 class="text-2xl font-black text-slate-800">1,240</h3>
                        <span class="text-[10px] text-emerald-600 font-bold flex items-center mt-1">
                            <i class="fa-solid fa-arrow-up mr-1"></i> +32 new registrations
                        </span>
                    </div>
                </div>

                <!-- KPI 3 -->
                <div class="bg-white rounded-3xl p-5 border border-slate-100 shadow-sm space-y-3 flex flex-col justify-between hover:shadow-md transition">
                    <div class="flex justify-between items-center">
                        <span class="text-xs font-bold text-slate-400 uppercase tracking-wider">Total Deliveries</span>
                        <div class="w-10 h-10 rounded-xl bg-emerald-50 text-[#2E7D32] flex items-center justify-center shadow-inner">
                            <i class="fa-solid fa-truck-fast text-sm"></i>
                        </div>
                    </div>
                    <div>
                        <h3 class="text-2xl font-black text-slate-800">894 Tasks</h3>
                        <span class="text-[10px] text-emerald-600 font-bold flex items-center mt-1">
                            <i class="fa-solid fa-circle-check mr-1"></i> 98.4% delivery success
                        </span>
                    </div>
                </div>

                <!-- KPI 4 -->
                <div class="bg-white rounded-3xl p-5 border border-slate-100 shadow-sm space-y-3 flex flex-col justify-between hover:shadow-md transition">
                    <div class="flex justify-between items-center">
                        <span class="text-xs font-bold text-slate-400 uppercase tracking-wider">Platform Cut</span>
                        <div class="w-10 h-10 rounded-xl bg-amber-50 text-agri-gold flex items-center justify-center shadow-inner">
                            <i class="fa-solid fa-sack-dollar text-sm"></i>
                        </div>
                    </div>
                    <div>
                        <h3 class="text-2xl font-black text-slate-800">LKR 184,500</h3>
                        <span class="text-[10px] text-slate-400 font-medium flex items-center mt-1">
                            Accumulated system commissions
                        </span>
                    </div>
                </div>
            </div>

            <!-- Operations Grid -->
            <div class="grid grid-cols-1 xl:grid-cols-2 gap-8 items-start">
                
                <!-- Plantation Verification Requests -->
                <div class="bg-white rounded-3xl p-6 border border-slate-100 shadow-sm space-y-6">
                    <div class="flex justify-between items-center border-b border-slate-50 pb-4">
                        <div>
                            <h3 class="text-lg font-bold text-slate-800 flex items-center">
                                <i class="fa-solid fa-hourglass-half text-amber-500 mr-2"></i> 
                                Crop Verification Pipeline
                            </h3>
                            <p class="text-xs text-slate-400">Verifying GAP certificates and crop grade estimations</p>
                        </div>
                        <span class="px-2.5 py-1 rounded-full bg-amber-100 text-amber-800 text-[10px] font-bold">
                            4 Tasks Left
                        </span>
                    </div>

                    <div class="space-y-4">
                        <!-- Verification Row 1 -->
                        <div id="row-crop-1" class="p-4 bg-slate-50 border border-slate-100 rounded-2xl flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 transition">
                            <div class="space-y-1">
                                <span class="text-sm font-bold text-slate-800 block">Saman Kumara (Farmer ID: #FM1044)</span>
                                <span class="text-xs text-slate-400 block">Yield: Nuwara Eliya Carrot • Quantity: 350 kg • Expected: Grade A</span>
                                <span class="inline-flex px-2 py-0.5 rounded bg-emerald-100 text-emerald-800 text-[9px] font-bold uppercase mt-1">GAP Certified</span>
                            </div>
                            <div class="flex space-x-2 w-full sm:w-auto">
                                <button onclick="approveRequest('crop-1')" class="flex-1 sm:flex-initial px-4 py-2 bg-gradient-to-r from-agri-deep to-agri-fresh text-white rounded-xl text-xs font-bold shadow-sm transition hover:shadow-lg hover:shadow-emerald-600/10">Approve</button>
                                <button onclick="rejectRequest('crop-1')" class="flex-1 sm:flex-initial px-4 py-2 bg-rose-50 hover:bg-rose-100 text-rose-600 rounded-xl text-xs font-bold transition">Reject</button>
                            </div>
                        </div>

                        <!-- Verification Row 2 -->
                        <div id="row-crop-2" class="p-4 bg-slate-50 border border-slate-100 rounded-2xl flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 transition">
                            <div class="space-y-1">
                                <span class="text-sm font-bold text-slate-800 block">Sunil Perera (Farmer ID: #FM1028)</span>
                                <span class="text-xs text-slate-400 block">Yield: Keeri Samba Rice • Quantity: 2,500 kg • Expected: Grade A</span>
                                <span class="inline-flex px-2 py-0.5 rounded bg-amber-100 text-amber-800 text-[9px] font-bold uppercase mt-1">Organic Certificate Pending</span>
                            </div>
                            <div class="flex space-x-2 w-full sm:w-auto">
                                <button onclick="approveRequest('crop-2')" class="flex-1 sm:flex-initial px-4 py-2 bg-gradient-to-r from-agri-deep to-agri-fresh text-white rounded-xl text-xs font-bold shadow-sm transition hover:shadow-lg hover:shadow-emerald-600/10">Approve</button>
                                <button onclick="rejectRequest('crop-2')" class="flex-1 sm:flex-initial px-4 py-2 bg-rose-50 hover:bg-rose-100 text-rose-600 rounded-xl text-xs font-bold transition">Reject</button>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Financial Volume Chart -->
                <div class="bg-white rounded-3xl p-6 border border-slate-100 shadow-sm space-y-6">
                    <div class="flex justify-between items-center border-b border-slate-50 pb-4">
                        <div>
                            <h3 class="text-lg font-bold text-slate-800 flex items-center">
                                <i class="fa-solid fa-chart-column text-[#2E7D32] mr-2"></i>
                                Platform Commission Treasury
                            </h3>
                            <p class="text-xs text-slate-400">Weekly commission earnings from bidding and dispatches</p>
                        </div>
                    </div>

                    <div class="h-64 w-full flex items-center justify-center relative">
                        <canvas id="commissionChart" class="max-h-full w-full"></canvas>
                    </div>
                </div>

            </div>
        </main>
    </div>

    <!-- Admin Footer Component -->
    <x-admin-footer />

    <!-- Chart rendering and verification approvals logic -->
    <script>
        // Crop verification pipeline simulation
        function approveRequest(id) {
            const row = document.getElementById(`row-${id}`);
            row.style.opacity = '0.3';
            setTimeout(() => {
                row.remove();
                Swal.fire({
                    icon: 'success',
                    title: 'Crop Verified',
                    text: 'Crop yield verified and listed in the public marketplace database!',
                    confirmButtonColor: '#2E7D32'
                });
            }, 600);
        }

        function rejectRequest(id) {
            const row = document.getElementById(`row-${id}`);
            row.style.opacity = '0.3';
            setTimeout(() => {
                row.remove();
                Swal.fire({
                    icon: 'success',
                    title: 'Request Rejected',
                    text: 'Verification request rejected. Feedback dispatched to the farmer.',
                    confirmButtonColor: '#2E7D32'
                });
            }, 600);
        }

        // Initialize Chart.js on page load
        document.addEventListener("DOMContentLoaded", function() {
            const ctx = document.getElementById('commissionChart').getContext('2d');
            new Chart(ctx, {
                type: 'line',
                data: {
                    labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                    datasets: [{
                        label: 'Commission (LKR)',
                        data: [12000, 19000, 32000, 50000, 42000, 68000, 84500],
                        borderColor: '#2E7D32',
                        backgroundColor: 'rgba(46, 125, 50, 0.08)',
                        borderWidth: 3,
                        fill: true,
                        tension: 0.4,
                        pointRadius: 4,
                        pointBackgroundColor: '#2E7D32'
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { display: false }
                    },
                    scales: {
                        y: {
                            grid: { color: '#F1F5F9' },
                            ticks: { font: { family: 'Inter', size: 10 } }
                        },
                        x: {
                            grid: { display: false },
                            ticks: { font: { family: 'Inter', size: 10 } }
                        }
                    }
                }
            });
        });
    </script>
</body>
</html>
