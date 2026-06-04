<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Aswenna - User Management Roles</title>
    <link rel="icon" type="image/png" href="{{ asset('images/logo.png') }}">
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;950&family=Poppins:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
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
    <div id="sidebar-overlay" class="fixed inset-0 bg-slate-900/20 backdrop-blur-sm z-30 hidden transition-opacity duration-300 opacity-0 md:hidden" aria-hidden="true"></div>

    <div class="flex w-full min-h-screen">
        <x-admin-sidebar :pending-crop-count="$pendingCropCount" />

        <div class="flex-1 flex flex-col min-w-0 min-h-screen">
            <x-admin-header />

            <main class="flex-1 p-4 sm:p-6 md:p-8 overflow-y-auto w-full max-w-[1700px] mx-auto space-y-8">
                <!-- Header Block -->
                <section class="flex flex-col xl:flex-row xl:items-end xl:justify-between gap-4">
                    <div>
                        <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-50 border border-emerald-100 text-emerald-700 text-[11px] font-extrabold uppercase tracking-widest">
                            <i class="fa-solid fa-users-gear"></i>
                            User Access Control
                        </div>
                        <h1 class="mt-3 text-2xl sm:text-3xl font-black tracking-tight text-slate-900 font-poppins">User Management</h1>
                        <p class="mt-1 text-sm text-slate-500 font-medium max-w-2xl">Select a user role below to review, audit verification documents, and manage active accounts.</p>
                    </div>
                    <div class="flex gap-3">
                        <a href="{{ route('admin.dashboard') }}" class="inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-white border border-slate-200 text-slate-600 hover:text-emerald-700 hover:border-emerald-200 text-xs font-bold shadow-sm transition">
                            <i class="fa-solid fa-arrow-left"></i>
                            Dashboard
                        </a>
                    </div>
                </section>

                <!-- Cards Grid -->
                <section class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    <!-- 1. Farmer -->
                    <div class="group bg-white rounded-3xl p-6 border border-slate-100 shadow-[0_2px_10px_-3px_rgba(6,81,237,0.03)] flex flex-col justify-between hover:shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:-translate-y-1.5 transition-all duration-300 relative overflow-hidden">
                        <div class="absolute -right-6 -top-6 w-24 h-24 bg-emerald-50 rounded-full blur-2xl group-hover:bg-emerald-100 transition-colors duration-500"></div>
                        <div class="space-y-4">
                            <div class="flex justify-between items-center relative z-10">
                                <div class="w-12 h-12 rounded-2xl bg-emerald-50 border border-emerald-100 text-emerald-600 flex items-center justify-center shadow-inner group-hover:scale-110 transition-transform duration-300">
                                    <i class="fa-solid fa-wheat-awn text-lg"></i>
                                </div>
                                <span class="px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-700 text-[10px] font-black tracking-wider uppercase border border-emerald-100">
                                    {{ $roleCounts['farmer'] }} Registered
                                </span>
                            </div>
                            <div class="space-y-2">
                                <h3 class="text-lg font-bold text-slate-800">Farmers</h3>
                                <p class="text-xs text-slate-500 leading-relaxed font-medium">Review organic & GAP certifications, crop variety estimations, and land registration logs.</p>
                            </div>
                        </div>
                        <div class="mt-6 pt-4 border-t border-slate-50">
                            <a href="{{ route('admin.users.index', 'farmer') }}" class="w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-slate-900 hover:bg-emerald-600 text-white text-xs font-bold transition">
                                Inspect Farmers
                                <i class="fa-solid fa-arrow-right text-[10px] group-hover:translate-x-1 transition-transform"></i>
                            </a>
                        </div>
                    </div>

                    <!-- 2. Retail Seller -->
                    <div class="group bg-white rounded-3xl p-6 border border-slate-100 shadow-[0_2px_10px_-3px_rgba(6,81,237,0.03)] flex flex-col justify-between hover:shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:-translate-y-1.5 transition-all duration-300 relative overflow-hidden">
                        <div class="absolute -right-6 -top-6 w-24 h-24 bg-blue-50 rounded-full blur-2xl group-hover:bg-blue-100 transition-colors duration-500"></div>
                        <div class="space-y-4">
                            <div class="flex justify-between items-center relative z-10">
                                <div class="w-12 h-12 rounded-2xl bg-blue-50 border border-blue-100 text-blue-600 flex items-center justify-center shadow-inner group-hover:scale-110 transition-transform duration-300">
                                    <i class="fa-solid fa-store text-lg"></i>
                                </div>
                                <span class="px-2.5 py-1 rounded-full bg-blue-50 text-blue-700 text-[10px] font-black tracking-wider uppercase border border-blue-100">
                                    {{ $roleCounts['retail_seller'] }} Registered
                                </span>
                            </div>
                            <div class="space-y-2">
                                <h3 class="text-lg font-bold text-slate-800">Retail Sellers</h3>
                                <p class="text-xs text-slate-500 leading-relaxed font-medium">Audit business registrations (BR), BR image files, shop locations, and ownership details.</p>
                            </div>
                        </div>
                        <div class="mt-6 pt-4 border-t border-slate-50">
                            <a href="{{ route('admin.users.index', 'retail_seller') }}" class="w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-slate-900 hover:bg-blue-600 text-white text-xs font-bold transition">
                                Inspect Sellers
                                <i class="fa-solid fa-arrow-right text-[10px] group-hover:translate-x-1 transition-transform"></i>
                            </a>
                        </div>
                    </div>

                    <!-- 3. Delivery Partner -->
                    <div class="group bg-white rounded-3xl p-6 border border-slate-100 shadow-[0_2px_10px_-3px_rgba(6,81,237,0.03)] flex flex-col justify-between hover:shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:-translate-y-1.5 transition-all duration-300 relative overflow-hidden">
                        <div class="absolute -right-6 -top-6 w-24 h-24 bg-indigo-50 rounded-full blur-2xl group-hover:bg-indigo-100 transition-colors duration-500"></div>
                        <div class="space-y-4">
                            <div class="flex justify-between items-center relative z-10">
                                <div class="w-12 h-12 rounded-2xl bg-indigo-50 border border-indigo-100 text-indigo-600 flex items-center justify-center shadow-inner group-hover:scale-110 transition-transform duration-300">
                                    <i class="fa-solid fa-truck-fast text-lg"></i>
                                </div>
                                <span class="px-2.5 py-1 rounded-full bg-indigo-50 text-indigo-700 text-[10px] font-black tracking-wider uppercase border border-indigo-100">
                                    {{ $roleCounts['delivery_partner'] }} Registered
                                </span>
                            </div>
                            <div class="space-y-2">
                                <h3 class="text-lg font-bold text-slate-800">Delivery Partners</h3>
                                <p class="text-xs text-slate-500 leading-relaxed font-medium">Approve transport licenses, vehicle details, registration numbers, and insurance policies.</p>
                            </div>
                        </div>
                        <div class="mt-6 pt-4 border-t border-slate-50">
                            <a href="{{ route('admin.users.index', 'delivery_partner') }}" class="w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-slate-900 hover:bg-indigo-600 text-white text-xs font-bold transition">
                                Inspect Partners
                                <i class="fa-solid fa-arrow-right text-[10px] group-hover:translate-x-1 transition-transform"></i>
                            </a>
                        </div>
                    </div>

                    <!-- 4. Buyer -->
                    <div class="group bg-white rounded-3xl p-6 border border-slate-100 shadow-[0_2px_10px_-3px_rgba(6,81,237,0.03)] flex flex-col justify-between hover:shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:-translate-y-1.5 transition-all duration-300 relative overflow-hidden">
                        <div class="absolute -right-6 -top-6 w-24 h-24 bg-violet-50 rounded-full blur-2xl group-hover:bg-violet-100 transition-colors duration-500"></div>
                        <div class="space-y-4">
                            <div class="flex justify-between items-center relative z-10">
                                <div class="w-12 h-12 rounded-2xl bg-violet-50 border border-violet-100 text-violet-600 flex items-center justify-center shadow-inner group-hover:scale-110 transition-transform duration-300">
                                    <i class="fa-solid fa-hand-holding-dollar text-lg"></i>
                                </div>
                                <span class="px-2.5 py-1 rounded-full bg-violet-50 text-violet-700 text-[10px] font-black tracking-wider uppercase border border-violet-100">
                                    {{ $roleCounts['buyer'] }} Registered
                                </span>
                            </div>
                            <div class="space-y-2">
                                <h3 class="text-lg font-bold text-slate-800">Buyers</h3>
                                <p class="text-xs text-slate-500 leading-relaxed font-medium">Verify wholesale buyer accounts, business parameters, and national ID cards.</p>
                            </div>
                        </div>
                        <div class="mt-6 pt-4 border-t border-slate-50">
                            <a href="{{ route('admin.users.index', 'buyer') }}" class="w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-slate-900 hover:bg-violet-600 text-white text-xs font-bold transition">
                                Inspect Buyers
                                <i class="fa-solid fa-arrow-right text-[10px] group-hover:translate-x-1 transition-transform"></i>
                            </a>
                        </div>
                    </div>

                    <!-- 5. Customer -->
                    <div class="group bg-white rounded-3xl p-6 border border-slate-100 shadow-[0_2px_10px_-3px_rgba(6,81,237,0.03)] flex flex-col justify-between hover:shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:-translate-y-1.5 transition-all duration-300 relative overflow-hidden">
                        <div class="absolute -right-6 -top-6 w-24 h-24 bg-teal-50 rounded-full blur-2xl group-hover:bg-teal-100 transition-colors duration-500"></div>
                        <div class="space-y-4">
                            <div class="flex justify-between items-center relative z-10">
                                <div class="w-12 h-12 rounded-2xl bg-teal-50 border border-teal-100 text-teal-600 flex items-center justify-center shadow-inner group-hover:scale-110 transition-transform duration-300">
                                    <i class="fa-solid fa-cart-shopping text-lg"></i>
                                </div>
                                <span class="px-2.5 py-1 rounded-full bg-teal-50 text-teal-700 text-[10px] font-black tracking-wider uppercase border border-teal-100">
                                    {{ $roleCounts['customer'] }} Registered
                                </span>
                            </div>
                            <div class="space-y-2">
                                <h3 class="text-lg font-bold text-slate-800">Customers</h3>
                                <p class="text-xs text-slate-500 leading-relaxed font-medium">Review standard platform consumers, verify identities, and manage account active/inactive statuses.</p>
                            </div>
                        </div>
                        <div class="mt-6 pt-4 border-t border-slate-50">
                            <a href="{{ route('admin.users.index', 'customer') }}" class="w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-slate-900 hover:bg-teal-600 text-white text-xs font-bold transition">
                                Inspect Customers
                                <i class="fa-solid fa-arrow-right text-[10px] group-hover:translate-x-1 transition-transform"></i>
                            </a>
                        </div>
                    </div>

                    <!-- 6. Admin -->
                    <div class="group bg-white rounded-3xl p-6 border border-slate-100 shadow-[0_2px_10px_-3px_rgba(6,81,237,0.03)] flex flex-col justify-between hover:shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:-translate-y-1.5 transition-all duration-300 relative overflow-hidden">
                        <div class="absolute -right-6 -top-6 w-24 h-24 bg-slate-100 rounded-full blur-2xl group-hover:bg-slate-200 transition-colors duration-500"></div>
                        <div class="space-y-4">
                            <div class="flex justify-between items-center relative z-10">
                                <div class="w-12 h-12 rounded-2xl bg-slate-100 border border-slate-200 text-slate-600 flex items-center justify-center shadow-inner group-hover:scale-110 transition-transform duration-300">
                                    <i class="fa-solid fa-user-shield text-lg"></i>
                                </div>
                                <span class="px-2.5 py-1 rounded-full bg-slate-100 text-slate-700 text-[10px] font-black tracking-wider uppercase border border-slate-200">
                                    {{ $roleCounts['admin'] }} Active
                                </span>
                            </div>
                            <div class="space-y-2">
                                <h3 class="text-lg font-bold text-slate-800">Administrators</h3>
                                <p class="text-xs text-slate-500 leading-relaxed font-medium">Manage administrative console access, update roles, and review security logs.</p>
                            </div>
                        </div>
                        <div class="mt-6 pt-4 border-t border-slate-50">
                            <a href="{{ route('admin.users.index', 'admin') }}" class="w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-slate-900 hover:bg-slate-700 text-white text-xs font-bold transition">
                                Inspect Admins
                                <i class="fa-solid fa-arrow-right text-[10px] group-hover:translate-x-1 transition-transform"></i>
                            </a>
                        </div>
                    </div>
                </section>
            </main>

            <x-admin-footer />
        </div>
    </div>

    <script>
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
                    setTimeout(() => overlay.classList.add('opacity-100'), 10);
                }
            }

            toggleBtn?.addEventListener('click', toggleSidebar);
            overlay?.addEventListener('click', toggleSidebar);
        });
    </script>
</body>
</html>
