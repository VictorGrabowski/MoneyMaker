import React, { useState, useEffect } from 'react'
import { useSalaryStore } from '../store/salaryStore'

export const WageInput: React.FC = () => {
    console.log('Renderer: WageInput rendering...')
    const { monthlyNet, setMonthlyNet, loadSalaryData, setViewMode } = useSalaryStore()
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

    return (
        <div className="p-6 rounded-2xl bg-white/5 border border-white/10 shadow-xl max-w-sm w-full mx-auto">
            <div className="flex items-center gap-3 mb-6">
                <h2 className="text-xl font-medium text-white">Salaire Mensuel</h2>
            </div>

            <div className="space-y-4">
                <label className="block text-sm font-light text-slate-300">
                    Combien gagnez-vous en net par mois ?
                </label>

                <div className="relative group">
                    <input
                        type="number"
                        step="1"
                        value={inputValue}
                        onChange={(e) => setInputValue(e.target.value)}
                        className="w-full bg-black/20 border border-white/10 rounded-xl px-4 py-3 text-2xl font-semibold text-white focus:outline-none"
                        placeholder="Ex: 2500"
                    />
                    <span className="absolute right-4 top-1/2 -translate-y-1/2 text-2xl font-bold text-white/20">
                        €
                    </span>
                </div>

                <button
                    onClick={handleSave}
                    className="w-full bg-indigo-600 hover:bg-indigo-500 text-white font-medium py-3 rounded-xl transition-all shadow-lg shadow-indigo-600/20"
                >
                    Calculer mon gain (39h)
                </button>

                {monthlyNet > 0 && (
                    <button
                        onClick={() => setViewMode('widget')}
                        className="w-full bg-white/5 hover:bg-white/10 text-indigo-200 text-sm font-medium py-2 rounded-xl transition-all border border-white/5"
                    >
                        Passer en mode Widget
                    </button>
                )}

                {monthlyNet > 0 && (
                    <button
                        onClick={() => setViewMode('bocal')}
                        className="w-full bg-indigo-900/40 hover:bg-indigo-900/60 text-indigo-100 text-sm font-medium py-2 rounded-xl transition-all border border-indigo-500/20"
                    >
                        Voir mon Bocal
                    </button>
                )}
            </div>

            <p className="mt-4 text-[10px] text-center text-white/30 uppercase tracking-[0.2em]">
                Contrat 39h (169h/mois)
            </p>
        </div>
    )
}
