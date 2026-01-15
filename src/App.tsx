import { useSalaryStore } from './store/salaryStore'
import { WageInput } from './components/WageInput'
import { MoneyWidget } from './components/MoneyWidget'
import { BocalView } from './components/BocalView'
import { RadioPlayer } from './components/RadioPlayer'
import { HubView } from './components/hub/HubView' // New Import

import { useWeatherStore } from './store/weatherStore'
import { CloudRain, CloudSnow, Sun, Moon } from 'lucide-react'

function App() {
    const viewMode = useSalaryStore(s => s.viewMode)
    const setViewMode = useSalaryStore(s => s.setViewMode)

    // Weather store updates are infrequent so destructuring is less critical, 
    // but good practice to be specific if needed. Keeping it simple for now as weather doesn't tick.
    const { condition, isDay, setWeather, toggleDayNight } = useWeatherStore()

    console.log('Renderer: App component rendering... Mode:', viewMode)

    let content
    // ... (viewMode logic remains same)
    if (viewMode === 'widget') {
        content = <MoneyWidget />
    } else if (viewMode === 'bocal') {
        content = <BocalView />
    } else {
        content = (
            <HubView />
        )
    }

    return (
        <>
            <RadioPlayer />

            {/* Weather Debug Controls (Always visible for now) */}
            <div className="fixed top-4 left-4 z-[100] flex gap-2 no-drag group opacity-0 hover:opacity-100 transition-opacity">
                <button
                    onClick={toggleDayNight}
                    className="p-2 bg-black/50 rounded-full hover:bg-black/80 text-white"
                    title="Toggle Day/Night"
                >
                    {isDay ? <Sun size={16} /> : <Moon size={16} />}
                </button>
                <button
                    onClick={() => setWeather(condition === 'rain' ? 'clear' : 'rain')}
                    className={`p-2 rounded-full hover:bg-black/80 text-white ${condition === 'rain' ? 'bg-blue-500' : 'bg-black/50'}`}
                    title="Toggle Rain"
                >
                    <CloudRain size={16} />
                </button>
                <button
                    onClick={() => setWeather(condition === 'snow' ? 'clear' : 'snow')}
                    className={`p-2 rounded-full hover:bg-black/80 text-white ${condition === 'snow' ? 'bg-white/50' : 'bg-black/50'}`}
                    title="Toggle Snow"
                >
                    <CloudSnow size={16} />
                </button>
            </div>

            {content}
        </>
    )
}


export default App
