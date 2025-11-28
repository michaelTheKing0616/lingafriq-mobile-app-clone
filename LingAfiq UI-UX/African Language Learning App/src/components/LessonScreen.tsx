import { useState } from 'react';
import { motion } from 'motion/react';
import { ChevronLeft, Volume2, X as CloseIcon } from 'lucide-react';

interface LessonScreenProps {
  onComplete: () => void;
  onBack: () => void;
}

const lessonContent = [
  {
    type: 'intro',
    title: 'Greetings and Introductions',
    content: 'Learn how to greet people in Swahili and introduce yourself',
    image: 'https://images.unsplash.com/photo-1582213782179-e0d53f98f2ca?w=600'
  },
  {
    type: 'vocabulary',
    title: 'Basic Greetings',
    words: [
      { swahili: 'Jambo', english: 'Hello', pronunciation: 'JAM-bo' },
      { swahili: 'Habari', english: 'How are you?', pronunciation: 'ha-BAH-ree' },
      { swahili: 'Asante', english: 'Thank you', pronunciation: 'ah-SAHN-tay' },
      { swahili: 'Karibu', english: 'Welcome', pronunciation: 'kah-REE-boo' }
    ]
  },
  {
    type: 'practice',
    title: 'Practice',
    question: 'How do you say "Hello" in Swahili?',
    options: ['Jambo', 'Habari', 'Asante'],
    correct: 0
  }
];

export default function LessonScreen({ onComplete, onBack }: LessonScreenProps) {
  const [currentStep, setCurrentStep] = useState(0);
  const [selectedAnswer, setSelectedAnswer] = useState<number | null>(null);
  const [showFeedback, setShowFeedback] = useState(false);

  const step = lessonContent[currentStep];
  const progress = ((currentStep + 1) / lessonContent.length) * 100;

  const handleNext = () => {
    if (currentStep < lessonContent.length - 1) {
      setCurrentStep(currentStep + 1);
      setSelectedAnswer(null);
      setShowFeedback(false);
    } else {
      onComplete();
    }
  };

  const handleAnswer = (index: number) => {
    setSelectedAnswer(index);
    setShowFeedback(true);
  };

  return (
    <div className="w-full min-h-screen bg-gradient-to-br from-green-50 to-teal-50 flex flex-col">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 p-4">
        <div className="flex items-center gap-4 mb-3">
          <button
            onClick={onBack}
            className="w-10 h-10 rounded-xl bg-gray-100 flex items-center justify-center"
          >
            <ChevronLeft className="w-5 h-5 text-gray-700" />
          </button>
          <div className="flex-1">
            <div className="h-2 bg-gray-200 rounded-full overflow-hidden">
              <motion.div
                className="h-full bg-gradient-to-r from-green-400 to-teal-500"
                initial={{ width: 0 }}
                animate={{ width: `${progress}%` }}
                transition={{ duration: 0.3 }}
              />
            </div>
          </div>
          <span className="text-sm text-gray-600">{currentStep + 1}/{lessonContent.length}</span>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 flex flex-col items-center justify-center p-6">
        <motion.div
          key={currentStep}
          initial={{ opacity: 0, x: 50 }}
          animate={{ opacity: 1, x: 0 }}
          exit={{ opacity: 0, x: -50 }}
          className="w-full max-w-md"
        >
          {step.type === 'intro' && (
            <div className="text-center">
              <div className="w-full h-64 rounded-3xl overflow-hidden mb-6 shadow-lg">
                <img src={step.image} alt={step.title} className="w-full h-full object-cover" />
              </div>
              <h2 className="text-gray-900 mb-4">{step.title}</h2>
              <p className="text-gray-600 mb-8">{step.content}</p>
            </div>
          )}

          {step.type === 'vocabulary' && 'words' in step && (
            <div>
              <h2 className="text-gray-900 mb-6 text-center">{step.title}</h2>
              <div className="space-y-4">
                {step.words.map((word, index) => (
                  <motion.div
                    key={index}
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: index * 0.1 }}
                    className="bg-white rounded-2xl p-6 shadow-md"
                  >
                    <div className="flex items-center justify-between mb-2">
                      <h3 className="text-gray-900">{word.swahili}</h3>
                      <button className="w-10 h-10 rounded-full bg-green-100 flex items-center justify-center hover:bg-green-200 transition-colors">
                        <Volume2 className="w-5 h-5 text-green-600" />
                      </button>
                    </div>
                    <p className="text-gray-600 mb-1">{word.english}</p>
                    <p className="text-sm text-gray-500 italic">{word.pronunciation}</p>
                  </motion.div>
                ))}
              </div>
            </div>
          )}

          {step.type === 'practice' && 'options' in step && (
            <div>
              <h2 className="text-gray-900 mb-6 text-center">{step.title}</h2>
              <div className="bg-white rounded-2xl p-6 shadow-lg mb-6">
                <p className="text-gray-700 text-center text-lg">{step.question}</p>
              </div>
              <div className="space-y-3">
                {step.options.map((option, index) => (
                  <button
                    key={index}
                    onClick={() => handleAnswer(index)}
                    disabled={showFeedback}
                    className={`w-full p-4 rounded-xl text-left transition-all ${
                      selectedAnswer === index
                        ? showFeedback
                          ? index === step.correct
                            ? 'bg-green-100 border-2 border-green-500 text-green-700'
                            : 'bg-red-100 border-2 border-red-500 text-red-700'
                          : 'bg-blue-100 border-2 border-blue-500'
                        : 'bg-white border-2 border-gray-200 hover:border-gray-300'
                    }`}
                  >
                    {option}
                  </button>
                ))}
              </div>
              {showFeedback && selectedAnswer !== null && (
                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  className={`mt-4 p-4 rounded-xl ${
                    selectedAnswer === step.correct ? 'bg-green-50' : 'bg-orange-50'
                  }`}
                >
                  <p className={selectedAnswer === step.correct ? 'text-green-700' : 'text-orange-700'}>
                    {selectedAnswer === step.correct ? '✓ Correct! Great job!' : '✗ Not quite. Try again next time!'}
                  </p>
                </motion.div>
              )}
            </div>
          )}
        </motion.div>
      </div>

      {/* Next Button */}
      <div className="p-6">
        <motion.button
          onClick={handleNext}
          disabled={step.type === 'practice' && !showFeedback}
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
          className="w-full py-4 rounded-xl bg-gradient-to-r from-green-500 to-teal-600 text-white shadow-lg disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {currentStep === lessonContent.length - 1 ? 'Complete Lesson' : 'Continue'}
        </motion.button>
      </div>
    </div>
  );
}
