# Decked 🎴

A premium iOS app for Pokémon TCG collectors. Scan, identify, organize, and showcase your card collection.

![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

### 📸 Smart Card Scanner
- Continuous scanning using device camera
- On-device OCR processing (Vision framework)
- Multi-language support (EN, ES, JP)
- Real-time card detection with visual feedback

### 🔍 Card Identification
- Automatic card number detection (e.g., "123/198")
- Rarity recognition (Common to Secret Rare)
- Name inference using smart heuristics
- Match confidence scoring

### 📚 Collection Management
- Track your entire card collection
- Record condition, language, and foil status
- Price tracking (paid vs. market value)
- Search and filter capabilities

### 📁 Digital Binders
- Create custom binders for organization
- Beautiful album-style grid display
- Public/private binder options
- Ready for future sharing features

## Architecture

```
Decked/
├── App/
│   ├── DeckedApp.swift
│   └── MainTabView.swift
├── Features/
│   ├── Scanner/
│   │   ├── ScannerView.swift
│   │   └── ScannerViewModel.swift
│   ├── Identification/
│   │   └── ResultsListView.swift
│   ├── Collection/
│   │   ├── CollectionView.swift
│   │   ├── CollectionViewModel.swift
│   │   ├── AddToCollectionView.swift
│   │   └── AddToCollectionViewModel.swift
│   └── Binders/
│       ├── BindersView.swift
│       └── BindersViewModel.swift
├── Services/
│   ├── Camera/
│   │   └── CameraService.swift
│   ├── OCR/
│   │   └── OCRService.swift
│   ├── Parsing/
│   │   └── CardTextParser.swift
│   └── API/
│       └── CardAPIClient.swift
├── Models/
│   ├── Card.swift
│   └── ParsedCardHint.swift
└── Shared/
    ├── Theme/
    │   └── Theme.swift
    └── UI/
        └── Components/
            ├── CardImageView.swift
            ├── LoadingView.swift
            └── EmptyStateView.swift
```

## Tech Stack

- **UI**: SwiftUI (iOS 17+)
- **Architecture**: MVVM with async/await
- **Camera**: AVFoundation
- **OCR**: Vision framework (VNRecognizeTextRequest)
- **Storage**: UserDefaults (MVP), prepared for Core Data + CloudKit
- **API**: Mock data, designed for Pokémon TCG API v2

## Design System

### Colors
- **Background**: `#0F172A` (Carbon/Dark Blue)
- **Surface**: `#1E293B`
- **Accent**: `#38BDF8` (Electric Cyan)
- **Text Primary**: `#F1F5F9`
- **Text Secondary**: `#94A3B8`

### Rarity Colors
- Common: `#94A3B8`
- Uncommon: `#4ADE80`
- Rare: `#60A5FA`
- Holo: `#A78BFA`
- Ultra Rare: `#F472B6`
- Secret Rare: `#F97316`
- Special Art: `#FBBF24`

## Getting Started

### Requirements
- Xcode 15+
- iOS 17+
- Physical device (camera required for scanning)

### Setup
1. Clone the repository
2. Open `Decked.xcodeproj` in Xcode
3. Select your development team
4. Build and run on a physical device

## Permissions

The app requires camera access for card scanning:
```xml
<key>NSCameraUsageDescription</key>
<string>Decked needs camera access to scan and identify your Pokémon cards.</string>
```

## Roadmap

- [ ] Real Pokémon TCG API v2 integration
- [ ] Core Data persistence
- [ ] CloudKit sync
- [ ] Binder sharing & showcase
- [ ] Price alerts
- [ ] Collection statistics & insights
- [ ] Deck building tools
- [ ] Trade tracking

## API

This app is designed to use the [Pokémon TCG API](https://pokemontcg.io/). Currently using mock data for development.

## Disclaimer

Pokémon and Pokémon character names are trademarks of Nintendo. This app is not affiliated with, endorsed, sponsored, or approved by Nintendo, The Pokémon Company, or any of their subsidiaries.

## License

MIT License - see LICENSE file for details.
