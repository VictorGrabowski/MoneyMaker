import { create } from 'zustand'
import { persist } from 'zustand/middleware'

// --- Types ---

export type PlantStage = -2 | -1 | 0 | 1 | 2 | 3 | 4 
// -2=Empty Pot, -1=Soil, 0=Seed, 1=Sprout, 2=Young, 3=Growing, 4=Mature

export type PlantSpecies = 'monstera' | 'succulent' | 'fern'
export type ItemCategory = 'plant' | 'pot' | 'soil' | 'tool' | 'consumable'

export interface PlantInstance {
    id: string
    species: PlantSpecies | 'none' // 'none' for empty pot
    stage: PlantStage
    health: number // 0-100
    lastWatered: number // timestamp
    plantedAt: number // timestamp
    position: { x: number; y: number } 
    isThirsty: boolean
}

export interface InventoryItem {
    id: string
    type: 'seed' | 'pot' | 'soil' | 'pastry'
    name: string
    description: string
    funnyStat?: string // e.g. "Crunchiness: 11/10"
    species?: PlantSpecies
    count: number
}

// Extended Catalog with Descriptions & Stats
export const CATALOG: Omit<InventoryItem, 'count'>[] = [
    { id: 'pot_terra', type: 'pot', name: 'Terracotta Pot', description: 'A humble home for a friend.', funnyStat: 'Eco-Friendly: Yes' },
    { id: 'soil_rich', type: 'soil', name: 'Rich Soil', description: 'Smells like rain and potential.', funnyStat: 'Worms included: Maybe' },
    { id: 'seed_monstera', type: 'seed', species: 'monstera', name: 'Monstera Seed', description: 'Will take over your room.', funnyStat: 'Ego: Massive' },
    { id: 'seed_succulent', type: 'seed', species: 'succulent', name: 'Succulent Mix', description: 'Thrives on neglect.', funnyStat: 'Thirst: Low' },
    { id: 'pastry_croissant', type: 'pastry', name: 'Butter Croissant', description: 'Flaky buttery goodness.', funnyStat: 'Crumbs: Everywhere' },
]

interface PlantState {
    plants: PlantInstance[]
    inventory: InventoryItem[]
    herbarium: { [species in PlantSpecies]?: boolean }

    // Actions
    addInventoryItem: (itemId: string, count?: number) => void
    removeInventoryItem: (itemId: string, count?: number) => void
    
    // Interaction Actions
    placeItem: (itemId: string, position: { x: number, y: number }) => void // E.g. placing a pot
    interactWithPlant: (plantId: string, itemId: string) => void // E.g. adding soil/seed to a pot
    pickupPlant: (plantId: string) => void // Put back invalid/empty pot to inventory
    
    plantSeed: (seedId: string, position: { x: number, y: number }) => void // Keeping legacy for now or removing? converting to new flow.
    deletePlant: (plantId: string) => void
    movePlant: (plantId: string, x: number, y: number) => void
    waterPlant: (plantId: string) => void
    prunePlant: (plantId: string) => void
    checkGrowth: () => void
}

const GROWTH_INTERVAL_MS = 24 * 60 * 60 * 1000 
const THIRST_THRESHOLD_MS = 48 * 60 * 60 * 1000 
const generateId = () => Math.random().toString(36).substr(2, 9)

