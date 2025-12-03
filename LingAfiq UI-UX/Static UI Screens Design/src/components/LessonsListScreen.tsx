import React from 'react';
import { ArrowLeft, ChevronRight, CheckCircle, Lock, Play } from 'lucide-react';

const lessonsData = [
  {
    section: 'Basics',
    description: 'Learn fundamental greetings and introductions',
    lessons: [
      { id: 1, title: 'Greetings', completed: true, locked: false, score: 95 },
      { id: 2, title: 'Introductions', completed: true, locked: false, score: 88 },
      { id: 3, title: 'Common Phrases', completed: false, locked: false, score: 0 },
      { id: 4, title: 'Numbers 1-20', completed: false, locked: true, score: 0 },
    ],
  },
  {
    section: 'Family & Relationships',
    description: 'Vocabulary for family members and relationships',
    lessons: [
      { id: 5, title: 'Family Members', completed: false, locked: true, score: 0 },
      { id: 6, title: 'Describing People', completed: false, locked: true, score: 0 },
    ],
  },
  {
    section: 'Daily Life',
    description: 'Essential phrases for everyday situations',
    lessons: [
      { id: 7, title: 'At the Market', completed: false, locked: true, score: 0 },
      { id: 8, title: 'Food & Dining', completed: false, locked: true, score: 0 },
      { id: 9, title: 'Transportation', completed: false, locked: true, score: 0 },
    ],
  },
];

export function LessonsListScreen() {
  const [expandedSection, setExpandedSection] = React.useState<string | null>('Basics');
  
  return (
    <div className="min-h-screen bg-gradient-to-b from-slate-50 to-white">
      {/* Header */}
      <div className="bg-gradient-to-br from-[#007A3D] to-[#005a2d] text-white px-4 py-6 shadow-lg rounded-b-[24px] mb-6">
        <div className="flex items-center gap-3 mb-4">
          <button className="p-2 hover:bg-white/10 rounded-lg transition-colors">
            <ArrowLeft className="w-6 h-6" />
          </button>
          <div>
            <h1 className="text-2xl">Swahili Lessons</h1>
            <p className="text-white/80 text-sm">Choose a lesson to begin</p>
          </div>
        </div>
        
        {/* Progress */}
        <div className="bg-white/20 backdrop-blur-sm rounded-xl p-4">
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm text-white/90">Overall Progress</span>
            <span className="text-sm">2/15 lessons</span>
          </div>
          <div className="w-full h-2 bg-white/30 rounded-full overflow-hidden">
            <div className="h-full bg-[#FCD116] rounded-full" style={{ width: '13%' }} />
          </div>
        </div>
      </div>

      {/* Lessons List */}
      <div className="px-4 space-y-4 pb-8">
        {lessonsData.map((section, index) => (
          <div key={index} className="bg-white rounded-2xl shadow-sm overflow-hidden">
            {/* Section Header */}
            <button
              onClick={() => setExpandedSection(expandedSection === section.section ? null : section.section)}
              className="w-full p-5 flex items-center justify-between hover:bg-gray-50 transition-colors"
            >
              <div className="text-left">
                <h3 className="text-gray-900 mb-1">{section.section}</h3>
                <p className="text-sm text-gray-600">{section.description}</p>
                <p className="text-xs text-[#007A3D] mt-1">{section.lessons.length} lessons</p>
              </div>
              <ChevronRight
                className={`w-6 h-6 text-gray-400 transition-transform ${
                  expandedSection === section.section ? 'rotate-90' : ''
                }`}
              />
            </button>

            {/* Lessons */}
            {expandedSection === section.section && (
              <div className="border-t border-gray-100">
                {section.lessons.map((lesson) => (
                  <button
                    key={lesson.id}
                    disabled={lesson.locked}
                    className={`w-full p-4 flex items-center gap-4 hover:bg-gray-50 transition-colors border-b border-gray-50 last:border-b-0 ${
                      lesson.locked ? 'opacity-50 cursor-not-allowed' : ''
                    }`}
                  >
                    {/* Status Icon */}
                    <div
                      className={`w-12 h-12 rounded-xl flex items-center justify-center shrink-0 ${
                        lesson.completed
                          ? 'bg-gradient-to-br from-[#007A3D] to-[#00a84f]'
                          : lesson.locked
                          ? 'bg-gray-200'
                          : 'bg-gradient-to-br from-[#FF6B35] to-[#FCD116]'
                      }`}
                    >
                      {lesson.completed ? (
                        <CheckCircle className="w-6 h-6 text-white" />
                      ) : lesson.locked ? (
                        <Lock className="w-6 h-6 text-gray-500" />
                      ) : (
                        <Play className="w-6 h-6 text-white" />
                      )}
                    </div>

                    {/* Lesson Info */}
                    <div className="flex-1 text-left">
                      <div className="flex items-center gap-2 mb-1">
                        <span className="text-xs text-gray-500">Lesson {lesson.id}</span>
                        {lesson.locked && (
                          <span className="text-xs bg-gray-200 text-gray-600 px-2 py-0.5 rounded-full">
                            Locked
                          </span>
                        )}
                      </div>
                      <h4 className="text-gray-900 mb-1">{lesson.title}</h4>
                      {lesson.completed && (
                        <div className="flex items-center gap-2">
                          <div className="flex-1 h-1 bg-gray-200 rounded-full overflow-hidden">
                            <div
                              className="h-full bg-[#007A3D] rounded-full"
                              style={{ width: `${lesson.score}%` }}
                            />
                          </div>
                          <span className="text-xs text-[#007A3D]">{lesson.score}%</span>
                        </div>
                      )}
                    </div>

                    {/* Arrow */}
                    {!lesson.locked && (
                      <ChevronRight className="w-5 h-5 text-gray-400" />
                    )}
                  </button>
                ))}
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
