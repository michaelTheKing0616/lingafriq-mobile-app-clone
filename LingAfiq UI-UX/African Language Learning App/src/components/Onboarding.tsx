import { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { ChevronRight, Globe, Trophy, MessageCircle, BookOpen, Sparkles } from 'lucide-react';
import { Button } from './ui/button';

type OnboardingStep = {
  title: string;
  description: string;
  icon: React.ReactNode;
  gradient: string;
  image: string;
};

const onboardingSteps: OnboardingStep[] = [
  {
    title: 'Connect with African Heritage',
    description: 'Learn authentic African languages from native speakers and immerse yourself in rich cultural traditions.',
    icon: <Globe className="w-16 h-16" />,
    gradient: 'gradient-african-sunset',
    image: 'https://images.unsplash.com/photo-1523396140703-e5bdad4e5dea?w=800'
  },
  {
    title: 'Interactive Learning Experience',
    description: 'Engage with AI-powered tutors, interactive games, and real-world conversations to accelerate your learning.',
    icon: <Sparkles className="w-16 h-16" />,
    gradient: 'gradient-african-nature',
    image: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=800'
  },
  {
    title: 'Track Your Progress',
    description: 'Earn XP, unlock badges, and compete on global leaderboards while building your language skills.',
    icon: <Trophy className="w-16 h-16" />,
    gradient: 'gradient-african-royal',
    image: 'https://images.unsplash.com/photo-1547471080-7cc2caa01a7e?w=800'
  },
  {
    title: 'Join Our Community',
    description: 'Connect with millions of learners worldwide, share experiences, and discover African culture together.',
    icon: <MessageCircle className="w-16 h-16" />,
    gradient: 'gradient-african-earth',
    image: 'https://images.unsplash.com/photo-1516026672322-bc52d61a55d5?w=800'
  }
];

type OnboardingProps = {
  onComplete: () => void;
};

export default function Onboarding({ onComplete }: OnboardingProps) {
  const [currentStep, setCurrentStep] = useState(0);
  const step = onboardingSteps[currentStep];
  const isLastStep = currentStep === onboardingSteps.length - 1;

  const handleNext = () => {
    if (isLastStep) {
      onComplete();
    } else {
      setCurrentStep(prev => prev + 1);
    }
  };

  const handleSkip = () => {
    onComplete();
  };

  return (
    <div className="min-h-screen relative overflow-hidden bg-gradient-to-br from-stone-50 to-stone-100">
      {/* Background Pattern */}
      <div className="african-pattern-overlay absolute inset-0" />
      
      <div className="relative z-10 flex flex-col h-screen">
        {/* Header */}
        <div className="flex justify-between items-center p-6">
          <div className="flex gap-2">
            {onboardingSteps.map((_, index) => (
              <div
                key={index}
                className={`h-1 rounded-full transition-all duration-300 ${
                  index === currentStep 
                    ? 'w-8 bg-[#E63946]' 
                    : index < currentStep
                    ? 'w-8 bg-[#F4A261]'
                    : 'w-8 bg-stone-300'
                }`}
              />
            ))}
          </div>
          <button
            onClick={handleSkip}
            className="text-stone-600 hover:text-stone-900 transition-colors px-4 py-2"
          >
            Skip
          </button>
        </div>

        {/* Content */}
        <div className="flex-1 flex flex-col items-center justify-center px-6 pb-12">
          <AnimatePresence mode="wait">
            <motion.div
              key={currentStep}
              initial={{ opacity: 0, x: 50 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -50 }}
              transition={{ duration: 0.4 }}
              className="w-full max-w-lg flex flex-col items-center text-center"
            >
              {/* Image Section */}
              <motion.div
                initial={{ scale: 0.8, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                transition={{ delay: 0.2, duration: 0.5 }}
                className={`w-full aspect-square max-w-sm rounded-3xl overflow-hidden mb-8 shadow-2xl relative ${step.gradient}`}
              >
                <img 
                  src={step.image} 
                  alt={step.title}
                  className="w-full h-full object-cover mix-blend-overlay opacity-80"
                />
                <div className="absolute inset-0 flex items-center justify-center">
                  <div className="text-white drop-shadow-lg">
                    {step.icon}
                  </div>
                </div>
              </motion.div>

              {/* Text Content */}
              <motion.h2
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.3, duration: 0.5 }}
                className="mb-4 text-stone-900 max-w-md"
              >
                {step.title}
              </motion.h2>

              <motion.p
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.4, duration: 0.5 }}
                className="text-stone-600 max-w-md leading-relaxed"
              >
                {step.description}
              </motion.p>
            </motion.div>
          </AnimatePresence>
        </div>

        {/* Navigation Button */}
        <div className="p-6">
          <Button
            onClick={handleNext}
            className="w-full h-14 bg-[#E63946] hover:bg-[#C62F3A] text-white rounded-2xl shadow-lg transition-all duration-300 hover:shadow-xl hover:-translate-y-0.5"
            size="lg"
          >
            <span className="flex items-center justify-center gap-2">
              {isLastStep ? "Get Started" : "Continue"}
              <ChevronRight className="w-5 h-5" />
            </span>
          </Button>
        </div>
      </div>
    </div>
  );
}
