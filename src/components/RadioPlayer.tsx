import React, { useEffect, useRef, useState } from 'react'
import ReactPlayer from 'react-player'
import { useImmersionStore, RADIO_STATIONS } from '../store/immersionStore'
import { useSalaryStore } from '../store/salaryStore'

export const RadioPlayer: React.FC = () => {
    const { isRadioOn, currentStationIndex, volume } = useImmersionStore()
    const { viewMode } = useSalaryStore()
    const [isPlaying, setIsPlaying] = useState(false)
    const [isBuffering, setIsBuffering] = useState(false)
    const audioContextRef = useRef<AudioContext | null>(null)
    const playerRef = useRef<any>(null)

    const station = RADIO_STATIONS[currentStationIndex]
    const [retryCount, setRetryCount] = useState(0)

    // Reset retry count when station changes
    useEffect(() => {
        setRetryCount(0)
    }, [currentStationIndex])

    // PLAY/PAUSE SYNC & CONTEXT RESUME
    useEffect(() => {
        setIsPlaying(isRadioOn)

        if (isRadioOn) {
            console.log("RadioPlayer: Radio toggled ON. Station:", station.name)
            if (audioContextRef.current?.state === 'suspended') {
                audioContextRef.current.resume().then(() => {
                    console.log("RadioPlayer: AudioContext resumed via effect.")
                })
            }
        } else {
            console.log("RadioPlayer: Radio toggled OFF.")
        }
    }, [isRadioOn, station.name])

    // GLOBAL INTERACTION HOOK (The most reliable way to resume AudioContext)
    useEffect(() => {
        const resumeAudio = () => {
            if (audioContextRef.current && audioContextRef.current.state === 'suspended') {
                audioContextRef.current.resume().then(() => {
                    console.log("RadioPlayer: AudioContext resumed via global interaction.")
                })
            }
        }

        window.addEventListener('click', resumeAudio)
        window.addEventListener('keydown', resumeAudio)
        return () => {
            window.removeEventListener('click', resumeAudio)
            window.removeEventListener('keydown', resumeAudio)
        }
    }, [])

    // STATION SWITCH EFFECT
    useEffect(() => {
        if (isRadioOn) {
            console.log("RadioPlayer: Switching station to:", station.name)
            playStaticNoise()
        }
    }, [currentStationIndex, isRadioOn, station.name])

    // PROCEDURAL STATIC NOISE (White Noise)
    const playStaticNoise = () => {
        try {
            if (!audioContextRef.current) {
                audioContextRef.current = new (window.AudioContext || (window as any).webkitAudioContext)()
            }

            const ctx = audioContextRef.current
            if (ctx.state === 'suspended') {
                ctx.resume()
            }

            const bufferSize = ctx.sampleRate * 0.6 // Longer static for transition
            const buffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate)
            const data = buffer.getChannelData(0)

            for (let i = 0; i < bufferSize; i++) {
                data[i] = Math.random() * 2 - 1
            }

            const noise = ctx.createBufferSource()
            noise.buffer = buffer

            const gainNode = ctx.createGain()
            gainNode.gain.value = 0.05 * volume // Even quieter static

            noise.connect(gainNode)
            gainNode.connect(ctx.destination)
            noise.start()
        } catch (e) {
            console.error("RadioPlayer: Static noise error:", e)
        }
    }

    // Native Audio Ref for Streams
    const audioRef = useRef<HTMLAudioElement>(null)

    // UNIFIED PLAYBACK CONTROL
    useEffect(() => {
        // 1. Reset State on Station Change
        setIsPlaying(false)
        console.log(`RadioPlayer: Station changed to ${station.name} (${station.type})`)

        if (station.type === 'stream' && audioRef.current) {
            // STOP old stream
            audioRef.current.pause()
            audioRef.current.src = ""
            audioRef.current.load()

            // START new stream (if Radio is ON)
            if (isRadioOn) {
                // We use the raw URL without cache-busting to avoid forcing pre-roll ads
                audioRef.current.src = station.url
                audioRef.current.load()

                const playPromise = audioRef.current.play()
                if (playPromise !== undefined) {
                    playPromise
                        .then(() => setIsPlaying(true))
                        .catch(e => console.error("RadioPlayer: Stream Play Error", e))
                }
            }
        } else if (station.type === 'youtube') {
            // Stop native audio if active
            if (audioRef.current) {
                audioRef.current.pause()
                audioRef.current.src = ""
            }
            // ReactPlayer handles its own prop updates (url change)
            // We just sync playing state
            setIsPlaying(isRadioOn)
        }

    }, [currentStationIndex, isRadioOn, station])

    // Handle Volume Side Effect separately as it doesn't need to rebuild player
    useEffect(() => {
        if (audioRef.current) audioRef.current.volume = volume
    }, [volume])

    const isYoutube = station.type === 'youtube'
    const isLofiGirl = station.name === 'Lofi Girl'
    const showPlayer = isRadioOn && isLofiGirl

    // Dynamic Container Styles
    const getContainerStyle = () => {
        if (!showPlayer) {
            return "fixed top-[-10px] left-[-10px] w-[1px] h-[1px] opacity-[0.01] overflow-hidden pointer-events-none z-[-1]"
        }

        if (viewMode === 'widget') {
            // Widget Mode: Background
            // We use z-0 so it sits behind the widget content (if widget has transparency)
            // But RadioPlayer is rendered BEFORE content in App.tsx, so it is naturally behind.
            // We just need to make it fill screen.
            return "fixed inset-0 w-full h-full z-[-1] opacity-80"
        } else {
            // Main Mode: PiP Bottom Right
            // z-[60] to be above other UI elements (Hub nav is z-50)
            return "fixed bottom-6 right-6 w-80 aspect-video rounded-xl overflow-hidden shadow-2xl z-[60] border border-white/10 transition-all duration-500 animate-in slide-in-from-bottom-10 fade-in"
        }
    }

    return (
        <div
            className={getContainerStyle()}
            aria-hidden={!showPlayer}
        >
            {isYoutube ? (
                <div className="w-full h-full relative">
                    {/* Overlay to prevent interaction if needed, or allow it? Lofi Girl live chat etc might be distracting. 
                        Let's allow interaction in Main Mode, but block in Widget mode */}
                    {viewMode === 'widget' && <div className="absolute inset-0 z-10 bg-transparent" />}

                    <ReactPlayer
                        ref={playerRef}
                        url={`https://www.youtube.com/watch?v=${station.url}`}
                        playing={isRadioOn && isPlaying}
                        volume={volume}
                        width="100%"
                        height="100%"
                        playsinline
                        onStart={() => console.log("RadioPlayer: YT Playback started.")}
                        onError={(e) => console.error("RadioPlayer: YT Error:", e)}
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
            ) : (
                <audio
                    ref={audioRef}
                    src={station.url}
                    controls={false}
                    onError={(e) => console.error("RadioPlayer: Native Audio Error", e.currentTarget.error)}
                    onCanPlay={() => console.log("RadioPlayer: Native Can Play")}
                    onPlaying={() => console.log("RadioPlayer: Native Playing")}
                />
            )}
        </div>
    )
}
