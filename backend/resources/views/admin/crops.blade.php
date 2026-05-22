<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Aswenna - Crop Varieties</title>
    <link rel="icon" type="image/png" href="{{ asset('images/logo.png') }}">
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;950&family=Poppins:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    @livewireStyles
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
                <livewire:admin.crop-varieties-table />
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

        document.addEventListener('livewire:init', () => {
            Livewire.on('crop-saved', (event) => {
                Swal.fire({
                    icon: 'success',
                    title: 'Saved',
                    text: event.message || 'Crop variety updated.',
                    timer: 1800,
                    showConfirmButton: false,
                    customClass: {
                        popup: 'rounded-3xl shadow-2xl border border-slate-100'
                    }
                });
            });

            window.addEventListener('confirm-crop-delete', (event) => {
                const componentRoot = event.target?.closest?.('[wire\\:id]');
                const component = componentRoot ? Livewire.find(componentRoot.getAttribute('wire:id')) : null;

                Swal.fire({
                    icon: 'warning',
                    title: 'Remove crop?',
                    text: `This permanently removes ${event.detail.cropName || 'this crop'} from the crop table.`,
                    showCancelButton: true,
                    confirmButtonColor: '#e11d48',
                    cancelButtonColor: '#94a3b8',
                    confirmButtonText: 'Yes, remove',
                    cancelButtonText: 'Cancel',
                    customClass: {
                        popup: 'rounded-3xl shadow-2xl border border-slate-100',
                        confirmButton: 'rounded-xl font-bold shadow-md shadow-rose-500/20 px-6 py-2.5',
                        cancelButton: 'rounded-xl font-bold px-6 py-2.5'
                    }
                }).then((result) => {
                    if (result.isConfirmed && component) {
                        component.call('deleteCrop', event.detail.cropId);
                    }
                });
            });
        });
    </script>
    @livewireScripts
</body>
</html>
