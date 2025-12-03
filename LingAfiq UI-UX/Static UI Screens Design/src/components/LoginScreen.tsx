import React from 'react';
import { Eye, EyeOff, Mail, Lock } from 'lucide-react';

export function LoginScreen() {
  const [showPassword, setShowPassword] = React.useState(false);
  const [email, setEmail] = React.useState('');
  const [password, setPassword] = React.useState('');
  
  return (
    <div className="min-h-screen bg-gradient-to-b from-white via-[#007A3D]/5 to-[#007A3D]/10 flex flex-col">
      {/* Logo Section */}
      <div className="flex-1 flex flex-col items-center justify-center px-6 pt-12">
        <div className="w-24 h-24 bg-gradient-to-br from-[#FCD116] to-[#FF6B35] rounded-full flex items-center justify-center shadow-2xl shadow-[#FCD116]/30 mb-6">
          <span className="text-5xl">🌍</span>
        </div>
        <h1 className="text-4xl text-gray-900 mb-2">LingAfriq</h1>
        <p className="text-gray-600 mb-12">Welcome back!</p>

        {/* Login Form */}
        <div className="w-full max-w-md space-y-4">
          {/* Email Input */}
          <div className="space-y-2">
            <label className="text-gray-700 text-sm">Email</label>
            <div className="relative">
              <Mail className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="your.email@example.com"
                className="w-full pl-12 pr-4 py-4 rounded-2xl border-2 border-gray-200 focus:border-[#007A3D] outline-none transition-colors"
              />
            </div>
          </div>

          {/* Password Input */}
          <div className="space-y-2">
            <label className="text-gray-700 text-sm">Password</label>
            <div className="relative">
              <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                type={showPassword ? 'text' : 'password'}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Enter your password"
                className="w-full pl-12 pr-12 py-4 rounded-2xl border-2 border-gray-200 focus:border-[#007A3D] outline-none transition-colors"
              />
              <button
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
              >
                {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
              </button>
            </div>
          </div>

          {/* Forgot Password */}
          <div className="text-right">
            <button className="text-[#007A3D] text-sm hover:underline">
              Forgot password?
            </button>
          </div>

          {/* Login Button */}
          <button className="w-full bg-gradient-to-r from-[#007A3D] to-[#00a84f] text-white py-4 rounded-2xl hover:shadow-lg transition-all">
            Login
          </button>

          {/* Sign Up Link */}
          <p className="text-center text-gray-600 text-sm">
            Don't have an account?{' '}
            <button className="text-[#007A3D] hover:underline">
              Sign up
            </button>
          </p>
        </div>
      </div>

      {/* Decorative Bottom */}
      <div className="h-32 bg-gradient-to-t from-[#007A3D]/20 to-transparent" />
    </div>
  );
}
