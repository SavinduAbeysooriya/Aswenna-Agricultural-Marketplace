<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Aswenna - Reset Password</title>
    <!-- Tailwind CSS -->
    <script src="https://cdn.tailwindcss.com"></script>
    <!-- Alpine.js for lightweight state management -->
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
    <!-- SweetAlert2 for modern premium notifications -->
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <!-- Google Fonts: Inter & Poppins -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&family=Poppins:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
    <!-- FontAwesome icons -->
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
<body class="min-h-screen bg-slate-50 text-slate-800 antialiased flex flex-col justify-between overflow-x-hidden">

    <!-- Landing Header Component -->
    <x-landing-header />

    <!-- Main Content Container with Organic Accents -->
    <main class="flex-1 flex items-center justify-center pt-28 md:pt-36 pb-16 px-6 relative overflow-hidden">
        <!-- Background Leaf Blurs -->
        <div class="absolute -top-40 -right-40 w-96 h-96 bg-emerald-100/40 rounded-full blur-3xl pointer-events-none"></div>
        <div class="absolute -bottom-40 -left-40 w-96 h-96 bg-emerald-100/30 rounded-full blur-3xl pointer-events-none"></div>

        <div class="w-full max-w-md bg-white rounded-3xl p-8 border border-slate-100 shadow-xl relative z-10 space-y-6">
            <!-- Branding -->
            <div class="text-center space-y-2">
                <div class="w-14 h-14 bg-emerald-50 text-agri-deep rounded-2xl flex items-center justify-center text-2xl mx-auto shadow-md">
                    <i class="fa-solid fa-lock-open animate-pulse"></i>
                </div>
                <h2 class="text-2xl font-extrabold text-slate-800 tracking-tight mt-3">Reset Admin Password</h2>
                <p class="text-xs text-slate-400">Complete verification to register a new administrator key</p>
            </div>

            <!-- Context Info -->
            <div class="p-4 bg-emerald-50 border border-emerald-100 text-agri-dark rounded-2xl text-xs leading-relaxed font-semibold">
                <i class="fa-solid fa-circle-info mr-1.5 text-base"></i>
                <span>Please supply the recovery code sent to <strong>{{ session('reset_email') }}</strong> along with your new password.</span>
            </div>

            <!-- Error Alerts (Session validation errors) -->
            @if ($errors->any())
                <div class="p-3.5 bg-rose-50 border border-rose-100 text-rose-600 rounded-2xl text-xs font-semibold space-y-1">
                    @foreach ($errors->all() as $error)
                        <div class="flex items-center">
                            <i class="fa-solid fa-triangle-exclamation mr-2 text-sm"></i>
                            <span>{{ $error }}</span>
                        </div>
                    @endforeach
                </div>
            @endif

            <!-- Reset Password Form -->
            <form action="{{ route('admin.reset-password.submit') }}" method="POST" class="space-y-4">
                @csrf
                <div>
                    <label class="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Verification Code (6-Digits)</label>
                    <div class="relative">
                        <i class="fa-solid fa-key absolute left-4 top-3.5 text-slate-400 text-sm"></i>
                        <input type="text" name="otp" required maxlength="6" placeholder="000000" class="w-full pl-10 pr-4 py-3 bg-slate-50 border border-slate-200 focus:border-agri-deep focus:bg-white rounded-2xl text-sm focus:outline-none transition font-medium text-slate-800 tracking-wider">
                    </div>
                </div>

                <div>
                    <label class="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">New Password</label>
                    <div class="relative">
                        <i class="fa-solid fa-lock absolute left-4 top-3.5 text-slate-400 text-sm"></i>
                        <input type="password" name="password" required class="w-full pl-10 pr-4 py-3 bg-slate-50 border border-slate-200 focus:border-agri-deep focus:bg-white rounded-2xl text-sm focus:outline-none transition font-medium text-slate-800">
                    </div>
                </div>

                <div>
                    <label class="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Confirm New Password</label>
                    <div class="relative">
                        <i class="fa-solid fa-lock absolute left-4 top-3.5 text-slate-400 text-sm"></i>
                        <input type="password" name="password_confirmation" required class="w-full pl-10 pr-4 py-3 bg-slate-50 border border-slate-200 focus:border-agri-deep focus:bg-white rounded-2xl text-sm focus:outline-none transition font-medium text-slate-800">
                    </div>
                </div>

                <div class="pt-2">
                    <button type="submit" id="btn-reset-password" class="w-full py-4 bg-gradient-to-r from-agri-deep to-agri-fresh text-white rounded-2xl font-bold hover:shadow-lg hover:shadow-emerald-600/20 active:scale-[0.98] transition">
                        Reset Administrator Password
                    </button>
                </div>
            </form>
        </div>
    </main>

    <!-- Landing Footer Component -->
    <x-landing-footer />

    <!-- SweetAlert2 session notification listener -->
    @if (session('status'))
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            Swal.fire({
                icon: 'success',
                title: 'Success!',
                text: "{{ session('status') }}",
                confirmButtonColor: '#2E7D32'
            });
        });
    </script>
    @endif

    @if ($errors->any())
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            Swal.fire({
                icon: 'error',
                title: 'Reset Failed',
                html: `{!! implode('<br>', $errors->all()) !!}`,
                confirmButtonColor: '#2E7D32'
            });
        });
    </script>
    @endif

</body>
</html>
