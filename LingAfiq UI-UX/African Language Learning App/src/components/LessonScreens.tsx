import { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Button } from './ui/button';
import { Card } from './ui/card';
import { Progress } from './ui/progress';
import { Badge } from './ui/badge';
import { ArrowLeft, Volume2, Check, X, ChevronRight, Star, Trophy } from 'lucide-react';

interface LessonScreensProps {
  onComplete: () => void;
  onBack?: () => void;
}

interface Exercise {
  id: number;
  type: 'translation' | 'multiple-choice' | 'fill-blank' | 'listening' | 'speaking';
  question: string;
  options?: string[];
  correctAnswer: string;
  audioUrl?: string;
  translation?: string;
}

const exercises: Exercise[] = [
  {
    id: 1,
    type: 'multiple-choice',
    question: 'What does "Jambo" mean in English?',
    options: ['Goodbye', 'Hello', 'Thank you', 'Please'],
    correctAnswer: 'Hello',
  },
  {
    id: 2,
    type: 'translation',
    question: 'Translate: How are you?',
    correctAnswer: 'Habari yako?',
    translation: 'Habari yako?',
  },
  {
    id: 3,
    type: 'fill-blank',
    question: 'Fill in the blank: Jina langu ni _____',
    correctAnswer: 'name',
    translation: 'My name is _____',
  },
  {
    id: 4,
    type: 'listening',
    question: 'Listen and select the correct phrase:',
    options: ['Asante sana', 'Karibu sana', 'Habari gani', 'Nzuri sana'],
    correctAnswer: 'Asante sana',
    audioUrl: '/audio/asante.mp3',
  },
];

