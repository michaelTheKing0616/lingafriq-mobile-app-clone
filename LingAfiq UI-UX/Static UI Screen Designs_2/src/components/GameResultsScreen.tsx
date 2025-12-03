import { Trophy, Star, Share2, RotateCcw, Home } from 'lucide-react';

export function GameResultsScreen() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-[#FCD116] via-[#FF6B35] to-[#CE1126] flex items-center justify-center p-6">
      {/* Confetti Effect (Static) */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-10 left-10 text-4xl animate-bounce">🎉</div>
        <div className="absolute top-20 right-20 text-4xl animate-bounce" style={{ animationDelay: '0.2s' }}>⭐</div>
        <div className="absolute top-40 left-1/3 text-4xl animate-bounce" style={{ animationDelay: '0.4s' }}>✨</div>
        <div className="absolute bottom-40 right-10 text-4xl animate-bounce" style={{ animationDelay: '0.6s' }}>🎊</div>
      </div>

      <div className="w-full max-w-md relative z-10">
        {/* Trophy Animation */}
        <div className="flex justify-center mb-6 animate-bounce">
          <div className="w-32 h-32 bg-white rounded-full flex items-center justify-center shadow-2xl">
            <Trophy className="w-20 h-20 text-[#FCD116] fill-[#FCD116]" />
          </div>
        </div>

        {/* Results Card */}
        <div className="bg-white rounded-3xl p-8 shadow-2xl">
          {/* Title */}
          <div className="text-center mb-6">
            <h1 className="text-gray-900 mb-2">Excellent Work!</h1>
            <p className="text-gray-600">You're getting better every day</p>
          </div>

          {/* Score Circle */}
          <div className="flex justify-center mb-6">
            <div className="relative w-48 h-48">
              <svg className="w-48 h-48 transform -rotate-90">
                <circle
                  cx="96"
                  cy="96"
                  r="88"
                  stroke="#E5E7EB"
                  strokeWidth="16"
                  fill="none"
                />
                <circle
                  cx="96"
                  cy="96"
                  r="88"
                  stroke="url(#gradient)"
                  strokeWidth="16"
                  fill="none"
                  strokeDasharray="553"
                  strokeDashoffset="111"
                  strokeLinecap="round"
                />
                <defs>
                  <linearGradient id="gradient" x1="0%" y1="0%" x2="100%" y2="100%">
                    <stop offset="0%" stopColor="#007A3D" />
                    <stop offset="100%" stopColor="#FF6B35" />
                  </linearGradient>
                </defs>
              </svg>
              <div className="absolute inset-0 flex flex-col items-center justify-center">
                <span className="text-5xl text-gray-900">80%</span>
                <span className="text-gray-600 mt-1">Accuracy</span>
              </div>
            </div>
          </div>

          {/* Stats Grid */}
          <div className="grid grid-cols-2 gap-4 mb-6">
            <div className="bg-gradient-to-br from-[#007A3D]/10 to-[#007A3D]/5 rounded-2xl p-4 text-center">
              <div className="text-3xl mb-1">8/10</div>
              <div className="text-sm text-gray-600">Correct</div>
            </div>
            <div className="bg-gradient-to-br from-[#FF6B35]/10 to-[#FF6B35]/5 rounded-2xl p-4 text-center">
              <div className="text-3xl mb-1">2:34</div>
              <div className="text-sm text-gray-600">Time</div>
            </div>
            <div className="bg-gradient-to-br from-[#FCD116]/10 to-[#FCD116]/5 rounded-2xl p-4 text-center">
              <div className="text-3xl mb-1">+320</div>
              <div className="text-sm text-gray-600">XP Earned</div>
            </div>
            <div className="bg-gradient-to-br from-[#7B2CBF]/10 to-[#7B2CBF]/5 rounded-2xl p-4 text-center">
              <div className="text-3xl mb-1">#8</div>
              <div className="text-sm text-gray-600">Rank</div>
            </div>
          </div>

          {/* Stars */}
          <div className="flex justify-center gap-2 mb-6">
            <Star className="w-10 h-10 text-[#FCD116] fill-[#FCD116]" />
            <Star className="w-10 h-10 text-[#FCD116] fill-[#FCD116]" />
            <Star className="w-10 h-10 text-[#FCD116] fill-[#FCD116]" />
          </div>

          {/* New Badge Alert */}
          <div className="bg-gradient-to-r from-[#7B2CBF] to-[#9D4EDD] rounded-2xl p-4 mb-6 flex items-center gap-4">
            <div className="text-4xl">🏆</div>
            <div className="flex-1 text-white">
              <p className="text-sm opacity-90">New Achievement!</p>
              <p>Speed Demon Badge</p>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="space-y-3">
            <button className="w-full bg-gradient-to-r from-[#007A3D] to-[#005A2D] text-white py-4 rounded-2xl shadow-lg hover:shadow-xl transition-all flex items-center justify-center gap-2">
              <RotateCcw className="w-5 h-5" />
              <span>Play Again</span>
            </button>
            
            <button className="w-full bg-[#FF6B35] text-white py-4 rounded-2xl shadow-lg hover:shadow-xl transition-all flex items-center justify-center gap-2">
              <Share2 className="w-5 h-5" />
              <span>Share Score</span>
            </button>
            
            <button className="w-full bg-white text-gray-700 py-4 rounded-2xl border-2 border-gray-200 hover:bg-gray-50 transition-all flex items-center justify-center gap-2">
              <Home className="w-5 h-5" />
              <span>Return to Games</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
