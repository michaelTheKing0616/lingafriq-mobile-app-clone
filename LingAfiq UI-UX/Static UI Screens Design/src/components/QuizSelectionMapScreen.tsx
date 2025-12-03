import React from 'react';
import { ArrowLeft, Menu } from 'lucide-react';

export function QuizSelectionMapScreen() {
  return (
    <div className="h-screen bg-gradient-to-b from-[#8B6F47] via-[#D4A574] to-[#8B6F47] relative overflow-hidden">
      {/* Background Pattern */}
      <div className="absolute inset-0 opacity-10">
        <div className="absolute top-20 left-10 w-40 h-40 border-2 border-white/30 rounded-full" />
        <div className="absolute top-40 right-20 w-32 h-32 border-2 border-white/30 rounded-full" />
        <div className="absolute bottom-40 left-1/4 w-48 h-48 border-2 border-white/30 rounded-full" />
      </div>

      {/* Header */}
      <div className="relative z-10 px-4 py-6">
        <div className="flex items-center justify-between mb-4">
          <button className="p-2 bg-white/20 backdrop-blur-sm rounded-lg hover:bg-white/30 transition-colors">
            <Menu className="w-6 h-6 text-white" />
          </button>
          <button className="p-2 bg-white/20 backdrop-blur-sm rounded-lg hover:bg-white/30 transition-colors">
            <ArrowLeft className="w-6 h-6 text-white" />
          </button>
        </div>
        
        <div className="text-center text-white">
          <h1 className="text-3xl mb-2">Choose Your Quiz</h1>
          <p className="text-white/90">Select a quiz type to test your knowledge</p>
        </div>
      </div>

      {/* Quiz Bubbles on Map */}
      <div className="relative z-10 flex-1 px-6 py-12">
        {/* Random Quiz - Top Center */}
        <div className="absolute top-16 left-1/2 -translate-x-1/2 animate-float">
          <button className="group">
            <div className="relative">
              <div className="w-32 h-32 bg-gradient-to-br from-[#FF6B35] to-[#FCD116] rounded-full shadow-2xl flex items-center justify-center group-hover:scale-110 transition-transform">
                <span className="text-5xl">🎲</span>
              </div>
              <div className="absolute -bottom-12 left-1/2 -translate-x-1/2 bg-white rounded-xl px-4 py-2 shadow-lg whitespace-nowrap">
                <p className="text-gray-900">Random Quiz</p>
              </div>
            </div>
          </button>
        </div>

        {/* Language Quiz - Left Side */}
        <div className="absolute top-1/3 left-8 animate-float" style={{ animationDelay: '0.5s' }}>
          <button className="group">
            <div className="relative">
              <div className="w-36 h-36 bg-gradient-to-br from-[#007A3D] to-[#00a84f] rounded-full shadow-2xl flex items-center justify-center group-hover:scale-110 transition-transform">
                <span className="text-6xl">🗣️</span>
              </div>
              <div className="absolute -bottom-12 left-1/2 -translate-x-1/2 bg-white rounded-xl px-4 py-2 shadow-lg whitespace-nowrap">
                <p className="text-gray-900">Language Quiz</p>
              </div>
            </div>
          </button>
        </div>

        {/* History Quiz - Right Side */}
        <div className="absolute bottom-1/4 right-8 animate-float" style={{ animationDelay: '1s' }}>
          <button className="group">
            <div className="relative">
              <div className="w-36 h-36 bg-gradient-to-br from-[#7B2CBF] to-[#9d4edd] rounded-full shadow-2xl flex items-center justify-center group-hover:scale-110 transition-transform">
                <span className="text-6xl">📚</span>
              </div>
              <div className="absolute -bottom-12 left-1/2 -translate-x-1/2 bg-white rounded-xl px-4 py-2 shadow-lg whitespace-nowrap">
                <p className="text-gray-900">History Quiz</p>
              </div>
            </div>
          </button>
        </div>

        {/* Connecting Lines */}
        <svg className="absolute inset-0 w-full h-full pointer-events-none" style={{ opacity: 0.2 }}>
          <line x1="50%" y1="20%" x2="20%" y2="40%" stroke="white" strokeWidth="2" strokeDasharray="10,5" />
          <line x1="50%" y1="20%" x2="80%" y2="60%" stroke="white" strokeWidth="2" strokeDasharray="10,5" />
          <line x1="20%" y1="40%" x2="80%" y2="60%" stroke="white" strokeWidth="2" strokeDasharray="10,5" />
        </svg>
      </div>

      {/* Stats Bar */}
      <div className="relative z-10 bg-white/10 backdrop-blur-md px-6 py-4">
        <div className="flex items-center justify-around">
          <div className="text-center">
            <p className="text-white/80 text-sm mb-1">Quizzes Taken</p>
            <p className="text-white text-2xl">24</p>
          </div>
          <div className="w-px h-12 bg-white/30" />
          <div className="text-center">
            <p className="text-white/80 text-sm mb-1">Average Score</p>
            <p className="text-white text-2xl">87%</p>
          </div>
          <div className="w-px h-12 bg-white/30" />
          <div className="text-center">
            <p className="text-white/80 text-sm mb-1">Best Score</p>
            <p className="text-white text-2xl">100%</p>
          </div>
        </div>
      </div>

      <style jsx>{`
        @keyframes float {
          0%, 100% {
            transform: translateY(0px);
          }
          50% {
            transform: translateY(-20px);
          }
        }
        .animate-float {
          animation: float 3s ease-in-out infinite;
        }
      `}</style>
    </div>
  );
}
