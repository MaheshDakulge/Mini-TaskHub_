# 📱 Mini TaskHub

A beautifully animated personal task tracking app built with **Flutter** and **Supabase**, following clean layered architecture. Manage your daily tasks with priority levels, smart filters, offline support and smooth UI transitions.

---

## ✨ Key Features

| Feature | Description |
|---|---|
| 🔐 **Authentication** | Email & password login with persistent Supabase sessions |
| ✅ **Task Management** | Create, update, complete & swipe-to-delete tasks |
| 🎯 **Priority Levels** | High / Medium / Low priority per task |
| 🔍 **Smart Filters** | Filter by All, Pending, or Completed |
| 🌙 **Dark Mode** | Adaptive light/dark theme via `adaptive_theme` |
| 📶 **Offline Support** | Local caching via `SharedPreferences` with connectivity banner |
| 🎨 **Animations** | Fade transitions, scale animations, smooth bottom sheets |

---

## 🚀 Setup Instructions

### Prerequisites

Make sure you have the following installed:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `>=3.0.0`
- [Dart SDK](https://dart.dev/get-dart) (bundled with Flutter)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/) with Flutter + Dart extensions
- A [Supabase](https://supabase.com) account (free tier works)
- Android device or emulator (API level 21+)

### Step 1 — Clone the Repository

```bash
git clone <your-repository-url>
cd mini_taskhub_app
```

### Step 2 — Install Dependencies

```bash
flutter pub get
```

### Step 3 — Configure Supabase Credentials

Open `lib/main.dart` and locate the `Supabase.initialize()` call. Replace the placeholder values with your own project credentials (see Supabase Setup section below):

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_PROJECT_URL',       // e.g. https://xxxx.supabase.co
  anonKey: 'YOUR_SUPABASE_ANON_KEY',      // From Project Settings > API
);
```

### Step 4 — Run the App

Connect a physical Android device (with USB debugging on) or start an emulator, then:

```bash
flutter run
```

### Step 5 — Build Release APK

```bash
flutter build apk
```

The APK will be at:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 🗄️ Supabase Setup Guide

### 1. Create a Supabase Project

1. Go to [https://supabase.com](https://supabase.com) and sign in
2. Click **"New Project"**, choose a name, password, and region
3. Wait for the project to be provisioned (~1–2 minutes)

### 2. Enable Email Authentication

1. In your project dashboard, go to **Authentication → Providers**
2. Ensure **Email** is enabled (it is by default)
3. Optionally disable "Confirm email" for easier testing during development

### 3. Create the Tasks Table

Go to **SQL Editor** in your Supabase project and run the following SQL:

```sql
-- Create Tasks Table
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    is_completed BOOLEAN DEFAULT FALSE,
    priority TEXT DEFAULT 'medium',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Enable Row Level Security (RLS)
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Policies: Users can only access their own data
CREATE POLICY "Users can view own tasks"
  ON tasks FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own tasks"
  ON tasks FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own tasks"
  ON tasks FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own tasks"
  ON tasks FOR DELETE USING (auth.uid() = user_id);
```

### 4. Get Your API Keys

1. Go to **Project Settings → API**
2. Copy the **Project URL** → paste as `url` in `main.dart`
3. Copy the **anon / public** key → paste as `anonKey` in `main.dart`

> ⚠️ Never commit your real `anonKey` to a public repository. Use environment variables or a `.env` file for production apps.

---

## 🔥 Hot Reload vs Hot Restart

One of Flutter's most powerful developer features is the ability to see changes instantly without a full rebuild.

### Hot Reload (`r` in terminal / `Ctrl+S` in IDE)

- **What it does**: Injects the updated Dart source code directly into the running Dart VM **without resetting app state**.
- **What is preserved**: Current navigation stack, filled form fields, scroll position, in-memory data.
- **What triggers it**: Changes to widget `build()` methods, UI styling, layout adjustments.
- **Limitations**: Does NOT pick up changes to `main()`, `initState()`, global variables, or added packages.

**Example use case**: You changed a button color from blue to red — Hot Reload shows it instantly while you stay on the same screen.

### Hot Restart (`R` in terminal / `Ctrl+Shift+\` in IDE)

- **What it does**: Fully restarts the Dart VM and rebuilds the entire widget tree from scratch. **All app state is reset**.
- **What is preserved**: Nothing in memory — the app starts fresh from `main()`.
- **What triggers it**: Changes to `main()`, adding new providers, modifying global state initialization, adding/removing packages.
- **Speed**: Still faster than a full compile — no need to reinstall the APK.

**Example use case**: You added a new `Provider` in `main()` — only Hot Restart will pick this up since `main()` needs to re-execute.

### Quick Reference

| | Hot Reload 🔥 | Hot Restart ♻️ |
|---|---|---|
| **Shortcut** | `r` / `Ctrl+S` | `R` / `Ctrl+Shift+\` |
| **Speed** | Fastest (~ms) | Fast (~seconds) |
| **State reset?** | ❌ No | ✅ Yes |
| **Picks up `main()` changes?** | ❌ No | ✅ Yes |
| **Best for** | UI tweaks, styling | Logic changes, new packages |

---

## 📂 Architecture & Folder Structure

```
lib/
├── main.dart                        # App entry point & Supabase init
├── app/
│   ├── theme.dart                   # Material 3 color schemes & typography
│   ├── router.dart                  # GoRouter config & auth guards
│   └── transitions.dart             # Custom page transition animations
├── auth/
│   ├── login_screen.dart            # Login UI + form validation
│   ├── signup_screen.dart           # Registration UI
│   ├── splash_screen.dart           # Session check loader
│   └── auth_service.dart            # Supabase auth interactions
├── dashboard/
│   ├── dashboard_screen.dart        # Main task list screen
│   ├── task_tile.dart               # Animated swipeable task item
│   ├── task_model.dart              # Data class & JSON serializers
│   └── add_task_sheet.dart          # Bottom sheet for creating tasks
├── providers/
│   ├── auth_provider.dart           # Global auth state (Provider)
│   └── task_provider.dart           # Task list state + CRUD
├── services/
│   ├── supabase_service.dart        # Centralized Supabase client
│   ├── connectivity_service.dart    # Network status monitoring
│   └── local_storage_service.dart   # SharedPreferences caching
└── utils/
    ├── validators.dart              # Shared form validation logic
    └── connectivity_banner.dart     # Offline warning widget
```

---

## 🧪 Testing

The codebase includes unit tests targeting the `TaskModel` data class to ensure correct JSON serialization/deserialization.

```bash
flutter test test/task_model_test.dart
```

---

## 🏗️ Tech Stack

| Technology | Purpose |
|---|---|
| [Flutter](https://flutter.dev) | UI framework |
| [Supabase](https://supabase.com) | Backend (Auth + PostgreSQL DB) |
| [Provider](https://pub.dev/packages/provider) | State management |
| [GoRouter](https://pub.dev/packages/go_router) | Navigation & routing |
| [Google Fonts](https://pub.dev/packages/google_fonts) | Typography |
| [flutter_animate](https://pub.dev/packages/flutter_animate) | Micro-animations |
| [flutter_slidable](https://pub.dev/packages/flutter_slidable) | Swipe-to-delete |
| [adaptive_theme](https://pub.dev/packages/adaptive_theme) | Light/Dark mode |
| [shared_preferences](https://pub.dev/packages/shared_preferences) | Local caching |
| [connectivity_plus](https://pub.dev/packages/connectivity_plus) | Network status |
