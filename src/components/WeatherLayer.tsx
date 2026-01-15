import React, { useEffect, useRef } from 'react'
import { useWeatherStore } from '../store/weatherStore'

interface Particle {
    x: number
    y: number
    speed: number
    length: number // For rain
    radius: number // For snow
    opacity: number
    angle: number // Start angle
    sway: number // For snow
}

export const WeatherLayer: React.FC = () => {
    const condition = useWeatherStore(s => s.condition)
    const canvasRef = useRef<HTMLCanvasElement>(null)
    const particlesRef = useRef<Particle[]>([])
    const frameIdRef = useRef<number>(0)

    // SETUP PARTICLES
    useEffect(() => {
        if (!canvasRef.current) return
        const width = window.innerWidth
        const height = window.innerHeight

        particlesRef.current = []
        const particles = particlesRef.current

        if (condition === 'rain') {
            // Create 300 Rain Drops
            for (let i = 0; i < 300; i++) {
                particles.push({
                    x: Math.random() * width,
                    y: Math.random() * height,
                    speed: 15 + Math.random() * 10, // Fast but varied
                    length: 15 + Math.random() * 20,
                    radius: 0,
                    opacity: 0.3 + Math.random() * 0.3, // "Chill" opacity
                    angle: Math.PI / 12, // ~15 degrees
                    sway: 0
                })
            }
        } else if (condition === 'snow') {
            // Create 200 Snow Flakes
            for (let i = 0; i < 200; i++) {
                particles.push({
                    x: Math.random() * width,
                    y: Math.random() * height,
                    speed: 1 + Math.random() * 2,
                    length: 0,
                    radius: 2 + Math.random() * 3,
                    opacity: 0.5 + Math.random() * 0.5,
                    angle: 0,
                    sway: Math.random() * Math.PI * 2
                })
            }
        }

    }, [condition])

    // ANIMATION LOOP
    useEffect(() => {
        const canvas = canvasRef.current
        if (!canvas) return
        const ctx = canvas.getContext('2d')
        if (!ctx) return

        const render = () => {
            const width = canvas.width
            const height = canvas.height
            ctx.clearRect(0, 0, width, height)

            if (condition === 'clear' || condition === 'cloudy') {
                // Only draw particles for rain/snow, but keep loop for generic cleanup or transitions if needed
                if (frameIdRef.current) cancelAnimationFrame(frameIdRef.current)
                return
            }

            const particles = particlesRef.current

            ctx.lineCap = 'round'

            particles.forEach(p => {
                // UPDATE
                if (condition === 'rain') {
                    p.y += p.speed
                    p.x += Math.tan(p.angle) * p.speed
                } else if (condition === 'snow') {
                    p.y += p.speed
                    p.sway += 0.02
                    p.x += Math.sin(p.sway) * 0.5
                }

                // RESET
                // Wider reset area to account for angle
                if (p.y > height + 50 || p.x > width + 500) {
                    p.y = -50 - Math.random() * 50
                    p.x = Math.random() * width - (condition === 'rain' ? 200 : 0) // Shift rain start left due to angle
                }

                // DRAW
                ctx.beginPath()
                if (condition === 'rain') {
                    ctx.strokeStyle = `rgba(165, 243, 252, ${p.opacity})`
                    ctx.lineWidth = 1.5
                    ctx.moveTo(p.x, p.y)
                    ctx.lineTo(p.x + Math.tan(p.angle) * p.length, p.y + p.length)
                    ctx.stroke()
                } else if (condition === 'snow') {
                    ctx.fillStyle = `rgba(255, 255, 255, ${p.opacity})`
                    ctx.beginPath()
                    ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2)
                    ctx.fill()
                }
            })

            frameIdRef.current = requestAnimationFrame(render)
        }

        // Handle Resize
        const handleResize = () => {
            canvas.width = window.innerWidth
            canvas.height = window.innerHeight
        }
        handleResize()
        window.addEventListener('resize', handleResize)

        // Start render loop
        render()

        return () => {
            cancelAnimationFrame(frameIdRef.current)
            window.removeEventListener('resize', handleResize)
        }
    }, [condition])

    return (
        <>
            <canvas
                ref={canvasRef}
                className="absolute inset-0 w-full h-full pointer-events-none z-30"
            />
            {condition === 'cloudy' && (
                <div className="absolute inset-0 bg-slate-400/20 backdrop-blur-[1px] pointer-events-none z-40"></div>
            )}
        </>
    )
}
