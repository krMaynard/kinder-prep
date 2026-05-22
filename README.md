# Harker Prep Curriculum

A 6-month personalized learning project to prepare a gifted 4-year-old for admission to The Harker School by teaching foundational reading and math skills.

## Goal

By the end of 6 months, the child should be able to:

**Reading**
- Recognize all 26 uppercase and lowercase letters
- Understand letter-sound relationships (phonics)
- Blend sounds to decode simple CVC words (cat, dog, sun)
- Read simple sight words (Dolch Pre-K and Kindergarten lists)
- Read short sentences and simple books independently
- Answer basic comprehension questions about what was read

**Math**
- Count reliably to 20 (and beyond)
- Recognize and write numerals 0–10
- Understand one-to-one correspondence
- Perform simple addition and subtraction within 10
- Recognize basic shapes and patterns
- Understand basic measurement concepts (longer/shorter, heavier/lighter)

## Structure

```
/curriculum     - Week-by-week lesson plans
/apps           - Interactive learning tools and games
/assessments    - Progress tracking and milestone checks
/resources      - Reference materials, printables, and admission standards
```

## Timeline

| Month | Reading Focus | Math Focus |
|-------|--------------|------------|
| 1 | Letter recognition & sounds | Counting 1–10, number recognition |
| 2 | Phonics blending, CVC words | Numbers 11–20, patterns |
| 3 | Sight words (Pre-K list) | Addition within 5 |
| 4 | Short sentence reading | Subtraction within 5 |
| 5 | Sight words (K list), fluency | Addition & subtraction within 10 |
| 6 | Simple book reading, comprehension | Shapes, measurement, review |

## Target School

The Harker School — a rigorous independent school in the San Jose area. Kindergarten admission assesses school readiness including pre-literacy and pre-numeracy skills.

See [`resources/harker-admission-standards.md`](resources/harker-admission-standards.md) for a detailed breakdown of what the assessment evaluates.

---

## Story Generator Tools

Two versions of the personalized story generator exist: a macOS desktop app and an Android tablet app. Both call the Gemini API to produce decodable books tailored to the child's phonics level and favorite characters, then generate an illustration for each page.

You will need a **Gemini API key** from [aistudio.google.com](https://aistudio.google.com/). The free tier is sufficient for normal use.

---

### Python Desktop App (macOS)

**Location:** `tools/story_generator.py`

#### Requirements

- macOS (uses Tkinter, which ships with the system Python on macOS 12+)
- Python 3.10 or later
- The three Python packages listed in `tools/requirements.txt`

#### Setup

```bash
pip3 install -r tools/requirements.txt
```

> **Note:** If `pip3 install keyring` fails on a fresh macOS install, run `pip3 install --user -r tools/requirements.txt` or use a virtual environment.

#### Running

```bash
python3 tools/story_generator.py
```

A Tkinter window opens with four sections:

| Section | What to fill in |
|---------|----------------|
| **Profile** | Child's name, favorite characters, phonics level |
| **Story Spec** | Title, theme, target sight words, page count (4–8) |
| **API Key** | Paste your Gemini key; tick *Remember key (Keychain)* to store it in the macOS Keychain so you only enter it once |
| **Image Style Guide** | Choose a template (Watercolor / Cartoon / Colored Pencil / Pixel Art) or write your own; save custom templates by name |

**Workflow:**

1. Fill in all sections and click **Generate Text** — the story appears in the preview pane.
2. Review each page; click **Regenerate** on any page you want rewritten.
3. Click **Generate Images** — one illustration per page is created (this calls the image API and takes ~10–30 s per page).
4. Click **Save to Repo** — writes `apps/social-stories/stories/<slug>/story.json` and `page-NN.png` into the repo. Commit and push as normal.

#### API key storage

The key is stored in the **macOS Keychain** under service `harker-prep`, account `gemini-api-key`. To remove it:

```bash
python3 -c "import keyring; keyring.delete_password('harker-prep', 'gemini-api-key')"
```

---

### Flutter Android App

**Location:** `apps-native/story_generator_flutter/`

#### Requirements

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.22.0
- Android SDK with build-tools (installed automatically by Android Studio, or via `sdkmanager`)
- A physical Android device or emulator running Android 5.0+ (API 21+)
- A connected device with **USB debugging** enabled, or an AVD running in Android Studio

Verify your environment:

```bash
flutter doctor
```

All items under *Android toolchain* and *Connected device* should show a green check before proceeding.

#### Setup

```bash
cd apps-native/story_generator_flutter
flutter pub get
```

#### Running on a device (development)

Plug in your Android tablet via USB (or start an AVD), then:

```bash
flutter run
```

Flutter selects the connected device automatically. The app hot-reloads on save during development.

#### Building a release APK (sideloading)

```bash
flutter build apk --release
```

The APK is written to:

```
apps-native/story_generator_flutter/build/app/outputs/flutter-apk/app-release.apk
```

Transfer it to the device (USB, Google Drive, email, Bluetooth, etc.) and open it to install. You may need to enable **Install unknown apps** for the file manager or browser you use to open the APK.

> The release build is signed with the debug keystore (fine for personal sideloading; not suitable for Play Store submission).

#### In-app workflow

1. **Profile** — enter the child's name, favorite character, and phonics level. Tap **Save Profile**.
2. **Story Spec** — set theme, optional character override, sight words, and page count.
3. **API Key** — paste your Gemini key; toggle *Remember key (Keystore)* to save it to the Android Keystore.
4. **Image Style Guide** — pick a template or write a custom style; save templates by name.
5. Tap **Generate Story** → review text on the next screen; tap any page to edit it.
6. Tap **Generate Images** → a progress bar fills as each page is illustrated.
7. Tap **Export Story** (share icon) to share `story.json` + PNGs via the Android share sheet — save to Files, send to Drive, etc.

#### API key storage

The key is stored in the **Android Keystore** via `flutter_secure_storage` with `encryptedSharedPreferences: true`. It is never written to disk in plaintext. To clear it, toggle the *Remember key* switch off inside the app.
