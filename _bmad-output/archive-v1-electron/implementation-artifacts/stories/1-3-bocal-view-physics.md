# Story 1.3: Bocal View & Physics

Status: in-progress

## Story

As a player,
I want to open the bocal view and see coins fall with satisfying physics,
so that I can feel my money becoming "real" and tangible.

## Acceptance Criteria

1. **Bocal Access**: A button/zone in the Hub that switches to the "Bocal View".
2. **Physics Engine**: Integration of a 2D physics engine (e.g., Matter.js) for coins.
3. **Coin Generation**: Coins fall into the bocal whenever a certain amount is earned (e.g., every 0.01€).
4. **Collision & Stacking**: Coins should stack realistically and interact with each other.
5. **Aesthetics**: Premium visual polish for coins (gold/silver reflections) and the glass bocal.

## Tasks / Subtasks

- [ ] **Physics Setup**: Install and configure Matter.js [/]
- [ ] **Bocal UI**: Create `src/components/BocalView.tsx` with a glass-like container [ ]
- [ ] **Coin Logic**: Create a `Coin` entity and generator logic [ ]
- [ ] **Store Integration**: Update `salaryStore.ts` to trigger coin spawns [ ]
- [ ] **Polish**: Add sound effects and visual juice [ ]

## Dev Notes

- **Performance**: Matter.js bodies should be limited to avoid lag after thousands of coins.
- **Optimization**: Use a simple boundary and maybe "sleep" inactive coins.
- **Scaling**: Coin value should probably vary (cent coins, euro coins) to avoid over-cluttering.

### References

- [Architecture: Physics Implementation](file:///c:/Users/v.grabowski/OneDrive - Betclic Group/Documents/DEV/PROJETS/PERSO/MoneyMaker/_bmad-output/game-architecture.md#Technical-Design)
