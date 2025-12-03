import React from 'react';
import { Mail, ArrowLeft, CheckCircle } from 'lucide-react';

export function ForgotPasswordScreen() {
  const [sent, setSent] = React.useState(false);

  return (
    <div className="min-h-screen bg-gradient-to-br from-white to-purple-50 flex flex-col">
      {/* Header */}
      <div className="p-6">
        <button className="flex items-center gap-2 text-gray-600 hover:text-gray-900">
          <ArrowLeft className="w-5 h-5" />
          Back
        </button>
      </div>

      {/* Content */}
      <div className="flex-1 flex flex-col items-center justify-center px-8">
        <div className="bg-white rounded-3xl shadow-xl p-8 max-w-md w-full">
          {!sent ? (
            <>
              {/* Icon */}
              <div className="w-20 h-20 mx-auto rounded-full bg-gradient-to-br from-[#7B2CBF] to-[#CE1126] flex items-center justify-center shadow-lg mb-6">
                <Mail className="w-10 h-10 text-white" />
              </div>

              <h2 className="text-[#7B2CBF] text-center mb-2">Forgot Password?</h2>
              <p className="text-gray-600 text-center mb-8">
                No worries! Enter your email and we'll send you a reset link.
              </p>

              {/* Email Input */}
              <div className="mb-6">
                <label className="block text-gray-700 mb-2">Email Address</label>
                <div className="relative">
                  <Mail className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 w-5 h-5" />
                  <input
                    type="email"
                    placeholder="your.email@example.com"
                    className="w-full pl-12 pr-4 py-4 border-2 border-gray-200 rounded-xl focus:border-[#7B2CBF] focus:outline-none transition-colors"
                  />
                </div>
              </div>

              {/* Submit Button */}
              <button 
                onClick={() => setSent(true)}
                className="w-full bg-gradient-to-r from-[#7B2CBF] to-[#CE1126] text-white py-4 rounded-xl shadow-lg hover:shadow-xl transition-shadow"
              >
                Send Reset Link
              </button>

              {/* Back to Login */}
              <div className="text-center mt-6">
                <a href="#" className="text-[#7B2CBF] hover:underline">
                  Back to Login
                </a>
              </div>
            </>
          ) : (
            <>
              {/* Success State */}
              <div className="w-20 h-20 mx-auto rounded-full bg-green-100 flex items-center justify-center mb-6">
                <CheckCircle className="w-12 h-12 text-green-600" />
              </div>

              <h2 className="text-green-600 text-center mb-2">Check Your Email!</h2>
              <p className="text-gray-600 text-center mb-8">
                We've sent a password reset link to your email address. Please check your inbox and follow the instructions.
              </p>

              <button className="w-full bg-gradient-to-r from-[#007A3D] to-[#005A2D] text-white py-4 rounded-xl shadow-lg hover:shadow-xl transition-shadow">
                Back to Login
              </button>

              <div className="text-center mt-6">
                <p className="text-gray-600">
                  Didn't receive the email?{' '}
                  <a href="#" className="text-[#7B2CBF] hover:underline">Resend</a>
                </p>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
