# MoneyMaker Polish Epics

## Epic 1: MoneyMaker Polish
Focus on improving the overall feel, stability, and "juice" of the game.

### Story 1.1: Connect Baking Logic
**As a** player,
**I want** my baking actions in the Living Room to be reflected in the game state,
**So that** I feel my actions have impact and I can earn rewards.

- Connect `hasFinishedStock` in `LivingRoomView` to `bakingStore`.

### Story 1.2: Recipe Completion Event
**As a** player,
**I want** a clear visual or event when I finish a recipe,
**So that** I know I have succeeded and receive positive feedback.

- Trigger a global 'Recipe Complete' event in `bakingStore.ts`.

### Story 1.3: Save System Robustness
**As a** developer,
**I want** the save system to handle edge cases like corrupted files,
**So that** players don't lose their progress accidentally.

- Verify `persistence.ts` robustness.

### Story 1.4: Plant Assets
**As a** player,
**I want** to see actual plant images instead of placeholders,
**So that** the garden looks beautiful and immersive.

- Replace placeholder logic in `PlantOverlay.tsx` with images from `art-prompts-plants.md`.

### Story 1.5: Inventory Particles
**As a** player,
**I want** to see particle effects when I eat or use items,
**So that** the interaction feels satisfying.

- Add particle effects in `InventoryWindow.tsx`.

### Story 1.6: Hub Parallax
**As a** player,
**I want** the Hub background to move slightly with my mouse,
**So that** the scene feels deep and alive.

- Refine mouse parallax effect in `HubView` (currently `blob1Ref`, `blob2Ref`).

### Story 1.7: Eating Sounds
**As a** player,
**I want** to hear a crunch when I eat items,
**So that** the action feels real.

- Add "Crunch! Delicious" sound effect in `InventoryWindow.tsx`.

### Story 1.8: UI Feedback Sounds
**As a** player,
**I want** buttons to make sounds when hovered or clicked,
**So that** the UI feels responsive and tactile.

- Add hover/click sounds to Hub buttons.

### Story 1.9: Ambient Audio
**As a** player,
**I want** different ambient sounds for day and night,
**So that** I feel the passage of time.

- Add day/night ambient tracks in `HubView`.

### Story 1.10: FPS Counter Toggle
**As a** power user,
**I want** to toggle the FPS counter,
**So that** it doesn't clutter the screen when I don't need it.

- Make `FpsCounter` togglable via settings or shortcut.

### Story 1.11: Hub Navigation Tooltips
**As a** new player,
**I want** tooltips on navigation arrows,
**So that** I know where they lead before clicking.

- Add tooltips to Hub navigation arrows.

### Story 1.12: Zone Transitions
**As a** player,
**I want** smooth transitions between rooms,
**So that** moving around the house feels seamless.

- Smooth out transition between "Office" and "Living Room".

### Story 1.13: Refactor Magic Numbers
**As a** developer,
**I want** to move parallax constants to a config,
**So that** I can easily tweak the feel later.

- Refactor magic numbers in `HubView`.

### Story 1.14: Persistence Type Safety
**As a** developer,
**I want** full type safety in the persistence layer,
**So that** I can avoid runtime errors.

- Remove `as any` casting in `persistence.ts`.

## Epic 2: Interface Consistency
Ensure the interface is consistent across all views and doesn't have visual glitches or missing controls.

### Story 2.1: Window Controls in Bocal
**As a** player,
**I want** to be able to minimize, maximize, or close the app from the Bocal view,
**So that** I don't have to switch views to manage the window.

- Add window controls (min/max/close) to Bocal View.

### Story 2.2: Baking UI Layering
**As a** player,
**I want** the baking interface to be clearly visible without other UI elements overlapping it,
**So that** I can focus on the cooking minigame.

- Fix Z-index/layering issues where Inventory/Shop buttons overlap the Baking UI.

### Story 2.3: Baking UI Refinement
**As a** player,
**I want** the baking interface to be compact and well-designed,
**So that** it feels integrated and doesn't obscure too much of the screen.

- Reduce the size of the Baking UI and refine its styling.

## Epic 3: Widget Overhaul
Improve the Widget mode's usability and aesthetics.

### Story 3.1: Widget Layout Stability
**As a** user,
**I want** the widget layout to remain stable regardless of text length,
**So that** buttons like 'maximize' don't shift or become unclickable.

- Fix layout shifting issues caused by long recipe sentences in Widget mode.

### Story 3.2: Pomodoro Circular UI
**As a** user,
**I want** a beautiful circular progress bar for the Pomodoro timer,
**So that** it looks modern and I can easily see my progress at a glance.

- Replace text timer with a circular "camembert" progress bar.

## Epic 4: Advanced Settings
Give players more control over their experience, including performance and personalization.

### Story 4.1: Manual Weather Control
**As a** player,
**I want** to manually set the weather (day/night/rain),
**So that** I can control the mood of the app regardless of real time.

- Add weather override toggle in Settings.

### Story 4.2: Global Parallax Toggle
**As a** player prone to motion sickness,
**I want** to disable the parallax effect globally,
**So that** the app is comfortable for me to use.

- Add "Enable Parallax" toggle in Settings.

### Story 4.3: Widget Transparency Toggle
**As a** player,
**I want** to toggle the glass transparency effect of the widget,
**So that** it is readable against any desktop background.

- Add "Widget Transparency" toggle in Settings.

### Story 4.4: Radio Station Manager
**As a** music lover,
**I want** to select which radio stations appear in the rotation,
**So that** I only listen to genres I like.

- Add a list of available radios with checkboxes in Settings.
