import React, { useEffect, useState } from 'react';
import { useBakingStore } from '../store/bakingStore';
import { motion, AnimatePresence } from 'framer-motion';
import { Play, Pause, Square, ArrowRight, ChefHat, Clock } from 'lucide-react';

const BakingView: React.FC = () => {
    const {
        currentRecipe,
        currentPhaseIndex,
        isBaking,
        timeRemaining,
        startPhase,
        pausePhase,
        completePhase,
        tickTimer,
        getCurrentPhase
    } = useBakingStore();

    const currentPhase = getCurrentPhase();
    const [narrativeIndex, setNarrativeIndex] = useState(0);

    // Timer Logic
    useEffect(() => {
        let interval: NodeJS.Timeout;
        if (isBaking) {
            interval = setInterval(() => {
                tickTimer();
            }, 1000);
        }
        return () => clearInterval(interval);
    }, [isBaking, tickTimer]);

    // Narrative Cycler
    useEffect(() => {
        let narrativeInterval: NodeJS.Timeout;
        if (isBaking && currentPhase) {
            narrativeInterval = setInterval(() => {
                setNarrativeIndex((prev) =>
                    (prev + 1) % currentPhase.narrativeSteps.length
                );
            }, 8000); // Change text every 8 seconds
        }
        return () => clearInterval(narrativeInterval);
    }, [isBaking, currentPhase]);

    // Format Time (MM:SS)
    const formatTime = (seconds: number) => {
        const mins = Math.floor(seconds / 60);
        const secs = seconds % 60;
        return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    };

    if (!currentRecipe || !currentPhase) {
        return (
            <div className="flex flex-col items-center justify-center h-full text-slate-400">
                <ChefHat size={48} className="mb-4 opacity-50" />
                <p>Aucune recette sélectionnée.</p>
            </div>
        );
    }

    return (
        <div className="relative h-full w-full flex flex-col bg-amber-50 rounded-xl overflow-hidden shadow-inner text-amber-900">
            {/* Header */}
            <div className="px-6 py-4 flex justify-between items-center bg-white/50 backdrop-blur-sm border-b border-amber-100">
                <div>
                    <h2 className="text-xl font-bold font-serif">{currentRecipe.title}</h2>
                    <p className="text-sm text-amber-700/80">
                        Phase {currentPhaseIndex + 1}/{currentRecipe.totalPhases} : {currentPhase.name}
                    </p>
                </div>
                <div className="flex items-center gap-2 bg-amber-100 px-3 py-1 rounded-full">
                    <Clock size={16} />
                    <span className="font-mono font-medium">{formatTime(timeRemaining)}</span>
                </div>
            </div>

            {/* Main Content */}
            <div className="flex-1 flex flex-col items-center justify-center p-8 text-center">

                {/* Visual Placeholder (To be replaced by Assets) */}
                <div className="w-64 h-64 bg-amber-200 rounded-full mb-8 flex items-center justify-center shadow-lg relative overflow-hidden">
                    {/* Pulsing effect when baking */}
                    {isBaking && (
                        <div className="absolute inset-0 bg-amber-400/20 animate-pulse rounded-full"></div>
                    )}
                    <ChefHat size={64} className="text-amber-500" />
                    <span className="absolute bottom-4 text-xs font-mono opacity-50">{currentPhase.assetId}</span>
                </div>

                {/* Narrative Text */}
                <div className="h-20 flex items-center justify-center px-4">
                    <AnimatePresence mode="wait">
                        <motion.div
                            key={narrativeIndex}
                            initial={{ opacity: 0, y: 5 }}
                            animate={{ opacity: 1, y: 0 }}
                            exit={{ opacity: 0, y: -5 }}
                            className="flex items-center gap-3 text-lg font-medium text-amber-900 bg-white/60 px-6 py-3 rounded-full shadow-sm backdrop-blur-sm"
                        >
                            <span className="text-2xl">
                                {isBaking ? currentPhase.narrativeSteps[narrativeIndex]?.icon : "🥣"}
                            </span>
                            <span className="italic">
                                {isBaking ? currentPhase.narrativeSteps[narrativeIndex]?.text : "Prêt à pâtisser ?"}
                                {isBaking && (
                                    <span className="inline-flex w-4 justify-start">
                                        <motion.span
                                            animate={{ opacity: [0, 1, 0] }}
                                            transition={{ duration: 1.5, repeat: Infinity, times: [0, 0.5, 1] }}
                                        >
                                            .
                                        </motion.span>
                                        <motion.span
                                            animate={{ opacity: [0, 1, 0] }}
                                            transition={{ duration: 1.5, delay: 0.2, repeat: Infinity, times: [0, 0.5, 1] }}
                                        >
                                            .
                                        </motion.span>
                                        <motion.span
                                            animate={{ opacity: [0, 1, 0] }}
                                            transition={{ duration: 1.5, delay: 0.4, repeat: Infinity, times: [0, 0.5, 1] }}
                                        >
                                            .
                                        </motion.span>
                                    </span>
                                )}
                            </span>
                        </motion.div>
                    </AnimatePresence>
                </div>
            </div>

            {/* Controls */}
            <div className="p-8 flex justify-center gap-6">
                {!isBaking ? (
                    <button
                        onClick={startPhase}
                        className="flex items-center gap-3 px-8 py-4 bg-amber-500 hover:bg-amber-600 text-white rounded-full shadow-lg transition-all transform hover:scale-105"
                    >
                        <Play fill="currentColor" />
                        <span className="font-bold text-lg">Cuisiner</span>
                    </button>
                ) : (
                    <button
                        onClick={pausePhase}
                        className="flex items-center gap-3 px-8 py-4 bg-amber-200 hover:bg-amber-300 text-amber-800 rounded-full shadow-md transition-all"
                    >
                        <Pause fill="currentColor" />
                        <span className="font-bold text-lg">Pause</span>
                    </button>
                )}
            </div>

            {/* Progress Bar */}
            <div className="absolute bottom-0 left-0 w-full h-2 bg-amber-100">
                <motion.div
                    className="h-full bg-amber-500"
                    initial={{ width: 0 }}
                    animate={{ width: `${((currentPhase.duration * 60 - timeRemaining) / (currentPhase.duration * 60)) * 100}%` }}
                    transition={{ ease: "linear" }}
                />
            </div>
        </div>
    );
};

export default BakingView;  
