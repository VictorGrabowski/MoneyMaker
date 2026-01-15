import React, { useEffect, useState } from 'react'

export const FpsCounter = () => {
    const [fps, setFps] = useState(0)

    useEffect(() => {
        let frameCount = 0
        let lastTime = performance.now()
        let rafId: number

        const loop = (time: number) => {
            frameCount++
            const elapsed = time - lastTime

            if (elapsed >= 1000) {
                setFps(Math.round((frameCount * 1000) / elapsed))
                frameCount = 0
                lastTime = time
            }

            rafId = requestAnimationFrame(loop)
        }

        rafId = requestAnimationFrame(loop)

        return () => cancelAnimationFrame(rafId)
    }, [])

    return (
        <div className={`
            fixed top-4 right-4 z-[9999] 
            px-3 py-1.5 rounded-lg 
            font-mono text-xs font-bold 
            backdrop-blur-md border border-white/10 shadow-lg
            transition-colors duration-500
            ${fps < 30 ? 'bg-red-500/20 text-red-400 border-red-500/30' :
                fps < 50 ? 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30' :
                    'bg-emerald-500/20 text-emerald-400 border-emerald-500/30'}
        `}>
            {fps} FPS
        </div>
    )
}
