import React from 'react'
import { Cat } from 'lucide-react'

export const KitchenView: React.FC = () => {
    return (
        <div className="flex flex-col items-center justify-center animate-in fade-in zoom-in duration-500 text-center opacity-50">
            <div className="p-8 rounded-full bg-white/5 mb-6">
                <Cat size={64} className="opacity-50" />
            </div>
            <h2 className="text-2xl font-light tracking-widest uppercase mb-2">La Cuisine</h2>
            <p className="text-sm">Le repaire de Chips • Bientôt disponible</p>
        </div>
    )
}
