import { useState } from 'react';
import { motion } from 'motion/react';
import { Button } from './ui/button';
import { Card } from './ui/card';
import { Badge } from './ui/badge';
import { Input } from './ui/input';
import { ArrowLeft, Search, Check, ChevronRight } from 'lucide-react';

interface Language {
  id: string;
  name: string;
  nativeName: string;
  flag: string;
  speakers: string;
  difficulty: 'Beginner' | 'Intermediate' | 'Advanced';
  region: string;
}

const languages: Language[] = [
  {
    id: 'swahili',
    name: 'Swahili',
    nativeName: 'Kiswahili',
    flag: '🇰🇪',
    speakers: '200M+',
    difficulty: 'Beginner',
    region: 'East Africa',
  },
  {
    id: 'yoruba',
    name: 'Yoruba',
    nativeName: 'Èdè Yorùbá',
    flag: '🇳🇬',
    speakers: '45M+',
    difficulty: 'Intermediate',
    region: 'West Africa',
  },
  {
    id: 'zulu',
    name: 'Zulu',
    nativeName: 'isiZulu',
    flag: '🇿🇦',
    speakers: '27M+',
    difficulty: 'Intermediate',
    region: 'Southern Africa',
  },
  {
    id: 'amharic',
    name: 'Amharic',
    nativeName: 'አማርኛ',
    flag: '🇪🇹',
    speakers: '57M+',
    difficulty: 'Advanced',
    region: 'East Africa',
  },
  {
    id: 'hausa',
    name: 'Hausa',
    nativeName: 'Harshen Hausa',
    flag: '🇳🇬',
    speakers: '77M+',
    difficulty: 'Beginner',
    region: 'West Africa',
  },
  {
    id: 'igbo',
    name: 'Igbo',
    nativeName: 'Asụsụ Igbo',
    flag: '🇳🇬',
    speakers: '44M+',
    difficulty: 'Intermediate',
    region: 'West Africa',
  },
  {
    id: 'oromo',
    name: 'Oromo',
    nativeName: 'Afaan Oromoo',
    flag: '🇪🇹',
    speakers: '37M+',
    difficulty: 'Intermediate',
    region: 'East Africa',
  },
  {
    id: 'shona',
    name: 'Shona',
    nativeName: 'chiShona',
    flag: '🇿🇼',
    speakers: '14M+',
    difficulty: 'Beginner',
    region: 'Southern Africa',
  },
  {
    id: 'somali',
    name: 'Somali',
    nativeName: 'Af-Soomaali',
    flag: '🇸🇴',
    speakers: '21M+',
    difficulty: 'Intermediate',
    region: 'East Africa',
  },
  {
    id: 'xhosa',
    name: 'Xhosa',
    nativeName: 'isiXhosa',
    flag: '🇿🇦',
    speakers: '19M+',
    difficulty: 'Advanced',
    region: 'Southern Africa',
  },
  {
    id: 'tigrinya',
    name: 'Tigrinya',
    nativeName: 'ትግርኛ',
    flag: '🇪🇷',
    speakers: '9M+',
    difficulty: 'Advanced',
    region: 'East Africa',
  },
  {
    id: 'akan',
    name: 'Akan',
    nativeName: 'Akan',
    flag: '🇬🇭',
    speakers: '11M+',
    difficulty: 'Beginner',
    region: 'West Africa',
  },
];

const difficultyColors = {
  Beginner: 'bg-[#007A3D]/10 text-[#007A3D]',
  Intermediate: 'bg-[#FCD116]/20 text-[#8B4513]',
  Advanced: 'bg-[#CE1126]/10 text-[#CE1126]',
};

interface LanguageSelectionProps {
  onSelect: (language: Language) => void;
  onBack?: () => void;
}

export default function LanguageSelection({ onSelect, onBack }: LanguageSelectionProps) {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedLanguage, setSelectedLanguage] = useState<Language | null>(null);

  const filteredLanguages = languages.filter(
    (lang) =>
      lang.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      lang.nativeName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      lang.region.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const handleContinue = () => {
    if (selectedLanguage) {
      onSelect(selectedLanguage);
    }
  };

  return (
    <div className="min-h-screen bg-background flex flex-col">
      {/* Header */}
      <div className="relative bg-gradient-to-br from-[#CE1126] to-[#FF6B35] px-6 pt-12 pb-8 rounded-b-[2.5rem] shadow-lg">
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
            <h1 className="text-3xl mb-2">Choose Your Language</h1>
            <p className="opacity-90">Which African language would you like to learn?</p>
          </div>
        </div>
      </div>

      {/* Search Bar */}
      <div className="px-6 -mt-6 mb-6">
        <div className="relative">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
          <Input
            type="text"
            placeholder="Search languages..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-12 h-14 rounded-2xl bg-card shadow-lg border-0"
          />
        </div>
      </div>

      {/* Languages Grid */}
      <div className="flex-1 px-6 pb-32 overflow-y-auto">
        <div className="grid grid-cols-1 gap-3">
          {filteredLanguages.map((language, index) => (
            <motion.div
              key={language.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.05 }}
            >
              <Card
                onClick={() => setSelectedLanguage(language)}
                className={`p-4 rounded-2xl cursor-pointer transition-all duration-300 border-2 ${
                  selectedLanguage?.id === language.id
                    ? 'border-primary shadow-lg scale-[1.02]'
                    : 'border-transparent shadow hover:shadow-md'
                }`}
              >
                <div className="flex items-center gap-4">
                  {/* Flag */}
                  <div className="text-4xl">{language.flag}</div>

                  {/* Language Info */}
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <h3>{language.name}</h3>
                      {selectedLanguage?.id === language.id && (
                        <div className="w-6 h-6 rounded-full bg-primary flex items-center justify-center">
                          <Check className="w-4 h-4 text-white" />
                        </div>
                      )}
                    </div>
                    <p className="text-sm text-muted-foreground mb-2">{language.nativeName}</p>
                    <div className="flex items-center gap-2 flex-wrap">
                      <Badge variant="secondary" className="text-xs">
                        {language.region}
                      </Badge>
                      <Badge className={`text-xs ${difficultyColors[language.difficulty]}`}>
                        {language.difficulty}
                      </Badge>
                      <span className="text-xs text-muted-foreground">{language.speakers} speakers</span>
                    </div>
                  </div>

                  {/* Arrow Indicator */}
                  <ChevronRight
                    className={`w-5 h-5 transition-colors ${
                      selectedLanguage?.id === language.id ? 'text-primary' : 'text-muted-foreground'
                    }`}
                  />
                </div>
              </Card>
            </motion.div>
          ))}
        </div>

        {filteredLanguages.length === 0 && (
          <div className="text-center py-12">
            <p className="text-muted-foreground">No languages found matching "{searchQuery}"</p>
          </div>
        )}
      </div>

      {/* Continue Button */}
      <div className="fixed bottom-0 left-0 right-0 p-6 bg-gradient-to-t from-background via-background to-transparent">
        <Button
          onClick={handleContinue}
          disabled={!selectedLanguage}
          className={`w-full h-14 rounded-2xl text-white shadow-lg transition-all duration-300 ${
            selectedLanguage
              ? 'bg-gradient-to-r from-[#CE1126] to-[#FF6B35] hover:shadow-xl'
              : 'bg-muted text-muted-foreground cursor-not-allowed'
          }`}
          size="lg"
        >
          Continue with {selectedLanguage?.name || 'Selected Language'}
          <ChevronRight className="ml-2 w-5 h-5" />
        </Button>
      </div>
    </div>
  );
}
