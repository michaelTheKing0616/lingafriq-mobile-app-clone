import React from 'react';
import { ArrowLeft, Lock, Eye, CheckCircle } from 'lucide-react';

export function ChangePasswordScreen() {
  const [showCurrent, setShowCurrent] = React.useState(false);
  const [showNew, setShowNew] = React.useState(false);
  const [showConfirm, setShowConfirm] = React.useState(false);

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#7B2CBF] to-[#CE1126] px-6 py-6 shadow-lg">
        <div className="flex items-center gap-4">
          <button className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
            <ArrowLeft className="w-5 h-5 text-white" />
          </button>
          <h1 className="text-white">Change Password</h1>
        </div>
      </div>

      {/* Content */}
      <div className="px-6 py-8">
        {/* Icon */}
        <div className="flex justify-center mb-8">
          <div className="w-20 h-20 bg-gradient-to-br from-[#7B2CBF] to-[#CE1126] rounded-full flex items-center justify-center shadow-lg">
            <Lock className="w-10 h-10 text-white" />
          </div>
        </div>

        {/* Form */}
        <div className="space-y-5 mb-8">
          {/* Current Password */}
          <div>
            <label className="block text-gray-700 mb-2">Current Password</label>
            <div className="relative">
              <Lock className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 w-5 h-5" />
              <input
                type={showCurrent ? 'text' : 'password'}
                placeholder="Enter current password"
                className="w-full pl-12 pr-12 py-4 border-2 border-gray-200 rounded-xl focus:border-[#7B2CBF] focus:outline-none transition-colors"
              />
              <button
                onClick={() => setShowCurrent(!showCurrent)}
                className="absolute right-4 top-1/2 -translate-y-1/2"
              >
                <Eye className="w-5 h-5 text-gray-400" />
              </button>
            </div>
          </div>

          {/* New Password */}
          <div>
            <label className="block text-gray-700 mb-2">New Password</label>
            <div className="relative">
              <Lock className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 w-5 h-5" />
              <input
                type={showNew ? 'text' : 'password'}
                placeholder="Enter new password"
                className="w-full pl-12 pr-12 py-4 border-2 border-gray-200 rounded-xl focus:border-[#7B2CBF] focus:outline-none transition-colors"
              />
              <button
                onClick={() => setShowNew(!showNew)}
                className="absolute right-4 top-1/2 -translate-y-1/2"
              >
                <Eye className="w-5 h-5 text-gray-400" />
              </button>
            </div>
            
            {/* Password Strength Indicator */}
            <div className="flex gap-1 mt-3">
              <div className="h-1 flex-1 rounded bg-green-500"></div>
              <div className="h-1 flex-1 rounded bg-green-500"></div>
              <div className="h-1 flex-1 rounded bg-green-500"></div>
              <div className="h-1 flex-1 rounded bg-gray-200"></div>
            </div>
            <p className="text-sm text-green-600 mt-1">Strong password</p>
          </div>

          {/* Confirm Password */}
          <div>
            <label className="block text-gray-700 mb-2">Confirm New Password</label>
            <div className="relative">
              <Lock className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 w-5 h-5" />
              <input
                type={showConfirm ? 'text' : 'password'}
                placeholder="Confirm new password"
                className="w-full pl-12 pr-12 py-4 border-2 border-gray-200 rounded-xl focus:border-[#7B2CBF] focus:outline-none transition-colors"
              />
              <button
                onClick={() => setShowConfirm(!showConfirm)}
                className="absolute right-4 top-1/2 -translate-y-1/2"
              >
                <Eye className="w-5 h-5 text-gray-400" />
              </button>
            </div>
          </div>
        </div>

        {/* Password Requirements */}
        <div className="bg-white rounded-2xl p-5 shadow-md mb-8">
          <h4 className="text-gray-800 mb-3">Password Requirements</h4>
          <div className="space-y-2">
            <div className="flex items-center gap-2 text-sm">
              <CheckCircle className="w-4 h-4 text-green-500" />
              <span className="text-green-600">At least 8 characters</span>
            </div>
            <div className="flex items-center gap-2 text-sm">
              <CheckCircle className="w-4 h-4 text-green-500" />
              <span className="text-green-600">Contains uppercase letter</span>
            </div>
            <div className="flex items-center gap-2 text-sm">
              <CheckCircle className="w-4 h-4 text-green-500" />
              <span className="text-green-600">Contains lowercase letter</span>
            </div>
            <div className="flex items-center gap-2 text-sm">
              <div className="w-4 h-4 rounded-full border-2 border-gray-300"></div>
              <span className="text-gray-400">Contains number</span>
            </div>
            <div className="flex items-center gap-2 text-sm">
              <div className="w-4 h-4 rounded-full border-2 border-gray-300"></div>
              <span className="text-gray-400">Contains special character</span>
            </div>
          </div>
        </div>

        {/* Update Button */}
        <button className="w-full bg-gradient-to-r from-[#7B2CBF] to-[#CE1126] text-white py-4 rounded-xl shadow-lg hover:shadow-xl transition-shadow">
          Update Password
        </button>
      </div>
    </div>
  );
}
