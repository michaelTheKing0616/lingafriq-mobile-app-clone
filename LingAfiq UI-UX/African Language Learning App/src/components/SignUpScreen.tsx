import { useState } from 'react';
import { motion } from 'motion/react';
import { Mail, Lock, User, Eye, EyeOff, ArrowRight } from 'lucide-react';

interface SignUpScreenProps {
  onSignUp: () => void;
  onNavigateToSignIn: () => void;
}

export default function SignUpScreen({ onSignUp, onNavigateToSignIn }: SignUpScreenProps) {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSignUp();
  };

  return (
    <div className="w-full min-h-screen flex flex-col relative overflow-hidden" style={{
      background: 'linear-gradient(135deg, #3498DB 0%, #9B59B6 50%, #E74C3C 100%)'
    }}>
      {/* Background Patterns */}
      <div className="absolute inset-0 opacity-10">
        <div className="absolute top-0 left-0 w-64 h-64 rounded-full bg-white/30 blur-3xl" />
        <div className="absolute bottom-0 right-0 w-80 h-80 rounded-full bg-white/30 blur-3xl" />
      </div>

      {/* Content */}
      <div className="relative z-10 flex-1 flex flex-col justify-between p-6 pt-12">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          className="text-center mb-8"
        >
          <div className="w-20 h-20 mx-auto mb-4 bg-white rounded-2xl shadow-xl flex items-center justify-center">
            <span className="text-4xl">✨</span>
          </div>
          <h1 className="text-white mb-2">Create Account</h1>
          <p className="text-white/90">Join thousands learning African languages</p>
        </motion.div>

        {/* Form */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2, duration: 0.6 }}
          className="flex-1"
        >
          <div className="bg-white rounded-3xl shadow-2xl p-8">
            <form onSubmit={handleSubmit} className="space-y-5">
              {/* Name Input */}
              <div>
                <label htmlFor="name" className="block text-gray-700 mb-2 font-medium">
                  Full Name
                </label>
                <div className="relative">
                  <User className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                  <input
                    id="name"
                    type="text"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="Your Name"
                    className="w-full pl-12 pr-4 py-4 rounded-xl border-2 border-gray-200 focus:border-purple-500 focus:outline-none transition-colors"
                    required
                  />
                </div>
              </div>

              {/* Email Input */}
              <div>
                <label htmlFor="email" className="block text-gray-700 mb-2 font-medium">
                  Email
                </label>
                <div className="relative">
                  <Mail className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                  <input
                    id="email"
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="your.email@example.com"
                    className="w-full pl-12 pr-4 py-4 rounded-xl border-2 border-gray-200 focus:border-purple-500 focus:outline-none transition-colors"
                    required
                  />
                </div>
              </div>

              {/* Password Input */}
              <div>
                <label htmlFor="password" className="block text-gray-700 mb-2 font-medium">
                  Password
                </label>
                <div className="relative">
                  <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                  <input
                    id="password"
                    type={showPassword ? 'text' : 'password'}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="••••••••"
                    className="w-full pl-12 pr-12 py-4 rounded-xl border-2 border-gray-200 focus:border-purple-500 focus:outline-none transition-colors"
                    required
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                  >
                    {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                  </button>
                </div>
              </div>

              {/* Terms Agreement */}
              <div className="flex items-start gap-3">
                <input
                  type="checkbox"
                  id="terms"
                  className="mt-1 w-5 h-5 rounded border-gray-300 text-purple-600 focus:ring-purple-500"
                  required
                />
                <label htmlFor="terms" className="text-sm text-gray-600">
                  I agree to the Terms of Service and Privacy Policy
                </label>
              </div>

              {/* Sign Up Button */}
              <motion.button
                type="submit"
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                className="w-full py-4 rounded-xl text-white flex items-center justify-center gap-2 shadow-lg"
                style={{
                  background: 'linear-gradient(135deg, #9B59B6 0%, #E74C3C 100%)'
                }}
              >
                <span>Create Account</span>
                <ArrowRight className="w-5 h-5" />
              </motion.button>

              {/* Divider */}
              <div className="relative my-4">
                <div className="absolute inset-0 flex items-center">
                  <div className="w-full border-t border-gray-300" />
                </div>
                <div className="relative flex justify-center text-sm">
                  <span className="px-4 bg-white text-gray-500">or sign up with</span>
                </div>
              </div>

              {/* Social Sign Up */}
              <div className="grid grid-cols-2 gap-4">
                <button
                  type="button"
                  className="py-3 px-4 rounded-xl border-2 border-gray-200 hover:border-gray-300 transition-colors flex items-center justify-center gap-2"
                >
                  <span className="text-xl">🔵</span>
                  <span className="text-sm text-gray-700">Google</span>
                </button>
                <button
                  type="button"
                  className="py-3 px-4 rounded-xl border-2 border-gray-200 hover:border-gray-300 transition-colors flex items-center justify-center gap-2"
                >
                  <span className="text-xl">📘</span>
                  <span className="text-sm text-gray-700">Facebook</span>
                </button>
              </div>
            </form>
          </div>
        </motion.div>

        {/* Sign In Link */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.4, duration: 0.6 }}
          className="text-center mt-6"
        >
          <p className="text-white">
            Already have an account?{' '}
            <button
              onClick={onNavigateToSignIn}
              className="font-semibold underline hover:no-underline"
            >
              Sign In
            </button>
          </p>
        </motion.div>
      </div>
    </div>
  );
}
