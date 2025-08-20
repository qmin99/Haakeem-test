### Arabic Agents – Technical Documentation

This document captures the full implementation details for the Arabic voice agents that were added to the project, including architecture, backend and frontend changes, voice/dialect handling, file-processing behavior, and known trade‑offs.

---

## TL;DR

- Two Arabic agents are available:
  - ArabicAgent (continuous conversation)
  - ArabicClickToTalkAgent (push/click‑to‑talk)
- STT: Azure Speech to Text configured for Arabic (`ar-SA`, `ar-EG`).
- TTS: Azure TTS Gulf voice by default (`ar-OM-AbdullahNeural`).
- LLM: Groq `allam-2-7b` for Arabic.
- Backend orchestrator supports mode switching via LiveKit data messages.
- File messages rendered in Arabic for both Arabic agents.
- Dialect: speak in the user’s dialect when recognizable; otherwise default to Gulf. Instructions enforce this.
- Frontend supports language → agent filtering, Arabic Click‑to‑Talk UI, proper mic control, and visible Stop button for continuous Arabic.

---

## Directory Map

- Backend (Python)
  - `backend/agent/agent.py` – orchestrator; start/stop sessions; switching; cleanup
  - `backend/agent/agents/arabic_agent.py` – continuous Arabic agent
  - `backend/agent/agents/arabic_click_to_talk_agent.py` – Arabic click‑to‑talk agent
  - `backend/agent/agents/__init__.py` – exports agent classes
- Frontend (Flutter)
  - `app/lib/controllers/app_ctrl.dart` – agent switching, mic control, click‑to‑talk flow, language filter
  - `app/lib/widgets/agent_selection_widget.dart` – language segmented control + filtered agent grid
  - `app/lib/screens/main_screen.dart` – UI wiring, STT locale, waveform/Stop controls
  - `app/lib/widgets/click_to_talk_controls.dart` – click‑to‑talk controls shared by EN+AR CTT

---

## Backend – Orchestrator (`backend/agent/agent.py`)

### Sessions

- Continuous agents (attorney, arabic) use `AgentSession` with VAD (Silero) and audio input enabled.
- Click‑to‑talk agents (click_to_talk, arabic_click_to_talk) use `AgentSession(turn_detection="manual")`, audio input disabled by default; `start_turn`/`end_turn` flip input audio.

### Switching

- Supported data messages from the frontend:
  - `switch_to_attorney`
  - `switch_to_click_to_talk`
  - `switch_to_arabic`
  - `switch_to_arabic_click_to_talk`
- The orchestrator performs an aggressive cleanup when switching from continuous agents to click‑to‑talk to prevent lingering speech (disable input, multiple interrupts, short waits), then starts the new session and broadcasts the active agent.

### Click‑to‑Talk RPC / Data handling

- `start_turn`: interrupt, clear user turn, `session.input.set_audio_enabled(True)`
- `end_turn`: `session.input.set_audio_enabled(False)`, `session.commit_user_turn(...)`
- `cancel_turn`: disable input, clear user turn

---

## Backend – Arabic Agents

### Common characteristics

- STT: `AzureSTT(language=["ar-SA", "ar-EG"])`
- LLM: `groq.LLM(model="allam-2-7b")`
- TTS: `AzureTTS(voice="ar-OM-AbdullahNeural", language="ar-OM")` (Gulf voice by default). You can switch to `ar-SA-HamedNeural` if you prefer Saudi.
- Instructions emphasize: speak in the user’s dialect when detectable; otherwise default to Gulf; keep replies concise and practical.
- All file‑processing user‑visible strings are in Arabic.

### `arabic_agent.py` (continuous)

- Instructions (summary):
  - اسمك حَكيم (Binfin8). تحدث بلهجة المستخدم إن أمكن؛ إن تعذّر فاختر لهجة خليجية واضحة بدل الفصحى.
  - ردود عملية موجزة؛ اطلب المعلومات الناقصة بدقة.
  - عند الملفات: أعطِ ملخصًا ثم نقاطًا قانونية قابلة للتنفيذ.
- `on_enter`: ترحيب عربي موجز.
- File handling:
  - Text/PDF/Image/Word/JSON supported.
  - Arabic messages returned to chat, e.g. “مستند PDF… المحتوى…”, “صورة… بيانات Base64…”, “ملف JSON…”.

### `arabic_click_to_talk_agent.py` (click‑to‑talk)

- Instructions (summary):
  - نفس مبدأ اللهجة؛ الرد موجز لأن التدفق يدوي (Start/End).
  - ملخص قصير ثم نقاط عملية.
- `on_enter`: ترحيب عربي موجز يشرح زر التكلّم والإرسال.
- File handling: نفس تغطية الأنواع ورسائل عربية.

