import React from 'react';
import { ArrowLeft, BookOpen, Target, Clock, Award } from 'lucide-react';
import { ImageWithFallback } from './figma/ImageWithFallback';

export function LanguageDetailScreen() {
  return (
    <div className="min-h-screen bg-white">
      {/* Header with Language Image */}
      <div className="relative h-64">
        <ImageWithFallback
          src="https://images.unsplash.com/photo-1696299871960-59ae209db58b?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxzd2FoaWxpJTIwY3VsdHVyZXxlbnwxfHx8fDE3NjQ3NTA2NzB8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral"
          alt="Swahili"
          className="w-full h-full object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-black/80 to-transparent" />
        
        {/* Back Button */}
        <button className="absolute top-6 left-4 p-2 bg-white/20 backdrop-blur-sm rounded-lg hover:bg-white/30 transition-colors">
          <ArrowLeft className="w-6 h-6 text-white" />
        </button>
        
        {/* Language Name */}
        <div className="absolute bottom-6 left-6 right-6">
          <h1 className="text-white text-4xl mb-2">Swahili</h1>
          <p className="text-white/90">Lugha ya Kiswahili</p>
        </div>
      </div>

      {/* Content */}
      <div className="px-6 py-8">
        {/* Introduction */}
        <div className="mb-8">
          <h2 className="text-gray-900 text-xl mb-3">About this language</h2>
          <p className="text-gray-600 leading-relaxed">
            Swahili is a Bantu language spoken by over 100 million people across East Africa. 
            It's the official language of Kenya, Tanzania, and Uganda, and widely used in the 
            African Great Lakes region.
          </p>
        </div>

        {/* Statistics */}
        <div className="grid grid-cols-3 gap-4 mb-8">
          <div className="bg-gradient-to-br from-[#007A3D]/10 to-[#00a84f]/10 rounded-2xl p-4 text-center">
            <BookOpen className="w-8 h-8 text-[#007A3D] mx-auto mb-2" />
            <p className="text-2xl text-gray-900 mb-1">48</p>
            <p className="text-xs text-gray-600">Lessons</p>
          </div>
          <div className="bg-gradient-to-br from-[#FF6B35]/10 to-[#FCD116]/10 rounded-2xl p-4 text-center">
            <Target className="w-8 h-8 text-[#FF6B35] mx-auto mb-2" />
            <p className="text-2xl text-gray-900 mb-1">24</p>
            <p className="text-xs text-gray-600">Quizzes</p>
          </div>
          <div className="bg-gradient-to-br from-[#7B2CBF]/10 to-[#9d4edd]/10 rounded-2xl p-4 text-center">
            <Award className="w-8 h-8 text-[#7B2CBF] mx-auto mb-2" />
            <p className="text-2xl text-gray-900 mb-1">65%</p>
            <p className="text-xs text-gray-600">Complete</p>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="space-y-3">
          <button className="w-full bg-gradient-to-r from-[#007A3D] to-[#00a84f] text-white py-4 rounded-2xl flex items-center justify-center gap-2 hover:shadow-lg transition-all">
            <BookOpen className="w-5 h-5" />
            <span className="text-lg">Take a Lesson</span>
          </button>
          
          <button className="w-full bg-gradient-to-r from-[#FF6B35] to-[#FCD116] text-white py-4 rounded-2xl flex items-center justify-center gap-2 hover:shadow-lg transition-all">
            <Target className="w-5 h-5" />
            <span className="text-lg">Take a Quiz</span>
          </button>
          
          <div className="grid grid-cols-2 gap-3">
            <button className="bg-white border-2 border-gray-200 text-gray-700 py-3 rounded-xl hover:border-[#007A3D] transition-colors">
              View History
            </button>
            <button className="bg-white border-2 border-gray-200 text-gray-700 py-3 rounded-xl hover:border-[#007A3D] transition-colors">
              Mannerisms
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
