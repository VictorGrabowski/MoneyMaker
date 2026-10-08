## Versions du fichier de sauvegarde.
## Quand son format change : augmenter CURRENT_VERSION, ajouter ici la fonction qui fait passer
## de l'ancienne version à la nouvelle, et un fichier d'exemple de l'ancienne version dans les tests.
extends RefCounted

const CURRENT_VERSION := 1


## Vrai pour une sauvegarde que cette version du jeu sait lire.
## Une sauvegarde plus récente que le jeu est refusée : mieux vaut la mettre de côté que l'abîmer.
static func is_loadable(data: Dictionary) -> bool:
	var version: Variant = data.get("version")
	if typeof(version) != TYPE_INT and typeof(version) != TYPE_FLOAT:
		return false
	return int(version) >= 1 and int(version) <= CURRENT_VERSION


## Amène une sauvegarde lisible à la version courante.
static func migrate(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	var version := int(migrated.get("version", CURRENT_VERSION))
	while version < CURRENT_VERSION:
		# Une étape par version, par exemple :
		#     if version == 1:
		#         migrated = _from_1_to_2(migrated)
		version += 1
	migrated["version"] = CURRENT_VERSION
	return migrated
