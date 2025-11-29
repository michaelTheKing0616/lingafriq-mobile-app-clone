import { useState } from 'react';
import { motion } from 'motion/react';
import { Button } from './ui/button';
import { Card } from './ui/card';
import { Progress } from './ui/progress';
import { Badge } from './ui/badge';
import { ArrowLeft, Trophy, Star, Zap, Target } from 'lucide-react';

interface Question {
  id: number;
  question: string;
  options: string[];
  correctAnswer: string;
  points: number;
}

const quizQuestions: Question[] = [
  {
    id: 1,
    question: 'How do you say "Good morning" in Swahili?',
    options: ['Habari za asubuhi', 'Habari za jioni', 'Asante sana', 'Karibu'],
    correctAnswer: 'Habari za asubuhi',
    points: 20,
  },
  {
    id: 2,
    question: 'What is the Swahili word for "water"?',
    options: ['Chakula', 'Maji', 'Kahawa', 'Maziwa'],
    correctAnswer: 'Maji',
    points: 20,
  },
  {
    id: 3,
    question: 'Which phrase means "Thank you very much"?',
    options: ['Jambo sana', 'Asante sana', 'Karibu sana', 'Nzuri sana'],
    correctAnswer: 'Asante sana',
    points: 20,
  },
  {
    id: 4,
    question: 'How do you say "I am fine" in Swahili?',
    options: ['Niko vizuri', 'Nina njaa', 'Ninapenda', 'Ninaenda'],
    correctAnswer: 'Niko vizuri',
    points: 20,
  },
  {
    id: 5,
    question: 'What does "Pole pole" mean?',
    options: ['Very fast', 'Slowly/Gently', 'Right now', 'Maybe'],
    correctAnswer: 'Slowly/Gently',
    points: 20,
  },
];

interface QuizScreenProps {
  onComplete: (score: number) => void;
  onBack?: () => void;
}

