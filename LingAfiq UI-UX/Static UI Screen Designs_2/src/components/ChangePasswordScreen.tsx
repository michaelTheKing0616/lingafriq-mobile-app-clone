import { Lock, Eye, EyeOff, Check } from 'lucide-react';

export function ChangePasswordScreen() {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#007A3D] to-[#005A2D] px-6 py-4 flex items-center justify-between">
        <button className="p-2 hover:bg-white/10 rounded-lg transition-colors">
          <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
          </svg>
        </button>
        <h2 className="text-white">Change Password</h2>
        <div className="w-10" />
      </div>

      <div className="px-6 py-8">
        {/* Icon */}
        <div className="flex justify-center mb-8">
          <div className="w-20 h-20 bg-gradient-to-br from-[#007A3D] to-[#005A2D] rounded-full flex items-center justify-center">
            <Lock className="w-10 h-10 text-white" />
          </div>
        </div>

        {/* Info Message */}
        <div className="bg-blue-50 border-l-4 border-blue-400 p-4 rounded-r-xl mb-6">
          <p className="text-sm text-gray-700">
            Choose a strong password that you haven't used elsewhere. Must be at least 8 characters long.
          </p>
        </div>

        {/* Form */}
        <div className="space-y-6">
          {/* Current Password */}
          <div>
            <label className="block text-gray-700 mb-2">Current Password</label>
            <div className="relative">
              <input
                type="password"
                placeholder="Enter current password"
                className="w-full px-4 py-3 pr-12 rounded-xl border-2 border-gray-200 focus:border-[#007A3D] outline-none transition-colors"
              />
              <button className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
                <Eye className="w-5 h-5" />
              </button>
            </div>
          </div>

          {/* New Password */}
          <div>
            <label className="block text-gray-700 mb-2">New Password</label>
            <div className="relative">
              <input
                type="password"
                placeholder="Enter new password"
                className="w-full px-4 py-3 pr-12 rounded-xl border-2 border-gray-200 focus:border-[#007A3D] outline-none transition-colors"
              />
              <button className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
                <Eye className="w-5 h-5" />
              </button>
            </div>

            {/* Password Strength Indicator */}
            <div className="mt-3">
              <div className="flex gap-1 mb-2">
                <div className="flex-1 h-1.5 bg-red-500 rounded-full" />
                <div className="flex-1 h-1.5 bg-yellow-500 rounded-full" />
                <div className="flex-1 h-1.5 bg-green-500 rounded-full" />
              </div>
              <p className="text-sm text-green-600">Strong password</p>
            </div>

            {/* Requirements */}
            <div className="mt-4 space-y-2">
              <div className="flex items-center gap-2">
                <Check className="w-4 h-4 text-green-500" />
                <span className="text-sm text-gray-600">At least 8 characters</span>
              </div>
              <div className="flex items-center gap-2">
                <Check className="w-4 h-4 text-green-500" />
                <span className="text-sm text-gray-600">Contains uppercase letter</span>
              </div>
              <div className="flex items-center gap-2">
                <Check className="w-4 h-4 text-green-500" />
                <span className="text-sm text-gray-600">Contains number</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-4 h-4 border-2 border-gray-300 rounded-full" />
                <span className="text-sm text-gray-400">Contains special character</span>
              </div>
            </div>
          </div>

          {/* Confirm Password */}
          <div>
            <label className="block text-gray-700 mb-2">Confirm New Password</label>
            <div className="relative">
              <input
                type="password"
                placeholder="Confirm new password"
                className="w-full px-4 py-3 pr-12 rounded-xl border-2 border-gray-200 focus:border-[#007A3D] outline-none transition-colors"
              />
              <button className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
                <Eye className="w-5 h-5" />
              </button>
            </div>
          </div>
        </div>

        {/* Update Button */}
        <button className="w-full mt-8 bg-gradient-to-r from-[#007A3D] to-[#005A2D] text-white py-4 rounded-2xl shadow-lg hover:shadow-xl transition-all">
          Update Password
        </button>

        {/* Cancel Button */}
        <button className="w-full mt-3 bg-white text-gray-600 py-4 rounded-2xl border-2 border-gray-200 hover:bg-gray-50 transition-all">
          Cancel
        </button>

        {/* Forgot Password Link */}
        <div className="text-center mt-6">
          <button className="text-[#007A3D] text-sm hover:underline">
            Forgot your current password?
          </button>
        </div>
      </div>
    </div>
  );
}
