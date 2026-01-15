import Store from 'electron-store';
import { ipcMain } from 'electron';

interface GameData {
    wage: number;
    lastSeen: number;
}

const store = new Store<GameData>({
    defaults: {
        wage: 0,
        lastSeen: Date.now()
    }
});

export const initPersistence = () => {
    // IPC handlers for wage
    ipcMain.handle('get-wage', () => {
        return store.get('wage');
    });

    ipcMain.on('set-wage', (_event, value: number) => {
        store.set('wage', value);
    });

    // IPC handlers for salary engine needs
    ipcMain.handle('get-last-seen', () => {
        return store.get('lastSeen');
    });

    ipcMain.on('set-last-seen', (_event, value: number) => {
        store.set('lastSeen', value);
    });
};

export default store;