export default function QuizScreenComponent({ onComplete, onBack }: QuizScreenProps) {
  const [currentQuestion, setCurrentQuestion] = useState(0);
  const [answers, setAnswers] = useState<Record<number, string>>({});
  const [showResults, setShowResults] = useState(false);

  const question = quizQuestions[currentQuestion];
  const progress = ((currentQuestion + 1) / quizQuestions.length) * 100;

  const handleAnswer = (answer: string) => {
    setAnswers({ ...answers, [question.id]: answer });
  };

  const nextQuestion = () => {
    if (currentQuestion < quizQuestions.length - 1) {
      setCurrentQuestion(currentQuestion + 1);
    } else {
      setShowResults(true);
    }
  };

  const calculateScore = () => {
    let correct = 0;
    quizQuestions.forEach((q) => {
      if (answers[q.id] === q.correctAnswer) {
        correct += q.points;
      }
    });
    return correct;
  };

  const score = calculateScore();
  const percentage = (score / 100) * 100;

  if (showResults) {
    return (
      <div className="min-h-screen bg-background flex flex-col">
        <div className="flex-1 flex flex-col items-center justify-center px-6">
          <motion.div
            initial={{ scale: 0.8, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            className="text-center"
          >
            {/* Trophy Animation */}
            <motion.div
              initial={{ y: -20 }}
              animate={{ y: 0 }}
              transition={{ repeat: Infinity, duration: 2, repeatType: 'reverse' }}
              className="mb-8"
            >
              <div className="inline-flex p-8 rounded-full bg-gradient-to-br from-[#FCD116] to-[#FF6B35] shadow-2xl">
                <Trophy className="w-20 h-20 text-white" />
              </div>
            </motion.div>

            {/* Score */}
            <h1 className="text-4xl mb-4">Quiz Complete!</h1>
            <p className="text-muted-foreground mb-8">Great job! Here's how you did:</p>

            {/* Stats Cards */}
            <div className="grid grid-cols-3 gap-3 mb-8">
              <Card className="p-4 rounded-2xl border-0 shadow-lg">
                <Star className="w-6 h-6 text-[#FCD116] mx-auto mb-2" />
                <p className="text-2xl mb-1">{score}</p>
                <p className="text-xs text-muted-foreground">Points</p>
              </Card>
              <Card className="p-4 rounded-2xl border-0 shadow-lg">
                <Target className="w-6 h-6 text-[#007A3D] mx-auto mb-2" />
                <p className="text-2xl mb-1">{percentage}%</p>
                <p className="text-xs text-muted-foreground">Accuracy</p>
              </Card>
              <Card className="p-4 rounded-2xl border-0 shadow-lg">
                <Zap className="w-6 h-6 text-primary mx-auto mb-2" />
                <p className="text-2xl mb-1">+{score}</p>
                <p className="text-xs text-muted-foreground">XP Earned</p>
              </Card>
            </div>

            {/* Review */}
            <Card className="p-6 rounded-2xl shadow-lg border-0 mb-6">
              <h3 className="mb-4">Review Answers</h3>
              <div className="space-y-3 text-left">
                {quizQuestions.map((q) => (
                  <div
                    key={q.id}
                    className={`p-3 rounded-xl ${
                      answers[q.id] === q.correctAnswer
                        ? 'bg-[#007A3D]/10'
                        : 'bg-destructive/10'
                    }`}
                  >
                    <p className="text-sm mb-1">{q.question}</p>
                    <div className="flex items-center gap-2 text-xs">
                      <span className={answers[q.id] === q.correctAnswer ? 'text-[#007A3D]' : 'text-destructive'}>
                        Your answer: {answers[q.id] || 'Not answered'}
                      </span>
                      {answers[q.id] !== q.correctAnswer && (
                        <span className="text-muted-foreground">
                          (Correct: {q.correctAnswer})
                        </span>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </Card>

            {/* Action Buttons */}
            <div className="grid grid-cols-2 gap-3 max-w-md mx-auto">
              <Button
                onClick={onBack}
                variant="outline"
                className="h-12 rounded-xl"
              >
                Back to Course
              </Button>
              <Button
                onClick={() => onComplete(score)}
                className="h-12 rounded-xl bg-gradient-to-r from-[#CE1126] to-[#FF6B35] text-white"
              >
                Continue
              </Button>
            </div>
          </motion.div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background flex flex-col">
      {/* Header */}
      <div className="sticky top-0 z-10 bg-card shadow-sm px-6 py-4">
        <div className="flex items-center gap-4 mb-3">
          <Button variant="ghost" size="icon" onClick={onBack} className="rounded-full">
            <ArrowLeft className="w-5 h-5" />
          </Button>
          <h2 className="flex-1">Unit Quiz</h2>
          <Badge className="bg-primary/10 text-primary">
            {currentQuestion + 1}/{quizQuestions.length}
          </Badge>
        </div>
        <Progress value={progress} className="h-2" />
      </div>

      {/* Question */}
      <div className="flex-1 px-6 py-8">
        <motion.div
          key={currentQuestion}
          initial={{ opacity: 0, x: 50 }}
          animate={{ opacity: 1, x: 0 }}
          className="space-y-6"
        >
          {/* Question Card */}
          <Card className="p-6 rounded-2xl shadow-lg border-0">
            <div className="flex items-start gap-3 mb-2">
              <Badge className="bg-[#FCD116]/20 text-[#8B4513]">{question.points} pts</Badge>
            </div>
            <h2 className="text-xl">{question.question}</h2>
          </Card>

          {/* Options */}
          <div className="space-y-3">
            {question.options.map((option, index) => (
              <motion.button
                key={index}
                onClick={() => handleAnswer(option)}
                whileTap={{ scale: 0.98 }}
                className={`w-full p-4 rounded-xl border-2 text-left transition-all ${
                  answers[question.id] === option
                    ? 'border-primary bg-primary/5 shadow-md'
                    : 'border-border hover:border-primary/50 hover:shadow'
                }`}
              >
                <div className="flex items-center gap-3">
                  <div
                    className={`w-6 h-6 rounded-full border-2 flex items-center justify-center transition-all ${
                      answers[question.id] === option
                        ? 'border-primary bg-primary'
                        : 'border-border'
                    }`}
                  >
                    {answers[question.id] === option && (
                      <div className="w-2 h-2 rounded-full bg-white" />
                    )}
                  </div>
                  <span>{option}</span>
                </div>
              </motion.button>
            ))}
          </div>
        </motion.div>
      </div>

      {/* Bottom Button */}
      <div className="sticky bottom-0 p-6 bg-gradient-to-t from-background via-background to-transparent">
        <Button
          onClick={nextQuestion}
          disabled={!answers[question.id]}
          className={`w-full h-14 rounded-2xl text-white shadow-lg transition-all ${
            answers[question.id]
              ? 'bg-gradient-to-r from-[#007A3D] to-[#00A8E8] hover:shadow-xl'
              : 'bg-muted text-muted-foreground cursor-not-allowed'
          }`}
          size="lg"
        >
          {currentQuestion < quizQuestions.length - 1 ? 'Next Question' : 'Complete Quiz'}
        </Button>
      </div>
    </div>
  );
}
