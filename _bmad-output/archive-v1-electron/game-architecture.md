---
title: 'Game Architecture'
project: 'MoneyMaker'
date: '2026-01-15'
author: 'V.grabowski'
version: '1.0'
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8, 9]
status: 'complete'
engine: 'electron-vite'
platform: 'Windows'
---

# Game Architecture

## Executive Summary

L'architecture de **MoneyMaker** est conçue pour être performante, immersive et respectueuse de la vie privée. Basée sur **electron-vite**, elle permet de transformer le salaire réel en temps réel en une expérience de pâtisserie cozy habitée par Chips le chat.

**Décisions Architecturales Clés :**
- **Catch-up Burst Logic** : Accumulation de salaire hors-ligne et "pluie" de pièces physique lissée à l'ouverture du Hub.
- **Matter.js Soft-Body** : Simulation physique feutrée (effet coussin) pour les pièces de monnaie.
- **Zustand Event Bus** : Synchronisation découplée entre le moteur de salaire (Back) et le Hub ASMR (Front).

**Structure du Projet :** Organisation hybride par fonctionnalités (Renderer) et services (Main), optimisée pour le développement parallèle par agents AI.

---

## Document Status

This architecture document is being created through the BMGD Architecture Workflow.

**Steps Completed:** 7 of 9 (Implementation Patterns)

---

## Project Structure

### Organization Pattern

**Pattern:** Hybrid (Feature-driven in Renderer).

**Rationale:** Permet une séparation nette entre les processus Electron (Main/Renderer) tout en organisant le code de l'interface par domaines fonctionnels (Bakery, Radio, Libro) pour faciliter le développement parallèle.

### Directory Structure

```bash
MoneyMaker/
├── src/
│   ├── main/               # LOGIQUE LOURDE (Processing, Persistence)
│   │   ├── services/       # salaryEngine.ts, weatherService.ts
│   │   └── index.ts        # Point d'entrée Electron (Main Process)
│   ├── preload/            # LE PONT (ContextBridge)
│   │   └── index.ts        # Exposition des APIs sécurisées
│   └── renderer/           # LE HUB COZY (React + Physics)
│       ├── src/
│       │   ├── components/ # UI Partagée (Buttons, Modals)
│       │   ├── features/   # SYSTÈMES AUTONOMES (Feature-sliced)
│       │   │   ├── bakery/ # Matter.js Hub, BurstManager
│       │   │   ├── libro/  # Livre de Comptes, Notes, Stats
│       │   │   └── radio/  # Audio, HLS Streams, Filters
│       │   ├── hooks/      # useSalary, usePhysics
│       │   └── store/      # Zustand store.ts
│       └── assets/         # WebP, SVG, SFX
└── resources/              # Icônes app, Installer resources
```

### System Location Mapping

| System | Location | Responsibility |
| :--- | :--- | :--- |
| **Salary Logic** | `src/main/services` | Calculer les gains hors-ligne et en temps réel. |
| **Physics Engine** | `src/renderer/.../bakery` | Gérer la chute et l'empilement des pièces. |
| **State Sync** | `src/renderer/src/store` | Centraliser l'état réactif global. |
| **Audio Mixing** | `src/renderer/.../radio` | Gérer le mixage Radio vs SFX. |

---

## Implementation Patterns

### Novel Pattern: Catch-up Burst

**Purpose:** Gérer l'accumulation de salaire hors-ligne et déclencher une "pluie" de pièces satisfaisante à l'ouverture du Hub sans saturer le moteur de physique.

**Components:**
- **Persistence (Main)** : Stocke le `lastSeenTimestamp`.
- **SalaryEngine (Main)** : Calcule le `delta` lors du focus/accès.
- **BurstManager (Renderer)** : Sprawne les entités Matter.js de manière lissée.

**Data Flow:**
1. Focus App -> Main calcule `amount = (now - lastSeen) * rate`.
2. Main envoie `amount` au Renderer via IPC.
3. BurstManager planifie l'instanciation de `amount / coinValue` pièces sur 5-10 secondes.

