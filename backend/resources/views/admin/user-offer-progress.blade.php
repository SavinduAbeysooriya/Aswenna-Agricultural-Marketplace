<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Aswenna - User Offer Progress</title>
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

            <main class="flex-1 p-4 sm:p-6 md:p-8 overflow-y-auto w-full max-w-[1700px] mx-auto">
                <section class="mb-8">
                    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
                        <div>
                            <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-slate-100 text-slate-700 text-[11px] font-extrabold uppercase tracking-widest border border-slate-200/50">
                                <i class="fa-solid fa-gift"></i>
                                Gamification / User Offer Progress
                            </div>
                            <h1 class="mt-3 text-2xl sm:text-3xl font-black tracking-tight text-slate-900 font-poppins">User Offer Progress Logs</h1>
                            <p class="mt-1 text-sm text-slate-500 font-medium">Monitor user interactions, campaign goals fulfillment status, and rewards claim history.</p>
                        </div>
                    </div>
                </section>

                <div class="bg-white border border-slate-100 rounded-3xl shadow-sm overflow-hidden">
                    <div class="overflow-x-auto">
                        <table class="min-w-full divide-y divide-slate-100 text-sm text-left">
                            <thead class="bg-slate-50 text-xs font-bold uppercase text-slate-400">
                                <tr>
                                    <th class="px-6 py-4">User</th>
                                    <th class="px-6 py-4">Campaign Code & Title</th>
                                    <th class="px-6 py-4">Goal Name</th>
                                    <th class="px-6 py-4">Fulfillment Status</th>
                                    <th class="px-6 py-4">Reward Claimed</th>
                                    <th class="px-6 py-4">Date Updated</th>
                                    <th class="px-6 py-4">Notes</th>
                                    <th class="px-6 py-4 text-right">Actions</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-slate-100 text-slate-700 font-semibold">
                                @forelse ($progressList as $progress)
                                    <tr class="hover:bg-slate-50/50 transition">
                                        <td class="px-6 py-4">
                                            <a href="{{ route('admin.users.profile', $progress->user_id) }}#tab-user-offer-progress" class="font-bold text-slate-900 hover:text-emerald-700 transition">
                                                {{ $progress->user_name }}
                                            </a>
                                            <div class="text-[10px] text-slate-400 font-bold uppercase tracking-wider mt-0.5">
                                                @php
                                                    $roles = is_string($progress->user_role) ? json_decode($progress->user_role, true) : $progress->user_role;
                                                    $rolesStr = is_array($roles) ? implode(', ', $roles) : $progress->user_role;
                                                @endphp
                                                {{ str_replace('_', ' ', $rolesStr) }}
                                            </div>
                                        </td>
                                        <td class="px-6 py-4">
                                            <span class="px-2 py-0.5 rounded text-[10px] bg-emerald-50 text-emerald-700 font-extrabold uppercase tracking-wide border border-emerald-100">
                                                {{ $progress->campaign_code }}
                                            </span>
                                            <div class="text-xs text-slate-500 mt-1 font-medium">{{ $progress->campaign_title }}</div>
                                        </td>
                                        <td class="px-6 py-4 text-xs font-medium text-slate-600">
                                            {{ $progress->goal_name ?: 'N/A' }}
                                        </td>
                                        <td class="px-6 py-4">
                                            @if ($progress->is_completed)
                                                <span class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-extrabold bg-emerald-50 text-emerald-700 border border-emerald-100">
                                                    <i class="fa-solid fa-circle-check text-[10px]"></i> Completed
                                                </span>
                                                @if ($progress->completed_at)
                                                    <div class="text-[10px] text-slate-400 mt-1 font-medium">{{ \Carbon\Carbon::parse($progress->completed_at)->format('Y-m-d H:i') }}</div>
                                                @endif
                                            @else
                                                <span class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-extrabold bg-amber-50 text-amber-700 border border-amber-100">
                                                    <i class="fa-solid fa-clock text-[10px]"></i> In Progress
                                                </span>
                                            @endif
                                        </td>
                                        <td class="px-6 py-4">
                                            @if ($progress->reward_claimed)
                                                <span class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-extrabold bg-emerald-50 text-emerald-700 border border-emerald-100">
                                                    <i class="fa-solid fa-gift text-[10px]"></i> Claimed
                                                </span>
                                                @if ($progress->reward_claimed_at)
                                                    <div class="text-[10px] text-slate-400 mt-1 font-medium">{{ \Carbon\Carbon::parse($progress->reward_claimed_at)->format('Y-m-d H:i') }}</div>
                                                @endif
                                            @else
                                                <span class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-extrabold bg-slate-50 text-slate-500 border border-slate-100">
                                                    <i class="fa-solid fa-circle-xmark text-[10px]"></i> Unclaimed
                                                </span>
                                            @endif
                                        </td>
                                        <td class="px-6 py-4 text-xs font-medium text-slate-500">
                                            {{ \Carbon\Carbon::parse($progress->updated_at)->format('Y-m-d H:i') }}
                                        </td>
                                        <td class="px-6 py-4 text-xs font-medium text-slate-550 max-w-[200px] truncate" title="{{ $progress->notes }}">
                                            {{ $progress->notes ?: '-' }}
                                        </td>
                                        <td class="px-6 py-4 text-right">
                                            <a href="{{ route('admin.users.profile', $progress->user_id) }}#tab-user-offer-progress" class="inline-flex items-center justify-center w-8 h-8 rounded-xl bg-slate-100 hover:bg-emerald-50 text-slate-600 hover:text-emerald-700 transition" title="Inspect Profile Tab">
                                                <i class="fa-solid fa-arrow-up-right-from-square text-xs"></i>
                                            </a>
                                        </td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="8" class="px-6 py-12 text-center text-slate-400">
                                            <i class="fa-solid fa-spinner text-3xl mb-3 animate-spin"></i>
                                            <p class="text-xs font-bold">No Offer Progress Records Recorded</p>
                                        </td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>

                    @if ($progressList->hasPages())
                        <div class="px-6 py-4 border-t border-slate-150 bg-slate-50/50">
                            {{ $progressList->links() }}
                        </div>
                    @endif
                </div>
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
