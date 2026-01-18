import React, { useState, useEffect } from 'react'
import Slider from 'rc-slider'
import 'rc-slider/assets/index.css'
import { useSalaryStore } from '../store/salaryStore'

const DAYS = ['D', 'L', 'M', 'M', 'J', 'V', 'S'] // 0=Sun, 1=Mon...

export const WageInput: React.FC = () => {
    console.log('Renderer: WageInput rendering...')
    const {
        monthlyNet, setMonthlyNet, loadSalaryData, setViewMode,
        workingDays, setWorkingDays,
        workStartHour, workEndHour, setWorkHours,
        bocalMode, setBocalMode
    } = useSalaryStore()
    const [inputValue, setInputValue] = useState<string>('')

    useEffect(() => {
        console.log('Renderer: WageInput mounting, loading data...')
        loadSalaryData()
    }, [])

    useEffect(() => {
        if (monthlyNet > 0) {
            setInputValue(monthlyNet.toFixed(2))
        }
    }, [monthlyNet])

    const handleSave = () => {
        const net = parseFloat(inputValue)
        if (!isNaN(net) && net >= 0) {
            setMonthlyNet(net)
        }
    }

    const toggleDay = (dayIndex: number) => {
        if (workingDays.includes(dayIndex)) {
            setWorkingDays(workingDays.filter(d => d !== dayIndex))
        } else {
            setWorkingDays([...workingDays, dayIndex].sort())
        }
    }

    return (
        <div className="p-6 rounded-2xl bg-white/5 border border-white/10 shadow-xl max-w-md w-full mx-auto backdrop-blur-sm">
            <h2 className="text-xl font-medium text-white mb-6">Paramètres</h2>

            <div className="space-y-6">
                {/* SALARY INPUT */}
                <div className="space-y-2">
                    <label className="block text-sm font-light text-slate-300">
                        Salaire Net Mensuel
                    </label>
                    <div className="relative group">
                        <input
                            type="number"
                            step="1"
                            value={inputValue}
                            onChange={(e) => setInputValue(e.target.value)}
                            className="w-full bg-black/20 border border-white/10 rounded-xl px-4 py-3 text-2xl font-semibold text-white focus:outline-none focus:border-indigo-500/50 transition-colors"
                            placeholder="Ex: 2500"
                        />
                        <span className="absolute right-4 top-1/2 -translate-y-1/2 text-xl font-bold text-white/20">€</span>
                    </div>
                </div>

                {/* WORKING DAYS */}
                <div className="space-y-2">
                    <label className="block text-sm font-light text-slate-300">
                        Jours Travaillés
                    </label>
                    <div className="flex justify-between gap-1">
                        {DAYS.map((day, index) => {
                            // Adjust index to match Date.getDay() (0=Sun, 1=Mon...)
                            // But usually UI shows Mon first. Let's render Mon(1) -> Sun(0)
                            // Mapping render index 0..6 to Day index. 
                            // Render: 0(L), 1(M), 2(M), 3(J), 4(V), 5(S), 6(D)
                            // Real Day: 1, 2, 3, 4, 5, 6, 0
                            const realDayIndex = index === 6 ? 0 : index + 1
                            const isSelected = workingDays.includes(realDayIndex)

                            return (
                                <button
                                    key={index}
                                    onClick={() => toggleDay(realDayIndex)}
                                    className={`w-10 h-10 rounded-full flex items-center justify-center text-sm font-medium transition-all duration-200
                                    ${isSelected
                                            ? 'bg-indigo-600 text-white shadow-lg shadow-indigo-600/20 scale-100'
                                            : 'bg-white/5 text-slate-500 hover:bg-white/10 scale-95'
                                        }`}
                                >
                                    {DAYS[realDayIndex]}
                                </button>
                            )
                        })}
                    </div>
                </div>

                {/* TIME RANGE SLIDER */}
                <div className="space-y-4 pt-2">
                    <div className="flex justify-between text-sm font-light text-slate-300">
                        <span>Horaires</span>
                        <span className="font-mono text-indigo-300">{workStartHour}h - {workEndHour}h</span>
                    </div>
                    <div className="px-2">
                        <Slider
                            range
                            min={0}
                            max={24}
                            step={1}
                            value={[workStartHour, workEndHour]}
                            onChange={(val) => {
                                if (Array.isArray(val)) {
                                    setWorkHours(val[0], val[1])
                                }
                            }}
                            trackStyle={[{ backgroundColor: '#4f46e5' }]}
                            handleStyle={[
                                { borderColor: '#4f46e5', backgroundColor: '#1e1b4b', opacity: 1 },
                                { borderColor: '#4f46e5', backgroundColor: '#1e1b4b', opacity: 1 }
                            ]}
                            railStyle={{ backgroundColor: 'rgba(255,255,255,0.1)' }}
                        />
                    </div>
                </div>

                {/* DISPLAY MODE TOGGLE */}
                <div className="flex bg-black/20 p-1 rounded-xl">
                    <button
                        onClick={() => setBocalMode('daily')}
                        className={`flex-1 py-2 rounded-lg text-sm font-medium transition-all ${bocalMode === 'daily' ? 'bg-indigo-600 text-white shadow-lg' : 'text-slate-400 hover:text-white'
                            }`}
                    >
                        Jour
                    </button>
                    <button
                        onClick={() => setBocalMode('monthly')}
                        className={`flex-1 py-2 rounded-lg text-sm font-medium transition-all ${bocalMode === 'monthly' ? 'bg-indigo-600 text-white shadow-lg' : 'text-slate-400 hover:text-white'
                            }`}
                    >
                        Mois
                    </button>
                </div>

                {/* ACTION BUTTONS */}
                <div className="grid grid-cols-2 gap-3 pt-2">
                    <button
                        onClick={handleSave}
                        className="bg-emerald-600 hover:bg-emerald-500 text-white font-medium py-3 rounded-xl transition-all shadow-lg shadow-emerald-600/10 active:scale-95"
                    >
                        Sauvegarder
                    </button>

                    {monthlyNet > 0 && (
                        <button
                            onClick={() => setViewMode('widget')}
                            className="bg-white/5 hover:bg-white/10 text-slate-300 font-medium py-3 rounded-xl transition-all border border-white/5 active:scale-95"
                        >
                            Réduire
                        </button>
                    )}
                </div>
            </div>

            <p className="mt-6 text-[10px] text-center text-white/30 uppercase tracking-[0.2em]">
                Contrat 39h (Base)
            </p>
        </div>
    )
}
