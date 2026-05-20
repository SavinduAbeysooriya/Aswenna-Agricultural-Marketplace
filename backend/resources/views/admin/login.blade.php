<!DOCTYPE html>
<html lang="en" class="scroll-smooth">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Aswenna - Admin Sign In</title>
    <!-- Tailwind CSS -->
    <script src="https://cdn.tailwindcss.com"></script>
    <!-- Alpine.js for lightweight state management -->
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
    <!-- SweetAlert2 for modern premium notifications -->
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <!-- Google Identity Services (GIS) library for secure sign-in -->
    <script src="https://accounts.google.com/gsi/client" async defer></script>
    <!-- Google Fonts: Inter & Poppins -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&family=Poppins:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
    <!-- FontAwesome icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <script>
        function handleCredentialResponse(response) {
            const form = document.createElement('form');
            form.method = 'POST';
            form.action = "{{ route('admin.google.callback') }}";
            
            const csrfInput = document.createElement('input');
            csrfInput.type = 'hidden';
            csrfInput.name = '_token';
            csrfInput.value = "{{ csrf_token() }}";
            form.appendChild(csrfInput);
            
            const credentialInput = document.createElement('input');
            credentialInput.type = 'hidden';
            credentialInput.name = 'credential';
            credentialInput.value = response.credential;
            form.appendChild(credentialInput);
            
            document.body.appendChild(form);
            form.submit();
        }

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
                <div class="w-14 h-14 bg-agri-deep text-white rounded-2xl flex items-center justify-center text-2xl mx-auto shadow-md shadow-emerald-700/10">
                    <i class="fa-solid fa-shield-halved animate-pulse"></i>
                </div>
                <h2 class="text-2xl font-extrabold text-slate-800 tracking-tight mt-3">Aswenna Admin Portal</h2>
                <p class="text-xs text-slate-400">Secure Web-Based Platform Oversight System</p>
            </div>

            <!-- Success message -->
            @if (session('status'))
                <div class="p-3.5 bg-emerald-50 border border-emerald-100 text-agri-dark rounded-2xl text-xs font-semibold">
                    <i class="fa-solid fa-circle-check mr-2"></i> {{ session('status') }}
                </div>
            @endif

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

            <!-- Login Form -->
            <form action="{{ route('admin.login.submit') }}" method="POST" class="space-y-4">
                @csrf
                <div>
                    <label class="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Email Address</label>
                    <div class="relative">
                        <i class="fa-solid fa-envelope absolute left-4 top-3.5 text-slate-400 text-sm"></i>
                        <input type="email" name="email" required value="admin@aswenna.lk" class="w-full pl-10 pr-4 py-3 bg-slate-50 border border-slate-200 focus:border-agri-deep focus:bg-white rounded-2xl text-sm focus:outline-none transition font-medium text-slate-800">
                    </div>
                </div>
                <div>
                    <div class="flex justify-between items-center mb-2">
                        <label class="block text-xs font-bold text-slate-500 uppercase tracking-wider">Password</label>
                        <a href="{{ route('admin.forgot-password') }}" class="text-xs font-bold text-[#2E7D32] hover:underline">Forgot Password?</a>
                    </div>
                    <div class="relative">
                        <i class="fa-solid fa-lock absolute left-4 top-3.5 text-slate-400 text-sm"></i>
                        <input type="password" name="password" required value="adminpassword" class="w-full pl-10 pr-4 py-3 bg-slate-50 border border-slate-200 focus:border-agri-deep focus:bg-white rounded-2xl text-sm focus:outline-none transition font-medium text-slate-800">
                    </div>
                </div>

                <div class="flex items-center pt-1 pb-2">
                    <input id="remember" type="checkbox" name="remember" class="w-4 h-4 text-agri-deep bg-slate-50 border-slate-300 rounded focus:ring-agri-deep focus:ring-2 accent-[#2E7D32]">
                    <label for="remember" class="ml-2 text-xs font-bold text-slate-600 cursor-pointer">Remember me for 30 days</label>
                </div>

                <div class="pt-2">
                    <button type="submit" id="btn-web-login" class="w-full py-4 bg-gradient-to-r from-agri-deep to-agri-fresh text-white rounded-2xl font-bold hover:shadow-lg hover:shadow-emerald-600/20 active:scale-[0.98] transition">
                        Sign In to Console
                    </button>
                </div>
            </form>

            <!-- OR Divider -->
            <div class="relative flex py-2 items-center">
                <div class="flex-grow border-t border-slate-100"></div>
                <span class="flex-shrink mx-4 text-slate-400 text-[10px] font-bold uppercase tracking-wider">Or Continue With</span>
                <div class="flex-grow border-t border-slate-100"></div>
            </div>

            <!-- Google OAuth Sign In button wrapper -->
            <div class="w-full flex justify-center pt-1">
                <div id="g_id_onload"
                     data-client_id="{{ env('GOOGLE_CLIENT_ID') }}"
                     data-context="signin"
                     data-ux_mode="popup"
                     data-callback="handleCredentialResponse"
                     data-auto_select="false"
                     data-itp_support="true">
                </div>
                <div class="g_id_signin w-full"
                     data-type="standard"
                     data-shape="pill"
                     data-theme="outline"
                     data-text="signin_with"
                     data-size="large"
                     data-logo_alignment="left"
                     data-width="384">
                </div>
            </div>
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
                title: 'Authentication Error',
                html: `{!! implode('<br>', $errors->all()) !!}`,
                confirmButtonColor: '#2E7D32'
            });
        });
    </script>
    @endif

</body>
</html>
