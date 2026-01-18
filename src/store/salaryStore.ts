import { create } from 'zustand'

interface SalaryState {
    wage: number // hourly rate
    monthlyNet: number
    accumulated: number // The active target value (Daily or Monthly depending on mode)
    dailyAccumulated: number // Internal: always tracks daily total
    displayedAccumulated: number // what the user sees
    isCatchingUp: boolean
    viewMode: 'setup' | 'widget' | 'bocal'
    bocalMode: 'daily' | 'monthly'
    hasInitializedBocal: boolean
    workingDays: number[] // 0=Sun, 1=Mon, ..., 6=Sat
    workStartHour: number // 0-23
    workEndHour: number // 0-24
    setMonthlyNet: (net: number) => void
    setViewMode: (mode: 'setup' | 'widget' | 'bocal') => void
    setBocalMode: (mode: 'daily' | 'monthly') => void
    setHasInitializedBocal: (initialized: boolean) => void
    setWorkingDays: (days: number[]) => void
    setWorkHours: (start: number, end: number) => void
    tick: (ms: number) => void
    loadSalaryData: () => Promise<void>
}

// Fixed constant for 39h/week: (39 * 52) / 12 = 169h/month
const HOURS_PER_MONTH_39H = 169
const COIN_THRESHOLD = 0.01 // Spawn a coin every 1 cent

