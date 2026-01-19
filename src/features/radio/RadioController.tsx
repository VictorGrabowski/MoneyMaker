import { useEffect, useRef, useState, useCallback } from 'react'
import { Howl, Howler } from 'howler'
import { useImmersionStore, RADIO_STATIONS } from '../../store/immersionStore'

export const useRadioController = () => {
    const { isRadioOn, currentStationIndex, volume } = useImmersionStore()
    const station = RADIO_STATIONS[currentStationIndex]

    // Logic State
    const [isPlaying, setIsPlaying] = useState(false) // For UI feedback
    const howlRef = useRef<Howl | null>(null)
    const audioContextRef = useRef<AudioContext | null>(null)

    // --- STATIC NOISE GENERATOR (Proedural) ---
    const playStaticNoise = useCallback(() => {
        try {
            if (!audioContextRef.current) {
                audioContextRef.current = new (window.AudioContext || (window as any).webkitAudioContext)()
            }
            const ctx = audioContextRef.current
            if (ctx.state === 'suspended') ctx.resume()

            const bufferSize = ctx.sampleRate * 0.8 // 0.8s burst
            const buffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate)
            const data = buffer.getChannelData(0)

            for (let i = 0; i < bufferSize; i++) {
                data[i] = Math.random() * 2 - 1
            }

            const noise = ctx.createBufferSource()
            noise.buffer = buffer

            // Filter to make it sound more "Radio" (Bandpass)
            const filter = ctx.createBiquadFilter()
            filter.type = 'bandpass'
            filter.frequency.value = 1000

            const gainNode = ctx.createGain()
            gainNode.gain.value = 0.1 * volume // Quiet static

            noise.connect(filter)
            filter.connect(gainNode)
            gainNode.connect(ctx.destination)

            noise.start()
        } catch (e) {
            console.error("RadioController: Static noise error", e)
        }
    }, [volume])

    // --- HOWLER STREAM HANDLER ---
    useEffect(() => {
        // Cleanup previous Howl
        if (howlRef.current) {
            howlRef.current.unload()
            howlRef.current = null
        }

        // Trigger Static on station change (if radio is ON)
        if (isRadioOn) {
            playStaticNoise()
        }

        if (station.type === 'stream') {
            console.log(`RadioController: Init Howl for ${station.name}`)

            if (isRadioOn) {
                const sound = new Howl({
                    src: [station.url],
                    html5: true, // Crucial for streams
                    format: ['mp3', 'aac'],
                    volume: volume,
                    autoplay: true,
                    onplay: () => setIsPlaying(true),
                    onend: () => setIsPlaying(false),
                    onloaderror: (id, err) => console.error("Radio Load Error", err),
                    onplayerror: (id, err) => console.error("Radio Play Error", err)
                })
                howlRef.current = sound
            }
        } else {
            // YouTube handling is done in UI via props, but we manage 'isPlaying' state intent
            setIsPlaying(isRadioOn)
        }

        return () => {
            if (howlRef.current) howlRef.current.unload()
        }
    }, [currentStationIndex, isRadioOn, station, playStaticNoise]) // Volume is handled separately

    // --- VOLUME HANDLER ---
    useEffect(() => {
        if (howlRef.current) {
            howlRef.current.volume(volume)
        }
    }, [volume])

    // --- GLOBAL AUDIO CONTEXT RESUME (Chrome Policy) ---
    useEffect(() => {
        const resumeAudio = () => {
            if (Howler.ctx && Howler.ctx.state === 'suspended') {
                Howler.ctx.resume()
            }
            if (audioContextRef.current && audioContextRef.current.state === 'suspended') {
                audioContextRef.current.resume()
            }
        }
        window.addEventListener('click', resumeAudio)
        return () => window.removeEventListener('click', resumeAudio)
    }, [])

    return {
        station,
        isRadioOn,
        isPlaying, // For visual feedback
        volume
    }
}
