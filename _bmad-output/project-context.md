---
project_name: 'MoneyMaker'
user_name: 'V.grabowski'
date: '2026-01-15'
sections_completed: ['technology_stack', 'critical_rules', 'naming_conventions', 'novel_patterns']
---

# Project Context for AI Agents

_This file contains critical rules and patterns that AI agents must follow when implementing game code in MoneyMaker. Focus on unobvious details and strict architectural boundaries._

---

## 🛠️ Technology Stack & Versions

- **Core**: Electron (v39.2.x) + React (v19.x) + Vite (v7.x)
- **State**: Zustand (v5.x) - Centralized store for all cross-process sync.
- **Persistence**: `electron-store` (v8.x) - Local JSON only. **Zero-Sync policy**.
- **Physics**: Matter.js (v0.20.x) - Soft-body simulation via Distance Constraints.
- **Audio**: Howler.js (v2.2.x) - Multi-channel mixing (Radio vs ASMR).

---

## 📏 Naming Conventions

- **React Components**: `PascalCase` (e.g., `BakeryHub.tsx`).
- **Logic & Services**: `camelCase` (e.g., `salaryEngine.ts`).
- **Assets (WebP/SVG/SFX)**: `snake_case` (e.g., `coin_gold_soft.webp`).
- **Zustand Events/Actions**: `UPPER_SNAKE` (e.g., `UPDATE_SALARY`).

---

## 🏛️ Architectural Boundaries

1. **Main vs Renderer**:
   - **Main Process**: Heavy logic, persistence, and real-world sync (Weather, Salary calculation).
   - **Renderer Process**: Visuals, Physics (Matter.js), and Audio (Howler.js).
   - **Bridge**: Communication ONLY via `contextBridge` in `preload.ts`.

2. **Error Handling**:
   - **Silent Recovery**: NEVER break immersion with popups. Use `electron-log` for technical traces.
   - **Ghost-Loading**: Preload hub assets on UI hover to achieve <0.5s transition.

---

## 💡 Novel Patterns

### Catch-up Burst Pattern
- **Logic**: Salary is not tracked in real-time background threads (to avoid OS throttling).
- **Calculation**: On App Focus -> `(Now - LastSeen) * Rate`.
- **Visual**: Trigger a "Burst" of physical coins in the Renderer.
- **Implementation**: Use a `BurstManager` to spawn coins across 5-10 seconds (lissage) to maintain 60 FPS.

---

## ⚠️ Critical Rules (DO NOT DISREGARD)

- **Performance**: Maintain 60 FPS at all times. Object pooling is required for coins.
- **Assets**: Use WebP for images and SVG for icons. Keep the total build < 100MB.
- **Privacy**: NO external analytics or data collection. Everything stays local.
