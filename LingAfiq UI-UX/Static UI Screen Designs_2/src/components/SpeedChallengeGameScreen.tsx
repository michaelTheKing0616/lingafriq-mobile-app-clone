import { Zap, Pause } from 'lucide-react';

export function SpeedChallengeGameScreen() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-[#FF6B35] via-[#FCD116] to-[#FF6B35]">
      {/* Header */}
      <div className="px-6 py-4 flex items-center justify-between">
        <button className="p-2 hover:bg-white/20 rounded-lg transition-colors">
          <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
          </svg>
        </button>
        <h2 className="text-white">Speed Challenge</h2>
        <button className="p-2 hover:bg-white/20 rounded-lg transition-colors">
          <Pause className="w-6 h-6 text-white" />
        </button>
      </div>

      {/* Timer Circle */}
      <div className="flex justify-center py-8">
        <div className="relative w-40 h-40">
          {/* Timer Background */}
          <svg className="w-40 h-40 transform -rotate-90">
            <circle
              cx="80"
              cy="80"
              r="70"
              stroke="rgba(255,255,255,0.3)"
              strokeWidth="12"
              fill="none"
            />
            <circle
              cx="80"
              cy="80"
              r="70"
              stroke="white"
              strokeWidth="12"
              fill="none"
              strokeDasharray="440"
              strokeDashoffset="110"
              strokeLinecap="round"
            />
          </svg>
          <div className="absolute inset-0 flex flex-col items-center justify-center">
            <span className="text-white text-5xl">38</span>
            <span className="text-white/80 text-sm">seconds</span>
          </div>
        </div>
      </div>

      {/* Game Stats */}
      <div className="px-6 mb-6 flex justify-center gap-4">
        <div className="bg-white/20 backdrop-blur-sm px-6 py-3 rounded-2xl text-center">
          <p className="text-white/80 text-sm">Question</p>
          <p className="text-white text-xl">7/20</p>
        </div>
        <div className="bg-white/20 backdrop-blur-sm px-6 py-3 rounded-2xl text-center">
          <p className="text-white/80 text-sm">Score</p>
          <p className="text-white text-xl">850</p>
        </div>
        <div className="bg-white/20 backdrop-blur-sm px-6 py-3 rounded-2xl text-center">
          <p className="text-white/80 text-sm">Streak</p>
          <p className="text-white text-xl flex items-center gap-1">
            <Zap className="w-5 h-5 fill-white" />5
          </p>
        </div>
      </div>

      {/* Question Card */}
      <div className="px-6 mb-6">
        <div className="bg-white rounded-3xl p-8 shadow-2xl">
          <p className="text-gray-600 text-sm mb-2">Translate to English:</p>
          <h2 className="text-gray-900 text-center mb-4">Habari za asubuhi?</h2>
          
          {/* Combo Multiplier */}
          <div className="flex justify-center mb-4">
            <div className="bg-gradient-to-r from-[#FCD116] to-[#FF6B35] text-white px-4 py-2 rounded-full text-sm flex items-center gap-2 animate-pulse">
              <Zap className="w-4 h-4 fill-white" />
              <span>5x COMBO!</span>
            </div>
          </div>
        </div>
      </div>

      {/* Answer Options */}
      <div className="px-6 space-y-3">
        <button className="w-full bg-white hover:bg-[#007A3D] hover:text-white text-gray-900 py-5 rounded-2xl transition-all shadow-lg hover:shadow-xl hover:scale-105 active:scale-95">
          Good morning news?
        </button>
        <button className="w-full bg-white hover:bg-[#007A3D] hover:text-white text-gray-900 py-5 rounded-2xl transition-all shadow-lg hover:shadow-xl hover:scale-105 active:scale-95">
          How are you this evening?
        </button>
        <button className="w-full bg-gradient-to-r from-[#007A3D] to-[#005A2D] text-white py-5 rounded-2xl shadow-xl ring-4 ring-white/50 transform scale-105">
          How are you this morning?
        </button>
        <button className="w-full bg-white hover:bg-[#007A3D] hover:text-white text-gray-900 py-5 rounded-2xl transition-all shadow-lg hover:shadow-xl hover:scale-105 active:scale-95">
          What is your name?
        </button>
      </div>

      {/* Energy Bar */}
      <div className="px-6 py-6">
        <div className="bg-white/30 backdrop-blur-sm rounded-full h-4 overflow-hidden">
          <div 
            className="bg-gradient-to-r from-white via-yellow-200 to-white h-full rounded-full transition-all animate-pulse"
            style={{ width: '75%' }}
          />
        </div>
      </div>

      <div className="h-20" />
    </div>
  );
}
