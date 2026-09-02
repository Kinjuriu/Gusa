# GUSA — MVP Product & Technical Specification

**Working name:** Gusa  
**Meaning:** “Touch” / “to touch” in Swahili  
**Platform:** Android first  
**Client:** Flutter + native Kotlin  
**Backend:** No traditional backend  
**Cloud:** Small serverless API proxy for OpenAI + ElevenLabs  
**Team:** 3 developers

---

# 1. Product Vision

Gusa is a touch-first AI accessibility assistant that enables blind, deafblind, visually impaired, and other accessibility users to interact with people, apps, websites, forms, and digital services through:

- Braille
- vibration/haptics
- touch gestures
- speech
- large text
- AI assistance

The long-term goal is:

> Turn complicated visual digital interfaces into simple tactile conversations and actions.

Gusa should allow a user to perform commands such as:

- “What is on this screen?”
- “Read this.”
- “Open WhatsApp.”
- “Go back.”
- “Reply.”
- “Fill this form.”
- “Register me for this event.”
- “What information is missing?”
- “Explain this error.”
- “Repeat.”
- “Speak this for me.”

---

# 2. Core Product Principle

## Local-first accessibility. AI-enhanced intelligence.

Gusa must remain useful without AI or internet access.

The following must run directly on the Android phone:

- Braille input
- Braille decoding
- text-to-Braille conversion
- haptic output
- touch gestures
- Android accessibility service
- opening apps
- screen-tree inspection
- basic commands
- simple form recognition
- local profile
- Android text-to-speech fallback
- Android speech recognition fallback

Cloud services improve the experience but do not define it.

---

# 3. Target Users

### Primary

Deafblind users who know Braille.

### Secondary

Blind users.

### Additional accessibility users

- low-vision users
- hard-of-hearing users
- deaf users
- users with limited ability to navigate conventional interfaces

### Communication partner

A sighted/hearing person should also be able to use Gusa without knowing Braille.

---

# 4. MVP Hypothesis

The MVP should answer one central question:

> Can a user use Braille, touch and haptics to understand a phone interface and successfully complete a simple digital task?

The flagship demonstration will be:

**Event registration using a web page.**

---

# 5. MVP Core Journey

## Journey A — Human speaks to user

```text
Person speaks
      ↓
Speech-to-Text
      ↓
Optional AI simplification
      ↓
Text
      ↓
Braille Encoder
      ↓
Haptic Engine
      ↓
User feels message
```

Example:

Person:

“Would you like to attend the event tomorrow?”

AI can reduce this to:

```text
EVENT TOMORROW.
ATTEND?
```

---

# 6. User Responds Through Braille

The screen becomes a six-dot Braille input surface.

```text
1               4

2               5

3               6
```

Example:

```text
Braille taps
     ↓
YES
     ↓
Text
     ↓
ElevenLabs / Android TTS
     ↓
🔊 "Yes."
```

---

# 7. Braille Engine

Braille conversion must NOT use an LLM.

It should be deterministic.

Module:

```text
BrailleEngine
├── encode(text)
├── decode(dots)
├── validate(cell)
├── nextCharacter()
└── normalizeText()
```

Example:

```text
A → [1]
B → [1,2]
C → [1,4]
```

Initial MVP:

**English Grade 1 / uncontracted Braille.**

Contracted Braille can come later.

---

# 8. Haptic Engine

Create a dedicated local `HapticEngine`.

Responsibilities:

```text
Braille Cell
      ↓
Dot sequence
      ↓
Vibration pattern
      ↓
Character pause
      ↓
Word pause
```

Settings:

- vibration intensity
- dot duration
- character delay
- word delay
- playback speed
- repeat
- pause/resume

Example modes:

```text
Beginner
Normal
Fast
Custom
```

Do not assume the initial vibration pattern is correct.

The pattern must be user-tested.

---

# 9. Tactile Navigation

The user should be able to operate Gusa without visually navigating menus.

Initial gesture vocabulary:

```text
Double tap      Confirm
Long press      Repeat
Swipe right     Next
Swipe left      Previous
Swipe down      Back
Swipe up        Actions
Two-finger tap  Pause
```

