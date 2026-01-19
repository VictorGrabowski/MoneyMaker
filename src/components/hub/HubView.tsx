import React, { useState, useEffect } from 'react'
import { OfficeView } from './OfficeView'
import { LivingRoomView } from './LivingRoomView'
import { ChevronLeft, ChevronRight } from 'lucide-react'
import { useWeatherStore } from '../../store/weatherStore'
import bureauBg from '../../assets/hub/bureau_bg.png'

type Zone = 'office' | 'living-room'

export const HubView: React.FC = () => {
    const [currentZone, setCurrentZone] = useState<Zone>('office')
    const { isDay } = useWeatherStore()

    // Refs for direct DOM manipulation (Performance optimization)
    const contentRef = React.useRef<HTMLDivElement>(null)
    const blob1Ref = React.useRef<HTMLDivElement>(null)
    const blob2Ref = React.useRef<HTMLDivElement>(null)

    useEffect(() => {
        const handleMouseMove = (e: MouseEvent) => {
            if (!contentRef.current || !blob1Ref.current || !blob2Ref.current) return

            const x = (e.clientX / window.innerWidth - 0.5) * 20 // -10 to 10
            const y = (e.clientY / window.innerHeight - 0.5) * 20 // -10 to 10

            requestAnimationFrame(() => {
                if (contentRef.current) contentRef.current.style.transform = `translate(${-x * 0.5}px, ${-y * 0.5}px) scale(1.05)`
                if (blob1Ref.current) blob1Ref.current.style.transform = `translate(${x * 2}px, ${y * 2}px)`
                if (blob2Ref.current) blob2Ref.current.style.transform = `translate(${x * 1.5}px, ${y * 1.5}px)`
            })
        }

        window.addEventListener('mousemove', handleMouseMove)
        return () => window.removeEventListener('mousemove', handleMouseMove)
    }, [])

    const toggleZone = () => {
        setCurrentZone(prev => prev === 'office' ? 'living-room' : 'office')
    }

    return (
        <div
            className={`relative w-full h-full min-h-screen flex flex-col items-center justify-center overflow-hidden transition-colors duration-1000 ${isDay ? 'bg-sky-900' : 'bg-slate-950'} text-white`}
        >
            {/* Background Image */}
            <div
                className="absolute inset-0 bg-cover bg-center bg-no-repeat z-0"
                style={{ backgroundImage: `url(${bureauBg})` }}
            />
            {/* Dark overlay */}
            <div className={`absolute inset-0 z-0 transition-opacity duration-1000 ${isDay ? 'bg-black/20' : 'bg-black/40'}`} />

            {/* Draggable Background Area */}
            <div className="absolute top-0 left-0 right-0 h-32 drag z-0" />

            {/* Custom Window Controls */}
            <div className="absolute top-4 right-4 flex gap-2 z-50 no-drag">
                <button onClick={() => window.electron.minimize()} className="p-2 hover:bg-white/10 rounded-full text-slate-400 hover:text-white transition-colors">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="5" y1="12" x2="19" y2="12"></line></svg>
                </button>
                <button onClick={() => window.electron.toggleMaximize()} className="p-2 hover:bg-white/10 rounded-full text-slate-400 hover:text-white transition-colors">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect></svg>
                </button>
                <button onClick={() => window.electron.close()} className="p-2 hover:bg-red-500/20 rounded-full text-slate-400 hover:text-red-400 transition-colors">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                </button>
            </div>

            {/* Main Content Area */}
            <div ref={contentRef} className="flex-1 w-full h-full flex items-center justify-center relative z-10">
                {currentZone === 'office' ? <OfficeView /> : <LivingRoomView />}
            </div>

            {/* Side Navigation Arrows */}
            <div className="absolute inset-y-0 left-0 w-24 flex items-center justify-center z-40 group pointer-events-none">
                <button
                    onClick={toggleZone}
                    className={`pointer-events-auto p-4 rounded-full bg-white/5 hover:bg-white/20 backdrop-blur-sm transition-all duration-300 transform group-hover:scale-110 flex items-center justify-center
                    ${currentZone === 'living-room' ? 'opacity-100 translate-x-4' : 'opacity-0 -translate-x-full'}`}
                >
                    <ChevronLeft size={32} className="text-white/80" />
                </button>
            </div>

            <div className="absolute inset-y-0 right-0 w-24 flex items-center justify-center z-40 group pointer-events-none">
                <button
                    onClick={toggleZone}
                    className={`pointer-events-auto p-4 rounded-full bg-white/5 hover:bg-white/20 backdrop-blur-sm transition-all duration-300 transform group-hover:scale-110 flex items-center justify-center
                    ${currentZone === 'office' ? 'opacity-100 -translate-x-4' : 'opacity-0 translate-x-full'}`}
                >
                    <ChevronRight size={32} className="text-white/80" />
                </button>
            </div>

            {/* Background Ambient Glow */}
            <div className={`absolute pointer-events-none inset-0 transition-opacity duration-1000 ${isDay ? 'opacity-30' : 'opacity-10'}`}>
                <div ref={blob1Ref} className="absolute top-[-20%] left-[-10%] w-[600px] h-[600px] rounded-full bg-indigo-500 blur-[120px]" />
                <div ref={blob2Ref} className="absolute bottom-[-20%] right-[-10%] w-[500px] h-[500px] rounded-full bg-sky-500 blur-[120px]" />
            </div>
        </div>
    )
}