**Implementation Example:**
```typescript
class BurstManager {
  spawnBurst(totalCoins: number) {
    const coinsPerFrame = Math.max(1, totalCoins / 60); // Lisse sur 1sec
    const spawn = () => {
      for(let i=0; i<coinsPerFrame; i++) {
        physics.addCoin();
      }
      if(remaining > 0) requestAnimationFrame(spawn);
    };
    spawn();
  }
}
```

### Communication Patterns

**Pattern:** Decoupled Events via Zustand.
Toute interaction majeure émet un événement dans le store auquel les autres systèmes s'abonnent (ex: `onCoinImpact` -> `audio.play`).

### Entity Patterns

**Creation:** Factory Pattern.
Utilisation de `PieceFactory` et `BakeryItemFactory` pour centraliser la configuration des corps Matter.js (masse, friction, restitution).

### Consistency Rules

| Pattern | Convention | Enforcement |
| :--- | :--- | :--- |
| **Naming** | PascalCase (Components), camelCase (Logic) | ESLint |
| **Files** | kebab-case filenames | Project structure |
| **Icons** | SVG only | Asset strategy |
| **State** | Immutable updates only | Zustand practices |

---

## Cross-cutting Concerns

Ces patterns s'appliquent à TOUS les systèmes et doivent être respectés par chaque implémentation pour garantir la cohérence des agents AI.

### Error Handling

**Strategy:** Silent Recovery & Local Logging.
L'immersion ne doit jamais être coupée par une erreur technique. Les erreurs sont capturées, logguées, et l'app tente une récupération silencieuse.

**Example:**
```typescript
try {
  await salaryEngine.increment();
} catch (error) {
  logger.error('Salary increment failed', { error });
  // Recovery: use last known delta
}
```

### Logging

**Format:** Structured JSON via `electron-log`.
**Destination:** Fichier local `app.log` et console en développement.

**Log Levels:**
- `ERROR`: Blocage fonctionnel (ex: échec écriture sauvegarde).
- `WARN`: Incident récupéré (ex: flux radio interrompu).
- `INFO`: Jalons de l'utilisateur (ex: début Pomodoro).
- `DEBUG`: Traces techniques détaillées.

### Event System

**Pattern:** Event Bus via Zustand.
Le store Zustand sert de dispatcher central pour coordonner les systèmes découplés (Physics, Audio, UI).

**Example:**
```typescript
// Emission d'un événement via le store
useGameStore.getState().emit('COIN_DROPPED', { value: 0.01 });

// Souscription dans le système Audio
useGameStore.getState().on('COIN_DROPPED', (data) => {
  audioEngine.play('clink_soft');
});
```

### Debug & Development Tools

**Panneau Secret (`Ctrl+Maj+D`) :**
- **Physics Tweak** : Sliders pour ajuster la friction et la gravité Matter.js.
- **Cheat Box** : Bouton "+10€" et "Skip Pomodoro" (dev uniquement).
- **Log Viewer** : Affichage en temps réel des dernières erreurs.

---

## Architectural Decisions

### Decision Summary

| Category | Decision | Version | Rationale |
| :--- | :--- | :--- | :--- |
| **State Management** | **Zustand** | v5.x | Léger, sans boilerplate, idéal pour synchroniser le Main/Renderer (IPC). |
| **Persistence** | **electron-store** | v8.x | Stockage JSON simple, persistant et performant pour Electron. |
| **Physics Engine** | **Matter.js** | v0.20.x | Support robuste des contraintes pour l'effet "Coussin". |
| **Audio Routing** | **Howler.js** | v2.2.x | Gestion multi-canaux (Radio vs ASMR) et spatialisation simple. |

### State Management

**Approach:** Centralized Store with Zustand.
Le salaire (Main Process) met à jour le store via IPC. Le Renderer (UI) s'abonne aux changements pour mettre à jour le bocal et le compteur en temps réel.

### Data Persistence

**Save System:** local JSON via `electron-store`.
Toutes les données (Salaire accumulé, Inventaire, Recettes, Notes) sont stockées localement. Aucune dépendance externe pour garantir le mode "Zero-Sync" et la confidentialité.

