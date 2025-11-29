import { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { ChevronRight, ChevronLeft } from 'lucide-react';
import { ImageWithFallback } from './figma/ImageWithFallback';

interface OnboardingScreenProps {
  onComplete: () => void;
}

const onboardingSlides = [
  {
    id: 1,
    title: 'Learn African Languages',
    description: 'Master Swahili, Yoruba, Zulu, and many more languages spoken across the African continent',
    image: 'https://images.unsplash.com/photo-1760907949889-eb62b7fd9f75?w=600',
    gradient: 'linear-gradient(135deg, #E74C3C 0%, #FF6B35 100%)',
    icon: '🗣️'
  },
  {
    id: 2,
    title: 'Interactive Lessons',
    description: 'Engage with fun, bite-sized lessons designed to make language learning enjoyable and effective',
    image: 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=600',
    gradient: 'linear-gradient(135deg, #F1C40F 0%, #D4AF37 100%)',
    icon: '📚'
  },
  {
    id: 3,
    title: 'Cultural Immersion',
    description: 'Discover the rich culture, music, art, and history of African communities while you learn',
    image: 'https://images.unsplash.com/photo-1603703182693-51a19941fa59?w=600',
    gradient: 'linear-gradient(135deg, #27AE60 0%, #00D2A3 100%)',
    icon: '🎨'
  },
  {
    id: 4,
    title: 'Join the Community',
    description: 'Connect with fellow learners, compete globally, and track your progress with daily challenges',
    image: 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=600',
    gradient: 'linear-gradient(135deg, #3498DB 0%, #9B59B6 100%)',
    icon: '🌍'
  }
];

export default function OnboardingScreen({ onComplete }: OnboardingScreenProps) {
  const [currentSlide, setCurrentSlide] = useState(0);
  const [direction, setDirection] = useState(0);

  const nextSlide = () => {
    if (currentSlide < onboardingSlides.length - 1) {
      setDirection(1);
      setCurrentSlide(currentSlide + 1);
    } else {
      onComplete();
    }
  };

  const prevSlide = () => {
    if (currentSlide > 0) {
      setDirection(-1);
      setCurrentSlide(currentSlide - 1);
    }
  };

  const skip = () => {
    onComplete();
  };

  const slide = onboardingSlides[currentSlide];

  const slideVariants = {
    enter: (direction: number) => ({
      x: direction > 0 ? 300 : -300,
      opacity: 0
    }),
    center: {
      x: 0,
      opacity: 1
    },
    exit: (direction: number) => ({
      x: direction < 0 ? 300 : -300,
      opacity: 0
    })
  };

  return (
    <div className="w-full h-screen flex flex-col relative overflow-hidden" style={{ background: slide.gradient }}>
      {/* Skip Button */}
      <div className="absolute top-8 right-6 z-20">
        <button
          onClick={skip}
          className="text-white/80 hover:text-white px-4 py-2 rounded-full bg-white/10 backdrop-blur-sm transition-all"
        >
          Skip
        </button>
      </div>

      {/* Slide Content */}
      <div className="flex-1 flex flex-col items-center justify-center px-6 pb-32">
        <AnimatePresence initial={false} custom={direction} mode="wait">
          <motion.div
            key={currentSlide}
            custom={direction}
            variants={slideVariants}
            initial="enter"
            animate="center"
            exit="exit"
            transition={{
              x: { type: 'spring', stiffness: 300, damping: 30 },
              opacity: { duration: 0.2 }
            }}
            className="flex flex-col items-center text-center"
          >
            {/* Icon */}
            <motion.div
              initial={{ scale: 0, rotate: -180 }}
              animate={{ scale: 1, rotate: 0 }}
              transition={{ delay: 0.2, type: 'spring', bounce: 0.6 }}
              className="text-8xl mb-8"
            >
              {slide.icon}
            </motion.div>

            {/* Image */}
            <motion.div
              initial={{ scale: 0.8, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              transition={{ delay: 0.3 }}
              className="mb-8"
            >
              <div className="w-64 h-64 rounded-3xl overflow-hidden shadow-2xl">
                <ImageWithFallback
                  src={slide.image}
                  alt={slide.title}
                  className="w-full h-full object-cover"
                />
              </div>
            </motion.div>

            {/* Title */}
            <motion.h2
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.4 }}
              className="text-white mb-4 px-8"
            >
              {slide.title}
            </motion.h2>

            {/* Description */}
            <motion.p
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.5 }}
              className="text-white/90 px-8 max-w-md"
            >
              {slide.description}
            </motion.p>
          </motion.div>
        </AnimatePresence>
      </div>

      {/* Bottom Navigation */}
      <div className="absolute bottom-0 left-0 right-0 p-6 bg-gradient-to-t from-black/20 to-transparent">
        {/* Dots Indicator */}
        <div className="flex justify-center gap-2 mb-6">
          {onboardingSlides.map((_, index) => (
            <motion.div
              key={index}
              className="h-2 rounded-full bg-white transition-all"
              animate={{
                width: currentSlide === index ? 32 : 8,
                opacity: currentSlide === index ? 1 : 0.5
              }}
            />
          ))}
        </div>

        {/* Navigation Buttons */}
        <div className="flex items-center justify-between gap-4">
          <button
            onClick={prevSlide}
            disabled={currentSlide === 0}
            className="w-14 h-14 rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center disabled:opacity-30 disabled:cursor-not-allowed transition-all hover:bg-white/30"
          >
            <ChevronLeft className="w-6 h-6 text-white" />
          </button>

          <button
            onClick={nextSlide}
            className="flex-1 h-14 rounded-full bg-white text-gray-900 flex items-center justify-center gap-2 shadow-lg hover:shadow-xl transition-all"
          >
            <span className="font-semibold">
              {currentSlide === onboardingSlides.length - 1 ? "Get Started" : "Next"}
            </span>
            <ChevronRight className="w-5 h-5" />
          </button>
        </div>
      </div>

      {/* Decorative Elements */}
      <div className="absolute top-20 left-6 w-20 h-20 rounded-full bg-white/10 backdrop-blur-sm animate-pulse" />
      <div className="absolute bottom-40 right-10 w-16 h-16 rounded-full bg-white/10 backdrop-blur-sm animate-pulse" style={{ animationDelay: '1s' }} />
    </div>
  );
}
