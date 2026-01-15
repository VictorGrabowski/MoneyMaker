# Story 1.1: Set Hourly Wage

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a player,
I want to set my hourly wage,
so that my income is calculated correctly in real-time.

## Acceptance Criteria

1. **Input Interface**: A clear UI field (diegetic if possible, or minimalist) to enter the hourly wage.
2. **Data Validation**: The input must accept only positive numeric values (decimals allowed).
3. **Persistence**: The wage is saved locally via `electron-store` and persists across app restarts.
4. **State Sync**: The wage is immediately available to the `SalaryEngine` in the Main process and reflected in the UI.

## Tasks / Subtasks

- [ ] **Data Layer**: Initialize `salaryStore` with Zustand (AC: 4)
  - [ ] Create `src/renderer/src/store/salaryStore.ts`
  - [ ] Define `wage` state and `setWage` action
- [ ] **Infrastructure**: Configure `electron-store` in Main process (AC: 3)
  - [ ] Setup Store in `src/main/services/persistence.ts`
  - [ ] Create IPC bridge in `preload.ts` to get/set the wage
- [ ] **UI Layer**: Implement Wage Input Component (AC: 1, 2)
  - [ ] Create `src/renderer/src/components/WageInput.tsx`
  - [ ] Style with Tailwind (Glassmorphism / Minimalist)
  - [ ] Add numeric validation
- [ ] **Integration**: Connect UI to Store and Persistence (AC: 1, 3, 4)
  - [ ] Fetch initial wage from `electron-store` on mount
  - [ ] Update `electron-store` when wage is changed

## Dev Notes

- **Architecture**: Follow the Hybrid structure. Logic in `main`, UI in `renderer`.
- **Patterns**: Use the `Zustand` event bus pattern if needed for sync.
- **Library**: `electron-store` for JSON persistence.
- **Source**: [Architecture: Project Structure](file:///c:/Users/v.grabowski/OneDrive - Betclic Group/Documents/DEV/PROJETS/PERSO/MoneyMaker/_bmad-output/game-architecture.md#Project-Structure)

### Project Structure Notes

- Align with `src/main`, `src/preload`, and `src/renderer`.
- Components in `src/renderer/src/components`.

### References

- [GDD: Core Mechanics](file:///c:/Users/v.grabowski/OneDrive - Betclic Group/Documents/DEV/PROJETS/PERSO/MoneyMaker/_bmad-output/gdd.md#Core-Gameplay)
- [Architecture: Persistence](file:///c:/Users/v.grabowski/OneDrive - Betclic Group/Documents/DEV/PROJETS/PERSO/MoneyMaker/_bmad-output/game-architecture.md#Data-Persistence)

## Dev Agent Record

### Agent Model Used

Antigravity (BMad Edition)

### Debug Log References

### Completion Notes List

### File List