export const useSalaryStore = create<SalaryState>((set, get) => ({
    wage: 0,
    monthlyNet: 0,
    accumulated: 0,
    dailyAccumulated: 0,
    displayedAccumulated: 0,
    isCatchingUp: false,
    viewMode: 'setup',
    bocalMode: 'daily',
    hasInitializedBocal: false,
    workingDays: [1, 2, 3, 4, 5], // Default Mon-Fri
    workStartHour: 9,
    workEndHour: 17,
    setMonthlyNet: (net: number) => {
        const hourlyRate = net / HOURS_PER_MONTH_39H
        const { workStartHour, workEndHour, workingDays } = get()

        // Calculate earnings since Start Hour today, capped at End Hour
        const now = new Date()
        const currentDay = now.getDay()
        let earnedSinceStart = 0

        if (workingDays.includes(currentDay)) {
            const todayStart = new Date(now)
            todayStart.setHours(workStartHour, 0, 0, 0)

            const todayEnd = new Date(now)
            todayEnd.setHours(workEndHour, 0, 0, 0)

            // If now is past End Hour, we cap the calculation time at End Hour
            const calcTime = now > todayEnd ? todayEnd : now

            // If now is before Start Hour, calcTime < todayStart -> msSinceStart = 0
            const msSinceStart = Math.max(0, calcTime.getTime() - todayStart.getTime())
            earnedSinceStart = (hourlyRate / (60 * 60 * 1000)) * msSinceStart
        }

        set({
            monthlyNet: net,
            wage: hourlyRate,
            accumulated: earnedSinceStart,
            dailyAccumulated: earnedSinceStart, // Initialize daily
            displayedAccumulated: 0,
            isCatchingUp: earnedSinceStart > 0,
            hasInitializedBocal: false
        })

        if (window.electron) {
            window.electron.setWage(hourlyRate)
        }
    },
    setViewMode: (mode) => {
        set({ viewMode: mode })
        if (window.electron) {
            window.electron.switchWindowMode(mode === 'widget' ? 'widget' : 'main')
        }
    },
    setBocalMode: (mode) => {
        set({ bocalMode: mode, hasInitializedBocal: false })
    },
    setHasInitializedBocal: (initialized) => {
        set({ hasInitializedBocal: initialized })
    },
    setWorkingDays: (days) => set({ workingDays: days }),
    setWorkHours: (start, end) => set({ workStartHour: start, workEndHour: end }),
    tick: (ms) => {
        const { wage, dailyAccumulated, displayedAccumulated, isCatchingUp, bocalMode, workingDays, workStartHour, workEndHour } = get()
        if (wage <= 0) return

        // 1. Update real accumulated
        const earnedPerMs = wage / (60 * 60 * 1000)

        const now = new Date()
        const currentHour = now.getHours()
        const currentDayOfWeek = now.getDay() // 0 = Sun, 6 = Sat

        let nextDailyAccumulated = dailyAccumulated

        // Accumulate only during working hours on working days
        // Note: Simple check currentHour >= start && currentHour < end handles standard hours.
        // For partial minutes, the tick ms simply adds up.
        // Boundary case: if currentHour changes from 16 to 17 (end), we stop.
        const isWorkingTime = currentHour >= workStartHour && currentHour < workEndHour
        const isWorkingDay = workingDays.includes(currentDayOfWeek)

        if (isWorkingTime && isWorkingDay) {
            nextDailyAccumulated = dailyAccumulated + (earnedPerMs * ms)
        }

        // Calculate Monthly Total (Excluding non-working days)
        const currentDayOfMonth = now.getDate()
        let workingDaysPrior = 0

        // Loop from 1st of month to yesterday
        for (let d = 1; d < currentDayOfMonth; d++) {
            const dateToCheck = new Date(now.getFullYear(), now.getMonth(), d)
            const dayOfWeek = dateToCheck.getDay()

            if (workingDays.includes(dayOfWeek)) {
                workingDaysPrior++
            }
        }

        const dailyHours = workEndHour - workStartHour
        const hoursPrior = workingDaysPrior * dailyHours
        const monthlyBaseline = hoursPrior * wage

        const nextMonthlyAccumulated = monthlyBaseline + nextDailyAccumulated

        // Determine Target based on Mode
        const targetAccumulated = bocalMode === 'daily' ? nextDailyAccumulated : nextMonthlyAccumulated

        // 2. Update displayed value (Catch-up or follow)
        let nextDisplayed = displayedAccumulated
        let nextIsCatchingUp = isCatchingUp

        if (isCatchingUp) {
            // Accelerate catch-up: catch 5% of the gap per tick (at 60fps)
            // Minimum speed is real-time speed
            const gap = targetAccumulated - displayedAccumulated
            const catchUpDelta = Math.max(earnedPerMs * ms, gap * 0.05)
            nextDisplayed += catchUpDelta

            if (nextDisplayed >= targetAccumulated) {
                nextDisplayed = targetAccumulated
                nextIsCatchingUp = false
            }
        } else {
            // Check if we need to START catching up (e.g. switched mode)
            if (targetAccumulated > nextDisplayed + 1.0) { // Tolerance
                nextIsCatchingUp = true
            } else {
                nextDisplayed = targetAccumulated
            }
        }

        // 3. Spawning is now handled by the UI reacting to nextDisplayed
        set({
            accumulated: targetAccumulated,
            dailyAccumulated: nextDailyAccumulated,
            displayedAccumulated: nextDisplayed,
            isCatchingUp: nextIsCatchingUp
        })
    },
    loadSalaryData: async () => {
        if (!window.electron) return
        const wage = await window.electron.getWage()
        const net = wage * HOURS_PER_MONTH_39H

        /* 
           We can't easily access the store state here via `get()` in the create callback 
           without casting, but we can assume defaults or use set state if we split logic.
           However, simplest is to re-read state inside the component or just assume defaults
           for initial load, OR better: use `get()` which IS available.
           Wait, `loadSalaryData` is defined in `create((set, get) => ...)` so `get` IS available.
        */
        const { workStartHour, workEndHour, workingDays } = get()

        const now = new Date()
        const currentDay = now.getDay()
        let earnedSinceStart = 0

        if (workingDays.includes(currentDay)) {
            const todayStart = new Date(now)
            todayStart.setHours(workStartHour, 0, 0, 0)

            const todayEnd = new Date(now)
            todayEnd.setHours(workEndHour, 0, 0, 0)

            const calcTime = now > todayEnd ? todayEnd : now
            const msSinceStart = Math.max(0, calcTime.getTime() - todayStart.getTime())
            earnedSinceStart = (wage / (60 * 60 * 1000)) * msSinceStart
        }

        set({
            wage,
            monthlyNet: net,
            accumulated: earnedSinceStart,
            dailyAccumulated: earnedSinceStart,
            displayedAccumulated: 0,
            isCatchingUp: earnedSinceStart > 0,
            hasInitializedBocal: false
        })
    }
}))
