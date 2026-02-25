# 🛡️ ScamScanner — AI Scam Detection for Elderly Malaysians

> **Protecting Malaysia's most vulnerable from online scams with the power of Gemini AI.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth-orange?logo=firebase)](https://firebase.google.com)
[![Gemini AI](https://img.shields.io/badge/Google-Gemini%202.5%20Flash-4285F4?logo=google)](https://ai.google.dev)
[![ML Kit](https://img.shields.io/badge/ML%20Kit-Text%20Recognition-34A853?logo=google)](https://developers.google.com/ml-kit)
[![Platform](https://img.shields.io/badge/Platform-Android-green?logo=android)](https://android.com)

---

## 🚨 The Problem

Malaysia loses **RM2.74 billion** to online scams annually. The **elderly (60+)** are the primary victims — they are targeted by Parcel Scams, Bank Impersonation, Love Scams, and Investment Fraud via WhatsApp and SMS.

Most scam detection tools are:
- ❌ English-only — inaccessible to Malay-speaking seniors
- ❌ Reactive — no real-time protection
- ❌ Complex — not designed for non-tech users
- ❌ Isolated — no family support loop

> **ScamScanner solves all of this — in seconds.**

---

## ✨ Key Features

### 🤖 Bilingual AI Analysis (EN + BM)
Powered by **Google Gemini 2.5 Flash**, ScamScanner analyzes suspicious messages and responds in both **English and Bahasa Malaysia** — ensuring elderly users who are more comfortable in BM can understand the risk immediately.

### 🔍 Scam Type Classification
Gemini doesn't just say "it's a scam" — it identifies the **exact type**:
`Parcel Scam` · `Bank Scam` · `Love Scam` · `Investment Fraud` · `Job Scam`

### 📸 3 Ways to Scan
| Method | Description |
|---|---|
| 📋 **Paste Text** | Copy-paste suspicious messages or links |
| 🖼️ **Screenshot OCR** | Upload a screenshot — ML Kit extracts the text |
| 🎤 **Voice Input** | Describe the scam by voice — ideal for elderly users |

### 📞 Malaysian Emergency Hotlines (Tap-to-Call)
Shown automatically on High & Medium risk results:
| Agency | Number |
|---|---|
| 🚔 PDRM (Police) | 999 |
| 📡 MCMC Scam Report | 1-800-888-030 |
| 🏦 BNM Banking Scam | 1-300-88-5465 |

### 👨‍👩‍👧 Family Guardian Alert
One tap sends a **pre-composed WhatsApp alert** to a family member, including the scam type, risk level, and original message — keeping loved ones in the loop instantly.

### 📊 Live Impact Counter
The home screen shows a real-time Firestore-powered counter of scams detected and users protected — demonstrating measurable impact.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | Flutter 3 (Dart) |
| **AI Analysis** | Google Gemini 2.5 Flash API |
| **OCR** | Google ML Kit Text Recognition (on-device) |
| **Voice Input** | `speech_to_text` package |
| **Text-to-Speech** | `flutter_tts` package |
| **Authentication** | Firebase Authentication (Google Sign-In) |
| **Database** | Cloud Firestore (real-time scan logs + stats) |
| **Deep Linking** | `url_launcher` (WhatsApp + tel: calls) |
| **Local Storage** | `shared_preferences` (guardian phone number) |

---

## 🎯 UN SDG Alignment

| SDG | How ScamScanner Contributes |
|---|---|
| **SDG 16** — Peace, Justice & Strong Institutions | Reduces financial crime targeting vulnerable populations |
| **SDG 3** — Good Health & Well-Being | Protects elderly mental and financial well-being from scam trauma |
| **SDG 10** — Reduced Inequalities | Bridges digital literacy gap with bilingual, voice-first UX |

---

## 🚀 Getting Started

### Prerequisites
- Flutter 3.x SDK
- Android device or emulator (API 21+)
- Firebase project with Firestore + Authentication enabled
- Gemini API key from [Google AI Studio](https://aistudio.google.com/app/apikey)

### Setup
```bash
# Clone the repo
git clone https://github.com/Priscilla0117/ScamScanner.git
cd ScamScanner/scam_scanner

# Install dependencies
flutter pub get
```

### Configuration (required before running)
1. Add your `google-services.json` to `android/app/`
2. Add your `lib/firebase_options.dart` (from Firebase CLI)
3. Replace the Gemini API key in `lib/services/gemini_service.dart`:
   ```dart
   static const String _apiKey = 'YOUR_GEMINI_API_KEY';
   ```

### Run
```bash
flutter run
```

### Firestore Security Rules
In **Firebase Console → Firestore → Rules**, set:
```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /scam_logs/{docId} {
      allow read, create: if request.auth != null
                         && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null
                   && request.auth.uid == request.resource.data.userId;
    }
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point + Firebase init
├── screens/
│   ├── login_screen.dart        # Google Sign-In
│   ├── home_screen.dart         # Dashboard + impact counter
│   ├── text_input_screen.dart   # Paste/type suspicious text
│   ├── image_input_screen.dart  # Screenshot OCR scanner
│   ├── voice_input_screen.dart  # Voice-based input
│   ├── result_screen.dart       # AI result + hotlines + family alert
│   └── history_screen.dart      # Past scan history (Firestore stream)
└── services/
    ├── gemini_service.dart      # Gemini AI analysis + bilingual prompt
    ├── firebase_service.dart    # Firestore logging + auth + streams
    ├── ocr_service.dart         # ML Kit text recognition
    └── tts_service.dart         # Text-to-speech readback
```
