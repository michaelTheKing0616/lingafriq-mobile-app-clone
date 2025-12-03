import React from 'react';
import { ArrowLeft, Mail, CheckCircle } from 'lucide-react';

export function ForgotPasswordScreen() {
  const [email, setEmail] = React.useState('');
  const [sent, setSent] = React.useState(false);
  
  return (
    <div className="min-h-screen bg-gradient-to-b from-white via-[#007A3D]/5 to-[#007A3D]/10 flex flex-col">
      <div className="flex-1 flex flex-col px-6 py-12">
        {/* Header */}
        <button className="self-start p-2 hover:bg-gray-100 rounded-lg transition-colors mb-8">
          <ArrowLeft className="w-6 h-6 text-gray-700" />
        </button>

        {!sent ? (
          <>
            <div className="flex-1 flex flex-col items-center justify-center max-w-md mx-auto w-full">
              <div className="w-20 h-20 bg-gradient-to-br from-[#FF6B35] to-[#FCD116] rounded-full flex items-center justify-center shadow-xl mb-6">
                <Mail className="w-10 h-10 text-white" />
              </div>
              
              <h1 className="text-3xl text-gray-900 mb-3 text-center">Forgot Password?</h1>
              <p className="text-gray-600 text-center mb-8">
                No worries! Enter your email and we'll send you a reset link.
              </p>

              <div className="w-full space-y-6">
                <div className="space-y-2">
                  <label className="text-gray-700 text-sm">Email Address</label>
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

                <button
                  onClick={() => setSent(true)}
                  className="w-full bg-gradient-to-r from-[#007A3D] to-[#00a84f] text-white py-4 rounded-2xl hover:shadow-lg transition-all"
                >
                  Send Reset Link
                </button>
              </div>
            </div>
          </>
        ) : (
          <div className="flex-1 flex flex-col items-center justify-center max-w-md mx-auto w-full text-center">
            <div className="w-20 h-20 bg-gradient-to-br from-[#007A3D] to-[#00a84f] rounded-full flex items-center justify-center shadow-xl mb-6">
              <CheckCircle className="w-10 h-10 text-white" />
            </div>
            
            <h1 className="text-3xl text-gray-900 mb-3">Check Your Email</h1>
            <p className="text-gray-600 mb-2">
              We've sent a password reset link to:
            </p>
            <p className="text-[#007A3D] mb-8">{email}</p>
            <p className="text-sm text-gray-500 mb-8">
              Didn't receive the email? Check your spam folder or try again.
            </p>

            <button
              onClick={() => setSent(false)}
              className="text-[#007A3D] hover:underline"
            >
              Try a different email
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
