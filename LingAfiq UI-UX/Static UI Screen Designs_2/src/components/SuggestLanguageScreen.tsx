import { Send, Globe } from 'lucide-react';

export function SuggestLanguageScreen() {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#FF6B35] to-[#FCD116] px-6 py-12 rounded-b-[32px]">
        <button className="p-2 hover:bg-white/10 rounded-lg transition-colors mb-6">
          <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
          </svg>
        </button>
        
        <div className="text-center text-white">
          <Globe className="w-16 h-16 mx-auto mb-4" />
          <h1 className="mb-2">Suggest a Language</h1>
          <p className="text-white/90">Help us expand our language library</p>
        </div>
      </div>

      <div className="px-6 py-8">
        {/* Info Card */}
        <div className="bg-gradient-to-br from-[#FF6B35]/10 to-[#FCD116]/10 border-l-4 border-[#FF6B35] p-4 rounded-r-xl mb-6">
          <div className="flex gap-3">
            <div className="text-2xl">💡</div>
            <div>
              <p className="text-sm text-gray-700">
                Don't see your language? Let us know! We're always looking to add more African languages to our platform.
              </p>
            </div>
          </div>
        </div>

        {/* Form */}
        <div className="space-y-6">
          {/* Language Name */}
          <div>
            <label className="block text-gray-700 mb-2">Language Name *</label>
            <input
              type="text"
              placeholder="e.g., Wolof, Tigrinya, Bemba"
              className="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-[#FF6B35] outline-none transition-colors bg-white"
            />
          </div>

          {/* Country/Region */}
          <div>
            <label className="block text-gray-700 mb-2">Country/Region *</label>
            <input
              type="text"
              placeholder="Where is this language spoken?"
              className="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-[#FF6B35] outline-none transition-colors bg-white"
            />
          </div>

          {/* Number of Speakers */}
          <div>
            <label className="block text-gray-700 mb-2">Number of Speakers (Optional)</label>
            <input
              type="text"
              placeholder="Approximate number of native speakers"
              className="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-[#FF6B35] outline-none transition-colors bg-white"
            />
          </div>

          {/* Why This Language */}
          <div>
            <label className="block text-gray-700 mb-2">Why do you want this language? *</label>
            <textarea
              rows={5}
              placeholder="Tell us why this language is important to you and why others might want to learn it..."
              className="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-[#FF6B35] outline-none transition-colors bg-white resize-none"
            />
            <p className="text-xs text-gray-500 mt-1 text-right">0 / 500 characters</p>
          </div>

          {/* Your Email (Optional) */}
          <div>
            <label className="block text-gray-700 mb-2">Your Email (Optional)</label>
            <input
              type="email"
              placeholder="We'll notify you when we add this language"
              className="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-[#FF6B35] outline-none transition-colors bg-white"
            />
          </div>
        </div>

        {/* Submit Button */}
        <button className="w-full mt-8 bg-gradient-to-r from-[#FF6B35] to-[#FCD116] text-white py-4 rounded-2xl shadow-lg hover:shadow-xl transition-all flex items-center justify-center gap-2">
          <Send className="w-5 h-5" />
          <span>Submit Suggestion</span>
        </button>

        {/* Most Requested */}
        <div className="mt-8 bg-white rounded-3xl p-6 shadow-sm">
          <h3 className="text-gray-900 mb-4">Most Requested Languages</h3>
          
          <div className="space-y-3">
            <div className="flex items-center justify-between p-3 bg-gray-50 rounded-xl">
              <div className="flex items-center gap-3">
                <span className="text-xl">🇸🇳</span>
                <span className="text-gray-900">Wolof</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="bg-[#FF6B35]/10 text-[#FF6B35] px-3 py-1 rounded-full text-xs">
                  245 requests
                </div>
              </div>
            </div>

            <div className="flex items-center justify-between p-3 bg-gray-50 rounded-xl">
              <div className="flex items-center gap-3">
                <span className="text-xl">🇪🇷</span>
                <span className="text-gray-900">Tigrinya</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="bg-[#FF6B35]/10 text-[#FF6B35] px-3 py-1 rounded-full text-xs">
                  189 requests
                </div>
              </div>
            </div>

            <div className="flex items-center justify-between p-3 bg-gray-50 rounded-xl">
              <div className="flex items-center gap-3">
                <span className="text-xl">🇿🇲</span>
                <span className="text-gray-900">Bemba</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="bg-[#FF6B35]/10 text-[#FF6B35] px-3 py-1 rounded-full text-xs">
                  156 requests
                </div>
              </div>
            </div>
          </div>

          <button className="w-full mt-4 text-[#FF6B35] text-sm hover:underline">
            View all requested languages
          </button>
        </div>
      </div>

      <div className="h-20" />
    </div>
  );
}
