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

    // PLAY/PAUSE SYNC
    useEffect(() => {
        setIsPlaying(isRadioOn)
    }, [isRadioOn])

    // STATION SWITCH EFFECT
    useEffect(() => {
        if (isRadioOn) {
            playStaticNoise()
        }
    }, [currentStationIndex]) // Trigger fade on station change

    // PROCEDURAL STATIC NOISE (White Noise)
    const playStaticNoise = () => {
        try {
            if (!audioContextRef.current) {
                audioContextRef.current = new (window.AudioContext || (window as any).webkitAudioContext)()
            }

            const ctx = audioContextRef.current
            // Resume context if suspended (browser auto-play policy)
            if (ctx.state === 'suspended') {
                ctx.resume()
            }

            const bufferSize = ctx.sampleRate * 0.5 // 0.5 seconds
            const buffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate)
            const data = buffer.getChannelData(0)

            for (let i = 0; i < bufferSize; i++) {
                data[i] = Math.random() * 2 - 1
            }

            const noise = ctx.createBufferSource()
            noise.buffer = buffer

            const gainNode = ctx.createGain()
            gainNode.gain.value = 0.1 * volume // Quieter static

            noise.connect(gainNode)
            gainNode.connect(ctx.destination)
            noise.start()
        } catch (e) {
            console.error("Static noise error:", e)
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
        <div style={{ display: 'none' }}>
            <ReactPlayer
                ref={playerRef}
                url={getUrl()}
                playing={isPlaying}
                volume={volume}
                width="0"
                height="0"
                onBuffer={() => setIsBuffering(true)}
                onBufferEnd={() => setIsBuffering(false)}
                onError={(e) => console.error("ReactPlayer Error:", e)}
                config={{
                    youtube: {
                        playerVars: {
                            showinfo: 0,
                            controls: 0,
                            autoplay: 1
                        }
                    },
                    file: {
                        forceAudio: true
                    }
                }}
            />
        </div>
    )
}
