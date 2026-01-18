
import { create } from 'zustand'

export interface RadioStation {
    name: string
    url: string // URL for stream or Video ID for Youtube
    style: string
    type: 'stream' | 'youtube'
}

export const RADIO_STATIONS: RadioStation[] = [
    { name: 'Radio Nova', url: 'https://novazz.ice.infomaniak.ch/novazz-128.mp3', style: 'Eclectic', type: 'stream' },
    { name: 'FIP', url: 'https://icecast.radiofrance.fr/fip-midfi.mp3', style: 'Jazz / Groove', type: 'stream' },
    { name: 'France Info', url: 'https://icecast.radiofrance.fr/franceinfo-midfi.mp3', style: 'News', type: 'stream' }
]

interface ImmersionState {
    isRadioOn: boolean
    currentStationIndex: number
    volume: number
    toggleRadio: () => void
    nextStation: () => void
    prevStation: () => void
    setVolume: (vol: number) => void
}

export const useImmersionStore = create<ImmersionState>((set) => ({
    isRadioOn: false,
    currentStationIndex: 0,
    volume: 0.25,
    toggleRadio: () => set((state) => ({ isRadioOn: !state.isRadioOn })),
    nextStation: () => set((state) => ({
        currentStationIndex: (state.currentStationIndex + 1) % RADIO_STATIONS.length
    })),
    prevStation: () => set((state) => ({
        currentStationIndex: (state.currentStationIndex - 1 + RADIO_STATIONS.length) % RADIO_STATIONS.length
    })),
    setVolume: (vol) => set({ volume: Math.max(0, Math.min(1, vol)) })
}))
