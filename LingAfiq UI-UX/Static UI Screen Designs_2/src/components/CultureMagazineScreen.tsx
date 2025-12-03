import { Newspaper, Bookmark, Search, Clock } from 'lucide-react';
import { ImageWithFallback } from './figma/ImageWithFallback';

export function CultureMagazineScreen() {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#FF6B35] to-[#7B2CBF] px-6 py-12 rounded-b-[32px]">
        <button className="p-2 hover:bg-white/10 rounded-lg transition-colors mb-6">
          <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
          </svg>
        </button>
        
        <div className="text-center text-white">
          <Newspaper className="w-16 h-16 mx-auto mb-4" />
          <h1 className="mb-2">Cultural Magazines</h1>
          <p className="text-white/90">Explore African culture</p>
        </div>
      </div>

      {/* Search */}
      <div className="px-6 py-4">
        <div className="relative">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            type="text"
            placeholder="Search articles..."
            className="w-full pl-12 pr-4 py-3 rounded-xl border-2 border-gray-200 focus:border-[#FF6B35] outline-none transition-colors bg-white"
          />
        </div>
      </div>

      {/* Tabs */}
      <div className="px-6 pb-4">
        <div className="flex gap-2 overflow-x-auto">
          <button className="px-4 py-2 bg-[#FF6B35] text-white rounded-full text-sm whitespace-nowrap">
            Featured
          </button>
          <button className="px-4 py-2 bg-gray-100 text-gray-700 rounded-full text-sm whitespace-nowrap hover:bg-gray-200">
            History
          </button>
          <button className="px-4 py-2 bg-gray-100 text-gray-700 rounded-full text-sm whitespace-nowrap hover:bg-gray-200">
            Culture
          </button>
          <button className="px-4 py-2 bg-gray-100 text-gray-700 rounded-full text-sm whitespace-nowrap hover:bg-gray-200">
            Language
          </button>
          <button className="px-4 py-2 bg-gray-100 text-gray-700 rounded-full text-sm whitespace-nowrap hover:bg-gray-200">
            Music
          </button>
          <button className="px-4 py-2 bg-gray-100 text-gray-700 rounded-full text-sm whitespace-nowrap hover:bg-gray-200">
            Food
          </button>
        </div>
      </div>

      {/* Featured Article */}
      <div className="px-6 pb-6">
        <div className="bg-white rounded-3xl overflow-hidden shadow-lg">
          <div className="relative h-48">
            <ImageWithFallback
              src="https://images.unsplash.com/photo-1746189897983-ffd3a582a827?w=800"
              alt="Featured Article"
              className="w-full h-full object-cover"
            />
            <div className="absolute top-4 left-4">
              <span className="bg-[#FF6B35] text-white px-3 py-1 rounded-full text-xs">Featured</span>
            </div>
            <div className="absolute top-4 right-4">
              <button className="w-10 h-10 bg-white/90 backdrop-blur-sm rounded-full flex items-center justify-center hover:bg-white transition-colors">
                <Bookmark className="w-5 h-5 text-gray-700" />
              </button>
            </div>
          </div>
          <div className="p-6">
            <div className="flex items-center gap-2 mb-3">
              <span className="px-2 py-1 bg-[#7B2CBF]/10 text-[#7B2CBF] rounded-full text-xs">Culture</span>
              <span className="text-gray-500 text-xs flex items-center gap-1">
                <Clock className="w-3 h-3" />
                8 min read
              </span>
            </div>
            <h2 className="text-gray-900 mb-2">The Rich Tapestry of African Storytelling Traditions</h2>
            <p className="text-gray-600 text-sm mb-4">
              Discover how oral traditions have preserved history and culture across the African continent for millennia...
            </p>
            <button className="text-[#FF6B35] text-sm">Read More →</button>
          </div>
        </div>
      </div>

      {/* Article Grid */}
      <div className="px-6 pb-6">
        <h3 className="text-gray-900 mb-4">Latest Articles</h3>
        
        <div className="grid grid-cols-2 gap-4">
          {/* Article 1 */}
          <div className="bg-white rounded-2xl overflow-hidden shadow-sm">
            <div className="relative h-32">
              <ImageWithFallback
                src="https://images.unsplash.com/photo-1535940360221-641a69c43bac?w=400"
                alt="Article"
                className="w-full h-full object-cover"
              />
              <button className="absolute top-2 right-2 w-8 h-8 bg-white/90 backdrop-blur-sm rounded-full flex items-center justify-center">
                <Bookmark className="w-4 h-4 text-gray-700" />
              </button>
            </div>
            <div className="p-3">
              <span className="px-2 py-1 bg-[#007A3D]/10 text-[#007A3D] rounded-full text-xs">History</span>
              <h4 className="text-gray-900 text-sm mt-2 mb-1 line-clamp-2">
                Ancient Kingdoms of West Africa
              </h4>
              <p className="text-xs text-gray-500 flex items-center gap-1">
                <Clock className="w-3 h-3" />
                5 min read
              </p>
            </div>
          </div>

          {/* Article 2 */}
          <div className="bg-white rounded-2xl overflow-hidden shadow-sm">
            <div className="relative h-32">
              <ImageWithFallback
                src="https://images.unsplash.com/photo-1664629153222-a5a66e6c961f?w=400"
                alt="Article"
                className="w-full h-full object-cover"
              />
              <button className="absolute top-2 right-2 w-8 h-8 bg-white/90 backdrop-blur-sm rounded-full flex items-center justify-center">
                <Bookmark className="w-4 h-4 text-gray-700" />
              </button>
            </div>
            <div className="p-3">
              <span className="px-2 py-1 bg-[#FCD116]/20 text-[#FF6B35] rounded-full text-xs">Music</span>
              <h4 className="text-gray-900 text-sm mt-2 mb-1 line-clamp-2">
                The Evolution of Afrobeat
              </h4>
              <p className="text-xs text-gray-500 flex items-center gap-1">
                <Clock className="w-3 h-3" />
                6 min read
              </p>
            </div>
          </div>

          {/* Article 3 */}
          <div className="bg-white rounded-2xl overflow-hidden shadow-sm">
            <div className="relative h-32">
              <ImageWithFallback
                src="https://images.unsplash.com/photo-1763256294121-303b83e7e767?w=400"
                alt="Article"
                className="w-full h-full object-cover"
              />
              <button className="absolute top-2 right-2 w-8 h-8 bg-white/90 backdrop-blur-sm rounded-full flex items-center justify-center">
                <Bookmark className="w-4 h-4 text-gray-700" />
              </button>
            </div>
            <div className="p-3">
              <span className="px-2 py-1 bg-[#CE1126]/10 text-[#CE1126] rounded-full text-xs">Food</span>
              <h4 className="text-gray-900 text-sm mt-2 mb-1 line-clamp-2">
                Traditional Nigerian Cuisine
              </h4>
              <p className="text-xs text-gray-500 flex items-center gap-1">
                <Clock className="w-3 h-3" />
                4 min read
              </p>
            </div>
          </div>

          {/* Article 4 */}
          <div className="bg-white rounded-2xl overflow-hidden shadow-sm">
            <div className="relative h-32">
              <ImageWithFallback
                src="https://images.unsplash.com/photo-1542725752-e9f7259b3881?w=400"
                alt="Article"
                className="w-full h-full object-cover"
              />
              <button className="absolute top-2 right-2 w-8 h-8 bg-white/90 backdrop-blur-sm rounded-full flex items-center justify-center">
                <Bookmark className="w-4 h-4 text-gray-700" />
              </button>
            </div>
            <div className="p-3">
              <span className="px-2 py-1 bg-[#7B2CBF]/10 text-[#7B2CBF] rounded-full text-xs">Language</span>
              <h4 className="text-gray-900 text-sm mt-2 mb-1 line-clamp-2">
                Swahili: A Bridge Language
              </h4>
              <p className="text-xs text-gray-500 flex items-center gap-1">
                <Clock className="w-3 h-3" />
                7 min read
              </p>
            </div>
          </div>
        </div>
      </div>

      <div className="h-20" />
    </div>
  );
}
