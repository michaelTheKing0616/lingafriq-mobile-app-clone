import React from 'react';
import { ArrowLeft, Camera, Save, X } from 'lucide-react';

export function ProfileEditScreen() {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#007A3D] to-[#005A2D] px-6 py-6 shadow-lg">
        <div className="flex items-center gap-4">
          <button className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
            <ArrowLeft className="w-5 h-5 text-white" />
          </button>
          <h1 className="text-white flex-1">Edit Profile</h1>
          <button className="text-white">
            <X className="w-6 h-6" />
          </button>
        </div>
      </div>

      {/* Content */}
      <div className="px-6 py-8">
        {/* Avatar Upload */}
        <div className="flex justify-center mb-8">
          <div className="relative">
            <div className="w-32 h-32 bg-gradient-to-br from-[#007A3D] to-[#005A2D] rounded-full flex items-center justify-center">
              <span className="text-5xl">👤</span>
            </div>
            <button className="absolute bottom-0 right-0 w-10 h-10 bg-[#FCD116] rounded-full flex items-center justify-center shadow-lg">
              <Camera className="w-5 h-5 text-gray-800" />
            </button>
          </div>
        </div>

        {/* Form Fields */}
        <div className="space-y-5">
          {/* Username */}
          <div>
            <label className="block text-gray-700 mb-2">Username</label>
            <input
              type="text"
              defaultValue="SwahiliLearner2024"
              className="w-full px-4 py-3 border-2 border-gray-200 rounded-xl focus:border-[#007A3D] focus:outline-none transition-colors"
            />
          </div>

          {/* First Name */}
          <div>
            <label className="block text-gray-700 mb-2">First Name</label>
            <input
              type="text"
              defaultValue="Amani"
              className="w-full px-4 py-3 border-2 border-gray-200 rounded-xl focus:border-[#007A3D] focus:outline-none transition-colors"
            />
          </div>

          {/* Last Name */}
          <div>
            <label className="block text-gray-700 mb-2">Last Name</label>
            <input
              type="text"
              defaultValue="Okonkwo"
              className="w-full px-4 py-3 border-2 border-gray-200 rounded-xl focus:border-[#007A3D] focus:outline-none transition-colors"
            />
          </div>

          {/* Email (Read-only) */}
          <div>
            <label className="block text-gray-700 mb-2">Email</label>
            <input
              type="email"
              defaultValue="amani.okonkwo@example.com"
              readOnly
              className="w-full px-4 py-3 border-2 border-gray-200 rounded-xl bg-gray-100 text-gray-500 cursor-not-allowed"
            />
            <p className="text-gray-500 text-xs mt-1">Email cannot be changed</p>
          </div>

          {/* Nationality */}
          <div>
            <label className="block text-gray-700 mb-2">Nationality</label>
            <select className="w-full px-4 py-3 border-2 border-gray-200 rounded-xl focus:border-[#007A3D] focus:outline-none transition-colors appearance-none bg-white">
              <option>🇳🇬 Nigeria</option>
              <option>🇰🇪 Kenya</option>
              <option>🇿🇦 South Africa</option>
              <option>🇬🇭 Ghana</option>
              <option>🇪🇹 Ethiopia</option>
              <option>🇹🇿 Tanzania</option>
            </select>
          </div>

          {/* Bio */}
          <div>
            <label className="block text-gray-700 mb-2">Bio</label>
            <textarea
              rows={4}
              defaultValue="Passionate about learning African languages and connecting with my heritage. Love Swahili music and culture!"
              className="w-full px-4 py-3 border-2 border-gray-200 rounded-xl focus:border-[#007A3D] focus:outline-none transition-colors resize-none"
            />
            <p className="text-gray-500 text-xs mt-1">150/200 characters</p>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex gap-3 mt-8">
          <button className="flex-1 bg-gradient-to-r from-[#007A3D] to-[#005A2D] text-white py-4 rounded-xl shadow-lg hover:shadow-xl transition-shadow flex items-center justify-center gap-2">
            <Save className="w-5 h-5" />
            Save Changes
          </button>
          <button className="bg-gray-200 text-gray-700 px-6 py-4 rounded-xl hover:bg-gray-300 transition-colors">
            Cancel
          </button>
        </div>
      </div>
    </div>
  );
}
