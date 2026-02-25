#  ScamScanner  AI Scam Detection for Elderly Malaysians

> **Protecting Malaysia's most vulnerable from online scams with the power of Gemini AI.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth-orange?logo=firebase)](https://firebase.google.com)
[![Gemini AI](https://img.shields.io/badge/Google-Gemini%202.5%20Flash-4285F4?logo=google)](https://ai.google.dev)
[![ML Kit](https://img.shields.io/badge/ML%20Kit-Text%20Recognition-34A853?logo=google)](https://developers.google.com/ml-kit)
[![Platform](https://img.shields.io/badge/Platform-Android-green?logo=android)](https://android.com)

---

##  The Problem

Malaysia loses **RM2.74 billion** to online scams annually. The **elderly (60+)** are the primary victims  targeted by Parcel Scams, Bank Impersonation, Love Scams, and Investment Fraud via WhatsApp and SMS.

Most existing tools are:
-  English-only  inaccessible to Malay-speaking seniors
-  Reactive  no real-time protection
-  Complex  not designed for non-tech users
-  Isolated  no family support loop

> **ScamScanner solves all of this  in seconds.**

---

##  Key Features

###  Bilingual AI Analysis (English + Bahasa Malaysia)
Powered by **Google Gemini 2.5 Flash**, ScamScanner analyses suspicious messages and responds in both **English and Bahasa Malaysia**  ensuring elderly users who are more comfortable in BM can understand the risk immediately.

###  Scam Type Classification
Not just "it's a scam"  Gemini identifies the **exact scam category**:

`Parcel Scam`  `Bank Scam`  `Love Scam`  `Investment Fraud`  `Job Scam`

###  3 Flexible Scan Methods
| Input Method | Description |
|---|---|
|  **Paste Text** | Copy-paste suspicious messages, links, or descriptions |
|  **Screenshot OCR** | Upload a screenshot  on-device ML Kit extracts the text |
|  **Voice Input** | Describe the scam by voice  ideal for elderly users |

###  Text-to-Speech Readback
Results are read aloud automatically  no need to read small text.

###  Malaysian Emergency Hotlines (Tap-to-Call)
Shown automatically on High & Medium risk results:

| Agency | Number |
|---|---|
|  PDRM (Police) | 999 |
|  MCMC Scam Report | 1-800-888-030 |
|  BNM Banking Scam | 1-300-88-5465 |

###  Family Guardian Alert
One tap sends a **pre-composed WhatsApp alert** to a designated family member  including the scam type, risk level, and original message. Family members stay in the loop instantly, with the guardian's number saved for future alerts.

###  Live Impact Counter (Home Screen)
A real-time Firestore-powered counter on the home screen shows scams detected and users protected  demonstrating measurable, live impact.

###  Scan History
Full history of past scans with expandable AI analysis, risk badges, timestamps, and a stats summary (High / Medium / Safe).

---

##  Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | Flutter 3 (Dart)  cross-platform mobile |
| **AI Analysis** | Google Gemini 2.5 Flash API |
| **OCR** | Google ML Kit Text Recognition (on-device, offline) |
| **Voice Input** | speech_to_text package |
| **Text-to-Speech** | lutter_tts package |
| **Authentication** | Firebase Authentication (Google Sign-In) |
| **Database & Logging** | Cloud Firestore (real-time scan logs + stats) |
| **Deep Linking** | url_launcher (WhatsApp alerts + tap-to-call) |
| **Local Storage** | shared_preferences (guardian phone number) |

---

##  UN SDG Alignment

| SDG | How ScamScanner Contributes |
|---|---|
| **SDG 16**  Peace, Justice & Strong Institutions | Actively reduces financial cybercrime targeting vulnerable populations |
| **SDG 3**  Good Health & Well-Being | Protects elderly mental and financial well-being from scam trauma |
| **SDG 10**  Reduced Inequalities | Bridges digital literacy gap with bilingual, voice-first UX |

---

##  Quick Start (for Judges)

Firebase is pre-configured  no setup needed. Just clone and run:

`ash
# 1. Clone the repo
git clone https://github.com/Priscilla0117/ScamScanner.git
cd ScamScanner/scam_scanner

# 2. Install dependencies
flutter pub get

# 3. Connect an Android device (or start emulator), then:
flutter run
`

>  google-services.json and irebase_options.dart are included in the repo.
> Judges log in with their own Google account via Firebase Auth.

### Firestore Security Rules
In your **Firebase Console  Firestore  Rules**, ensure you have:
`javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /scam_logs/{docId} {
      allow read: if request.auth != null && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
    }
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
`

---

##  Project Structure

`
scam_scanner/
 android/
    app/
        google-services.json       # Firebase Android config
        build.gradle.kts
 lib/
    main.dart                      # App entry + Firebase init
    firebase_options.dart          # Firebase multi-platform config
    screens/
       login_screen.dart          # Google Sign-In
       home_screen.dart           # Dashboard + live impact counter
       text_input_screen.dart     # Paste/type suspicious text
       image_input_screen.dart    # Screenshot  OCR  scan
       voice_input_screen.dart    # Voice-based input
       result_screen.dart         # AI result + hotlines + family alert
       history_screen.dart        # Scan history (Firestore stream)
    services/
        gemini_service.dart        # Gemini AI (bilingual prompt + scam type)
        firebase_service.dart      # Firestore logging, auth, streams
        ocr_service.dart           # ML Kit text recognition
        tts_service.dart           # Text-to-speech readback
 pubspec.yaml
`

---

##  Team

Built with  for the hackathon  protecting Malaysian families, one scan at a time.

---

##  License

MIT License  feel free to use, adapt, and build upon this project to protect more communities.
