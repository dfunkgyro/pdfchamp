# PDFChamp - Professional PDF Editor for macOS

A modern, feature-rich PDF editor built with Flutter, featuring AI-powered assistance, cloud storage, and an intuitive user interface.

![Version](https://img.shields.io/badge/version-2.0.0-blue)
![Flutter](https://img.shields.io/badge/flutter-3.13+-blue)
![Dart](https://img.shields.io/badge/dart-3.0+-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## ✨ Features

### 🎨 Modern UI/UX
- **Three-Panel Layout** - Toggleable left sidebar, center content, and right sidebar
- **Dark/Light Themes** - Beautiful Material 3 themes with custom color schemes
- **Smooth Animations** - Professional transitions and staggered list animations
- **Keyboard Shortcuts** - Full keyboard navigation support
- **Responsive Design** - Optimized for macOS desktop

### 🤖 AI-Powered
- **AI Chat Assistant** - Powered by OpenAI GPT-4
- **PDF Summarization** - Automatic document summaries
- **Content Extraction** - Extract key information
- **Document Analysis** - Analyze structure and content
- **Question Answering** - Ask questions about your PDFs
- **Translation** - Translate PDF content to any language

### ☁️ Cloud Integration
- **Supabase Backend** - Secure cloud storage and sync
- **User Authentication** - Email/password authentication
- **Real-time Collaboration** - Live updates and sharing
- **File Storage** - Secure PDF storage with RLS policies
- **Folder Organization** - Organize PDFs in folders
- **Activity Tracking** - Track all document activities

### 📝 PDF Features
- **View PDFs** - High-quality PDF rendering
- **Edit Text** - Add and modify text in PDFs
- **Annotations** - Add comments and highlights
- **Form Filling** - Fill PDF forms
- **Page Management** - Add, remove, reorder pages
- **Export Options** - Save and export in various formats

## 🚀 Quick Start

### Prerequisites
- macOS 10.11 or later
- Flutter 3.13 or later
- Dart 3.0 or later

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/dfunkgyro/pdfchamp.git
   cd pdfchamp
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment**
   ```bash
   cp assets/.env.example assets/.env
   # Edit assets/.env with your API keys
   ```

4. **Set up Supabase** (Optional - for cloud features)
   - Create a project at [supabase.com](https://supabase.com)
   - Run the SQL migration: `supabase/migrations/001_initial_schema.sql`
   - Add your Supabase URL and keys to `.env`

5. **Set up OpenAI** (Optional - for AI features)
   - Get API key from [platform.openai.com](https://platform.openai.com)
   - Add your OpenAI key to `.env`

6. **Run the app**
   ```bash
   flutter run -d macos
   ```

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+O` | Open PDF |
| `Ctrl+S` | Save PDF |
| `Ctrl+E` | Toggle Edit Mode |
| `Ctrl+L` | Toggle Left Sidebar |
| `Ctrl+R` | Toggle Right Sidebar |
| `Ctrl+T` | Toggle Top Panel |
| `Ctrl+Shift+A` | Toggle AI Assistant |

## 📁 Project Structure

```
pdfchamp/
├── lib/
│   ├── core/
│   │   ├── config/           # App configuration
│   │   ├── error/            # Error handling
│   │   ├── exceptions/       # Custom exceptions
│   │   ├── logging/          # Logging system
│   │   ├── services/         # Services (Supabase, OpenAI)
│   │   ├── state/            # State management
│   │   └── theme/            # Theme system
│   ├── models/               # Data models
│   ├── screens/              # App screens
│   ├── services/             # Business logic
│   ├── utils/                # Utility functions
│   └── widgets/              # Reusable widgets
│       ├── ai/              # AI-related widgets
│       └── panels/          # Panel components
├── assets/
│   ├── .env                 # Environment config (gitignored)
│   ├── .env.example         # Environment template
│   ├── fonts/               # Custom fonts
│   ├── images/              # Image assets
│   └── animations/          # Animation files
├── supabase/
│   └── migrations/          # Database migrations
└── test/                    # Unit & widget tests
```

## 📚 Documentation

- **[Implementation Progress](IMPLEMENTATION_PROGRESS.md)** - Phase 1 details
- **[Phase 2 Summary](PHASE2_SUMMARY.md)** - UI/UX enhancements

## 🛠️ Tech Stack

- **Flutter** - UI framework
- **Dart** - Programming language
- **Supabase** - Backend as a Service
- **OpenAI** - AI capabilities
- **Provider** - State management
- **Material 3** - Design system

### Key Packages
- `supabase_flutter` - Supabase client
- `dart_openai` - OpenAI client
- `flutter_dotenv` - Environment variables
- `provider` - State management
- `shimmer` - Loading effects
- `lottie` - Animations
- `flutter_staggered_animations` - List animations

## 🗺️ Roadmap

### v2.1 (Next Release)
- [ ] Complete PDF viewer integration
- [ ] PDF editing tools
- [ ] Zoom controls
- [ ] Page thumbnails
- [ ] Search within PDFs

### v2.2
- [ ] Annotation tools
- [ ] Form filling
- [ ] Digital signatures
- [ ] OCR support
- [ ] Batch processing

### v3.0
- [ ] iOS/Android support
- [ ] Web version
- [ ] Collaboration features
- [ ] Templates library

## 📊 Stats

- **Lines of Code:** ~4,700
- **Components:** 40+
- **Themes:** 2 complete themes
- **Keyboard Shortcuts:** 7
- **AI Features:** 6
- **Cloud Features:** 10+

## 🔒 Security

- Row Level Security (RLS) in Supabase
- Encrypted local storage
- Secure API key management
- HTTPS only
- No sensitive data in logs

---

**Built with ❤️ using Flutter**

**Version:** 2.0.0 | **Last Updated:** 2025-12-03
