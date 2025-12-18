import React from 'react';
import { ArrowLeft, Play, Pause, Volume2, CheckCircle, ChevronRight } from 'lucide-react';

export function LessonDetailScreen() {
  const [isPlaying, setIsPlaying] = React.useState(false);

  const vocabulary = [
    { word: 'Jambo', translation: 'Hello', pronunciation: 'JAM-boh' },
    { word: 'Habari', translation: 'How are you?', pronunciation: 'ha-BAR-ee' },
    { word: 'Nzuri', translation: 'Good/Fine', pronunciation: 'n-ZOO-ree' },
    { word: 'Asante', translation: 'Thank you', pronunciation: 'a-SAN-teh' }
  ];

  return (
    <div className="min-h-screen bg-gray-50 pb-24">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#007A3D] to-[#005A2D] px-6 py-6 shadow-lg">
        <div className="flex items-center gap-4">
          <button className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
            <ArrowLeft className="w-5 h-5 text-white" />
          </button>
          <div className="flex-1">
            <h2 className="text-white">Lesson 1: Greetings</h2>
            <p className="text-white/80 text-sm">Basics • 5 min</p>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="px-6 py-6 space-y-6">
        {/* Video Player */}
        <div className="bg-black rounded-2xl overflow-hidden shadow-lg aspect-video relative">
          <div className="absolute inset-0 flex items-center justify-center">
            <button 
              onClick={() => setIsPlaying(!isPlaying)}
              className="w-16 h-16 bg-white/90 rounded-full flex items-center justify-center hover:bg-white transition-colors"
            >
              {isPlaying ? (
                <Pause className="w-8 h-8 text-gray-800" />
              ) : (
                <Play className="w-8 h-8 text-gray-800 ml-1" />
              )}
            </button>
          </div>
          
          {/* Video Progress */}
          <div className="absolute bottom-0 left-0 right-0 p-4">
            <div className="h-1 bg-white/30 rounded-full overflow-hidden">
              <div className="h-full bg-white w-1/3"></div>
            </div>
          </div>
        </div>

        {/* Lesson Content */}
        <div className="bg-white rounded-2xl p-6 shadow-md">
          <h3 className="text-gray-800 mb-4">Introduction</h3>
          <p className="text-gray-600 mb-4">
            In this lesson, you'll learn the basic greetings used in Swahili-speaking communities. 
            Greetings are very important in African culture and show respect.
          </p>
          <p className="text-gray-600">
            Practice these phrases and pay attention to pronunciation. Don't be afraid to repeat 
            after the speaker multiple times!
          </p>
        </div>

        {/* Vocabulary List */}
        <div className="bg-white rounded-2xl p-6 shadow-md">
          <h3 className="text-gray-800 mb-4">Key Vocabulary</h3>
          <div className="space-y-4">
            {vocabulary.map((item, index) => (
              <div key={index} className="flex items-center gap-4 p-4 bg-gray-50 rounded-xl">
                <button className="w-12 h-12 bg-[#007A3D] rounded-full flex items-center justify-center flex-shrink-0 hover:bg-[#005A2D] transition-colors">
                  <Volume2 className="w-5 h-5 text-white" />
                </button>
                <div className="flex-1">
                  <p className="text-gray-800 mb-1">{item.word}</p>
                  <p className="text-gray-500 text-sm">{item.translation}</p>
                  <p className="text-gray-400 text-xs mt-1">Pronunciation: {item.pronunciation}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Bottom Action Bar */}
      <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 p-6 shadow-lg">
        <div className="flex gap-3">
          <button className="flex-1 bg-gradient-to-r from-[#007A3D] to-[#005A2D] text-white py-4 rounded-xl shadow-lg hover:shadow-xl transition-shadow flex items-center justify-center gap-2">
            <CheckCircle className="w-5 h-5" />
            Mark as Complete
          </button>
          <button className="bg-gray-200 text-gray-700 px-6 py-4 rounded-xl hover:bg-gray-300 transition-colors flex items-center justify-center gap-2">
            Next
            <ChevronRight className="w-5 h-5" />
          </button>
        </div>
      </div>
    </div>
  );
}
