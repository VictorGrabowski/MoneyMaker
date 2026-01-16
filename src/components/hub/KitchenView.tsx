import React, { useState } from 'react'
import { useWeatherStore } from '../../store/weatherStore'
import { Cat } from 'lucide-react'

// Assets
import imgKitchenDay from '../../assets/hub/kitchen_day.png'
import imgKitchenNight from '../../assets/hub/kitchen_night.png'
import imgChipsDay from '../../assets/hub/chips_sleeping_day.png'
import imgChipsNight from '../../assets/hub/chips_sleeping_night.png'

export const KitchenView: React.FC = () => {
    const { isDay } = useWeatherStore()
    const [showChipsTooltip, setShowChipsTooltip] = useState(false)
    const [isCoffeeMachineOn, setIsCoffeeMachineOn] = useState(false)

    return (
        <div className="absolute inset-0 w-full h-full overflow-hidden flex items-center justify-center">
            {/* Background Layer */}
            <div
                className="absolute inset-0 transition-opacity duration-1000 ease-in-out bg-cover bg-center"
                style={{
                    backgroundImage: `url(${isDay ? imgKitchenDay : imgKitchenNight})`,
                }}
            />

            {/* Atmosphere Overlay */}
            <div className={`absolute inset-0 pointer-events-none transition-colors duration-[2000ms] ${isDay ? 'bg-orange-500/5 mix-blend-overlay' : 'bg-blue-900/10 mix-blend-overlay'}`} />

            {/* Content Container */}
            <div className="relative z-10 w-full h-full max-w-6xl mx-auto flex flex-col items-center justify-center text-center px-8">

                {/* Visual Title (Subtle) */}
                <div className="mb-12 animate-in fade-in slide-in-from-bottom-4 duration-1000">
                    <h2 className="text-4xl font-extralight tracking-[0.3em] uppercase opacity-40 mb-2">La Cuisine</h2>
                    <div className="h-px w-24 bg-white/20 mx-auto" />
                </div>

                <div className="relative w-full h-full">

                    {/* Chips the Cat Zone - Placed at the absolute bottom right corner */}
                    <div
                        className="absolute bottom-0 right-0 group transition-all duration-700 cursor-pointer"
                        onMouseEnter={() => setShowChipsTooltip(true)}
                        onMouseLeave={() => setShowChipsTooltip(false)}
                        onClick={() => {
                            console.log("Maw!")
                        }}
                    >
                        <div className="relative">
                            {/* Ghibli Chips Asset */}
                            <img
                                src={isDay ? imgChipsDay : imgChipsNight}
                                alt="Chips"
                                className="w-64 h-auto drop-shadow-2xl transition-all duration-700 group-hover:scale-105 group-hover:drop-shadow-[0_0_20px_rgba(255,255,255,0.2)]"
                            />

                            {/* Sleeping Zzz animation */}
                            <div className="absolute top-0 right-0 flex flex-col gap-1 opacity-0 group-hover:opacity-100 transition-opacity duration-1000">
                                <span className="text-sm font-bold animate-pulse [animation-delay:0s] text-white/60">Z</span>
                                <span className="text-md font-bold animate-pulse [animation-delay:0.3s] ml-2 text-white/40">z</span>
                                <span className="text-lg font-bold animate-pulse [animation-delay:0.6s] ml-4 text-white/20">z</span>
                            </div>
                        </div>

                        {/* Tooltip */}
                        <div className={`absolute -top-12 left-1/2 -translate-x-1/2 px-6 py-3 bg-white text-slate-900 rounded-2xl text-xs font-bold transition-all duration-500 pointer-events-none shadow-2xl scale-0 group-hover:scale-100
                            ${showChipsTooltip ? 'opacity-100 -translate-y-2' : 'opacity-0 translate-y-0'}
                        `}>
                            Ron ron ron... 💤
                            <div className="absolute bottom-[-6px] left-1/2 -translate-x-1/2 w-3 h-3 bg-white rotate-45" />
                        </div>
                    </div>

                </div>

                {/* Status Message */}
                <div className="mt-20 flex flex-col items-center gap-4">
                    <div className="h-px w-12 bg-white/10" />
                    <div className="opacity-20 text-[10px] tracking-[0.4em] uppercase font-bold">
                        Le repaire secret de Chips
                    </div>
                </div>
            </div>
        </div>
    )
}
