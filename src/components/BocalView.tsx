import React, { useEffect, useRef, useState, useCallback, memo } from 'react'
import Matter from 'matter-js'
import { useSalaryStore } from '../store/salaryStore'
import { useImmersionStore, RADIO_STATIONS } from '../store/immersionStore'
import { useWeatherStore } from '../store/weatherStore'
import { BureauControls } from './hub/BureauControls'
import { WeatherLayer } from './WeatherLayer'
import { FpsCounter } from './FpsCounter'
import { ArrowLeft, RefreshCw, Radio, SkipForward, Volume2, VolumeX, CloudRain, CloudSnow, Sun, Moon, ZoomIn, ZoomOut } from 'lucide-react'
import Slider from 'rc-slider'
import 'rc-slider/assets/index.css'

// Asset Imports
import imgBocalEnv from '../assets/hub/bocal_env.png'
import imgCoin1 from '../assets/money/coin_1.png'
import imgCoin2 from '../assets/money/coin_2.png'
import imgCoin1Cent from '../assets/money/coin_1_cent.png'
import imgCoin5Cents from '../assets/money/coin_5_cents.png'
import imgCoin50Cents from '../assets/money/coin_50_cent.png'
import imgCoinCopper from '../assets/money/coin_copper_generic.png'
import imgCoinGold from '../assets/money/coin_gold_generic.png'
import imgBill5 from '../assets/money/bill_5.png'
import imgBill10 from '../assets/money/bill_10.png'
import imgBill20 from '../assets/money/bill_20.png'
import imgBill50 from '../assets/money/bill_50.png'
import imgBill100 from '../assets/money/bill_100.png'
import imgBill200 from '../assets/money/bill_200.png'
import imgBill500 from '../assets/money/bill_500.png'
import imgIngotGold from '../assets/hub/golden_bar.png'



interface ItemConfig {
    value: number
    type: 'coin' | 'bill' | 'ingot' | 'gem'
    color: string
    borderColor: string
    width: number
    height: number
    displayText: string
    texture?: string
    textureScale?: number
}

const DENOMINATIONS: ItemConfig[] = [
    { value: 10000, type: 'gem', color: '#b6e3f4', borderColor: '#fff', width: 120, height: 120, displayText: '💎' },
    { value: 5000, type: 'ingot', color: '#f59e0b', borderColor: '#b45309', width: 200, height: 100, displayText: '5k' },
    { value: 2000, type: 'ingot', color: '#fbbf24', borderColor: '#d97706', width: 180, height: 90, displayText: '2k' },
    { value: 1000, type: 'ingot', color: '#fcd34d', borderColor: '#b45309', width: 176, height: 88, displayText: '1k', texture: imgIngotGold },
    { value: 500, type: 'bill', color: '#d946ef', borderColor: '#86198f', width: 320, height: 164, displayText: '500', texture: imgBill500 }, // ~1.95 ratio
    { value: 200, type: 'bill', color: '#eab308', borderColor: '#854d0e', width: 306, height: 164, displayText: '200', texture: imgBill200 }, // ~1.86 ratio
    { value: 100, type: 'bill', color: '#10b981', borderColor: '#064e3b', width: 294, height: 164, displayText: '100', texture: imgBill100 }, // ~1.79 ratio
    { value: 50, type: 'bill', color: '#f59e0b', borderColor: '#78350f', width: 280, height: 154, displayText: '50', texture: imgBill50 }, // ~1.81 ratio
    { value: 20, type: 'bill', color: '#3b82f6', borderColor: '#1e3a8a', width: 266, height: 144, displayText: '20', texture: imgBill20 }, // ~1.84 ratio
    { value: 10, type: 'bill', color: '#ef4444', borderColor: '#7f1d1d', width: 254, height: 134, displayText: '10', texture: imgBill10 }, // ~1.90 ratio
    { value: 5, type: 'bill', color: '#8b5cf6', borderColor: '#4c1d95', width: 240, height: 124, displayText: '5', texture: imgBill5 }, // ~1.93 ratio
    { value: 2, type: 'coin', color: '#fbbf24', borderColor: '#92400e', width: 103, height: 103, displayText: '2€', texture: imgCoin2, textureScale: 1.38 },
    { value: 1, type: 'coin', color: '#fbbf24', borderColor: '#92400e', width: 93, height: 93, displayText: '1€', texture: imgCoin1, textureScale: 1.10 },
    { value: 0.5, type: 'coin', color: '#fde68a', borderColor: '#b45309', width: 97, height: 97, displayText: '50', texture: imgCoin50Cents, textureScale: 1.24 },
    { value: 0.2, type: 'coin', color: '#fde68a', borderColor: '#b45309', width: 89, height: 89, displayText: '20', texture: imgCoinGold, textureScale: 1.28 },
    { value: 0.1, type: 'coin', color: '#fde68a', borderColor: '#b45309', width: 79, height: 79, displayText: '10', texture: imgCoinGold, textureScale: 1.26 },
    { value: 0.05, type: 'coin', color: '#b45309', borderColor: '#451a03', width: 85, height: 85, displayText: '5', texture: imgCoin5Cents, textureScale: 1.88 },
    { value: 0.02, type: 'coin', color: '#b45309', borderColor: '#451a03', width: 75, height: 75, displayText: '2', texture: imgCoinCopper, textureScale: 1.75 },
    { value: 0.01, type: 'coin', color: '#b45309', borderColor: '#451a03', width: 65, height: 65, displayText: '1', texture: imgCoin1Cent, textureScale: 1.05 },
]

// Sorted by value ascending for slider display
const DENOMINATIONS_SORTED = [...DENOMINATIONS].sort((a, b) => a.value - b.value)

// Labels for slider
const getDenominationLabel = (value: number): string => {
    if (value >= 1000) return `${value / 1000}k€`
    if (value >= 1) return `${value}€`
    return `${Math.round(value * 100)}c`
}

const MERGE_RECIPES: { inputs: number[], outputs: number[] }[] = [
    { inputs: [0.01, 0.01], outputs: [0.02] },
    { inputs: [0.02, 0.02, 0.01], outputs: [0.05] },
    { inputs: [0.02, 0.02, 0.02], outputs: [0.05, 0.01] }, // 3x2c -> 5c + 1c
    { inputs: [0.05, 0.05], outputs: [0.10] },
    { inputs: [0.10, 0.10], outputs: [0.20] },
    { inputs: [0.20, 0.20, 0.10], outputs: [0.50] },
    { inputs: [0.20, 0.20, 0.20], outputs: [0.50, 0.10] }, // 3x20c -> 50c + 10c
    { inputs: [0.50, 0.50], outputs: [1.00] },
    { inputs: [1.00, 1.00], outputs: [2.00] },
    { inputs: [2.00, 2.00, 0.999], outputs: [5.00] }, // Fallback logic slightly adjusted in code logic usually but here inputs are exact match
    { inputs: [2.00, 2.00, 1.00], outputs: [5.00] },
    { inputs: [2.00, 2.00, 2.00], outputs: [5.00, 1.00] },
    { inputs: [5.00, 5.00], outputs: [10.00] },
    { inputs: [10.00, 10.00], outputs: [20.00] },
    { inputs: [20.00, 20.00, 10.00], outputs: [50.00] },
    { inputs: [20.00, 20.00, 20.00], outputs: [50.00, 10.00] }, // 3x20€ -> 50€ + 10€
    { inputs: [50.00, 50.00], outputs: [100.00] },
    { inputs: [100.00, 100.00], outputs: [200.00] },
    { inputs: [200.00, 200.00, 100.00], outputs: [500.00] },
    { inputs: [200.00, 200.00, 200.00], outputs: [500.00, 100.00] }, // 3x200€ -> 500€ + 100€
    { inputs: [500.00, 500.00], outputs: [1000.00] },
    { inputs: [1000.00, 1000.00], outputs: [2000.00] },
    { inputs: [2000.00, 2000.00, 1000.00], outputs: [5000.00] },
    { inputs: [2000.00, 2000.00, 2000.00], outputs: [5000.00, 1000.00] }, // 3x2k -> 5k + 1k
    { inputs: [5000.00, 5000.00], outputs: [10000.00] },
]

