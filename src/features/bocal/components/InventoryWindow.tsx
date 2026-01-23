import React, { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { usePlantStore, InventoryItem, CATALOG, ItemCategory } from '@/store/plantStore'
import { X, Backpack, Sprout, Hammer, Pizza, Info } from 'lucide-react'

interface InventoryWindowProps {
    isOpen: boolean
    onClose: () => void
}

type Tab = 'all' | 'plant' | 'pot' | 'soil' | 'consumable'

export const InventoryWindow: React.FC<InventoryWindowProps> = ({ isOpen, onClose }) => {
    const inventory = usePlantStore(state => state.inventory)
    const placeItem = usePlantStore(state => state.placeItem)
    const [activeTab, setActiveTab] = useState<Tab>('all')
    const [selectedItemId, setSelectedItemId] = useState<string | null>(null)

    if (!isOpen) return null

    // Filter Items
    const filteredItems = inventory.filter(item => {
        if (activeTab === 'all') return true
        // Map catalog type to Tab? 
        // CATALOG types: 'seed', 'pot', 'soil', 'pastry'
        // Tab types: 'plant' (seed), 'pot' (pot), 'soil' (soil), 'consumable' (pastry)
        if (activeTab === 'plant') return item.type === 'seed'
        if (activeTab === 'pot') return item.type === 'pot'
        if (activeTab === 'soil') return item.type === 'soil'
        if (activeTab === 'consumable') return item.type === 'pastry'
        return true
    })

    const handleAction = (item: InventoryItem) => {
        if (item.type === 'pot') {
            // Place it in the center for now
            // In the future: "Drag from inventory"
            placeItem(item.id, { x: window.innerWidth/2, y: window.innerHeight/2 })
            onClose()
        } else if (item.type === 'pastry') {
            alert('Crunch! Delicious.') // TODO: Sound & Particle
            usePlantStore.getState().removeInventoryItem(item.id, 1)
        }
    }

    return (
        <AnimatePresence>
            <motion.div 
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: 20 }}
                className="fixed inset-0 bg-black/60 z-50 flex items-center justify-center p-4"
                onClick={onClose}
            >
                <div 
                    className="bg-[#fffbf0] w-full max-w-4xl h-[600px] rounded-xl shadow-2xl flex overflow-hidden ring-4 ring-[#5c4d3c]"
                    onClick={e => e.stopPropagation()}
                >
                    {/* Sidebar / Tabs */}
                    <div className="w-20 bg-[#e5d5c0] flex flex-col items-center py-6 gap-6 text-[#5c4d3c]">
                         <Backpack className="w-8 h-8 mb-4 text-[#8c7b66]" />
                         
                         <button onClick={() => setActiveTab('all')} className={`p-3 rounded-xl transition ${activeTab === 'all' ? 'bg-[#fffbf0] shadow-md' : 'hover:bg-[#d4c3b0]'}`}>
                            <div className="font-bold text-xs">ALL</div>
                         </button>
                         <button onClick={() => setActiveTab('plant')} className={`p-3 rounded-xl transition ${activeTab === 'plant' ? 'bg-[#fffbf0] shadow-md' : 'hover:bg-[#d4c3b0]'}`}>
                            <Sprout className="w-6 h-6" />
                         </button>
                         <button onClick={() => setActiveTab('pot')} className={`p-3 rounded-xl transition ${activeTab === 'pot' ? 'bg-[#fffbf0] shadow-md' : 'hover:bg-[#d4c3b0]'}`}>
                            <div className="text-xl">🏺</div>
                         </button>
                         <button onClick={() => setActiveTab('consumable')} className={`p-3 rounded-xl transition ${activeTab === 'consumable' ? 'bg-[#fffbf0] shadow-md' : 'hover:bg-[#d4c3b0]'}`}>
                            <Pizza className="w-6 h-6" />
                         </button>
                         
                         <div className="flex-1" />
                         <button onClick={onClose} className="p-2 bg-[#c9bba6] rounded-full hover:bg-[#b0a08d]">
                            <X className="w-6 h-6 text-white" />
                         </button>
                    </div>

                    {/* Main Grid */}
                    <div className="flex-1 p-8 overflow-y-auto bg-[#faf7f2]">
                        <h2 className="text-2xl font-serif font-bold text-[#5c4d3c] mb-6 capitalize">{activeTab} Items</h2>
                        
                        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
                            {filteredItems.map(item => (
                                <div 
                                    key={item.id}
                                    onClick={() => setSelectedItemId(item.id)}
                                    className={`bg-white p-4 rounded-xl border-2 transition-all cursor-pointer relative group flex flex-col items-center gap-3
                                        ${selectedItemId === item.id ? 'border-emerald-500 shadow-lg scale-105' : 'border-[#e5e0d8] hover:border-emerald-300'}
                                    `}
                                >
                                    <div className="absolute top-2 right-2 bg-[#e5d5c0] text-[#5c4d3c] text-xs font-bold px-2 py-1 rounded-full">
                                        x{item.count}
                                    </div>

                                    <div className="w-20 h-20 bg-gray-50 rounded-full flex items-center justify-center text-4xl shadow-inner">
                                        {item.type === 'seed' ? '🌱' : item.type === 'pot' ? '🏺' : item.type === 'soil' ? '🟫' : '🥐'}
                                    </div>
                                    
                                    <div className="text-center w-full">
                                        <h3 className="font-bold text-gray-800 truncate">{item.name}</h3>
                                        <p className="text-[10px] text-gray-400 uppercase tracking-widest">{item.type}</p>
                                    </div>

                                    {/* Action Button (Visible on Hover or Select) */}
                                    {selectedItemId === item.id && (
                                        <motion.div 
                                            initial={{ opacity: 0, height: 0 }}
                                            animate={{ opacity: 1, height: 'auto' }}
                                            className="w-full pt-2"
                                        >
                                            <button 
                                                onClick={(e) => {
                                                    e.stopPropagation()
                                                    handleAction(item)
                                                }}
                                                className="w-full py-1.5 bg-emerald-600 text-white rounded-lg text-sm font-bold shadow-md hover:bg-emerald-500 active:scale-95 transition"
                                            >
                                                {item.type === 'pot' ? 'Place' : item.type === 'pastry' ? 'Eat' : 'Inspect'}
                                            </button>
                                        </motion.div>
                                    )}
                                </div>
                            ))}
                        </div>

                        {filteredItems.length === 0 && (
                            <div className="w-full h-64 flex flex-col items-center justify-center text-gray-400 opacity-50">
                                <Backpack className="w-16 h-16 mb-4" />
                                <p>This pocket is empty.</p>
                            </div>
                        )}
                    </div>

                    {/* Details Panel (Right Side - Optional or Bottom) */}
                    {selectedItemId && (() => {
                        const item = inventory.find(i => i.id === selectedItemId)
                        if (!item) return null
                        return (
                            <div className="w-72 bg-white border-l border-[#e5e0d8] p-6 flex flex-col items-center shadow-xl z-10">
                                <div className="w-32 h-32 bg-[#faf7f2] rounded-full flex items-center justify-center text-6xl mb-6 shadow-inset border-4 border-white shadow-lg">
                                    {item.type === 'seed' ? '🌱' : item.type === 'pot' ? '🏺' : item.type === 'soil' ? '🟫' : '🥐'}
                                </div>
                                
                                <h2 className="text-xl font-bold text-center text-gray-800 mb-2">{item.name}</h2>
                                <p className="text-center text-gray-500 text-sm mb-6 leading-relaxed italic">
                                    "{item.description}"
                                </p>

                                <div className="w-full bg-[#fcf8f2] rounded-lg p-4 border border-[#f0e6d6] mb-auto">
                                    <div className="flex items-center gap-2 mb-2 text-[#8c7b66] text-xs font-bold uppercase tracking-wider">
                                        <Info className="w-3 h-3" />
                                        <span>Stats</span>
                                    </div>
                                    <p className="text-emerald-700 font-mono text-sm">
                                        {item.funnyStat || "Mystery: 100%"}
                                    </p>
                                </div>

                                <div className="text-xs text-center text-gray-300 mt-4">
                                    Item ID: {item.id}
                                </div>
                            </div>
                        )
                    })()}
                </div>
            </motion.div>
        </AnimatePresence>
    )
}
