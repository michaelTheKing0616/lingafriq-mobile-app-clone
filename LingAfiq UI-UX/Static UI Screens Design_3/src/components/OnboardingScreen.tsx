import React from 'react';
import { ArrowRight, ChevronRight, X } from 'lucide-react';
import { ImageWithFallback } from './figma/ImageWithFallback';

export function OnboardingScreen() {
  const [step, setStep] = React.useState(0);

  const steps = [
    {
      title: "Welcome to Kijiji cha Lugha",
      subtitle: "The Language Village",
      content: "Your journey begins here",
      image: "https://images.unsplash.com/photo-1704684391018-5ec0a70106f5?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxiYW9iYWIlMjB0cmVlJTIwQWZyaWNhfGVufDF8fHx8MTc2NDc1ODgwM3ww&ixlib=rb-4.1.0&q=80&w=1080"
    },
    {
      title: "The Elder",
      character: "Mzee Kato",
      dialogue: "Welcome, traveler. I am Mzee Kato, keeper of the village memory.",
      question: "Who are you?",
      type: "age_purpose"
    },
    {
      title: "The Weaver",
      character: "Adisa the Weaver",
      dialogue: "I am Adisa, the Weaver. Choose the threads of your voice.",
      question: "Select your language",
      type: "language_selection"
    },
    {
      title: "Rhythm Master",
      character: "Nuru",
      dialogue: "I am Nuru the Rhythm Master. Tap the drum that sings to your spirit.",
      question: "How do you learn best?",
      type: "learning_style"
    },
    {
      title: "Timekeeper",
      character: "Zawadi",
      dialogue: "I am Zawadi, keeper of time. When shall we train your tongue?",
      question: "Set your schedule",
      type: "schedule"
    }
  ];

  const currentStep = steps[step];

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#D4A574] to-[#8B6F47] relative overflow-hidden">
      {/* African Pattern Overlay */}
      <div className="absolute inset-0 opacity-5">
        <div className="w-full h-full" style={{
          backgroundImage: 'repeating-linear-gradient(45deg, transparent, transparent 10px, rgba(0,0,0,.1) 10px, rgba(0,0,0,.1) 20px)'
        }}></div>
      </div>

      {/* Skip Button */}
      {step < 3 && (
        <button className="absolute top-6 right-6 z-20 text-white/80 hover:text-white flex items-center gap-1">
          Skip <X className="w-4 h-4" />
        </button>
      )}

      {/* Progress Dots */}
      <div className="absolute top-6 left-1/2 -translate-x-1/2 flex gap-2 z-20">
        {[...Array(10)].map((_, i) => (
          <div
            key={i}
            className={`w-2 h-2 rounded-full transition-all ${
              i === step ? 'bg-white w-6' : 'bg-white/40'
            }`}
          />
        ))}
      </div>

      {/* Content */}
      <div className="relative z-10 h-screen flex flex-col justify-between p-8 pt-20">
        {step === 0 ? (
          // Welcome Screen
          <div className="flex-1 flex flex-col items-center justify-center">
            <div className="w-48 h-48 rounded-full overflow-hidden mb-8 border-4 border-white shadow-2xl">
              <ImageWithFallback 
                src={currentStep.image}
                alt="Baobab tree"
                className="w-full h-full object-cover"
              />
            </div>
            <h1 className="text-white text-center mb-3">{currentStep.title}</h1>
            <p className="text-white/90 text-center text-xl mb-12">{currentStep.subtitle}</p>
            <p className="text-white/80 text-center text-2xl mb-16">{currentStep.content}</p>
            
            <button 
              onClick={() => setStep(1)}
              className="bg-white text-[#007A3D] px-12 py-4 rounded-full shadow-xl hover:shadow-2xl transition-all flex items-center gap-3"
            >
              Begin Journey
              <ArrowRight className="w-5 h-5" />
            </button>
          </div>
        ) : (
          // Character Screens
          <>
            {/* Character Icon */}
            <div className="flex flex-col items-center mb-6">
              <div className="w-32 h-32 rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center mb-4 border-2 border-white/40">
                <span className="text-6xl">
                  {step === 1 && '👴🏿'}
                  {step === 2 && '🧵'}
                  {step === 3 && '🥁'}
                  {step === 4 && '⏰'}
                </span>
              </div>
              <h3 className="text-white mb-2">{currentStep.character}</h3>
              <p className="text-white/90 text-center max-w-md mb-6">"{currentStep.dialogue}"</p>
            </div>

            {/* Question & Options */}
            <div className="flex-1 flex flex-col justify-center">
              <h2 className="text-white text-center mb-8">{currentStep.question}</h2>

              {currentStep.type === 'age_purpose' && (
                <div className="space-y-4">
                  <div className="flex gap-3 justify-center mb-6">
                    <button className="bg-white/90 px-6 py-3 rounded-full hover:bg-white transition-colors">
                      CHILD
                    </button>
                    <button className="bg-white/90 px-6 py-3 rounded-full hover:bg-white transition-colors">
                      TEEN
                    </button>
                    <button className="bg-white/90 px-6 py-3 rounded-full hover:bg-white transition-colors">
                      ADULT
                    </button>
                  </div>
                  <div className="flex flex-wrap gap-3 justify-center">
                    <button className="bg-white/20 border-2 border-white/40 text-white px-5 py-2 rounded-full hover:bg-white/30 transition-colors">
                      Heritage
                    </button>
                    <button className="bg-white/20 border-2 border-white/40 text-white px-5 py-2 rounded-full hover:bg-white/30 transition-colors">
                      Travel
                    </button>
                    <button className="bg-white/20 border-2 border-white/40 text-white px-5 py-2 rounded-full hover:bg-white/30 transition-colors">
                      School
                    </button>
                    <button className="bg-white/20 border-2 border-white/40 text-white px-5 py-2 rounded-full hover:bg-white/30 transition-colors">
                      Business
                    </button>
                    <button className="bg-white/20 border-2 border-white/40 text-white px-5 py-2 rounded-full hover:bg-white/30 transition-colors">
                      Curiosity
                    </button>
                  </div>
                </div>
              )}

              {currentStep.type === 'language_selection' && (
                <div className="grid grid-cols-2 gap-4 max-w-md mx-auto">
                  {['Swahili', 'Yoruba', 'Amharic', 'Zulu', 'Hausa', 'Igbo'].map((lang) => (
                    <button key={lang} className="bg-white/90 px-6 py-4 rounded-2xl hover:bg-white transition-colors shadow-lg">
                      {lang}
                    </button>
                  ))}
                </div>
              )}

              {currentStep.type === 'learning_style' && (
                <div className="flex flex-wrap gap-3 justify-center max-w-md mx-auto">
                  {['Audio', 'Visual', 'Stories', 'Drills', 'Conversation'].map((style) => (
                    <button key={style} className="bg-white/90 px-6 py-3 rounded-full hover:bg-white transition-colors">
                      {style}
                    </button>
                  ))}
                </div>
              )}

              {currentStep.type === 'schedule' && (
                <div className="space-y-6 max-w-md mx-auto">
                  <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-6 border border-white/40">
                    <p className="text-white mb-3">Daily practice time</p>
                    <input type="range" min="5" max="25" defaultValue="15" className="w-full" />
                    <p className="text-white/80 text-center mt-2">15 minutes/day</p>
                  </div>
                  <div className="flex gap-3 justify-center">
                    <button className="bg-white/90 px-5 py-3 rounded-full hover:bg-white transition-colors">
                      🌅 Sunrise
                    </button>
                    <button className="bg-white/90 px-5 py-3 rounded-full hover:bg-white transition-colors">
                      ☀️ Midday
                    </button>
                    <button className="bg-white/90 px-5 py-3 rounded-full hover:bg-white transition-colors">
                      🌆 Sunset
                    </button>
                    <button className="bg-white/90 px-5 py-3 rounded-full hover:bg-white transition-colors">
                      🌙 Night
                    </button>
                  </div>
                </div>
              )}
            </div>

            {/* Next Button */}
            <div className="flex justify-center mt-8">
              <button 
                onClick={() => setStep(Math.min(step + 1, steps.length - 1))}
                className="bg-white text-[#007A3D] px-10 py-4 rounded-full shadow-xl hover:shadow-2xl transition-all flex items-center gap-2"
              >
                Next
                <ChevronRight className="w-5 h-5" />
              </button>
            </div>
          </>
        )}
      </div>
    </div>
  );
}