// ... (Interface MoneyBody remains unchanged) ...

// ... (JarDecoration & ScoreDisplay remain unchanged) ...

// ... (Inside BocalView) ...



interface MoneyBody extends Matter.Body {
    isFrozen?: boolean
    denomination: ItemConfig
    createdAt?: number
}

// Memoized Jar Decoration to avoid expensive re-renders
// Import visual assets



// Memoized Jar Decoration to avoid expensive re-renders
const JarDecoration = memo(({ jarRef }: { jarRef: React.Ref<HTMLDivElement> }) => {
    const jarPath = "M135 10C135 4.47715 139.477 0 145 0H305C310.523 0 315 4.47715 315 10V70C315 75 320 80 340 90C390 115 450 150 450 250V520C450 564.183 414.183 600 370 600H80C35.8172 600 0 564.183 0 520V250C0 150 60 115 110 90C130 80 135 75 135 70V10Z"

    return (
        <div
            ref={jarRef}
            className="relative w-[450px] aspect-[3/4] max-h-[75vh] flex items-center justify-center pointer-events-none"
        >
            {/* Glass Effect Container (Clipped to Jar Shape) */}
            <div
                className="absolute inset-0 z-30"
                style={{ clipPath: `path('${jarPath}')` }}
            >
                {/* Reflection/Lighting Gradient (Light from behind/left) */}
                <div className="absolute inset-0 bg-gradient-to-br from-white/30 via-white/5 to-black/10 mix-blend-overlay" />

                {/* Subtle Inner Glow */}
                <div className="absolute inset-0 bg-[radial-gradient(circle_at_30%_30%,rgba(255,255,255,0.2),transparent_70%)]" />
            </div>

            {/* Structure & Details */}
            <svg
                viewBox="0 0 450 600"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
                className="absolute inset-0 w-full h-full z-40 pointer-events-none"
            >
                <defs>
                    <linearGradient id="glassEdge" x1="0%" y1="0%" x2="100%" y2="0%">
                        <stop offset="0%" stopColor="rgba(255,255,255,0.8)" />
                        <stop offset="50%" stopColor="rgba(255,255,255,0.3)" />
                        <stop offset="100%" stopColor="rgba(255,255,255,0.8)" />
                    </linearGradient>
                </defs>

                {/* Main Outline */}
                <path
                    d={jarPath}
                    stroke="url(#glassEdge)"
                    strokeWidth="3"
                    className="drop-shadow-lg"
                />

                {/* Neck Highlights */}
                <path d="M145 15 H 305" stroke="rgba(255,255,255,0.5)" strokeWidth="1" />
                <path d="M140 65 H 310" stroke="rgba(255,255,255,0.3)" strokeWidth="1" />

            </svg>
        </div>
    )
})

// Sub-component for Score to isolate its re-renders
const ScoreDisplay = () => {
    const displayedAccumulated = useSalaryStore(s => s.displayedAccumulated)
    const bocalMode = useSalaryStore(s => s.bocalMode)
    return (
        <div className="mt-8 text-center z-[60]">
            <div className="text-7xl font-black text-white text-outline tabular-nums drop-shadow-[0_10px_10px_rgba(0,0,0,0.5)] flex items-baseline gap-3 justify-center">
                {displayedAccumulated.toFixed(2)}<span className="text-white text-outline text-4xl">€</span>
            </div>
            <div className="text-[14px] text-white text-outline font-bold uppercase tracking-[0.6em] opacity-80 mt-2">
                {bocalMode === 'daily' ? 'Economies du Jour' : 'Economies du Mois'}
            </div>
        </div>
    )
}


