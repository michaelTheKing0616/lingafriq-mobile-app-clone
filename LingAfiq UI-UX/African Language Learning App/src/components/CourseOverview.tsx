import { motion } from 'motion/react';
import { Button } from './ui/button';
import { Card } from './ui/card';
import { Progress } from './ui/progress';
import { Badge } from './ui/badge';
import {
  ArrowLeft,
  BookOpen,
  Lock,
  Check,
  Star,
  PlayCircle,
  Trophy,
  MessageCircle,
  Sparkles,
} from 'lucide-react';

interface Lesson {
  id: number;
  title: string;
  duration: string;
  status: 'completed' | 'current' | 'locked';
  xp: number;
  type: 'lesson' | 'quiz' | 'practice';
}

interface Unit {
  id: number;
  title: string;
  description: string;
  progress: number;
  lessons: Lesson[];
  unlocked: boolean;
}

const units: Unit[] = [
  {
    id: 1,
    title: 'Unit 1: Foundations',
    description: 'Learn the basics of pronunciation and alphabet',
    progress: 100,
    unlocked: true,
    lessons: [
      { id: 1, title: 'Introduction to Swahili', duration: '10 min', status: 'completed', xp: 50, type: 'lesson' },
      { id: 2, title: 'The Alphabet', duration: '15 min', status: 'completed', xp: 50, type: 'lesson' },
      { id: 3, title: 'Pronunciation Basics', duration: '20 min', status: 'completed', xp: 75, type: 'practice' },
      { id: 4, title: 'Unit 1 Quiz', duration: '10 min', status: 'completed', xp: 100, type: 'quiz' },
    ],
  },
  {
    id: 2,
    title: 'Unit 2: Greetings & Introductions',
    description: 'Master common greetings and how to introduce yourself',
    progress: 60,
    unlocked: true,
    lessons: [
      { id: 5, title: 'Common Greetings', duration: '15 min', status: 'completed', xp: 50, type: 'lesson' },
      { id: 6, title: 'Introducing Yourself', duration: '15 min', status: 'current', xp: 50, type: 'lesson' },
      { id: 7, title: 'Conversation Practice', duration: '20 min', status: 'locked', xp: 75, type: 'practice' },
      { id: 8, title: 'Unit 2 Quiz', duration: '10 min', status: 'locked', xp: 100, type: 'quiz' },
    ],
  },
  {
    id: 3,
    title: 'Unit 3: Numbers & Time',
    description: 'Learn to count and tell time in Swahili',
    progress: 0,
    unlocked: false,
    lessons: [
      { id: 9, title: 'Numbers 1-100', duration: '15 min', status: 'locked', xp: 50, type: 'lesson' },
      { id: 10, title: 'Telling Time', duration: '15 min', status: 'locked', xp: 50, type: 'lesson' },
      { id: 11, title: 'Practice: Time & Numbers', duration: '20 min', status: 'locked', xp: 75, type: 'practice' },
      { id: 12, title: 'Unit 3 Quiz', duration: '10 min', status: 'locked', xp: 100, type: 'quiz' },
    ],
  },
  {
    id: 4,
    title: 'Unit 4: Family & Relationships',
    description: 'Vocabulary for family members and relationships',
    progress: 0,
    unlocked: false,
    lessons: [
      { id: 13, title: 'Family Members', duration: '15 min', status: 'locked', xp: 50, type: 'lesson' },
      { id: 14, title: 'Describing Relationships', duration: '15 min', status: 'locked', xp: 50, type: 'lesson' },
      { id: 15, title: 'Family Conversations', duration: '20 min', status: 'locked', xp: 75, type: 'practice' },
      { id: 16, title: 'Unit 4 Quiz', duration: '10 min', status: 'locked', xp: 100, type: 'quiz' },
    ],
  },
];

interface CourseOverviewProps {
  language: string;
  onStartLesson: (lessonId: number) => void;
  onBack?: () => void;
}

