import { motion } from 'motion/react';
import { ChevronLeft, Play, Lock, CheckCircle2, Clock, Award } from 'lucide-react';
import { courses, lessons } from '../lib/mock-data';
import { ImageWithFallback } from './figma/ImageWithFallback';

interface CourseOverviewScreenProps {
  onSelectLesson: () => void;
  onBack: () => void;
}

export default function CourseOverviewScreen({ onSelectLesson, onBack }: CourseOverviewScreenProps) {
  const course = courses[0];
  const courseLessons = lessons.filter(l => l.courseId === course.id);

  return (
    <div className="w-full min-h-screen bg-gray-50 flex flex-col">
      {/* Header with Course Image */}
      <div className="relative h-64">
        <ImageWithFallback
          src={course.image || ''}
          alt={course.title}
          className="w-full h-full object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent" />
        
        <button
          onClick={onBack}
          className="absolute top-6 left-6 w-10 h-10 rounded-xl bg-white/20 backdrop-blur-sm flex items-center justify-center text-white"
        >
          <ChevronLeft className="w-5 h-5" />
        </button>

        <div className="absolute bottom-6 left-6 right-6">
          <h1 className="text-white mb-2">{course.title}</h1>
          <p className="text-white/90 text-sm">{course.description}</p>
        </div>
      </div>

      {/* Course Stats */}
      <div className="bg-white border-b border-gray-200 p-6">
        <div className="grid grid-cols-3 gap-4">
          <div className="text-center">
            <div className="text-2xl mb-1">📚</div>
            <div className="text-sm text-gray-600">Lessons</div>
            <div className="text-gray-900">{course.lessonsCount}</div>
          </div>
          <div className="text-center">
            <div className="text-2xl mb-1">⏱️</div>
            <div className="text-sm text-gray-600">Duration</div>
            <div className="text-gray-900">{course.estimatedTime}</div>
          </div>
          <div className="text-center">
            <div className="text-2xl mb-1">📊</div>
            <div className="text-sm text-gray-600">Progress</div>
            <div className="text-gray-900">{course.progress}%</div>
          </div>
        </div>

        {/* Progress Bar */}
        <div className="mt-4">
          <div className="h-3 bg-gray-100 rounded-full overflow-hidden">
            <div
              className="h-full bg-gradient-to-r from-green-400 to-green-600 rounded-full transition-all"
              style={{ width: `${course.progress}%` }}
            />
          </div>
        </div>
      </div>

      {/* Lessons List */}
      <div className="flex-1 p-6 overflow-y-auto">
        <h2 className="text-gray-900 mb-4">Lessons</h2>
        <div className="space-y-3">
          {courseLessons.map((lesson, index) => (
            <motion.button
              key={lesson.id}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: index * 0.05 }}
              onClick={() => !lesson.locked && onSelectLesson()}
              disabled={lesson.locked}
              className={`w-full bg-white rounded-2xl p-4 shadow-sm border transition-all ${
                lesson.locked
                  ? 'border-gray-200 opacity-60 cursor-not-allowed'
                  : lesson.completed
                  ? 'border-green-200 hover:shadow-md'
                  : 'border-gray-200 hover:shadow-md'
              }`}
            >
              <div className="flex items-center gap-4">
                {/* Icon */}
                <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${
                  lesson.completed
                    ? 'bg-green-100'
                    : lesson.locked
                    ? 'bg-gray-100'
                    : 'bg-gradient-to-br from-orange-400 to-red-500'
                }`}>
                  {lesson.completed ? (
                    <CheckCircle2 className="w-6 h-6 text-green-600" />
                  ) : lesson.locked ? (
                    <Lock className="w-6 h-6 text-gray-400" />
                  ) : (
                    <Play className="w-6 h-6 text-white" />
                  )}
                </div>

                {/* Content */}
                <div className="flex-1 text-left">
                  <h3 className="text-gray-900 mb-1">{lesson.title}</h3>
                  <div className="flex items-center gap-3 text-sm text-gray-600">
                    <div className="flex items-center gap-1">
                      <Clock className="w-4 h-4" />
                      <span>{lesson.duration} min</span>
                    </div>
                    <span className={`px-2 py-0.5 rounded-full text-xs ${
                      lesson.type === 'vocabulary'
                        ? 'bg-blue-100 text-blue-700'
                        : lesson.type === 'grammar'
                        ? 'bg-purple-100 text-purple-700'
                        : lesson.type === 'conversation'
                        ? 'bg-green-100 text-green-700'
                        : lesson.type === 'culture'
                        ? 'bg-orange-100 text-orange-700'
                        : 'bg-pink-100 text-pink-700'
                    }`}>
                      {lesson.type}
                    </span>
                  </div>
                </div>

                {/* Status Badge */}
                {lesson.completed && (
                  <Award className="w-5 h-5 text-yellow-500" />
                )}
              </div>
            </motion.button>
          ))}
        </div>
      </div>
    </div>
  );
}
