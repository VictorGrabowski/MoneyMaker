import React, { useState, useEffect } from 'react'
import imgDayWithPastry from '../../assets/hub/salon_day_with_pastry.png'
import imgDayEmpty from '../../assets/hub/salon_day.png'
import imgNight from '../../assets/hub/salon_night.png'
import { useWeatherStore } from '../../store/weatherStore'
import { useSalaryStore } from '../../store/salaryStore'
import { useBakingStore } from '../../store/bakingStore'
import RecipeBook from '../RecipeBook'
import BakingView from '../BakingView'
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
                <span className="text-white text-outline font-mono font-bold text-lg animate-pulse">{timeLeft}</span>
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
    const { isBaking, timeRemaining } = useBakingStore()

    // Local state for modals
    const [showRecipeBook, setShowRecipeBook] = useState(false)
    const [isCoffeeMachineOn, setIsCoffeeMachineOn] = useState(false)
    const [showChipsTooltip, setShowChipsTooltip] = useState(false)

    // Assets
    const imgChipsDay = new URL('../../assets/hub/chips_sleeping_day.png', import.meta.url).href
    const imgChipsNight = new URL('../../assets/hub/chips_sleeping_night.png', import.meta.url).href

    // Determine background
    // TODO: Connect "hasFinishedStock" to bakingStore logic if needed for reward visuals
    const backgroundImage = isDay ? imgDayEmpty : imgNight

    const handleOvenClick = () => {
        if (!isBaking) {
            setShowRecipeBook(true)
        }
    }

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
                        ${showRecipeBook || isBaking ? 'pointer-events-none opacity-0' : 'transition-colors duration-300 opacity-100'}
                        hover:bg-yellow-400/5 bg-transparent
                    `}
                    onClick={handleOvenClick}
                    title="Ouvrir le Livre de Recettes"
                >
                </div>

                {/* "Bocal" (Jar) Click Zone */}
                <div
                    className={`absolute bottom-[5%] left-[42.5%] w-[15%] h-[30%] cursor-pointer rounded-lg z-20 transition-colors duration-300 outline-none focus:ring-0
                        ${showRecipeBook || isBaking ? 'pointer-events-none opacity-0' : 'hover:bg-white/5 bg-transparent opacity-100'}
                    `}
                    onClick={() => setViewMode('bocal')}
                    title="Le Bocal"
                />

                {/* Machine à Espresso */}
                <div
                    className={`absolute bottom-[40%] right-[10%] group cursor-pointer p-6 rounded-3xl transition-all duration-700 backdrop-blur-sm border border-white/5
                        ${isCoffeeMachineOn ? 'bg-orange-500/10 shadow-[0_0_30px_rgba(251,146,60,0.2)]' : 'hover:bg-white/5'}
                        ${showRecipeBook || isBaking ? 'pointer-events-none opacity-0' : 'opacity-100'}
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

                {/* Chips the Cat */}
                <div
                    className={`absolute bottom-[5%] left-[0%] group cursor-pointer p-6 transition-all duration-700
                        ${showRecipeBook || isBaking ? 'pointer-events-none opacity-0' : 'opacity-100'}
                    `}
                    onMouseEnter={() => setShowChipsTooltip(true)}
                    onMouseLeave={() => setShowChipsTooltip(false)}
                    onClick={() => console.log("Maw!")}
                >
                    <div className="relative">
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
                    <div className={`absolute -top-12 left-1/2 -translate-x-1/2 px-4 py-2 bg-white text-slate-900 rounded-xl text-[10px] font-bold transition-all duration-500 pointer-events-none shadow-xl scale-0 group-hover:scale-100
                        ${showChipsTooltip ? 'opacity-100 -translate-y-1' : 'opacity-0 translate-y-0'}
                    `}>
                        Ron ron... 💤
                        <div className="absolute bottom-[-4px] left-1/2 -translate-x-1/2 w-2 h-2 bg-white rotate-45" />
                    </div>
                </div>
            </div>

            {/* FULLSCREENS */}

            {/* 1. Recipe Book Modal */}
            {showRecipeBook && !isBaking && (
                <div className="absolute inset-0 z-50 bg-black/50 backdrop-blur-md flex items-center justify-center p-12 animate-in fade-in zoom-in-95 duration-200">
                    <div className="w-full h-full max-w-4xl max-h-[85vh] bg-white rounded-2xl overflow-hidden shadow-2xl ring-1 ring-white/10">
                        <RecipeBook onBack={() => setShowRecipeBook(false)} />
                    </div>
                </div>
            )}

            {/* 2. Baking View (Active) */}
            {isBaking && (
                <div className="absolute inset-0 z-50 bg-black/60 backdrop-blur-md flex items-center justify-center p-12 animate-in slide-in-from-bottom duration-500">
                    <div className="w-full h-full max-w-4xl max-h-[85vh] bg-amber-50 rounded-2xl overflow-hidden shadow-2xl ring-1 ring-white/10">
                        <BakingView />
                    </div>
                </div>
            )}
        </div>
    )
}
