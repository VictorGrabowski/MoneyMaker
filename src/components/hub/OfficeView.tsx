import React from 'react'
import { WageInput } from '../WageInput'
import { useWeatherStore } from '../../store/weatherStore'
import { useImmersionStore, RADIO_STATIONS } from '../../store/immersionStore'
import { Sun, Moon, CloudRain, CloudSnow, Radio, Play, Pause, SkipBack, SkipForward, Volume2 } from 'lucide-react'
import Slider from 'rc-slider'
import 'rc-slider/assets/index.css'

export const OfficeView: React.FC = () => {
    const { isDay, condition, toggleDayNight, setWeather } = useWeatherStore()
    const { isRadioOn, toggleRadio, currentStationIndex, nextStation, prevStation, volume, setVolume } = useImmersionStore()

    const currentStation = RADIO_STATIONS[currentStationIndex]

    return (
        <div className="flex flex-col items-center justify-center animate-in fade-in zoom-in duration-500 w-full max-w-5xl p-8">
            <h2 className="text-3xl font-light mb-4 tracking-widest uppercase opacity-80">Le Bureau</h2>

            <div className="flex gap-4 mb-8">
                {/* Weather Controls */}
                <div className="flex items-center gap-2 p-2 rounded-full bg-black/20 backdrop-blur-md border border-white/5">
                    <button
                        onClick={toggleDayNight}
                        className={`p-2 rounded-full transition-colors ${isDay ? 'bg-sky-500/20 text-sky-200 hover:bg-sky-500/30' : 'bg-slate-700/50 text-slate-300 hover:bg-slate-600'}`}
                        title="Toggle Day/Night"
                    >
                        {isDay ? <Sun size={18} /> : <Moon size={18} />}
                    </button>
                    <div className="w-px h-6 bg-white/10" />
                    <button
                        onClick={() => setWeather(condition === 'rain' ? 'clear' : 'rain')}
                        className={`p-2 rounded-full transition-colors ${condition === 'rain' ? 'bg-blue-500 text-white shadow-[0_0_15px_rgba(59,130,246,0.5)]' : 'bg-white/5 text-slate-400 hover:bg-white/10'}`}
                        title="Pluie"
                    >
                        <CloudRain size={18} />
                    </button>
                    <button
                        onClick={() => setWeather(condition === 'snow' ? 'clear' : 'snow')}
                        className={`p-2 rounded-full transition-colors ${condition === 'snow' ? 'bg-white text-slate-900 shadow-[0_0_15px_rgba(255,255,255,0.3)]' : 'bg-white/5 text-slate-400 hover:bg-white/10'}`}
                        title="Neige"
                    >
                        <CloudSnow size={18} />
                    </button>
                </div>

                {/* Radio Controls */}
                <div className="flex items-center gap-4 p-2 pl-4 pr-4 rounded-full bg-black/20 backdrop-blur-md border border-white/5">
                    <div className="flex items-center gap-2 mr-2">
                        <Radio size={16} className={isRadioOn ? "text-indigo-400 animate-pulse" : "text-slate-500"} />
                        <div className="flex flex-col w-32 overflow-hidden">
                            <span className="text-xs font-bold text-white whitespace-nowrap truncate">
                                {isRadioOn ? currentStation.name : "Radio OFF"}
                            </span>
                            <span className="text-[10px] text-slate-400 whitespace-nowrap truncate">
                                {isRadioOn ? currentStation.style : "Silence"}
                            </span>
                        </div>
                    </div>

                    <div className="flex items-center gap-1">
                        <button onClick={prevStation} className="p-1.5 hover:bg-white/10 rounded-full text-slate-300 hover:text-white transition-colors">
                            <SkipBack size={16} fill="currentColor" />
                        </button>
                        <button
                            onClick={toggleRadio}
                            className={`p-2 rounded-full transition-colors ${isRadioOn ? 'bg-indigo-500 text-white shadow-lg shadow-indigo-500/30 hover:bg-indigo-400' : 'bg-white/5 text-slate-300 hover:bg-white/10'}`}
                        >
                            {isRadioOn ? <Pause size={16} fill="currentColor" /> : <Play size={16} fill="currentColor" className="ml-0.5" />}
                        </button>
                        <button onClick={nextStation} className="p-1.5 hover:bg-white/10 rounded-full text-slate-300 hover:text-white transition-colors">
                            <SkipForward size={16} fill="currentColor" />
                        </button>
                    </div>

                    <div className="w-px h-6 bg-white/10 mx-1" />

                    <div className="flex items-center gap-2 w-20 group">
                        <Volume2 size={14} className="text-slate-400 group-hover:text-white transition-colors" />
                        <div className="flex-1">
                            <Slider
                                min={0}
                                max={0.5}
                                step={0.01}
                                value={volume}
                                onChange={(val) => typeof val === 'number' && setVolume(val)}
                                trackStyle={{ backgroundColor: '#818cf8', height: 4 }}
                                handleStyle={{
                                    border: '2px solid #818cf8',
                                    backgroundColor: '#1e1b4b',
                                    opacity: 1,
                                    width: 12,
                                    height: 12,
                                    marginTop: -4
                                }}
                                railStyle={{ backgroundColor: 'rgba(255,255,255,0.1)', height: 4 }}
                            />
                        </div>
                    </div>
                </div>
            </div>

            <WageInput />
        </div>
    )
}
