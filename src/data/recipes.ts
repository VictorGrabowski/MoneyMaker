export type RecipeCategory = 'Sucré' | 'Salé';

export type RecipeDuration = 'Court (25m)' | 'Moyen (50m)' | 'Long (4x25m)';

export type RecipeType =
    | 'Gâteau'
    | 'Tarte'
    | 'Biscuit'
    | 'Boulangerie'
    | 'Snack'
    | 'Entremets';

export interface RecipePhase {
    id: string;
    name: string; // Nom de la phase (ex: "Préparation de la pâte")
    duration: number; // En minutes, standard 25
    narrativeSteps: { text: string; icon: string }[]; // Phrases d'ambiance avec icône
    instructions: string[]; // Vraie recette pour cette phase
    assetId: string; // Id pour l'image (ex: "lemon_pie_dough")
}

export interface Recipe {
    id: string;
    title: string;
    category: RecipeCategory;
    durationLabel: RecipeDuration;
    type: RecipeType;
    totalPhases: number;
    description: string;
    phases: RecipePhase[];
}

export const RECIPES: Recipe[] = [
    // --- RECETTES COURTES (1 Phase / 25m) ---
    {
        id: 'chocolate_chip_cookies',
        title: 'Cookies Pépites Chocolat',
        category: 'Sucré',
        durationLabel: 'Court (25m)',
        type: 'Biscuit',
        totalPhases: 1,
        description: 'Des cookies classiques, croustillants dehors et moelleux dedans.',
        phases: [
            {
                id: 'cookies_all',
                name: 'Préparation & Cuisson',
                duration: 25,
                assetId: 'cookies_baking',
                narrativeSteps: [
                    { text: "Mélange du beurre mou et du sucre...", icon: "🥣" },
                    { text: "Ajout de l'œuf et de la vanille...", icon: "🥚" },
                    { text: "Incorporation de la farine...", icon: "🌾" },
                    { text: "Pluie de pépites de chocolat !", icon: "🍫" },
                    { text: "Façonnage des petites boules...", icon: "👐" },
                    { text: "Enfournement...", icon: "🔥" },
                    { text: "Ça commence à sentir bon...", icon: "👃" },
                    { text: "Dorure parfaite en cours...", icon: "✨" },
                    { text: "Sortie du four !", icon: "🍪" }
                ],
                instructions: [
                    "Mélanger 120g de beurre mou avec 100g de sucre.",
                    "Ajouter 1 œuf et de l'extrait de vanille.",
                    "Incorporer 220g de farine et 1/2 sachet de levure.",
                    "Ajouter 100g de pépites de chocolat.",
                    "Former des boules sur une plaque.",
                    "Cuire 10-12 minutes à 180°C."
                ]
            }
        ]
    },
    {
        id: 'mug_cake_chocolat',
        title: 'Mug Cake Fondant',
        category: 'Sucré',
        durationLabel: 'Court (25m)',
        type: 'Gâteau',
        totalPhases: 1,
        description: 'Un plaisir chocolaté express, prêt en quelques minutes.',
        phases: [
            {
                id: 'mug_cake_all',
                name: 'Mélange & Micro-ondes',
                duration: 25,
                assetId: 'mug_cake_mixing',
                narrativeSteps: [
                    { text: "Choix de votre plus beau mug...", icon: "☕" },
                    { text: "Casser le chocolat en morceaux...", icon: "🍫" },
                    { text: "Fusion du beurre et du chocolat...", icon: "🧈" },
                    { text: "Mélange vigoureux...", icon: "🥄" },
                    { text: "Ajout de la farine et du sucre...", icon: "🌾" },
                    { text: "Cuisson express !", icon: "⚡" },
                    { text: "Attente insoutenable que ça refroidisse...", icon: "⏳" },
                    { text: "Dégustation mentale...", icon: "😋" }
                ],
                instructions: [
                    "Faire fondre 40g de chocolat et 30g de beurre.",
                    "Ajouter 20g de sucre et 1 œuf, mélanger.",
                    "Ajouter 20g de farine.",
                    "Cuire 1 min au micro-ondes.",
                    "Laisser tiédir avant de déguster."
                ]
            }
        ]
    },

    // --- RECETTES MOYENNES (2 Phases / 50m) ---
    {
        id: 'brioche_tressee',
        title: 'Brioche Tressée',
        category: 'Sucré',
        durationLabel: 'Moyen (50m)',
        type: 'Boulangerie',
        totalPhases: 2,
        description: 'Une brioche dorée et filante pour le petit déjeuner.',
        phases: [
            {
                id: 'brioche_dough',
                name: 'Pétrissage & Pousse',
                duration: 25,
                assetId: 'brioche_kneading',
                narrativeSteps: [
                    { text: "Réveil de la levure...", icon: "✨" },
                    { text: "Pétrissage lent...", icon: "👐" },
                    { text: "Ajout du beurre petit à petit...", icon: "🧈" },
                    { text: "La pâte devient élastique...", icon: "🥨" },
                    { text: "Couverture du bol...", icon: "🥣" },
                    { text: "La pâte se repose au chaud...", icon: "🌡️" },
                    { text: "Ça gonfle doucement...", icon: "🎈" },
                    { text: "Patience, la levure travaille...", icon: "🦠" }
                ],
                instructions: [
                    "Mélanger 250g de farine, 30g de sucre, 1 sachet de levure boulangère.",
                    "Ajouter 2 œufs et 50ml de lait tiède.",
                    "Pétrir pendant 10 minutes.",
                    "Incorporer 100g de beurre mou.",
                    "Laisser reposer la pâte (1ère pousse)."
                ]
            },
            {
                id: 'brioche_baking',
                name: 'Façonnage & Cuisson',
                duration: 25,
                assetId: 'brioche_oven',
                narrativeSteps: [
                    { text: "Dégazage de la pâte...", icon: "👊" },
                    { text: "Division en 3 brins...", icon: "🔪" },
                    { text: "Tressage délicat...", icon: "🧶" },
                    { text: "Dorure au jaune d'œuf...", icon: "🖌️" },
                    { text: "Enfournement !", icon: "🔥" },
                    { text: "L'odeur de boulangerie arrive...", icon: "👃" },
                    { text: "La croûte dore...", icon: "🥖" },
                    { text: "C'est prêt et magnifique !", icon: "🤩" }
                ],
                instructions: [
                    "Chasser l'air de la pâte.",
                    "Former 3 boudins et réaliser une tresse.",
                    "Laisser pousser encore un peu si possible.",
                    "Badigeonner de jaune d'œuf.",
                    "Cuire 25 min à 180°C."
                ]
            }
        ]
    },
    {
        id: 'focaccia_herbes',
        title: 'Focaccia Romarin',
        category: 'Salé',
        durationLabel: 'Moyen (50m)',
        type: 'Boulangerie',
        totalPhases: 2,
        description: 'Pain italien à l\'huile d\'olive et aux herbes.',
        phases: [
            {
                id: 'focaccia_prep',
                name: 'Mélange & Repos',
                duration: 25,
                assetId: 'focaccia_dough',
                narrativeSteps: [
                    { text: "Mélange farine et eau...", icon: "🥣" },
                    { text: "L'huile d'olive coule à flots...", icon: "🫒" },
                    { text: "Pétrissage souple...", icon: "👐" },
                    { text: "La pâte est hydratée...", icon: "💧" },
                    { text: "Repos bien mérité...", icon: "😴" },
                    { text: "Les bulles se forment...", icon: "🫧" },
                    { text: "Fermentation en cours...", icon: "🦠" }
                ],
                instructions: [
                    "Mélanger 500g de farine, 300ml d'eau tiède, levure.",
                    "Ajouter sel et généreuse huile d'olive.",
                    "Pétrir jusqu'à obtenir une pâte souple.",
                    "Laisser pousser à l'abri des courants d'air."
                ]
            },
            {
                id: 'focaccia_baking',
                name: 'Empreintes & Cuisson',
                duration: 25,
                assetId: 'focaccia_oven',
                narrativeSteps: [
                    { text: "Étaler la pâte sur la plaque...", icon: "📜" },
                    { text: "Faire des trous avec les doigts...", icon: "👇" },
                    { text: "Encore de l'huile d'olive...", icon: "🫒" },
                    { text: "Saupoudrage de romarin et fleur de sel...", icon: "🌿" },
                    { text: "Au four !", icon: "🔥" },
                    { text: "Ça croustille...", icon: "👂" },
                    { text: "Dorée comme le soleil d'Italie...", icon: "☀️" }
                ],
                instructions: [
                    "Étaler la pâte sur une plaque huilée.",
                    "Faire des empreintes avec le bout des doigts.",
                    "Arroser d'huile et parsemer de romarin.",
                    "Cuire 20-25 min à 200°C."
                ]
            }
        ]
    },

    // --- RECETTES LONGUES (4 Phases / 1h40) ---
    {
        id: 'tarte_citron_meringuee',
        title: 'Tarte Citron Meringuée',
        category: 'Sucré',
        durationLabel: 'Long (4x25min)',
        type: 'Tarte',
        totalPhases: 4,
        description: 'Le grand classique : pâte sablée, crémeux citron acidulé et nuage de meringue.',
        phases: [
            {
                id: 'lemon_pie_dough',
                name: 'La Pâte Sablée',
                duration: 25,
                assetId: 'pie_dough_prep',
                narrativeSteps: [
                    { text: "Sablage du beurre et de la farine...", icon: "👐" },
                    { text: "Ajout du sucre glace...", icon: "🍚" },
                    { text: "L'œuf lie le tout...", icon: "🥚" },
                    { text: "Fraisage de la pâte...", icon: "💪" },
                    { text: "Formation d'une boule...", icon: "🥯" },
                    { text: "Repos au frais...", icon: "❄️" },
                    { text: "Étlaage au rouleau...", icon: "🥢" },
                    { text: "Fonçage du moule...", icon: "🥧" }
                ],
                instructions: [
                    "Sabler 250g de farine et 125g de beurre froid.",
                    "Ajouter 70g de sucre glace et 1 jaune d'œuf.",
                    "Former une boule sans trop travailler la pâte.",
                    "Laisser reposer au frais 15 min.",
                    "Étaler et foncer le moule à tarte."
                ]
            },
            {
                id: 'lemon_pie_blind_bake',
                name: 'Cuisson à Blanc & Crémeux',
                duration: 25,
                assetId: 'pie_blind_bake',
                narrativeSteps: [
                    { text: "Piquage du fond de tarte...", icon: "🍴" },
                    { text: "Cuisson à blanc au four...", icon: "🔥" },
                    { text: "Pressage des citrons...", icon: "🍋" },
                    { text: "Zestage délicat...", icon: "🔪" },
                    { text: "Mélange œufs et sucre pour la crème...", icon: "🌪️" },
                    { text: "Le fond de tarte est cuit et doré !", icon: "🥧" },
                    { text: "Préparation de la casserole...", icon: "🥘" }
                ],
                instructions: [
                    "Cuire le fond de tarte à blanc 15-20 min à 180°C.",
                    "Pendant ce temps, prélever le zeste de 2 citrons.",
                    "Presser le jus de 4 citrons (env. 150ml).",
                    "Fouetter 3 œufs avec 150g de sucre."
                ]
            },
            {
                id: 'lemon_pie_curd',
                name: 'Cuisson du Crémeux',
                duration: 25,
                assetId: 'lemon_curd_cooking',
                narrativeSteps: [
                    { text: "Chauffer le jus de citron...", icon: "🔥" },
                    { text: "Verser sur les œufs...", icon: "🥚" },
                    { text: "Retour à la casserole...", icon: "🥘" },
                    { text: "Vannage à la spatule...", icon: "🥄" },
                    { text: "La crème s'épaissit...", icon: "🍮" },
                    { text: "Ajout du beurre pour le brillant...", icon: "🧈" },
                    { text: "Coulage sur le fond de tarte...", icon: "🌊" },
                    { text: "Lissage parfait...", icon: "✨" }
                ],
                instructions: [
                    "Cuire le mélange citron/œufs à feu moyen en remuant.",
                    "Aux premiers bouillons, retirer du feu.",
                    "Incorporer 75g de beurre en morceaux.",
                    "Verser la crème sur le fond de tarte cuit.",
                    "Laisser refroidir."
                ]
            },
            {
                id: 'lemon_pie_meringue',
                name: 'Meringue Italienne & Finition',
                duration: 25,
                assetId: 'meringue_torching',
                narrativeSteps: [
                    { text: "Cuisson du sirop de sucre (118°C)...", icon: "🌡️" },
                    { text: "Montage des blancs en neige...", icon: "☁️" },
                    { text: "Verser le sirop en filet...", icon: "💧" },
                    { text: "Le fouet tourne à fond...", icon: "🌪️" },
                    { text: "Bec d'oiseau magnifique...", icon: "🐦" },
                    { text: "Pochage des décorations...", icon: "🧁" },
                    { text: "Coup de chalumeau final...", icon: "🔥" },
                    { text: "Chef d'œuvre !", icon: "🏆" }
                ],
                instructions: [
                    "Cuire 200g de sucre et 70g d'eau à 118°C.",
                    "Monter 100g de blancs d'œufs.",
                    "Verser le sirop sur les blancs en fouettant.",
                    "Fouetter jusqu'à refroidissement (Meringue Italienne).",
                    "Pocher sur la tarte et dorer au chalumeau."
                ]
            }
        ]
    },
    {
        id: 'black_forest_cake',
        title: 'Forêt Noire',
        category: 'Sucré',
        durationLabel: 'Long (4x25min)',
        type: 'Gâteau',
        totalPhases: 4,
        description: 'Génoise cacao, chantilly légère et cerises griottes. Un monument.',
        phases: [
            {
                id: 'forest_sponge',
                name: 'Génoise Cacao',
                duration: 25,
                assetId: 'cocoa_sponge_prep',
                narrativeSteps: [
                    { text: "Fouetter œufs et sucre au bain-marie...", icon: "🌪️" },
                    { text: "Le mélange double, triple de volume...", icon: "☁️" },
                    { text: "C'est mousseux et léger...", icon: "🌬️" },
                    { text: "Pluie de cacao et farine...", icon: "🌫️" },
                    { text: "Mélange délicat à la maryse...", icon: "🥄" },
                    { text: "Verser dans le moule...", icon: "🕳️" },
                    { text: "Enfournement douceur...", icon: "🔥" }
                ],
                instructions: [
                    "Fouetter 4 œufs et 125g de sucre au bain-marie jusqu'à 40°C.",
                    "Continuer au batteur jusqu'à complet refroidissement.",
                    "Tamiser 90g de farine et 30g de cacao.",
                    "Incorporer délicatement.",
                    "Cuire 20-25 min à 180°C."
                ]
            },
            {
                id: 'forest_syrup_cherries',
                name: 'Sirop & Griottes',
                duration: 25,
                assetId: 'cherry_prep',
                narrativeSteps: [
                    { text: "Égouttage des griottes...", icon: "🍒" },
                    { text: "Récupération du jus...", icon: "🍷" },
                    { text: "Ajout de kirsch (optionnel)...", icon: "🥃" },
                    { text: "Cuisson du sirop d'imbibage...", icon: "🔥" },
                    { text: "La génoise refroidit...", icon: "❄️" },
                    { text: "Découpe de la génoise en 3 disques...", icon: "🔪" },
                    { text: "Attention à la régularité...", icon: "📏" }
                ],
                instructions: [
                    "Égoutter un bocal de griottes au sirop.",
                    "Réaliser un sirop avec le jus et un peu de sucre.",
                    "Parfumer avec du Kirsch si désiré.",
                    "Couper la génoise froide en 3 disques égaux."
                ]
            },
            {
                id: 'forest_chantilly',
                name: 'Chantilly Nuage',
                duration: 25,
                assetId: 'whipping_cream',
                narrativeSteps: [
                    { text: "Crème liquide très froide...", icon: "🥛" },
                    { text: "Le fouet démarre doucement...", icon: "🌪️" },
                    { text: "Ajout du sucre glace...", icon: "🍚" },
                    { text: "Accélération...", icon: "🚀" },
                    { text: "La crème prend...", icon: "🍦" },
                    { text: "Ferme mais pas beurre...", icon: "💪" },
                    { text: "Préparation de la poche à douille...", icon: "🥡" }
                ],
                instructions: [
                    "Monter 50cl de crème liquide entière très froide.",
                    "Ajouter 50g de sucre glace quand elle commence à prendre.",
                    "Serrer jusqu'à obtenir une chantilly ferme.",
                    "Mettre en poche."
                ]
            },
            {
                id: 'forest_assembly',
                name: 'Montage & Copeaux',
                duration: 25,
                assetId: 'cake_decorating',
                narrativeSteps: [
                    { text: "Imbiber le premier biscuit...", icon: "🌧️" },
                    { text: "Couche de chantilly...", icon: "☁️" },
                    { text: "Dissémination des griottes...", icon: "🍒" },
                    { text: "Deuxième biscuit...", icon: "🍰" },
                    { text: "On répète l'opération...", icon: "🔄" },
                    { text: "Masquage du gâteau à la chantilly...", icon: "👻" },
                    { text: "Râper le chocolat pour les copeaux...", icon: "🍫" },
                    { text: "Décoration finale...", icon: "🎀" }
                ],
                instructions: [
                    "Imbiber chaque disque de sirop.",
                    "Alterner couche de biscuit, chantilly, et griottes.",
                    "Recouvrir entièrement le gâteau de chantilly.",
                    "Décorer avec des copeaux de chocolat et des griottes entières."
                ]
            }
        ]
    }
];
