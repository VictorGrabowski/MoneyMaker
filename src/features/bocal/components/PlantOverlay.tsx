import React, { useState } from 'react'
import { motion } from 'framer-motion'
import { usePlantStore, PlantInstance, PlantStage, PlantSpecies } from '../../../store/plantStore'
import { CareWindow } from './CareWindow' // Will create next

const getPlantEmoji = (plant: PlantInstance) => {
    if (plant.stage === -2) return '🏺'
    if (plant.stage === -1) return '🟫' // Soil in pot look 
    
    // Growth Stages
    if (plant.species === 'monstera') return ['🌱', '🌿', '🍃', '🪴', '🌴'][plant.stage] || '🌿'
    if (plant.species === 'succulent') return ['🌱', '🌵', '🌵', '🌵', '🌵'][plant.stage] || '🌵'
    return '🌱'
}

export const PlantOverlay: React.FC = () => {
    const plants = usePlantStore(state => state.plants)
    const movePlant = usePlantStore(state => state.movePlant)
    
    // Care Window State
    const [selectedPlantId, setSelectedPlantId] = useState<string | null>(null)

    const handleDragEnd = (plant: PlantInstance, info: any) => {
        // info.point is relative to viewport, but we might want relative to container
        // For simplicity in a full-screen overlay, we can track delta or use `x/y` from style?
        // Framer Motion `drag` modifies the transform. To Save, we need the final position.
        // A better approach for "Save Position" is to use `onDragEnd` and read the element's position, 
        // OR updates state on every drag (perf heavy).
        // Let's assume the Plants utilize `layout` prop or we just let Framer handle the visual pos
        // and only update store when "dropping".
        
        // Actually, for free positioning, let's use the visual position provided by Framer if possible, 
        // or just local state. Since `plants` state update triggers re-render, we need to be careful.
        
        // Simplified V1: We'll use a `dragListener={false}` approach or similar if we want a separate "Edit Mode".
        // But the requirement is "Drag Anywhere".
        // We will default to NOT updating store on every frame, but on drag end.
        // Getting exact XY from `info` is tricky without a ref to the container.
        
        // Let's assume the overlay is 100vw/100vh.
        // We will update with `info.point.x` and `info.point.y`.
        movePlant(plant.id, info.point.x, info.point.y)
    }

    return (
        <div className="absolute inset-0 z-30 pointer-events-none overflow-hidden">
            {/* 
                pointer-events-none allows clicking through to Bocal/Physics below.
                We need pointer-events-auto ONLY on the plants.
            */}
            
            {plants.map(plant => (
                <motion.div
                    key={plant.id}
                    drag
                    dragMomentum={false} // Precise placement
                    onDragEnd={(e, info) => handleDragEnd(plant, info)}
                    initial={{ x: plant.position.x, y: plant.position.y }}
                    // Use style x/y to prevent re-render jumps if we sync state? 
                    // Actually, if we update store onDragEnd, we should update `x/y` or `style`.
                    // To avoid conflict between framer's internal state and react state, key helps.
                    style={{ position: 'absolute', x: plant.position.x, y: plant.position.y }}
                    
                    className="cursor-grab active:cursor-grabbing pointer-events-auto"
                    onClick={() => setSelectedPlantId(plant.id)}
                >
                    <div className="text-4xl filter drop-shadow-lg select-none cursor-pointer hover:scale-110 transition-transform">
                        {/* 
                            Visual Representation 
                            TODO: Replace with actual images from `art-prompts-plants.md`.
                            Using Emojis for now.
                        */}
                        {getPlantEmoji(plant)}
                        
                        {/* Water Indicator */}
                        {plant.isThirsty && (
                            <div className="absolute -top-2 -right-2 bg-blue-500 text-white text-[10px] rounded-full w-4 h-4 flex items-center justify-center animate-bounce">
                                💧
                            </div>
                        )}
                    </div>
                </motion.div>
            ))}

            {selectedPlantId && (
                <CareWindow 
                    plantId={selectedPlantId} 
                    onClose={() => setSelectedPlantId(null)} 
                />
            )}
        </div>
    )
}
