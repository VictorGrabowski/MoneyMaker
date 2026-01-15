import React, { useState, useEffect } from 'react'
import { X, Play, ChevronLeft, ChevronRight, Save, Pencil } from 'lucide-react'
import { useCookingStore } from '../../store/cookingStore'

interface GrimoireViewProps {
    onClose: () => void
}

const RECIPES = [
    {
        id: 'cookie',
        title: "My First Cookie",
        icon: "🍪",
        desc: "Un classique indémodable. Parfait pour se concentrer 25 minutes.",
        ingredients: [
            "200g de Farine",
            "100g de Chocolat",
            "1 Oeuf de Phoenix",
            "Beaucoup d'amour"
        ],
        time: 25,
        color: "text-amber-900",
        bg: "bg-orange-100",
        border: "border-orange-300"
    },
    {
        id: 'brownie',
        title: "Grandma's Brownie",
        icon: "🍫",
        desc: "Fondant, intense, et magique. Idéal pour les grosses sessions.",
        ingredients: [
            "300g de Chocolat Noir",
            "150g de Beurre (Salé !)",
            "3 Oeufs de Dragon",
            "Une pincée de Poudre d'Etoile"
        ],
        time: 50, // Longer session?
        color: "text-amber-950",
        bg: "bg-amber-800/20",
        border: "border-amber-800"
    }
]

// --- Sub Components ---

const IntroPage = () => (
    <div className="w-full h-full flex flex-col items-center justify-center p-12 text-center">
        <div className="mb-6 opacity-80 mix-blend-multiply">
            <img src="https://cdn-icons-png.flaticon.com/512/2232/2232688.png" alt="Wizard Hat" className="w-32 h-32" />
        </div>
        <h2 className="text-4xl font-serif font-bold text-amber-900 mb-4">Le Grimoire des Saveurs</h2>
        <p className="text-amber-800/80 font-serif italic text-lg leading-relaxed">
            "Ici sont consignées les recettes ancestrales permettant de transformer le temps en délice. <br /><br />
            Choisissez votre sort, préparez vos ingrédients, et laissez la magie opérer."
        </p>
    </div>
)

const RecipePage = ({ recipe, onStart }: { recipe: any, onStart: (id: string) => void }) => (
    <div className="w-full h-full flex">
        {/* Left: Visuals */}
        <div className="w-1/2 p-12 flex flex-col items-center justify-center border-r border-amber-900/10">
            <div className={`w-48 h-48 ${recipe.bg} rounded-full flex items-center justify-center border-4 ${recipe.border} mb-6 shadow-inner`}>
                <span className="text-7xl absolute transition-transform hover:scale-110 cursor-default filter drop-shadow-md">{recipe.icon}</span>
            </div>
            <h2 className={`text-3xl font-serif font-bold ${recipe.color} mb-2 text-center leading-tight`}>{recipe.title}</h2>
            <p className="text-amber-800/60 text-center font-serif italic text-sm px-4">
                "{recipe.desc}"
            </p>
        </div>

        {/* Right: Details */}
        <div className="w-1/2 p-10 flex flex-col justify-between">
            <div>
                <h3 className="text-xl font-bold text-amber-900 mb-4 border-b border-amber-900/20 pb-2">Ingrédients</h3>
                <ul className="space-y-3 text-amber-900/80 font-serif text-sm">
                    {recipe.ingredients.map((ing: string, i: number) => (
                        <li key={i} className="flex items-center gap-3">
                            <div className="w-1.5 h-1.5 bg-amber-900/40 rounded-full" />
                            {ing}
                        </li>
                    ))}
                </ul>

                <div className="mt-8 p-4 bg-white/40 rounded-lg border border-amber-900/10">
                    <h4 className="font-bold text-amber-900/60 text-xs mb-1 uppercase tracking-wider">Durée du Rituel</h4>
                    <p className="text-amber-900 text-2xl font-bold flex items-center gap-2 font-mono">
                        ⏳ {recipe.time} min
                    </p>
                </div>
            </div>

            <button
                onClick={() => onStart(recipe.id)}
                className="w-full py-4 bg-amber-900 text-amber-50 rounded-xl hover:bg-amber-800 transition-all font-bold text-lg flex items-center justify-center gap-2 shadow-lg hover:shadow-xl translate-y-0 hover:-translate-y-1"
            >
                <Play size={20} fill="currentColor" /> Cuisiner
            </button>
        </div>
    </div>
)

const NOTES_BG_STYLE = {
    backgroundImage: "repeating-linear-gradient(transparent, transparent 31px, #78350f 31px, #78350f 32px)"
}