Every gesture needs haptic confirmation.

Example:

```text
Success        short-short
Error          long
Listening      pulse
Message        short-long
Confirmation   short-short-short
```

Patterns must be configurable later.

---

# 10. Accessibility Activation

Gusa should expose an Android AccessibilityService.

Activation:

```text
Android Accessibility Shortcut
             ↓
          GUSA
             ↓
       📳 READY
```

Once active, Gusa can operate across supported Android interfaces.

---

# 11. Read Screen

The Android layer inspects the active accessibility tree.

Example raw interface:

```text
Nairobi AI Meetup

Saturday 14 September

Register now

About Event

Location

Free Entry
```

Gusa converts this into a structured representation:

```json
{
  "title": "Nairobi AI Meetup",
  "texts": [],
  "buttons": [],
  "inputs": [],
  "links": []
}
```

---

# 12. AI Screen Understanding

AI receives a sanitized structured description rather than screenshots wherever possible.

Input:

```text
App: Chrome
Page title: Nairobi AI Meetup

Elements:
heading: Nairobi AI Meetup
text: Saturday 14 September
text: Free Entry
button: Register
button: Event Details
```

AI returns:

```text
Nairobi AI Meetup.
September 14.
Free.

Actions:
1. Register
2. Details
3. Back
```

This is then delivered through:

- haptics
- large text
- speech
- Braille

---

# 13. AI Action Planner

AI does NOT directly control Android.

AI returns a structured action proposal.

Example:

```json
{
  "intent": "register_event",
  "summary": "Free event registration.",
  "actions": [
    {
      "type": "click",
      "target": "Register"
    }
  ],
  "requiresConfirmation": false
}
```

The Android executor validates and performs the action.

Architecture:

```text
USER
 ↓
Intent
 ↓
AI Planner
 ↓
Structured Action
 ↓
Policy Validator
 ↓
Android Executor
 ↓
App / Website
```

---

# 14. Allowed Action Types

MVP action contract:

```text
OPEN_APP
CLICK
SET_TEXT
SCROLL_FORWARD
SCROLL_BACKWARD
GO_BACK
GO_HOME
READ_NODE
FOCUS_NODE
ASK_USER
SPEAK
PLAY_HAPTIC
```

Potential Phase 2 actions:

```text
SELECT_OPTION
UPLOAD_FILE
OPEN_LINK
SEND_MESSAGE
CALL
SHARE
```

---

# 15. Confirmation Policy

Gusa must distinguish between harmless navigation and consequential actions.

### No confirmation required

```text
Read screen
Scroll
Go back
Open app
Repeat
Read button
Focus field
```

### Confirmation required

```text
Submit registration
Send message
Upload document
Place call
Accept terms
Delete item
Share information
Book service
```

### Strong confirmation required later

```text
Payment
Financial transaction
Legal agreement
Sensitive document upload
Account deletion
```

AI can prepare these actions.

AI cannot silently execute them.

---

# 16. Example Event Registration

User command:

```text
REGISTER
```

Gusa finds:

```text
Full Name
Email Address
Phone
Attendance Type
Register
```

Local profile contains:

```text
Name ✓
Email ✓
Phone ✓
```

Gusa automatically prepares those values.

Missing:

```text
Attendance Type
```

User receives:

```text
CHOOSE ATTENDANCE

1 PHYSICAL
2 ONLINE
```

User selects:

```text
1
```

Gusa fills the form.

Then:

```text
READY TO REGISTER

FREE EVENT

CONFIRM?
```

User double-taps.

Only then:

```text
Register button
      ↓
CLICK
```

Success:

```text
📳 📳

REGISTRATION SUCCESSFUL
```

---

# 17. Local User Profile

For MVP:

```text
Full name
Email
Phone
Country
Preferred language

Braille mode
Haptic speed
Haptic intensity
Preferred output
Preferred input
```

No cloud account required initially.

