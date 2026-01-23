import React, { useState } from 'react'
import { usePlantStore } from '../../../store/plantStore'
import { Droplets, Scissors, Trash2, X, Shovel, Sprout, ShoppingBag } from 'lucide-react'
import { motion, AnimatePresence } from 'framer-motion'

interface CareWindowProps {
    plantId: string
    onClose: () => void
}

export const CareWindow: React.FC<CareWindowProps> = ({ plantId, onClose }) => {
    // Hooks MUST be at top level
    const plants = usePlantStore(state => state.plants)
    const inventory = usePlantStore(state => state.inventory)
    const waterPlant = usePlantStore(state => state.waterPlant)
    const prunePlant = usePlantStore(state => state.prunePlant)
    const pickupPlant = usePlantStore(state => state.pickupPlant) // Logic to put back in inventory
    const interactWithPlant = usePlantStore(state => state.interactWithPlant)

    // State for seed selection sub-menu
    const [showSeedSelector, setShowSeedSelector] = useState(false)

    // Find Logic
    const plant = plants.find(p => p.id === plantId)

    if (!plant) return null

    // -- Handlers --
    
    const handleWater = (e: React.MouseEvent) => {
        e.stopPropagation()
        waterPlant(plantId)
    }

    const handlePrune = (e: React.MouseEvent) => {
        e.stopPropagation()
        prunePlant(plantId)
    }

    const handlePickup = (e: React.MouseEvent) => {
        e.stopPropagation()
        pickupPlant(plantId)
        onClose()
    }

    const handleAddSoil = (e: React.MouseEvent) => {
        e.stopPropagation()
        // Check if we have soil
        const soil = inventory.find(i => i.type === 'soil')
        if (soil) {
            interactWithPlant(plantId, soil.id)
        } else {
            alert("You need Soil! Visit the Shop.")
        }
    }

    const handlePlantSeed = (e: React.MouseEvent, seedId: string) => {
        e.stopPropagation()
        interactWithPlant(plantId, seedId)
        onClose()
    }

    // -- Derived State --
    const hasSoil = inventory.some(i => i.type === 'soil')
    const availableSeeds = inventory.filter(i => i.type === 'seed')

    // -- Render Content based on Stage --

    const renderHeader = () => {
        if (plant.stage === -2) return <h4 className="font-bold text-amber-800">Empty Pot</h4>
        if (plant.stage === -1) return <h4 className="font-bold text-amber-900">Pot with Soil</h4>
        return (
            <div>
                <h4 className="font-bold text-emerald-800 capitalize">{plant.species}</h4>
                <span className="text-xs text-emerald-600">Stage {plant.stage}/4</span>
            </div>
        )
    }

    // Empty Pot View (-2)
    if (plant.stage === -2) {
        return (
             <AnimatePresence>
                <motion.div
                    initial={{ scale: 0.8, opacity: 0 }}
                    animate={{ scale: 1, opacity: 1 }}
                    exit={{ scale: 0.8, opacity: 0 }}
                    // ADDED pointer-events-auto HERE
                    className="absolute z-50 bg-[#fffbf0] p-4 rounded-xl shadow-xl border border-amber-200 flex flex-col gap-3 w-48 pointer-events-auto"
                    style={{ left: plant.position.x + 50, top: plant.position.y - 50 }}
                    onClick={e => e.stopPropagation()}
                >
                    <div className="flex justify-between items-start">
                        {renderHeader()}
                        <button onClick={onClose} className="p-1 hover:bg-amber-100 rounded-full"><X className="w-3 h-3 text-amber-800" /></button>
                    </div>
                    
                    <p className="text-xs text-amber-700">Needs soil to grow life.</p>

                    <button 
                        onClick={handleAddSoil}
                        disabled={!hasSoil}
                        className="flex items-center justify-center gap-2 p-2 rounded-lg bg-amber-100 text-amber-800 hover:bg-amber-200 disabled:opacity-50 transition font-bold text-xs"
                    >
                        <Shovel className="w-4 h-4" />
                        <span>Add Soil</span>
                    </button>

                    <button onClick={handlePickup} className="text-[10px] text-amber-600 underline hover:text-amber-800 text-center mt-1">
                        Put back in bag
                    </button>
                </motion.div>
            </AnimatePresence>
        )
    }

    // Soiled Pot View (-1)
    if (plant.stage === -1) {
        return (
             <AnimatePresence>
                <motion.div
                    initial={{ scale: 0.8, opacity: 0 }}
                    animate={{ scale: 1, opacity: 1 }}
                    exit={{ scale: 0.8, opacity: 0 }}
                    // ADDED pointer-events-auto HERE
                    className="absolute z-50 bg-[#fffbf0] p-4 rounded-xl shadow-xl border border-amber-200 flex flex-col gap-3 w-48 pointer-events-auto"
                    style={{ left: plant.position.x + 50, top: plant.position.y - 50 }}
                    onClick={e => e.stopPropagation()}
                >
                    <div className="flex justify-between items-start">
                        {renderHeader()}
                        <button onClick={onClose} className="p-1 hover:bg-amber-100 rounded-full"><X className="w-3 h-3 text-amber-800" /></button>
                    </div>

                    {!showSeedSelector ? (
                        <>
                            <p className="text-xs text-amber-700">Ready for a seed.</p>
                             <button 
                                onClick={(e) => { e.stopPropagation(); setShowSeedSelector(true) }}
                                disabled={availableSeeds.length === 0}
                                className="flex items-center justify-center gap-2 p-2 rounded-lg bg-emerald-100 text-emerald-800 hover:bg-emerald-200 disabled:opacity-50 transition font-bold text-xs"
                            >
                                <Sprout className="w-4 h-4" />
                                <span>Plant Seed</span>
                            </button>
                        </>
                    ) : (
                        <div className="flex flex-col gap-1 max-h-32 overflow-y-auto">
                            {availableSeeds.map(seed => (
                                <button
                                    key={seed.id}
                                    onClick={(e) => handlePlantSeed(e, seed.id)}
                                    className="text-left text-xs p-2 hover:bg-emerald-50 rounded border border-transparent hover:border-emerald-200 flex items-center gap-2"
                                >
                                    <span>🌱</span>
                                    <span>{seed.name}</span>
                                </button>
                            ))}
                              <button onClick={() => setShowSeedSelector(false)} className="text-[10px] text-gray-400 mt-2">Cancel</button>
                        </div>
                    )}

                     <button onClick={handlePickup} className="text-[10px] text-amber-600 underline hover:text-amber-800 text-center mt-1">
                        Put back in bag
                    </button>
                </motion.div>
            </AnimatePresence>
        )
    }

    // Normal Plant View (0 to 4)
    return (
        <AnimatePresence>
            <motion.div
                initial={{ scale: 0.8, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                exit={{ scale: 0.8, opacity: 0 }}
                // ADDED pointer-events-auto HERE (already was here from previous fix, ensuring it stays)
                className="absolute z-50 bg-white/95 backdrop-blur-sm p-4 rounded-xl shadow-xl border border-emerald-100 flex flex-col gap-3 w-48 pointer-events-auto"
                style={{ 
                    left: plant.position.x + 50, // Offset to right
                    top: plant.position.y - 50   // Offset up
                }}
                onClick={e => e.stopPropagation()} // Prevent click through
            >
                {/* Header */}
                <div className="flex justify-between items-start">
                    {renderHeader()}
                    <button onClick={onClose} className="p-1 hover:bg-gray-100 rounded-full">
                        <X className="w-3 h-3 text-gray-400" />
                    </button>
                </div>

                {/* Status Bar */}
                <div className="w-full bg-gray-100 h-1.5 rounded-full overflow-hidden">
                    <div 
                        className={`h-full transition-all duration-500 ${plant.isThirsty ? 'bg-amber-400' : 'bg-blue-400 w-full'}`}
                        style={{ width: plant.isThirsty ? '30%' : '100%' }}
                    />
                </div>
                <div className="text-[10px] text-gray-400 text-center">
                    {plant.isThirsty ? 'Needs water!' : 'Happy & Hydrated'}
                </div>

                {/* Actions */}
                <div className="grid grid-cols-3 gap-2 mt-1">
                    <button 
                        onClick={handleWater} // Handlers must stop propagation
                        title="Water"
                        className="flex flex-col items-center justify-center p-2 rounded-lg bg-blue-50 text-blue-500 hover:bg-blue-100 transition"
                    >
                        <Droplets className="w-5 h-5" />
                        <span className="text-[10px] mt-1">Water</span>
                    </button>

                    <button 
                        onClick={handlePrune}
                        title="Prune"
                        disabled={plant.stage < 3}
                        className="flex flex-col items-center justify-center p-2 rounded-lg bg-amber-50 text-amber-600 hover:bg-amber-100 disabled:opacity-50 disabled:cursor-not-allowed transition"
                    >
                        <Scissors className="w-5 h-5" />
                        <span className="text-[10px] mt-1">Prune</span>
                    </button>

                    <button 
                        onClick={handlePickup}
                        title="Store"
                        className="flex flex-col items-center justify-center p-2 rounded-lg bg-gray-50 text-gray-500 hover:bg-gray-100 transition"
                    >
                        <ShoppingBag className="w-5 h-5" />
                        <span className="text-[10px] mt-1">Store</span>
                    </button>
                </div>
            </motion.div>
        </AnimatePresence>
    )
}
