import React from 'react';
import { Mail, Lock, Eye } from 'lucide-react';

export function LoginScreen() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-white to-green-50 flex flex-col">
      {/* Header */}
      <div className="pt-16 pb-8 px-8 text-center">
        <div className="w-24 h-24 mx-auto rounded-full bg-gradient-to-br from-[#007A3D] to-[#005A2D] flex items-center justify-center shadow-lg mb-6">
          <span className="text-5xl">🌍</span>
        </div>
        <h1 className="text-[#007A3D] mb-2">Welcome Back!</h1>
        <p className="text-gray-600">Continue your language learning journey</p>
      </div>

      {/* Login Form */}
      <div className="flex-1 px-8">
        <div className="bg-white rounded-3xl shadow-xl p-8 max-w-md mx-auto">
          {/* Email Input */}
          <div className="mb-6">
            <label className="block text-gray-700 mb-2">Email</label>
            <div className="relative">
              <Mail className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 w-5 h-5" />
              <input
                type="email"
                placeholder="your.email@example.com"
                className="w-full pl-12 pr-4 py-4 border-2 border-gray-200 rounded-xl focus:border-[#007A3D] focus:outline-none transition-colors"
              />
            </div>
          </div>

          {/* Password Input */}
          <div className="mb-4">
            <label className="block text-gray-700 mb-2">Password</label>
            <div className="relative">
              <Lock className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 w-5 h-5" />
              <input
                type="password"
                placeholder="Enter your password"
                className="w-full pl-12 pr-12 py-4 border-2 border-gray-200 rounded-xl focus:border-[#007A3D] focus:outline-none transition-colors"
              />
              <Eye className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 w-5 h-5 cursor-pointer" />
            </div>
          </div>

          {/* Forgot Password Link */}
          <div className="text-right mb-8">
            <a href="#" className="text-[#007A3D] hover:underline">Forgot password?</a>
          </div>

          {/* Login Button */}
          <button className="w-full bg-gradient-to-r from-[#007A3D] to-[#005A2D] text-white py-4 rounded-xl shadow-lg hover:shadow-xl transition-shadow">
            Login
          </button>

          {/* Sign Up Link */}
          <div className="text-center mt-6">
            <p className="text-gray-600">
              Don't have an account?{' '}
              <a href="#" className="text-[#007A3D] hover:underline">Sign up</a>
            </p>
          </div>
        </div>
      </div>

      {/* Bottom Decoration */}
      <div className="h-32 bg-gradient-to-t from-[#007A3D]/10 to-transparent"></div>
    </div>
  );
}
