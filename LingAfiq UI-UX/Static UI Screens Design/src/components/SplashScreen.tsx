import React from 'react';

const facts = [
  "Africa is home to over 2,000 languages",
  "Swahili is spoken by 100+ million people",
  "Africa has 54 countries and diverse cultures",
  "The Baobab tree can live for over 2,000 years",
  "Africa is the second largest continent",
];

const greetings = [
  { text: "Sannu", language: "Hausa", translation: "Hello" },
  { text: "Jambo", language: "Swahili", translation: "Hello" },
  { text: "Ẹ káàbọ̀", language: "Yoruba", translation: "Welcome" },
  { text: "Sawubona", language: "Zulu", translation: "Hello" },
];

export function SplashScreen() {
  const [currentGreeting] = React.useState(greetings[0]);
  const [currentFact] = React.useState(facts[0]);
  const [progress, setProgress] = React.useState(0);
  
  React.useEffect(() => {
    const interval = setInterval(() => {
      setProgress((prev) => Math.min(prev + 1, 100));
    }, 30);
    
    return () => clearInterval(interval);
  }, []);
  
  return (
    <div className="h-screen bg-gradient-to-b from-[#007A3D] via-[#005a2d] to-black flex flex-col items-center justify-between text-white px-6 py-12">
      {/* Top Section */}
      <div className="flex-1 flex flex-col items-center justify-center">
        {/* Logo */}
        <div className="mb-12">
          <div className="w-32 h-32 bg-gradient-to-br from-[#FCD116] to-[#FF6B35] rounded-full flex items-center justify-center shadow-2xl shadow-[#FCD116]/30 mb-6">
            <span className="text-6xl">🌍</span>
          </div>
          <h1 className="text-4xl text-center text-white mb-2">LingAfriq</h1>
          <p className="text-center text-[#FCD116] text-sm tracking-wider">LANGUAGE VILLAGE</p>
        </div>

        {/* Rotating Avatar/Character */}
        <div className="relative mb-8">
          <div className="w-40 h-40 rounded-full bg-gradient-to-br from-white/20 to-white/5 backdrop-blur-sm flex items-center justify-center border-4 border-[#FCD116]/30 shadow-xl animate-pulse">
            <div className="w-32 h-32 rounded-full bg-gradient-to-br from-[#FF6B35] to-[#CE1126] flex items-center justify-center text-6xl">
              👋
            </div>
          </div>
          {/* Decorative African pattern circles */}
          <div className="absolute -top-2 -right-2 w-8 h-8 rounded-full bg-[#FCD116] opacity-70" />
          <div className="absolute -bottom-2 -left-2 w-6 h-6 rounded-full bg-[#FF6B35] opacity-70" />
        </div>

        {/* Greeting */}
        <div className="text-center mb-8">
          <h2 className="text-5xl mb-2">{currentGreeting.text}</h2>
          <p className="text-xl text-white/80">
            {currentGreeting.translation} <span className="text-[#FCD116]">({currentGreeting.language})</span>
          </p>
        </div>
      </div>

      {/* Bottom Section */}
      <div className="w-full space-y-6">
        {/* Interesting Fact */}
        <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-6 border border-white/20">
          <p className="text-sm text-[#FCD116] mb-2">Did you know?</p>
          <p className="text-white text-lg leading-relaxed">{currentFact}</p>
        </div>

        {/* Loading Progress */}
        <div className="space-y-2">
          <p className="text-center text-white/70 text-sm">Loading your journey...</p>
          <div className="w-full h-2 bg-white/20 rounded-full overflow-hidden">
            <div
              className="h-full bg-gradient-to-r from-[#FCD116] via-[#FF6B35] to-[#FCD116] rounded-full transition-all duration-300 animate-pulse"
              style={{ width: `${progress}%` }}
            />
          </div>
          <p className="text-center text-white/50 text-xs">{progress}%</p>
        </div>
      </div>
    </div>
  );
}
