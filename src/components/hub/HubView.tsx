import React, { useState } from 'react'
import { OfficeView } from './OfficeView'
import { LivingRoomView } from './LivingRoomView'
import { KitchenView } from './KitchenView'
import { Briefcase, Sofa, Coffee } from 'lucide-react'
import { useWeatherStore } from '../../store/weatherStore'

type Zone = 'office' | 'living-room' | 'kitchen'

export const HubView: React.FC = () => {
    const [currentZone, setCurrentZone] = useState<Zone>('office')
    const { isDay } = useWeatherStore()

    // Refs for direct DOM manipulation (Performance optimization)
    const contentRef = React.useRef<HTMLDivElement>(null)
    const blob1Ref = React.useRef<HTMLDivElement>(null)
    const blob2Ref = React.useRef<HTMLDivElement>(null)

    React.useEffect(() => {
        const handleMouseMove = (e: MouseEvent) => {
            if (!contentRef.current || !blob1Ref.current || !blob2Ref.current) return

            const x = (e.clientX / window.innerWidth - 0.5) * 20 // -10 to 10
            const y = (e.clientY / window.innerHeight - 0.5) * 20 // -10 to 10

            // Apply transforms directly without triggering React re-renders
            requestAnimationFrame(() => {
                if (contentRef.current) contentRef.current.style.transform = `translate(${-x * 0.5}px, ${-y * 0.5}px)`
                if (blob1Ref.current) blob1Ref.current.style.transform = `translate(${x * 2}px, ${y * 2}px)`
                if (blob2Ref.current) blob2Ref.current.style.transform = `translate(${x * 1.5}px, ${y * 1.5}px)`
            })
        }

        window.addEventListener('mousemove', handleMouseMove)
        return () => window.removeEventListener('mousemove', handleMouseMove)
    }, [])

    const renderZone = () => {
        switch (currentZone) {
            case 'office': return <OfficeView />
            case 'living-room': return <LivingRoomView />
            case 'kitchen': return <KitchenView />
        }
    }

    return (
        <div
            className={`relative w-full h-full min-h-screen flex flex-col items-center justify-center overflow-hidden transition-colors duration-1000 ${isDay ? 'bg-sky-900' : 'bg-slate-950'} text-white`}
        >
            {/* Draggable Background Area - Placed FIRST to sit behind content */}
            <div className="absolute top-0 left-0 right-0 h-32 drag z-0" />

            {/* Custom Window Controls (Top Right) */}
            <div className="absolute top-4 right-4 flex gap-2 z-50 no-drag">
                <button
                    onClick={() => window.electron.minimize()}
                    className="p-2 hover:bg-white/10 rounded-full text-slate-400 hover:text-white transition-colors cursor-pointer"
                    title="Minimize"
                >
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="5" y1="12" x2="19" y2="12"></line></svg>
                </button>
                <button
                    onClick={() => window.electron.toggleMaximize()}
                    className="p-2 hover:bg-white/10 rounded-full text-slate-400 hover:text-white transition-colors cursor-pointer"
                    title="Maximize/Restore"
                >
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect></svg>
                </button>
                <button
                    onClick={() => window.electron.close()}
                    className="p-2 hover:bg-red-500/20 rounded-full text-slate-400 hover:text-red-400 transition-colors cursor-pointer"
                    title="Close"
                >
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                </button>
            </div>

            {/* Main Content Area */}
            <div
                ref={contentRef}
                className="flex-1 w-full h-full flex items-center justify-center relative z-10" // Removed max-w-5xl mx-auto p-8 for fullscreen views
            >
                {renderZone()}
            </div>

            {/* Floating Navigation Bar */}
            <div className="fixed bottom-8 flex gap-4 p-2 rounded-full bg-white/10 border border-white/10 backdrop-blur-xl shadow-2xl z-50 no-drag">
                <NavButton
                    active={currentZone === 'office'}
                    onClick={() => setCurrentZone('office')}
                    icon={<Briefcase size={20} />}
                    label="Bureau"
                />
                <NavButton
                    active={currentZone === 'living-room'}
                    onClick={() => setCurrentZone('living-room')}
                    icon={<Sofa size={20} />}
                    label="Salon de Thé"
                />
                <NavButton
                    active={currentZone === 'kitchen'}
                    onClick={() => setCurrentZone('kitchen')}
                    icon={<Coffee size={20} />}
                    label="Cuisine"
                />
            </div>

            {/* Background Ambient Glow (Parallaxed) */}
            <div className={`absolute pointer-events-none inset-0 transition-opacity duration-1000 ${isDay ? 'opacity-30' : 'opacity-10'}`}>
                <div
                    ref={blob1Ref}
                    className="absolute top-[-20%] left-[-10%] w-[600px] h-[600px] rounded-full bg-indigo-500 blur-[120px]" // Removed transition-transform
                />
                <div
                    ref={blob2Ref}
                    className="absolute bottom-[-20%] right-[-10%] w-[500px] h-[500px] rounded-full bg-sky-500 blur-[120px]" // Removed transition-transform
                />
            </div>
        </div >
    )
}

const NavButton: React.FC<{ active: boolean, onClick: () => void, icon: React.ReactNode, label: string }> = ({ active, onClick, icon, label }) => (
    <button
        onClick={onClick}
        title={label}
        className={`relative flex items-center justify-center px-6 py-3 rounded-full transition-all duration-300 group
        ${active
                ? 'bg-white text-slate-900 shadow-[0_0_20px_rgba(255,255,255,0.3)]'
                : 'bg-transparent text-slate-400 hover:bg-white/5 hover:text-white'
            }`}
    >
        <span className="relative z-10">{icon}</span>
    </button>
)
