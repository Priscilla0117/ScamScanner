<div align="center">

#  ScamScanner

### AI-Powered Scam Detection for Elderly Malaysians

*Protecting Malaysia's most vulnerable from online scams  in seconds.*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Gemini AI](https://img.shields.io/badge/Gemini%202.5%20Flash-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://ai.google.dev)
[![ML Kit](https://img.shields.io/badge/ML%20Kit-34A853?style=for-the-badge&logo=google&logoColor=white)](https://developers.google.com/ml-kit)
[![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://android.com)

</div>

---

##  The Problem

> Malaysia loses **RM2.74 billion** to online scams every year. The **elderly (60+)** are the #1 target.

Seniors are bombarded with fake parcel notifications, bank impersonation calls, fake investment schemes, and love scams  primarily through **WhatsApp and SMS**.

Existing tools fail them because they are:

|  Problem | Impact |
|---|---|
| English-only | Malay-speaking seniors cannot understand warnings |
| Too technical | Confusing UI drives elderly users away |
| Reactive | Damage is done before detection |
| Isolated | No way to alert family members |

**ScamScanner changes all of that.**

---

##  Features

###  Bilingual AI Analysis  English + Bahasa Malaysia
Every scan result is delivered in **both languages simultaneously**, powered by **Google Gemini 2.5 Flash**. Elderly users who are more comfortable in BM get full clarity  not just a translated summary.

###  Scam Type Classification
Gemini identifies the **exact scam category**, not just the risk level:

> `Parcel Scam`  `Bank Scam`  `Love Scam`  `Investment Fraud`  `Job Scam`  `Unknown`

###  3 Input Methods  For Every User
| Method | How it works |
|---|---|
|  **Paste Text** | Copy-paste a suspicious message or link |
|  **Screenshot OCR** | Upload a screenshot  on-device ML Kit reads the text |
|  **Voice Input** | Speak the message  ideal for elderly non-typists |

###  Text-to-Speech Readback
Results are **read aloud automatically** so users with poor eyesight never miss a warning.

###  Malaysian Emergency Hotlines  Tap to Call
Shown instantly for **High** and **Medium** risk results:

|  Agency |  Number |
|---|---|
|  PDRM (Police) | **999** |
|  MCMC Scam Hotline | **1-800-888-030** |
|  BNM Banking Scam | **1-300-88-5465** |

###  Family Guardian Alert
One tap sends a **pre-composed WhatsApp message** to a saved family member  including the risk level, scam type, and original text. The guardian number is saved so future alerts are instant.

###  Live Impact Counter
The home screen displays a **real-time Firestore-powered counter** showing how many scams you have detected and avoided  a motivating, demonstrable metric.

###  Full Scan History
Every scan is logged to **Cloud Firestore** and viewable in a history screen with expandable AI analysis, risk badges, timestamps, and a live stats summary.

---

##  Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| **UI Framework** | Flutter 3 (Dart) | Cross-platform mobile |
| **AI Brain** | Google Gemini 2.5 Flash | Bilingual scam analysis + classification |
| **OCR** | Google ML Kit | On-device, offline text extraction |
| **Voice** | `speech_to_text` | Voice-to-text input |
| **TTS** | `flutter_tts` | Read results aloud |
| **Auth** | Firebase Authentication | Google Sign-In |
| **Database** | Cloud Firestore | Real-time scan logs + live stats |
| **Alerts** | `url_launcher` | WhatsApp deep link + tap-to-call |
| **Local Storage** | `shared_preferences` | Save guardian phone number |

---

##  UN Sustainable Development Goals

| SDG | Contribution |
|---|---|
| ** SDG 16**  Peace, Justice & Strong Institutions | Combats financial cybercrime targeting vulnerable groups |
| ** SDG 3**  Good Health & Well-Being | Protects elderly mental and financial well-being |
| ** SDG 10**  Reduced Inequalities | Bridges the digital literacy gap with bilingual, voice-first design |

---

##  Quick Start for Judges

> 🔑 **Demo Login Credentials (for Phone OTP login):**
>
> | Field | Value |
> |---|---|
> | **Phone Number** | `+60121234567` |
> | **OTP Code** | `123456` |
>
> *(This is a Firebase test number — no real SMS is sent. Google Sign-In works with any Google account.)*

>  **Firebase is pre-configured  no account setup needed. Just clone and run.**

```bash
# 1. Clone the repository
git clone https://github.com/Priscilla0117/ScamScanner.git

# 2. Enter the Flutter project folder
cd ScamScanner/scam_scanner

# 3. Install dependencies
flutter pub get

# 4. Connect an Android device (USB debugging on), then run:
flutter run
```

>  `google-services.json` and `firebase_options.dart` are included in the repo.
> Sign in with any Google account  no Firebase project setup required.

---

##  Project Structure

```
ScamScanner/
 scam_scanner/               Flutter project root
     android/app/
        google-services.json   # Firebase Android config (included)
     lib/
        main.dart              # App entry + Firebase init
        firebase_options.dart  # Firebase config (included)
        screens/
           login_screen.dart          # Google Sign-In
           home_screen.dart           # Dashboard + live impact counter
           text_input_screen.dart     # Paste/type suspicious text
           image_input_screen.dart    # Screenshot  OCR  Gemini
           voice_input_screen.dart    # Voice input  Gemini
           result_screen.dart         # Risk result + hotlines + family alert
           history_screen.dart        # Full scan history (Firestore stream)
        services/
            gemini_service.dart        # Gemini AI + bilingual prompt + scam type
            firebase_service.dart      # Firestore logging + auth + live streams
            ocr_service.dart           # ML Kit text recognition
            tts_service.dart           # Text-to-speech
     pubspec.yaml
```

---

##  Firestore Security Rules

For the history and impact counter to work, set these rules in **Firebase Console  Firestore  Rules**:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /scam_logs/{docId} {
      allow read: if request.auth != null
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



</div>
