import { Camera, Save, X } from 'lucide-react';

export function ProfileEditScreen() {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#007A3D] to-[#005A2D] px-6 py-4 flex items-center justify-between">
        <button className="p-2 hover:bg-white/10 rounded-lg transition-colors">
          <X className="w-6 h-6 text-white" />
        </button>
        <h1 className="text-white">Edit Profile</h1>
        <button className="p-2 hover:bg-white/10 rounded-lg transition-colors">
          <Save className="w-6 h-6 text-white" />
        </button>
      </div>

      {/* Content */}
      <div className="px-6 py-8">
        {/* Avatar Section */}
        <div className="flex flex-col items-center mb-8">
          <div className="relative">
            <div className="w-32 h-32 rounded-full bg-gradient-to-br from-[#007A3D] to-[#FF6B35] flex items-center justify-center text-5xl shadow-xl">
              👤
            </div>
            <button className="absolute bottom-0 right-0 bg-[#FF6B35] text-white p-3 rounded-full shadow-lg hover:bg-[#FF5525] transition-colors">
              <Camera className="w-5 h-5" />
            </button>
          </div>
          <p className="text-gray-600 text-sm mt-3">Tap to change photo</p>
        </div>

        {/* Form Fields */}
        <div className="space-y-6">
          {/* Username */}
          <div>
            <label className="block text-gray-700 mb-2">Username</label>
            <input
              type="text"
              defaultValue="kofi_mensah"
              className="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-[#007A3D] outline-none transition-colors bg-white"
              placeholder="Enter username"
            />
          </div>

          {/* First Name */}
          <div>
            <label className="block text-gray-700 mb-2">First Name</label>
            <input
              type="text"
              defaultValue="Kofi"
              className="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-[#007A3D] outline-none transition-colors bg-white"
              placeholder="Enter first name"
            />
          </div>

          {/* Last Name */}
          <div>
            <label className="block text-gray-700 mb-2">Last Name</label>
            <input
              type="text"
              defaultValue="Mensah"
              className="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-[#007A3D] outline-none transition-colors bg-white"
              placeholder="Enter last name"
            />
          </div>

          {/* Email (Read-only) */}
          <div>
            <label className="block text-gray-700 mb-2">Email</label>
            <input
              type="email"
              defaultValue="kofi.mensah@email.com"
              className="w-full px-4 py-3 rounded-xl border-2 border-gray-200 bg-gray-100 text-gray-500 cursor-not-allowed"
              placeholder="Email"
              disabled
            />
            <p className="text-xs text-gray-500 mt-1">Email cannot be changed</p>
          </div>

          {/* Nationality */}
          <div>
            <label className="block text-gray-700 mb-2">Nationality</label>
            <div className="relative">
              <select className="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-[#007A3D] outline-none transition-colors bg-white appearance-none">
                <option>🇬🇭 Ghana</option>
                <option>🇳🇬 Nigeria</option>
                <option>🇰🇪 Kenya</option>
                <option>🇿🇦 South Africa</option>
                <option>🇪🇹 Ethiopia</option>
                <option>🇸🇳 Senegal</option>
              </select>
              <div className="absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none">
                <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                </svg>
              </div>
            </div>
          </div>

          {/* Bio */}
          <div>
            <label className="block text-gray-700 mb-2">Bio</label>
            <textarea
              rows={4}
              defaultValue="Passionate about learning African languages and connecting with cultures across the continent. 🌍"
              className="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-[#007A3D] outline-none transition-colors bg-white resize-none"
              placeholder="Tell us about yourself..."
            />
            <p className="text-xs text-gray-500 mt-1 text-right">120 characters</p>
          </div>
        </div>

        {/* Save Button */}
        <button className="w-full mt-8 bg-gradient-to-r from-[#007A3D] to-[#005A2D] text-white py-4 rounded-2xl shadow-lg hover:shadow-xl transition-all">
          Save Changes
        </button>

        {/* Cancel Button */}
        <button className="w-full mt-3 bg-white text-gray-600 py-4 rounded-2xl border-2 border-gray-200 hover:bg-gray-50 transition-all">
          Cancel
        </button>
      </div>
    </div>
  );
}
