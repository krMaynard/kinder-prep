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

**Quick start:**
```bash
./scripts/setup-python.sh
```
This checks your Python version, creates a `tools/.venv` virtual environment, installs all dependencies, writes a `tools/run.sh` launcher, and opens the app. Re-run any time to repair or upgrade the environment. Pass `--no-launch` to skip auto-opening the app.

After the first run, launch with:
```bash
./tools/run.sh
```

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

### Flutter App (iPad · Android tablet)

**Location:** `apps-native/story_generator_flutter/`

**Quick start:**
```bash
./scripts/setup-flutter.sh
```
The script checks Flutter, detects whether Xcode (iPad) or Android SDK is available, adds iOS platform files on first run if Xcode is found, fetches packages, and interactively offers to run or build for your target device.

#### Requirements

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.22.0
- **iPad (recommended):** Mac with Xcode 15+ — install from the Mac App Store
- **Android tablet:** Android Studio with SDK Platform 35 and NDK installed

Check your setup:
```bash
flutter doctor
```

#### Running on iPad (recommended)

1. Connect iPad to your Mac via USB
2. Unlock iPad and tap **Trust** when prompted
3. Run the setup script and choose **i**, or:

```bash
cd apps-native/story_generator_flutter
flutter run
```

On first run the script adds the `ios/` platform files automatically (`flutter create --platforms ios .`). Flutter selects the connected iPad and hot-reloads on save.

> **First-time signing prompt:** Xcode may ask you to add your Apple ID under *Xcode → Settings → Accounts* and select a Development Team in `ios/Runner.xcodeproj`. Free Apple IDs work for personal sideloading (7-day cert, re-run `flutter run` to renew).

#### Running on Android tablet

Plug in your Android tablet with USB debugging enabled:
```bash
flutter run
```

If you see an Android SDK version error, open **Android Studio → SDK Manager** and install:
- SDK Platform **35** (or whatever Flutter's `flutter doctor` requests)
- **NDK** (latest stable)

#### Building a release APK (Android sideloading)

```bash
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
```

Transfer via USB, Google Drive, or email and tap to install. Enable **Install unknown apps** in Android Settings if prompted.

#### In-app workflow

1. **Profile** — child's name, favorite character, phonics level → **Save Profile**
2. **Story Spec** — theme, sight words, page count (4–8)
3. **API Key** — paste your Gemini key; toggle *Remember key* to store it securely (Keychain on iOS, Keystore on Android)
4. **Image Style Guide** — pick a template or write your own; save custom templates by name
5. **Generate Story** → review text, tap any page to edit
6. **Generate Images** → progress bar fills as each page is illustrated
7. **Export Story** → shares `story.json` + PNGs via the system share sheet

#### API key storage

The key is stored in the device's secure enclave via `flutter_secure_storage` — Keychain on iOS, encrypted SharedPreferences on Android. It is never written to disk in plaintext. Toggle *Remember key* off to delete it.
