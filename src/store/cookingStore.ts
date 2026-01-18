import { create } from 'zustand'

export type CookingStatus = 'idle' | 'prep' | 'baking' | 'done' | 'burnt'
export type RecipeType = 'cookie' | 'brownie' | null

interface CookingState {
    status: CookingStatus
    recipe: RecipeType

    // Prep Phase
    prepProgress: number // 0 to 100

    // Baking Phase
    startTime: number | null
    duration: number // milliseconds (e.g. 25 * 60 * 1000)

    // Completion
    quality: number // 0 to 100
    hasFinishedStock: boolean // True if we have pastries on the counter

    // Actions
    startPrep: (recipe: RecipeType) => void
    advancePrep: (amount: number) => void
    startBaking: () => void
    checkBakingStatus: () => void // Called by tick/interval
    finishCooking: () => void // Collect reward
    cancelCooking: () => void // Burn/Reset
}

// DURATIONS
const DURATION_COOKIE = 25 * 60 * 1000 // 25 Minutes
const DURATION_BROWNIE = 50 * 60 * 1000 // 50 Minutes

export const useCookingStore = create<CookingState>((set, get) => ({
    status: 'idle',
    recipe: null,
    prepProgress: 0,
    startTime: null,
    duration: DURATION_COOKIE, // Default
    quality: 100,
    hasFinishedStock: false,

    startPrep: (recipe) => set({
        status: 'prep',
        recipe,
        prepProgress: 0,
        quality: 100,
        hasFinishedStock: false
    }),

    advancePrep: (amount) => {
        const { prepProgress } = get()
        const newProgress = Math.min(100, prepProgress + amount)
        set({ prepProgress: newProgress })
    },

    startBaking: () => {
        const { recipe } = get()
        let duration = DURATION_COOKIE

        if (recipe === 'brownie') {
            duration = DURATION_BROWNIE
        }

        set({
            status: 'baking',
            startTime: Date.now(),
            duration: duration
        })
    },

    checkBakingStatus: () => {
        const { status, startTime, duration } = get()
        if (status !== 'baking' || !startTime) return

        const elapsed = Date.now() - startTime
        if (elapsed >= duration) {
            set({ status: 'done' })
            // Trigger Notification? (Side effect handled in UI)
        }
    },

    finishCooking: () => {
        // Here we would add the reward to the wallet
        set({
            status: 'idle',
            recipe: null,
            prepProgress: 0,
            startTime: null,
            hasFinishedStock: true // Pastries appear on counter now
        })
    },

    cancelCooking: () => set({
        status: 'idle',
        recipe: null,
        prepProgress: 0,
        startTime: null
    })
}))
