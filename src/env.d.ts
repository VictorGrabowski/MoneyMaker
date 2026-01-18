export interface IElectronAPI {
    getWage: () => Promise<number>
    setWage: (value: number) => void
    getWorkingDays: () => Promise<number[]>
    setWorkingDays: (value: number[]) => void
    getWorkHours: () => Promise<{ start: number, end: number }>
    setWorkHours: (value: { start: number, end: number }) => void
    getLunchBreak: () => Promise<{ duration: number, start: number }>
    setLunchBreak: (value: { duration: number, start: number }) => void
    getLastSeen: () => Promise<number>
    setLastSeen: (value: number) => Promise<void>
    switchWindowMode: (mode: 'main' | 'widget') => void
    minimize: () => void
    toggleMaximize: () => void
    close: () => void
}

declare global {
    interface Window {
        electron: IElectronAPI
        ipcRenderer: any
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