### Physics (The Cushion Effect)

**Implementation Strategy:**
- **Soft-Body Simulation** : Utilisation de `Matter.Constraint` (ressorts) pour lier les points des pièces de monnaie, permettant une déformation visuelle satisfaisante à l'impact.
- **Damping** : Friction de l'air élevée pour éviter les rebonds métalliques et renforcer l'aspect feutré.

### Audio Architecture

**Mixing Groups:**
1. **Radio Channel** : Stream HLS avec filtre audio (BiquadFilter) pour simuler la friture.
2. **Tactile Channel** : Sons de papier, clics et ronrons (Howler instances dédiées).
3. **World Channel** : Collisions des pièces (Triggered by Matter.js events).

---

## Engine & Framework

### Selected Engine

**Electron v39.2.x** with **React 19** and **Vite 7**.

**Rationale:** `electron-vite` a été choisi pour sa vitesse de développement (HMR sur le Main process), ses optimisations natives pour les assets (WebP/SVG), et sa structure robuste facilitant les transitions ultra-rapides (< 0.5s) via Ghost-Loading.

### Project Initialization

```bash
# Commande recommandée pour initialiser le projet proprement
npm create @quick-start/electron@latest ./ -- --template react-ts
```

### Engine-Provided Architecture

| Component | Solution | Notes |
| :--- | :--- | :--- |
| **Rendering** | React 19 | Virtual DOM performant pour le Hub. |
| **Build System** | Vite 7 | Bundling rapide et optimisé pour le dev. |
| **IPC Bridge** | Electron ContextBridge | Communication sécurisée entre Main et Renderer. |
| **Process Management** | Main/Renderer/Preload | Structure multi-processus standard d'Electron. |
| **Developer Experience** | HMR / Fast Refresh | Mise à jour instantanée du code Main et UI. |

### Remaining Architectural Decisions

Les décisions suivantes doivent encore être définies explicitement au cours des prochaines étapes :

- **Persistence** : Stockage local (Electron-store ou SQLite).
- **Physics** : Implémentation fine de Matter.js pour l'effet "Coussin".
- **Audio Routing** : Gestion des instances Howler.js pour le mixage Radio vs ASMR.
- **State Management** : Gestion du salaire global vs État local du HUB (Zustand ?).

---

## Project Context

### Game Overview

**MoneyMaker** - Un compagnon de bureau apaisant qui transforme le salaire réel en temps réel en une échoppe de pâtisserie cozy habitée par Chips le chat.

### Technical Scope

**Platform:** Windows (Electron/React/Vite) + Android (Widget indépendant)
**Genre:** Idle / Incremental / Productivity Tool
**Project Level:** 3 (Complexité élevée sur le game feel et la performance background)

### Core Systems

| System | Complexity | GDD Reference |
| :--- | :--- | :--- |
| **Salary Engine** | Medium | Precision 1:1, Background persistence |
| **Physics Hub (Matter.js)** | High | Soft-body pieces, satisfying tactile piles |
| **Diegetic UI (Livre)** | Medium | Bookmark navigation, overlay seamless |
| **Atmosphere (Howler.js)** | Medium | Audio streaming HLS, Weather/Season sync |
| **Transition Controller** | High | 0.5s Blur, Ghost-Loading prefetch |

### Technical Requirements

- **Performance** : 60 FPS constants pour la physique d'accumulation.
- **Réactivité** : < 0.5s pour l'ouverture du Hub.
- **Légèreté** : Build final < 100 Mo (fondamental pour un outil de productivité).
- **Zéro-Sync** : Dépendance locale uniquement (confidentialité totale).

### Complexity Drivers

- **Physique de Coussin** : Gérer des centaines d'objets avec Matter.js tout en gardant Electron réactif.
- **Ghost-Loading** : Stratégie de pré-chargement invisible au survol pour garantir la fluidité instantanée.

### Technical Risks

- **Background Throttling** : Windows/Electron peuvent suspendre le calcul de salaire si l'app est trop discrète.
- **Audio Stream Stability** : Dépendance aux flux radio externes.