**MVP authentication: none (D-011, decided 2026-09-02).** The MVP is a demo. There is no
password, no OTP, no login and no user account — the app opens straight into the
experience: touch/haptic Braille feedback, speech-to-text, and open-app actions.
This is separate from the proxy shared-secret in D-006, which protects the API key and is
not a user credential, and separate from §37 redaction, which strips *other* apps'
password and OTP text before anything is sent to the AI.

Sensitive information stays on-device.

---

# 18. Form Intelligence

Start with deterministic matching before AI.

Example synonyms:

```text
NAME

name
full name
your name
participant
attendee
```

```text
EMAIL

email
email address
e-mail
```

```text
PHONE

phone
mobile
mobile number
telephone
contact number
```

Confidence:

```text
"Participant Name"

→ profile.name
→ confidence 0.94
```

Low confidence:

```text
UNKNOWN FIELD

Ask user.
```

AI can handle ambiguous fields.

---

# 19. AI Responsibilities

AI should be used for:

### Screen summarization

Turn complicated interfaces into concise tactile information.

### Intent understanding

Understand:

```text
"Help me register."

"Tell me what is on this page."

"Find the registration."

"What am I supposed to enter?"
```

### Message simplification

Original:

```text
Your booking scheduled for Wednesday afternoon
has unfortunately been rescheduled...
```

Accessible:

```text
BOOKING CHANGED.
THURSDAY 9 AM.
```

### Error explanation

Website:

```text
Please provide a valid MSISDN including international prefix.
```

Gusa:

```text
PHONE NUMBER NEEDS COUNTRY CODE.

USE +254...
```

### Quick responses

Question:

```text
Do you want tea or coffee?
```

AI:

```text
1 Tea
2 Coffee
3 Neither
```

---

# 20. Voice

## Primary cloud provider

ElevenLabs.

Use:

- Speech-to-Text
- Text-to-Speech

Cloud flow:

```text
Flutter
 ↓
Serverless Proxy
 ↓
ElevenLabs
```

Never ship the permanent ElevenLabs API key inside the production APK.

---

# 21. Voice Fallback

If internet is unavailable:

```text
Android SpeechRecognizer
+
Android TextToSpeech
```

Therefore:

```text
Internet available
→ ElevenLabs

Internet unavailable
→ Android voice services
```

---

# 22. AI Provider

Use OpenAI through a serverless proxy.

Important requirement:

The AI action planner must return **Structured Outputs / JSON schema**, not arbitrary prose.

Example schema:

```json
{
  "intent": "string",
  "summary": "string",
  "actions": [],
  "requiresConfirmation": true
}
```

This makes the Android executor deterministic.

---

# 23. No Traditional Backend

MVP architecture does NOT require:

```text
Python
FastAPI
Django
NestJS server
Redis
Celery
Kafka
Kubernetes
Backend database
```

Instead:

```text
Flutter / Android
       ↓
Serverless Proxy
       ↓
OpenAI
ElevenLabs
```

---

# 24. Serverless Layer

Recommended:

**Cloudflare Workers**

Alternative:

**Supabase Edge Functions**

Responsibilities ONLY:

```text
Protect API keys
Call OpenAI
Call ElevenLabs
Rate limiting
Basic request validation
```

Do not put accessibility logic here.

---

# 25. Complete Architecture

```text
                    ┌──────────────────────┐
                    │       USER           │
                    │ Braille / Touch      │
                    │ Speech / Visual      │
                    └──────────┬───────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │     FLUTTER APP      │
                    │                      │
                    │ Braille Engine       │
                    │ Gesture Engine       │
                    │ Haptic Engine        │
                    │ Conversation UI      │
                    │ Local Profile        │
                    │ Intent Router        │
                    └──────────┬───────────┘
                               │
                ┌──────────────┴─────────────┐
                │                            │
                ▼                            ▼
       ┌─────────────────┐           ┌──────────────────┐
       │ ANDROID / KOTLIN│           │ SERVERLESS PROXY │
       │                 │           │                  │
       │ Accessibility   │           │ OpenAI           │
       │ Screen reader   │           │ ElevenLabs       │
       │ UI actions      │           │                  │
       │ App launcher    │           └──────────────────┘
       │ Vibration       │
       └────────┬────────┘
                │
                ▼
       ┌──────────────────┐
       │ OTHER ANDROID    │
       │ APPS / WEBSITES  │
       └──────────────────┘
```

