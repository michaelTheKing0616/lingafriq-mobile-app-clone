import React from 'react';
import { Mail, Lock, User, Flag } from 'lucide-react';

export function SignUpScreen() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-white to-orange-50 flex flex-col py-8">
      {/* Header */}
      <div className="pt-8 pb-6 px-8 text-center">
        <div className="w-20 h-20 mx-auto rounded-full bg-gradient-to-br from-[#FF6B35] to-[#CE1126] flex items-center justify-center shadow-lg mb-4">
          <span className="text-4xl">🌍</span>
        </div>
        <h1 className="text-[#FF6B35] mb-2">Join LingAfriq</h1>
        <p className="text-gray-600">Start learning African languages today</p>
      </div>

      {/* Sign Up Form */}
      <div className="flex-1 px-8 pb-8 overflow-y-auto">
        <div className="bg-white rounded-3xl shadow-xl p-8 max-w-md mx-auto">
          {/* Email */}
          <div className="mb-5">
            <label className="block text-gray-700 mb-2">Email</label>
            <div className="relative">
              <Mail className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 w-5 h-5" />
              <input
                type="email"
                placeholder="your.email@example.com"
                className="w-full pl-12 pr-4 py-3 border-2 border-gray-200 rounded-xl focus:border-[#FF6B35] focus:outline-none transition-colors"
              />
            </div>
          </div>

          {/* Username */}
          <div className="mb-5">
            <label className="block text-gray-700 mb-2">Username</label>
            <div className="relative">
              <User className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 w-5 h-5" />
              <input
                type="text"
                placeholder="Choose a username"
                className="w-full pl-12 pr-4 py-3 border-2 border-gray-200 rounded-xl focus:border-[#FF6B35] focus:outline-none transition-colors"
              />
            </div>
          </div>

          {/* First Name */}
          <div className="mb-5">
            <label className="block text-gray-700 mb-2">First Name</label>
            <div className="relative">
              <User className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 w-5 h-5" />
              <input
                type="text"
                placeholder="First name"
                className="w-full pl-12 pr-4 py-3 border-2 border-gray-200 rounded-xl focus:border-[#FF6B35] focus:outline-none transition-colors"
              />
            </div>
          </div>

          {/* Last Name */}
          <div className="mb-5">
            <label className="block text-gray-700 mb-2">Last Name</label>
            <div className="relative">
              <User className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 w-5 h-5" />
              <input
                type="text"
                placeholder="Last name"
                className="w-full pl-12 pr-4 py-3 border-2 border-gray-200 rounded-xl focus:border-[#FF6B35] focus:outline-none transition-colors"
              />
            </div>
          </div>

          {/* Nationality */}
          <div className="mb-5">
            <label className="block text-gray-700 mb-2">Nationality</label>
            <div className="relative">
              <Flag className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 w-5 h-5" />
              <select className="w-full pl-12 pr-4 py-3 border-2 border-gray-200 rounded-xl focus:border-[#FF6B35] focus:outline-none transition-colors appearance-none bg-white">
                <option>Select country</option>
                <option>🇳🇬 Nigeria</option>
                <option>🇰🇪 Kenya</option>
                <option>🇿🇦 South Africa</option>
                <option>🇬🇭 Ghana</option>
                <option>🇪🇹 Ethiopia</option>
              </select>
            </div>
          </div>

          {/* Password */}
          <div className="mb-5">
            <label className="block text-gray-700 mb-2">Password</label>
            <div className="relative">
              <Lock className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 w-5 h-5" />
              <input
                type="password"
                placeholder="Create a password"
                className="w-full pl-12 pr-4 py-3 border-2 border-gray-200 rounded-xl focus:border-[#FF6B35] focus:outline-none transition-colors"
              />
            </div>
            {/* Password Strength Indicator */}
            <div className="flex gap-1 mt-2">
              <div className="h-1 flex-1 rounded bg-red-500"></div>
              <div className="h-1 flex-1 rounded bg-yellow-500"></div>
              <div className="h-1 flex-1 rounded bg-gray-200"></div>
              <div className="h-1 flex-1 rounded bg-gray-200"></div>
            </div>
            <p className="text-xs text-gray-500 mt-1">Weak - Add more characters</p>
          </div>

          {/* Confirm Password */}
          <div className="mb-5">
            <label className="block text-gray-700 mb-2">Confirm Password</label>
            <div className="relative">
              <Lock className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 w-5 h-5" />
              <input
                type="password"
                placeholder="Confirm your password"
                className="w-full pl-12 pr-4 py-3 border-2 border-gray-200 rounded-xl focus:border-[#FF6B35] focus:outline-none transition-colors"
              />
            </div>
          </div>

          {/* Terms Checkbox */}
          <div className="mb-6">
            <label className="flex items-start gap-3 cursor-pointer">
              <input type="checkbox" className="mt-1 w-5 h-5 accent-[#FF6B35]" />
              <span className="text-sm text-gray-600">
                I agree to the <a href="#" className="text-[#FF6B35] hover:underline">privacy terms</a> and conditions
              </span>
            </label>
          </div>

          {/* Sign Up Button */}
          <button className="w-full bg-gradient-to-r from-[#FF6B35] to-[#CE1126] text-white py-4 rounded-xl shadow-lg hover:shadow-xl transition-shadow">
            Sign Up
          </button>

          {/* Login Link */}
          <div className="text-center mt-6">
            <p className="text-gray-600">
              Already have an account?{' '}
              <a href="#" className="text-[#FF6B35] hover:underline">Login</a>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
