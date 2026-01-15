import React, { useState, useEffect } from 'react'
import imgDayWithPastry from '../../assets/hub/salon_day_with_pastry.png'
import imgDayEmpty from '../../assets/hub/salon_day.png'
import imgNight from '../../assets/hub/salon_night.png'
import { useWeatherStore } from '../../store/weatherStore'
import { useSalaryStore } from '../../store/salaryStore'
import { useCookingStore } from '../../store/cookingStore'
import { GrimoireView } from '../cooking/GrimoireView'
import { PrepStation } from '../cooking/PrepStation'

// Sub-component for Baking Timer overlay
const OvenTimer = () => {
    const { startTime, duration, checkBakingStatus, status } = useCookingStore()
    const [timeLeft, setTimeLeft] = useState("")
    const [progress, setProgress] = useState(0)

    useEffect(() => {
        if (status !== 'baking' || !startTime) return

        const interval = setInterval(() => {
            const elapsed = Date.now() - startTime
            const remaining = Math.max(0, duration - elapsed)

            // Format mm:ss
            const minutes = Math.floor(remaining / 60000)
            const seconds = Math.floor((remaining % 60000) / 1000)
            setTimeLeft(`${minutes}:${seconds.toString().padStart(2, '0')}`)
            setProgress((elapsed / duration) * 100)

            checkBakingStatus() // Trigger state change if done
        }, 1000)

        return () => clearInterval(interval)
    }, [status, startTime, duration, checkBakingStatus])

    if (status !== 'baking') return null

    return (
        <div className="absolute inset-0 flex items-center justify-center flex-col pointer-events-none">
            <div className="bg-black/60 backdrop-blur-md px-3 py-1 rounded-lg border border-orange-500/30 shadow-[0_0_15px_rgba(249,115,22,0.4)]">
                <span className="text-orange-400 font-mono font-bold text-lg animate-pulse">{timeLeft}</span>
            </div>
            <div className="w-[80%] h-1 bg-gray-700 mt-2 rounded-full overflow-hidden">
                <div
                    className="h-full bg-orange-500 transition-all duration-1000 ease-linear"
                    style={{ width: `${progress}%` }}
                />
            </div>
        </div>
    )
}

export const LivingRoomView: React.FC = () => {
    const { isDay } = useWeatherStore()
    const setViewMode = useSalaryStore(s => s.setViewMode)
    const { status, finishCooking, hasFinishedStock } = useCookingStore()

    // Local state for modals
    const [showGrimoire, setShowGrimoire] = useState(false)

    // Only show pastries background if we have finished a session and collected the reward
    const backgroundImage = isDay
        ? (hasFinishedStock ? imgDayWithPastry : imgDayEmpty)
        : imgNight

    const handleOvenClick = () => {
        if (showGrimoire || status !== 'idle' && status !== 'done') return // Prevent click through

        if (status === 'idle') {
            setShowGrimoire(true)
        } else if (status === 'done') {
            finishCooking()
        }
    }

    const isModalOpen = showGrimoire || status === 'prep'


    return (
        <div className="absolute inset-0 w-full h-full overflow-hidden">
            {/* Background Layer */}
            <div
                className="absolute inset-0 bg-cover bg-center transition-all duration-1000 ease-in-out"
                style={{
                    backgroundImage: `url(${backgroundImage})`
                }}
            />

            {/* Atmosphere Overlay */}
            <div className={`absolute inset-0 pointer-events-none transition-colors duration-[2000ms] ${isDay ? 'bg-orange-500/10 mix-blend-overlay' : 'bg-blue-900/20 mix-blend-overlay'}`} />

            {/* Content Container */}
            <div className="relative z-10 w-full h-full">

                {/* "Four" (Oven) Interaction Zone */}
                <div
                    className={`absolute bottom-[5%] right-[2%] w-[25%] h-[35%] cursor-pointer rounded-lg z-20 group outline-none focus:ring-0
                        ${isModalOpen ? 'pointer-events-none opacity-0' : 'transition-colors duration-300 opacity-100'}
                        ${status === 'idle' ? 'hover:bg-yellow-400/5 bg-transparent' : ''}
                        ${status === 'baking' ? 'hover:bg-orange-500/10 bg-transparent' : ''}
                        ${status === 'done' ? 'bg-green-400/10 shadow-[0_0_50px_rgba(74,222,128,0.4)] animate-pulse' : ''}
                    `}
                    onClick={handleOvenClick}
                    title={status === 'idle' ? "Ouvrir le Grimoire" : status === 'baking' ? "Cuisson en cours..." : "Récupérer !"}
                >
                    {/* Cooking Overlays */}
                    {status === 'baking' && <OvenTimer />}

                    {status === 'done' && (
                        <div className="absolute inset-0 flex items-center justify-center">
                            <span className="text-4xl animate-bounce drop-shadow-lg">✨🍪✨</span>
                        </div>
                    )}
                </div>

                {/* "Bocal" (Jar) Click Zone */}
                <div
                    className={`absolute bottom-[5%] left-[42.5%] w-[15%] h-[30%] cursor-pointer rounded-lg z-20 transition-colors duration-300 outline-none focus:ring-0
                        ${isModalOpen ? 'pointer-events-none opacity-0' : 'hover:bg-white/5 bg-transparent opacity-100'}
                    `}
                    onClick={() => setViewMode('bocal')}
                    title="Le Bocal"
                />
            </div>

            {/* MODALS / OVERLAYS */}
            {showGrimoire && status === 'idle' && (
                <GrimoireView onClose={() => setShowGrimoire(false)} />
            )}

            {status === 'prep' && (
                <PrepStation />
            )}
        </div>
    )
}
