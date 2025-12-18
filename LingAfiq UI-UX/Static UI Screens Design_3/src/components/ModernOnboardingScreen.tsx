import React from 'react';
import { ChevronRight } from 'lucide-react';
import { ImageWithFallback } from './figma/ImageWithFallback';

export function ModernOnboardingScreen() {
  const [currentSlide, setCurrentSlide] = React.useState(0);

  const slides = [
    {
      topImage: "https://images.unsplash.com/photo-1547922938-a6dcb893f375?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxBZnJpY2FuJTIwdmlsbGFnZSUyMGNvbW11bml0eXxlbnwxfHx8fDE3NjQ3NTg4MDR8MA&ixlib=rb-4.1.0&q=80&w=1080",
      title: "Learn African Languages",
      description: "Connect with your heritage and explore the rich linguistic diversity of Africa"
    },
    {
      topImage: "https://images.unsplash.com/photo-1630067458414-0080622bc0df?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxTd2FoaWxpJTIwY3VsdHVyZSUyMFRhbnphbmlhfGVufDF8fHx8MTc2NDc1ODg2M3ww&ixlib=rb-4.1.0&q=80&w=1080",
      title: "Interactive Learning",
      description: "Engage with AI tutors, play games, and practice with native speakers"
    },
    {
      topImage: "https://images.unsplash.com/photo-1633980990916-74317cba1ea3?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxFdGhpb3BpYW4lMjBjdWx0dXJlJTIwQW1oYXJpY3xlbnwxfHx8fDE3NjQ3NTg4NjR8MA&ixlib=rb-4.1.0&q=80&w=1080",
      title: "Track Your Progress",
      description: "Monitor your achievements, compete with friends, and celebrate milestones"
    },
    {
      topImage: "https://images.unsplash.com/photo-1732027198077-4e29b491d15a?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxBZnJpY2FuJTIwc2F2YW5uYSUyMHN1bnNldHxlbnwxfHx8fDE3NjQ2NjMyNzZ8MA&ixlib=rb-4.1.0&q=80&w=1080",
      title: "Start Your Journey",
      description: "Begin learning today and unlock the beauty of African languages"
    }
  ];

  const currentSlideData = slides[currentSlide];

  return (
    <div className="min-h-screen bg-white flex flex-col">
      {/* Top Image Section */}
      <div className="h-[45vh] relative overflow-hidden">
        <ImageWithFallback 
          src={currentSlideData.topImage}
          alt="Onboarding"
          className="w-full h-full object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-b from-transparent to-white"></div>
      </div>

      {/* Content Section */}
      <div className="flex-1 flex flex-col justify-between px-8 py-8">
        <div className="text-center">
          <h1 className="text-[#007A3D] mb-4">{currentSlideData.title}</h1>
          <p className="text-gray-600 text-lg max-w-md mx-auto">
            {currentSlideData.description}
          </p>
        </div>

        {/* Dot Indicators */}
        <div className="flex justify-center gap-2 mb-8">
          {slides.map((_, index) => (
            <div
              key={index}
              className={`h-2 rounded-full transition-all ${
                index === currentSlide 
                  ? 'bg-[#007A3D] w-8' 
                  : 'bg-gray-300 w-2'
              }`}
            />
          ))}
        </div>

        {/* Navigation Button */}
        <button 
          onClick={() => setCurrentSlide((currentSlide + 1) % slides.length)}
          className="w-16 h-16 ml-auto bg-gradient-to-r from-[#007A3D] to-[#005A2D] rounded-full flex items-center justify-center shadow-xl hover:shadow-2xl transition-all"
        >
          <ChevronRight className="w-8 h-8 text-white" />
        </button>
      </div>

      {/* Bottom Background Image (Decorative) */}
      <div className="h-32 relative overflow-hidden">
        <ImageWithFallback 
          src="https://images.unsplash.com/photo-1763256294121-303b83e7e767?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxBZnJpY2FuJTIwcGF0dGVybnMlMjBjb2xvcmZ1bHxlbnwxfHx8fDE3NjQ3NTg4MDJ8MA&ixlib=rb-4.1.0&q=80&w=1080"
          alt="Pattern"
          className="w-full h-full object-cover opacity-20"
        />
      </div>
    </div>
  );
}
