import { useState } from 'react';
import { motion } from 'motion/react';
import { Button } from './ui/button';
import { Card } from './ui/card';
import { RadioGroup, RadioGroupItem } from './ui/radio-group';
import { Label } from './ui/label';
import { ArrowLeft, ChevronRight, Sparkles, BookOpen, GraduationCap } from 'lucide-react';

interface ProficiencyLevel {
  id: string;
  title: string;
  description: string;
  icon: any;
  gradient: string;
  features: string[];
}

const proficiencyLevels: ProficiencyLevel[] = [
  {
    id: 'beginner',
    title: 'Beginner',
    description: "I'm new to this language",
    icon: Sparkles,
    gradient: 'from-[#007A3D] to-[#00A8E8]',
    features: [
      'Start from the basics',
      'Learn alphabet and pronunciation',
      'Basic vocabulary and phrases',
      'Guided lessons with lots of support',
    ],
  },
  {
    id: 'intermediate',
    title: 'Intermediate',
    description: 'I know some basics already',
    icon: BookOpen,
    gradient: 'from-[#FCD116] to-[#FF6B35]',
    features: [
      'Build on existing knowledge',
      'Expand vocabulary significantly',
      'Practice conversations',
      'Learn grammar rules and structures',
    ],
  },
  {
    id: 'expert',
    title: 'Expert',
    description: 'I want to achieve fluency',
    icon: GraduationCap,
    gradient: 'from-[#CE1126] to-[#7B2CBF]',
    features: [
      'Advanced lessons and content',
      'Master complex grammar',
      'Cultural nuances and idioms',
      'Read and discuss literature',
    ],
  },
];

interface ProficiencySelectionProps {
  language: string;
  onSelect: (level: string) => void;
  onBack?: () => void;
}

export default function ProficiencySelection({
  language,
  onSelect,
  onBack,
}: ProficiencySelectionProps) {
  const [selectedLevel, setSelectedLevel] = useState('');

  const handleContinue = () => {
    if (selectedLevel) {
      onSelect(selectedLevel);
    }
  };

  return (
    <div className="min-h-screen bg-background flex flex-col">
      {/* Header */}
      <div className="relative bg-gradient-to-br from-[#7B2CBF] to-[#CE1126] px-6 pt-12 pb-8 rounded-b-[2.5rem] shadow-lg">
        <div className="absolute inset-0 opacity-10">
          <div
            className="absolute inset-0"
            style={{
              backgroundImage: `repeating-linear-gradient(45deg, transparent, transparent 35px, rgba(255, 255, 255, 0.3) 35px, rgba(255, 255, 255, 0.3) 70px)`,
            }}
          />
        </div>

        <div className="relative">
          {onBack && (
            <Button
              variant="ghost"
              size="icon"
              onClick={onBack}
              className="absolute -left-2 -top-2 text-white hover:bg-white/20 rounded-full"
            >
              <ArrowLeft className="w-5 h-5" />
            </Button>
          )}

          <div className="text-center text-white pt-8">
            <h1 className="text-3xl mb-2">Your {language} Level</h1>
            <p className="opacity-90">Select your current proficiency level</p>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 px-6 py-6 pb-32 overflow-y-auto">
        <RadioGroup value={selectedLevel} onValueChange={setSelectedLevel}>
          <div className="space-y-4">
            {proficiencyLevels.map((level, index) => {
              const Icon = level.icon;
              const isSelected = selectedLevel === level.id;

              return (
                <motion.div
                  key={level.id}
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: index * 0.1 }}
                >
                  <Card
                    onClick={() => setSelectedLevel(level.id)}
                    className={`relative overflow-hidden cursor-pointer transition-all duration-300 border-2 ${
                      isSelected
                        ? 'border-primary shadow-lg scale-[1.02]'
                        : 'border-transparent shadow hover:shadow-md'
                    }`}
                  >
                    {/* Gradient Background when selected */}
                    {isSelected && (
                      <div
                        className={`absolute inset-0 bg-gradient-to-br ${level.gradient} opacity-5`}
                      />
                    )}

                    <div className="relative p-5">
                      <div className="flex items-start gap-4 mb-4">
                        {/* Icon */}
                        <div
                          className={`p-3 rounded-2xl bg-gradient-to-br ${level.gradient} shadow-md`}
                        >
                          <Icon className="w-6 h-6 text-white" />
                        </div>

                        {/* Title and Description */}
                        <div className="flex-1">
                          <div className="flex items-center gap-3 mb-1">
                            <h3>{level.title}</h3>
                            <RadioGroupItem value={level.id} id={level.id} className="mt-1" />
                          </div>
                          <p className="text-sm text-muted-foreground">{level.description}</p>
                        </div>
                      </div>

                      {/* Features List */}
                      <div className="space-y-2 pl-14">
                        {level.features.map((feature, idx) => (
                          <div key={idx} className="flex items-center gap-2">
                            <div
                              className={`w-1.5 h-1.5 rounded-full ${
                                isSelected ? 'bg-primary' : 'bg-muted-foreground'
                              }`}
                            />
                            <p className="text-sm text-muted-foreground">{feature}</p>
                          </div>
                        ))}
                      </div>
                    </div>
                  </Card>
                </motion.div>
              );
            })}
          </div>
        </RadioGroup>

        {/* Info Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          className="mt-6"
        >
          <Card className="p-5 rounded-2xl bg-muted/50 border-0">
            <p className="text-sm text-muted-foreground text-center">
              💡 Don't worry! You can always adjust your level later based on your progress and
              comfort with the lessons.
            </p>
          </Card>
        </motion.div>
      </div>

      {/* Continue Button */}
      <div className="fixed bottom-0 left-0 right-0 p-6 bg-gradient-to-t from-background via-background to-transparent">
        <Button
          onClick={handleContinue}
          disabled={!selectedLevel}
          className={`w-full h-14 rounded-2xl text-white shadow-lg transition-all duration-300 ${
            selectedLevel
              ? 'bg-gradient-to-r from-[#7B2CBF] to-[#CE1126] hover:shadow-xl'
              : 'bg-muted text-muted-foreground cursor-not-allowed'
          }`}
          size="lg"
        >
          Continue
          <ChevronRight className="ml-2 w-5 h-5" />
        </Button>
      </div>
    </div>
  );
}
