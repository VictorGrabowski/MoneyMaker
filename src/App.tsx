import { useSalaryStore } from './store/salaryStore'
import { WageInput } from './components/WageInput'
import { MoneyWidget } from './components/MoneyWidget'
import { BocalView } from './components/BocalView'
import { RadioPlayer } from './components/RadioPlayer'
import { WeatherLayer } from './components/WeatherLayer' // Added global import
import { HubView } from './components/hub/HubView' // New Import

import { useWeatherStore } from './store/weatherStore'
import { Minimize2 } from 'lucide-react'

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
        <div className="relative w-full h-full overflow-hidden">
            {/* Main App Background / Container */}

            <RadioPlayer />
            {viewMode !== 'widget' && <WeatherLayer />} {/* Global Weather Overlay */}



            {/* Reduce Button (Visible everywhere EXCEPT Widget) */}
            {viewMode !== 'widget' && (
                <button
                    onClick={() => setViewMode('widget')}
                    className="absolute bottom-4 right-4 z-[100] flex items-center gap-2 px-4 py-2 bg-black/40 hover:bg-black/60 text-white/70 hover:text-white rounded-xl backdrop-blur-md border border-white/10 transition-all shadow-lg group no-drag pointer-events-auto"
                >
                    <span className="text-xs font-bold uppercase tracking-wider opacity-0 group-hover:opacity-100 transition-opacity translate-x-2 group-hover:translate-x-0 duration-300">Réduire</span>
                    <Minimize2 size={18} />
                </button>
            )}

            {content}
        </div>
    )
}


export default App
