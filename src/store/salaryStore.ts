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
    lunchBreakDuration: number // in minutes
    lunchBreakStartHour: number // e.g. 12.0
    monthlyHours: number
    setMonthlyNet: (net: number) => void
    setViewMode: (mode: 'setup' | 'widget' | 'bocal') => void
    setBocalMode: (mode: 'daily' | 'monthly') => void
    setHasInitializedBocal: (initialized: boolean) => void
    setWorkingDays: (days: number[]) => void
    setWorkHours: (start: number, end: number) => void
    setLunchBreak: (duration: number, start: number) => void
    tick: (ms: number) => void
    loadSalaryData: () => Promise<void>
    saveSettings: () => void
}

export const calculateEffectiveDailyHours = (start: number, end: number, lunchDurationMinutes: number, lunchStartHour: number) => {
    // Convert all to minutes for easier intersection logic
    const startMins = start * 60
    const endMins = end * 60
    const lunchStartMins = lunchStartHour * 60
    const lunchEndMins = lunchStartMins + lunchDurationMinutes

    // Check strict validity
    if (endMins <= startMins) return 0

    // Intersection of Work and Lunch
    const overlapStart = Math.max(startMins, lunchStartMins)
    const overlapEnd = Math.min(endMins, lunchEndMins)
    const overlapMins = Math.max(0, overlapEnd - overlapStart)

    const totalWorkMins = endMins - startMins
    const effectiveMins = Math.max(0, totalWorkMins - overlapMins)

    return effectiveMins / 60
}

