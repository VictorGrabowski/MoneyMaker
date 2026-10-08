---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
inputDocuments: ['brainstorming-session-2026-01-14.md']
documentCounts:
  brainstorming: 1
  research: 0
  notes: 0
workflowType: 'game-brief'
lastStep: 0
project_name: 'MoneyMaker'
user_name: 'V.grabowski'
date: '2026-01-14'
game_name: 'MoneyMaker'
---

# Game Brief: MoneyMaker

**Date:** 2026-01-14
**Author:** V.grabowski
**Status:** Draft for GDD Development

---

## Executive Summary

**MoneyMaker** est un compagnon de bureau apaisant qui transforme le stress de la productivité en une expérience de découverte chaleureuse. L'application synchronise les revenus réels de l'utilisateur en temps réel, matérialisant chaque centime sous forme de pièces physiques s'accumulant dans une échoppe de pâtisserie personnalisée ("The Bakery"). En alliant un outil de focus Pomodoro à un univers "Cozy" rempli de secrets affectifs, MoneyMaker redonne une valeur tangible et émotionnelle au temps de travail.

---

## Game Vision

### Core Concept

Une application de productivité "chill" qui transforme l'accumulation de salaire en temps réel en une expérience gratifiante de gestion d'une échoppe cozy, rythmée par des sessions de Pomodoro.

### Elevator Pitch

MoneyMaker est un compagnon de bureau apaisant qui incite à l'équilibre en forçant des pauses régulières pour s'occuper de son échoppe virtuelle. En visualisant ses revenus en temps réel (ni plus, ni moins), l'utilisateur redécouvre la valeur tangible de son travail à travers des rituels satisfaisants et une progression lente mais enrichissante.

### Vision Statement

Créer une expérience de découverte quotidienne remplie de secrets, de satisfactions visuelles et de bienveillance. L'objectif est de transformer le stress financier ou professionnel en un moment de calme et de fierté partagée, où chaque fonctionnalité cachée et chaque petit mot doux renforcent le sentiment d'accomplissement et de sérénité.

---

## Target Market

### Primary Audience

Une utilisatrice spécifique (votre copine) au profil de joueuse occasionnelle, aimant les ambiances "Cozy" et la personnalisation. Elle apprécie les expériences calmes, esthétiques et remplies de détails à découvrir.

**Demographics:**
Femme, jeune active, familière avec l'informatique et travaillant sur PC de bureau.

**Gaming Preferences:**
Jeux de simulation de vie et de construction (Animal Crossing, Valheim), esthétique Lo-Fi Girl, appréciation pour les micro-interactions satisfaisantes.

**Motivations:**
Découverte de secrets, sentiment de progression tangible, relaxation après/pendant le travail, et affection pour les attentions personnalisées.

### Secondary Audience

Toute personne travaillant sur ordinateur (freelances, employés de bureau, étudiants) souhaitant suivre ses revenus en temps réel sans stress, tout en structurant ses journées via un système Pomodoro élégant et ludique. Particulièrement attractif pour les jeunes actifs touchant leurs premiers salaires.

### Market Context

MoneyMaker s'inscrit à la croisée des chemins entre les outils de finance personnelle, les utilitaires de productivité (Pomodoro) et les "Cosy Games" d'accumulation.

