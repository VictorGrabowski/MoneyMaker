import React, { useEffect, useRef } from 'react'
import { useSalaryStore } from '../store/salaryStore'
import { useWeatherStore } from '../store/weatherStore'
import { Settings2 } from 'lucide-react'

export const MoneyWidget: React.FC = () => {
    const { displayedAccumulated, tick, setViewMode } = useSalaryStore()
    const { isDay, condition } = useWeatherStore()
    const lastTick = useRef<number>(Date.now())

    // WEATHER CANVAS
    const canvasRef = useRef<HTMLCanvasElement>(null)
    const raindropsRef = useRef<{ x: number, y: number, size: number, speed: number }[]>([])
    const snowflakesRef = useRef<{ x: number, y: number, size: number, speed: number, sway: number }[]>([])
    const frameIdRef = useRef<number>(0)

    useEffect(() => {
        const interval = setInterval(() => {
            const now = Date.now()
            const delta = now - lastTick.current
            tick(delta)
            lastTick.current = now
        }, 16)

        return () => clearInterval(interval)
    }, [tick])

    // WEATHER ANIMATION EFFECT
    useEffect(() => {
        if (!canvasRef.current) return
        const canvas = canvasRef.current
        const ctx = canvas.getContext('2d')
        if (!ctx) return

        // Init Particles
        if (condition === 'rain') {
            raindropsRef.current = Array.from({ length: 20 }).map(() => ({
                x: Math.random() * 250,
                y: Math.random() * 100,
                size: Math.random() * 2 + 1,
                speed: Math.random() * 0.2 + 0.05
            }))
        } else if (condition === 'snow') {
            snowflakesRef.current = Array.from({ length: 30 }).map(() => ({
                x: Math.random() * 250,
                y: Math.random() * 100,
                size: Math.random() * 1.5 + 1,
                speed: Math.random() * 0.5 + 0.2,
                sway: Math.random() * Math.PI * 2
            }))
        }

        const render = () => {
            // Clear with trail for blur effect? No, just clear.
            ctx.clearRect(0, 0, 250, 100)

            if (condition === 'rain') {
                ctx.strokeStyle = 'rgba(165, 243, 252, 0.5)'
                ctx.lineWidth = 1.5
                ctx.lineCap = 'round'
                raindropsRef.current.forEach(drop => {
                    drop.y += drop.speed
                    if (drop.y > 100) {
                        drop.y = -5
                        drop.x = Math.random() * 250
                    }

                    // Condensate stuck look
                    if (Math.random() > 0.98) drop.speed += 0.5 // Occasional slide
                    if (drop.speed > 0.5) drop.speed *= 0.95 // Friction

                    ctx.beginPath()
                    ctx.moveTo(drop.x, drop.y)
                    ctx.lineTo(drop.x, drop.y + 4) // Short streak
                    ctx.stroke()
                })
            } else if (condition === 'snow') {
                ctx.fillStyle = 'rgba(255, 255, 255, 0.6)'
                snowflakesRef.current.forEach(flake => {
                    flake.y += flake.speed
                    flake.sway += 0.05
                    const x = flake.x + Math.sin(flake.sway) * 2

                    if (flake.y > 100) {
                        flake.y = -5
                        flake.x = Math.random() * 250
                    }

                    ctx.beginPath()
                    ctx.arc(x, flake.y, flake.size, 0, Math.PI * 2)
                    ctx.fill()
                })
            }

            frameIdRef.current = requestAnimationFrame(render)
        }

        render()

        return () => cancelAnimationFrame(frameIdRef.current)
    }, [condition])

    return (
        <div className={`group relative w-[250px] h-[100px] flex items-center justify-center 
            ${isDay ? 'bg-white/10 border-white/20' : 'bg-black/10 border-white/10'} 
            backdrop-blur-xl border rounded-2xl overflow-hidden selection:bg-none no-drag transition-colors duration-1000 shadow-lg`}>

            {/* Weather Overlay Canvas */}
            <canvas
                ref={canvasRef}
                width={250}
                height={100}
                className="absolute inset-0 w-full h-full pointer-events-none opacity-80"
            />

            {/* Draggable Area */}
            <div className="absolute inset-0 cursor-move" style={{ WebkitAppRegion: 'drag' } as any} />

            {/* Content */}
            <div className="relative z-10 flex flex-col items-center pointer-events-none select-none">
                <div
                    className={`text-[10px] font-bold uppercase tracking-[0.3em] mb-1 opacity-90 ${isDay ? 'text-sky-200' : 'text-indigo-300'}`}
                    style={{ textShadow: '1px 1px 0 #000, -1px -1px 0 #000, 1px -1px 0 #000, -1px 1px 0 #000, 1px 1px 0 #000' }}
                >
                    Gains Réels
                </div>
                <div
                    className="text-4xl font-black text-white tabular-nums drop-shadow-2xl"
                    style={{ textShadow: '2px 2px 0 #000, -1px -1px 0 #000, 1px -1px 0 #000, -1px 1px 0 #000, 1px 1px 0 #000' }}
                >
                    {displayedAccumulated.toFixed(4)}<span className={`ml-1 ${isDay ? 'text-sky-300' : 'text-indigo-400'}`}>€</span>
                </div>
            </div>

            {/* Back Button */}
            <button
                onClick={() => setViewMode('setup')}
                className="absolute top-2 right-2 p-2 rounded-lg bg-white/5 hover:bg-white/10 text-white/20 hover:text-white transition-all duration-300 opacity-0 group-hover:opacity-100 no-drag pointer-events-auto"
                title="Paramètres"
            >
                <Settings2 size={14} />
            </button>

            {/* Animated Glow Bottom */}
            <div className={`absolute bottom-0 left-0 right-0 h-[2px] bg-gradient-to-r from-transparent via-${isDay ? 'sky' : 'indigo'}-500/50 to-transparent`} />
        </div>
    )
}
