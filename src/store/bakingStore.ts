import { create } from 'zustand';
import { Recipe, RECIPES, RecipePhase } from '../data/recipes';

interface BakingState {
    currentRecipe: Recipe | null;
    currentPhaseIndex: number;
    isBaking: boolean;
    timeRemaining: number;

    // Actions
    selectRecipe: (recipeId: string) => void;
    startPhase: () => void;
    pausePhase: () => void;
    resetPhase: () => void;
    completePhase: () => void;
    tickTimer: () => void;
    getCurrentPhase: () => RecipePhase | null;
}

export const useBakingStore = create<BakingState>((set, get) => ({
    currentRecipe: null,
    currentPhaseIndex: 0,
    isBaking: false,
    timeRemaining: 25 * 60, // Default 25 min in seconds

    selectRecipe: (recipeId) => {
        const recipe = RECIPES.find(r => r.id === recipeId);
        if (recipe) {
            set({
                currentRecipe: recipe,
                currentPhaseIndex: 0,
                isBaking: false,
                timeRemaining: recipe.phases[0].duration * 60
            });
        }
    },

    startPhase: () => set({ isBaking: true }),

    pausePhase: () => set({ isBaking: false }),

    resetPhase: () => {
        const { currentRecipe, currentPhaseIndex } = get();
        if (currentRecipe) {
            set({
                isBaking: false,
                timeRemaining: currentRecipe.phases[currentPhaseIndex].duration * 60
            });
        }
    },

    completePhase: () => {
        const { currentRecipe, currentPhaseIndex } = get();
        if (currentRecipe) {
            const nextIndex = currentPhaseIndex + 1;
            if (nextIndex < currentRecipe.phases.length) {
                // Next phase available
                set({
                    currentPhaseIndex: nextIndex,
                    isBaking: false,
                    timeRemaining: currentRecipe.phases[nextIndex].duration * 60
                });
            } else {
                // Recipe complete!
                set({
                    isBaking: false,
                    timeRemaining: 0,
                    // TODO: Trigger a global 'Recipe Complete' event or visual
                });
            }
        }
    },

    tickTimer: () => {
        const { isBaking, timeRemaining } = get();
        if (isBaking && timeRemaining > 0) {
            set({ timeRemaining: timeRemaining - 1 });
        } else if (isBaking && timeRemaining === 0) {
            get().completePhase();
        }
    },

    getCurrentPhase: () => {
        const { currentRecipe, currentPhaseIndex } = get();
        if (!currentRecipe) return null;
        return currentRecipe.phases[currentPhaseIndex] || null;
    }
}));
