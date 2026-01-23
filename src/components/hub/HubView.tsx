import React, { useState, useEffect } from 'react'
import { OfficeView } from './OfficeView'
import { LivingRoomView } from './LivingRoomView'
import { ChevronLeft, ChevronRight, Flower2, BookOpen, Backpack } from 'lucide-react'
import { useWeatherStore } from '../../store/weatherStore'
import { usePlantStore } from '../../store/plantStore'
import { PlantOverlay } from '../../features/bocal/components/PlantOverlay'
import { GardenShop } from '../../features/bocal/components/GardenShop'
import { Herbarium } from '../../features/bocal/components/Herbarium'
import { InventoryWindow } from '../../features/bocal/components/InventoryWindow'
import bureauBg from '../../assets/hub/bureau_bg.png'

type Zone = 'office' | 'living-room'

export const HubView: React.FC = () => {
    const [currentZone, setCurrentZone] = useState<Zone>('office')
    const { isDay } = useWeatherStore()
    const checkGrowth = usePlantStore(state => state.checkGrowth)

    // UI States
    const [isShopOpen, setShopOpen] = useState(false)
    const [isHerbariumOpen, setHerbariumOpen] = useState(false)
    const [isInventoryOpen, setInventoryOpen] = useState(false)

    useEffect(() => {
        // Check plant growth on mount
        checkGrowth()
    }, [])

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

            {/* Main Content Area */}
            <div ref={contentRef} className="flex-1 w-full h-full flex items-center justify-center relative z-10">
                {currentZone === 'office' ? <OfficeView /> : <LivingRoomView />}
            </div>

            {/* Plant Features */}
            <div className="absolute inset-0 z-30 pointer-events-none">
                <PlantOverlay />
            </div>

            {/* Plant Controls */}
            <div className="absolute bottom-8 left-1/2 transform -translate-x-1/2 flex gap-4 z-50 pointer-events-auto">
                <button 
                    onClick={() => setShopOpen(true)}
                    className="p-3 bg-emerald-600/90 hover:bg-emerald-500 text-white rounded-full shadow-lg backdrop-blur-sm transition-transform hover:scale-110 flex items-center justify-center"
                    title="Garden Shop"
                >
                    <Flower2 size={24} />
                </button>
                <button 
                    onClick={() => setHerbariumOpen(true)}
                    className="p-3 bg-amber-700/90 hover:bg-amber-600 text-white rounded-full shadow-lg backdrop-blur-sm transition-transform hover:scale-110 flex items-center justify-center"
                    title="Herbarium"
                >
                    <BookOpen size={24} />
                </button>
                <button 
                    onClick={() => setInventoryOpen(true)}
                    className="p-3 bg-slate-700/90 hover:bg-slate-600 text-white rounded-full shadow-lg backdrop-blur-sm transition-transform hover:scale-110 flex items-center justify-center"
                    title="Inventory"
                >
                    <Backpack size={24} />
                </button>
            </div>

            {/* Modals */}
            <GardenShop isOpen={isShopOpen} onClose={() => setShopOpen(false)} />
            <Herbarium isOpen={isHerbariumOpen} onClose={() => setHerbariumOpen(false)} />
            <InventoryWindow isOpen={isInventoryOpen} onClose={() => setInventoryOpen(false)} />

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
