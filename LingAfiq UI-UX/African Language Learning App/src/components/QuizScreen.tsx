import { useState } from 'react';
import { motion } from 'motion/react';
import { ChevronLeft, Trophy, Star } from 'lucide-react';
import { quizQuestions } from '../lib/mock-data';

interface QuizScreenProps {
  onComplete: () => void;
  onBack: () => void;
}

export default function QuizScreen({ onComplete, onBack }: QuizScreenProps) {
  const [currentQuestion, setCurrentQuestion] = useState(0);
  const [selectedAnswer, setSelectedAnswer] = useState<string | null>(null);
  const [score, setScore] = useState(0);
  const [showResult, setShowResult] = useState(false);
  const [isCorrect, setIsCorrect] = useState(false);

  const question = quizQuestions[currentQuestion];
  const progress = ((currentQuestion + 1) / quizQuestions.length) * 100;

  const handleAnswer = (answer: string) => {
    setSelectedAnswer(answer);
    const correct = answer === question.correctAnswer;
    setIsCorrect(correct);
    if (correct) {
      setScore(score + 1);
    }
    
    setTimeout(() => {
      if (currentQuestion < quizQuestions.length - 1) {
        setCurrentQuestion(currentQuestion + 1);
        setSelectedAnswer(null);
      } else {
        setShowResult(true);
      }
    }, 1500);
  };

  if (showResult) {
    const percentage = Math.round((score / quizQuestions.length) * 100);
    return (
      <div className="w-full min-h-screen bg-gradient-to-br from-purple-50 to-pink-50 flex flex-col items-center justify-center p-6">
        <motion.div
          initial={{ scale: 0 }}
          animate={{ scale: 1 }}
          transition={{ type: 'spring', bounce: 0.5 }}
          className="text-center"
        >
          <div className="w-32 h-32 mx-auto mb-6 rounded-full bg-gradient-to-br from-yellow-400 to-orange-500 flex items-center justify-center shadow-2xl">
            <Trophy className="w-16 h-16 text-white" />
          </div>
          <h1 className="text-gray-900 mb-4">Quiz Complete!</h1>
          <p className="text-gray-600 mb-8">You scored {score} out of {quizQuestions.length}</p>
          
          <div className="bg-white rounded-3xl p-8 shadow-xl mb-8">
            <div className="text-6xl mb-4">{percentage}%</div>
            <div className="flex justify-center gap-1 mb-4">
              {[...Array(5)].map((_, i) => (
                <Star
                  key={i}
                  className={`w-6 h-6 ${i < Math.ceil(percentage / 20) ? 'text-yellow-400 fill-yellow-400' : 'text-gray-300'}`}
                />
              ))}
            </div>
            <p className="text-gray-600">
              {percentage >= 80 ? 'Excellent work!' : percentage >= 60 ? 'Good job!' : 'Keep practicing!'}
            </p>
          </div>

          <button
            onClick={onComplete}
            className="w-full py-4 rounded-xl bg-gradient-to-r from-purple-500 to-pink-500 text-white shadow-lg"
          >
            Continue
          </button>
        </motion.div>
      </div>
    );
  }

  return (
    <div className="w-full min-h-screen bg-gradient-to-br from-purple-50 to-pink-50 flex flex-col">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 p-4">
        <div className="flex items-center gap-4 mb-3">
          <button onClick={onBack} className="w-10 h-10 rounded-xl bg-gray-100 flex items-center justify-center">
            <ChevronLeft className="w-5 h-5 text-gray-700" />
          </button>
          <div className="flex-1">
            <div className="h-2 bg-gray-200 rounded-full overflow-hidden">
              <motion.div
                className="h-full bg-gradient-to-r from-purple-400 to-pink-500"
                initial={{ width: 0 }}
                animate={{ width: `${progress}%` }}
                transition={{ duration: 0.3 }}
              />
            </div>
          </div>
          <span className="text-sm text-gray-600">{currentQuestion + 1}/{quizQuestions.length}</span>
        </div>
      </div>

      {/* Question */}
      <div className="flex-1 flex flex-col items-center justify-center p-6">
        <motion.div
          key={currentQuestion}
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          className="w-full max-w-md"
        >
          <div className="bg-white rounded-3xl p-8 shadow-lg mb-8">
            <h2 className="text-gray-900 text-center mb-4">{question.question}</h2>
          </div>

          <div className="space-y-4">
            {question.options?.map((option, index) => (
              <motion.button
                key={index}
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                onClick={() => handleAnswer(option)}
                disabled={selectedAnswer !== null}
                className={`w-full p-4 rounded-2xl text-left transition-all ${
                  selectedAnswer === option
                    ? isCorrect
                      ? 'bg-green-100 border-2 border-green-500'
                      : 'bg-red-100 border-2 border-red-500'
                    : 'bg-white border-2 border-gray-200 hover:border-purple-300'
                }`}
              >
                <span className="text-gray-900">{option}</span>
              </motion.button>
            ))}
          </div>

          {selectedAnswer && (
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className={`mt-6 p-4 rounded-2xl ${isCorrect ? 'bg-green-50' : 'bg-orange-50'}`}
            >
              <p className={`mb-2 ${isCorrect ? 'text-green-700' : 'text-orange-700'}`}>
                {isCorrect ? '✓ Correct!' : '✗ Incorrect'}
              </p>
              <p className="text-sm text-gray-600">{question.explanation}</p>
            </motion.div>
          )}
        </motion.div>
      </div>
    </div>
  );
}