export const usePlantStore = create<PlantState>()(
    persist(
        (set, get) => ({
            plants: [],
            inventory: [],
            herbarium: {},

            addInventoryItem: (itemId, count = 1) => {
                set((state) => {
                    const existing = state.inventory.find((i) => i.id === itemId)
                    if (existing) {
                        return {
                            inventory: state.inventory.map((i) =>
                                i.id === itemId ? { ...i, count: i.count + count } : i
                            ),
                        }
                    }
                    const catalogItem = CATALOG.find(c => c.id === itemId)
                    if (!catalogItem) return state 

                    const newItem: InventoryItem = {
                        ...catalogItem,
                        count: count
                    }
                    return { inventory: [...state.inventory, newItem] }
                })
            },

            removeInventoryItem: (itemId, count = 1) => {
                set((state) => {
                    const existing = state.inventory.find((i) => i.id === itemId)
                    if (!existing || existing.count < count) return state

                    const newCount = existing.count - count
                    if (newCount <= 0) {
                        return { inventory: state.inventory.filter((i) => i.id !== itemId) }
                    }
                    return {
                        inventory: state.inventory.map((i) =>
                            i.id === itemId ? { ...i, count: newCount } : i
                        ),
                    }
                })
            },

            placeItem: (itemId, position) => {
                const state = get()
                const item = state.inventory.find(i => i.id === itemId)
                if (!item) return

                if (item.type === 'pot') {
                    get().removeInventoryItem(itemId, 1)
                    
                    const newPlant: PlantInstance = {
                        id: generateId(),
                        species: 'none',
                        stage: -2, // Empty Pot
                        health: 100,
                        lastWatered: Date.now(), // irrelevant yet
                        plantedAt: 0,
                        position,
                        isThirsty: false
                    }
                    set((s) => ({ plants: [...s.plants, newPlant] }))
                }
            },

            interactWithPlant: (plantId, itemId) => {
                const state = get()
                const plant = state.plants.find(p => p.id === plantId)
                const item = state.inventory.find(i => i.id === itemId)
                
                if (!plant || !item) return

                // Logic Flow:
                // 1. Pot -> Add Soil (-2 -> -1)
                // 2. Soiled Pot -> Add Seed (-1 -> 0)
                
                if (plant.stage === -2 && item.type === 'soil') {
                     get().removeInventoryItem(itemId, 1)
                     set(s => ({
                         plants: s.plants.map(p => p.id === plantId ? { ...p, stage: -1 } : p)
                     }))
                } else if (plant.stage === -1 && item.type === 'seed' && item.species) {
                     get().removeInventoryItem(itemId, 1)
                     set(s => ({
                         plants: s.plants.map(p => p.id === plantId ? { 
                             ...p, 
                             stage: 0, 
                             species: item.species!, 
                             plantedAt: Date.now(), 
                             lastWatered: Date.now() 
                         } : p)
                     }))
                }
            },

            pickupPlant: (plantId) => {
                // Return items to inventory based on stage?
                // For simplicity V1: If Pot/Soil, give back pot. If plant, maybe give nothing (compost).
                // Let's be generous: Give back Pot always.
                const state = get()
                const plant = state.plants.find(p => p.id === plantId)
                if(!plant) return

                get().addInventoryItem('pot_terra', 1) // Assume generic pot for now
                get().deletePlant(plantId)
            },

            plantSeed: (seedId, position) => {
                 // Deprecated / Creative Shortcut
                 // We keep it for "God Mode" logic if needed, or redirect to placeItem
                 // For the "Plant Now" button in shop that user liked, we can keep using this
                 // but correctly setting up the plant state to Stage 0 (Planted)
                 const state = get()
                 const seedItem = CATALOG.find(i => i.id === seedId)
                 if(!seedItem || seedItem.type !== 'seed') return

                 const newPlant: PlantInstance = {
                    id: generateId(),
                    species: seedItem.species!,
                    stage: 0, 
                    health: 100,
                    lastWatered: Date.now(),
                    plantedAt: Date.now(),
                    position,
                    isThirsty: false
                }
                set((s) => ({ plants: [...s.plants, newPlant] }))
            },

            deletePlant: (plantId) => {
                set((s) => ({ plants: s.plants.filter((p) => p.id !== plantId) }))
            },

            movePlant: (plantId, x, y) => {
                set((s) => ({
                    plants: s.plants.map((p) => (p.id === plantId ? { ...p, position: { x, y } } : p)),
                }))
            },

            waterPlant: (plantId) => {
                set((s) => ({
                    plants: s.plants.map((p) =>
                        p.id === plantId
                            ? { ...p, lastWatered: Date.now(), isThirsty: false, health: 100 }
                            : p
                    ),
                }))
            },

            prunePlant: (plantId) => {
                 console.log("Pruned plant", plantId)
            },

            checkGrowth: () => {
                const now = Date.now()
                set((s) => {
                    let herbariumUpdated = false
                    const newHerbarium = { ...s.herbarium }

                    const newPlants = s.plants.map((p) => {
                        if (p.stage < 0) return p // Pot/Soil don't grow

                        const msSinceWater = now - p.lastWatered
                        const isThirsty = msSinceWater > THIRST_THRESHOLD_MS
                        
                        let nextStage = p.stage
                        if (!isThirsty && p.stage < 4) {
                            const daysAlive = (now - p.plantedAt) / GROWTH_INTERVAL_MS
                            const targetStage = Math.min(4, Math.floor(daysAlive)) as PlantStage
                            if (targetStage > p.stage) {
                                nextStage = targetStage
                            }
                        }
                        
                        // Type safe check for species
                        if (nextStage === 4 && p.species !== 'none' && !s.herbarium[p.species]) {
                            newHerbarium[p.species] = true
                            herbariumUpdated = true
                        }

                        return {
                            ...p,
                            stage: nextStage,
                            isThirsty
                        }
                    })

                    return {
                        plants: newPlants,
                        herbarium: herbariumUpdated ? newHerbarium : s.herbarium
                    }
                })
            }
        }),
        {
            name: 'plant-storage',
        }
    )
)
