import React, { useEffect, useState } from 'react'
import { useCookingStore } from '../../store/cookingStore'
import { ChefHat, Check } from 'lucide-react'

export const PrepStation: React.FC = () => {
    const { startBaking, advancePrep, prepProgress, cancelCooking } = useCookingStore()
    const [step, setStep] = useState(0)

    // Simulation of steps
    const steps = [
        { name: "Ververser (Click to Pour)", emoji: "🥣" },
        { name: "Mélanger (Click to Mix)", emoji: "🥄" },
        { name: "Façonner (Click to Shape)", emoji: "🍪" }
    ]

    const handleClick = () => {
        if (prepProgress >= 100) return
        advancePrep(34) // 3 clicks to done roughly
        setStep(prev => Math.min(prev + 1, 2))
    }

    // Auto-start baking when full interactions done
    useEffect(() => {
        if (prepProgress >= 100) {
            const timeout = setTimeout(() => {
                startBaking()
            }, 1000) // 1s delay to admire work
            return () => clearTimeout(timeout)
        }
    }, [prepProgress, startBaking])

    const currentStep = steps[step] || steps[2]

    return (
        <div className="absolute inset-0 z-50 flex flex-col items-center justify-center bg-black/80 backdrop-blur-md animate-in fade-in zoom-in duration-300">

            <div className="mb-8 text-center animate-bounce">
                <ChefHat size={64} className="text-white mx-auto mb-4" />
                <h2 className="text-4xl font-bold text-white mb-2">Préparation en cours...</h2>
                <p className="text-white/60">Cliquez pour préparer la recette !</p>
            </div>

            {/* Interactive Area */}
            <button
                onClick={handleClick}
                disabled={prepProgress >= 100}
                className="w-64 h-64 bg-orange-500 rounded-full flex flex-col items-center justify-center shadow-[0_0_50px_rgba(249,115,22,0.5)] hover:scale-105 active:scale-95 transition-all cursor-pointer border-4 border-white/20 group"
            >
                <span className="text-8xl group-hover:scale-110 transition-transform duration-300 drop-shadow-lg">
                    {prepProgress >= 100 ? "✅" : currentStep.emoji}
                </span>
                <span className="mt-4 text-white font-bold uppercase tracking-widest bg-black/20 px-4 py-1 rounded-full">
                    {prepProgress >= 100 ? "Prêt !" : "Action !"}
                </span>
            </button>

            {/* Progress Bar */}
            <div className="mt-12 w-96 h-4 bg-white/10 rounded-full overflow-hidden border border-white/10">
                <div
                    className="h-full bg-gradient-to-r from-orange-400 to-yellow-400 transition-all duration-300 ease-out"
                    style={{ width: `${Math.min(100, prepProgress)}%` }}
                />
            </div>

            <button
                onClick={cancelCooking}
                className="mt-8 text-white/40 hover:text-white transition-colors text-sm hover:underline"
            >
                Annuler et jeter à la poubelle
            </button>

        </div>
    )
}
