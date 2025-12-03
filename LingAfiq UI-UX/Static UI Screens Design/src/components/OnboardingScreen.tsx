import React from 'react';
import { ArrowRight, X } from 'lucide-react';
import { ImageWithFallback } from './figma/ImageWithFallback';

type Step = {
  id: number;
  title: string;
  character?: string;
  dialogue?: string;
  subtitle?: string;
  content: React.ReactNode;
};

export function OnboardingScreen() {
  const [currentStep, setCurrentStep] = React.useState(1);
  const [selections, setSelections] = React.useState({
    age: null as string | null,
    purpose: [] as string[],
    language: null as string | null,
    level: null as string | null,
    learningStyle: [] as string[],
    duration: 15,
    timeOfDay: null as string | null,
    goals: [] as string[],
    tone: null as string | null,
    gamification: null as string | null,
    accessibility: {
      largeText: false,
      highContrast: false,
      dyslexiaFriendly: false,
      soundOff: false,
      motionReduction: false,
    },
    social: null as string | null,
    username: '',
  });

  const totalSteps = 10;
  const progress = (currentStep / totalSteps) * 100;

  const canProceed = () => {
    switch (currentStep) {
      case 1: return true;
      case 2: return selections.age && selections.purpose.length > 0;
      case 3: return selections.language && selections.level;
      case 4: return selections.learningStyle.length > 0;
      case 5: return selections.timeOfDay;
      case 6: return selections.goals.length > 0;
      case 7: return selections.tone && selections.gamification;
      case 8: return true;
      case 9: return selections.social;
      case 10: return selections.username.trim().length > 0;
      default: return false;
    }
  };

  const renderStep = () => {
    switch (currentStep) {
      case 1:
        return (
          <div className="flex-1 flex flex-col items-center justify-center text-center px-6">
            <div className="relative mb-12">
              <ImageWithFallback
                src="https://images.unsplash.com/photo-1760199078320-18976d421338?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhZnJpY2FuJTIwc2F2YW5uYSUyMGJhb2JhYiUyMHRyZWV8ZW58MXx8fHwxNzY0NzUwOTE4fDA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral"
                alt="Baobab tree"
                className="w-40 h-40 rounded-full object-cover shadow-2xl"
              />
              <div className="absolute -bottom-4 left-1/2 -translate-x-1/2 bg-white px-4 py-2 rounded-full shadow-lg">
                <span className="text-2xl">🌳</span>
              </div>
            </div>
            <h1 className="text-4xl text-gray-900 mb-4">Welcome to Kijiji cha Lugha</h1>
            <p className="text-xl text-gray-600 mb-2">The Language Village</p>
            <p className="text-gray-500 max-w-md">Your journey to learning African languages begins here</p>
          </div>
        );

      case 2:
        return (
          <div className="px-6 py-8">
            <div className="mb-8 text-center">
              <div className="w-20 h-20 bg-gradient-to-br from-[#7B2CBF] to-[#9d4edd] rounded-full mx-auto mb-4 flex items-center justify-center text-4xl shadow-lg">
                👴
              </div>
              <h2 className="text-gray-900 text-2xl mb-2">Mzee Kato, the Elder</h2>
              <p className="text-gray-600 italic">"Welcome, traveler. I am Mzee Kato, keeper of the village memory."</p>
            </div>

            <div className="space-y-6">
              <div>
                <p className="text-gray-700 mb-3">Who are you?</p>
                <div className="flex gap-3">
                  {['CHILD', 'TEEN', 'ADULT'].map((age) => (
                    <button
                      key={age}
                      onClick={() => setSelections({ ...selections, age })}
                      className={`flex-1 py-3 px-4 rounded-xl transition-all ${
                        selections.age === age
                          ? 'bg-gradient-to-r from-[#007A3D] to-[#00a84f] text-white shadow-lg'
                          : 'bg-white border-2 border-gray-200 text-gray-700 hover:border-[#007A3D]'
                      }`}
                    >
                      {age}
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <p className="text-gray-700 mb-3">Why do you want to learn? (Select all that apply)</p>
                <div className="grid grid-cols-2 gap-3">
                  {['HERITAGE', 'TRAVEL', 'SCHOOL', 'BUSINESS', 'CURIOSITY'].map((purpose) => (
                    <button
                      key={purpose}
                      onClick={() => {
                        const newPurposes = selections.purpose.includes(purpose)
                          ? selections.purpose.filter(p => p !== purpose)
                          : [...selections.purpose, purpose];
                        setSelections({ ...selections, purpose: newPurposes });
                      }}
                      className={`py-3 px-4 rounded-xl transition-all ${
                        selections.purpose.includes(purpose)
                          ? 'bg-gradient-to-r from-[#FF6B35] to-[#FCD116] text-white shadow-lg'
                          : 'bg-white border-2 border-gray-200 text-gray-700 hover:border-[#FF6B35]'
                      }`}
                    >
                      {purpose}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          </div>
        );

      case 3:
        return (
          <div className="px-6 py-8">
            <div className="mb-8 text-center">
              <div className="w-20 h-20 bg-gradient-to-br from-[#FF6B35] to-[#FCD116] rounded-full mx-auto mb-4 flex items-center justify-center text-4xl shadow-lg">
                🧶
              </div>
              <h2 className="text-gray-900 text-2xl mb-2">Adisa, the Weaver</h2>
              <p className="text-gray-600 italic">"I am Adisa, the Weaver. Choose the threads of your voice."</p>
            </div>

            <div className="space-y-6">
              <div>
                <p className="text-gray-700 mb-3">Select a language</p>
                <div className="grid grid-cols-2 gap-3">
                  {['Swahili', 'Yoruba', 'Amharic', 'Zulu', 'Hausa', 'Igbo'].map((lang) => (
                    <button
                      key={lang}
                      onClick={() => setSelections({ ...selections, language: lang })}
                      className={`py-4 px-4 rounded-xl transition-all ${
                        selections.language === lang
                          ? 'bg-gradient-to-r from-[#007A3D] to-[#00a84f] text-white shadow-lg'
                          : 'bg-white border-2 border-gray-200 text-gray-700 hover:border-[#007A3D]'
                      }`}
                    >
                      {lang}
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <p className="text-gray-700 mb-3">Your proficiency level</p>
                <div className="flex gap-3">
                  {['BEGINNER', 'INTERMEDIATE', 'ADVANCED'].map((level) => (
                    <button
                      key={level}
                      onClick={() => setSelections({ ...selections, level })}
                      className={`flex-1 py-3 px-4 rounded-xl transition-all ${
                        selections.level === level
                          ? 'bg-gradient-to-r from-[#7B2CBF] to-[#9d4edd] text-white shadow-lg'
                          : 'bg-white border-2 border-gray-200 text-gray-700 hover:border-[#7B2CBF]'
                      }`}
                    >
                      {level}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          </div>
        );

      case 4:
        return (
          <div className="px-6 py-8">
            <div className="mb-8 text-center">
              <div className="w-20 h-20 bg-gradient-to-br from-[#CE1126] to-[#e01636] rounded-full mx-auto mb-4 flex items-center justify-center text-4xl shadow-lg">
                🥁
              </div>
              <h2 className="text-gray-900 text-2xl mb-2">Nuru, the Rhythm Master</h2>
              <p className="text-gray-600 italic">"Tap the drum that sings to your spirit."</p>
            </div>

            <div>
              <p className="text-gray-700 mb-4">How do you learn best? (Select all that apply)</p>
              <div className="grid grid-cols-2 gap-3">
                {['AUDIO', 'VISUAL', 'STORIES', 'DRILLS', 'CONVERSATION'].map((style) => (
                  <button
                    key={style}
                    onClick={() => {
                      const newStyles = selections.learningStyle.includes(style)
                        ? selections.learningStyle.filter(s => s !== style)
                        : [...selections.learningStyle, style];
                      setSelections({ ...selections, learningStyle: newStyles });
                    }}
                    className={`py-4 px-4 rounded-xl transition-all ${
                      selections.learningStyle.includes(style)
                        ? 'bg-gradient-to-r from-[#CE1126] to-[#e01636] text-white shadow-lg'
                        : 'bg-white border-2 border-gray-200 text-gray-700 hover:border-[#CE1126]'
                    }`}
                  >
                    {style}
                  </button>
                ))}
              </div>
            </div>
          </div>
        );

      case 5:
        return (
          <div className="px-6 py-8">
            <div className="mb-8 text-center">
              <div className="w-20 h-20 bg-gradient-to-br from-[#FCD116] to-[#FF6B35] rounded-full mx-auto mb-4 flex items-center justify-center text-4xl shadow-lg">
                ⏰
              </div>
              <h2 className="text-gray-900 text-2xl mb-2">Zawadi, the Timekeeper</h2>
              <p className="text-gray-600 italic">"When shall we train your tongue?"</p>
            </div>

            <div className="space-y-6">
              <div>
                <p className="text-gray-700 mb-3">Minutes per day: {selections.duration}</p>
                <input
                  type="range"
                  min="5"
                  max="60"
                  value={selections.duration}
                  onChange={(e) => setSelections({ ...selections, duration: parseInt(e.target.value) })}
                  className="w-full h-3 bg-gray-200 rounded-lg appearance-none cursor-pointer accent-[#007A3D]"
                />
                <div className="flex justify-between text-sm text-gray-500 mt-2">
                  <span>5 min</span>
                  <span>30 min</span>
                  <span>60 min</span>
                </div>
              </div>

              <div>
                <p className="text-gray-700 mb-3">Preferred time of day</p>
                <div className="grid grid-cols-2 gap-3">
                  {['SUNRISE', 'MIDDAY', 'SUNSET', 'NIGHT'].map((time) => (
                    <button
                      key={time}
                      onClick={() => setSelections({ ...selections, timeOfDay: time })}
                      className={`py-4 px-4 rounded-xl transition-all ${
                        selections.timeOfDay === time
                          ? 'bg-gradient-to-r from-[#FCD116] to-[#FF6B35] text-white shadow-lg'
                          : 'bg-white border-2 border-gray-200 text-gray-700 hover:border-[#FCD116]'
                      }`}
                    >
                      {time === 'SUNRISE' && '🌅 '}
                      {time === 'MIDDAY' && '☀️ '}
                      {time === 'SUNSET' && '🌇 '}
                      {time === 'NIGHT' && '🌙 '}
                      {time}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          </div>
        );

      case 10:
        return (
          <div className="px-6 py-8 text-center">
            <div className="mb-8">
              <div className="text-6xl mb-4">🎉</div>
              <h2 className="text-gray-900 text-2xl mb-4">One Last Thing!</h2>
              <p className="text-gray-600 italic mb-8">"A learner without a name is a drum without a rhythm!"</p>
            </div>

            <div className="max-w-md mx-auto">
              <input
                type="text"
                value={selections.username}
                onChange={(e) => setSelections({ ...selections, username: e.target.value })}
                placeholder="Enter your username"
                className="w-full px-6 py-4 rounded-2xl border-2 border-gray-200 focus:border-[#007A3D] outline-none text-center text-xl"
              />
            </div>
          </div>
        );

      default:
        return (
          <div className="px-6 py-8 text-center">
            <h2 className="text-gray-900 text-2xl mb-4">Step {currentStep}</h2>
            <p className="text-gray-600">Content for this step...</p>
          </div>
        );
    }
  };

  return (
    <div className="h-screen bg-gradient-to-b from-[#D4A574] to-[#8B6F47] flex flex-col">
      {/* Progress Dots */}
      <div className="flex items-center justify-center gap-2 py-6">
        {Array.from({ length: totalSteps }).map((_, index) => (
          <div
            key={index}
            className={`w-2 h-2 rounded-full transition-all ${
              index + 1 === currentStep
                ? 'w-6 bg-white'
                : index + 1 < currentStep
                ? 'bg-white'
                : 'bg-white/30'
            }`}
          />
        ))}
      </div>

      {/* Skip Button */}
      {currentStep <= 3 && (
        <button className="absolute top-6 right-6 text-white/80 hover:text-white text-sm">
          Skip
        </button>
      )}

      {/* Content */}
      <div className="flex-1 bg-white rounded-t-[32px] shadow-2xl overflow-y-auto">
        {renderStep()}
      </div>

      {/* Navigation Buttons */}
      <div className="bg-white px-6 py-6">
        <button
          onClick={() => setCurrentStep(Math.min(currentStep + 1, totalSteps))}
          disabled={!canProceed()}
          className="w-full bg-gradient-to-r from-[#007A3D] to-[#00a84f] text-white py-4 rounded-2xl flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed hover:shadow-lg transition-all"
        >
          <span className="text-lg">
            {currentStep === totalSteps ? 'Begin Journey' : 'Next'}
          </span>
          <ArrowRight className="w-5 h-5" />
        </button>
      </div>
    </div>
  );
}
