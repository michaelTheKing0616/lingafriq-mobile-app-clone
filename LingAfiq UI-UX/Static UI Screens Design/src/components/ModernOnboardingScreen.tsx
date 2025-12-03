import React from 'react';
import { ArrowRight } from 'lucide-react';
import { ImageWithFallback } from './figma/ImageWithFallback';

const onboardingSlides = [
  {
    topImage: 'https://images.unsplash.com/photo-1586627789099-e9d422d1c5cb?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhZnJpY2FuJTIwY29tbXVuaXR5JTIwcGVvcGxlfGVufDF8fHx8MTc2NDc1MTA0Nnww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
    title: 'Learn Authentic African Languages',
    description: 'Connect with African cultures through their native languages. Start your journey today.',
  },
  {
    topImage: 'https://images.unsplash.com/photo-1761251948108-f89666f5b4ca?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxsYW5ndWFnZSUyMGxlYXJuaW5nJTIwZWR1Y2F0aW9ufGVufDF8fHx8MTc2NDc1MTA0Nnww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
    title: 'Interactive Lessons & Games',
    description: 'Make learning fun with interactive lessons, quizzes, and language games designed for all levels.',
  },
  {
    topImage: 'https://images.unsplash.com/photo-1746189861370-7a41351d7f11?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhZnJpY2FuJTIwY3VsdHVyZSUyMGNlbGVicmF0aW9ufGVufDF8fHx8MTc2NDc1MTA0Nnww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
    title: 'Cultural Immersion',
    description: 'Explore rich African cultures, traditions, and histories while learning the language.',
  },
  {
    topImage: 'https://images.unsplash.com/photo-1633250391894-397930e3f5f2?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtb2JpbGUlMjBhcHAlMjBsZWFybmluZ3xlbnwxfHx8fDE3NjQ2ODA1NzV8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
    title: 'Learn at Your Own Pace',
    description: 'Practice anytime, anywhere. Track your progress and achieve your language goals.',
  },
];

export function ModernOnboardingScreen() {
  const [currentSlide, setCurrentSlide] = React.useState(0);
  
  const nextSlide = () => {
    if (currentSlide < onboardingSlides.length - 1) {
      setCurrentSlide(currentSlide + 1);
    }
  };
  
  const slide = onboardingSlides[currentSlide];
  
  return (
    <div className="h-screen bg-white flex flex-col">
      {/* Skip Button */}
      <div className="absolute top-8 right-6 z-10">
        <button className="text-gray-600 hover:text-gray-900 transition-colors">
          Skip
        </button>
      </div>

      {/* Top Image Section */}
      <div className="relative h-[55%] overflow-hidden">
        <ImageWithFallback
          src={slide.topImage}
          alt={slide.title}
          className="w-full h-full object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-b from-transparent via-transparent to-white" />
      </div>

      {/* Content Section */}
      <div className="flex-1 px-8 py-6 flex flex-col">
        {/* Pagination Dots */}
        <div className="flex items-center justify-center gap-2 mb-8">
          {onboardingSlides.map((_, index) => (
            <div
              key={index}
              className={`h-2 rounded-full transition-all ${
                index === currentSlide
                  ? 'w-8 bg-[#007A3D]'
                  : 'w-2 bg-gray-300'
              }`}
            />
          ))}
        </div>

        {/* Title & Description */}
        <div className="flex-1 flex flex-col items-center text-center">
          <h2 className="text-gray-900 text-3xl mb-4 leading-tight">
            {slide.title}
          </h2>
          <p className="text-gray-600 text-lg max-w-md leading-relaxed">
            {slide.description}
          </p>
        </div>

        {/* Next Button */}
        <button
          onClick={nextSlide}
          className="w-full bg-gradient-to-r from-[#007A3D] to-[#00a84f] text-white py-4 rounded-2xl flex items-center justify-center gap-2 hover:shadow-lg transition-all"
        >
          <span className="text-lg">
            {currentSlide === onboardingSlides.length - 1 ? 'Get Started' : 'Next'}
          </span>
          <ArrowRight className="w-5 h-5" />
        </button>
      </div>
    </div>
  );
}
