import React from 'react';
import { ArrowLeft, X, Heart, Timer } from 'lucide-react';

export function WordMatchGameScreen() {
  const [timeLeft, setTimeLeft] = React.useState(180); // 3 minutes
  const [score, setScore] = React.useState(0);
  const [lives, setLives] = React.useState(3);

  const leftWords = [
    { id: 1, text: 'Jambo', matched: false },
    { id: 2, text: 'Asante', matched: true },
    { id: 3, text: 'Karibu', matched: false },
    { id: 4, text: 'Kwaheri', matched: false }
  ];

  const rightWords = [
    { id: 1, text: 'Hello', matched: false },
    { id: 2, text: 'Thank you', matched: true },
    { id: 3, text: 'Welcome', matched: false },
    { id: 4, text: 'Goodbye', matched: false }
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#007A3D] to-[#005A2D] flex flex-col">
      {/* Header */}
      <div className="p-6">
        <div className="flex items-center justify-between mb-6">
          <button className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
            <ArrowLeft className="w-5 h-5 text-white" />
          </button>
          
          <h2 className="text-white">Word Match</h2>
          
          <button className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
            <X className="w-5 h-5 text-white" />
          </button>
        </div>

        {/* Game Stats */}
        <div className="grid grid-cols-3 gap-3">
          <div className="bg-white/20 backdrop-blur-sm rounded-xl p-3 text-center border border-white/40">
            <Timer className="w-5 h-5 text-[#FCD116] mx-auto mb-1" />
            <p className="text-white text-sm">{Math.floor(timeLeft / 60)}:{(timeLeft % 60).toString().padStart(2, '0')}</p>
          </div>
          <div className="bg-white/20 backdrop-blur-sm rounded-xl p-3 text-center border border-white/40">
            <p className="text-[#FCD116] text-sm mb-1">Score</p>
            <p className="text-white">{score}</p>
          </div>
          <div className="bg-white/20 backdrop-blur-sm rounded-xl p-3 text-center border border-white/40">
            <div className="flex justify-center gap-1">
              {[...Array(3)].map((_, i) => (
                <Heart key={i} className={`w-4 h-4 ${i < lives ? 'text-red-500 fill-red-500' : 'text-white/30'}`} />
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Game Area */}
      <div className="flex-1 px-6 py-6">
        <div className="grid grid-cols-2 gap-6 h-full">
          {/* Left Column - Swahili */}
          <div className="space-y-3">
            <p className="text-white/80 text-center mb-4">Swahili</p>
            {leftWords.map((word) => (
              <button
                key={word.id}
                className={`w-full p-4 rounded-xl transition-all ${
                  word.matched
                    ? 'bg-green-500 text-white border-2 border-green-400'
                    : 'bg-white text-gray-800 hover:bg-gray-100'
                }`}
                disabled={word.matched}
              >
                {word.text}
              </button>
            ))}
          </div>

          {/* Right Column - English */}
          <div className="space-y-3">
            <p className="text-white/80 text-center mb-4">English</p>
            {rightWords.map((word) => (
              <button
                key={word.id}
                className={`w-full p-4 rounded-xl transition-all ${
                  word.matched
                    ? 'bg-green-500 text-white border-2 border-green-400'
                    : 'bg-white text-gray-800 hover:bg-gray-100'
                }`}
                disabled={word.matched}
              >
                {word.text}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Bottom Actions */}
      <div className="p-6 space-y-3">
        <button className="w-full bg-[#FCD116] text-gray-800 py-4 rounded-xl shadow-lg hover:shadow-xl transition-shadow">
          Submit Matches
        </button>
        <button className="w-full bg-white/20 text-white py-4 rounded-xl">
          Give Up
        </button>
      </div>
    </div>
  );
}
