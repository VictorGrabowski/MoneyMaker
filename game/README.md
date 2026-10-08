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

| Geste | Effet |
|---|---|
| Glisser une pièce | L'attraper, la lancer |
| Clic dans le vide | Tapoter la vitre |
| Espace | Secouer le bocal |
| P | Fiche de paie (provisoire) |
| W, ou Ctrl+Maj+M | Passer en widget |
| Ctrl+Maj+H | Mode discret : les montants sont masqués |
| M | Couper ou remettre le son |
| F | Images par seconde |

### En widget

| Geste | Effet |
|---|---|
| Glisser | Déplacer le widget (sa place est retenue) |
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

Les arguments se placent après `--`.

| Argument | Effet |
|---|---|
| `--fill=9230` | Démonstration : 92,30 € dans le bocal, sauvegarde ni lue ni écrite |
| `--pour=8` | Avec `--fill` et `--shot` : verse ensuite 8 fois 5 € |
| `--bench=240` | Démonstration : 240 objets, mesure des images par seconde |
| `--jar=bocal` | Change de bocal : `pot`, `bocal` ou `bonbonne` |
| `--widget=mini_bocal` | Démarre en widget : `pastille`, `bandeau` ou `mini_bocal` |
| `--discreet` | Active le mode discret |
| `--profile=essai` | Sauvegarde à part, dans `save_essai` |
| `--now=2026-10-05T12:00:00` | Fait comme s'il était cette heure-là |
| `--net=200000` | Règle le net mensuel (en centimes) si rien n'est réglé |
| `--shot=C:\tmp\vue.png` | Enregistre une capture et un rapport, puis quitte |
| `--exercise` | Avec `--shot` : secoue, passe par les trois formats, revient à la maison |

`--profile`, `--now`, `--net` et `--jar` (hors démonstration) n'existent que dans la version de
développement.

## Organisation

| Dossier | Contenu |
|---|---|
| `core/` | Règles du jeu, sans aucun nœud Godot : testables hors écran |
| `services/` | Services globaux : `Events`, `Clock`, `Game`, `WindowModes` |
| `scenes/jar/` | Le bocal 2.5D, son verre, ses faces et ses sons |
| `scenes/widget/` | Le widget et ses trois formats |
| `scenes/workbench/` | Écran de travail en attendant la maison : ardoise, fiche de paie |
| `tests/` | Lanceur maison et suites |
| `tools/` | `godot.ps1` |