const calculateMonthlyHours = (days: number[], start: number, end: number, lunchDurationMinutes: number, lunchStartHour: number) => {
    const effectiveHoursPerDay = calculateEffectiveDailyHours(start, end, lunchDurationMinutes, lunchStartHour)
    const daysPerWeek = days.length
    // Average hours per year: (Weekly Hours * 52) / 12
    return (daysPerWeek * effectiveHoursPerDay * 52) / 12
}

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
    lunchBreakDuration: 0,
    lunchBreakStartHour: 12,
    monthlyHours: 169, // Default 39h/week approx

    setMonthlyNet: (net: number) => {
        const { monthlyHours } = get()
        const safeMonthlyHours = monthlyHours || 1 // Avoid division by zero
        const hourlyRate = net / safeMonthlyHours

        // Update calculations immediately
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
            earnedSinceStart = (hourlyRate / (60 * 60 * 1000)) * msSinceStart
        }

        set({
            monthlyNet: net,
            wage: hourlyRate,
            accumulated: earnedSinceStart,
            dailyAccumulated: earnedSinceStart,
            displayedAccumulated: 0,
            isCatchingUp: earnedSinceStart > 0,
            hasInitializedBocal: false
        })

        // NOTE: We do NOT auto-save here anymore, as the user wants explicit Save button behavior for settings
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

    setWorkingDays: (days) => {
        const { workStartHour, workEndHour, monthlyNet, lunchBreakDuration, lunchBreakStartHour } = get()
        const newMonthlyHours = calculateMonthlyHours(days, workStartHour, workEndHour, lunchBreakDuration, lunchBreakStartHour)
        const safeMonthlyHours = newMonthlyHours || 1

        // If monthly net is set, we adjust wage to keep net constant.
        // If wage was set but net wasn't (initial load), we interpret current logic as "Fixed Net, Variable Wage"
        const newWage = monthlyNet / safeMonthlyHours

        set({
            workingDays: days,
            monthlyHours: newMonthlyHours,
            wage: newWage
        })
    },

    setWorkHours: (start, end) => {
        const { workingDays, monthlyNet, lunchBreakDuration, lunchBreakStartHour } = get()
        const newMonthlyHours = calculateMonthlyHours(workingDays, start, end, lunchBreakDuration, lunchBreakStartHour)
        const safeMonthlyHours = newMonthlyHours || 1

        const newWage = monthlyNet / safeMonthlyHours

        set({
            workStartHour: start,
            workEndHour: end,
            monthlyHours: newMonthlyHours,
            wage: newWage
        })
    },

    setLunchBreak: (duration, start) => {
        const { workingDays, monthlyNet, workStartHour, workEndHour } = get()
        const newMonthlyHours = calculateMonthlyHours(workingDays, workStartHour, workEndHour, duration, start)
        const safeMonthlyHours = newMonthlyHours || 1
        const newWage = monthlyNet / safeMonthlyHours

        set({
            lunchBreakDuration: duration,
            lunchBreakStartHour: start,
            monthlyHours: newMonthlyHours,
            wage: newWage
        })
    },

    tick: (ms) => {
        const { wage, dailyAccumulated, displayedAccumulated, isCatchingUp, bocalMode, workingDays, workStartHour, workEndHour, lunchBreakDuration, lunchBreakStartHour } = get()
        if (wage <= 0) return

        // 1. Update real accumulated
        const earnedPerMs = wage / (60 * 60 * 1000)

        const now = new Date()
        const currentHour = now.getHours()
        const currentMinute = now.getMinutes()
        const currentTotalMinutes = currentHour * 60 + currentMinute
        const currentDayOfWeek = now.getDay() // 0 = Sun, 6 = Sat

        let nextDailyAccumulated = dailyAccumulated

        // Accumulate only during working hours on working days
        // Note: Simple check currentHour >= start && currentHour < end handles standard hours.
        // For partial minutes, the tick ms simply adds up.
        // Boundary case: if currentHour changes from 16 to 17 (end), we stop.
        const isWorkingTime = currentHour >= workStartHour && currentHour < workEndHour
        const isWorkingDay = workingDays.includes(currentDayOfWeek)

        // Lunch check
        const lunchStartMinutes = lunchBreakStartHour * 60
        const lunchEndMinutes = lunchStartMinutes + lunchBreakDuration
        const isLunchBreak = currentTotalMinutes >= lunchStartMinutes && currentTotalMinutes < lunchEndMinutes

        if (isWorkingTime && isWorkingDay && !isLunchBreak) {
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

        const dailyActiveHours = (workEndHour - workStartHour) - (lunchBreakDuration / 60)
        const effectiveDailyHours = Math.max(0, dailyActiveHours)
        const hoursPrior = workingDaysPrior * effectiveDailyHours
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

        try {
            const wage = await window.electron.getWage()
            const workingDays = await window.electron.getWorkingDays() || [1, 2, 3, 4, 5]
            const workHours = await window.electron.getWorkHours() || { start: 9, end: 17 }
            const lunchBreak = await window.electron.getLunchBreak() || { duration: 0, start: 12 }

            const monthlyHours = calculateMonthlyHours(workingDays, workHours.start, workHours.end, lunchBreak.duration, lunchBreak.start)

            // Recalculate net from wage for display, although we generally drive wage from net.
            // If we only store wage, we must derive net.
            const net = wage * monthlyHours

            const now = new Date()
            const currentDay = now.getDay()
            let earnedSinceStart = 0

            if (workingDays.includes(currentDay)) {
                const todayStart = new Date(now)
                todayStart.setHours(workHours.start, 0, 0, 0)

                const todayEnd = new Date(now)
                todayEnd.setHours(workHours.end, 0, 0, 0)

                const current = now > todayEnd ? todayEnd : now

                const startMins = workHours.start * 60
                const curMins = current.getHours() * 60 + current.getMinutes()

                const lunchStartMins = lunchBreak.start * 60
                const lunchEndMins = lunchStartMins + lunchBreak.duration

                // Interval intersection: [start, cur] INTERSECT [lunchStart, lunchEnd]
                const overlapStart = Math.max(startMins, lunchStartMins)
                const overlapEnd = Math.min(curMins, lunchEndMins)
                const overlap = Math.max(0, overlapEnd - overlapStart)

                const rawWorkedMinutes = Math.max(0, curMins - startMins)
                const effectiveWorkedMinutes = Math.max(0, rawWorkedMinutes - overlap)

                earnedSinceStart = (wage / 60) * effectiveWorkedMinutes * (60 * 1000) // Convert mins to ms for consistency or just calculate directly: wage per hour / 60 = wage per minute. * minutes. The store expects accumulated in CURRENCY UNITS?
                // Wait, wage is hourly rate. 
                // earnedSinceStart in store is Currency.
                // (wage / 60) * minutes is correct.
                earnedSinceStart = (wage / 60) * effectiveWorkedMinutes
            }

            set({
                wage,
                monthlyNet: net,
                workingDays,
                workStartHour: workHours.start,
                workEndHour: workHours.end,
                lunchBreakDuration: lunchBreak.duration,
                lunchBreakStartHour: lunchBreak.start,
                monthlyHours,
                accumulated: earnedSinceStart,
                dailyAccumulated: earnedSinceStart,
                displayedAccumulated: 0,
                isCatchingUp: earnedSinceStart > 0,
                hasInitializedBocal: false
            })
        } catch (error) {
            console.error("Failed to load salary data:", error)
        }
    },

    saveSettings: () => {
        if (!window.electron) return
        const { wage, workingDays, workStartHour, workEndHour, lunchBreakDuration, lunchBreakStartHour } = get()

        window.electron.setWage(wage)
        if (window.electron.setWorkingDays) window.electron.setWorkingDays(workingDays)
        if (window.electron.setWorkHours) window.electron.setWorkHours({ start: workStartHour, end: workEndHour })
        if (window.electron.setLunchBreak) window.electron.setLunchBreak({ duration: lunchBreakDuration, start: lunchBreakStartHour })

        console.log("Settings saved:", { wage, workingDays, start: workStartHour, end: workEndHour, lunch: lunchBreakDuration })
    }
}))