---

## Frontend – Language and Agents

### State & Selection (`app_ctrl.dart`, `agent_selection_widget.dart`)

- `AgentLanguage { en, ar }` + `selectedLanguage`.
- `agentsFor(lang)` filters available agents:
  - `en` → Attorney (continuous), Click‑to‑Talk
  - `ar` → Arabic (continuous), Arabic Click‑to‑Talk
- Segmented control UI for language; grid below shows only the relevant modes.
- Auto‑switch to a valid default when the language changes.

### Connection & Mic control (`app_ctrl.dart`)

- Continuous agents (attorney, arabic): mic enabled.
- Click‑to‑talk agents (click_to_talk, arabicClickToTalk): mic disabled until `start_turn`.
- Robust switch cleanup and debouncing to avoid overlapping audio.

### Click‑to‑Talk controls (`click_to_talk_controls.dart`)

- Shared UI for EN/AR CTT (start/cancel/end/send).
- `AppCtrl` enforces correct state transitions and publishes `start_turn` / `end_turn` / `cancel_turn` messages to the backend.

### Local STT preview locale (`main_screen.dart`)

- For `selectedAgent` in `{ arabic, arabicClickToTalk }`, the local Flutter STT preview uses `ar_SA` for interim text.

### Waveform & Stop button (`main_screen.dart`)

- Draggable waveform shown when voice mode is active.
- Stop button visibility fixed: now shown for both continuous agents (`attorney` and `arabic`).

---

## File Upload Pipeline (Arabic agents)

1. Frontend sends file bytes via LiveKit byte stream topic `files` (or a data fallback with base64).
2. Orchestrator routes `_file_received` to the current agent.
3. Agent reads the stream, processes content by MIME type, and pushes an Arabic message to chat context.
4. Agent generates a reply: concise summary + legal points.

---

## Dialect and Voice

- Primary strategy is instruction‑level: “mirror the user’s dialect; otherwise default to Gulf”.
- TTS voice is seeded with a Gulf voice (`ar-OM-AbdullahNeural`) to bias the output. Swap to `ar-SA-HamedNeural` if preferred.
- Future enhancement: auto‑switch TTS voice based on STT locale confidence (e.g., `ar-EG` → Egyptian voice, `ar-SA` → Saudi voice).

---

## Switching & Stability Notes

- Mode switching uses LiveKit data messages. The orchestrator:
  - Performs interrupts and disables audio on continuous agents before switching.
  - Creates the new session with correct turn detection and audio input state.
  - Broadcasts active agent (`active_agent:<type>`).
- A bug where the Arabic agent kept talking after switching to Click‑to‑Talk was fixed with aggressive cleanup.
- UI bug fixed: the Stop button now remains visible when switching to the Arabic continuous agent.

---

## How to Use

1. From Settings → choose language (English / العربية). Only relevant agents appear.
2. Pick mode:
   - Continuous (Attorney / Arabic): speak freely; press Stop to end the live conversation.
   - Click‑to‑Talk (EN / AR): press Start → speak → End → Send to agent.
3. Upload files; Arabic agents will produce Arabic messages in the chat and respond in Arabic.

---

## Maintenance Pointers

- Update dialect/voice defaults in:
  - `arabic_agent.py`, `arabic_click_to_talk_agent.py` → `tts=AzureTTS(...)` and instructions string
- Adjust Arabic file message templates in `_process_file` and `_file_received_fallback` for each Arabic agent.
- Frontend locale for local STT preview: `main_screen.dart` (look for `localeId: ... 'ar_SA'`).
- Language selector and filtering: `AppCtrl.agentsFor()` and `AgentSelectionWidget`.

---

## Known Limitations / Future Work

- Heuristic dialect mirroring is instruction‑based; dynamic TTS voice switching by inferred locale would improve realism.
- Add more Arabic TTS voices and an in‑UI selector (e.g., Saudi/Egyptian/Gulf).
- Expand file‑type coverage (e.g., PowerPoint, Excel) with safe parsers.
- Consider Arabic punctuation and numeral normalization for clearer TTS.

---

## Changelog (Arabic scope)

- Added `ArabicAgent` and `ArabicClickToTalkAgent` with Azure STT/TTS, Groq LLM.
- Localized all file‑related chat messages to Arabic.
- Integrated agent switching (`switch_to_arabic`, `switch_to_arabic_click_to_talk`).
- Fixed lingering speech after switching from Arabic to Click‑to‑Talk by enhancing cleanup.
- Implemented Language segmented control and filtered agent selection in the UI.
- Enabled Stop button for Arabic continuous agent in the waveform panel.