export const BocalView: React.FC = () => {
    const sceneRef = useRef<HTMLDivElement>(null)
    const jarRef = useRef<HTMLDivElement>(null)

    // LAZY INITIALIZATION of Engine to prevent leaks/crashes on re-renders
    const engineRef = useRef<Matter.Engine | null>(null)
    if (!engineRef.current) {
        engineRef.current = Matter.Engine.create({
            enableSleeping: true,
            positionIterations: 20,
            velocityIterations: 20
        })
    }

    const itemsRef = useRef<MoneyBody[]>([])
    const wallsRef = useRef<Matter.Body[]>([])

    // VISUAL EFFECTS
    type FadingGhost = {
        x: number, y: number, angle: number,
        texture: string, width: number, type: 'coin' | 'bill',
        life: number // 1.0 -> 0.0
    }
    const fadingGhostsRef = useRef<FadingGhost[]>([])
    const mouseConstraintRef = useRef<Matter.MouseConstraint | null>(null)
    const imageCache = useRef<Map<string, HTMLImageElement>>(new Map())

    const scaleRef = useRef<number>(1)
    const [physicsScale, setPhysicsScale] = useState(1)
    const [isShaking, setIsShaking] = useState(false)
    const [resetTrigger, setResetTrigger] = useState(0)
    const [zoomLevel, setZoomLevel] = useState(1) // ZOOM STATE
    const zoomLevelRef = useRef(1)
    const physicsScaleRef = useRef(1)



    // SCROLL TO ZOOM HANDLER
    const handleWheel = useCallback((e: React.WheelEvent) => {
        // e.deltaY > 0 means scroll down (zoom out), e.deltaY < 0 means scroll up (zoom in)
        const delta = -e.deltaY * 0.001

        setZoomLevel(prev => {
            const newZoom = Math.min(Math.max(prev + delta, 1), 1.4)
            return parseFloat(newZoom.toFixed(2)) // Keep it clean
        })
    }, [])

    // DENOMINATION CAP: Index in DENOMINATIONS_SORTED (0 = 1c, max = 💎)
    const [maxDenomIndex, setMaxDenomIndex] = useState(DENOMINATIONS_SORTED.length - 1) // Default: all allowed
    const maxDenomValueRef = useRef(DENOMINATIONS_SORTED[DENOMINATIONS_SORTED.length - 1].value)

    // Sync ref when state changes + WAKE UP items when increasing limit
    const prevMaxDenomIndex = useRef(DENOMINATIONS_SORTED.length - 1)
    useEffect(() => {
        const newValue = DENOMINATIONS_SORTED[maxDenomIndex].value
        const oldValue = maxDenomValueRef.current
        maxDenomValueRef.current = newValue

        // If limit was INCREASED, wake up all sleeping items so they can merge
        if (newValue > oldValue) {
            itemsRef.current.forEach(item => {
                if (item.isStatic || item.isSleeping) {
                    Matter.Sleeping.set(item, false)
                    Matter.Body.setStatic(item, false)
                    item.isFrozen = false
                    // Give a tiny impulse to trigger collision detection
                    Matter.Body.applyForce(item, item.position, { x: 0, y: 0.0001 })
                }
            })
        }

        prevMaxDenomIndex.current = maxDenomIndex
    }, [maxDenomIndex])


    const lastWallConfig = useRef<{ w: number, h: number, x: number, y: number } | null>(null)
    const jarObserverRef = useRef<ResizeObserver | null>(null)

    // Sync Ref
    useEffect(() => {
        zoomLevelRef.current = zoomLevel
        // updateWallPositions will check if effective dimensions actually changed
        updateWallPositions()
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [zoomLevel]) // updateWallPositions is stable via useCallback, removed to prevent circular deps

    const setViewMode = useSalaryStore(s => s.setViewMode)
    const tick = useSalaryStore(s => s.tick)
    const hasInitializedBocal = useSalaryStore(s => s.hasInitializedBocal)
    const setHasInitializedBocal = useSalaryStore(s => s.setHasInitializedBocal)

    const bocalMode = useSalaryStore(s => s.bocalMode)
    const isDay = useWeatherStore(s => s.isDay)

    const lastTick = useRef<number>(Date.now())

    const freezeItem = useCallback((item: MoneyBody) => {
        if (item.isStatic) return
        Matter.Body.setStatic(item, true)
        item.isFrozen = true
    }, [])

    const wakeItem = useCallback((item: MoneyBody) => {
        if (!item.isFrozen) return
        Matter.Body.setStatic(item, false)
        item.isFrozen = false
    }, [])

    const updateWallPositions = useCallback(() => {
        if (!jarRef.current || !engineRef.current) return

        const scaledRect = jarRef.current.getBoundingClientRect()
        if (scaledRect.width === 0 || scaledRect.height === 0) return

        // Normalize rect back to scale=1
        const zoom = zoomLevelRef.current
        const effectiveWidth = scaledRect.width / zoom
        const effectiveHeight = scaledRect.height / zoom
        const effectiveLeft = (scaledRect.left - window.innerWidth / 2) / zoom + window.innerWidth / 2
        const effectiveTop = (scaledRect.top - window.innerHeight / 2) / zoom + window.innerHeight / 2

        // OPTIMIZATION & STABILITY:
        // Provide Tolerance (0.5px) to avoid rebuilding walls on micro-fluctuations during zoom/layout
        // This prevents "tunneling" where items fall through walls during the brief moment walls are removed/added.
        // IMPORTANT: Skip this optimization if walls don't exist yet (initial load)
        if (lastWallConfig.current && wallsRef.current.length > 0) {
            const c = lastWallConfig.current
            if (
                Math.abs(c.w - effectiveWidth) < 0.5 &&
                Math.abs(c.h - effectiveHeight) < 0.5 &&
                Math.abs(c.x - effectiveLeft) < 0.5 &&
                Math.abs(c.y - effectiveTop) < 0.5
            ) {
                return // Dimensions effectively unchanged, skip expensive physics update
            }
        }

        // CRITICAL: If walls don't exist yet but we have invalid dimensions, skip and wait for proper layout
        if (wallsRef.current.length === 0 && (effectiveWidth < 10 || effectiveHeight < 10)) {
            return // Layout not ready yet, skip this call
        }

        // Update Cache
        lastWallConfig.current = { w: effectiveWidth, h: effectiveHeight, x: effectiveLeft, y: effectiveTop }

        const world = engineRef.current.world

        if (wallsRef.current.length > 0) {
            Matter.World.remove(world, wallsRef.current)
        }

        // Calculate Scale Factor
        const scale = effectiveWidth / 1350

        const mapX = (x: number) => effectiveLeft + (x / 450) * effectiveWidth
        const mapY = (y: number) => effectiveTop + (y / 600) * effectiveHeight

        // DYNAMIC ITEM RESCALING logic
        if (itemsRef.current.length > 0 && scaleRef.current !== scale && scaleRef.current > 0) {
            const ratio = scale / scaleRef.current
            if (isFinite(ratio) && Math.abs(ratio - 1) > 0.001) {
                itemsRef.current.forEach(item => {
                    Matter.Body.scale(item, ratio, ratio)
                })
            }
        }

        scaleRef.current = scale
        setPhysicsScale(scale)
        physicsScaleRef.current = scale

        // Collision categories: walls = 0x0001, items = 0x0002
        const CATEGORY_WALL = 0x0001
        const CATEGORY_ITEM = 0x0002

        const wallOptions = {
            isStatic: true,
            render: { fillStyle: 'transparent' }, // Hidden
            collisionFilter: {
                category: CATEGORY_WALL,
                mask: CATEGORY_ITEM | CATEGORY_WALL // Walls collide with items and other walls
            }
        }
        const wallThick = 300 * scale

        const newWalls: Matter.Body[] = []

        const addSegment = (x1: number, y1: number, x2: number, y2: number, thickness: number = wallThick) => {
            const cx = (mapX(x1) + mapX(x2)) / 2
            const cy = (mapY(y1) + mapY(y2)) / 2
            const dx = mapX(x2) - mapX(x1)
            const dy = mapY(y2) - mapY(y1)
            const len = Math.sqrt(dx * dx + dy * dy)
            const angle = Math.atan2(dy, dx)

            const perpAngle = angle + Math.PI / 2
            const finalCX = cx - Math.cos(perpAngle) * (thickness / 2)
            const finalCY = cy - Math.sin(perpAngle) * (thickness / 2)

            const body = Matter.Bodies.rectangle(finalCX, finalCY, len + 10, thickness, {
                ...wallOptions,
                angle: angle
            })
            newWalls.push(body)
        }

        // Neck walls - height matches the visible jar texture (starts at y=0 instead of -50)
        addSegment(305, 0, 305, 80)   // Right neck wall
        addSegment(135, 80, 135, 0)   // Left neck wall
        addSegment(350, 0, 305, 0)    // Right upper funnel (Flat rim)
        addSegment(135, 0, 90, 0)     // Left upper funnel (Flat rim)
        addSegment(305, 80, 340, 100)
        addSegment(340, 100, 450, 255)
        addSegment(100, 100, 135, 80)
        addSegment(0, 255, 100, 100)
        addSegment(450, 255, 450, 520)
        addSegment(0, 520, 0, 255)
        addSegment(450, 520, 420, 575)
        addSegment(420, 575, 370, 600)
        addSegment(370, 600, 80, 600)
        addSegment(80, 600, 30, 575)
        addSegment(30, 575, 0, 520)

        wallsRef.current = newWalls
        Matter.World.add(world, newWalls)
    }, []) // REMOVED zoomLevel dependency, it is accessed via Ref

    const handleResetJar = useCallback(() => {
        if (!engineRef.current) return
        const world = engineRef.current.world
        Matter.World.clear(world, false)
        itemsRef.current = []
        hasManuallyEmptied.current = true // FORCE PENNY MODE after manual reset
        spawnTimeoutsRef.current.forEach(clearTimeout)
        spawnTimeoutsRef.current = []

        // FORCE WALL REBUILD
        wallsRef.current = []
        lastWallConfig.current = null
        updateWallPositions()

        // RE-ADD MOUSE CONSTRAINT (It was removed by World.clear)
        if (mouseConstraintRef.current) {
            Matter.World.add(world, mouseConstraintRef.current)
        }

        // TRIGGER REFILL
        setResetTrigger(prev => prev + 1)
    }, [updateWallPositions])

    // RESET JAR ON MODE CHANGE
    useEffect(() => {
        // When switching modes (Day/Month), we want to:
        // 1. Clear the jar
        // 2. Allow it to refill efficiently ("CatchUp" mode with large bills)

        // Call reset logic manually to avoid setting hasManuallyEmptied = true
        if (!engineRef.current) return
        const world = engineRef.current.world
        Matter.World.clear(world, false)
        itemsRef.current = []
        spawnTimeoutsRef.current.forEach(clearTimeout)
        spawnTimeoutsRef.current = []

        wallsRef.current = []
        lastWallConfig.current = null // FORCE UPDATE
        updateWallPositions()

        // RE-ADD MOUSE CONSTRAINT
        if (mouseConstraintRef.current) {
            Matter.World.add(world, mouseConstraintRef.current)
        }

        // CRITICAL: Ensure we are NOT in manual empty mode, so it uses optimized filling
        hasManuallyEmptied.current = false

    }, [bocalMode, updateWallPositions])

    const handleShake = () => {
        if (isShaking || !jarRef.current) return
        setIsShaking(true)
        setTimeout(() => setIsShaking(false), 500)

        // Calculate Jar Center X
        const rect = jarRef.current.getBoundingClientRect()
        // Un-scale coordinates to match physics world
        const zoom = zoomLevelRef.current
        const effectiveLeft = (rect.left - window.innerWidth / 2) / zoom + window.innerWidth / 2
        const effectiveWidth = rect.width / zoom
        const centerX = effectiveLeft + effectiveWidth / 2

        // SHAKE LOGIC: "Slosh" Effect
        // Propel items towards the OPPOSITE side of the jar.
        // If on Left -> Push Right. If on Right -> Push Left.

        // WAKE UP AND SHAKE ALL ITEMS
        itemsRef.current.forEach(item => {
            // Wake up from sleep mode
            if (item.isStatic || item.isSleeping) {
                Matter.Sleeping.set(item, false)
                Matter.Body.setStatic(item, false)
                item.isFrozen = false
            }

            wakeItem(item)

            // Determine direction to center/opposite side
            const dirX = item.position.x < centerX ? 1 : -1

            // Add some randomness but bias heavily towards the opposite side
            // Power: 0.15 to 0.25 * mass
            const power = (0.15 + Math.random() * 0.1) * item.mass

            const force = {
                x: dirX * power,
                y: -Math.random() * 0.15 * item.mass // Good upward kick
            }
            Matter.Body.applyForce(item, item.position, force)

            // Add random torque for spin
            Matter.Body.setAngularVelocity(item, (Math.random() - 0.5) * 0.5)
        })
    }

    const createItem = useCallback((config: ItemConfig, x: number, y: number, isNewMerge = false): MoneyBody => {
        // Collision categories: walls = 0x0001, items = 0x0002
        const CATEGORY_WALL = 0x0001
        const CATEGORY_ITEM = 0x0002

        const options: Matter.IChamferableBodyDefinition = {
            restitution: config.type === 'coin' || config.type === 'gem' ? 0.2 : 0.1,
            friction: config.type === 'ingot' ? 0.8 : 0.1,
            density: config.type === 'ingot' ? 0.005 : 0.001,
            frictionAir: config.type === 'bill' ? 0.02 : 0.01,
            angle: (Math.random() - 0.5) * Math.PI, // Random start angle
            // Sleeping threshold
            sleepThreshold: 60,
            render: {
                fillStyle: 'transparent',
                strokeStyle: 'transparent',
                lineWidth: 0
            },
            collisionFilter: {
                category: CATEGORY_ITEM,
                mask: CATEGORY_WALL | CATEGORY_ITEM // Items collide with walls and other items
            }
        }

        const scale = physicsScaleRef.current || 0.001 // Prevent 0 scale
        const radius = Math.max(0.1, (config.width * scale) / 2) // Prevent 0 radius
        let body: MoneyBody

        if (config.type === 'coin' || config.type === 'gem') {
            body = Matter.Bodies.circle(x, y, radius, options) as MoneyBody
        } else {
            const height = config.height * scale
            body = Matter.Bodies.rectangle(x, y, config.width * scale, height, options) as MoneyBody
        }

        body.denomination = config
        body.isFrozen = false
        // Add timestamp for "Growth" animation
        body.createdAt = isNewMerge ? Date.now() : 0 // 0 means no anim on load

        return body
    }, [])

    // TICK STABILIZATION
    useEffect(() => {
        const interval = setInterval(() => {
            const now = Date.now()
            tick(now - lastTick.current)
            lastTick.current = now
        }, 16)
        return () => clearInterval(interval)
    }, [tick])

    // PHYSIC STABILIZATION & CONFINEMENT LOOP
    useEffect(() => {
        const engine = engineRef.current
        const maxVelocity = 15
        const maxAngularVelocity = 0.2

        const stabilization = () => {
            const width = window.innerWidth
            const height = window.innerHeight
            const rect = jarRef.current?.getBoundingClientRect()
            if (!rect) return

            const zoom = zoomLevelRef.current
            const effectiveLeft = (rect.left - window.innerWidth / 2) / zoom + window.innerWidth / 2
            const effectiveWidth = rect.width / zoom
            const effectiveTop = (rect.top - window.innerHeight / 2) / zoom + window.innerHeight / 2

            itemsRef.current.forEach(body => {
                if (body.isStatic) return

                // 1. Strict Confinement REMOVED to allow Overflow
                // We no longer teleport items if they go outside the JAR bounds.
                // We only care if they fall off the WORLD (Global Floor).

                // 2. Global Out of Bounds (Fall Protection)
                // If it falls way below the jar/screen, bring it back to top
                if (body.position.y > height + 200 || body.position.x < -1000 || body.position.x > width + 1000) {
                    const spawnX = effectiveLeft + effectiveWidth / 2
                    Matter.Body.setPosition(body, { x: spawnX, y: effectiveTop - 50 })
                    Matter.Body.setVelocity(body, { x: 0, y: 0 })
                    wakeItem(body)
                    return
                }

                // 3. Velocity Capping
                if (Matter.Vector.magnitude(body.velocity) > maxVelocity) {
                    const capped = Matter.Vector.mult(Matter.Vector.normalise(body.velocity), maxVelocity)
                    Matter.Body.setVelocity(body, capped)
                }
                if (Math.abs(body.angularVelocity) > maxAngularVelocity) {
                    Matter.Body.setAngularVelocity(body, Math.sign(body.angularVelocity) * maxAngularVelocity)
                }
            })
        }

        Matter.Events.on(engine, 'beforeUpdate', stabilization)
        return () => Matter.Events.off(engine, 'beforeUpdate', stabilization)
    }, [wakeItem])

    // VELOCITY-BASED SLEEPING (The "Anti-Ghost" Logic)
    useEffect(() => {
        const interval = setInterval(() => {
            // Check active items (not frozen)
            const currentHeldBody = mouseConstraintRef.current?.body

            itemsRef.current.forEach(item => {
                if (item.isFrozen || item.isStatic) return

                // CRITICAL FIX: DO NOT FREEZE ITEM CURRENTLY HELD BY MOUSE
                if (item === currentHeldBody) return

                // If practically staying still
                if (item.speed < 0.15 && Math.abs(item.angularVelocity) < 0.1) {
                    freezeItem(item)
                }
            })
        }, 1000) // Check every second

        return () => clearInterval(interval)
    }, [freezeItem])

    // MAIN MATTER.JS SETUP (Run once)
    useEffect(() => {
        if (!sceneRef.current || !engineRef.current) return

        const engine = engineRef.current
        const world = engine.world

        // FORCE CLEAR on setup to avoid ghost items from HMR or previous state
        Matter.World.clear(world, false)
        itemsRef.current = []
        wallsRef.current = []
        lastWallConfig.current = null
        // Rebuild walls immediately if jar is already mounted (recovers from World.clear wiping callback-created walls)
        if (jarRef.current) updateWallPositions()

        const width = window.innerWidth
        const height = window.innerHeight

        const render = Matter.Render.create({
            element: sceneRef.current,
            engine: engine,
            options: {
                width, height,
                fillStyle: 'transparent',
                strokeStyle: 'transparent',
                opacity: 0,
                lineWidth: 0,
                wireframes: false,
                background: 'transparent'
            }
        })

        // Store render reference for zoom updates
        const renderRef = { current: render }

        // Mouse interaction with ZOOM-AWARE coordinate transformation
        const mouse = Matter.Mouse.create(render.canvas)

        // Override mouse position to account for zoom
        const originalSetOffset = mouse.offset
        const updateMouseForZoom = () => {
            // Transform screen coordinates to physics world coordinates
            const zoom = zoomLevelRef.current
            const centerX = window.innerWidth / 2
            const centerY = window.innerHeight / 2

            // Custom mousemove handler to transform coordinates
            render.canvas.addEventListener('mousemove', (e) => {
                // Get raw screen position
                const rect = render.canvas.getBoundingClientRect()
                const screenX = e.clientX - rect.left
                const screenY = e.clientY - rect.top

                // Transform: inverse zoom around center
                const zoom = zoomLevelRef.current
                const transformedX = centerX + (screenX - centerX) / zoom
                const transformedY = centerY + (screenY - centerY) / zoom

                // Update Matter.js mouse position directly
                mouse.position.x = transformedX
                mouse.position.y = transformedY
                mouse.absolute.x = transformedX
                mouse.absolute.y = transformedY
            })
        }
        updateMouseForZoom()

        // Collision categories: walls = 0x0001, items = 0x0002
        const CATEGORY_ITEM = 0x0002

        const mouseConstraint = Matter.MouseConstraint.create(engine, {
            mouse: mouse,
            constraint: {
                stiffness: 0.05,
                render: {
                    visible: false // Hide the constraint line
                }
            },
            collisionFilter: {
                mask: CATEGORY_ITEM // Only interact with items, NOT walls
            }
        })

        // CRITICAL FIX: WAKE ITEM ON DRAG START
        Matter.Events.on(mouseConstraint, 'startdrag', (event) => {
            const body = event.body as MoneyBody
            if (body) {
                // Determine if we need to wake it
                if (body.isStatic || body.isFrozen) {
                    Matter.Body.setStatic(body, false)
                    body.isFrozen = false
                    body.isStatic = false // Ensure it's not static
                }
            }
        })

        Matter.Events.on(mouseConstraint, 'enddrag', (event) => {
            const body = event.body as MoneyBody
            // Optional: We could re-evaluate specific logic here, but usually fine to let physics take over
        })

        mouseConstraintRef.current = mouseConstraint
        Matter.World.add(world, mouseConstraint)

        updateWallPositions()

        // CANVAS RESIZING (Visuals)
        const handleWindowResize = () => {
            render.canvas.width = window.innerWidth
            render.canvas.height = window.innerHeight
        }
        window.addEventListener('resize', handleWindowResize)

        // JAR RESIZING (Physics Scale)
        // Handled via "setJarRef" callback now for robustness

        const runner = Matter.Runner.create()
        Matter.Runner.run(runner, engine)
        Matter.Render.run(render)

        const handleCollision = (event: Matter.IEventCollision<Matter.Engine>) => {
            const pairs = event.pairs
            const toRemove: MoneyBody[] = []
            const toAdd: { config: ItemConfig, x: number, y: number }[] = []

            pairs.forEach(pair => {
                const { bodyA, bodyB } = pair as unknown as { bodyA: MoneyBody, bodyB: MoneyBody }
                if (!bodyA.denomination || !bodyB.denomination) return

                // WAKE ON IMPACT LOGIC
                // If one body is static (frozen) and hit by a moving body, wake it up!
                const speedA = bodyA.speed
                const speedB = bodyB.speed
                const impactThreshold = 0.5 // Minimal speed to wake up a neighbor

                if (bodyA.isStatic && !bodyB.isStatic && speedB > impactThreshold) {
                    wakeItem(bodyA)
                }
                else if (bodyB.isStatic && !bodyA.isStatic && speedA > impactThreshold) {
                    wakeItem(bodyB)
                }

                const valA = bodyA.denomination.value
                const valB = bodyB.denomination.value

                const directRecipe = MERGE_RECIPES.find(r => r.inputs.length === 2 && r.inputs[0] === valA && r.inputs[1] === valB)

                // CHECK DENOMINATION CAP: Skip merge if any output exceeds max allowed
                if (directRecipe && directRecipe.outputs.some(v => v > maxDenomValueRef.current)) {
                    return // Don't merge - output would exceed cap
                }

                if (directRecipe && !toRemove.includes(bodyA) && !toRemove.includes(bodyB)) {
                    toRemove.push(bodyA, bodyB)
                    directRecipe.outputs.forEach((outVal, idx) => {
                        toAdd.push({
                            config: DENOMINATIONS.find(d => d.value === outVal)!,
                            x: (bodyA.position.x + bodyB.position.x) / 2 + (idx * 5),
                            y: (bodyA.position.y + bodyB.position.y) / 2 - (idx * 5)
                        })
                    })
                    return
                }

                // Triple Merge Logic
                // Limit this check to only run rarely or optimize
                const tripleRecipes = MERGE_RECIPES.filter(r => r.inputs.length === 3)
                for (const recipe of tripleRecipes) {
                    // CHECK DENOMINATION CAP: Skip if any output exceeds max allowed
                    if (recipe.outputs.some(v => v > maxDenomValueRef.current)) {
                        continue // Don't process this recipe - output would exceed cap
                    }

                    const needed = [...recipe.inputs]
                    const idxA = needed.indexOf(valA)
                    if (idxA > -1) needed.splice(idxA, 1)
                    else continue

                    const idxB = needed.indexOf(valB)
                    if (idxB > -1) needed.splice(idxB, 1)
                    else continue

                    const targetVal = needed[0]
                    // Optimize: Use spatial hash or similar if possible, but for now just limit scope?
                    // Matter.Query is relatively fast but doing it inside loop is dangerous.
                    // Let's keep it but be aware.
                    const thirdBody = itemsRef.current.find(c => {
                        if (c === bodyA || c === bodyB || toRemove.includes(c)) return false
                        if (c.denomination.value !== targetVal) return false
                        return Matter.Query.collides(c, [bodyA, bodyB]).length > 0
                    })

                    if (thirdBody) {
                        toRemove.push(bodyA, bodyB, thirdBody)
                        const centerX = (bodyA.position.x + bodyB.position.x + thirdBody.position.x) / 3
                        const centerY = (bodyA.position.y + bodyB.position.y + thirdBody.position.y) / 3
                        recipe.outputs.forEach((outVal, idx) => {
                            toAdd.push({
                                config: DENOMINATIONS.find(d => d.value === outVal)!,
                                x: centerX + (idx * 5),
                                y: centerY - (idx * 5)
                            })
                        })
                        break
                    }
                }
            })

            if (toRemove.length > 0) {
                let reattachToNewBody = false
                const currentHeldBody = mouseConstraintRef.current?.body

                // ADD GHOSTS BEFORE REMOVING
                toRemove.forEach(item => {
                    if (item === currentHeldBody) {
                        reattachToNewBody = true
                    }

                    if (item.denomination && item.denomination.texture) {
                        const fadingGhosts = fadingGhostsRef.current
                        fadingGhosts.push({
                            x: item.position.x,
                            y: item.position.y,
                            angle: item.angle,
                            texture: item.denomination.texture,
                            width: item.denomination.width,
                            type: item.denomination.type as 'coin' | 'bill',
                            life: 1.0 // Start full opacity
                        })
                    }
                })

                Matter.World.remove(world, toRemove)
                itemsRef.current = itemsRef.current.filter(i => !toRemove.includes(i))

                toAdd.forEach(item => {
                    const body = createItem(item.config, item.x, item.y, true)
                    Matter.World.add(world, body)
                    itemsRef.current.push(body)

                    // STICKY MERGE: If we were holding one of the merged items, grab the new one!
                    if (reattachToNewBody && mouseConstraintRef.current) {
                        mouseConstraintRef.current.body = body
                        mouseConstraintRef.current.constraint.bodyB = body
                        mouseConstraintRef.current.constraint.pointB = { x: 0, y: 0 }
                        mouseConstraintRef.current.constraint.angleB = body.angle
                        Matter.World.add(world, mouseConstraintRef.current.constraint)
                        reattachToNewBody = false // Only grab one
                    }
                })
            }
        }

        Matter.Events.on(engine, 'collisionStart', handleCollision)

        // DRAW LABELS ON ITEMS with ZOOM
        Matter.Events.on(render, 'afterRender', () => {
            const context = render.context
            if (!context) return

            const zoom = zoomLevelRef.current
            const centerX = window.innerWidth / 2
            const centerY = window.innerHeight / 2

            // Apply zoom transformation to the canvas
            context.save()
            context.translate(centerX, centerY)
            context.scale(zoom, zoom)
            context.translate(-centerX, -centerY)

            itemsRef.current.forEach(item => {
                const { position, angle, denomination } = item
                if (!denomination) return

                // MANUAL DRAW LOOP
                context.save()
                context.translate(position.x, position.y)
                context.rotate(angle)

                if (denomination.texture) {
                    // REALISTIC MODE
                    const scale = scaleRef.current

                    // GET OR CREATE CACHED IMAGE
                    let img = imageCache.current.get(denomination.texture)
                    if (!img) {
                        img = new Image()
                        img.src = denomination.texture
                        imageCache.current.set(denomination.texture, img)
                    }

                    // ANIMATION LOGIC: GROWTH & BRIGHTNESS
                    let animScale = 1.0
                    let brightness = 100 // %

                    // Only animate if created recently (and is a merged item, assuming we check createdAt > 0)
                    if (item.createdAt && item.createdAt > 0) {
                        const age = Date.now() - item.createdAt
                        if (age < 500) {
                            const progress = age / 500
                            // EaseOutBack: c1 = 1.70158; c3 = c1 + 1; return 1 + c3 * Math.pow(x - 1, 3) + c1 * Math.pow(x - 1, 2);
                            // Simplified "Pop" grow:
                            // 0 -> 1.1 -> 1.0
                            // Let's use simple Linear for size 0->1 very fast, then settle
                            // Better: 0.5 + 0.5 * progress (grow from half size)
                            animScale = 0.2 + 0.8 * Math.pow(progress, 0.5) // Fast grow start

                            // Brightness: 300% -> 100%
                            brightness = 100 + (1 - progress) * 200
                        }
                    }

                    // Apply Brightness Filter
                    if (brightness > 100) {
                        context.filter = `brightness(${brightness}%)`
                    }

                    // Assume 1024px source size for calculation, keep sync with creation logic
                    const sourceSize = 1024

                    if (denomination.type === 'coin') {
                        // COINS
                        const radius = (denomination.width * scale) / 2

                        context.beginPath()
                        context.arc(0, 0, radius, 0, 2 * Math.PI)

                        // 1. Clip to hitbox
                        context.clip()

                        // 3. Draw Texture Zoomed & Scaled by Animation
                        // Use Specific Scale + Animation.
                        const specificScale = denomination.textureScale ?? 1.1
                        const drawZoom = specificScale * animScale
                        const drawSize = (denomination.width * scale) * drawZoom

                        context.drawImage(
                            img,
                            -drawSize / 2,
                            -drawSize / 2,
                            drawSize,
                            drawSize
                        )
                        // ...

                    } else if (denomination.type === 'ingot') {
                        // INGOTS
                        const drawZoom = (denomination.textureScale ?? 1.35) * animScale
                        const drawSizeW = (denomination.width * scale) * drawZoom * 1.1 // Stretched length by 10%
                        const drawSizeH = (denomination.height * scale) * drawZoom * 1.2 // Stretched height by 20% total

                        context.drawImage(
                            img,
                            -drawSizeW / 2,
                            -drawSizeH / 2,
                            drawSizeW,
                            drawSizeH
                        )

                    } else {
                        // BILLS
                        const drawZoom = (denomination.textureScale ?? 1.35) * animScale
                        const drawSize = (denomination.width * scale) * drawZoom

                        // Draw Texture as SQUARE (width x width) to preserve 1:1 source aspect
                        context.drawImage(
                            img,
                            -drawSize / 2,
                            -drawSize / 2,
                            drawSize,
                            drawSize
                        )
                    }

                    // Reset Filter
                    if (brightness > 100) {
                        context.filter = 'none'
                    }

                } else {
                    // VECTOR MODE (Legacy Labels)
                    context.fillStyle = denomination.borderColor
                    context.textAlign = 'center'
                    context.textBaseline = 'middle'

                    const scale = scaleRef.current
                    const fontSize = denomination.type === 'coin'
                        ? Math.max(12, (denomination.width * scale) * 0.35)
                        : Math.max(20, (denomination.height * scale) * 0.35)

                    context.font = `bold ${fontSize}px "Outfit", sans-serif`
                    context.fillText(denomination.displayText, 0, 0)
                }

                context.restore()
            })

            // DRAW FADING GHOSTS (Merged Inputs disappearing)
            for (let i = fadingGhostsRef.current.length - 1; i >= 0; i--) {
                const ghost = fadingGhostsRef.current[i]
                ghost.life -= 0.08 // Fast fade (approx 12 frames -> 200ms)

                if (ghost.life <= 0) {
                    fadingGhostsRef.current.splice(i, 1)
                    continue
                }

                context.save()
                context.translate(ghost.x, ghost.y)
                context.rotate(ghost.angle)
                context.globalAlpha = ghost.life // FADE OUT

                const scale = scaleRef.current

                // GET OR CREATE CACHED IMAGE
                let img = imageCache.current.get(ghost.texture)
                if (!img) {
                    img = new Image()
                    img.src = ghost.texture
                    imageCache.current.set(ghost.texture, img)
                }

                if (ghost.type === 'coin') {
                    // Coins: MUST CLIP to match the alive item's visual size
                    const radius = (ghost.width * scale) / 2
                    context.beginPath()
                    context.arc(0, 0, radius, 0, 2 * Math.PI)
                    context.clip()

                    // We reuse the zoom logic to match size
                    const drawZoom = ghost.denomination?.textureScale ?? 1.75
                    const drawSize = (ghost.width * scale) * drawZoom
                    context.drawImage(img, -drawSize / 2, -drawSize / 2, drawSize, drawSize)
                } else {
                    // Bills
                    const drawZoom = ghost.denomination?.textureScale ?? 1.35
                    const drawSize = (ghost.width * scale) * drawZoom
                    context.drawImage(img, -drawSize / 2, -drawSize / 2, drawSize, drawSize)
                }

                context.restore()
            }

            // Restore the zoom transformation
            context.restore()
        })

        return () => {
            window.removeEventListener('resize', handleWindowResize)
            // jarObserverRef is handled in its own callback ref
            Matter.Events.off(engine, 'collisionStart', handleCollision)
            Matter.Render.stop(render)
            Matter.Runner.stop(runner)
            if (render.canvas) render.canvas.remove()
        }
    }, [updateWallPositions, wakeItem, createItem])

    // SYNC JAR CONTENT WITH DISPLAYED COUNTER (SELF-CORRECTING)
    const displayedAccumulated = useSalaryStore(s => s.displayedAccumulated)
    const lastProcessedValue = useRef<number>(0)
    const spawnTimeoutsRef = useRef<NodeJS.Timeout[]>([])
    const hasManuallyEmptied = useRef(false)



    // Wait for physics scale to be determined before spawning
    // Wait for physics scale to be determined before spawning
    useEffect(() => {
        const checkSpawning = () => {
            if (!jarRef.current || physicsScale === 0) return

            const accumulated = useSalaryStore.getState().accumulated

            // 1. Calculate REAL current value in the jar
            const currentValueInJar = itemsRef.current.reduce((sum, item) => sum + item.denomination.value, 0)

            // 2. Calculate the gap (Use accumulated (REAL) instead of displayed (ANIMATED) to ensure we see the full gap on load)
            const gap = parseFloat((accumulated - currentValueInJar).toFixed(2))

            // Only spawn if we are missing money (avoid infinite loops if merging)
            if (gap < 0.01) return

            // Clear pending scheduled spawns to avoid duplicates
            spawnTimeoutsRef.current.forEach(clearTimeout)
            spawnTimeoutsRef.current = []

            if (!engineRef.current) return
            const world = engineRef.current.world
            const rect = jarRef.current.getBoundingClientRect()

            const zoom = zoomLevelRef.current
            const effectiveWidth = rect.width / zoom
            const effectiveLeft = (rect.left - window.innerWidth / 2) / zoom + window.innerWidth / 2

            const neckW = effectiveWidth * (170 / 450)
            const centerX = effectiveLeft + effectiveWidth / 2

            let remainingGap = gap
            const toSpawn: ItemConfig[] = []
            let spawnDelay = 400 // Default slow rain for live updates

            // 3. Determine Spawn Strategy
            // "First Navigation" / Catch-Up Logic:
            // If we haven't manually emptied the jar AND the gap is significant (> 2€), we assume we need to fill it up efficiently
            const isCatchUpMode = !hasManuallyEmptied.current && gap > 2.0

            if (isCatchUpMode) {
                // STRATEGY: OPTIMIZED (First Load / Catch Up)
                // Fill the jar efficiently with largest denominations
                spawnDelay = 150 // Moderate speed for initial load (not too fast, not too slow)

                // Filter denominations by max allowed
                const allowedConfigs = DENOMINATIONS.filter(d => d.value <= maxDenomValueRef.current)

                for (const config of allowedConfigs) {
                    const count = Math.floor(parseFloat((remainingGap / config.value).toFixed(4)))
                    if (count > 0) {
                        const actualToSpawn = Math.min(count, 30) // Batch limit
                        for (let i = 0; i < actualToSpawn; i++) {
                            toSpawn.push(config)
                        }
                        remainingGap = parseFloat((remainingGap - (actualToSpawn * config.value)).toFixed(2))
                    }
                    if (toSpawn.length > 50) break
                }
            } else {
                // STRATEGY: RESET MODE (Smart Fill)
                // If the gap is huge, don't just use pennies!
                // Dynamically enable larger denominations based on remaining amount.

                // ALL denominations from high to low (always include smallest coins)
                let allowedDenoms: number[] = []

                if (remainingGap > 500) {
                    // Huge gap: Allow everything up to 50€ + all small coins
                    allowedDenoms = [50, 20, 10, 5, 2, 1, 0.50, 0.20, 0.10, 0.05, 0.02, 0.01]
                } else if (remainingGap > 100) {
                    // Big gap: Allow bills up to 10€ + all small coins
                    allowedDenoms = [10, 5, 2, 1, 0.50, 0.20, 0.10, 0.05, 0.02, 0.01]
                } else if (remainingGap > 20) {
                    // Moderate gap: Allow coins up to 2€ + all small coins
                    allowedDenoms = [2, 1, 0.50, 0.20, 0.10, 0.05, 0.02, 0.01]
                } else {
                    // Small gap: The classic "Penny Rain"
                    allowedDenoms = [0.20, 0.10, 0.05, 0.02, 0.01]
                }

                // Filter by max denomination cap
                allowedDenoms = allowedDenoms.filter(v => v <= maxDenomValueRef.current)

                // FALLBACK: If filter removed everything, use smallest available denomination
                if (allowedDenoms.length === 0) {
                    allowedDenoms = [maxDenomValueRef.current]
                }

                // Calculate dynamic delay based on remaining gap
                if (remainingGap > 50) spawnDelay = 40 // Faster for big amounts
                else if (remainingGap > 10) spawnDelay = 60
                else if (remainingGap > 2) spawnDelay = 100
                else spawnDelay = 200

                for (const val of allowedDenoms) {
                    const config = DENOMINATIONS.find(d => d.value === val)
                    if (config) {
                        const count = Math.floor(parseFloat((remainingGap / config.value).toFixed(4)))
                        if (count > 0) {
                            const batchLimit = 50 // Keep batches reasonable
                            const actualToSpawn = Math.min(count, batchLimit)

                            for (let i = 0; i < actualToSpawn; i++) {
                                toSpawn.push(config)
                            }

                            remainingGap = parseFloat((remainingGap - (actualToSpawn * config.value)).toFixed(2))
                        }
                    }
                    if (toSpawn.length > 150) break
                }
            }

            // 4. Batch Spawn
            toSpawn.forEach((config, idx) => {
                const timeout = setTimeout(() => {
                    if (!jarRef.current) return
                    // Pass current physicsScale manually to ensure closure freshness if needed, 
                    // though createItem reads ref. The key is that we waited for scale to be ready.
                    const body = createItem(config, centerX + (Math.random() - 0.5) * (neckW * 0.2), -150)
                    Matter.World.add(world, body)
                    itemsRef.current.push(body)

                    // Remove timeout from tracker when done
                    spawnTimeoutsRef.current = spawnTimeoutsRef.current.filter(t => t !== timeout)
                }, idx * spawnDelay) // SPAWN RATE: Dynamic based on strategy
                spawnTimeoutsRef.current.push(timeout)
            })
        }

        // Run check immediately and then on interval
        checkSpawning()
        const interval = setInterval(checkSpawning, 500) // Check every 500ms

        return () => {
            clearInterval(interval)
            spawnTimeoutsRef.current.forEach(clearTimeout)
        }
    }, [createItem, physicsScale, resetTrigger])

    // CALLBACK REF REFACTOR
    const setJarRef = useCallback((node: HTMLDivElement | null) => {
        (jarRef as React.MutableRefObject<HTMLDivElement | null>).current = node

        // CLEANUP: Disconnect previous observer if exists
        if (jarObserverRef.current) {
            jarObserverRef.current.disconnect()
            jarObserverRef.current = null
        }

        if (node) {
            console.log("LOG: Jar Node Mounted. Initializing Walls via Callback Ref.")
            const resizeObserver = new ResizeObserver(() => updateWallPositions())
            resizeObserver.observe(node)
            jarObserverRef.current = resizeObserver

            // Retry logic
            const ensureWallsCreated = (retries = 20) => {
                requestAnimationFrame(() => {
                    // Verify node is still current
                    if (jarRef.current !== node) return

                    // Force update
                    if (wallsRef.current.length === 0) lastWallConfig.current = null
                    updateWallPositions()

                    if (wallsRef.current.length === 0 && retries > 0) {
                        setTimeout(() => ensureWallsCreated(retries - 1), 100)
                    }
                })
            }
            ensureWallsCreated()
        }
    }, [updateWallPositions])

    return (
        <div
            className={`fixed inset-0 flex flex-col items-center justify-center p-8 z-50 overflow-hidden transition-colors duration-1000 ${isDay ? 'bg-sky-900' : 'bg-slate-950'} pointer-events-none`}
            style={{ backgroundColor: isDay ? '#0c4a6e' : '#020617' }} // Fallback solid color to prevent transparency
            onWheel={handleWheel}
        >

            {/* ZOOM CONTAINER - Background and decorations ONLY (not physics canvas) */}
            <div
                className="absolute inset-0 w-full h-full flex flex-col items-center justify-center"
                style={{ transform: `scale(${zoomLevel})`, transformOrigin: 'center center' }}
            >
                {/* Immersive Background - Static */}
                <div
                    className="absolute inset-0 bg-cover bg-center pointer-events-none opacity-100"
                    style={{ backgroundImage: `url(${imgBocalEnv})` }}
                />
                <div className="absolute inset-0 bg-black/30 pointer-events-none" /> {/* Dimmer */}

                {/* Weather Layer - Static (Atmosphere) */}
                <WeatherLayer />

                {/* Jar Decoration - Zoomed with background, z-35 to be above canvas (z-25) */}
                <div className={`absolute inset-0 w-full h-full flex flex-col items-center justify-center z-[35] ${isShaking ? 'camera-shake' : ''}`}>
                    <div className="absolute inset-0 bg-[radial-gradient(circle_at_center,rgba(99,102,241,0.1)_0%,transparent_75%)] pointer-events-none" />
                    <JarDecoration jarRef={setJarRef} />
                    <ScoreDisplay />
                </div>
            </div>

            {/* PHYSICS CANVAS - OUTSIDE zoom container, handles its own zoom via context transform */}
            <div
                ref={sceneRef}
                className={`absolute inset-0 w-full h-full pointer-events-auto outline-none focus:outline-none ring-0 ${isShaking ? 'camera-shake' : ''}`}
                style={{ zIndex: 25 }} // Above background, below UI
            />

            {/* FIXED UI LAYER (Not Zoomed) */}

            {/* FPS Counter (Debug) */}
            <div className="absolute top-4 left-4 z-50 pointer-events-auto">
                <FpsCounter />
            </div>

            <div className="absolute top-8 left-8 flex flex-col gap-4 z-[100] pointer-events-auto">
                <button
                    onClick={() => setViewMode('setup')}
                    className="flex items-center gap-3 px-6 py-3 bg-white/5 hover:bg-white/10 rounded-2xl text-white transition-all border border-white/10 no-drag shadow-2xl backdrop-blur-md pointer-events-auto w-full"
                >
                    <ArrowLeft size={20} /> Retour
                </button>

                <button
                    onClick={handleShake}
                    className="flex items-center gap-3 px-6 py-4 bg-indigo-600 hover:bg-indigo-500 rounded-2xl text-white transition-all border border-white/20 no-drag shadow-2xl font-bold uppercase tracking-wider group pointer-events-auto w-full justify-center"
                >
                    <RefreshCw size={22} className={`group-hover:rotate-180 transition-transform duration-500 ${isShaking ? 'animate-spin' : ''}`} />
                    Secouer
                </button>

                <button
                    onClick={handleResetJar}
                    className="flex items-center gap-3 px-6 py-3 bg-orange-500/10 hover:bg-orange-500/20 rounded-2xl text-orange-400 transition-all border border-orange-500/20 no-drag backdrop-blur-md opacity-60 hover:opacity-100 w-full justify-center"
                >
                    Reset
                </button>


                {/* DENOMINATION CAP SLIDER */}
                <div className="flex flex-col gap-2 p-4 rounded-xl bg-black/40 backdrop-blur-md border border-white/10 w-full">
                    <div className="flex items-center justify-between text-white text-outline text-xs font-bold uppercase tracking-wider mb-2">
                        <span>Plus gros billet</span>
                        <span className="text-white text-outline">{getDenominationLabel(DENOMINATIONS_SORTED[maxDenomIndex].value)}</span>
                    </div>
                    <Slider
                        min={0}
                        max={DENOMINATIONS_SORTED.length - 1}
                        step={1}
                        value={maxDenomIndex}
                        onChange={(val) => typeof val === 'number' && setMaxDenomIndex(val)}
                        trackStyle={{ backgroundColor: '#f59e0b', height: 4 }}
                        handleStyle={{
                            border: '2px solid #f59e0b',
                            backgroundColor: '#1e1b4b',
                            opacity: 1,
                            width: 14,
                            height: 14,
                            marginTop: -5
                        }}
                        railStyle={{ backgroundColor: 'rgba(255,255,255,0.1)', height: 4 }}
                    />
                    <div className="flex justify-between text-[9px] text-white text-outline mt-1">
                        <span>1c</span>
                        <span>💎</span>
                    </div>
                </div>

                {/* ZOOM SLIDER - RESTORED */}
                <div className="flex flex-col gap-2 p-4 rounded-xl bg-black/40 backdrop-blur-md border border-white/10 w-full">
                    <div className="flex items-center justify-between text-white text-outline text-xs font-bold uppercase tracking-wider mb-2">
                        <span>Zoom</span>
                        <span className="text-white text-outline">{Math.round(zoomLevel * 100)}%</span>
                    </div>
                    <div className="flex items-center gap-3">
                        <ZoomOut size={14} className="text-slate-400" />
                        <Slider
                            min={1.0}
                            max={1.4}
                            step={0.01}
                            value={zoomLevel}
                            onChange={(val) => typeof val === 'number' && setZoomLevel(val)}
                            trackStyle={{ backgroundColor: '#818cf8', height: 4 }}
                            handleStyle={{
                                border: '2px solid #818cf8',
                                backgroundColor: '#1e1b4b',
                                opacity: 1,
                                width: 14,
                                height: 14,
                                marginTop: -5
                            }}
                            railStyle={{ backgroundColor: 'rgba(255,255,255,0.1)', height: 4 }}
                        />
                        <ZoomIn size={14} className="text-slate-400" />
                    </div>
                </div>
                <div className="mt-4 border-t border-white/10 pt-4 space-y-4">
                    <div className="flex bg-black/40 p-1 rounded-xl backdrop-blur-xl border border-white/10 w-full">
                        <button
                            onClick={() => useSalaryStore.getState().setBocalMode('daily')}
                            className={`flex-1 py-2 rounded-lg text-xs font-bold uppercase text-outline tracking-wider transition-all ${useSalaryStore(s => s.bocalMode) === 'daily' ? 'bg-white/10 text-white shadow-sm' : 'text-slate-300 hover:text-white'}`}
                        >
                            Jour
                        </button>
                        <button
                            onClick={() => useSalaryStore.getState().setBocalMode('monthly')}
                            className={`flex-1 py-2 rounded-lg text-xs font-bold uppercase text-outline tracking-wider transition-all ${useSalaryStore(s => s.bocalMode) === 'monthly' ? 'bg-indigo-500/20 text-white shadow-sm border border-indigo-500/30' : 'text-slate-300 hover:text-white'}`}
                        >
                            Mois
                        </button>
                    </div>

                    <BureauControls orientation="vertical" showWeather={false} />
                </div>
            </div>
        </div>
    )
}

