import Store from 'electron-store';
import { ipcMain } from 'electron';

interface GameData {
    wage: number;
    lastSeen: number;
    workingDays: number[];
    workStartHour: number;
    workEndHour: number;
    lunchBreakDuration: number; // in minutes
    lunchBreakStartHour: number; // e.g. 12.5 for 12:30
}

const store = new Store<GameData>({
    defaults: {
        wage: 0,
        lastSeen: Date.now(),
        workingDays: [1, 2, 3, 4, 5],
        workStartHour: 9,
        workEndHour: 17,
        lunchBreakDuration: 0,
        lunchBreakStartHour: 12
    }
}) as any;

export const initPersistence = () => {
    ipcMain.handle('get-wage', () => {
        return store.get('wage');
    });

    ipcMain.on('set-wage', (_event, value: number) => {
        store.set('wage', value);
    });

    ipcMain.handle('get-working-days', () => {
        return store.get('workingDays');
    });

    ipcMain.on('set-working-days', (_event, value: number[]) => {
        store.set('workingDays', value);
    });

    ipcMain.handle('get-work-hours', () => {
        return {
            start: store.get('workStartHour'),
            end: store.get('workEndHour')
        };
    });

    ipcMain.on('set-work-hours', (_event, value: { start: number, end: number }) => {
        store.set('workStartHour', value.start);
        store.set('workEndHour', value.end);
    });

    ipcMain.handle('get-lunch-break', () => {
        return {
            duration: store.get('lunchBreakDuration'),
            start: store.get('lunchBreakStartHour')
        };
    });

    ipcMain.on('set-lunch-break', (_event, value: { duration: number, start: number }) => {
        store.set('lunchBreakDuration', value.duration);
        store.set('lunchBreakStartHour', value.start);
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
