import { motion } from 'motion/react';
import { ChevronLeft, Circle, CheckCircle2 } from 'lucide-react';
import { useState } from 'react';
import { Proficiency } from '../lib/types';

interface ProficiencyScreenProps {
  onSelect: (proficiency: Proficiency) => void;
  onBack: () => void;
}

const proficiencyLevels = [
  {
    id: 'beginner' as Proficiency,
    title: 'Beginner',
    description: 'I\'m new to this language',
    details: 'Perfect for those starting from scratch. Learn basic vocabulary, pronunciation, and simple phrases.',
    icon: '🌱',
    gradient: 'from-green-400 to-green-600'
  },
  {
    id: 'intermediate' as Proficiency,
    title: 'Intermediate',
    description: 'I know some basics',
    details: 'Build on your foundation with more complex grammar, conversations, and cultural nuances.',
    icon: '🌿',
    gradient: 'from-yellow-400 to-orange-500'
  },
  {
    id: 'expert' as Proficiency,
    title: 'Expert',
    description: 'I want to master the language',
    details: 'Advanced content including idioms, professional vocabulary, and native-level comprehension.',
    icon: '🌳',
    gradient: 'from-red-500 to-purple-600'
  }
];

export default function ProficiencyScreen({ onSelect, onBack }: ProficiencyScreenProps) {
  const [selectedLevel, setSelectedLevel] = useState<Proficiency | null>(null);

  const handleSelect = (level: Proficiency) => {
    setSelectedLevel(level);
    setTimeout(() => onSelect(level), 300);
  };

  return (
    <div className="w-full min-h-screen bg-gray-50 flex flex-col">
      {/* Header */}
      <div className="bg-gradient-to-r from-purple-500 via-pink-500 to-red-500 p-6">
        <div className="flex items-center gap-4 mb-4">
          <button
            onClick={onBack}
            className="w-10 h-10 rounded-xl bg-white/20 backdrop-blur-sm flex items-center justify-center text-white"
          >
            <ChevronLeft className="w-5 h-5" />
          </button>
          <div className="flex-1">
            <h1 className="text-white mb-1">Choose Your Level</h1>
            <p className="text-white/90 text-sm">Select your current proficiency</p>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 p-6 overflow-y-auto">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="space-y-4"
        >
          {proficiencyLevels.map((level, index) => (
            <motion.button
              key={level.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
              onClick={() => handleSelect(level.id)}
              className={`w-full bg-white rounded-3xl p-6 shadow-sm border-2 transition-all hover:shadow-md text-left ${
                selectedLevel === level.id
                  ? 'border-purple-500 ring-4 ring-purple-100'
                  : 'border-gray-100'
              }`}
            >
              <div className="flex items-start gap-4">
                {/* Radio Button */}
                <div className="mt-1">
                  {selectedLevel === level.id ? (
                    <CheckCircle2 className="w-6 h-6 text-purple-600" />
                  ) : (
                    <Circle className="w-6 h-6 text-gray-300" />
                  )}
                </div>

                {/* Content */}
                <div className="flex-1">
                  <div className="flex items-center gap-3 mb-2">
                    <div className={`w-12 h-12 rounded-2xl bg-gradient-to-br ${level.gradient} flex items-center justify-center text-2xl shadow-md`}>
                      {level.icon}
                    </div>
                    <div>
                      <h3 className="text-gray-900 mb-1">{level.title}</h3>
                      <p className="text-sm text-gray-600">{level.description}</p>
                    </div>
                  </div>
                  <p className="text-sm text-gray-500 pl-15">
                    {level.details}
                  </p>
                </div>
              </div>
            </motion.button>
          ))}
        </motion.div>

        {/* Info Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          className="mt-6 bg-blue-50 rounded-2xl p-6 border border-blue-100"
        >
          <div className="flex gap-3">
            <span className="text-2xl">💡</span>
            <div>
              <h4 className="text-gray-900 mb-2">Don't worry!</h4>
              <p className="text-sm text-gray-600">
                You can always adjust your level later. We'll personalize your learning path based on your selection.
              </p>
            </div>
          </div>
        </motion.div>
      </div>
    </div>
  );
}