const NotesPage = () => {
    const [note, setNote] = useState("")

    useEffect(() => {
        const saved = localStorage.getItem('grimoire_notes')
        if (saved) setNote(saved)
    }, [])

    const handleChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
        const val = e.target.value
        setNote(val)
        localStorage.setItem('grimoire_notes', val)
    }

    return (
        <div className="w-full h-full p-8 flex flex-col relative">
            <h3 className="text-2xl font-serif font-bold text-amber-900 mb-2 pl-4 flex items-center gap-3">
                <Pencil size={20} className="opacity-60" />
                Notes du Chef
            </h3>
            <div className="flex-1 relative">
                {/* Lines background - Static */}
                <div
                    className="absolute inset-0 pointer-events-none opacity-20 z-0"
                    style={NOTES_BG_STYLE}
                />

                <textarea
                    value={note}
                    onChange={handleChange}
                    placeholder="Écrivez vos pensées, idées de recettes, ou liste de courses ici..."
                    className="w-full h-full bg-transparent resize-none border-none focus:ring-0 text-amber-900 text-2xl leading-[32px] p-2 pt-[3px] font-['Indie_Flower'] outline-none relative z-10"
                    spellCheck={false}
                />

                {/* Save indicator - simplified to avoid group-hover flicker */}
                <div className="absolute bottom-2 right-4 flex items-center gap-1 text-amber-900/40 text-xs italic z-20">
                    <Save size={12} /> Sauvegardé
                </div>

                {/* Decorative Pencil - Resting on the page */}
                <div className="absolute bottom-4 left-4 rotate-[-35deg] opacity-40 pointer-events-none z-20">
                    <Pencil size={32} className="text-amber-900" />
                </div>
            </div>
        </div>
    )
}

// --- Main Component ---

export const GrimoireView: React.FC<GrimoireViewProps> = ({ onClose }) => {
    const startPrep = useCookingStore(s => s.startPrep)
    const [page, setPage] = useState(0)

    // Pages: 0 = Intro, 1..N = Recipes, Last = Notes
    const totalPages = 1 + RECIPES.length + 1

    const handleStart = (recipeId: any) => {
        startPrep(recipeId)
        onClose()
    }

    const renderPageContent = () => {
        if (page === 0) return <IntroPage />
        if (page === totalPages - 1) return <NotesPage />

        // Recipe Pages (1-indexed in logic, so page-1 for array)
        const recipeIndex = page - 1
        return <RecipePage recipe={RECIPES[recipeIndex]} onStart={handleStart} />
    }

    return (
        <div className="absolute inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm animate-in fade-in duration-300">
            {/* The Book Container */}
            <div className="relative w-[900px] h-[650px] bg-[#fdf6e3] rounded-r-2xl rounded-l-md shadow-2xl flex overflow-hidden border-y-[12px] border-r-[12px] border-l-[2px] border-amber-900 bg-[url('https://www.transparenttextures.com/patterns/aged-paper.png')]">

                {/* Visual Binding (Spine) */}
                <div className="absolute left-0 top-0 bottom-0 w-12 bg-gradient-to-r from-amber-950 to-amber-900 shadow-2xl z-20 flex flex-col items-center justify-center gap-12 border-r border-amber-950/50">
                    <div className="w-full h-[2px] bg-amber-400/20" />
                    <div className="w-full h-[2px] bg-amber-400/20" />
                    <div className="w-full h-[2px] bg-amber-400/20" />
                </div>

                {/* Close Button */}
                <button
                    onClick={onClose}
                    className="absolute top-6 right-6 p-2 text-amber-900/60 hover:text-amber-900 hover:bg-amber-900/10 rounded-full transition-colors z-30"
                >
                    <X size={28} />
                </button>

                {/* Main Content Area */}
                <div className="flex-1 ml-12 h-full relative">
                    {/* Navigation Arrows */}
                    {page > 0 && (
                        <button
                            onClick={() => setPage(p => p - 1)}
                            className="absolute left-4 top-1/2 -translate-y-1/2 p-3 text-amber-900/30 hover:text-amber-900 hover:bg-amber-900/5 rounded-full transition-all z-20 -ml-2"
                        >
                            <ChevronLeft size={40} />
                        </button>
                    )}

                    {page < totalPages - 1 && (
                        <button
                            onClick={() => setPage(p => p + 1)}
                            className="absolute right-4 top-1/2 -translate-y-1/2 p-3 text-amber-900/30 hover:text-amber-900 hover:bg-amber-900/5 rounded-full transition-all z-20 -mr-2"
                        >
                            <ChevronRight size={40} />
                        </button>
                    )}

                    {/* Page Content with Slide Animation Keyed by Page */}
                    <div key={page} className="w-full h-full">
                        {renderPageContent()}
                    </div>

                    {/* Page Number */}
                    <div className="absolute bottom-4 w-full text-center text-amber-900/30 font-serif text-sm pointer-events-none">
                        Page {page + 1}
                    </div>
                </div>

            </div>
        </div>
    )
}
