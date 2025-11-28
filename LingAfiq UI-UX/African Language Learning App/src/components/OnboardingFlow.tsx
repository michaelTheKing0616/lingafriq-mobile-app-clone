import { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Button } from './ui/button';
import { ChevronRight, Globe, BookOpen, Users, Trophy } from 'lucide-react';
import { ImageWithFallback } from './figma/ImageWithFallback';

interface OnboardingSlide {
  title: string;
  description: string;
  image: string;
  icon: any;
  gradient: string;
}

const slides: OnboardingSlide[] = [
  {
    title: 'Welcome to AfriLingo',
    description: 'Your reliable companion in the journey through African languages. Immerse yourself in the world of languages with our AI-powered learning platform.',
    image: 'https://images.unsplash.com/photo-1655902586913-e81bce3adeec?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhZnJpY2FuJTIwY3VsdHVyZSUyMGFydHxlbnwxfHx8fDE3NjQzMDY1NTJ8MA&ixlib=rb-4.1.0&q=80&w=1080',
    icon: Globe,
    gradient: 'from-[#CE1126] to-[#FF6B35]',
  },
  {
    title: 'Learn with AI Tutors',
    description: 'Practice with our intelligent AI tutors and translators. Get instant feedback and personalized learning paths tailored to your goals.',
    image: 'https://images.unsplash.com/photo-1523396140703-e5bdad4e5dea?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhZnJpY2FuJTIwbGFuZ3VhZ2VzJTIwc3R1ZHl8ZW58MXx8fHwxNzY0MzA2NTUyfDA&ixlib=rb-4.1.0&q=80&w=1080',
    icon: BookOpen,
    gradient: 'from-[#007A3D] to-[#00A8E8]',
  },
  {
    title: 'Join the Community',
    description: 'Connect with learners worldwide. Share your progress, compete in challenges, and immerse yourself in Pan-African culture.',
    image: 'https://images.unsplash.com/photo-1586627789099-e9d422d1c5cb?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhZnJpY2FuJTIwY29tbXVuaXR5JTIwcGVvcGxlfGVufDF8fHx8MTc2NDMwNjIyOXww&ixlib=rb-4.1.0&q=80&w=1080',
    icon: Users,
    gradient: 'from-[#FCD116] to-[#FF6B35]',
  },
  {
    title: 'Track Your Progress',
    description: 'Earn badges, maintain streaks, and climb global rankings. Celebrate every milestone in your language learning journey.',
    image: 'https://images.unsplash.com/photo-1757009400493-509e7b48c95d?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhZnJpY2FuJTIwcGF0dGVybnMlMjB0ZXh0aWxlc3xlbnwxfHx8fDE3NjQzMDY1NTJ8MA&ixlib=rb-4.1.0&q=80&w=1080',
    icon: Trophy,
    gradient: 'from-[#7B2CBF] to-[#CE1126]',
  },
];

export default function OnboardingFlow({ onComplete }: { onComplete: () => void }) {
  const [currentSlide, setCurrentSlide] = useState(0);

  const nextSlide = () => {
    if (currentSlide < slides.length - 1) {
      setCurrentSlide(currentSlide + 1);
    } else {
      onComplete();
    }
  };

  const skipOnboarding = () => {
    onComplete();
  };

  const slide = slides[currentSlide];
  const Icon = slide.icon;

  return (
    <div className="fixed inset-0 bg-background z-50 overflow-hidden">
      {/* Background Pattern */}
      <div className="absolute inset-0 opacity-5">
        <div className="absolute inset-0" style={{
          backgroundImage: `repeating-linear-gradient(45deg, transparent, transparent 35px, rgba(206, 17, 38, 0.1) 35px, rgba(206, 17, 38, 0.1) 70px)`,
        }} />
      </div>

      <div className="relative h-full flex flex-col max-w-md mx-auto">
        {/* Header */}
        <div className="flex justify-between items-center p-6">
          <div className="flex gap-2">
            {slides.map((_, index) => (
              <div
                key={index}
                className={`h-1 rounded-full transition-all duration-300 ${
                  index === currentSlide ? 'w-8 bg-primary' : 'w-1 bg-muted'
                }`}
              />
            ))}
          </div>
          <Button variant="ghost" onClick={skipOnboarding} className="text-muted-foreground">
            Skip
          </Button>
        </div>

        {/* Content */}
        <div className="flex-1 flex flex-col justify-center px-6 pb-32">
          <AnimatePresence mode="wait">
            <motion.div
              key={currentSlide}
              initial={{ opacity: 0, x: 50 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -50 }}
              transition={{ duration: 0.3 }}
              className="space-y-8"
            >
              {/* Icon with Gradient Background */}
              <motion.div
                initial={{ scale: 0.8, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                transition={{ delay: 0.1 }}
                className="relative mx-auto w-full h-80 rounded-3xl overflow-hidden"
              >
                <div className={`absolute inset-0 bg-gradient-to-br ${slide.gradient} opacity-20`} />
                <ImageWithFallback
                  src={slide.image}
                  alt={slide.title}
                  className="w-full h-full object-cover"
                />
                <div className="absolute inset-0 flex items-center justify-center">
                  <div className={`p-6 rounded-full bg-gradient-to-br ${slide.gradient} shadow-2xl`}>
                    <Icon className="w-16 h-16 text-white" />
                  </div>
                </div>
              </motion.div>

              {/* Text Content */}
              <motion.div
                initial={{ y: 20, opacity: 0 }}
                animate={{ y: 0, opacity: 1 }}
                transition={{ delay: 0.2 }}
                className="text-center space-y-4"
              >
                <h1 className="text-3xl">{slide.title}</h1>
                <p className="text-muted-foreground leading-relaxed px-4">
                  {slide.description}
                </p>
              </motion.div>
            </motion.div>
          </AnimatePresence>
        </div>

        {/* Bottom Button */}
        <div className="absolute bottom-0 left-0 right-0 p-6 bg-gradient-to-t from-background via-background to-transparent">
          <Button
            onClick={nextSlide}
            className={`w-full h-14 rounded-2xl bg-gradient-to-r ${slide.gradient} text-white shadow-lg hover:shadow-xl transition-all duration-300 group`}
            size="lg"
          >
            {currentSlide === slides.length - 1 ? "Get Started" : "Continue"}
            <ChevronRight className="ml-2 w-5 h-5 group-hover:translate-x-1 transition-transform" />
          </Button>
        </div>
      </div>
    </div>
  );
}
