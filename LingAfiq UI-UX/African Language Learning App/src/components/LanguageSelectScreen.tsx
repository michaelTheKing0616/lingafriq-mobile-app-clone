import { motion } from 'motion/react';
import { ChevronLeft, Search, CheckCircle2 } from 'lucide-react';
import { useState } from 'react';
import { africanLanguages } from '../lib/mock-data';

interface LanguageSelectScreenProps {
  onSelect: (languageId: string) => void;
  onBack: () => void;
}

export default function LanguageSelectScreen({ onSelect, onBack }: LanguageSelectScreenProps) {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedLanguage, setSelectedLanguage] = useState<string | null>(null);

  const filteredLanguages = africanLanguages.filter(lang =>
    lang.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    lang.nativeName.toLowerCase().includes(searchQuery.toLowerCase()) ||
    lang.region.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const handleSelect = (languageId: string) => {
    setSelectedLanguage(languageId);
    setTimeout(() => onSelect(languageId), 300);
  };

  return (
    <div className="w-full min-h-screen bg-gray-50 flex flex-col">
      {/* Header */}
      <div className="bg-gradient-to-r from-red-500 via-yellow-500 to-green-500 p-6 pb-8">
        <div className="flex items-center gap-4 mb-6">
          <button
            onClick={onBack}
            className="w-10 h-10 rounded-xl bg-white/20 backdrop-blur-sm flex items-center justify-center text-white"
          >
            <ChevronLeft className="w-5 h-5" />
          </button>
          <h1 className="text-white flex-1">Select Language</h1>
        </div>

        {/* Search Bar */}
        <div className="relative">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search languages..."
            className="w-full pl-12 pr-4 py-3 rounded-2xl border-none focus:outline-none focus:ring-2 focus:ring-white/50"
          />
        </div>
      </div>

      {/* Languages List */}
      <div className="flex-1 p-6 overflow-y-auto">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="space-y-3"
        >
          {filteredLanguages.map((language, index) => (
            <motion.button
              key={language.id}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: index * 0.05 }}
              onClick={() => handleSelect(language.id)}
              className={`w-full bg-white rounded-2xl p-4 shadow-sm border-2 transition-all hover:shadow-md ${
                selectedLanguage === language.id
                  ? 'border-green-500 bg-green-50'
                  : 'border-gray-100'
              }`}
            >
              <div className="flex items-center gap-4">
                {/* Flag */}
                <div className="w-14 h-14 rounded-xl bg-gradient-to-br from-gray-100 to-gray-200 flex items-center justify-center text-3xl">
                  {language.flag}
                </div>

                {/* Language Info */}
                <div className="flex-1 text-left">
                  <div className="flex items-center gap-2 mb-1">
                    <h3 className="text-gray-900">{language.name}</h3>
                    {selectedLanguage === language.id && (
                      <CheckCircle2 className="w-5 h-5 text-green-600" />
                    )}
                  </div>
                  <p className="text-sm text-gray-600 mb-1">{language.nativeName}</p>
                  <div className="flex items-center gap-3 text-xs text-gray-500">
                    <span>{language.region}</span>
                    <span>•</span>
                    <span>{language.speakers} speakers</span>
                  </div>
                </div>

                {/* Difficulty Badge */}
                <div>
                  <span className={`px-3 py-1 rounded-full text-xs ${
                    language.difficulty === 'beginner'
                      ? 'bg-green-100 text-green-700'
                      : language.difficulty === 'intermediate'
                      ? 'bg-yellow-100 text-yellow-700'
                      : 'bg-red-100 text-red-700'
                  }`}>
                    {language.difficulty}
                  </span>
                </div>
              </div>
            </motion.button>
          ))}
        </motion.div>

        {filteredLanguages.length === 0 && (
          <div className="text-center py-12">
            <p className="text-gray-500">No languages found</p>
          </div>
        )}
      </div>
    </div>
  );
}