export default function LessonScreens({ onComplete, onBack }: LessonScreensProps) {
  const [currentExercise, setCurrentExercise] = useState(0);
  const [selectedAnswer, setSelectedAnswer] = useState('');
  const [showFeedback, setShowFeedback] = useState(false);
  const [isCorrect, setIsCorrect] = useState(false);
  const [score, setScore] = useState(0);

  const exercise = exercises[currentExercise];
  const progress = ((currentExercise + 1) / exercises.length) * 100;

  const checkAnswer = () => {
    const correct = selectedAnswer.toLowerCase() === exercise.correctAnswer.toLowerCase();
    setIsCorrect(correct);
    setShowFeedback(true);
    if (correct) {
      setScore(score + 25);
    }
  };

  const nextExercise = () => {
    if (currentExercise < exercises.length - 1) {
      setCurrentExercise(currentExercise + 1);
      setSelectedAnswer('');
      setShowFeedback(false);
      setIsCorrect(false);
    } else {
      onComplete();
    }
  };

  const renderExercise = () => {
    switch (exercise.type) {
      case 'multiple-choice':
      case 'listening':
        return (
          <div className="space-y-3">
            {exercise.options?.map((option, index) => (
              <motion.button
                key={index}
                onClick={() => !showFeedback && setSelectedAnswer(option)}
                whileTap={{ scale: 0.98 }}
                className={`w-full p-4 rounded-xl border-2 text-left transition-all ${
                  selectedAnswer === option
                    ? showFeedback
                      ? isCorrect
                        ? 'border-[#007A3D] bg-[#007A3D]/10'
                        : 'border-destructive bg-destructive/10'
                      : 'border-primary bg-primary/5'
                    : 'border-border hover:border-primary/50'
                }`}
              >
                <div className="flex items-center justify-between">
                  <span>{option}</span>
                  {showFeedback && selectedAnswer === option && (
                    <div
                      className={`w-6 h-6 rounded-full flex items-center justify-center ${
                        isCorrect ? 'bg-[#007A3D]' : 'bg-destructive'
                      }`}
                    >
                      {isCorrect ? (
                        <Check className="w-4 h-4 text-white" />
                      ) : (
                        <X className="w-4 h-4 text-white" />
                      )}
                    </div>
                  )}
                </div>
              </motion.button>
            ))}
          </div>
        );

      case 'translation':
      case 'fill-blank':
        return (
          <div>
            <input
              type="text"
              value={selectedAnswer}
              onChange={(e) => !showFeedback && setSelectedAnswer(e.target.value)}
              placeholder="Type your answer..."
              className="w-full p-4 rounded-xl border-2 border-border focus:border-primary outline-none transition-colors text-lg"
              disabled={showFeedback}
            />
            {exercise.translation && (
              <p className="text-sm text-muted-foreground mt-2 text-center">
                {exercise.translation}
              </p>
            )}
          </div>
        );

      default:
        return null;
    }
  };

  return (
    <div className="min-h-screen bg-background flex flex-col">
      {/* Header */}
      <div className="sticky top-0 z-10 bg-card shadow-sm px-6 py-4">
        <div className="flex items-center gap-4">
          <Button variant="ghost" size="icon" onClick={onBack} className="rounded-full">
            <ArrowLeft className="w-5 h-5" />
          </Button>
          <div className="flex-1">
            <Progress value={progress} className="h-2" />
          </div>
          <div className="flex items-center gap-2">
            <Star className="w-5 h-5 text-[#FCD116]" />
            <span>{score}</span>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 flex flex-col px-6 py-8">
        <AnimatePresence mode="wait">
          <motion.div
            key={currentExercise}
            initial={{ opacity: 0, x: 50 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -50 }}
            className="flex-1 flex flex-col"
          >
            {/* Exercise Type Badge */}
            <Badge className="self-start mb-4 bg-primary/10 text-primary">
              {exercise.type.replace('-', ' ').toUpperCase()}
            </Badge>

            {/* Question */}
            <Card className="p-6 rounded-2xl shadow-lg border-0 mb-6">
              <div className="flex items-start gap-4">
                {exercise.type === 'listening' && (
                  <Button
                    variant="ghost"
                    size="icon"
                    className="rounded-full bg-primary/10 hover:bg-primary/20"
                  >
                    <Volume2 className="w-5 h-5 text-primary" />
                  </Button>
                )}
                <div className="flex-1">
                  <h2 className="text-xl">{exercise.question}</h2>
                </div>
              </div>
            </Card>

            {/* Answer Options */}
            {renderExercise()}

            {/* Feedback */}
            <AnimatePresence>
              {showFeedback && (
                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: 20 }}
                  className="mt-6"
                >
                  <Card
                    className={`p-5 rounded-2xl border-2 ${
                      isCorrect
                        ? 'border-[#007A3D] bg-[#007A3D]/5'
                        : 'border-destructive bg-destructive/5'
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      <div
                        className={`w-12 h-12 rounded-full flex items-center justify-center ${
                          isCorrect ? 'bg-[#007A3D]' : 'bg-destructive'
                        }`}
                      >
                        {isCorrect ? (
                          <Check className="w-6 h-6 text-white" />
                        ) : (
                          <X className="w-6 h-6 text-white" />
                        )}
                      </div>
                      <div className="flex-1">
                        <h3 className={isCorrect ? 'text-[#007A3D]' : 'text-destructive'}>
                          {isCorrect ? 'Excellent!' : 'Not quite right'}
                        </h3>
                        {!isCorrect && (
                          <p className="text-sm text-muted-foreground mt-1">
                            Correct answer: {exercise.correctAnswer}
                          </p>
                        )}
                      </div>
                    </div>
                  </Card>
                </motion.div>
              )}
            </AnimatePresence>
          </motion.div>
        </AnimatePresence>
      </div>

      {/* Bottom Button */}
      <div className="sticky bottom-0 p-6 bg-gradient-to-t from-background via-background to-transparent">
        {!showFeedback ? (
          <Button
            onClick={checkAnswer}
            disabled={!selectedAnswer}
            className={`w-full h-14 rounded-2xl text-white shadow-lg transition-all ${
              selectedAnswer
                ? 'bg-gradient-to-r from-[#007A3D] to-[#00A8E8] hover:shadow-xl'
                : 'bg-muted text-muted-foreground cursor-not-allowed'
            }`}
            size="lg"
          >
            Check Answer
          </Button>
        ) : (
          <Button
            onClick={nextExercise}
            className="w-full h-14 rounded-2xl bg-gradient-to-r from-[#CE1126] to-[#FF6B35] text-white shadow-lg hover:shadow-xl transition-all"
            size="lg"
          >
            {currentExercise < exercises.length - 1 ? (
              <>
                Continue
                <ChevronRight className="ml-2 w-5 h-5" />
              </>
            ) : (
              <>
                Complete Lesson
                <Trophy className="ml-2 w-5 h-5" />
              </>
            )}
          </Button>
        )}
      </div>
    </div>
  );
}
