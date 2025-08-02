# SSOT v1.0.0 - Math Genius Quantum Learning System

## System Overview
- **System**: Math Genius Quantum Learning System
- **Audience**: PreK–12 Students, Parents, and Educators
- **Mode**: Single-User, Multi-Student–to–Parent, Multi-Parent, School
- **Platform**: Android, iOS, Web, Tablet, Desktop
- **Technology**: Flutter 3.32+, Riverpod, Firebase, TFLite, AI-native architecture
- **Design**: Role-Aware, Game-Like, Educational, Accessible
- **AI Directive**: DO NOT GUESS. Always analyze the complete codebase context. Generate code only after confirming architecture compliance and dependency order.

## 🧠 CORE MODULES (Must be built first – No model/service/widget dependencies)

### core/context/
**Purpose**: Global runtime context, theme mode, auth session, device info

**AI Instruction**:
- Create a ContextService with:
  - UserContext (role, ID, current device)
  - DeviceContext (screen type, platform)
  - ThemeContext (light, dark, user-selected)
- Never access BuildContext unnecessarily to avoid rebuild loops
- Store live context in Riverpod global provider

### core/platform/
**Purpose**: Platform-aware utilities

**AI Instruction**:
- Detect: iOS, Android, Web, Desktop
- Provide PlatformService to allow:
  - Custom animations per platform
  - Native dialog styles
  - Permission handling logic (e.g. iOS push alerts)

### core/theme/
**Purpose**: Universal theme system

**AI Instruction**:
- Define slot-based ColorScheme, Typography, and ComponentThemeData
- Support: light, dark, child-friendly, girl-mode, pro-mode
- Expose gradient + opacity pickers
- Avoid any hardcoded colors in UI files
- Use SharedPreferences for persistence

### core/language/
**Purpose**: i18n / l10n

**AI Instruction**:
- Scaffold for: English, French, Spanish, Arabic
- Add locale switcher and flag/icon selector
- Use ARB/JSON and Flutter intl + context-aware fallback

### core/privacy/
**Purpose**: Account & data handling compliance

**AI Instruction**:
- Add logic for:
  - GDPR compliance
  - Deleting account + local data
  - Offline-only mode
  - Show policies by role (parent/student/school)

## 🧩 FEATURES (Each folder is fully self-contained)

### features/game/
**Purpose**: Quiz + Multiplayer Math Game

**AI Instruction**:
- Build GameModel, GameService, GameScreen, GameWidget
- Add category filters: Easy, Normal, Genius, Quantum
- Add multiplayer lobby (one device per user)
- Use WebRTC / Firebase LiveData for score sync
- Show result in leaderboard card style
- Cache assets locally — avoid runtime fetch

### features/ai_tutor_agent/
**Purpose**: Live AI Math Tutor

**AI Instruction**:
- Include:
  - TutorContextModel (grade, mood, progress)
  - AITutorService (hint engine)
  - TutorChatWidget, TutorPanelScreen
- Use TFLite locally, not remote AI for latency control
- Integrate voice (TTS + STT) but fallback to text if device unsupported

### features/family_system/
**Purpose**: Multi-student & multi-parent support

**AI Instruction**:
- One ParentAccount ➝ many StudentProfile
- Use local DB (Hive) if no Firebase, else Firestore
- Lock access to 1 device per user
- Live status (Online, In Quiz, Idle) via StreamProvider

### features/rewards/
**Purpose**: Reward & motivation engine

**AI Instruction**:
- RewardModel, RewardService, RewardShelfWidget
- Trigger stars, badges, messages
- Support real-time reward display with sound + animation
- Cache rewards locally; sync when online

### features/live_session/
**Purpose**: Parent/Teacher can host live quiz/study

**AI Instruction**:
- Parent/Teacher triggers quiz → broadcast to all children
- Use Firestore listener streams for real-time participation
- Include live leaderboard per session
- Add Firebase FCM for session alerts

### features/user_management/
**Purpose**: Auth, session, account control

**AI Instruction**:
- Firebase Auth (Email for Parent/Teacher, PIN/QR for Student)
- Store token minimally (securely in SharedPreferences)
- Lock down re-auth on multiple devices
- Add delete-account feature that wipes local + remote data

## 📦 SYSTEM-WIDE FEATURES

| Category | Instruction |
|----------|-------------|
| 📲 Device Lock | Lock full-screen study/game view; prevent app switching unless parent exits |
| 🛡️ Error Handling | All services and UI must catch + report errors gracefully |
| 🔁 No Rebuild Loops | Use ref.watch.select and const constructors |
| 📊 Analytics | Track time-on-question, error rates, improvement per topic |
| 🧠 AI Agents | AI Planner (suggest weekly plans), AI Tutor (real-time guide), AI Security (detect abuse) |
| 💬 Sharing | Via QR, deep link, share intent |
| 🔔 Notifications | FCM + local notifications: quiz starts, reward, idle, new challenge |
| 📡 Offline Support | Cache quizzes, rewards, progress locally; sync when online |
| 📍 Localization Tools | Enable testers to preview UI in all languages & RTL support |
| 🎨 Theme Selector | Switch by user: Fun Kid, Girl Magic, Genius Pro, Dark Mode |
| 🎙️ Voice Interface | Text-to-speech (TTS) and Speech-to-text (STT) for quiz and tutoring |
| 📈 Caching | Use shared_preferences, hive, isar for local sync-first logic |
| 📤 Report Export | Allow export of progress as PDF, CSV via printing package |
| 🪙 Monetization | Support AdMob + optional premium mode — disable ads for students |

## 📐 Barrel Architecture & Import Control

**AI must follow this exact rule**:
- NO global models/, services/, or widgets/ folders
- Each feature must encapsulate its own structure
- Import only what is needed (lazy import)
- Use barrel.dart in each feature folder for internal exposure
- core/ folders are import-only (never depend on features)

## ✅ FIREBASE LOW TOKEN INSTRUCTION

| Goal | Instruction |
|------|-------------|
| Avoid Excess Reads | Use .where().limit() or startAfter() in lists |
| Stream Cleanup | Always cancel StreamSubscription on dispose |
| Watch Only Needed Fields | Use select on Riverpod and .snapshots(includeMetadataChanges: false) |
| Auth Token | Use secure refresh & never poll unless triggered |

## 🧠 Final AI Instruction (Do Not Skip)

Before any code generation:
1. Verify project folder context
2. Analyze entire current dependency graph
3. Respect modularity and barrel architecture
4. Ensure code has no:
   - Syntax errors
   - Overflow
   - Linter warnings
   - Unscoped rebuilds
5. Ensure all UI adapts to breakpoints, orientation, and accessibility
6. Prefer ref.watch.select(...) and const where possible 