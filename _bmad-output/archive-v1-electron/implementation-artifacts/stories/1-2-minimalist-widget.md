# Story 1.2: Minimalist Widget

Status: done

## Story

As a player,
I want a minimalist widget that stays always on top,
so that I can see my earnings grow in real-time without obscuring my workspace.

## Acceptance Criteria

1. **Always-on-Top**: The widget window stays visible above all other applications.
2. **Transparency & Feel**: Frameless window with a semi-transparent, premium glassmorphic background.
3. **Real-time Counter**: A high-precision counter ($0.0000 format) updating at 60 FPS (or close to it) based on the hourly wage.
4. **Draggable**: The user can move the widget anywhere on the screen (no standard title bar).
5. **Switch Logic**: Ability to switch between the "Main View" (Settings/Setup) and "Widget View".

## Tasks / Subtasks

- [x] **Main Process**: Configure the Widget Window (AC: 1, 2)
  - [x] Add logic in `main.ts` to support a secondary frameless window or resize the main window.
  - [x] Set `alwaysOnTop: true`, `frame: false`, `transparent: true`.
- [x] **Salary Engine**: Implement real-time accumulation (AC: 3)
  - [x] Enhance `salaryStore.ts` with an `accumulated` state.
  - [x] Create a `useEffect` ticker in the Renderer to increment based on `earnedPerMs`.
- [x] **UI Layer**: Design the Minimalist Widget (AC: 2, 4)
  - [x] Create `src/components/MoneyWidget.tsx`.
  - [x] Style with ultra-minimalist typography.
  - [x] Implement `-webkit-app-region: drag` for movement.
- [x] **Handoff Logic**: main-to-widget transition (AC: 5)
  - [x] Add a "Switch to Widget" button in the Main View.

## Dev Notes

- **Performance**: High-frequency updates should be efficient (use `requestAnimationFrame` if possible, or standard interval).
- **Aesthetics**: Stick to the "Ghibli-Clean" / Dark mode aesthetic.
- **IPC**: Use existing bridge for get/set wage.

### References

- [Architecture: Widget Properties](file:///c:/Users/v.grabowski/OneDrive - Betclic Group/Documents/DEV/PROJETS/PERSO/MoneyMaker/_bmad-output/game-architecture.md#Cross-platform-Strategy)
- [GDD: Widget Design](file:///c:/Users/v.grabowski/OneDrive - Betclic Group/Documents/DEV/PROJETS/PERSO/MoneyMaker/_bmad-output/gdd.md#Target-Platforms)