**Similar Successful Games:**
- **Animal Crossing** (pour la collection et l'ambiance).
- **Habitica** (pour la gamification de la vie réelle).
- **Argent-Salaire.com** (pour l'utilité brute du calcul en temps réel).

**Market Opportunity:**
Il existe un manque d'outils financiers qui soient visuellement "satisfaisants" et émotionnellement engageants. MoneyMaker comble ce vide en alliant l'utilité brute d'un compteur de salaire à une expérience esthétique premium et personnalisable, rendant le rapport à l'argent plus sain et moins abstrait.

---

## Game Fundamentals

### Core Gameplay Pillars

- **Abondance Tangible** : Chaque centime gagné doit être ressenti physiquement (visuel, sonore, physique). L'argent n'est pas un chiffre, c'est une matière que l'on manipule et que l'on voit s'accumuler.
- **Sérénité Productive** : L'application doit réduire l'anxiété liée au travail. L'esthétique cozy, le rythme Pomodoro et le mode minimaliste garantissent un focus total sans stress.
- **Découverte Affective** : Le jeu est un jardin secret rempli de petits mots doux, de recettes de pâtisserie et de références personnelles (Animal Crossing, Valheim, Chips le chat) qui se révèlent petit à petit.

**Pillar Priority:** When pillars conflict, prioritize:
1. Sérénité Productive (le travail ne doit jamais être perturbé)
2. Abondance Tangible
3. Découverte Affective

### Primary Mechanics

- **Accumuler (Verbe Central)** : Voir l'argent s'incrémenter en temps réel. En mode minimaliste, un compteur simple et élégant ; en mode fullscreen, une pluie physique de pièces.
- **Transition Fluide** : Passage organique entre le mode "Vitre Propre" (minimaliste) et le hub "Fullscreen" (boutique). L'ATH du mode minimaliste se retrouve de manière **intra-diégétique** dans la boutique (ex: l'ardoise sur le comptoir affiche le solde de la journée).
- **Focaliser (Pomodoro)** : Lancer des sessions de travail structurées. Le hub cozy n'est accessible que pendant les pauses de gratification.
- **Améliorer & Pâtisser** : Utiliser l'argent pour acheter du mobilier, des ingrédients et débloquer des recettes de pâtisserie dans le Grimoire Sucré.
- **Découvrir** : Cliquer sur les éléments du décor pour trouver des secrets, des anecdotes (Lore) et des messages cachés.

**Core Loop:** Travailler (Minimalisme) → Accumuler du salaire → Sonnerie de Pause → Entrée dans le Hub (Fullscreen) → Dépenser/Pâtisser/Découvrir → Reprise du Travail.

### Player Experience Goals

- **La Gratification** : Ressentir la satisfaction immédiate de "voir ses efforts" se matérialiser physiquement.
- **La Curiosité** : Vouloir découvrir "quelle surprise m'attend aujourd'hui ?" (nouvel item, nouveau message, nouvelle recette).
- **L'Apaisement** : Un sentiment de calme profond, comme entrer dans son café préféré un jour de pluie avec Chips le chat.

**Emotional Journey:** Calme et concentration (Travail) → Surprise et joie (Découverte) → Fierté et accomplissement (Progression du Shop).

---

## Scope and Constraints

### Target Platforms

**Primary:** Windows (Desktop Application via Electron).
**Secondary:** Android (Minimalist mode as a home-screen widget).

### Budget Considerations

Projet personnel (cadeau). Budget zéro ou très faible, privilégiant les outils open-source, les assets gratuits (CC0/Poussière de Domaine) et la création de contenu assistée par IA (génération d'images et de code).

### Team Resources

**Team:** V.grabowski (Solo Developer) assisté par Antigravity (IA Agent).

**Skill Gaps:** Besoin d'une gestion optimisée de la physique des pièces (overflow) et de l'intégration d'une API Météo sans latence.

### Technical Constraints

- **Performance** : Utilisation minimale des ressources CPU/RAM en mode "Vitre Propre" pour ne pas gêner le travail.
- **Persistence** : Stockage local des paramètres (salaire, objectifs) et de l'état du shop sans base de données lourde.
- **Connectivité** : Connexion internet requise pour la météo dynamique et potentiellement le mode social (Livre d'Or).
- **Framework** : Base technique Electron + React + Vite pour garantir la portabilité et la réactivité du hub.

### Scope Realities

Le focus est mis sur la boucle de cœur (Money Tracking) et l'ambiance visuelle avant d'attaquer les systèmes complexes de pâtisserie ou le mode social global. L'expérience doit être parfaite sur Windows avant d'être portée sur Android.

---

## Reference Framework

### Inspiration Games

**Animal Crossing**
- Taking: Système de collection, cycle jour/nuit en temps réel, ambiance "cozy" et bienveillante.
- Not Taking: Le côté répétitif des dialogues et le manque d'utilité directe pour le travail.

**Valheim**
- Taking: Esthétique visuelle "rustique", sentiment de bâtir et d'améliorer son propre foyer (le hub).
- Not Taking: Le combat, le stress de la survie et la difficulté punitive.

**LoFi Girl**
- Taking: Univers visuel apaisant, décor "fenêtre sur le monde", ambiance sonore parfaite pour le focus.
- Not Taking: L'absence d'interactions et de progression.

**Argent-salaire.com**
- Taking: L'idée fondamentale du compteur de salaire qui s'incrémente en temps réel.
- Not Taking: L'interface austère, les publicités et le manque total d'immersion.

### Competitive Analysis

**Direct Competitors:**
- **Habitica** : Gamification de la vie sous forme de RPG. Force : Communauté. Faiblesse : Trop complexe et "chargé" visuellement.
- **Forest** : Aide à la concentration en faisant pousser des arbres. Force : Simplicité. Faiblesse : Manque de matérialité (l'argent ne s'empile pas) et de personnalisation affective.

**Competitor Strengths:**
Efficacité prouvée pour la productivité et large base de fonctionnalités.

**Competitor Weaknesses:**
Manque d'engagement émotionnel profond et de satisfaction physique (physique des pièces).

### Key Differentiators

- **Lore Personnel & Affectif** : L'application n'est pas un outil générique ; elle contient des messages, des anecdotes et des secrets qui ne parlent qu'à l'utilisatrice.
- **Matérialité de la Richesse (Overflow)** : Voir physiquement les pièces déborder du bocal et s'empiler au sol crée une gratification que les chiffres seuls n'offrent pas.
- **Micro-Hub Pâtisserie (The Bakery)** : Une thématique unique liant la productivité à une passion concrète, créant une boucle de collection gourmande (Grimoire Sucré).

**Unique Value Proposition:**
MoneyMaker transforme le temps de travail abstrait en une aventure sensorielle et émotionnelle unique, faite de pièces qui s'empilent et de pâtisseries à débloquer dans un univers ultra-personnalisé.

---

## Content Framework

### World and Setting

Une échoppe de café/pâtisserie chaleureuse et habitée, baignée de petits traits de lumière. Le point de vue est un plan fixe mais riche en vie : effets de fumée, vapeur, et Chips le chat se déplaçant calmement avant de se figer ou de s'asseoir. L'espace suggère une présence humaine (ombres à la fenêtre, bruits de rue, discussions lointaines) sans jamais montrer de personnage distinct de manière à préserver l'imaginaire.

### Narrative Approach

Approche purement environnementale et fragmentée. Le lore n'est jamais imposé mais distillé à travers :
- Les descriptions poétiques ou humoristiques des objets achetés.
- Les intitulés et conditions des succès.

**Story Delivery:** Aucun dialogue direct ou texte de contexte global. L'utilisateur construit sa propre narration à partir des indices visuels et textuels (secrets).

### Content Volume

- **Collectibles** : ~30-50 objets de décoration et mobilier.
- **Pâtisseries** : 10 recettes à débloquer via le Grimoire Sucré (une à la fois).
- **Secrets** : ~20 messages cachés et anecdotes de lore.

---

## Art and Audio Direction

### Visual Style

2D Haute Définition avec un rendu "dessiné à la main" (ni hyper-réaliste, ni pixel art, ni low-poly).
- Style douillet et organique (traits doux, couleurs chaudes).
- Utilisation de sprites 2D pour les objets et l'argent.

**References:** LoFi Girl, Animal Crossing (esprit de collection), Ghibli (pour la chaleur des intérieurs).

### Audio Style

- **Musique** : Radio Lo-Fi avec playlist personnalisable.
- **ASMR** : Bruits de cuisine, craquement de pâtisserie, miaulement de Chips.
- **Ambiance** : Discussions sourdes de café, sons de rue étouffés.
- **Contrôle** : Mixage indépendant pour chaque source sonore (radio, rue, chat, ASMR).

### Production Approach

IA-Assisted Production : Génération initiale des assets visuels et sonores par IA, puis affinage manuel. Possibilité de faire appel à un artiste ultérieurement pour une uniformisation complète. Enregistrements réels prévus pour les bruits du chat.

---

## Risk Assessment

### Key Risks

- **Démotivation (Moyenne/Élevée)** : Risque inhérent au développement solo sur le long terme. Mitigation : Workflow BMAd stimulant, itérations rapides, et gratification immédiate de voir l'app fonctionner.
- **Gestion de la densité visuelle (Moyenne)** : Remplissage du bocal sans "trous" ni débordement chaotique. Mitigation : Utilisation de sprites pré-calculés et couches de profondeur plutôt que physique 2D complexe.

### Technical Challenges

- Optimisation de l'affichage de nombreux sprites 2D (argent) en arrière-plan sans impact sur les performances du PC de travail.
- Mixage audio dynamique avec de multiples sources indépendantes.

### Market Risks

Projet de niche (cadeau personnel) : le risque principal est que l'app ne réponde pas exactement aux attentes émotionnelles de l'utilisatrice finale.

### Mitigation Strategies

- Prioriser le mode "Vitre Propre" pour assurer l'utilité immédiate.
- Tester régulièrement les sensations (game feel) des pièces qui s'empilent.
- Garder le scope serré : une pâtisserie à la fois, ingrédients obligatoires.

---

## Success Criteria

### MVP Definition

- **Widget Minimaliste (Vitre Propre)** : Compteur de salaire discret s'incrémentant en temps réel sur Windows.
- **Hub Primaire (The Bakery)** : Affichage plein écran d'une échoppe cozy avec le chat Chips et le bocal à monnaie.
- **Visualisation des Totaux** : Affichage intra-diégétique (ex: ardoise) du total gagné (Aujourd'hui, Ce mois, Depuis le début).
- **Physique de Base** : Remplissage satisfaisant du bocal via sprites 2D.

### Success Metrics

- **Utilisation Quotidienne** : L'utilisatrice finale lance l'app à chaque session de travail sur son PC.
- **Sourire à la Découverte** : Les secrets et mots doux provoquent une émotion positive réelle.
- **Accomplissement Tangible** : Voir le bocal déborder pour la première fois à la fin du mois.

### Launch Goals

- Version Windows 1.0 (MVP) installée et fonctionnelle sur le PC cible.
- Premiers secrets et ingrédients de base configurés.

---

## Next Steps

### Immediate Actions

1. **Lancer le Workflow GDD** : Détailler les formules de calcul, l'inventaire et les recettes.
2. **Prototype d'Incrémentation** : Coder le moteur de calcul du salaire en temps réel (Electron/React).
3. **Exploration Visuelle** : Générer les concepts IA pour le décor et Chips.

### Research Needs

- API Météo gratuite et intégration "Météo Financière".
- Librairie audio (Howler.js) pour le mixage multivoies.

### Open Questions

- Comment gérer la transition fluide entre widget et fullscreen ?
- Quelles seront les premières recettes du Grimoire Sucré ?

---

_This Game Brief serves as the foundational input for Game Design Document (GDD) creation._

_Next Steps: Use the `workflow gdd` command to create detailed game design documentation._
