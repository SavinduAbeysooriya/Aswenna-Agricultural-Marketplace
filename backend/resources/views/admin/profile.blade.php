<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Aswenna - Admin Profile</title>
    <link rel="icon" type="image/png" href="{{ asset('images/logo.png') }}">
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;950&family=Poppins:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <!-- Google Maps JS SDK with Places Library -->
    <script src="https://maps.googleapis.com/maps/api/js?key={{ env('GOOGLE_MAPS_API_KEY') }}&libraries=places"></script>
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

            <main class="flex-1 p-4 sm:p-6 md:p-8 overflow-y-auto w-full max-w-[1100px] mx-auto space-y-6 md:space-y-8">
                
                <!-- Page Title -->
                <div class="flex items-center space-x-3.5 border-b border-slate-200 pb-5">
                    <div class="w-10 h-10 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center shadow-inner">
                        <i class="fa-solid fa-user-gear text-lg"></i>
                    </div>
                    <div>
                        <h2 class="text-xl font-extrabold text-slate-800 tracking-tight">Admin Profile Settings</h2>
                        <p class="text-xs text-slate-500 font-medium">Manage your personal credentials, contact points, location, avatar, and verify security documents</p>
                    </div>
                </div>

                <!-- Alert Banners -->
                @if(session('success'))
                    <div class="p-4 bg-emerald-50 border border-emerald-100 text-emerald-800 rounded-2xl text-xs font-bold flex items-center space-x-3 shadow-sm shadow-emerald-500/5">
                        <i class="fa-solid fa-circle-check text-base text-emerald-600"></i>
                        <span>{{ session('success') }}</span>
                    </div>
                @endif

                @if($errors->any())
                    <div class="p-4 bg-rose-50 border border-rose-100 text-rose-800 rounded-2xl text-xs font-bold space-y-1.5 shadow-sm shadow-rose-500/5">
                        <div class="flex items-center space-x-3">
                            <i class="fa-solid fa-circle-exclamation text-base text-rose-600"></i>
                            <span>Please fix the following validation errors:</span>
                        </div>
                        <ul class="list-disc list-inside pl-4 font-semibold text-rose-700">
                            @foreach($errors->all() as $error)
                                <li>{{ $error }}</li>
                            @endforeach
                        </ul>
                    </div>
                @endif

                <!-- Profile details form -->
                <form action="{{ route('admin.profile.update') }}" method="POST" enctype="multipart/form-data" class="space-y-6 md:space-y-8">
                    @csrf
                    
                    <!-- Top header card -->
                    <div class="bg-white rounded-3xl border border-slate-100 shadow-[0_2px_10px_-3px_rgba(6,81,237,0.03)] overflow-hidden">
                        <div class="p-6 sm:p-8 bg-gradient-to-r from-slate-50 to-white flex flex-col sm:flex-row items-center justify-between gap-6">
                            <div class="flex flex-col sm:flex-row items-center gap-5 text-center sm:text-left">
                                <div class="relative group">
                                    <div class="w-20 h-20 rounded-full bg-slate-900 text-white flex items-center justify-center font-extrabold text-2xl shadow-md border-4 border-white overflow-hidden">
                                        @if($user->profile_picture_path)
                                            <img id="avatar-preview" src="{{ asset('storage/' . $user->profile_picture_path) }}" alt="Avatar" class="w-full h-full object-cover">
                                        @else
                                            <div id="avatar-initial" class="w-full h-full flex items-center justify-center bg-slate-900 text-white">
                                                {{ substr($user->full_name ?? 'A', 0, 1) }}
                                            </div>
                                            <img id="avatar-preview" class="w-full h-full object-cover hidden">
                                        @endif
                                    </div>
                                    <label class="absolute inset-0 rounded-full bg-black/40 text-white flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity cursor-pointer text-[10px] font-bold">
                                        <i class="fa-solid fa-camera mr-1"></i> Upload
                                        <input type="file" name="profile_picture" onchange="previewAvatar(this)" class="hidden" accept="image/*">
                                    </label>
                                </div>
                                <div>
                                    <h3 class="text-sm font-extrabold text-slate-800 flex items-center justify-center sm:justify-start gap-1.5 leading-tight">
                                        {{ $user->full_name }}
                                        @if($user->is_verified)
                                            <span class="text-sky-500 text-xs" title="Verified Administrator Profile">
                                                <i class="fa-solid fa-circle-check"></i>
                                            </span>
                                        @endif
                                    </h3>
                                    <div class="flex flex-wrap items-center justify-center sm:justify-start gap-2 mt-1">
                                        <span class="text-[10px] font-bold text-emerald-600 bg-emerald-50 border border-emerald-100 px-2 py-0.5 rounded-full inline-block">Super Administrator</span>
                                        @if($user->is_verified)
                                            <span class="text-[10px] font-bold text-emerald-700 bg-emerald-50 border border-emerald-200 px-2 py-0.5 rounded-full flex items-center gap-1">
                                                <i class="fa-solid fa-shield-check text-[10px]"></i> Verified Profile
                                            </span>
                                        @else
                                            <span class="text-[10px] font-bold text-amber-700 bg-amber-50 border border-amber-100 px-2 py-0.5 rounded-full flex items-center gap-1">
                                                <i class="fa-solid fa-triangle-exclamation text-[10px]"></i> Unverified Profile
                                            </span>
                                        @endif
                                    </div>
                                </div>
                            </div>
                            <div class="flex flex-col items-end gap-1 text-right">
                                <span class="text-[10px] text-slate-400 font-bold">Account ID: #{{ $user->id }}</span>
                                <span class="text-[10px] text-slate-400 font-semibold">Registered: {{ \Carbon\Carbon::parse($user->created_at)->format('Y-M-d') }}</span>
                            </div>
                        </div>
                    </div>

                    <!-- Left/Right Form Columns -->
                    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 md:gap-8 items-start">
                        
                        <!-- Col 1 & 2: Forms and locations -->
                        <div class="lg:col-span-2 space-y-6 md:space-y-8">
                            
                            <!-- Basic details card -->
                            <div class="bg-white rounded-3xl p-6 sm:p-8 border border-slate-100 shadow-[0_2px_10px_-3px_rgba(6,81,237,0.03)] space-y-6">
                                <h4 class="text-xs font-black text-slate-400 uppercase tracking-widest border-b border-slate-50 pb-2">Profile Details</h4>
                                <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
                                    <div class="space-y-1.5">
                                        <label class="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">Full Name</label>
                                        <div class="relative">
                                            <i class="fa-solid fa-user absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 text-sm"></i>
                                            <input type="text" name="full_name" required value="{{ old('full_name', $user->full_name) }}" class="w-full pl-11 pr-4 py-3 rounded-xl border border-slate-200 text-xs font-semibold text-slate-700 focus:outline-none focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 transition-all">
                                        </div>
                                    </div>
                                    <div class="space-y-1.5">
                                        <label class="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">Email Address</label>
                                        <div class="relative">
                                            <i class="fa-solid fa-envelope absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 text-sm"></i>
                                            <input type="email" name="email" required value="{{ old('email', $user->email) }}" class="w-full pl-11 pr-4 py-3 rounded-xl border border-slate-200 text-xs font-semibold text-slate-700 focus:outline-none focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 transition-all">
                                        </div>
                                    </div>
                                    <div class="space-y-1.5">
                                        <label class="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">Primary Phone</label>
                                        <div class="relative">
                                            <i class="fa-solid fa-phone absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 text-sm"></i>
                                            <input type="text" name="phone_number" value="{{ old('phone_number', $user->phone_number) }}" placeholder="+94 7X XXX XXXX" class="w-full pl-11 pr-4 py-3 rounded-xl border border-slate-200 text-xs font-semibold text-slate-700 focus:outline-none focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 transition-all">
                                        </div>
                                    </div>
                                    <div class="space-y-1.5">
                                        <label class="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">Secondary Phone</label>
                                        <div class="relative">
                                            <i class="fa-solid fa-phone absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 text-sm"></i>
                                            <input type="text" name="phone_number_2" value="{{ old('phone_number_2', $user->phone_number_2) }}" placeholder="Optional line" class="w-full pl-11 pr-4 py-3 rounded-xl border border-slate-200 text-xs font-semibold text-slate-700 focus:outline-none focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 transition-all">
                                        </div>
                                    </div>
                                    <div class="space-y-1.5 sm:col-span-2">
                                        <label class="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">National ID / NIC</label>
                                        <div class="relative">
                                            <i class="fa-solid fa-address-card absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 text-sm"></i>
                                            <input type="text" name="national_id" value="{{ old('national_id', $user->national_id) }}" placeholder="e.g. 1999XXXXXXXX / XXXXXXXXv" class="w-full pl-11 pr-4 py-3 rounded-xl border border-slate-200 text-xs font-semibold text-slate-700 focus:outline-none focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 transition-all">
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Location details card -->
                            <div class="bg-white rounded-3xl p-6 sm:p-8 border border-slate-100 shadow-[0_2px_10px_-3px_rgba(6,81,237,0.03)] space-y-6">
                                <h4 class="text-xs font-black text-slate-400 uppercase tracking-widest border-b border-slate-50 pb-2">Address & Location</h4>
                                <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
                                    <div class="space-y-1.5 sm:col-span-2">
                                        <label class="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">Home / Office Address</label>
                                        <div class="relative">
                                            <i class="fa-solid fa-location-dot absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 text-sm"></i>
                                            <input type="text" name="address" value="{{ old('address', $user->address) }}" placeholder="Street address details..." class="w-full pl-11 pr-4 py-3 rounded-xl border border-slate-200 text-xs font-semibold text-slate-700 focus:outline-none focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 transition-all">
                                        </div>
                                    </div>
                                    <div class="space-y-1.5">
                                        <label class="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">Province</label>
                                        <select id="province-select" onchange="onProvinceChange()" class="w-full px-4 py-3 rounded-xl border border-slate-200 text-xs font-semibold text-slate-700 focus:outline-none focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 transition-all">
                                            <option value="">Select Province</option>
                                        </select>
                                        <input type="text" name="province" id="province-manual" value="{{ old('province', $user->province) }}" placeholder="Enter Province Manually" class="hidden mt-2 w-full px-4 py-3 rounded-xl border border-slate-200 text-xs font-semibold text-slate-700 focus:outline-none focus:border-emerald-500 transition-all">
                                    </div>
                                    <div class="space-y-1.5">
                                        <label class="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">District</label>
                                        <select id="district-select" onchange="onDistrictChange()" class="w-full px-4 py-3 rounded-xl border border-slate-200 text-xs font-semibold text-slate-700 focus:outline-none focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 transition-all">
                                            <option value="">Select District</option>
                                        </select>
                                        <input type="text" name="district" id="district-manual" value="{{ old('district', $user->district) }}" placeholder="Enter District Manually" class="hidden mt-2 w-full px-4 py-3 rounded-xl border border-slate-200 text-xs font-semibold text-slate-700 focus:outline-none focus:border-emerald-500 transition-all">
                                    </div>
                                    <div class="space-y-1.5">
                                        <label class="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">City</label>
                                        <select id="city-select" onchange="onCityChange()" class="w-full px-4 py-3 rounded-xl border border-slate-200 text-xs font-semibold text-slate-700 focus:outline-none focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 transition-all">
                                            <option value="">Select City</option>
                                        </select>
                                        <input type="text" name="city" id="city-manual" value="{{ old('city', $user->city) }}" placeholder="Enter City Manually" class="hidden mt-2 w-full px-4 py-3 rounded-xl border border-slate-200 text-xs font-semibold text-slate-700 focus:outline-none focus:border-emerald-500 transition-all">
                                    </div>
                                    <div class="space-y-1.5 sm:col-span-2">
                                        <label class="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">Map Search & Geolocation Location</label>
                                        <div class="flex space-x-2">
                                            <input type="text" id="map-search-input" placeholder="Type city or area to locate on map..." class="flex-1 px-4 py-3 rounded-xl border border-slate-200 text-xs font-semibold text-slate-700 focus:outline-none focus:border-emerald-500 transition-all">
                                            <button type="button" onclick="searchMapLocation()" class="px-5 py-3 bg-slate-800 text-white font-bold rounded-xl text-xs hover:bg-slate-900 transition-all active:scale-95">Search Map</button>
                                        </div>
                                    </div>
                                    <div class="space-y-1.5 sm:col-span-2">
                                        <div id="map" class="h-64 rounded-2xl border border-slate-200 overflow-hidden shadow-inner z-10"></div>
                                    </div>
                                    <div class="space-y-1.5 sm:col-span-2">
                                        <label class="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">Coordinates (Lat / Long)</label>
                                        <div class="grid grid-cols-2 gap-4">
                                            <div class="space-y-1">
                                                <span class="text-[9px] text-slate-400 font-bold block">Latitude</span>
                                                <input type="text" name="latitude" id="latitude" value="{{ old('latitude', $user->latitude) }}" placeholder="Latitude" class="w-full px-4 py-3 rounded-xl border border-slate-200 text-xs font-semibold text-slate-700 focus:outline-none focus:border-emerald-500 transition-all">
                                            </div>
                                            <div class="space-y-1">
                                                <span class="text-[9px] text-slate-400 font-bold block">Longitude</span>
                                                <input type="text" name="longitude" id="longitude" value="{{ old('longitude', $user->longitude) }}" placeholder="Longitude" class="w-full px-4 py-3 rounded-xl border border-slate-200 text-xs font-semibold text-slate-700 focus:outline-none focus:border-emerald-500 transition-all">
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Col 3: Side Info (Password reset & Verification Documents display) -->
                        <div class="space-y-6 md:space-y-8">
                            
                            <!-- Security card -->
                            <div class="bg-white rounded-3xl p-6 border border-slate-100 shadow-[0_2px_10px_-3px_rgba(6,81,237,0.03)] space-y-6">
                                <h4 class="text-xs font-black text-slate-400 uppercase tracking-widest border-b border-slate-50 pb-2">Change Password</h4>
                                <div class="space-y-4">
                                    <div class="space-y-1.5">
                                        <label class="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">Current Password</label>
                                        <input type="password" name="current_password" placeholder="••••••••" class="w-full px-4 py-2.5 rounded-xl border border-slate-200 text-xs font-semibold text-slate-700 focus:outline-none focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 transition-all">
                                    </div>
                                    <div class="space-y-1.5">
                                        <label class="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">New Password</label>
                                        <input type="password" name="new_password" placeholder="Min 6 chars" class="w-full px-4 py-2.5 rounded-xl border border-slate-200 text-xs font-semibold text-slate-700 focus:outline-none focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 transition-all">
                                    </div>
                                    <div class="space-y-1.5">
                                        <label class="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">Confirm Password</label>
                                        <input type="password" name="new_password_confirmation" placeholder="••••••••" class="w-full px-4 py-2.5 rounded-xl border border-slate-200 text-xs font-semibold text-slate-700 focus:outline-none focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 transition-all">
                                    </div>
                                </div>
                            </div>

                            <!-- Verification Docs Display -->
                            <div class="bg-white rounded-3xl p-6 border border-slate-100 shadow-[0_2px_10px_-3px_rgba(6,81,237,0.03)] space-y-6">
                                <h4 class="text-xs font-black text-slate-400 uppercase tracking-widest border-b border-slate-50 pb-2">Verification Vault</h4>
                                <div id="verification-docs-container" class="space-y-4">
                                    @forelse($verificationDocs as $doc)
                                    <div class="p-4 bg-slate-50 border border-slate-100 rounded-2xl space-y-3">
                                        <div class="flex justify-between items-center">
                                            <span class="text-xs font-bold text-slate-700 uppercase">{{ str_replace('_', ' ', $doc->document_type) }}</span>
                                            <span class="px-2 py-0.5 rounded text-[9px] font-extrabold uppercase border
                                                @if($doc->verification_status === 'approved') bg-emerald-50 text-emerald-700 border-emerald-100
                                                @elseif($doc->verification_status === 'pending') bg-amber-50 text-amber-700 border-amber-100
                                                @else bg-rose-50 text-rose-700 border-rose-100
                                                @endif
                                            ">{{ $doc->verification_status }}</span>
                                        </div>
                                        
                                        <!-- Images preview -->
                                        <div class="grid grid-cols-2 gap-2">
                                            @if($doc->front_image_path)
                                            <a href="{{ asset('storage/' . $doc->front_image_path) }}" target="_blank" class="block border border-slate-200 rounded-xl overflow-hidden bg-white hover:opacity-90 transition-all shadow-sm">
                                                <img src="{{ asset('storage/' . $doc->front_image_path) }}" alt="Front" class="w-full h-16 object-cover">
                                                <span class="text-[8px] text-slate-400 font-bold block text-center py-1 bg-slate-50">Front View</span>
                                            </a>
                                            @endif
                                            @if($doc->back_image_path)
                                            <a href="{{ asset('storage/' . $doc->back_image_path) }}" target="_blank" class="block border border-slate-200 rounded-xl overflow-hidden bg-white hover:opacity-90 transition-all shadow-sm">
                                                <img src="{{ asset('storage/' . $doc->back_image_path) }}" alt="Back" class="w-full h-16 object-cover">
                                                <span class="text-[8px] text-slate-400 font-bold block text-center py-1 bg-slate-50">Back View</span>
                                            </a>
                                            @endif
                                        </div>

                                        @if($doc->rejection_reason)
                                        <p class="text-[10px] text-rose-600 bg-rose-50 p-2 rounded-lg border border-rose-100 font-medium">Reason: {{ $doc->rejection_reason }}</p>
                                        @endif
                                    </div>
                                    @empty
                                    <div class="flex flex-col items-center justify-center py-6 text-slate-400 text-center space-y-2">
                                        <div class="w-10 h-10 rounded-full bg-slate-50 flex items-center justify-center text-slate-300">
                                            <i class="fa-solid fa-folder-open text-base"></i>
                                        </div>
                                        <p class="text-[10px] font-bold">No verification documents uploaded</p>
                                    </div>
                                    @endforelse
                                </div>

                                <!-- Upload new document form controls -->
                                <div class="border-t border-slate-100 pt-5 space-y-4">
                                    <h5 class="text-[10px] font-black uppercase text-slate-400 tracking-wider">Upload New Document</h5>
                                    <div class="space-y-3 text-xs">
                                        <div class="space-y-1.5">
                                            <span class="text-[9px] text-slate-400 font-bold block">Document Type</span>
                                            <select name="verification_document_type" id="verification_document_type" onchange="toggleBackImageUpload()" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-xs font-semibold text-slate-700 focus:outline-none focus:border-emerald-500">
                                                <option value="">Select Type</option>
                                                <option value="national_id">National ID / NIC</option>
                                             
                                                <option value="driving_license">Driving License</option>
       
                                            </select>
                                        </div>
                                        <div class="space-y-1.5">
                                            <span class="text-[9px] text-slate-400 font-bold block">Front Image</span>
                                            <input type="file" name="verification_front_image" accept="image/*" class="w-full text-slate-500 font-semibold file:mr-3 file:py-1.5 file:px-3 file:rounded-lg file:border-0 file:text-[10px] file:font-extrabold file:bg-slate-100 file:text-slate-700 hover:file:bg-slate-200 file:cursor-pointer">
                                        </div>
                                        <div class="space-y-1.5" id="back-image-upload-wrapper">
                                            <span class="text-[9px] text-slate-400 font-bold block">Back Image</span>
                                            <input type="file" name="verification_back_image" accept="image/*" class="w-full text-slate-500 font-semibold file:mr-3 file:py-1.5 file:px-3 file:rounded-lg file:border-0 file:text-[10px] file:font-extrabold file:bg-slate-100 file:text-slate-700 hover:file:bg-slate-200 file:cursor-pointer">
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Form Submission Trigger -->
                    <div class="flex justify-end pt-4 border-t border-slate-100">
                        <button type="submit" class="px-8 py-3 bg-gradient-to-b from-emerald-500 to-emerald-600 hover:to-emerald-700 text-white rounded-xl text-xs font-bold shadow-md shadow-emerald-500/20 transition-all active:scale-95">
                            Save Settings Profile
                        </button>
                    </div>
                </form>
            </main>

            <x-admin-footer />
        </div>
    </div>

    <!-- Script to handle avatar previews and sidebar controls -->
    <script>
        const locationData = {
            "Western": {
                "Colombo": ["Colombo", "Dehiwala-Mount Lavinia", "Moratuwa", "Kotte", "Battaramulla", "Kolonnawa", "Kaduwela", "Hanwella", "Homagama", "Maharagama", "Kesbewa", "Avissawella"],
                "Gampaha": ["Gampaha", "Negombo", "Katunayake", "Veyangoda", "Minuwangoda", "Kadawatha", "Kiribathgoda", "Ragama", "Ja-Ela", "Wattala", "Kelaniya"],
                "Kalutara": ["Kalutara", "Panadura", "Horana", "Aluthgama", "Bandaragama", "Wadduwa", "Beruwala", "Matugama"]
            },
            "Central": {
                "Kandy": ["Kandy", "Gampola", "Nawalapitiya", "Peradeniya", "Katugastota", "Kundasale", "Gelioya", "Pilimathalawa"],
                "Matale": ["Matale", "Dambulla", "Sigiriya", "Ukuwela", "Yatawatta", "Galewela"],
                "Nuwara Eliya": ["Nuwara Eliya", "Hatton", "Talawakele", "Ginigathena", "Walapane", "Hanguranketha"]
            },
            "Southern": {
                "Galle": ["Galle", "Ambalangoda", "Hikkaduwa", "Elpitiya", "Karapitiya", "Bentota", "Baddegama"],
                "Matara": ["Matara", "Weligama", "Dickwella", "Devinuwara", "Deniyaya", "Hakmana"],
                "Hambantota": ["Hambantota", "Tangalle", "Beliatta", "Ambalantota", "Tissamaharama"]
            },
            "Northern": {
                "Jaffna": ["Jaffna", "Chavakachcheri", "Point Pedro", "Nallur", "Karainagar"],
                "Kilinochchi": ["Kilinochchi", "Pooneryn", "Pallai"],
                "Mannar": ["Mannar", "Murunkan", "Madhu"],
                "Vavuniya": ["Vavuniya", "Nedunkeni", "Cheddikulam"],
                "Mullaitivu": ["Mullaitivu", "Oddusuddan", "Puthukkudiyiruppu"]
            },
            "Eastern": {
                "Trincomalee": ["Trincomalee", "Mutur", "Kinniya", "Kantale"],
                "Batticaloa": ["Batticaloa", "Kattankudy", "Eravur", "Valachchenai"],
                "Ampara": ["Ampara", "Kalmunai", "Sainthamaruthu", "Akkaraipattu", "Sammanthurai"]
            },
            "North Western": {
                "Kurunegala": ["Kurunegala", "Kuliyapitiya", "Narammala", "Wariyapola", "Pannala", "Maho", "Ibbagamuwa"],
                "Puttalam": ["Puttalam", "Chilaw", "Marawila", "Wennappuwa", "Dankotuwa", "Kalpitiya"]
            },
            "North Central": {
                "Anuradhapura": ["Anuradhapura", "Mihintale", "Medawachchiya", "Kekirawa", "Eppawala", "Tambuttegama"],
                "Polonnaruwa": ["Polonnaruwa", "Kaduruwela", "Hingurakgoda", "Medirigiriya"]
            },
            "Uva": {
                "Badulla": ["Badulla", "Bandarawela", "Hali-Ela", "Diyatalawa", "Ella", "Welimada", "Passara"],
                "Moneragala": ["Moneragala", "Wellawaya", "Bibile", "Kataragama", "Buttala"]
            },
            "Sabaragamuwa": {
                "Ratnapura": ["Ratnapura", "Balangoda", "Embilipitiya", "Pelmadulla", "Kuruwita"],
                "Kegalle": ["Kegalle", "Mawanella", "Rambukkana", "Warakapola", "Dehiowita", "Ruwanwella"]
            }
        };

        function previewAvatar(input) {
            if (input.files && input.files[0]) {
                const reader = new FileReader();
                reader.onload = function(e) {
                    const preview = document.getElementById('avatar-preview');
                    const initial = document.getElementById('avatar-initial');
                    preview.src = e.target.result;
                    preview.classList.remove('hidden');
                    if (initial) initial.classList.add('hidden');
                }
                reader.readAsDataURL(input.files[0]);
            }
        }

        function initLocations() {
            const provinceSelect = document.getElementById('province-select');
            const provinceManual = document.getElementById('province-manual');
            const initialProvince = provinceManual.value;

            provinceSelect.innerHTML = '<option value="">Select Province</option>';
            Object.keys(locationData).forEach(p => {
                provinceSelect.innerHTML += `<option value="${p}">${p}</option>`;
            });
            provinceSelect.innerHTML += '<option value="other">Other / Manual Entry</option>';

            if (initialProvince) {
                if (locationData[initialProvince]) {
                    provinceSelect.value = initialProvince;
                    provinceManual.classList.add('hidden');
                } else {
                    provinceSelect.value = 'other';
                    provinceManual.classList.remove('hidden');
                }
            }
            populateDistricts();
        }

        function populateDistricts() {
            const provinceSelect = document.getElementById('province-select');
            const districtSelect = document.getElementById('district-select');
            const districtManual = document.getElementById('district-manual');
            const selectedProvince = provinceSelect.value;
            const initialDistrict = districtManual.value;

            districtSelect.innerHTML = '<option value="">Select District</option>';

            if (selectedProvince && selectedProvince !== 'other') {
                Object.keys(locationData[selectedProvince]).forEach(d => {
                    districtSelect.innerHTML += `<option value="${d}">${d}</option>`;
                });
                districtSelect.innerHTML += '<option value="other">Other / Manual Entry</option>';
                districtSelect.disabled = false;

                if (initialDistrict) {
                    if (locationData[selectedProvince][initialDistrict]) {
                        districtSelect.value = initialDistrict;
                        districtManual.classList.add('hidden');
                    } else {
                        districtSelect.value = 'other';
                        districtManual.classList.remove('hidden');
                    }
                }
            } else {
                if (selectedProvince === 'other') {
                    districtSelect.innerHTML += '<option value="other">Other / Manual Entry</option>';
                    districtSelect.value = 'other';
                    districtSelect.disabled = true;
                    districtManual.classList.remove('hidden');
                } else {
                    districtSelect.disabled = true;
                    districtManual.classList.add('hidden');
                }
            }
            populateCities();
        }

        function populateCities() {
            const provinceSelect = document.getElementById('province-select');
            const districtSelect = document.getElementById('district-select');
            const citySelect = document.getElementById('city-select');
            const cityManual = document.getElementById('city-manual');
            const selectedProvince = provinceSelect.value;
            const selectedDistrict = districtSelect.value;
            const initialCity = cityManual.value;

            citySelect.innerHTML = '<option value="">Select City</option>';

            if (selectedProvince && selectedProvince !== 'other' && selectedDistrict && selectedDistrict !== 'other') {
                const citiesList = locationData[selectedProvince][selectedDistrict] || [];
                citiesList.forEach(c => {
                    citySelect.innerHTML += `<option value="${c}">${c}</option>`;
                });
                citySelect.innerHTML += '<option value="other">Other / Manual Entry</option>';
                citySelect.disabled = false;

                if (initialCity) {
                    if (citiesList.includes(initialCity)) {
                        citySelect.value = initialCity;
                        cityManual.classList.add('hidden');
                    } else {
                        citySelect.value = 'other';
                        cityManual.classList.remove('hidden');
                    }
                }
            } else {
                if (selectedProvince === 'other' || selectedDistrict === 'other') {
                    citySelect.innerHTML += '<option value="other">Other / Manual Entry</option>';
                    citySelect.value = 'other';
                    citySelect.disabled = true;
                    cityManual.classList.remove('hidden');
                } else {
                    citySelect.disabled = true;
                    cityManual.classList.add('hidden');
                }
            }
        }

        function onProvinceChange() {
            const provinceSelect = document.getElementById('province-select');
            const provinceManual = document.getElementById('province-manual');
            
            if (provinceSelect.value === 'other') {
                provinceManual.value = '';
                provinceManual.classList.remove('hidden');
            } else {
                provinceManual.value = provinceSelect.value;
                provinceManual.classList.add('hidden');
            }

            document.getElementById('district-manual').value = '';
            document.getElementById('city-manual').value = '';
            populateDistricts();
        }

        function onDistrictChange() {
            const districtSelect = document.getElementById('district-select');
            const districtManual = document.getElementById('district-manual');

            if (districtSelect.value === 'other') {
                districtManual.value = '';
                districtManual.classList.remove('hidden');
            } else {
                districtManual.value = districtSelect.value;
                districtManual.classList.add('hidden');
            }

            document.getElementById('city-manual').value = '';
            populateCities();
        }

        function onCityChange() {
            const citySelect = document.getElementById('city-select');
            const cityManual = document.getElementById('city-manual');

            if (citySelect.value === 'other') {
                cityManual.value = '';
                cityManual.classList.remove('hidden');
            } else {
                cityManual.value = citySelect.value;
                cityManual.classList.add('hidden');
            }
        }

        var map, marker;

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

            // Initialize Cascading dropdowns
            initLocations();

            // Initialize Google Map
            var initLat = parseFloat(document.getElementById('latitude').value) || 7.8731;
            var initLng = parseFloat(document.getElementById('longitude').value) || 80.7718;
            var hasCoords = document.getElementById('latitude').value && document.getElementById('longitude').value;

            var mapOptions = {
                center: { lat: initLat, lng: initLng },
                zoom: hasCoords ? 14 : 7,
                mapTypeControl: false,
                fullscreenControl: false,
                streetViewControl: false
            };

            map = new google.maps.Map(document.getElementById('map'), mapOptions);

            marker = new google.maps.Marker({
                position: { lat: initLat, lng: initLng },
                map: map,
                draggable: true
            });

            // Update Lat/Long inputs when marker is dragged
            marker.addListener('dragend', function() {
                var position = marker.getPosition();
                updateCoordsInputs(position.lat(), position.lng());
            });

            // Update marker and inputs when map is clicked
            map.addListener('click', function(e) {
                marker.setPosition(e.latLng);
                updateCoordsInputs(e.latLng.lat(), e.latLng.lng());
            });

            // Manually entering coordinates changes map
            document.getElementById('latitude').addEventListener('input', syncMapFromInputs);
            document.getElementById('longitude').addEventListener('input', syncMapFromInputs);

            // Google Places Autocomplete
            var searchInput = document.getElementById('map-search-input');
            var autocomplete = new google.maps.places.Autocomplete(searchInput);
            autocomplete.bindTo('bounds', map);

            autocomplete.addListener('place_changed', function() {
                var place = autocomplete.getPlace();
                if (!place.geometry || !place.geometry.location) {
                    return;
                }

                if (place.geometry.viewport) {
                    map.fitBounds(place.geometry.viewport);
                } else {
                    map.setCenter(place.geometry.location);
                    map.setZoom(17);
                }

                marker.setPosition(place.geometry.location);
                updateCoordsInputs(place.geometry.location.lat(), place.geometry.location.lng());
            });

            // Initialize document upload wrapper visibility
            toggleBackImageUpload();
        });

        function updateCoordsInputs(lat, lng) {
            document.getElementById('latitude').value = parseFloat(lat).toFixed(8);
            document.getElementById('longitude').value = parseFloat(lng).toFixed(8);
        }

        function syncMapFromInputs() {
            var lat = parseFloat(document.getElementById('latitude').value);
            var lng = parseFloat(document.getElementById('longitude').value);
            if (!isNaN(lat) && !isNaN(lng)) {
                var newPos = { lat: lat, lng: lng };
                marker.setPosition(newPos);
                map.setCenter(newPos);
                map.setZoom(14);
            }
        }

        function searchMapLocation() {
            var query = document.getElementById('map-search-input').value;
            if (!query || query.trim() === '') return;

            var geocoder = new google.maps.Geocoder();
            geocoder.geocode({ address: query }, function(results, status) {
                if (status === 'OK' && results[0] && results[0].geometry) {
                    var loc = results[0].geometry.location;
                    map.setCenter(loc);
                    map.setZoom(14);
                    marker.setPosition(loc);
                    updateCoordsInputs(loc.lat(), loc.lng());
                } else {
                    Swal.fire({
                        icon: 'warning',
                        title: 'Location Not Found',
                        text: 'Google Maps could not locate the requested address.',
                        confirmButtonColor: '#10b981',
                        customClass: {
                            popup: 'rounded-3xl border border-slate-100 shadow-xl'
                        }
                    });
                }
            });
        }

        function toggleBackImageUpload() {
            const docType = document.getElementById('verification_document_type').value;
            const backWrapper = document.getElementById('back-image-upload-wrapper');
            if (docType === 'national_id' || docType === 'driving_license') {
                backWrapper.classList.remove('hidden');
            } else {
                backWrapper.classList.add('hidden');
            }
        }
    </script>
</body>
</html>
