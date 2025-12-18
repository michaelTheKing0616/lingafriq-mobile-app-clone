import { useState } from 'react';
import { motion } from 'motion/react';
import { Mail, Lock, Eye, EyeOff, ArrowRight } from 'lucide-react';

interface SignInScreenProps {
  onSignIn: () => void;
  onNavigateToSignUp: () => void;
}

export default function SignInScreen({ onSignIn, onNavigateToSignUp }: SignInScreenProps) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSignIn();
  };

  return (
    <div className="w-full min-h-screen flex flex-col relative overflow-hidden" style={{
      background: 'linear-gradient(135deg, #E74C3C 0%, #F1C40F 50%, #27AE60 100%)'
    }}>
      {/* Background Patterns */}
      <div className="absolute inset-0 opacity-10">
        <div className="absolute top-0 right-0 w-64 h-64 rounded-full bg-white/30 blur-3xl" />
        <div className="absolute bottom-0 left-0 w-80 h-80 rounded-full bg-white/30 blur-3xl" />
      </div>

      {/* Content */}
      <div className="relative z-10 flex-1 flex flex-col justify-between p-6 pt-16">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          className="text-center mb-12"
        >
          <div className="w-20 h-20 mx-auto mb-4 bg-white rounded-2xl shadow-xl flex items-center justify-center">
            <span className="text-4xl">🌍</span>
          </div>
          <h1 className="text-white mb-2">Welcome Back!</h1>
          <p className="text-white/90">Sign in to continue your learning journey</p>
        </motion.div>

        {/* Form */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2, duration: 0.6 }}
          className="flex-1"
        >
          <div className="bg-white rounded-3xl shadow-2xl p-8">
            <form onSubmit={handleSubmit} className="space-y-6">
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
                    className="w-full pl-12 pr-4 py-4 rounded-xl border-2 border-gray-200 focus:border-green-500 focus:outline-none transition-colors"
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
                    className="w-full pl-12 pr-12 py-4 rounded-xl border-2 border-gray-200 focus:border-green-500 focus:outline-none transition-colors"
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

              {/* Forgot Password */}
              <div className="text-right">
                <button type="button" className="text-sm text-green-600 hover:text-green-700">
                  Forgot Password?
                </button>
              </div>

              {/* Sign In Button */}
              <motion.button
                type="submit"
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                className="w-full py-4 rounded-xl text-white flex items-center justify-center gap-2 shadow-lg"
                style={{
                  background: 'linear-gradient(135deg, #27AE60 0%, #00D2A3 100%)'
                }}
              >
                <span>Sign In</span>
                <ArrowRight className="w-5 h-5" />
              </motion.button>

              {/* Divider */}
              <div className="relative my-6">
                <div className="absolute inset-0 flex items-center">
                  <div className="w-full border-t border-gray-300" />
                </div>
                <div className="relative flex justify-center text-sm">
                  <span className="px-4 bg-white text-gray-500">or continue with</span>
                </div>
              </div>

              {/* Social Login */}
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

        {/* Sign Up Link */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.4, duration: 0.6 }}
          className="text-center mt-6"
        >
          <p className="text-white">
            Don't have an account?{' '}
            <button
              onClick={onNavigateToSignUp}
              className="font-semibold underline hover:no-underline"
            >
              Sign Up
            </button>
          </p>
        </motion.div>
      </div>
    </div>
  );
}
