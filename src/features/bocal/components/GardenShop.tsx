import React from 'react'
import { usePlantStore, CATALOG } from '../../../store/plantStore'
import { X, ShoppingBag } from 'lucide-react'
import { motion, AnimatePresence } from 'framer-motion'

interface GardenShopProps {
    isOpen: boolean
    onClose: () => void
}

export const GardenShop: React.FC<GardenShopProps> = ({ isOpen, onClose }) => {
    const addInventoryItem = usePlantStore(state => state.addInventoryItem)
    const inventory = usePlantStore(state => state.inventory)

    if (!isOpen) return null

    return (
        <AnimatePresence>
            <motion.div 
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4"
                onClick={onClose}
            >
                <div 
                    className="bg-[#fcf8f2] w-full max-w-2xl rounded-xl shadow-2xl overflow-hidden border-2 border-[#e5d5c0]"
                    onClick={e => e.stopPropagation()}
                >
                    {/* Header */}
                    <div className="bg-[#e5d5c0] p-4 flex justify-between items-center text-[#5c4d3c]">
                        <div className="flex items-center gap-2">
                            <ShoppingBag className="w-5 h-5" />
                            <h2 className="font-bold text-lg">Garden Shop (Free)</h2>
                        </div>
                        <button onClick={onClose} className="p-1 hover:bg-[#d4c3b0] rounded">
                            <X className="w-5 h-5" />
                        </button>
                    </div>

                    {/* Content */}
                    <div className="p-6 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                        {CATALOG.map(item => (
                            <div 
                                key={item.id}
                                className="bg-white p-4 rounded-lg shadow-sm border border-gray-100 flex flex-col items-center gap-3 transition-transform hover:scale-105"
                            >
                                <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center text-3xl">
                                    {item.type === 'seed' ? '🌱' : item.type === 'pot' ? '🏺' : '🟫'}
                                </div>
                                <div className="text-center">
                                    <h3 className="font-semibold text-gray-800">{item.name}</h3>
                                    <p className="text-xs text-gray-500 uppercase">{item.type}</p>
                                </div>
                                    <button
                                        onClick={() => addInventoryItem(item.id)}
                                        className="w-full py-2 bg-[#8cba80] text-white rounded-md font-medium hover:bg-[#7aa66f] active:scale-95 transition"
                                    >
                                        Take (Free)
                                    </button>
                            </div>
                        ))}
                    </div>

                    {/* Footer / Inventory Preview */}
                    <div className="bg-[#f0e6d6] p-3 text-xs text-center text-[#8c7b66]">
                        You can take as many seeds and pots as you like! Creativity is free.
                    </div>
                </div>
            </motion.div>
        </AnimatePresence>
    )
}
