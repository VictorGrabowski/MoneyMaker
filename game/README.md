# MoneyMaker — le jeu (Godot 4.7)

Refonte de MoneyMaker en jeu. La conception est dans `../_bmad-output/` :
GDD et epics dans `planning-artifacts/gdds/`, architecture dans `game-architecture.md`,
direction artistique et prompts dans `planning-artifacts/art-direction.md`.

## Lancer

```powershell
& "D:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --path game
```

Ajouter `--editor` pour ouvrir le projet dans l'éditeur.

Au premier lancement, le jeu reprend le salaire et les horaires de l'application v1 s'il les trouve
(`%APPDATA%\money-maker\config.json`) ; sinon la fiche de paie s'ouvre.

La sauvegarde est dans `%APPDATA%\Godot\app_userdata\MoneyMaker\save\`.

### À la maison

La maison fait deux écrans de large : le coin bureau à gauche, le comptoir au milieu, la cuisine à
droite. Son décor est provisoire, dessiné par le code en attendant les illustrations. Sa lumière suit
l'heure et le soleil ; sa météo, celle de la ville réglée sur le baromètre.

| Geste | Effet |
|---|---|
| Souris vers un bord de l'écran, Q / D ou flèches | Balayer la maison |
| Clic sur un objet | L'ouvrir en gros plan |
| Échap, clic droit, ou clic hors de l'objet | Refermer le gros plan |
| W, ou Ctrl+Maj+M | Passer en widget |
| Ctrl+Maj+H | Mode discret : les montants sont masqués |
| M | Couper ou remettre le son |

| Objet | Où | Ce qu'on y fait |
|---|---|---|
| Fiche de paie | Sur le bureau | Net mensuel, horaires, jours travaillés, pointage à la main |
| Petit cadre | Sur le bureau | Choisir le format du widget, y passer |
| Chevalet | Sur le bureau | Dit « Au travail » ou « Au repos » ; se clique pour pointer, si l'on pointe soi-même |
| Calendrier | Au mur du bureau | Ce que chaque jour a rapporté ; marquer un congé, un férié, un jour sans solde |
| Baromètre | Au mur du bureau | La ville, pour la météo réelle, ou un temps choisi |
| Caisse | Sur le comptoir | Le ticket du soir |
| Bocal | Sur le comptoir | Un clic l'ouvre en gros plan ; le faire glisser le secoue sur place |

### Jouer avec le bocal, en gros plan

| Geste | Effet |
|---|---|
| Glisser une pièce | L'attraper, la lancer |
| Glisser une pièce sur une semblable | Elles fusionnent en une plus grosse, qui reste dans la main : on peut enchaîner jusqu'aux billets. À trois (2 € + 2 € + 1 €), la troisième vient d'elle-même |
| Glisser le bocal par le verre, ou par un vide | Le secouer (le curseur change au-dessus du verre) |
| Clic dans un vide | Tapoter la vitre |
| Espace | Secouer d'un coup |

Une pièce tombée dehors retourne d'elle-même dans le bocal, tant qu'il n'est pas plein. Le bocal ne
recasse jamais ce qu'on a fusionné : il compte seulement moins de pièces, et les centimes suivants
tombent sans fusionner jusqu'à ce qu'il ait retrouvé son niveau.

### En widget

| Geste | Effet |
|---|---|
| Glisser | Déplacer le widget (sa place est retenue) ; en mini-bocal, le contenu du bocal s'en ressent |
| Glisser une pièce du mini-bocal | L'attraper, la fusionner, comme en gros plan |
| Clic droit | Format suivant : pastille, bandeau, mini-bocal |
| Molette | Plus ou moins opaque |
| Double-clic, Échap ou W | Revenir à la maison |

Un clic sur l'icône de la zone de notification bascule aussi entre maison et widget.

En pastille et en bandeau, le bocal est en pause : ce qui est gagné tombe au retour à la maison.

## Remplacer une face provisoire par une illustration

Déposer l'image dans `game/assets/art/money/`, sous le nom attendu : `coin_100_face.png` (pièce de
1 €, valeur en centimes), `bill_20_face.png` (billet de 20 €, valeur en euros), `ingot_face.png`,
`gem_face.png`. PNG ou WebP, sur fond blanc, la coupure occupant environ 92 % de l'image.
Elle est prise en compte au lancement suivant ; le détourage est fait par le jeu.

## Tester

```powershell
.\game\tools\godot.ps1 -Tests
```

Le script lit le chemin de Godot dans la variable d'environnement `GODOT`, sinon prend l'installation
Steam ci-dessus. Il impose un délai : hors écran, Godot ne se ferme pas si un script plante.

Une suite est un fichier `tests/unit/test_*.gd` ; chaque méthode `test_*` est un test.

## Essayer sans toucher à sa sauvegarde

Les arguments se placent après `--`. `--profile` range tout dans une sauvegarde à part, sans reprise
des réglages de la v1 :

```powershell
.\game\tools\godot.ps1 -GodotArgs '--', '--profile=essai', '--net=200000', '--now=2026-10-08T22:30:00', '--weather=neige', '--season=hiver'
```

| Argument | Effet |
|---|---|
| `--profile=essai` | Sauvegarde à part, dans `save_essai` |
| `--now=2026-10-05T12:00:00` | Fait comme s'il était cette heure-là (la lumière suit) |
| `--net=200000` | Règle le net mensuel (en centimes) si rien n'est réglé |
| `--jar=bocal` | Change de bocal : `pot`, `bocal` ou `bonbonne` |
| `--weather=pluie` | Impose la météo : `clair`, `nuageux`, `pluie`, `neige`, `brouillard` |
| `--season=hiver` | Impose la saison : `printemps`, `ete`, `automne`, `hiver` |
| `--city=Paris,48.9,2.3` | Règle la ville (nom, latitude, longitude) : un relevé météo réel part aussitôt |
| `--mark=2026-10-16:conge` | Marque un jour : `conge`, `ferie`, `sans_solde` |
| `--manual` ou `--manual=pointe` | Passe au pointage manuel (et pointe l'arrivée) |
| `--widget=mini_bocal` | Démarre en widget : `pastille`, `bandeau` ou `mini_bocal` |
| `--discreet` | Active le mode discret |
| `--pan=0.5` | Position du balayage, de 0 (extrême gauche) à 1 (extrême droite) |
| `--closeup=calendrier` | Ouvre un gros plan : `fiche_de_paie`, `calendrier`, `barometre`, `caisse`, `cadre_du_widget`, `bocal` |
| `--shot=C:\tmp\vue.png` | Enregistre une capture et un rapport, puis quitte (`--shot-delay=8` pour attendre 8 s) |
| `--tour` | Avec `--shot` : ouvre et referme chaque gros plan, passe par le mini-bocal, revient |
| `--gestures` | Avec `--shot` : joue les gestes à la souris avec de vrais événements (secouer le bocal, l'ouvrir d'un clic, fusionner des pièces, clic droit sur le mini-bocal) ; `--snaps=C:\tmp\geste` enregistre des captures en plein geste |
| `--watch=40` | Avec `--shot` : observe le bocal 40 s et rapporte la part du temps où il simule |
| `--mouse=0.8,-0.6` | Avec `--shot` : fait comme si la souris était là (de -1 à 1) |
| `--search=Lyon` | Avec `--shot` : cherche une ville auprès du service météo |
| `--fps=30` | Images par seconde au plus |

`--profile`, `--now`, `--net`, `--jar`, `--weather`, `--season`, `--city`, `--mark`, `--manual`,
`--discreet` et `--fps` n'existent que dans la version de développement.

Pour changer de forme de fenêtre, les arguments du moteur se placent avant `--` :
`-GodotArgs '--resolution', '1280x800', '--', '--profile=essai'`.

### Le banc d'essai du bocal

L'ancien écran de travail reste là pour essayer le bocal seul, sans sauvegarde :

```powershell
.\game\tools\godot.ps1 -GodotArgs 'res://scenes/workbench/workbench.tscn', '--', '--fill=9230'
```

| Argument | Effet |
|---|---|
| `--fill=9230` | 92,30 € dans le bocal, sauvegarde ni lue ni écrite |
| `--pour=8` | Avec `--fill` et `--shot` : verse ensuite 8 fois 5 € |
| `--bench=240` | 240 objets, mesure des images par seconde |
| `--exercise` | Avec `--shot` : secoue, passe par les trois formats, revient |

Il accepte aussi `--jar`, `--widget`, `--discreet`, `--profile`, `--now`, `--net` et `--shot`.

## Organisation

| Dossier | Contenu |
|---|---|
| `core/` | Règles du jeu, sans aucun nœud Godot : testables hors écran |
| `services/` | Services globaux : `Events`, `Clock`, `Game`, `WindowModes`, `Atmosphere` (lumière, météo, saison) |
| `scenes/home/` | La maison : la scène, sa mise en place (`home_layout.gd`), son décor et ses objets provisoires |
| `scenes/closeups/` | Les gros plans : fiche de paie, calendrier, ticket, baromètre, cadre du widget |
| `scenes/jar/` | Le bocal 2.5D, son verre, ses faces et ses sons |
| `scenes/widget/` | Le widget et ses trois formats |
| `scenes/shared/` | Ce qui sert à plusieurs lieux : les plans à parallaxe |
| `scenes/workbench/` | Banc d'essai du bocal (l'ancien écran de travail) |
| `tests/` | Lanceur maison et suites |
| `tools/` | `godot.ps1` |
