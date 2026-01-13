import React from 'react';
import { ArrowLeft, Menu, Shuffle, Globe, BookOpen } from 'lucide-react';

export function QuizSelectionMapScreen() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-[#FF6B35] via-[#FCD116] to-[#007A3D] relative overflow-hidden">
      {/* African Map Pattern Background */}
      <div className="absolute inset-0 opacity-20">
        <svg viewBox="0 0 400 800" className="w-full h-full">
          {/* Simplified Africa Map Shape */}
          <path
            d="M 200 100 Q 180 120, 170 150 Q 160 180, 165 210 Q 170 240, 180 270 Q 190 300, 200 330 Q 210 360, 220 390 Q 230 420, 235 450 Q 240 480, 235 510 Q 230 540, 220 570 Q 210 600, 200 630 Q 190 660, 185 690 L 215 690 Q 220 660, 230 630 Q 240 600, 250 570 Q 260 540, 265 510 Q 270 480, 265 450 Q 260 420, 250 390 Q 240 360, 230 330 Q 220 300, 215 270 Q 210 240, 215 210 Q 220 180, 230 150 Q 240 120, 250 100 Z"
            fill="white"
            opacity="0.3"
          />
        </svg>
      </div>

      {/* Header */}
      <div className="relative z-10 p-6 flex items-center justify-between">
        <button className="w-10 h-10 bg-white/90 rounded-full flex items-center justify-center shadow-lg">
          <ArrowLeft className="w-5 h-5 text-gray-800" />
        </button>
        <button className="w-10 h-10 bg-white/90 rounded-full flex items-center justify-center shadow-lg">
          <Menu className="w-5 h-5 text-gray-800" />
        </button>
      </div>

      {/* Title */}
      <div className="relative z-10 text-center px-6 mb-12">
        <h1 className="text-white mb-2">Choose Your Quiz</h1>
        <p className="text-white/90">Test your knowledge</p>
      </div>

      {/* Quiz Type Bubbles */}
      <div className="relative z-10 px-6 space-y-6">
        {/* Random Quiz */}
        <div className="flex justify-start">
          <div className="relative">
            <div className="w-48 h-48 bg-white/90 backdrop-blur-sm rounded-full shadow-2xl flex flex-col items-center justify-center cursor-pointer hover:bg-white transition-all hover:scale-105 border-4 border-white/50">
              <div className="w-16 h-16 bg-gradient-to-br from-[#7B2CBF] to-[#CE1126] rounded-full flex items-center justify-center mb-3">
                <Shuffle className="w-8 h-8 text-white" />
              </div>
              <h3 className="text-gray-800">Random Quiz</h3>
              <p className="text-gray-500 text-sm">Mixed questions</p>
            </div>
            {/* Connecting Line */}
            <div className="absolute -bottom-6 left-1/2 w-1 h-12 bg-white/40"></div>
          </div>
        </div>

        {/* Language Quiz */}
        <div className="flex justify-end">
          <div className="relative">
            <div className="w-52 h-52 bg-white/90 backdrop-blur-sm rounded-full shadow-2xl flex flex-col items-center justify-center cursor-pointer hover:bg-white transition-all hover:scale-105 border-4 border-white/50">
              <div className="w-16 h-16 bg-gradient-to-br from-[#007A3D] to-[#005A2D] rounded-full flex items-center justify-center mb-3">
                <Globe className="w-8 h-8 text-white" />
              </div>
              <h3 className="text-gray-800">Language Quiz</h3>
              <p className="text-gray-500 text-sm">Translation focus</p>
            </div>
            {/* Connecting Line */}
            <div className="absolute -bottom-6 left-1/2 w-1 h-12 bg-white/40"></div>
          </div>
        </div>

        {/* History Quiz */}
        <div className="flex justify-center">
          <div className="w-48 h-48 bg-white/90 backdrop-blur-sm rounded-full shadow-2xl flex flex-col items-center justify-center cursor-pointer hover:bg-white transition-all hover:scale-105 border-4 border-white/50">
            <div className="w-16 h-16 bg-gradient-to-br from-[#FF6B35] to-[#FCD116] rounded-full flex items-center justify-center mb-3">
              <BookOpen className="w-8 h-8 text-white" />
            </div>
            <h3 className="text-gray-800">History Quiz</h3>
            <p className="text-gray-500 text-sm">Cultural knowledge</p>
          </div>
        </div>
      </div>

      {/* Bottom Decoration */}
      <div className="absolute bottom-0 left-0 right-0 h-32 bg-gradient-to-t from-black/20 to-transparent"></div>
    </div>
  );
}
