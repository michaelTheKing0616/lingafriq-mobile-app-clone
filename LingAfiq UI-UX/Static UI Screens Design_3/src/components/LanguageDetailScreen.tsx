import React from 'react';
import { ArrowLeft, BookOpen, Brain, History, Hand } from 'lucide-react';
import { ImageWithFallback } from './figma/ImageWithFallback';

export function LanguageDetailScreen() {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header Image */}
      <div className="relative h-64">
        <ImageWithFallback 
          src="https://images.unsplash.com/photo-1630067458414-0080622bc0df?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxTd2FoaWxpJTIwY3VsdHVyZSUyMFRhbnphbmlhfGVufDF8fHx8MTc2NDc1ODg2M3ww&ixlib=rb-4.1.0&q=80&w=1080"
          alt="Swahili"
          className="w-full h-full object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-black/70 to-transparent"></div>
        
        {/* Back Button */}
        <button className="absolute top-6 left-6 w-10 h-10 bg-white/90 rounded-full flex items-center justify-center shadow-lg">
          <ArrowLeft className="w-5 h-5 text-gray-800" />
        </button>

        {/* Language Name */}
        <div className="absolute bottom-6 left-6 right-6">
          <h1 className="text-white mb-2">Swahili</h1>
          <p className="text-white/90">East African Language</p>
        </div>
      </div>

      {/* Content */}
      <div className="px-6 py-6">
        {/* Introduction */}
        <div className="bg-white rounded-2xl p-6 shadow-md mb-6">
          <h3 className="text-gray-800 mb-3">About Swahili</h3>
          <p className="text-gray-600 mb-4">
            Swahili is a Bantu language spoken by over 100 million people across East Africa. 
            It's the official language of Tanzania, Kenya, and Uganda.
          </p>
          
          {/* Statistics */}
          <div className="grid grid-cols-3 gap-4 pt-4 border-t border-gray-200">
            <div className="text-center">
              <p className="text-2xl text-[#007A3D]">24</p>
              <p className="text-gray-500 text-sm">Lessons</p>
            </div>
            <div className="text-center">
              <p className="text-2xl text-[#FF6B35]">18</p>
              <p className="text-gray-500 text-sm">Quizzes</p>
            </div>
            <div className="text-center">
              <p className="text-2xl text-[#FCD116]">45%</p>
              <p className="text-gray-500 text-sm">Complete</p>
            </div>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="space-y-3">
          <button className="w-full bg-gradient-to-r from-[#007A3D] to-[#005A2D] text-white py-4 rounded-xl shadow-lg hover:shadow-xl transition-shadow flex items-center justify-center gap-3">
            <BookOpen className="w-5 h-5" />
            Take a Lesson
          </button>

          <button className="w-full bg-gradient-to-r from-[#FF6B35] to-[#CE1126] text-white py-4 rounded-xl shadow-lg hover:shadow-xl transition-shadow flex items-center justify-center gap-3">
            <Brain className="w-5 h-5" />
            Take a Quiz
          </button>

          <button className="w-full bg-white border-2 border-gray-300 text-gray-700 py-4 rounded-xl hover:border-[#7B2CBF] transition-colors flex items-center justify-center gap-3">
            <History className="w-5 h-5" />
            View History
          </button>

          <button className="w-full bg-white border-2 border-gray-300 text-gray-700 py-4 rounded-xl hover:border-[#7B2CBF] transition-colors flex items-center justify-center gap-3">
            <Hand className="w-5 h-5" />
            View Mannerisms
          </button>
        </div>
      </div>
    </div>
  );
}
