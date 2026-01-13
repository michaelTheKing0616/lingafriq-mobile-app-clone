import { useState } from 'react';
import { motion } from 'motion/react';
import { Mail, Lock, Eye, EyeOff, ArrowRight } from 'lucide-react';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';

type SignInProps = {
  onSignIn: () => void;
  onSwitchToSignUp: () => void;
};

export default function SignIn({ onSignIn, onSwitchToSignUp }: SignInProps) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // Mock sign in
    onSignIn();
  };

  return (
    <div className="min-h-screen flex flex-col lg:flex-row">
      {/* Left Side - Branding */}
      <motion.div
        initial={{ opacity: 0, x: -50 }}
        animate={{ opacity: 1, x: 0 }}
        transition={{ duration: 0.6 }}
        className="lg:w-1/2 gradient-african-sunset p-8 lg:p-12 flex flex-col justify-center items-center text-white relative overflow-hidden"
      >
        <div className="african-pattern-overlay absolute inset-0" />
        <div className="relative z-10 max-w-md">
          <motion.div
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            transition={{ delay: 0.3, type: 'spring', stiffness: 200 }}
            className="w-20 h-20 bg-white/20 backdrop-blur-sm rounded-3xl flex items-center justify-center mb-6"
          >
            <span className="text-4xl">🌍</span>
          </motion.div>
          <h1 className="mb-4">Welcome Back!</h1>
          <p className="text-white/90 text-lg">
            Continue your journey to mastering African languages and connecting with diverse cultures.
          </p>
        </div>
      </motion.div>

      {/* Right Side - Sign In Form */}
      <motion.div
        initial={{ opacity: 0, x: 50 }}
        animate={{ opacity: 1, x: 0 }}
        transition={{ duration: 0.6 }}
        className="lg:w-1/2 bg-white p-8 lg:p-12 flex items-center justify-center"
      >
        <div className="w-full max-w-md">
          <div className="mb-8">
            <h2 className="mb-2">Sign In</h2>
            <p className="text-stone-600">Enter your credentials to access your account</p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-6">
            {/* Email Field */}
            <div className="space-y-2">
              <Label htmlFor="email">Email Address</Label>
              <div className="relative">
                <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-stone-400" />
                <Input
                  id="email"
                  type="email"
                  placeholder="your@email.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="pl-10 h-12 rounded-xl border-stone-300 focus:border-[#E63946] focus:ring-[#E63946]"
                  required
                />
              </div>
            </div>

            {/* Password Field */}
            <div className="space-y-2">
              <Label htmlFor="password">Password</Label>
              <div className="relative">
                <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-stone-400" />
                <Input
                  id="password"
                  type={showPassword ? 'text' : 'password'}
                  placeholder="Enter your password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="pl-10 pr-10 h-12 rounded-xl border-stone-300 focus:border-[#E63946] focus:ring-[#E63946]"
                  required
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-stone-400 hover:text-stone-600"
                >
                  {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                </button>
              </div>
            </div>

            {/* Forgot Password */}
            <div className="flex items-center justify-between">
              <label className="flex items-center gap-2 cursor-pointer">
                <input type="checkbox" className="w-4 h-4 rounded border-stone-300 text-[#E63946] focus:ring-[#E63946]" />
                <span className="text-sm text-stone-600">Remember me</span>
              </label>
              <button type="button" className="text-sm text-[#E63946] hover:underline">
                Forgot password?
              </button>
            </div>

            {/* Submit Button */}
            <Button
              type="submit"
              className="w-full h-12 bg-[#E63946] hover:bg-[#C62F3A] text-white rounded-xl shadow-lg transition-all duration-300 hover:shadow-xl hover:-translate-y-0.5"
            >
              <span className="flex items-center justify-center gap-2">
                Sign In
                <ArrowRight className="w-5 h-5" />
              </span>
            </Button>

            {/* Divider */}
            <div className="relative my-6">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-stone-300" />
              </div>
              <div className="relative flex justify-center text-sm">
                <span className="px-4 bg-white text-stone-500">Or continue with</span>
              </div>
            </div>

            {/* Social Sign In */}
            <div className="grid grid-cols-2 gap-4">
              <Button
                type="button"
                variant="outline"
                className="h-12 rounded-xl border-stone-300 hover:bg-stone-50"
              >
                <img src="https://www.google.com/favicon.ico" alt="Google" className="w-5 h-5 mr-2" />
                Google
              </Button>
              <Button
                type="button"
                variant="outline"
                className="h-12 rounded-xl border-stone-300 hover:bg-stone-50"
              >
                <img src="https://www.apple.com/favicon.ico" alt="Apple" className="w-5 h-5 mr-2" />
                Apple
              </Button>
            </div>

            {/* Sign Up Link */}
            <p className="text-center text-sm text-stone-600">
              Don't have an account?{' '}
              <button
                type="button"
                onClick={onSwitchToSignUp}
                className="text-[#E63946] hover:underline"
              >
                Sign up for free
              </button>
            </p>
          </form>
        </div>
      </motion.div>
    </div>
  );
}
