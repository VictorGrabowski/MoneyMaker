import React from 'react'
import { WageInput } from '../WageInput'
import { BureauControls } from './BureauControls'
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
            <h2 className="text-3xl font-light mb-4 tracking-widest uppercase opacity-80 text-white text-outline">Le Bureau</h2>

            <BureauControls className="mb-8" />


            <WageInput />
        </div>
    )
}
