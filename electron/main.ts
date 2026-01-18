import { app, BrowserWindow, ipcMain, screen } from 'electron'
import path from 'path'
import { initPersistence } from '../src/main/services/persistence'
import Store from 'electron-store'

process.env.DIST = path.join(__dirname, '../dist')
process.env.VITE_PUBLIC = app.isPackaged ? process.env.DIST : path.join(process.env.DIST, '../public')

let win: BrowserWindow | null

interface StoreType {
    windowBounds: {
        main: { x: number, y: number, width: number, height: number, maximized: boolean }
        widget: { x: number, y: number }
    }
}

const store = new Store<StoreType>({
    defaults: {
        windowBounds: {
            main: { x: 0, y: 0, width: 400, height: 600, maximized: true },
            widget: { x: 0, y: 0 }
        }
    }
}) as any // Cast to any to bypass potential type definition mismatches with dot-notation

function createWindow() {
    const mainBounds = store.get('windowBounds.main')

    win = new BrowserWindow({
        icon: path.join(process.env.VITE_PUBLIC, 'electron-vite.svg'),
        webPreferences: {
            preload: path.join(__dirname, 'preload.js'),
            nodeIntegration: false,
            contextIsolation: true,
            backgroundThrottling: false // Keep running in background (vital for radio)
        },
        width: mainBounds.width || 800,
        height: mainBounds.height || 600,
        x: mainBounds.x,
        y: mainBounds.y,
        frame: false,
        transparent: true,
        backgroundColor: '#00000000',
        show: false // Don't show immediately
    })

    if (mainBounds.maximized) {
        win.maximize()
    }

    win.show()

    // Open DevTools automatically for debugging
    win.webContents.openDevTools()

    if (process.env.VITE_DEV_SERVER_URL) {
        console.log('Loading URL:', process.env.VITE_DEV_SERVER_URL)
        win.loadURL(process.env.VITE_DEV_SERVER_URL)
    } else {
        win.loadFile(path.join(process.env.DIST, 'index.html'))
    }

    // Window Mode Switcher
    ipcMain.on('switch-window-mode', (_event, mode: 'main' | 'widget') => {
        if (!win) return

        const currentBounds = win.getBounds()

        if (mode === 'widget') {
            // Saving Main State before switching
            const isMaximized = win.isMaximized()
            if (!isMaximized) {
                store.set('windowBounds.main', { ...currentBounds, maximized: false })
            } else {
                store.set('windowBounds.main.maximized', true)
            }

            // Setup Widget
            const widgetPos = store.get('windowBounds.widget')
            console.log('Switching to Widget Mode. Stored Pos:', widgetPos)

            win.setMinimumSize(250, 100)
            win.setResizable(false)
            win.setAlwaysOnTop(true)

            // Check if position is valid (not 0,0)
            if (widgetPos && (widgetPos.x !== 0 || widgetPos.y !== 0)) {
                console.log('Restoring stored widget position:', widgetPos)
                win.setBounds({ x: widgetPos.x, y: widgetPos.y, width: 250, height: 100 })
            } else {
                // Default to Bottom-Right
                console.log('No valid stored position (or 0,0). Calculating default bottom-right.')
                const calculatePos = () => {
                    const primaryDisplay = screen.getPrimaryDisplay()
                    const { width, height } = primaryDisplay.workAreaSize
                    const x = width - 250 - 20
                    const y = height - 100 - 20
                    console.log(`Screen: ${width}x${height}, Target: ${x},${y}`)
                    return { x, y }
                }

                try {
                    const { x, y } = calculatePos()
                    win.setPosition(x, y)
                } catch (err) {
                    console.error('Error calculating screen position:', err)
                    win.center() // Fallback
                }
            }
            win.setSize(250, 100) // Force size

        } else {
            // Saving Widget State before switching
            store.set('windowBounds.widget', { x: currentBounds.x, y: currentBounds.y })

            // Setup Main
            win.setMinimumSize(400, 600)
            win.setResizable(true)
            win.setAlwaysOnTop(false)

            const savedMain = store.get('windowBounds.main')
            if (savedMain.maximized) {
                win.maximize()
            } else {
                win.setBounds({
                    x: savedMain.x || 0,
                    y: savedMain.y || 0,
                    width: savedMain.width || 800,
                    height: savedMain.height || 600
                })
                win.center()
            }
        }
    })

    // Save Widget position on close if we are in widget mode?
    // Hard to inspect internal React state. 
    // We can rely on 'move' event debounced?

    let moveTimeout: NodeJS.Timeout
    win.on('move', () => {
        if (!win) return
        clearTimeout(moveTimeout)
        moveTimeout = setTimeout(() => {
            const bounds = win?.getBounds()
            if (!bounds) return

            if (bounds.width < 300) {
                store.set('windowBounds.widget', { x: bounds.x, y: bounds.y })
            } else {
                store.set('windowBounds.main', { ...bounds, maximized: win?.isMaximized() || false })
            }
        }, 500)
    })

    // Window Controls
    ipcMain.on('minimize-window', () => {
        win?.minimize()
    })

    ipcMain.on('toggle-maximize-window', () => {
        if (!win) return
        if (win.isMaximized()) {
            win.unmaximize()
        } else {
            win.maximize()
        }
    })

    ipcMain.on('close-window', () => {
        app.quit()
    })
}

app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') {
        app.quit()
        win = null
    }
})

app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
        createWindow()
    }
})

app.whenReady().then(() => {
    initPersistence()
    createWindow()
})
