import React from 'react';
import { Eye, EyeOff, Mail, User, Lock, Globe } from 'lucide-react';

export function SignUpScreen() {
  const [showPassword, setShowPassword] = React.useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = React.useState(false);
  const [formData, setFormData] = React.useState({
    email: '',
    username: '',
    firstName: '',
    lastName: '',
    nationality: '',
    password: '',
    confirmPassword: '',
    agreeToTerms: false,
  });
  
  const passwordStrength = () => {
    const length = formData.password.length;
    if (length === 0) return { level: 0, text: '', color: '' };
    if (length < 6) return { level: 1, text: 'Weak', color: 'bg-[#CE1126]' };
    if (length < 10) return { level: 2, text: 'Medium', color: 'bg-[#FCD116]' };
    return { level: 3, text: 'Strong', color: 'bg-[#007A3D]' };
  };
  
  const strength = passwordStrength();
  
  return (
    <div className="min-h-screen bg-gradient-to-b from-white via-[#007A3D]/5 to-[#007A3D]/10 px-6 py-8">
      {/* Header */}
      <div className="text-center mb-8">
        <div className="w-20 h-20 bg-gradient-to-br from-[#FCD116] to-[#FF6B35] rounded-full flex items-center justify-center shadow-xl shadow-[#FCD116]/30 mb-4 mx-auto">
          <span className="text-4xl">🌍</span>
        </div>
        <h1 className="text-3xl text-gray-900 mb-2">Create Account</h1>
        <p className="text-gray-600">Join the LingAfriq community</p>
      </div>

      {/* Sign Up Form */}
      <div className="max-w-md mx-auto space-y-4 pb-8">
        {/* Email */}
        <div className="space-y-2">
          <label className="text-gray-700 text-sm">Email *</label>
          <div className="relative">
            <Mail className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="email"
              value={formData.email}
              onChange={(e) => setFormData({ ...formData, email: e.target.value })}
              placeholder="your.email@example.com"
              className="w-full pl-12 pr-4 py-3 rounded-xl border-2 border-gray-200 focus:border-[#007A3D] outline-none transition-colors"
            />
          </div>
        </div>

        {/* Username */}
        <div className="space-y-2">
          <label className="text-gray-700 text-sm">Username *</label>
          <div className="relative">
            <User className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              value={formData.username}
              onChange={(e) => setFormData({ ...formData, username: e.target.value })}
              placeholder="Choose a username"
              className="w-full pl-12 pr-4 py-3 rounded-xl border-2 border-gray-200 focus:border-[#007A3D] outline-none transition-colors"
            />
          </div>
        </div>

        {/* First Name & Last Name */}
        <div className="grid grid-cols-2 gap-4">
          <div className="space-y-2">
            <label className="text-gray-700 text-sm">First Name *</label>
            <input
              type="text"
              value={formData.firstName}
              onChange={(e) => setFormData({ ...formData, firstName: e.target.value })}
              placeholder="First name"
              className="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-[#007A3D] outline-none transition-colors"
            />
          </div>
          <div className="space-y-2">
            <label className="text-gray-700 text-sm">Last Name *</label>
            <input
              type="text"
              value={formData.lastName}
              onChange={(e) => setFormData({ ...formData, lastName: e.target.value })}
              placeholder="Last name"
              className="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-[#007A3D] outline-none transition-colors"
            />
          </div>
        </div>

        {/* Nationality */}
        <div className="space-y-2">
          <label className="text-gray-700 text-sm">Nationality</label>
          <div className="relative">
            <Globe className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <select
              value={formData.nationality}
              onChange={(e) => setFormData({ ...formData, nationality: e.target.value })}
              className="w-full pl-12 pr-4 py-3 rounded-xl border-2 border-gray-200 focus:border-[#007A3D] outline-none transition-colors appearance-none bg-white"
            >
              <option value="">Select your country</option>
              <option value="NG">🇳🇬 Nigeria</option>
              <option value="KE">🇰🇪 Kenya</option>
              <option value="ZA">🇿🇦 South Africa</option>
              <option value="ET">🇪🇹 Ethiopia</option>
              <option value="GH">🇬🇭 Ghana</option>
              <option value="TZ">🇹🇿 Tanzania</option>
            </select>
          </div>
        </div>

        {/* Password */}
        <div className="space-y-2">
          <label className="text-gray-700 text-sm">Password *</label>
          <div className="relative">
            <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type={showPassword ? 'text' : 'password'}
              value={formData.password}
              onChange={(e) => setFormData({ ...formData, password: e.target.value })}
              placeholder="Create a password"
              className="w-full pl-12 pr-12 py-3 rounded-xl border-2 border-gray-200 focus:border-[#007A3D] outline-none transition-colors"
            />
            <button
              onClick={() => setShowPassword(!showPassword)}
              className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
            >
              {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
            </button>
          </div>
          {/* Password Strength */}
          {formData.password && (
            <div className="space-y-1">
              <div className="flex gap-1">
                {[1, 2, 3].map((level) => (
                  <div
                    key={level}
                    className={`h-1 flex-1 rounded-full ${
                      level <= strength.level ? strength.color : 'bg-gray-200'
                    }`}
                  />
                ))}
              </div>
              <p className={`text-xs ${strength.level === 3 ? 'text-[#007A3D]' : strength.level === 2 ? 'text-[#FCD116]' : 'text-[#CE1126]'}`}>
                {strength.text}
              </p>
            </div>
          )}
        </div>

        {/* Confirm Password */}
        <div className="space-y-2">
          <label className="text-gray-700 text-sm">Confirm Password *</label>
          <div className="relative">
            <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type={showConfirmPassword ? 'text' : 'password'}
              value={formData.confirmPassword}
              onChange={(e) => setFormData({ ...formData, confirmPassword: e.target.value })}
              placeholder="Confirm your password"
              className="w-full pl-12 pr-12 py-3 rounded-xl border-2 border-gray-200 focus:border-[#007A3D] outline-none transition-colors"
            />
            <button
              onClick={() => setShowConfirmPassword(!showConfirmPassword)}
              className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
            >
              {showConfirmPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
            </button>
          </div>
        </div>

        {/* Terms Checkbox */}
        <div className="flex items-start gap-3 pt-2">
          <input
            type="checkbox"
            checked={formData.agreeToTerms}
            onChange={(e) => setFormData({ ...formData, agreeToTerms: e.target.checked })}
            className="mt-1 w-4 h-4 rounded accent-[#007A3D]"
          />
          <label className="text-sm text-gray-600">
            I agree to the{' '}
            <button className="text-[#007A3D] hover:underline">Terms of Service</button>
            {' '}and{' '}
            <button className="text-[#007A3D] hover:underline">Privacy Policy</button>
          </label>
        </div>

        {/* Sign Up Button */}
        <button
          disabled={!formData.agreeToTerms}
          className="w-full bg-gradient-to-r from-[#007A3D] to-[#00a84f] text-white py-4 rounded-2xl disabled:opacity-50 disabled:cursor-not-allowed hover:shadow-lg transition-all"
        >
          Create Account
        </button>

        {/* Login Link */}
        <p className="text-center text-gray-600 text-sm">
          Already have an account?{' '}
          <button className="text-[#007A3D] hover:underline">
            Login
          </button>
        </p>
      </div>
    </div>
  );
}
