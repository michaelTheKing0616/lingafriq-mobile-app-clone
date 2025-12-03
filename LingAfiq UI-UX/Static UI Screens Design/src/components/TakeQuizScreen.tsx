import React from 'react';
import { ArrowLeft, X, Clock } from 'lucide-react';

const quizData = {
  currentQuestion: 3,
  totalQuestions: 10,
  question: 'What does "Jambo" mean in Swahili?',
  options: [
    { id: 'a', text: 'Hello', isCorrect: true },
    { id: 'b', text: 'Goodbye', isCorrect: false },
    { id: 'c', text: 'Thank you', isCorrect: false },
    { id: 'd', text: 'Please', isCorrect: false },
  ],
  timeRemaining: 45,
  score: 20,
};

export function TakeQuizScreen() {
  const [selectedAnswer, setSelectedAnswer] = React.useState<string | null>(null);
  const [showFeedback, setShowFeedback] = React.useState(false);
  const [timeLeft, setTimeLeft] = React.useState(quizData.timeRemaining);
  
  const progress = (quizData.currentQuestion / quizData.totalQuestions) * 100;
  
  const handleAnswerSelect = (optionId: string) => {
    setSelectedAnswer(optionId);
    setTimeout(() => {
      setShowFeedback(true);
      // Simulate moving to next question after 1.5 seconds
    }, 500);
  };
  
  return (
    <div className="min-h-screen bg-gradient-to-br from-[#FF6B35]/10 via-white to-[#7B2CBF]/10">
      {/* Header */}
      <div className="bg-white shadow-sm px-4 py-4">
        <div className="flex items-center justify-between mb-4">
          <button className="p-2 hover:bg-gray-100 rounded-lg transition-colors">
            <ArrowLeft className="w-6 h-6 text-gray-700" />
          </button>
          
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2 bg-[#FCD116]/20 px-3 py-2 rounded-lg">
              <Clock className="w-5 h-5 text-[#FF6B35]" />
              <span className="text-gray-900">{timeLeft}s</span>
            </div>
            
            <div className="text-right">
              <p className="text-sm text-gray-600">Score</p>
              <p className="text-xl text-[#007A3D]">{quizData.score}</p>
            </div>
          </div>
          
          <button className="p-2 hover:bg-gray-100 rounded-lg transition-colors">
            <X className="w-6 h-6 text-gray-700" />
          </button>
        </div>
        
        {/* Progress Bar */}
        <div className="space-y-2">
          <div className="flex items-center justify-between text-sm">
            <span className="text-gray-700">
              Question {quizData.currentQuestion}/{quizData.totalQuestions}
            </span>
            <span className="text-[#007A3D]">{Math.round(progress)}%</span>
          </div>
          <div className="w-full h-2 bg-gray-200 rounded-full overflow-hidden">
            <div
              className="h-full bg-gradient-to-r from-[#007A3D] to-[#00a84f] transition-all duration-500 rounded-full"
              style={{ width: `${progress}%` }}
            />
          </div>
        </div>
      </div>

      {/* Question Card */}
      <div className="px-4 py-8">
        <div className="bg-white rounded-3xl shadow-xl p-8 mb-8">
          <div className="text-center mb-2">
            <span className="inline-block bg-[#7B2CBF]/10 text-[#7B2CBF] px-4 py-2 rounded-full text-sm mb-4">
              Translation
            </span>
          </div>
          <h2 className="text-gray-900 text-center text-2xl leading-relaxed">
            {quizData.question}
          </h2>
        </div>

        {/* Answer Options */}
        <div className="space-y-4">
          {quizData.options.map((option, index) => {
            const isSelected = selectedAnswer === option.id;
            const showCorrect = showFeedback && option.isCorrect;
            const showWrong = showFeedback && isSelected && !option.isCorrect;
            
            return (
              <button
                key={option.id}
                onClick={() => !showFeedback && handleAnswerSelect(option.id)}
                disabled={showFeedback}
                className={`w-full text-left p-5 rounded-2xl transition-all transform hover:scale-[1.02] active:scale-[0.98] ${
                  showCorrect
                    ? 'bg-gradient-to-r from-[#007A3D] to-[#00a84f] text-white shadow-lg shadow-green-500/30 ring-4 ring-green-300'
                    : showWrong
                    ? 'bg-gradient-to-r from-[#CE1126] to-[#e01636] text-white shadow-lg shadow-red-500/30 ring-4 ring-red-300'
                    : isSelected
                    ? 'bg-gradient-to-r from-[#FF6B35] to-[#ff8555] text-white shadow-lg'
                    : 'bg-white hover:bg-gray-50 border-2 border-gray-200 hover:border-[#FF6B35]'
                }`}
              >
                <div className="flex items-center gap-4">
                  <div
                    className={`w-10 h-10 rounded-full flex items-center justify-center text-lg shrink-0 ${
                      showCorrect || showWrong || isSelected
                        ? 'bg-white/20'
                        : 'bg-gradient-to-br from-[#007A3D] to-[#00a84f] text-white'
                    }`}
                  >
                    {String.fromCharCode(65 + index)}
                  </div>
                  <span className={`text-lg ${showCorrect || showWrong || isSelected ? '' : 'text-gray-900'}`}>
                    {option.text}
                  </span>
                  
                  {showCorrect && (
                    <div className="ml-auto">
                      <svg className="w-7 h-7" fill="currentColor" viewBox="0 0 20 20">
                        <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                      </svg>
                    </div>
                  )}
                  
                  {showWrong && (
                    <div className="ml-auto">
                      <svg className="w-7 h-7" fill="currentColor" viewBox="0 0 20 20">
                        <path fillRule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clipRule="evenodd" />
                      </svg>
                    </div>
                  )}
                </div>
              </button>
            );
          })}
        </div>

        {/* Action Buttons */}
        <div className="mt-8 flex gap-4">
          <button className="flex-1 bg-gray-200 text-gray-700 py-4 rounded-xl hover:bg-gray-300 transition-colors">
            Skip
          </button>
          <button 
            disabled={!selectedAnswer}
            className="flex-1 bg-gradient-to-r from-[#007A3D] to-[#00a84f] text-white py-4 rounded-xl disabled:opacity-50 disabled:cursor-not-allowed hover:shadow-lg transition-all"
          >
            Submit Answer
          </button>
        </div>
      </div>
    </div>
  );
}
