import { contextBridge, ipcRenderer } from 'electron'

// --------- Expose some API to the Renderer process ---------
contextBridge.exposeInMainWorld('ipcRenderer', {
    on(...args: Parameters<typeof ipcRenderer.on>) {
        const [channel, listener] = args
        return ipcRenderer.on(channel, (event, ...args) => listener(event, ...args))
    },
    off(...args: Parameters<typeof ipcRenderer.off>) {
        const [channel, ...omit] = args
        return ipcRenderer.off(channel, ...omit)
    },
    send(...args: Parameters<typeof ipcRenderer.send>) {
        const [channel, ...omit] = args
        return ipcRenderer.send(channel, ...omit)
    },
    invoke(...args: Parameters<typeof ipcRenderer.invoke>) {
        const [channel, ...omit] = args
        return ipcRenderer.invoke(channel, ...omit)
    },
})

contextBridge.exposeInMainWorld('electron', {
    getWage: () => ipcRenderer.invoke('get-wage'),
    setWage: (value: number) => ipcRenderer.send('set-wage', value),
    getLastSeen: () => ipcRenderer.invoke('get-last-seen'),
    setLastSeen: (value: number) => ipcRenderer.send('set-last-seen', value),
    switchWindowMode: (mode: 'main' | 'widget') => ipcRenderer.send('switch-window-mode', mode),
    minimize: () => ipcRenderer.send('minimize-window'),
    toggleMaximize: () => ipcRenderer.send('toggle-maximize-window'),
    close: () => ipcRenderer.send('close-window'),
})
