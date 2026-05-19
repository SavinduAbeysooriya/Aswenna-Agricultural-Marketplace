<!DOCTYPE html>
<html lang="en" class="scroll-smooth">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Aswenna - Admin Sign In</title>
    <!-- Tailwind CSS -->
    <script src="https://cdn.tailwindcss.com"></script>
    <!-- Google Fonts: Inter -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
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
    <main class="flex-1 flex items-center justify-center py-16 px-6 relative overflow-hidden">
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
                    <label class="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Username / Phone Number</label>
                    <div class="relative">
                        <i class="fa-solid fa-user absolute left-4 top-3.5 text-slate-400 text-sm"></i>
                        <input type="text" name="username" required value="admin" class="w-full pl-10 pr-4 py-3 bg-slate-50 border border-slate-200 focus:border-agri-deep focus:bg-white rounded-2xl text-sm focus:outline-none transition font-medium text-slate-800">
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

                <div class="pt-2">
                    <button type="submit" id="btn-web-login" class="w-full py-4 bg-gradient-to-r from-agri-deep to-agri-fresh text-white rounded-2xl font-bold hover:shadow-lg hover:shadow-emerald-600/20 active:scale-[0.98] transition">
                        Sign In to Console
                    </button>
                </div>
            </form>
        </div>
    </main>

    <!-- Landing Footer Component -->
    <x-landing-footer />

</body>
</html>
