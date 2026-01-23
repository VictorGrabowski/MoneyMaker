import React from 'react'

export const WindowFrame: React.FC = () => {
    return (
        <>
            {/* Draggable Title Bar Area */}
            {/* z-30 ensures it's above basic backgrounds but below standard UI controls (usually z-40+) */}
            <div className="absolute top-0 left-0 right-0 h-10 drag z-30" />

            {/* Window Controls */}
            {/* z-50 ensures they are always clickable on top of everything */}
            <div className="absolute top-4 right-4 flex gap-2 z-50 no-drag">
                <button 
                    onClick={() => window.electron.minimize()} 
                    className="p-2 hover:bg-white/10 rounded-full text-slate-400 hover:text-white transition-colors cursor-pointer"
                >
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="5" y1="12" x2="19" y2="12"></line></svg>
                </button>
                <button 
                    onClick={() => window.electron.toggleMaximize()} 
                    className="p-2 hover:bg-white/10 rounded-full text-slate-400 hover:text-white transition-colors cursor-pointer"
                >
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect></svg>
                </button>
                <button 
                    onClick={() => window.electron.close()} 
                    className="p-2 hover:bg-red-500/20 rounded-full text-slate-400 hover:text-red-400 transition-colors cursor-pointer"
                >
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                </button>
            </div>
        </>
    )
}
