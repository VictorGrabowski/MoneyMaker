export interface IElectronAPI {
    getWage: () => Promise<number>
    setWage: (value: number) => void
    getLastSeen: () => Promise<number>
    setLastSeen: (value: number) => Promise<void>
    switchWindowMode: (mode: 'main' | 'widget') => void
    minimize: () => void
    toggleMaximize: () => void
    close: () => void
}

interface Window {
    electron: IElectronAPI
    ipcRenderer: any // For compatibility
}
}

declare module '*.png' {
    const value: string;
    export default value;
}

declare module '*.jpg' {
    const value: string;
    export default value;
}

declare module '*.svg' {
    const value: string;
    export default value;
}