---

# 26. Flutter Technology Stack

```text
Flutter
Dart

State:
Riverpod

Navigation:
go_router

Local Database:
Drift / SQLite

Sensitive storage:
flutter_secure_storage

Networking:
Dio

Audio:
audio recorder/player package as required

Native communication:
Pigeon preferred
or MethodChannel initially
```

Use Pigeon once the native contract stabilizes because typed Flutter↔Kotlin interfaces reduce integration mistakes.

---

# 27. Native Android Stack

```text
Kotlin

AccessibilityService
AccessibilityNodeInfo
AccessibilityEvent

VibrationEffect
VibratorManager

PackageManager / Intents

Android TextToSpeech
Android SpeechRecognizer
```

---

# 28. Flutter Modules

```text
lib/

core/
├── braille/
├── haptics/
├── gestures/
├── speech/
├── storage/
└── accessibility/

features/
├── onboarding/
├── home/
├── tactile_mode/
├── braille_keyboard/
├── conversation/
├── screen_reader/
├── form_assistant/
├── app_launcher/
└── settings/

services/
├── ai_service/
├── elevenlabs_service/
└── android_bridge/
```

---

# 29. Native Android Modules

```text
android/

GusaAccessibilityService.kt

AccessibilityTreeParser.kt

AccessibilityExecutor.kt

AppLauncher.kt

HapticController.kt

SpeechController.kt

AccessibilityBridge.kt
```

---

# 30. Shared Android Action Model

All developers should agree on this FIRST.

Example:

```json
{
  "id": "action_123",
  "type": "SET_TEXT",
  "target": {
    "text": "Email Address",
    "className": "EditText"
  },
  "value": "user@example.com",
  "risk": "LOW",
  "requiresConfirmation": false
}
```

This is the boundary between AI, Flutter and Android.

---

# 31. TEAM STRUCTURE — 3 DEVELOPERS

---

# Developer 1 — Flutter + Tactile Experience

### Owns

```text
Flutter application
Braille keyboard
Braille encoder/decoder
Haptic UX
Gesture UX
Conversation Mode
Large text display
Settings
Local profile
Local storage
```

### Main deliverables

#### D1.1 Flutter shell

Create:

```text
Navigation
Riverpod setup
Architecture
Theme
Accessibility semantics
```

#### D1.2 Braille Engine

Implement:

```text
BrailleCell
BrailleEncoder
BrailleDecoder
BrailleKeyboard
```

Unit tests required.

#### D1.3 Tactile interface

Implement:

```text
six-dot input
touch regions
gesture recognition
confirmation states
repeat
pause
```

#### D1.4 Haptic playback

Flutter-facing API:

```text
playCharacter()
playWord()
playMessage()
confirm()
error()
notification()
```

#### D1.5 Conversation screen

Build:

```text
Speak
Receive
Braille response
Large-text response
Play voice
```

#### D1.6 Settings

```text
Braille mode
Haptic speed
Haptic intensity
Output mode
Speech preference
```

---

# Developer 2 — Android Accessibility / Device Control

This developer owns the deepest technical part.

### Owns

```text
Kotlin
AccessibilityService
Accessibility tree
Opening apps
Clicking
Scrolling
Text insertion
Screen extraction
Haptic native APIs
Flutter native bridge
```

### Main deliverables

#### D2.1 Accessibility service

Implement:

```text
GusaAccessibilityService
```

Service should expose:

```text
getCurrentScreen()
performGlobalAction()
findNode()
clickNode()
setNodeText()
scroll()
```

#### D2.2 Accessibility Tree Parser

Convert Android nodes into something Flutter/AI can understand.

Example:

```json
{
  "id": "node_12",
  "role": "button",
  "text": "Register",
  "clickable": true,
  "editable": false
}
```

