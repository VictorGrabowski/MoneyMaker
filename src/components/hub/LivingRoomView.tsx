import React, { useState, useEffect } from 'react'
import imgDayWithPastry from '../../assets/hub/salon_day_with_pastry.png'
import imgDayEmpty from '../../assets/hub/salon_day.png'
import imgNight from '../../assets/hub/salon_night.png'
import { useWeatherStore } from '../../store/weatherStore'
import { useSalaryStore } from '../../store/salaryStore'
import { useCookingStore } from '../../store/cookingStore'
import { GrimoireView } from '../cooking/GrimoireView'
import { PrepStation } from '../cooking/PrepStation'
import { Coffee, Cat } from 'lucide-react'

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
    const [isCoffeeMachineOn, setIsCoffeeMachineOn] = useState(false)
    const [showChipsTooltip, setShowChipsTooltip] = useState(false)

    // Assets
    const imgChipsDay = new URL('../../assets/hub/chips_sleeping_day.png', import.meta.url).href
    const imgChipsNight = new URL('../../assets/hub/chips_sleeping_night.png', import.meta.url).href

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

                {/* Machine à Espresso (Now in Living Room) */}
                <div
                    className={`absolute bottom-[40%] right-[10%] group cursor-pointer p-6 rounded-3xl transition-all duration-700 backdrop-blur-sm border border-white/5
                        ${isCoffeeMachineOn ? 'bg-orange-500/10 shadow-[0_0_30px_rgba(251,146,60,0.2)]' : 'hover:bg-white/5'}
                        ${isModalOpen ? 'pointer-events-none opacity-0' : 'opacity-100'}
                    `}
                    onClick={() => setIsCoffeeMachineOn(!isCoffeeMachineOn)}
                >
                    <div className={`absolute top-3 right-3 w-1.5 h-1.5 rounded-full transition-all duration-500 ${isCoffeeMachineOn ? 'bg-green-500' : 'bg-slate-700'}`} />
                    <Coffee
                        size={40}
                        className={`transition-all duration-700 ${isCoffeeMachineOn ? 'text-orange-400 drop-shadow-[0_0_10px_rgba(251,146,60,0.5)] scale-110' : 'text-slate-500'}`}
                    />
                    {isCoffeeMachineOn && (
                        <div className="absolute -top-4 left-1/2 -translate-x-1/2 flex gap-0.5">
                            <div className="w-0.5 h-3 bg-white/20 rounded-full animate-bounce [animation-delay:-0.3s]" />
                            <div className="w-0.5 h-4 bg-white/20 rounded-full animate-bounce [animation-delay:-0.1s]" />
                        </div>
                    )}
                </div>

                {/* Chips the Cat - Adjusted position: lower and further left */}
                <div
                    className={`absolute bottom-[5%] left-[0%] group cursor-pointer p-6 transition-all duration-700
                        ${isModalOpen ? 'pointer-events-none opacity-0' : 'opacity-100'}
                    `}
                    onMouseEnter={() => setShowChipsTooltip(true)}
                    onMouseLeave={() => setShowChipsTooltip(false)}
                    onClick={() => console.log("Maw!")}
                >
                    <div className="relative">
                        {/* Ghibli Chips Asset */}
                        <img
                            src={isDay ? imgChipsDay : imgChipsNight}
                            alt="Chips"
                            className="w-40 h-auto drop-shadow-xl transition-all duration-700 group-hover:scale-105 group-hover:drop-shadow-[0_0_15px_rgba(255,255,255,0.2)]"
                        />

                        <div className="absolute -top-4 -right-2 flex flex-col gap-0.5 opacity-0 group-hover:opacity-100 transition-opacity duration-1000">
                            <span className="text-[10px] font-bold animate-pulse text-white/60">z</span>
                            <span className="text-[12px] font-bold animate-pulse [animation-delay:0.3s] ml-1 text-white/40">z</span>
                        </div>
                    </div>

                    {/* Tooltip */}
                    <div className={`absolute -top-12 left-1/2 -translate-x-1/2 px-4 py-2 bg-white text-slate-900 rounded-xl text-[10px] font-bold transition-all duration-500 pointer-events-none shadow-xl scale-0 group-hover:scale-100
                        ${showChipsTooltip ? 'opacity-100 -translate-y-1' : 'opacity-0 translate-y-0'}
                    `}>
                        Ron ron... 💤
                        <div className="absolute bottom-[-4px] left-1/2 -translate-x-1/2 w-2 h-2 bg-white rotate-45" />
                    </div>
                </div>
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
