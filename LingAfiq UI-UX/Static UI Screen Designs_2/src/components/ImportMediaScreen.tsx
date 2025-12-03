import { Upload, Link as LinkIcon, FileText, Image as ImageIcon } from 'lucide-react';

export function ImportMediaScreen() {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#007A3D] to-[#005A2D] px-6 py-12 rounded-b-[32px]">
        <button className="p-2 hover:bg-white/10 rounded-lg transition-colors mb-6">
          <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
          </svg>
        </button>
        
        <div className="text-center text-white">
          <Upload className="w-16 h-16 mx-auto mb-4" />
          <h1 className="mb-2">Media Import</h1>
          <p className="text-white/90">Share content with the community</p>
        </div>
      </div>

      {/* Upload Options */}
      <div className="px-6 py-8 space-y-4">
        {/* Upload File */}
        <div className="bg-white rounded-3xl p-6 shadow-sm border-2 border-dashed border-gray-300 hover:border-[#007A3D] transition-colors cursor-pointer">
          <div className="text-center">
            <div className="w-16 h-16 bg-[#007A3D]/10 rounded-full flex items-center justify-center mx-auto mb-4">
              <Upload className="w-8 h-8 text-[#007A3D]" />
            </div>
            <h3 className="text-gray-900 mb-2">Upload File</h3>
            <p className="text-sm text-gray-600 mb-4">
              Choose a file from your device
            </p>
            <button className="bg-gradient-to-r from-[#007A3D] to-[#005A2D] text-white px-6 py-3 rounded-xl hover:shadow-lg transition-all">
              Choose File
            </button>
            <p className="text-xs text-gray-500 mt-4">
              Supported: PDF, DOC, MP3, MP4, JPG, PNG (Max 50MB)
            </p>
          </div>
        </div>

        {/* Enter URL */}
        <div className="bg-white rounded-3xl p-6 shadow-sm">
          <div className="flex items-start gap-4 mb-4">
            <div className="w-12 h-12 bg-[#FF6B35]/10 rounded-xl flex items-center justify-center flex-shrink-0">
              <LinkIcon className="w-6 h-6 text-[#FF6B35]" />
            </div>
            <div className="flex-1">
              <h3 className="text-gray-900 mb-1">Import from URL</h3>
              <p className="text-sm text-gray-600">
                Paste a link to a video, article, or audio
              </p>
            </div>
          </div>
          <input
            type="url"
            placeholder="https://example.com/resource"
            className="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-[#FF6B35] outline-none transition-colors mb-3"
          />
          <button className="w-full bg-[#FF6B35] text-white py-3 rounded-xl hover:bg-[#FF5525] transition-colors">
            Import from URL
          </button>
        </div>

        {/* Paste Text */}
        <div className="bg-white rounded-3xl p-6 shadow-sm">
          <div className="flex items-start gap-4 mb-4">
            <div className="w-12 h-12 bg-[#7B2CBF]/10 rounded-xl flex items-center justify-center flex-shrink-0">
              <FileText className="w-6 h-6 text-[#7B2CBF]" />
            </div>
            <div className="flex-1">
              <h3 className="text-gray-900 mb-1">Import Text</h3>
              <p className="text-sm text-gray-600">
                Paste text content directly
              </p>
            </div>
          </div>
          <textarea
            rows={4}
            placeholder="Paste your text here..."
            className="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-[#7B2CBF] outline-none transition-colors resize-none mb-3"
          />
          <button className="w-full bg-gradient-to-r from-[#7B2CBF] to-[#9D4EDD] text-white py-3 rounded-xl hover:shadow-lg transition-all">
            Import Text
          </button>
        </div>
      </div>

      {/* Language Selector */}
      <div className="px-6 pb-6">
        <div className="bg-blue-50 border-l-4 border-blue-400 p-4 rounded-r-xl">
          <label className="block text-gray-700 mb-3">Select language for this content</label>
          <select className="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-[#007A3D] outline-none transition-colors bg-white">
            <option>🇹🇿 Swahili</option>
            <option>🇳🇬 Yoruba</option>
            <option>🇪🇹 Amharic</option>
            <option>🇿🇦 Zulu</option>
            <option>🇳🇬 Hausa</option>
            <option>🇳🇬 Igbo</option>
          </select>
        </div>
      </div>

      {/* My Imported Items */}
      <div className="px-6 pb-6">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-gray-900">Your Imported Items</h3>
          <button className="text-[#007A3D] text-sm">View All</button>
        </div>

        <div className="space-y-3">
          <div className="bg-white rounded-2xl p-4 shadow-sm flex items-center gap-4">
            <div className="w-12 h-12 bg-[#007A3D]/10 rounded-xl flex items-center justify-center">
              <ImageIcon className="w-6 h-6 text-[#007A3D]" />
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-gray-900 truncate">Swahili Proverbs Collection.pdf</p>
              <p className="text-xs text-gray-500">Uploaded 2 days ago</p>
            </div>
            <button className="text-gray-400 hover:text-gray-600">
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z" />
              </svg>
            </button>
          </div>

          <div className="bg-white rounded-2xl p-4 shadow-sm flex items-center gap-4">
            <div className="w-12 h-12 bg-[#FF6B35]/10 rounded-xl flex items-center justify-center">
              <FileText className="w-6 h-6 text-[#FF6B35]" />
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-gray-900 truncate">Yoruba Folk Tales</p>
              <p className="text-xs text-gray-500">Uploaded 1 week ago</p>
            </div>
            <button className="text-gray-400 hover:text-gray-600">
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z" />
              </svg>
            </button>
          </div>
        </div>
      </div>

      <div className="h-20" />
    </div>
  );
}
