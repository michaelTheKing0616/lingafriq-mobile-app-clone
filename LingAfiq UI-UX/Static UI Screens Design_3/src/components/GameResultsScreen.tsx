import React from 'react';
import { Trophy, Share2, RotateCcw, Home, Star } from 'lucide-react';

export function GameResultsScreen() {
  const finalScore = 2450;
  const accuracy = 85;
  const timeTaken = '2:34';
  const xpEarned = 150;
  const stars = 3;

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#FCD116] via-[#FF6B35] to-[#CE1126] flex flex-col items-center justify-center p-6">
      {/* Confetti Background Effect */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        {[...Array(20)].map((_, i) => (
          <div
            key={i}
            className="absolute w-3 h-3 bg-white/30 rounded-full animate-bounce"
            style={{
              left: `${Math.random() * 100}%`,
              top: `${Math.random() * 100}%`,
              animationDelay: `${Math.random() * 2}s`,
              animationDuration: `${2 + Math.random() * 2}s`
            }}
          ></div>
        ))}
      </div>

      {/* Content */}
      <div className="relative z-10 w-full max-w-md">
        {/* Trophy Icon */}
        <div className="flex justify-center mb-8">
          <div className="w-32 h-32 bg-white/20 backdrop-blur-sm rounded-full flex items-center justify-center border-4 border-white/40 shadow-2xl">
            <Trophy className="w-16 h-16 text-[#FCD116]" />
          </div>
        </div>

        {/* Title */}
        <h1 className="text-white text-center mb-2">Excellent Work!</h1>
        <p className="text-white/90 text-center mb-8">You've completed the game</p>

        {/* Score Card */}
        <div className="bg-white/95 backdrop-blur-sm rounded-3xl p-8 shadow-2xl mb-6">
          {/* Final Score */}
          <div className="text-center mb-6">
            <p className="text-gray-600 text-sm mb-2">Final Score</p>
            <p className="text-5xl text-[#007A3D] mb-4">{finalScore}</p>
            
            {/* Stars */}
            <div className="flex justify-center gap-2">
              {[...Array(3)].map((_, i) => (
                <Star
                  key={i}
                  className={`w-8 h-8 ${
                    i < stars ? 'text-[#FCD116] fill-[#FCD116]' : 'text-gray-300'
                  }`}
                />
              ))}
            </div>
          </div>

          {/* Stats Grid */}
          <div className="grid grid-cols-3 gap-4 mb-6">
            <div className="text-center">
              <p className="text-3xl mb-1">⚡</p>
              <p className="text-gray-800">{accuracy}%</p>
              <p className="text-gray-500 text-xs">Accuracy</p>
            </div>
            <div className="text-center">
              <p className="text-3xl mb-1">⏱️</p>
              <p className="text-gray-800">{timeTaken}</p>
              <p className="text-gray-500 text-xs">Time</p>
            </div>
            <div className="text-center">
              <p className="text-3xl mb-1">✨</p>
              <p className="text-gray-800">+{xpEarned}</p>
              <p className="text-gray-500 text-xs">XP Earned</p>
            </div>
          </div>

          {/* Leaderboard Position */}
          <div className="bg-gradient-to-r from-[#007A3D] to-[#005A2D] rounded-2xl p-4 text-center">
            <p className="text-white/80 text-sm mb-1">Leaderboard Position</p>
            <p className="text-white text-2xl">#12 🎯</p>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="space-y-3">
          <button className="w-full bg-white text-gray-800 py-4 rounded-xl shadow-lg hover:shadow-xl transition-shadow flex items-center justify-center gap-3">
            <Share2 className="w-5 h-5" />
            Share Score
          </button>

          <button className="w-full bg-white/20 backdrop-blur-sm text-white py-4 rounded-xl border border-white/40 hover:bg-white/30 transition-colors flex items-center justify-center gap-3">
            <RotateCcw className="w-5 h-5" />
            Play Again
          </button>

          <button className="w-full bg-white/10 backdrop-blur-sm text-white py-4 rounded-xl border border-white/30 hover:bg-white/20 transition-colors flex items-center justify-center gap-3">
            <Home className="w-5 h-5" />
            Return to Games
          </button>
        </div>
      </div>
    </div>
  );
}
