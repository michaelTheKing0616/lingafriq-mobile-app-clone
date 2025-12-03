import { Clock, Heart, ArrowLeft } from 'lucide-react';

export function WordMatchGameScreen() {
  const leftWords = [
    { id: 1, word: 'Jambo', matched: false },
    { id: 2, word: 'Asante', matched: true },
    { id: 3, word: 'Karibu', matched: false },
    { id: 4, word: 'Habari', matched: false },
    { id: 5, word: 'Ndiyo', matched: false },
  ];

  const rightWords = [
    { id: 1, word: 'Welcome', matched: false },
    { id: 2, word: 'Thank you', matched: true },
    { id: 3, word: 'Hello', matched: false },
    { id: 4, word: 'News/How are you', matched: false },
    { id: 5, word: 'Yes', matched: false },
  ];

  return (
    <div className="min-h-screen bg-gradient-to-b from-[#007A3D]/10 to-white">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#007A3D] to-[#005A2D] px-6 py-4">
        <div className="flex items-center justify-between mb-4">
          <button className="p-2 hover:bg-white/10 rounded-lg transition-colors">
            <ArrowLeft className="w-6 h-6 text-white" />
          </button>
          <h2 className="text-white">Word Match</h2>
          <button className="p-2 hover:bg-white/10 rounded-lg transition-colors">
            <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* Game Stats */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2 bg-white/20 backdrop-blur-sm px-4 py-2 rounded-full">
            <Clock className="w-5 h-5 text-white" />
            <span className="text-white">2:34</span>
          </div>
          
          <div className="flex items-center gap-2 bg-white/20 backdrop-blur-sm px-4 py-2 rounded-full">
            <span className="text-white">Score: 150</span>
          </div>
          
          <div className="flex items-center gap-1">
            <Heart className="w-6 h-6 text-red-400 fill-red-400" />
            <Heart className="w-6 h-6 text-red-400 fill-red-400" />
            <Heart className="w-6 h-6 text-red-400 fill-red-400" />
          </div>
        </div>
      </div>

      {/* Instructions */}
      <div className="px-6 py-4 bg-blue-50 border-l-4 border-[#007A3D] mx-6 mt-6 rounded-r-xl">
        <p className="text-gray-700 text-sm">Match the Swahili words on the left with their English translations on the right. Tap cards to select.</p>
      </div>

      {/* Game Area */}
      <div className="px-6 py-8">
        <div className="flex gap-4">
          {/* Left Column - African Language */}
          <div className="flex-1 space-y-3">
            <h3 className="text-center text-gray-700 mb-4">Swahili</h3>
            {leftWords.map((item, index) => (
              <div
                key={item.id}
                className={`p-4 rounded-2xl text-center transition-all cursor-pointer ${
                  item.matched
                    ? 'bg-gradient-to-r from-[#007A3D] to-[#005A2D] text-white shadow-lg scale-95'
                    : index === 0
                    ? 'bg-[#FF6B35] text-white shadow-lg ring-4 ring-[#FF6B35]/30'
                    : 'bg-white border-2 border-gray-200 hover:border-[#007A3D] hover:shadow-md'
                }`}
              >
                <span>{item.word}</span>
              </div>
            ))}
          </div>

          {/* Connection Lines Visualization */}
          <div className="flex items-center justify-center w-12">
            <svg className="w-full h-full" style={{ overflow: 'visible' }}>
              {/* Example matched line */}
              <line
                x1="0"
                y1="100"
                x2="48"
                y2="100"
                stroke="#007A3D"
                strokeWidth="3"
                strokeDasharray="5,5"
              />
            </svg>
          </div>

          {/* Right Column - English */}
          <div className="flex-1 space-y-3">
            <h3 className="text-center text-gray-700 mb-4">English</h3>
            {rightWords.map((item) => (
              <div
                key={item.id}
                className={`p-4 rounded-2xl text-center transition-all cursor-pointer ${
                  item.matched
                    ? 'bg-gradient-to-r from-[#007A3D] to-[#005A2D] text-white shadow-lg scale-95'
                    : 'bg-white border-2 border-gray-200 hover:border-[#007A3D] hover:shadow-md'
                }`}
              >
                <span className="text-sm">{item.word}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Progress */}
      <div className="px-6 py-4">
        <div className="bg-gray-200 rounded-full h-3 overflow-hidden">
          <div className="bg-gradient-to-r from-[#007A3D] to-[#FF6B35] h-full rounded-full transition-all" style={{ width: '20%' }} />
        </div>
        <p className="text-center text-sm text-gray-600 mt-2">1 of 5 matched</p>
      </div>

      {/* Action Buttons */}
      <div className="px-6 pb-6 flex gap-3">
        <button className="flex-1 bg-gray-100 text-gray-700 py-3 rounded-xl hover:bg-gray-200 transition-colors">
          Give Up
        </button>
        <button className="flex-1 bg-gradient-to-r from-[#007A3D] to-[#005A2D] text-white py-3 rounded-xl shadow-lg hover:shadow-xl transition-all">
          Submit Match
        </button>
      </div>

      <div className="h-20" />
    </div>
  );
}