#### D2.3 Executor

Implement deterministic actions:

```text
CLICK
SET_TEXT
SCROLL
BACK
HOME
FOCUS
OPEN_APP
```

#### D2.4 App launcher

Allow:

```text
OPEN WHATSAPP
OPEN CHROME
OPEN PHONE
```

through Android intents.

#### D2.5 Native haptics

Expose precise vibration APIs.

#### D2.6 Flutter bridge

Expose Kotlin functions to Developer 1.

---

# Developer 3 — AI + Voice + Agent Logic

### Owns

```text
AI integration
ElevenLabs
Serverless proxy
Intent system
Screen summarization
Action planning
Form interpretation
Safety policy
```

### Main deliverables

#### D3.1 Serverless gateway

Implement:

```text
POST /ai/summarize-screen

POST /ai/plan

POST /ai/simplify

POST /voice/stt

POST /voice/tts
```

No database required.

#### D3.2 Secrets

Store:

```text
OPENAI_API_KEY

ELEVENLABS_API_KEY
```

server-side.

#### D3.3 AI Screen Interpreter

Input:

```json
{
  "app": "Chrome",
  "nodes": []
}
```

Output:

```json
{
  "summary": "...",
  "availableActions": []
}
```

#### D3.4 AI Action Planner

Structured output ONLY.

AI should never generate arbitrary executable Android code.

#### D3.5 Intent Router

Local commands should bypass AI:

```text
BACK
NEXT
REPEAT
HOME
OPEN WHATSAPP
READ SCREEN
```

Complex instructions use AI.

#### D3.6 ElevenLabs

Implement:

```text
speech → text

text → speech
```

with Android fallback.

#### D3.7 Form Interpreter

Map:

```text
Name
Email
Phone
Company
Country
```

to local profile values.

---

# 32. How the Three Developers Work in Parallel

Before major implementation begins, agree on three contracts:

### Contract A

Flutter ↔ Android

```text
AccessibilityBridge
```

### Contract B

Flutter ↔ AI

```text
AIRequest / AIResponse
```

### Contract C

AI ↔ Android

```text
AccessibilityAction
```

Once these contracts are stable, the three developers can work mostly independently.

---

# 33. Parallel Development Sequence

## Stage 1 — Foundation

Developer 1:

```text
Flutter shell
Braille engine
Braille UI
```

Developer 2:

```text
AccessibilityService
Screen-tree extraction
```

Developer 3:

```text
Serverless proxy
AI structured schemas
ElevenLabs proof of concept
```

---

## Stage 2 — Integration

Developer 1:

```text
Tactile reader
Conversation mode
```

Developer 2:

```text
click
scroll
set text
open apps
```

Developer 3:

```text
screen summaries
action planning
form interpretation
```

---

## Stage 3 — Hero Demo

All three focus on:

```text
OPEN EVENT
    ↓
READ
    ↓
REGISTER
    ↓
FILL
    ↓
ASK MISSING INFO
    ↓
CONFIRM
    ↓
SUBMIT
```

---

# 34. MVP Screens

Only create:

```text
1 Onboarding

2 Accessibility Setup

3 Home

4 Touch / Braille Mode

5 Conversation Mode

6 Read Screen

7 My Profile

8 Accessibility Settings
```

Do not create unnecessary conventional app screens.

The product is supposed to reduce interface complexity.

---

# 35. Onboarding

Step 1:

```text
HOW DO YOU RECEIVE INFORMATION?
```

Options:

```text
Vibration / Braille
Voice
Large text
Screen reader
```

Step 2:

```text
HOW DO YOU RESPOND?
```

Options:

```text
Braille
Voice
Keyboard
Quick actions
```

Step 3:

Configure:

```text
Braille
Haptic speed
Voice
```

Step 4:

Enable Android Accessibility Service.

Step 5:

Practice.

---

# 36. Offline Behaviour

Offline must support:

```text
Braille input
Braille decoding
Haptics
Gestures
Profile
Read accessibility tree
Basic commands
App opening
Navigation
Simple form filling
Android TTS
```

Offline may lose:

