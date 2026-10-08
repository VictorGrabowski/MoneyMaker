# MoneyMaker — le jeu (Godot 4.7)

Refonte de MoneyMaker en jeu. La conception est dans `../_bmad-output/` :
GDD et epics dans `planning-artifacts/gdds/`, architecture dans `game-architecture.md`,
direction artistique et prompts dans `planning-artifacts/art-direction.md`.

## Lancer

```powershell
& "D:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" --path game
```

Ajouter `--editor` pour ouvrir le projet dans l'éditeur.

| Touche | Effet |
|---|---|
| Glisser | Attraper et lancer une pièce |
| Espace | Secouer le bocal |
| P | Fiche de paie (provisoire) |
| W | Basculer en widget ; double-clic ou Échap pour revenir |
| F | Images par seconde |

Au premier lancement, le jeu reprend le salaire et les horaires de l'application v1 s'il les trouve
(`%APPDATA%\money-maker\config.json`) ; sinon la fiche de paie s'ouvre.

La sauvegarde est dans `%APPDATA%\Godot\app_userdata\MoneyMaker\save\`.

## Tester

```powershell
.\game\tools\godot.ps1 -Tests
```

Le script lit le chemin de Godot dans la variable d'environnement `GODOT`, sinon prend l'installation
Steam ci-dessus. Il impose un délai : hors écran, Godot ne se ferme pas si un script plante.

Une suite est un fichier `tests/unit/test_*.gd` ; chaque méthode `test_*` est un test.

## Essayer sans toucher à sa sauvegarde

Les arguments se placent après `--`.

| Argument | Effet |
|---|---|
| `--fill=9231` | Démonstration : 92,31 € dans le bocal, sauvegarde ni lue ni écrite |
| `--bench=240` | Démonstration : 240 objets, mesure des images par seconde |
| `--profile=essai` | Sauvegarde à part, dans `save_essai` |
| `--now=2026-10-05T12:00:00` | Fait comme s'il était cette heure-là |
| `--net=200000` | Règle le net mensuel (en centimes) si rien n'est réglé |
| `--widget` | Démarre en widget |
| `--shot=C:\tmp\vue.png` | Enregistre une capture et un rapport, puis quitte |

`--profile`, `--now` et `--net` n'existent que dans la version de développement.

## Organisation

| Dossier | Contenu |
|---|---|
| `core/` | Règles du jeu, sans aucun nœud Godot : testables hors écran |
| `services/` | Services globaux : `Events`, `Clock`, `Game` |
| `scenes/prototype/` | Écran de travail actuel : bocal 2.5D, ardoise, fiche de paie, widget |
| `tests/` | Lanceur maison et suites |
| `tools/` | `godot.ps1` |
