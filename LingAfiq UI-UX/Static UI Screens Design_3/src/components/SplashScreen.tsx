import React from 'react';
import { ImageWithFallback } from './figma/ImageWithFallback';

export function SplashScreen() {
  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-gradient-to-b from-[#007A3D] via-[#005A2D] to-black relative overflow-hidden">
      {/* African Pattern Overlay */}
      <div className="absolute inset-0 opacity-10">
        <ImageWithFallback 
          src="https://images.unsplash.com/photo-1763256294121-303b83e7e767?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxBZnJpY2FuJTIwcGF0dGVybnMlMjBjb2xvcmZ1bHxlbnwxfHx8fDE3NjQ3NTg4MDJ8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral"
          alt="Pattern"
          className="w-full h-full object-cover"
        />
      </div>

      {/* Content */}
      <div className="relative z-10 flex flex-col items-center px-8">
        {/* App Logo */}
        <div className="mb-12">
          <div className="w-32 h-32 rounded-full bg-gradient-to-br from-[#FCD116] to-[#FF6B35] flex items-center justify-center shadow-2xl">
            <span className="text-6xl">🌍</span>
          </div>
        </div>

        {/* App Name */}
        <h1 className="text-white text-5xl mb-4 tracking-wide">LingAfriq</h1>
        
        {/* Circular Avatar */}
        <div className="w-40 h-40 rounded-full overflow-hidden border-4 border-[#FCD116] shadow-2xl mb-8">
          <ImageWithFallback 
            src="https://images.unsplash.com/photo-1688302017684-ddacc4767693?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxBZnJpY2FuJTIwd29tYW4lMjBwb3J0cmFpdHxlbnwxfHx8fDE3NjQ3NTc2MjJ8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral"
            alt="African person"
            className="w-full h-full object-cover"
          />
        </div>

        {/* Greeting */}
        <div className="text-center mb-2">
          <p className="text-[#FCD116] text-3xl mb-1">Sannu</p>
          <p className="text-white text-xl opacity-80">Hello in Hausa</p>
        </div>

        {/* Interesting Fact */}
        <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-6 max-w-md mt-8 border border-white/20">
          <p className="text-white text-center">
            <span className="text-[#FCD116]">💡 Did you know?</span>
            <br />
            Africa has over 2,000 languages, making it the most linguistically diverse continent in the world!
          </p>
        </div>

        {/* Loading Progress Bar */}
        <div className="w-64 mt-12">
          <div className="h-2 bg-white/20 rounded-full overflow-hidden">
            <div className="h-full bg-gradient-to-r from-[#FCD116] to-[#FF6B35] rounded-full w-2/3 animate-pulse"></div>
          </div>
          <p className="text-white/60 text-center mt-3">Loading your journey...</p>
        </div>
      </div>
    </div>
  );
}
