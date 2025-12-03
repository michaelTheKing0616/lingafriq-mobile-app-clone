import React from 'react';
import { ArrowLeft, Volume2, Lightbulb, Heart } from 'lucide-react';

export function PronunciationGameScreen() {
  const [questionCount, setQuestionCount] = React.useState(1);
  const [score, setScore] = React.useState(0);
  const [lives, setLives] = React.useState(3);
  const [playing, setPlaying] = React.useState<number | null>(null);

  const options = [
    { id: 1, text: 'jam-BOH', pronunciation: 'JAM-boh', correct: true },
    { id: 2, text: 'JAM-bo', pronunciation: 'jam-BO' },
    { id: 3, text: 'jam-bo', pronunciation: 'jam-bo' },
    { id: 4, text: 'JAM-BOH', pronunciation: 'JAM-BOH' }
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#7B2CBF] to-[#CE1126] flex flex-col">
      {/* Header */}
      <div className="p-6">
        <div className="flex items-center justify-between mb-6">
          <button className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
            <ArrowLeft className="w-5 h-5 text-white" />
          </button>
          
          <div className="text-center">
            <h2 className="text-white">Pronunciation Game</h2>
            <p className="text-white/80 text-sm">Question {questionCount}/10</p>
          </div>
          
          <button className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
            <Lightbulb className="w-5 h-5 text-[#FCD116]" />
          </button>
        </div>

        {/* Game Stats */}
        <div className="grid grid-cols-2 gap-3">
          <div className="bg-white/20 backdrop-blur-sm rounded-xl p-3 text-center border border-white/40">
            <p className="text-white/80 text-sm mb-1">Score</p>
            <p className="text-white text-2xl">{score}</p>
          </div>
          <div className="bg-white/20 backdrop-blur-sm rounded-xl p-3 text-center border border-white/40">
            <div className="flex justify-center gap-1 mb-1">
              {[...Array(3)].map((_, i) => (
                <Heart key={i} className={`w-4 h-4 ${i < lives ? 'text-red-500 fill-red-500' : 'text-white/30'}`} />
              ))}
            </div>
            <p className="text-white/80 text-xs">{lives} Lives</p>
          </div>
        </div>
      </div>

      {/* Question Section */}
      <div className="flex-1 px-6 py-6 flex flex-col justify-center">
        {/* Main Audio Player */}
        <div className="bg-white/90 rounded-3xl p-8 shadow-2xl mb-8 text-center">
          <button 
            onClick={() => setPlaying(0)}
            className="w-24 h-24 bg-gradient-to-br from-[#7B2CBF] to-[#CE1126] rounded-full flex items-center justify-center mx-auto mb-4 shadow-xl hover:shadow-2xl transition-all active:scale-95"
          >
            <Volume2 className="w-12 h-12 text-white" />
          </button>
          <h3 className="text-gray-800 mb-2">Listen to the pronunciation</h3>
          <p className="text-gray-600 text-sm">Which pronunciation is correct?</p>
          
          {/* Waveform Visual (decorative) */}
          <div className="flex justify-center gap-1 mt-4">
            {[...Array(20)].map((_, i) => (
              <div
                key={i}
                className="w-1 bg-[#7B2CBF] rounded-full"
                style={{ height: `${Math.random() * 30 + 10}px`, opacity: playing === 0 ? 1 : 0.3 }}
              ></div>
            ))}
          </div>
        </div>

        {/* Answer Options */}
        <div className="space-y-3">
          {options.map((option) => (
            <button
              key={option.id}
              onClick={() => setPlaying(option.id)}
              className={`w-full bg-white/90 rounded-2xl p-5 shadow-lg hover:shadow-xl transition-all active:scale-98 ${
                playing === option.id ? 'ring-2 ring-[#FCD116]' : ''
              }`}
            >
              <div className="flex items-center gap-4">
                <div className={`w-14 h-14 rounded-full flex items-center justify-center flex-shrink-0 ${
                  playing === option.id 
                    ? 'bg-gradient-to-br from-[#7B2CBF] to-[#CE1126]' 
                    : 'bg-gray-200'
                }`}>
                  <Volume2 className={`w-6 h-6 ${playing === option.id ? 'text-white' : 'text-gray-600'}`} />
                </div>
                
                <div className="flex-1 text-left">
                  <p className="text-gray-800 mb-1">{option.text}</p>
                  <p className="text-gray-500 text-sm">{option.pronunciation}</p>
                </div>

                {/* Mini Waveform */}
                {playing === option.id && (
                  <div className="flex gap-0.5">
                    {[...Array(5)].map((_, i) => (
                      <div
                        key={i}
                        className="w-1 bg-[#7B2CBF] rounded-full animate-pulse"
                        style={{ height: `${Math.random() * 20 + 10}px` }}
                      ></div>
                    ))}
                  </div>
                )}
              </div>
            </button>
          ))}
        </div>
      </div>

      {/* Bottom Actions */}
      <div className="p-6">
        <button className="w-full bg-[#FCD116] text-gray-800 py-4 rounded-xl shadow-lg hover:shadow-xl transition-shadow">
          Submit Answer
        </button>
      </div>
    </div>
  );
}
