import React from 'react';
import { ArrowLeft, X, CheckCircle, XCircle } from 'lucide-react';

export function TakeQuizScreen() {
  const [selectedAnswer, setSelectedAnswer] = React.useState<number | null>(null);
  const [showResult, setShowResult] = React.useState(false);

  const question = {
    number: 1,
    total: 10,
    text: "What does 'Jambo' mean in English?",
    options: [
      { id: 0, text: 'Goodbye' },
      { id: 1, text: 'Hello', correct: true },
      { id: 2, text: 'Thank you' },
      { id: 3, text: 'Please' }
    ]
  };

  const handleAnswerSelect = (id: number) => {
    setSelectedAnswer(id);
    setShowResult(true);
    // Simulate confetti animation on correct answer
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#007A3D] to-[#005A2D] flex flex-col">
      {/* Header */}
      <div className="p-6 flex items-center justify-between">
        <button className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
          <ArrowLeft className="w-5 h-5 text-white" />
        </button>
        <div className="text-white">
          <span className="opacity-80">Question</span> {question.number}/{question.total}
        </div>
        <button className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
          <X className="w-5 h-5 text-white" />
        </button>
      </div>

      {/* Progress Bar */}
      <div className="px-6 mb-8">
        <div className="h-2 bg-white/20 rounded-full overflow-hidden">
          <div 
            className="h-full bg-[#FCD116] transition-all duration-300" 
            style={{ width: `${(question.number / question.total) * 100}%` }}
          ></div>
        </div>
      </div>

      {/* Question */}
      <div className="flex-1 px-6">
        <div className="bg-white/10 backdrop-blur-sm rounded-3xl p-8 mb-8">
          <h2 className="text-white text-center">{question.text}</h2>
        </div>

        {/* Answer Options */}
        <div className="space-y-4">
          {question.options.map((option) => {
            const isSelected = selectedAnswer === option.id;
            const isCorrect = option.correct;
            const showCorrect = showResult && isCorrect;
            const showWrong = showResult && isSelected && !isCorrect;

            return (
              <button
                key={option.id}
                onClick={() => !showResult && handleAnswerSelect(option.id)}
                disabled={showResult}
                className={`w-full p-5 rounded-2xl transition-all ${
                  showCorrect
                    ? 'bg-green-500 border-2 border-green-400'
                    : showWrong
                    ? 'bg-red-500 border-2 border-red-400'
                    : isSelected
                    ? 'bg-white border-2 border-[#FCD116]'
                    : 'bg-white/90 hover:bg-white'
                } ${showResult ? 'cursor-not-allowed' : 'cursor-pointer'}`}
              >
                <div className="flex items-center justify-between">
                  <p className={`${showCorrect || showWrong ? 'text-white' : 'text-gray-800'}`}>
                    {option.text}
                  </p>
                  {showCorrect && <CheckCircle className="w-6 h-6 text-white" />}
                  {showWrong && <XCircle className="w-6 h-6 text-white" />}
                </div>
              </button>
            );
          })}
        </div>

        {/* Score Display */}
        <div className="mt-8 text-center">
          <div className="inline-block bg-white/20 backdrop-blur-sm rounded-full px-6 py-3">
            <p className="text-white">Score: 0 / {question.total}</p>
          </div>
        </div>
      </div>

      {/* Bottom Actions */}
      <div className="p-6">
        {showResult ? (
          <button className="w-full bg-[#FCD116] text-gray-800 py-4 rounded-xl shadow-lg hover:shadow-xl transition-shadow">
            Next Question
          </button>
        ) : (
          <button className="w-full bg-white/20 text-white py-4 rounded-xl">
            Skip Question
          </button>
        )}
      </div>
    </div>
  );
}
