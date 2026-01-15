import { create } from 'zustand'

export type WeatherCondition = 'clear' | 'rain' | 'snow' | 'cloudy'

interface WeatherState {
    condition: WeatherCondition
    isDay: boolean
    setWeather: (condition: WeatherCondition) => void
    toggleDayNight: () => void
}

export const useWeatherStore = create<WeatherState>((set) => ({
    condition: 'clear',
    isDay: true,
    setWeather: (condition) => set({ condition }),
    toggleDayNight: () => set((state) => ({ isDay: !state.isDay })),
}))
