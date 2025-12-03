import { Volume2, Heart, HelpCircle } from 'lucide-react';

export function PronunciationGameScreen() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-[#7B2CBF]/10 to-white">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#7B2CBF] to-[#9D4EDD] px-6 py-4">
        <div className="flex items-center justify-between mb-4">
          <button className="p-2 hover:bg-white/10 rounded-lg transition-colors">
            <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
            </svg>
          </button>
          <h2 className="text-white">Pronunciation</h2>
          <button className="p-2 hover:bg-white/10 rounded-lg transition-colors">
            <HelpCircle className="w-6 h-6 text-white" />
          </button>
        </div>

        {/* Stats */}
        <div className="flex items-center justify-between">
          <div className="bg-white/20 backdrop-blur-sm px-4 py-2 rounded-full">
            <span className="text-white">Question 3/10</span>
          </div>
          
          <div className="bg-white/20 backdrop-blur-sm px-4 py-2 rounded-full">
            <span className="text-white">Score: 240</span>
          </div>
          
          <div className="flex items-center gap-1">
            <Heart className="w-5 h-5 text-red-400 fill-red-400" />
            <Heart className="w-5 h-5 text-red-400 fill-red-400" />
            <Heart className="w-5 h-5 text-white/40" />
          </div>
        </div>
      </div>

      {/* Instructions */}
      <div className="px-6 py-6">
        <div className="bg-purple-50 border-l-4 border-[#7B2CBF] p-4 rounded-r-xl">
          <p className="text-gray-700 text-sm">Listen to the word and choose the correct pronunciation below</p>
        </div>
      </div>

      {/* Main Audio Player */}
      <div className="px-6 mb-8">
        <div className="bg-gradient-to-br from-[#7B2CBF] to-[#9D4EDD] rounded-3xl p-8 shadow-2xl">
          <div className="text-center mb-6">
            <h3 className="text-white/80 mb-2">Listen carefully:</h3>
            <h2 className="text-white text-3xl">Habari</h2>
          </div>
          
          {/* Play Button */}
          <button className="w-full bg-white/20 backdrop-blur-sm hover:bg-white/30 transition-all py-6 rounded-2xl flex items-center justify-center gap-3 group">
            <div className="w-16 h-16 bg-white rounded-full flex items-center justify-center group-hover:scale-110 transition-transform">
              <Volume2 className="w-8 h-8 text-[#7B2CBF]" />
            </div>
            <span className="text-white text-lg">Play Audio</span>
          </button>

          {/* Waveform Visualization */}
          <div className="flex items-center justify-center gap-1 mt-4 h-12">
            {[...Array(20)].map((_, i) => (
              <div
                key={i}
                className="w-1 bg-white/50 rounded-full"
                style={{ height: `${Math.random() * 100}%` }}
              />
            ))}
          </div>
        </div>
      </div>

      {/* Answer Options */}
      <div className="px-6">
        <h3 className="text-gray-900 mb-4">Choose the correct pronunciation:</h3>
        
        <div className="space-y-3">
          {/* Option 1 */}
          <div className="bg-white border-2 border-gray-200 rounded-2xl p-4 hover:border-[#7B2CBF] hover:shadow-lg transition-all cursor-pointer">
            <div className="flex items-center gap-4">
              <button className="w-12 h-12 bg-gradient-to-br from-[#7B2CBF] to-[#9D4EDD] rounded-full flex items-center justify-center hover:scale-110 transition-transform">
                <Volume2 className="w-6 h-6 text-white" />
              </button>
              <div className="flex-1">
                <p className="text-gray-900">/hah-BAH-ree/</p>
                <p className="text-sm text-gray-500">Emphasis on second syllable</p>
              </div>
            </div>
          </div>

          {/* Option 2 - Selected */}
          <div className="bg-gradient-to-br from-[#7B2CBF]/10 to-[#9D4EDD]/10 border-2 border-[#7B2CBF] rounded-2xl p-4 shadow-lg ring-4 ring-[#7B2CBF]/20">
            <div className="flex items-center gap-4">
              <button className="w-12 h-12 bg-gradient-to-br from-[#7B2CBF] to-[#9D4EDD] rounded-full flex items-center justify-center hover:scale-110 transition-transform">
                <Volume2 className="w-6 h-6 text-white" />
              </button>
              <div className="flex-1">
                <p className="text-gray-900">/ha-BAH-ri/</p>
                <p className="text-sm text-gray-500">Emphasis on middle syllable</p>
              </div>
              <div className="w-6 h-6 bg-[#7B2CBF] rounded-full flex items-center justify-center">
                <svg className="w-4 h-4 text-white" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                </svg>
              </div>
            </div>
          </div>

          {/* Option 3 */}
          <div className="bg-white border-2 border-gray-200 rounded-2xl p-4 hover:border-[#7B2CBF] hover:shadow-lg transition-all cursor-pointer">
            <div className="flex items-center gap-4">
              <button className="w-12 h-12 bg-gradient-to-br from-[#7B2CBF] to-[#9D4EDD] rounded-full flex items-center justify-center hover:scale-110 transition-transform">
                <Volume2 className="w-6 h-6 text-white" />
              </button>
              <div className="flex-1">
                <p className="text-gray-900">/HAH-bah-ree/</p>
                <p className="text-sm text-gray-500">Emphasis on first syllable</p>
              </div>
            </div>
          </div>

          {/* Option 4 */}
          <div className="bg-white border-2 border-gray-200 rounded-2xl p-4 hover:border-[#7B2CBF] hover:shadow-lg transition-all cursor-pointer">
            <div className="flex items-center gap-4">
              <button className="w-12 h-12 bg-gradient-to-br from-[#7B2CBF] to-[#9D4EDD] rounded-full flex items-center justify-center hover:scale-110 transition-transform">
                <Volume2 className="w-6 h-6 text-white" />
              </button>
              <div className="flex-1">
                <p className="text-gray-900">/ha-bah-REE/</p>
                <p className="text-sm text-gray-500">Emphasis on last syllable</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Action Buttons */}
      <div className="px-6 py-6 flex gap-3">
        <button className="px-6 py-3 bg-gray-100 text-gray-700 rounded-xl hover:bg-gray-200 transition-colors">
          Skip
        </button>
        <button className="flex-1 bg-gradient-to-r from-[#7B2CBF] to-[#9D4EDD] text-white py-3 rounded-xl shadow-lg hover:shadow-xl transition-all">
          Check Answer
        </button>
      </div>

      <div className="h-20" />
    </div>
  );
}
