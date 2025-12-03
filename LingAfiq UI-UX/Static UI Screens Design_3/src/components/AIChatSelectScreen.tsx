import React from 'react';
import { ArrowLeft, Languages, GraduationCap, Sparkles } from 'lucide-react';

export function AIChatSelectScreen() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-[#7B2CBF] to-[#CE1126] relative overflow-hidden">
      {/* Pattern Overlay */}
      <div className="absolute inset-0 opacity-10">
        <div className="w-full h-full" style={{
          backgroundImage: 'repeating-linear-gradient(45deg, transparent, transparent 15px, rgba(255,255,255,.1) 15px, rgba(255,255,255,.1) 30px)'
        }}></div>
      </div>

      {/* Header */}
      <div className="relative z-10 p-6 flex items-center gap-4">
        <button className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
          <ArrowLeft className="w-5 h-5 text-white" />
        </button>
        <div className="flex-1">
          <h1 className="text-white">AI Language Assistant</h1>
          <p className="text-white/80 text-sm">Choose how you'd like to practice</p>
        </div>
      </div>

      {/* AI Icon */}
      <div className="relative z-10 flex justify-center mt-8 mb-12">
        <div className="w-24 h-24 bg-white/20 backdrop-blur-sm rounded-full flex items-center justify-center border-2 border-white/40">
          <Sparkles className="w-12 h-12 text-[#FCD116]" />
        </div>
      </div>

      {/* Mode Cards */}
      <div className="relative z-10 px-6 space-y-6 pb-12">
        {/* Translator Mode */}
        <div className="bg-white/95 backdrop-blur-sm rounded-3xl p-8 shadow-2xl cursor-pointer hover:bg-white transition-all hover:scale-105">
          <div className="flex items-start gap-4 mb-4">
            <div className="w-16 h-16 bg-gradient-to-br from-[#007A3D] to-[#005A2D] rounded-2xl flex items-center justify-center flex-shrink-0">
              <Languages className="w-8 h-8 text-white" />
            </div>
            <div className="flex-1">
              <div className="flex items-center gap-2 mb-2">
                <h2 className="text-gray-800">Translator Mode</h2>
                <span className="bg-green-100 text-green-700 text-xs px-3 py-1 rounded-full">Quick & Easy</span>
              </div>
              <p className="text-gray-600">
                Instant translations between English and Swahili. Perfect for quick lookups and learning new phrases.
              </p>
            </div>
          </div>
          
          {/* Features */}
          <div className="flex flex-wrap gap-2 mt-4">
            <span className="bg-gray-100 text-gray-700 text-xs px-3 py-1 rounded-full">⚡ Instant</span>
            <span className="bg-gray-100 text-gray-700 text-xs px-3 py-1 rounded-full">🔊 Audio</span>
            <span className="bg-gray-100 text-gray-700 text-xs px-3 py-1 rounded-full">📝 Text</span>
          </div>
        </div>

        {/* Tutor Mode */}
        <div className="bg-white/95 backdrop-blur-sm rounded-3xl p-8 shadow-2xl cursor-pointer hover:bg-white transition-all hover:scale-105">
          <div className="flex items-start gap-4 mb-4">
            <div className="w-16 h-16 bg-gradient-to-br from-[#FF6B35] to-[#CE1126] rounded-2xl flex items-center justify-center flex-shrink-0">
              <GraduationCap className="w-8 h-8 text-white" />
            </div>
            <div className="flex-1">
              <div className="flex items-center gap-2 mb-2">
                <h2 className="text-gray-800">Tutor Mode</h2>
                <span className="bg-orange-100 text-orange-700 text-xs px-3 py-1 rounded-full">Interactive Learning</span>
              </div>
              <p className="text-gray-600">
                Practice conversations with your AI tutor. Get feedback, corrections, and personalized learning tips.
              </p>
            </div>
          </div>
          
          {/* Features */}
          <div className="flex flex-wrap gap-2 mt-4">
            <span className="bg-gray-100 text-gray-700 text-xs px-3 py-1 rounded-full">💬 Conversation</span>
            <span className="bg-gray-100 text-gray-700 text-xs px-3 py-1 rounded-full">📊 Feedback</span>
            <span className="bg-gray-100 text-gray-700 text-xs px-3 py-1 rounded-full">🎯 Personalized</span>
          </div>
        </div>
      </div>

      {/* Bottom Gradient */}
      <div className="absolute bottom-0 left-0 right-0 h-32 bg-gradient-to-t from-black/30 to-transparent pointer-events-none"></div>
    </div>
  );
}
