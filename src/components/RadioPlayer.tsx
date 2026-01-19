import React, { useRef } from 'react'
import ReactPlayer from 'react-player'
import { useRadioController } from '../features/radio/RadioController'
import { useSalaryStore } from '../store/salaryStore'

export const RadioPlayer: React.FC = () => {
    const { station, isRadioOn, volume } = useRadioController()
    const { viewMode } = useSalaryStore()
    const playerRef = useRef<any>(null)

    const isYoutube = station.type === 'youtube'
    const isLofiGirl = station.name === 'Lofi Girl'
    const showPlayer = isRadioOn && isLofiGirl

    // Dynamic Container Styles
    const getContainerStyle = () => {
        if (!showPlayer) {
            return "fixed top-[-10px] left-[-10px] w-[1px] h-[1px] opacity-[0.01] overflow-hidden pointer-events-none z-[-1]"
        }

        if (viewMode === 'widget') {
            return "absolute inset-0 w-full h-full z-[-1] opacity-80"
        } else {
            return "absolute bottom-6 right-6 w-80 aspect-video rounded-xl overflow-hidden shadow-2xl z-[60] border border-white/10 transition-all duration-500 animate-in slide-in-from-bottom-10 fade-in"
        }
    }

    return (
        <div
            className={getContainerStyle()}
            aria-hidden={!showPlayer}
        >
            {isYoutube && (
                <div className="w-full h-full relative">
                    {/* Overlay to prevent interaction in widget mode */}
                    {viewMode === 'widget' && <div className="absolute inset-0 z-10 bg-transparent" />}

                    <ReactPlayer
                        ref={playerRef}
                        url={`https://www.youtube.com/watch?v=${station.url}`}
                        playing={isRadioOn}
                        volume={volume}
                        width="100%"
                        height="100%"
                        playsinline
                        config={{
                            youtube: {
                                playerVars: {
                                    showinfo: 0,
                                    controls: 0,
                                    autoplay: 1,
                                    playsinline: 1,
                                    modestbranding: 1
                                } as any
                            }
                        }}
                    />
                </div>
            )}
        </div>
    )
}
