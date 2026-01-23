import React from 'react'
import { usePlantStore, PlantSpecies } from '../../../store/plantStore'
import { Book, X } from 'lucide-react'
import { motion, AnimatePresence } from 'framer-motion'

interface HerbariumProps {
    isOpen: boolean
    onClose: () => void
}

const SPECIES_INFO: Record<PlantSpecies, { title: string, desc: string, unlockedDesc: string }> = {
    monstera: {
        title: "Monstera Deliciosa",
        desc: "???? ??????",
        unlockedDesc: "The 'Swiss Cheese Plant'. Loves bright indirect light. A symbol of ambition and rapid growth."
    },
    succulent: {
        title: "Echeveria Elegans",
        desc: "???? ??????",
        unlockedDesc: "The 'Mexican Snowball'. Stores water in its leaves. Represents resilience in dry times."
    },
    fern: {
        title: "Boston Fern",
        desc: "???? ??????",
        unlockedDesc: "Nephrolepis exaltata. Thrives in humidity. Its ancient lineage predates the dinosaurs."
    }
}

export const Herbarium: React.FC<HerbariumProps> = ({ isOpen, onClose }) => {
    const herbarium = usePlantStore(state => state.herbarium)

    if (!isOpen) return null

    return (
        <AnimatePresence>
            <motion.div 
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: 20 }}
                className="fixed inset-0 bg-black/60 z-50 flex items-center justify-center p-4"
                onClick={onClose}
            >
                {/* Book Container - Chinese Ink Style */}
                <div 
                    className="bg-[#f2f0e9] w-full max-w-3xl aspect-[1.4] rounded items-stretch shadow-2xl flex overflow-hidden relative"
                    style={{ 
                        backgroundImage: `url("https://www.transparenttextures.com/patterns/rice-paper.png")`, // Placeholder texture
                        boxShadow: '0 0 50px rgba(0,0,0,0.5)'
                    }}
                    onClick={e => e.stopPropagation()}
                >
                     <button onClick={onClose} className="absolute top-4 right-4 z-10 p-2 hover:bg-black/5 rounded-full">
                        <X className="w-6 h-6 text-gray-800" />
                    </button>

                    {/* Book Binding/Crease */}
                    <div className="absolute left-1/2 top-0 bottom-0 w-8 -ml-4 bg-gradient-to-r from-transparent via-black/10 to-transparent z-10 mix-blend-multiply" />

                    {/* Left Page - Index */}
                    <div className="flex-1 p-12 border-r border-[#dcd8cc] flex flex-col font-serif">
                        <div className="text-center mb-12">
                            <Book className="w-8 h-8 mx-auto mb-4 text-gray-800" />
                            <h2 className="text-3xl font-bold tracking-widest text-gray-900" style={{ fontFamily: 'Times New Roman, serif' }}>
                                HERBARIUM
                            </h2>
                            <p className="text-sm text-gray-500 italic mt-2">Botanical Collection</p>
                        </div>
                        
                        <div className="space-y-4">
                            {(Object.keys(SPECIES_INFO) as PlantSpecies[]).map(species => {
                                const isUnlocked = herbarium[species]
                                return (
                                    <div key={species} className="flex items-center gap-4 text-gray-800 opacity-80 hover:opacity-100 cursor-pointer group">
                                        <div className={`w-8 h-8 flex items-center justify-center border border-gray-400 rounded-sm ${isUnlocked ? 'bg-[#8cba80]' : 'bg-gray-200'}`}>
                                            {isUnlocked ? '✓' : ''}
                                        </div>
                                        <span className={`text-lg border-b border-transparent group-hover:border-gray-800 transition ${isUnlocked ? 'font-bold' : 'text-gray-400'}`}>
                                            {isUnlocked ? SPECIES_INFO[species].title : '???? ??????'}
                                        </span>
                                    </div>
                                )
                            })}
                        </div>
                    </div>

                    {/* Right Page - Detail */}
                    <div className="flex-1 p-12 flex flex-col items-center justify-center">
                        <p className="text-gray-400 italic text-center">
                            Select a plant on the left... (Not implemented in V1, showing static view for now)
                        </p>
                        
                        {/* 
                            Visual Placeholder for the "Ink" aesthetic logic 
                            Ideally, clicking left side updates right side.
                            For V1 let's just show a grid of stamps.
                        */}
                         <div className="grid grid-cols-2 gap-8 mt-8 opacity-50">
                            <div className="w-24 h-32 border border-gray-400 bg-black/5 flex items-center justify-center">?</div>
                            <div className="w-24 h-32 border border-gray-400 bg-black/5 flex items-center justify-center">?</div>
                         </div>
                    </div>
                </div>
            </motion.div>
        </AnimatePresence>
    )
}
