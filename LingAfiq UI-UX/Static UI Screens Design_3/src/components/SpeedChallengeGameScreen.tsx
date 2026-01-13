import React from 'react';
import { ArrowLeft, Pause, Zap } from 'lucide-react';

export function SpeedChallengeGameScreen() {
  const [timeLeft, setTimeLeft] = React.useState(60);
  const [questionCount, setQuestionCount] = React.useState(1);
  const [score, setScore] = React.useState(0);
  const [streak, setStreak] = React.useState(5);
  const [multiplier, setMultiplier] = React.useState(2);

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#FF6B35] via-[#FCD116] to-[#FF6B35] flex flex-col">
      {/* Header */}
      <div className="p-6">
        <div className="flex items-center justify-between mb-6">
          <button className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
            <ArrowLeft className="w-5 h-5 text-white" />
          </button>
          
          <div className="flex-1 text-center">
            <h2 className="text-white">Speed Challenge</h2>
            <p className="text-white/80 text-sm">Question {questionCount}/20</p>
          </div>
          
          <button className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
            <Pause className="w-5 h-5 text-white" />
          </button>
        </div>

        {/* Game Stats */}
        <div className="grid grid-cols-3 gap-3 mb-6">
          <div className="bg-white/90 rounded-xl p-3 text-center">
            <p className="text-3xl mb-1">⏱️</p>
            <p className="text-2xl text-[#FF6B35]">{timeLeft}s</p>
          </div>
          <div className="bg-white/90 rounded-xl p-3 text-center">
            <p className="text-gray-600 text-sm">Score</p>
            <p className="text-2xl text-gray-800">{score}</p>
          </div>
          <div className="bg-white/90 rounded-xl p-3 text-center">
            <p className="text-3xl mb-1">🔥</p>
            <p className="text-2xl text-[#FF6B35]">{streak}</p>
          </div>
        </div>

        {/* Combo Multiplier */}
        {multiplier > 1 && (
          <div className="bg-white/20 backdrop-blur-sm rounded-xl p-4 border-2 border-[#FCD116] text-center mb-6">
            <div className="flex items-center justify-center gap-2">
              <Zap className="w-6 h-6 text-[#FCD116]" />
              <p className="text-white text-xl">COMBO x{multiplier}!</p>
              <Zap className="w-6 h-6 text-[#FCD116]" />
            </div>
          </div>
        )}
      </div>

      {/* Question */}
      <div className="flex-1 px-6 flex flex-col justify-center">
        <div className="bg-white/90 rounded-3xl p-8 shadow-2xl mb-8">
          <h2 className="text-gray-800 text-center">
            What is the English translation of "Habari"?
          </h2>
        </div>

        {/* Answer Options */}
        <div className="grid grid-cols-2 gap-4">
          {[
            { text: 'Hello', color: 'from-[#007A3D] to-[#005A2D]' },
            { text: 'How are you?', color: 'from-[#7B2CBF] to-[#CE1126]' },
            { text: 'Goodbye', color: 'from-[#FF6B35] to-[#CE1126]' },
            { text: 'Thank you', color: 'from-[#FCD116] to-[#FF6B35]' }
          ].map((option, index) => (
            <button
              key={index}
              className={`bg-gradient-to-br ${option.color} text-white p-6 rounded-2xl shadow-lg hover:shadow-xl transition-all active:scale-95`}
            >
              <p className="text-xl">{option.text}</p>
            </button>
          ))}
        </div>
      </div>

      {/* Score Running Total */}
      <div className="p-6">
        <div className="bg-white/90 rounded-xl p-4 flex items-center justify-between">
          <div>
            <p className="text-gray-600 text-sm">Running Total</p>
            <p className="text-2xl text-[#007A3D]">{score} points</p>
          </div>
          <div className="text-right">
            <p className="text-gray-600 text-sm">Streak Bonus</p>
            <p className="text-xl text-[#FF6B35]">+{streak * 10} pts</p>
          </div>
        </div>
      </div>
    </div>
  );
}