```text
AI summaries
AI reasoning
ElevenLabs
Advanced natural language
```

The app should automatically degrade gracefully.

---

# 37. Security

Never include permanent OpenAI or ElevenLabs API keys inside the release APK.

Send the minimum UI information required for AI reasoning.

Avoid sending:

```text
passwords
PINs
OTP codes
bank details
private screen contents
```

unless a future feature explicitly requires and safely handles them.

Do not store full accessibility screen histories by default.

---

# 38. Privacy

Default:

```text
No cloud conversation history.

No raw screen history.

No continuous screen monitoring storage.

No recording after microphone interaction ends.
```

AI requests should ideally be ephemeral.

---

# 39. MVP Non-Goals

Do NOT build yet:

```text
Payments
Banking automation
Full WhatsApp automation
Autonomous purchasing
Universal website support
Camera navigation
Face recognition
Cloud user accounts
Multi-device synchronization
Document vault
Complex OCR
Fully autonomous agent
iOS
```

---

# 40. Test Matrix

Test at minimum:

```text
Braille accuracy
Haptic recognition
Gesture accuracy
Offline mode
TalkBack compatibility
Speech input
Speech output
Accessibility activation
Chrome navigation
Form recognition
Text filling
Confirmation
Registration completion
Error recovery
```

---

# 41. Critical User Testing

Engineering tests are not enough.

The MVP must be tested with actual Braille users.

Measure:

```text
Character recognition accuracy

Words per minute

Message comprehension

Mistakes

Number of repeats

Time to complete task

Gesture errors

Fatigue

Form completion success

Confidence using Gusa
```

This testing will determine whether the haptic Braille concept is actually useful.

---

# 42. MVP Success Criteria

Consider MVP successful if test users can:

### Communication

Receive a short spoken message through tactile output.

### Braille

Enter a response using the six-dot interface.

### Speech

Have their response spoken aloud.

### Device interaction

Open another application through Gusa.

### Understanding

Get a simplified representation of the current screen.

### Navigation

Select an actionable element.

### Form completion

Fill common registration information.

### Task completion

Successfully register for a test event.

### Safety

Explicitly confirm before submission.

---

# 43. MVP Demo

The final demonstration should tell one clear story.

### Person speaks

> “There is an AI meetup tomorrow. Would you like to attend?”

### Gusa

Converts speech → accessible tactile message.

### User

Braille-types:

```text
YES
```

### Gusa

Speaks:

> “Yes.”

User opens event page.

User commands:

```text
READ SCREEN
```

Gusa:

```text
AI MEETUP.
TOMORROW.
FREE.

1 REGISTER
2 DETAILS
```

User:

```text
REGISTER
```

Gusa fills:

```text
Name ✓
Email ✓
Phone ✓
```

Asks:

```text
PHYSICAL OR ONLINE?
```

User chooses physical.

Gusa:

```text
REGISTRATION READY.
FREE.
CONFIRM?
```

Double tap.

Registration submitted.

```text
📳 📳

SUCCESS
```

That demonstration proves the core Gusa vision.

---

# 44. Phase 2

After validating MVP:

```text
WhatsApp/message accessibility
Notification summarization
Email
Calendar
Document reading
Camera/OCR
Translation
Kiswahili support
On-device AI
Refreshable Braille displays
Bluetooth tactile hardware
Contact commands
Bookings
Service integrations
```

---

# 45. Product Positioning

Do not position Gusa simply as:

> “A Braille app.”

Position it as:

> **A touch-first AI accessibility assistant.**

Or:

> **Use your phone through touch.**

Long-term:

> **Gusa turns speech, screens and digital services into accessible touch — and turns touch back into action.**

---

# 46. Recommended Working Name

## Gusa

Why it works:

- short
- easy to pronounce
- connected to touch
- African identity
- does not limit the product to Braille
- can grow into an accessibility platform

Potential feature names:

```text
Gusa Touch
Gusa Talk
Gusa Read
Gusa Assist
Gusa Actions
```

The name should still undergo trademark, Play Store and domain checks before public launch.