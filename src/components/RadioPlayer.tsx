import React, { useEffect, useRef, useState } from 'react'
import ReactPlayer from 'react-player'
import { useImmersionStore, RADIO_STATIONS } from '../store/immersionStore'

export const RadioPlayer: React.FC = () => {
    const { isRadioOn, currentStationIndex, volume } = useImmersionStore()
    const [isPlaying, setIsPlaying] = useState(false)
    const [isBuffering, setIsBuffering] = useState(false)
    const audioContextRef = useRef<AudioContext | null>(null)
    const playerRef = useRef<ReactPlayer>(null)

    const station = RADIO_STATIONS[currentStationIndex]

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

            const bufferSize = ctx.sampleRate * 0.3 // Shorter static
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

    // URL Handling: If it's YouTube, we need the full URL
    const getUrl = () => {
        if (station.type === 'youtube') {
            return `https://www.youtube.com/watch?v=${station.url}`
        }
        return station.url
    }

    return (
        <div
            className="fixed top-[-10px] left-[-10px] w-[1px] h-[1px] opacity-[0.01] overflow-hidden pointer-events-none z-[-1]"
            aria-hidden="true"
        >
            <ReactPlayer
                ref={playerRef}
                url={getUrl()}
                playing={isRadioOn && isPlaying}
                volume={volume}
                width="100%"
                height="100%"
                playsinline
                onStart={() => console.log("RadioPlayer: Playback started.")}
                onPlay={() => console.log("RadioPlayer: onPlay event.")}
                onPause={() => console.log("RadioPlayer: onPause event.")}
                onBuffer={() => {
                    setIsBuffering(true)
                    console.log("RadioPlayer: Buffering...")
                }}
                onBufferEnd={() => {
                    setIsBuffering(false)
                    console.log("RadioPlayer: Buffering ended.")
                }}
                onError={(e) => console.error("RadioPlayer: ReactPlayer Error:", e)}
                config={{
                    youtube: {
                        playerVars: {
                            showinfo: 0,
                            controls: 0,
                            autoplay: 1,
                            playsinline: 1
                        }
                    },
                    file: {
                        forceAudio: true,
                        attributes: {
                            controlsList: 'nodownload'
                        }
                    }
                }}
            />
        </div>
    )
}
