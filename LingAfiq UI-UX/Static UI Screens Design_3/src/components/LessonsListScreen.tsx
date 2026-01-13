import React from 'react';
import { ArrowLeft, CheckCircle, Lock, ChevronDown } from 'lucide-react';

export function LessonsListScreen() {
  const sections = [
    {
      title: 'Basics',
      description: 'Learn fundamental greetings and phrases',
      lessonCount: 8,
      expanded: true,
      lessons: [
        { number: 1, title: 'Greetings', completed: true, locked: false, points: 50 },
        { number: 2, title: 'Introductions', completed: true, locked: false, points: 50 },
        { number: 3, title: 'Common Phrases', completed: false, locked: false, points: 0 },
        { number: 4, title: 'Numbers 1-10', completed: false, locked: true, points: 0 }
      ]
    },
    {
      title: 'Food & Dining',
      description: 'Learn to order food and discuss meals',
      lessonCount: 6,
      expanded: false,
      lessons: []
    },
    {
      title: 'Travel',
      description: 'Essential phrases for getting around',
      lessonCount: 5,
      expanded: false,
      lessons: []
    }
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#007A3D] to-[#005A2D] px-6 py-6 shadow-lg">
        <div className="flex items-center gap-4 mb-4">
          <button className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
            <ArrowLeft className="w-5 h-5 text-white" />
          </button>
          <div>
            <h1 className="text-white">Swahili Lessons</h1>
            <p className="text-white/80 text-sm">Choose a lesson to begin</p>
          </div>
        </div>

        {/* Filter Options */}
        <div className="flex gap-2">
          <button className="bg-white/20 text-white px-4 py-2 rounded-full text-sm">All</button>
          <button className="bg-white/10 text-white/70 px-4 py-2 rounded-full text-sm">Completed</button>
          <button className="bg-white/10 text-white/70 px-4 py-2 rounded-full text-sm">Locked</button>
        </div>
      </div>

      {/* Sections List */}
      <div className="px-6 py-6 space-y-4">
        {sections.map((section, sectionIndex) => (
          <div key={sectionIndex} className="bg-white rounded-2xl shadow-md overflow-hidden">
            {/* Section Header */}
            <button className="w-full p-5 flex items-center justify-between hover:bg-gray-50 transition-colors">
              <div className="flex-1 text-left">
                <h3 className="text-gray-800 mb-1">{section.title}</h3>
                <p className="text-gray-500 text-sm mb-2">{section.description}</p>
                <p className="text-[#007A3D] text-sm">{section.lessonCount} lessons</p>
              </div>
              <ChevronDown className={`w-5 h-5 text-gray-400 transition-transform ${section.expanded ? 'rotate-180' : ''}`} />
            </button>

            {/* Lessons (if expanded) */}
            {section.expanded && (
              <div className="border-t border-gray-200">
                {section.lessons.map((lesson, lessonIndex) => (
                  <div
                    key={lessonIndex}
                    className={`flex items-center gap-4 p-4 border-b border-gray-100 last:border-b-0 ${
                      lesson.locked ? 'opacity-50' : 'hover:bg-gray-50 cursor-pointer'
                    }`}
                  >
                    {/* Lesson Number */}
                    <div className={`w-12 h-12 rounded-full flex items-center justify-center ${
                      lesson.completed 
                        ? 'bg-green-100' 
                        : lesson.locked 
                        ? 'bg-gray-100' 
                        : 'bg-[#007A3D]/10'
                    }`}>
                      {lesson.completed ? (
                        <CheckCircle className="w-6 h-6 text-green-600" />
                      ) : lesson.locked ? (
                        <Lock className="w-5 h-5 text-gray-400" />
                      ) : (
                        <span className="text-[#007A3D]">{lesson.number}</span>
                      )}
                    </div>

                    {/* Lesson Info */}
                    <div className="flex-1">
                      <h4 className="text-gray-800">{lesson.title}</h4>
                      {lesson.completed && (
                        <p className="text-green-600 text-sm">✓ Completed • {lesson.points} XP</p>
                      )}
                      {lesson.locked && (
                        <p className="text-gray-400 text-sm">🔒 Complete previous lessons</p>
                      )}
                    </div>

                    {/* Points */}
                    {!lesson.locked && !lesson.completed && (
                      <div className="text-right">
                        <p className="text-[#FCD116]">+50 XP</p>
                      </div>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
