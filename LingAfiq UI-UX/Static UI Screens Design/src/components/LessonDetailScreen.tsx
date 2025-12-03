import React from 'react';
import { ArrowLeft, Play, Pause, Volume2, CheckCircle, ChevronRight } from 'lucide-react';

const lessonData = {
  title: 'Greetings in Swahili',
  lessonNumber: 1,
  videoUrl: 'https://example.com/video.mp4',
  content: `In this lesson, you'll learn the most common greetings used in Swahili. 
  
Greetings are an essential part of Swahili culture and are used throughout the day. Knowing how to greet someone properly shows respect and helps build relationships.`,
  vocabulary: [
    { word: 'Jambo', translation: 'Hello', pronunciation: 'JAM-bo' },
    { word: 'Habari', translation: 'How are you?', pronunciation: 'ha-BAH-ree' },
    { word: 'Nzuri', translation: 'Good/Fine', pronunciation: 'n-ZOO-ree' },
    { word: 'Asante', translation: 'Thank you', pronunciation: 'a-SAN-teh' },
    { word: 'Karibu', translation: 'Welcome', pronunciation: 'ka-REE-boo' },
    { word: 'Kwaheri', translation: 'Goodbye', pronunciation: 'kwa-HEH-ree' },
  ],
};

export function LessonDetailScreen() {
  const [isPlaying, setIsPlaying] = React.useState(false);
  const [playingWord, setPlayingWord] = React.useState<number | null>(null);
  
  return (
    <div className="min-h-screen bg-gradient-to-b from-slate-50 to-white pb-20">
      {/* Header */}
      <div className="bg-white shadow-sm px-4 py-4 mb-6">
        <div className="flex items-center gap-3">
          <button className="p-2 hover:bg-gray-100 rounded-lg transition-colors">
            <ArrowLeft className="w-6 h-6 text-gray-700" />
          </button>
          <div className="flex-1">
            <p className="text-xs text-gray-500">Lesson {lessonData.lessonNumber}</p>
            <h1 className="text-gray-900 text-lg">{lessonData.title}</h1>
          </div>
        </div>
      </div>

      <div className="px-4 space-y-6">
        {/* Video Player */}
        <div className="bg-black rounded-2xl overflow-hidden shadow-xl aspect-video relative">
          <div className="absolute inset-0 flex items-center justify-center">
            <button
              onClick={() => setIsPlaying(!isPlaying)}
              className="w-20 h-20 bg-white/20 backdrop-blur-sm rounded-full flex items-center justify-center hover:bg-white/30 transition-all hover:scale-110"
            >
              {isPlaying ? (
                <Pause className="w-10 h-10 text-white ml-1" />
              ) : (
                <Play className="w-10 h-10 text-white ml-1" />
              )}
            </button>
          </div>
          
          {/* Video Controls */}
          <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/80 to-transparent p-4">
            <div className="flex items-center gap-3">
              <button className="text-white hover:text-[#FCD116] transition-colors">
                {isPlaying ? <Pause className="w-5 h-5" /> : <Play className="w-5 h-5" />}
              </button>
              <div className="flex-1 h-1 bg-white/30 rounded-full overflow-hidden">
                <div className="h-full bg-[#FCD116] rounded-full" style={{ width: '30%' }} />
              </div>
              <span className="text-white text-sm">0:45 / 2:30</span>
            </div>
          </div>
        </div>

        {/* Lesson Content */}
        <div className="bg-white rounded-2xl p-6 shadow-sm">
          <h2 className="text-gray-900 text-xl mb-4">Lesson Overview</h2>
          <p className="text-gray-600 leading-relaxed whitespace-pre-line">
            {lessonData.content}
          </p>
        </div>

        {/* Vocabulary List */}
        <div className="bg-white rounded-2xl p-6 shadow-sm">
          <h2 className="text-gray-900 text-xl mb-4">Vocabulary</h2>
          <div className="space-y-3">
            {lessonData.vocabulary.map((item, index) => (
              <div
                key={index}
                className="flex items-center gap-4 p-4 bg-gradient-to-r from-gray-50 to-white rounded-xl hover:from-[#007A3D]/5 hover:to-white transition-colors"
              >
                <button
                  onClick={() => setPlayingWord(playingWord === index ? null : index)}
                  className={`w-12 h-12 rounded-full flex items-center justify-center shrink-0 transition-all ${
                    playingWord === index
                      ? 'bg-gradient-to-br from-[#007A3D] to-[#00a84f] text-white scale-110'
                      : 'bg-gray-200 text-gray-600 hover:bg-gray-300'
                  }`}
                >
                  {playingWord === index ? (
                    <Pause className="w-5 h-5" />
                  ) : (
                    <Volume2 className="w-5 h-5" />
                  )}
                </button>
                
                <div className="flex-1">
                  <div className="flex items-baseline gap-2 mb-1">
                    <h3 className="text-gray-900 text-lg">{item.word}</h3>
                    <span className="text-xs text-gray-500 italic">({item.pronunciation})</span>
                  </div>
                  <p className="text-gray-600">{item.translation}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Action Buttons */}
        <div className="space-y-3">
          <button className="w-full bg-gradient-to-r from-[#007A3D] to-[#00a84f] text-white py-4 rounded-2xl flex items-center justify-center gap-2 hover:shadow-lg transition-all">
            <CheckCircle className="w-5 h-5" />
            <span>Mark as Complete</span>
          </button>
          
          <button className="w-full bg-white border-2 border-gray-200 text-gray-700 py-4 rounded-2xl flex items-center justify-center gap-2 hover:border-[#007A3D] transition-colors">
            <span>Next Lesson</span>
            <ChevronRight className="w-5 h-5" />
          </button>
        </div>
      </div>
    </div>
  );
}