export default function CourseOverview({ language, onStartLesson, onBack }: CourseOverviewProps) {
  const overallProgress = Math.round(
    units.reduce((acc, unit) => acc + unit.progress, 0) / units.length
  );

  const getLessonIcon = (type: string, status: string) => {
    if (status === 'completed') return Check;
    if (status === 'locked') return Lock;
    if (type === 'quiz') return Trophy;
    if (type === 'practice') return MessageCircle;
    return PlayCircle;
  };

  const getStatusColor = (status: string) => {
    if (status === 'completed') return 'text-[#007A3D]';
    if (status === 'current') return 'text-primary';
    return 'text-muted-foreground';
  };

  return (
    <div className="min-h-screen bg-background pb-24">
      {/* Header */}
      <div className="sticky top-0 z-10 bg-gradient-to-br from-[#007A3D] to-[#00A8E8] px-6 pt-12 pb-8 rounded-b-[2.5rem] shadow-lg">
        <div className="absolute inset-0 opacity-10">
          <div
            className="absolute inset-0"
            style={{
              backgroundImage: `repeating-linear-gradient(45deg, transparent, transparent 35px, rgba(255, 255, 255, 0.3) 35px, rgba(255, 255, 255, 0.3) 70px)`,
            }}
          />
        </div>

        <div className="relative">
          {onBack && (
            <Button
              variant="ghost"
              size="icon"
              onClick={onBack}
              className="absolute -left-2 -top-2 text-white hover:bg-white/20 rounded-full"
            >
              <ArrowLeft className="w-5 h-5" />
            </Button>
          )}

          <div className="text-center text-white pt-8">
            <h1 className="text-3xl mb-2">{language} Course</h1>
            <p className="opacity-90 mb-4">Your learning journey</p>

            {/* Overall Progress */}
            <Card className="bg-white/95 backdrop-blur-sm p-4 rounded-2xl border-0 shadow-md">
              <div className="flex justify-between items-center mb-2">
                <span className="text-foreground">Overall Progress</span>
                <Badge className="bg-[#007A3D] text-white">{overallProgress}%</Badge>
              </div>
              <Progress value={overallProgress} className="h-2" />
            </Card>
          </div>
        </div>
      </div>

      {/* Learning Path */}
      <div className="px-6 py-6">
        <div className="flex items-center gap-2 mb-6">
          <Sparkles className="w-5 h-5 text-primary" />
          <h2>Learning Path</h2>
        </div>

        <div className="space-y-6">
          {units.map((unit, unitIndex) => (
            <motion.div
              key={unit.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: unitIndex * 0.1 }}
            >
              {/* Unit Header */}
              <div className="relative">
                {/* Connecting Line */}
                {unitIndex < units.length - 1 && (
                  <div className="absolute left-6 top-20 bottom-0 w-0.5 bg-border -mb-6" />
                )}

                <div className={unit.unlocked ? 'opacity-100' : 'opacity-50'}>
                  {/* Unit Title Card */}
                  <Card className="p-5 rounded-2xl shadow-lg border-2 border-transparent hover:border-primary/20 transition-all">
                    <div className="flex items-start gap-4">
                      <div
                        className={`w-12 h-12 rounded-2xl flex items-center justify-center ${
                          unit.unlocked
                            ? 'bg-gradient-to-br from-[#007A3D] to-[#00A8E8]'
                            : 'bg-muted'
                        } shadow-md`}
                      >
                        {unit.unlocked ? (
                          <BookOpen className="w-6 h-6 text-white" />
                        ) : (
                          <Lock className="w-6 h-6 text-muted-foreground" />
                        )}
                      </div>
                      <div className="flex-1">
                        <h3 className="mb-1">{unit.title}</h3>
                        <p className="text-sm text-muted-foreground mb-3">{unit.description}</p>
                        {unit.unlocked && (
                          <div className="flex items-center gap-3">
                            <Progress value={unit.progress} className="h-2 flex-1" />
                            <span className="text-sm">{unit.progress}%</span>
                          </div>
                        )}
                      </div>
                    </div>
                  </Card>

                  {/* Lessons List */}
                  {unit.unlocked && (
                    <div className="ml-16 mt-3 space-y-2">
                      {unit.lessons.map((lesson, lessonIndex) => {
                        const LessonIcon = getLessonIcon(lesson.type, lesson.status);
                        const canStart = lesson.status !== 'locked';

                        return (
                          <motion.div
                            key={lesson.id}
                            initial={{ opacity: 0, x: -10 }}
                            animate={{ opacity: 1, x: 0 }}
                            transition={{ delay: (unitIndex * 0.1) + (lessonIndex * 0.05) }}
                          >
                            <Card
                              onClick={() => canStart && onStartLesson(lesson.id)}
                              className={`p-4 rounded-xl border ${
                                lesson.status === 'current'
                                  ? 'border-primary shadow-md'
                                  : 'border-transparent'
                              } ${canStart ? 'cursor-pointer hover:shadow-md' : 'opacity-50'} transition-all`}
                            >
                              <div className="flex items-center gap-3">
                                <div
                                  className={`w-10 h-10 rounded-xl flex items-center justify-center ${
                                    lesson.status === 'completed'
                                      ? 'bg-[#007A3D]/10'
                                      : lesson.status === 'current'
                                      ? 'bg-primary/10'
                                      : 'bg-muted'
                                  }`}
                                >
                                  <LessonIcon className={`w-5 h-5 ${getStatusColor(lesson.status)}`} />
                                </div>
                                <div className="flex-1">
                                  <h4 className="text-sm">{lesson.title}</h4>
                                  <div className="flex items-center gap-3 mt-1">
                                    <span className="text-xs text-muted-foreground">{lesson.duration}</span>
                                    <div className="flex items-center gap-1">
                                      <Star className="w-3 h-3 text-[#FCD116]" />
                                      <span className="text-xs text-muted-foreground">{lesson.xp} XP</span>
                                    </div>
                                  </div>
                                </div>
                                {lesson.status === 'completed' && (
                                  <Badge className="bg-[#007A3D]/10 text-[#007A3D]">Done</Badge>
                                )}
                                {lesson.status === 'current' && (
                                  <Badge className="bg-primary/10 text-primary">Continue</Badge>
                                )}
                              </div>
                            </Card>
                          </motion.div>
                        );
                      })}
                    </div>
                  )}
                </div>
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </div>
  );
}
