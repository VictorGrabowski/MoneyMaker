import React, { useState } from 'react';
import { RECIPES, Recipe, RecipeCategory, RecipeDuration, RecipeType } from '../data/recipes';
import { useBakingStore } from '../store/bakingStore';
import { Book, Clock, ChevronRight, ArrowLeft, ChefHat } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

const RecipeBook: React.FC<{ onBack: () => void }> = ({ onBack }) => {
    const { selectRecipe, startPhase } = useBakingStore();
    const [step, setStep] = useState<number>(0);
    const [selectedCategory, setSelectedCategory] = useState<RecipeCategory | null>(null);
    const [selectedDuration, setSelectedDuration] = useState<RecipeDuration | null>(null);
    const [selectedType, setSelectedType] = useState<RecipeType | null>(null);

    // Helpers to filter recipes
    const getDurations = () => {
        if (!selectedCategory) return [];
        const durationSet = new Set(
            RECIPES.filter(r => r.category === selectedCategory).map(r => r.durationLabel)
        );
        return Array.from(durationSet);
    };

    const getTypes = () => {
        if (!selectedCategory || !selectedDuration) return [];
        const typeSet = new Set(
            RECIPES.filter(r =>
                r.category === selectedCategory &&
                r.durationLabel === selectedDuration
            ).map(r => r.type)
        );
        return Array.from(typeSet);
    };

    const getFilteredRecipes = () => {
        return RECIPES.filter(r =>
            r.category === selectedCategory &&
            r.durationLabel === selectedDuration &&
            r.type === selectedType
        );
    };

    const handleReset = () => {
        setStep(0);
        setSelectedCategory(null);
        setSelectedDuration(null);
        setSelectedType(null);
    };

    const renderStep = () => {
        switch (step) {
            case 0: // Category Selection
                return (
                    <div className="grid grid-cols-2 gap-6 p-8">
                        {['Sucré', 'Salé'].map((cat) => (
                            <button
                                key={cat}
                                onClick={() => {
                                    setSelectedCategory(cat as RecipeCategory);
                                    setStep(1);
                                }}
                                className="h-48 rounded-2xl bg-amber-100 hover:bg-amber-200 border-2 border-amber-200 flex flex-col items-center justify-center gap-4 transition-all transform hover:scale-105"
                            >
                                <span className="text-4xl">{cat === 'Sucré' ? '🧁' : '🍕'}</span>
                                <span className="text-2xl font-serif font-bold text-amber-900">{cat}</span>
                            </button>
                        ))}
                    </div>
                );

            case 1: // Duration Selection
                return (
                    <div className="grid grid-cols-1 gap-4 p-8">
                        <h3 className="text-xl font-serif text-amber-900 mb-4 flex items-center gap-2">
                            <Clock size={20} /> Combien de temps avez-vous ?
                        </h3>
                        {getDurations().map((dur) => (
                            <button
                                key={dur}
                                onClick={() => {
                                    setSelectedDuration(dur as RecipeDuration);
                                    setStep(2);
                                }}
                                className="p-6 rounded-xl bg-white border border-amber-100 hover:border-amber-300 shadow-sm hover:shadow-md text-left transition-all"
                            >
                                <span className="text-lg font-medium text-amber-900">{dur}</span>
                            </button>
                        ))}
                    </div>
                );

            case 2: // Type Selection
                return (
                    <div className="grid grid-cols-2 gap-4 p-8">
                        <h3 className="col-span-2 text-xl font-serif text-amber-900 mb-4">
                            Quelle envie ?
                        </h3>
                        {getTypes().map((type) => (
                            <button
                                key={type}
                                onClick={() => {
                                    setSelectedType(type as RecipeType);
                                    setStep(3);
                                }}
                                className="p-6 rounded-xl bg-white border border-amber-100 hover:border-amber-300 shadow-sm flex flex-col items-center gap-2 transition-all"
                            >
                                <ChefHat className="text-amber-400" />
                                <span className="font-medium text-amber-900">{type}</span>
                            </button>
                        ))}
                    </div>
                );

            case 3: // Recipe List
                const recipes = getFilteredRecipes();
                return (
                    <div className="grid grid-cols-1 gap-4 p-8">
                        {recipes.map((recipe) => (
                            <button
                                key={recipe.id}
                                onClick={() => {
                                    selectRecipe(recipe.id);
                                    startPhase();
                                }}
                                className="group relative overflow-hidden rounded-xl bg-white border border-amber-100 hover:border-amber-400 shadow-sm hover:shadow-lg transition-all text-left"
                            >
                                <div className="p-6">
                                    <div className="flex justify-between items-start mb-2">
                                        <h4 className="text-xl font-bold text-amber-900">{recipe.title}</h4>
                                        <span className="bg-amber-100 text-amber-800 text-xs px-2 py-1 rounded-full font-mono">
                                            {recipe.totalPhases} Phase{recipe.totalPhases > 1 ? 's' : ''}
                                        </span>
                                    </div>
                                    <p className="text-sm text-amber-700/80 line-clamp-2">{recipe.description}</p>
                                </div>
                                <div className="absolute bottom-0 left-0 w-full h-1 bg-amber-200 group-hover:bg-amber-500 transition-colors" />
                            </button>
                        ))}
                    </div>
                );
        }
    };

    return (
        <div className="h-full flex flex-col bg-amber-50/50">
            {/* Header */}
            <div className="p-6 border-b border-amber-100 flex items-center gap-4 bg-white/80 backdrop-blur-sm">
                <button
                    onClick={step === 0 ? onBack : () => setStep(step - 1)}
                    className="p-2 hover:bg-amber-100 rounded-full text-amber-800 transition-colors"
                >
                    <ArrowLeft size={24} />
                </button>
                <div className="flex-1">
                    <h2 className="text-2xl font-serif font-bold text-amber-900 flex items-center gap-2">
                        <Book className="text-amber-600" />
                        Livre de Recettes
                    </h2>
                    {step > 0 && (
                        <div className="flex items-center gap-2 text-xs text-amber-600 mt-1">
                            <span>{selectedCategory}</span>
                            {selectedDuration && <><ChevronRight size={12} /> <span>{selectedDuration}</span></>}
                            {selectedType && <><ChevronRight size={12} /> <span>{selectedType}</span></>}
                        </div>
                    )}
                </div>
            </div>

            {/* Content with Animation */}
            <div className="flex-1 overflow-y-auto custom-scrollbar">
                <AnimatePresence mode="wait">
                    <motion.div
                        key={step}
                        initial={{ opacity: 0, x: 20 }}
                        animate={{ opacity: 1, x: 0 }}
                        exit={{ opacity: 0, x: -20 }}
                        transition={{ duration: 0.2 }}
                        className="h-full"
                    >
                        {renderStep()}
                    </motion.div>
                </AnimatePresence>
            </div>
        </div>
    );
};

export default RecipeBook;
