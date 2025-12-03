import { Puzzle, Zap, Mic, Trophy } from 'lucide-react';

export function GameSelectionScreen() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-[#FF6B35]/10 to-white">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#FF6B35] to-[#FCD116] px-6 py-12 rounded-b-[32px] shadow-lg">
        <button className="p-2 hover:bg-white/20 rounded-lg transition-colors mb-6">
          <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
          </svg>
        </button>
        
        <div className="text-center text-white">
          <div className="text-5xl mb-4">🎮</div>
          <h1>Language Games</h1>
          <p className="text-white/90 mt-2">Learn through play</p>
        </div>
      </div>

      {/* Language Selector */}
      <div className="px-6 py-6">
        <label className="block text-gray-700 mb-3">Choose Language</label>
        <div className="relative">
          <select className="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-[#FF6B35] outline-none transition-colors bg-white appearance-none">
            <option>🇹🇿 Swahili</option>
            <option>🇳🇬 Yoruba</option>
            <option>🇪🇹 Amharic</option>
            <option>🇿🇦 Zulu</option>
            <option>🇳🇬 Hausa</option>
            <option>🇳🇬 Igbo</option>
          </select>
          <div className="absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none">
            <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
            </svg>
          </div>
        </div>
      </div>

      {/* Game Cards */}
      <div className="px-6 pb-6 space-y-4">
        {/* Word Match Game */}
        <div className="bg-gradient-to-br from-[#007A3D] to-[#005A2D] rounded-3xl p-6 shadow-xl">
          <div className="flex items-start justify-between mb-4">
            <div className="w-16 h-16 bg-white/20 backdrop-blur-sm rounded-2xl flex items-center justify-center">
              <Puzzle className="w-8 h-8 text-white" />
            </div>
            <div className="bg-white/20 backdrop-blur-sm px-3 py-1 rounded-full">
              <span className="text-white text-sm">Easy</span>
            </div>
          </div>
          
          <h2 className="text-white mb-2">Word Match</h2>
          <p className="text-white/80 text-sm mb-4">Match words to their translations. Test your vocabulary skills!</p>
          
          <div className="flex items-center justify-between">
            <div className="text-white/60 text-sm">
              <Trophy className="w-4 h-4 inline mr-1" />
              Best: 850 pts
            </div>
            <button className="bg-white text-[#007A3D] px-6 py-3 rounded-xl hover:bg-gray-100 transition-colors">
              Play Now
            </button>
          </div>
        </div>

        {/* Speed Challenge */}
        <div className="bg-gradient-to-br from-[#FF6B35] to-[#CE1126] rounded-3xl p-6 shadow-xl">
          <div className="flex items-start justify-between mb-4">
            <div className="w-16 h-16 bg-white/20 backdrop-blur-sm rounded-2xl flex items-center justify-center">
              <Zap className="w-8 h-8 text-white fill-white" />
            </div>
            <div className="bg-white/20 backdrop-blur-sm px-3 py-1 rounded-full">
              <span className="text-white text-sm">Medium</span>
            </div>
          </div>
          
          <h2 className="text-white mb-2">Speed Challenge</h2>
          <p className="text-white/80 text-sm mb-4">Answer as fast as you can! Race against the clock.</p>
          
          <div className="flex items-center justify-between">
            <div className="text-white/60 text-sm">
              <Trophy className="w-4 h-4 inline mr-1" />
              Best: 1,240 pts
            </div>
            <button className="bg-white text-[#FF6B35] px-6 py-3 rounded-xl hover:bg-gray-100 transition-colors">
              Play Now
            </button>
          </div>
        </div>

        {/* Pronunciation Game */}
        <div className="bg-gradient-to-br from-[#7B2CBF] to-[#9D4EDD] rounded-3xl p-6 shadow-xl">
          <div className="flex items-start justify-between mb-4">
            <div className="w-16 h-16 bg-white/20 backdrop-blur-sm rounded-2xl flex items-center justify-center">
              <Mic className="w-8 h-8 text-white" />
            </div>
            <div className="bg-white/20 backdrop-blur-sm px-3 py-1 rounded-full">
              <span className="text-white text-sm">Hard</span>
            </div>
          </div>
          
          <h2 className="text-white mb-2">Pronunciation Practice</h2>
          <p className="text-white/80 text-sm mb-4">Listen and identify correct pronunciation. Train your ear!</p>
          
          <div className="flex items-center justify-between">
            <div className="text-white/60 text-sm">
              <Trophy className="w-4 h-4 inline mr-1" />
              Best: 620 pts
            </div>
            <button className="bg-white text-[#7B2CBF] px-6 py-3 rounded-xl hover:bg-gray-100 transition-colors">
              Play Now
            </button>
          </div>
        </div>
      </div>

      {/* Leaderboard Preview */}
      <div className="px-6 pb-6">
        <div className="bg-white rounded-3xl p-6 shadow-lg">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-gray-900">Top Players Today</h3>
            <button className="text-[#FF6B35] text-sm">View All</button>
          </div>
          
          <div className="space-y-3">
            <div className="flex items-center gap-3">
              <span className="text-xl">🥇</span>
              <div className="flex-1">
                <p className="text-gray-900">Kwame Mensah</p>
                <p className="text-xs text-gray-500">2,450 pts today</p>
              </div>
            </div>
            <div className="flex items-center gap-3">
              <span className="text-xl">🥈</span>
              <div className="flex-1">
                <p className="text-gray-900">Amara Okafor</p>
                <p className="text-xs text-gray-500">2,120 pts today</p>
              </div>
            </div>
            <div className="flex items-center gap-3">
              <span className="text-xl">🥉</span>
              <div className="flex-1">
                <p className="text-gray-900">Zainab Hassan</p>
                <p className="text-xs text-gray-500">1,890 pts today</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="h-20" />
    </div>
  );
}
