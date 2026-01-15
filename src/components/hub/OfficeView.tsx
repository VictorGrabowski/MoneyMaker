import React from 'react'
import { WageInput } from '../WageInput'
import { useWeatherStore } from '../../store/weatherStore'
import { Sun, Moon, CloudRain, CloudSnow } from 'lucide-react'

export const OfficeView: React.FC = () => {
    const { isDay, condition, toggleDayNight, setWeather } = useWeatherStore()

    return (
        <div className="flex flex-col items-center justify-center animate-in fade-in zoom-in duration-500 w-full max-w-5xl p-8">
            <h2 className="text-3xl font-light mb-4 tracking-widest uppercase opacity-80">Le Bureau</h2>

            {/* Weather Controls - Restored from App.tsx */}
            <div className="flex items-center justify-center gap-4 mb-8">
                <button
                    onClick={toggleDayNight}
                    className={`p-2 rounded-full transition-colors ${isDay ? 'bg-sky-500/20 text-sky-200 hover:bg-sky-500/30' : 'bg-slate-700/50 text-slate-300 hover:bg-slate-600'}`}
                    title="Toggle Day/Night"
                >
                    {isDay ? <Sun size={20} /> : <Moon size={20} />}
                </button>
                <div className="w-px h-6 bg-white/10" />
                <button
                    onClick={() => setWeather(condition === 'rain' ? 'clear' : 'rain')}
                    className={`p-2 rounded-full transition-colors ${condition === 'rain' ? 'bg-blue-500 text-white shadow-[0_0_15px_rgba(59,130,246,0.5)]' : 'bg-white/5 text-slate-400 hover:bg-white/10'}`}
                    title="Pluie"
                >
                    <CloudRain size={20} />
                </button>
                <button
                    onClick={() => setWeather(condition === 'snow' ? 'clear' : 'snow')}
                    className={`p-2 rounded-full transition-colors ${condition === 'snow' ? 'bg-white text-slate-900 shadow-[0_0_15px_rgba(255,255,255,0.3)]' : 'bg-white/5 text-slate-400 hover:bg-white/10'}`}
                    title="Neige"
                >
                    <CloudSnow size={20} />
                </button>
            </div>

            <WageInput />
        </div>
    )
}
