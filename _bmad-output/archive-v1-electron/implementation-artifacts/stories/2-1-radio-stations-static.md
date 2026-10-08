# Story 2-1: Radio Stations (Refactor to Howler.js)

**Status:** ready-for-dev
**Epic:** 2 - Ondes & Saisons
**Story Key:** 2-1-radio-stations-static

---

## 📖 User Story

**As a** developer
**I want to** refactor the existing RadioPlayer to use `Howler.js` for audio streams
**So that** the application complies with the audio architecture and supports advanced mixing (Radio vs SFX) in the future.

**As a** player
**I want** the radio to continue working exactly as before (streams, play/pause)
**So that** my experience is uninterrupted during this technical migration.

---

## ✅ Acceptance Criteria

### Functionality (Regression Testing)
- [ ] **Radio Toggle**: Clicking the Radio component toggles play/pause state.
- [ ] **Station Switching**: Clicking "Next" or "Previous" switches the active station immediately.
- [ ] **Stream Playback**: The app connects to real HLS/MP3 streams (Nova, FIP, etc.) via `Howler.js` (replacing native `Audio`).
- [ ] **Visual Feedback**: The radio dial or display updates to show the current station name.
- [ ] **YouTube Fallback**: Stations with `type: 'youtube'` continue to use `ReactPlayer` (Howler does not support YT).

### Architecture Compliance
- [ ] **Library**: `Howler.js` is installed and used for all `type: 'stream'` stations.
- [ ] **Component Split**: Logic is moved from `RadioPlayer.tsx` to a new `RadioController.tsx` or hook (Feature-sliced).
- [ ] **Audio Groups**: Radio audio uses a specific Howler Group/ID to allow future volume ducking.

### Immersion (New)
- [ ] **Static Noise**: Implement the "Friture-Juice" effect using Howler.js during station transitions (if not already present).

---

## 🛠️ Technical Implementation Requirements

> [!IMPORTANT]
> **Architecture Compliance Required**: The current `RadioPlayer.tsx` uses native HTML5 Audio. You **MUST** refactor this to use **Howler.js** (`howler`) as mandated by the Game Architecture.
> *Reason*: Consolidate audio handling for future mixing features (Radio vs ASMR vs Coins).

### 1. Audio Architecture (Howler.js)
- **Library**: `howler` (v2.2.x).
- **Configuration**:
  - Use `html5: true` to enable streaming (avoids full XHR download).
  - Create a `radioGroup` or separate `Howl` instance management for the radio to allow global volume ducking later.
- **Reference Implementation**:
  ```typescript
  // src/features/radio/audioEngine.ts (Pseudo-code)
  const radio = new Howl({
    src: [stationUrl],
    html5: true, // FORCE HTML5 Audio for streaming
    format: ['mp3', 'aac'],
    volume: 0.5
  });
  ```

### 2. Static Noise System ("Friture-Juice")
- **Implementation**:
  - Do NOT use procedural buffer generation if it sounds harsh.
  - **Preferred**: Use a pre-baked `static_noise.mp3` or `tuning.mp3` asset (if available, otherwise generate a high-quality buffer).
  - **Logic**:
    1. User clicks "Next Station".
    2. Trigger `playStatic()` (looping).
    3. Stop current stream.
    4. Start loading next stream.
    5. On `load`, fade out static and fade in new stream.

### 3. State Management (Zustand)
- **Store**: `useImmersionStore` (already exists).
- **Updates**: 
  - Ensure `currentStationIndex` persists (if persistence layer is active).
  - Add `isTuning` state if needed for UI animations.

### 4. Component Structure
- **Refactor**: `src/components/RadioPlayer.tsx` -> Move logic to `src/features/radio/RadioController.tsx` (align with Architecture "Feature-sliced").
- **UI**: Keep the visual component simple, adhering to "Ghibli-Clean" (SVG icons, subtle animations).

---

## 🧱 Architecture Guidelines

- **Layering**: Logic in `src/features/radio/`, UI in `src/renderer/...`.
- **Zustand**: Use `useImmersionStore` for state. Do not use local state for global radio status.
- **Assets**: If adding static noise MP3, place in `src/renderer/assets/audio/sfx/`.

---

## 🧪 Testing Strategy

### Manual Verification
1. **Stream Test**: Click through all 3 default stations (Nova, FIP, France Info). Confirm they play.
2. **Transition Test**: Switch stations rapidly. Confirm static noise plays *every time* and doesn't stack indefinitely (clean audio cleanup).
3. **Volume Test**: Lower volume in store. Confirm radio obeys.
4. **Network Cut**: Disconnect internet. Confirm "Dead Air" or Static handling (no app crash).

### Automated Tests (If applicable)
- Unit test `immersionStore` for station cycling logic ("Next" from last station goes to first).

---

## 🔍 Context & Learnings

- **From `RadioPlayer.tsx` (Current)**:
  - The logic for `AudioContext.resume()` on user interaction is solid. Keep this pattern! Browsers block auto-play.
  - The `Play/Pause` toggle logic works well.
  - **Change**: Replace the `native <audio>` and `ReactPlayer` mix with a unified `Howler` approach if possible. *Note: YouTube streams cannot be played via Howler. If the user insists on YouTube stations, keep ReactPlayer as a fallback for `type: 'youtube'`, but use Howler for `type: 'stream'`.*

- **From GDD**: "Friture-Juice" is a key tactile feature. Make it satisfying, not annoying.
