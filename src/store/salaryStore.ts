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
    setMonthlyNet: (net: number) => void
    setViewMode: (mode: 'setup' | 'widget' | 'bocal') => void
    setBocalMode: (mode: 'daily' | 'monthly') => void
    setHasInitializedBocal: (initialized: boolean) => void
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
    setMonthlyNet: (net: number) => {
        const hourlyRate = net / HOURS_PER_MONTH_39H

        // Calculate earnings since 9 AM today, capped at 17 PM
        const now = new Date()
        const today9AM = new Date(now)
        today9AM.setHours(9, 0, 0, 0)

        const today5PM = new Date(now)
        today5PM.setHours(17, 0, 0, 0)

        // If now is past 17h, we cap the calculation time at 17h
        const calcTime = now > today5PM ? today5PM : now

        const msSince9AM = Math.max(0, calcTime.getTime() - today9AM.getTime())
        const earnedSince9AM = (hourlyRate / (60 * 60 * 1000)) * msSince9AM

        set({
            monthlyNet: net,
            wage: hourlyRate,
            accumulated: earnedSince9AM,
            dailyAccumulated: earnedSince9AM, // Initialize daily
            displayedAccumulated: 0,
            isCatchingUp: earnedSince9AM > 0,
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
    tick: (ms) => {
        const { wage, dailyAccumulated, displayedAccumulated, isCatchingUp, bocalMode } = get()
        if (wage <= 0) return

        // 1. Update real accumulated
        const earnedPerMs = wage / (60 * 60 * 1000)

        const now = new Date()
        const currentHour = now.getHours()
        const currentDayOfWeek = now.getDay() // 0 = Sun, 6 = Sat
        let nextDailyAccumulated = dailyAccumulated

        // Only accumulate between 9h and 17h AND only on weekdays (Mon-Fri)
        if (currentHour >= 9 && currentHour < 17 && currentDayOfWeek !== 0 && currentDayOfWeek !== 6) {
            nextDailyAccumulated = dailyAccumulated + (earnedPerMs * ms)
        }

        // Calculate Monthly Total (Excluding Weekends)
        const currentDayOfMonth = now.getDate()
        let workingDaysPrior = 0

        // Loop from 1st of month to yesterday
        for (let d = 1; d < currentDayOfMonth; d++) {
            const dateToCheck = new Date(now.getFullYear(), now.getMonth(), d)
            const dayOfWeek = dateToCheck.getDay()
            // If Mon(1) to Fri(5), it counts
            if (dayOfWeek !== 0 && dayOfWeek !== 6) {
                workingDaysPrior++
            }
        }

        const hoursPrior = workingDaysPrior * 8 // 8h per working day
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

        const now = new Date()
        const today9AM = new Date(now)
        today9AM.setHours(9, 0, 0, 0)

        const today5PM = new Date(now)
        today5PM.setHours(17, 0, 0, 0)

        const calcTime = now > today5PM ? today5PM : now

        const msSince9AM = Math.max(0, calcTime.getTime() - today9AM.getTime())
        const earnedSince9AM = (wage / (60 * 60 * 1000)) * msSince9AM

        set({
            wage,
            monthlyNet: net,
            accumulated: earnedSince9AM,
            dailyAccumulated: earnedSince9AM,
            displayedAccumulated: 0,
            isCatchingUp: earnedSince9AM > 0,
            hasInitializedBocal: false
        })
    }
}))
