## Signaux transverses entre les lieux et les services.
## Liste fermée : un nouveau signal s'ajoute d'abord dans game-architecture.md.
extends Node

## Des centimes viennent d'être gagnés.
@warning_ignore("unused_signal")
signal cents_earned(cents: int)

## Le contenu du bocal a changé. `ops` : les opérations à jouer, dans l'ordre (voir core/money/jar.gd).
@warning_ignore("unused_signal")
signal jar_changed(ops: Array[Dictionary])

## Le salaire ou les horaires ont changé.
@warning_ignore("unused_signal")
signal settings_changed

## Une préférence d'affichage a changé (mode discret, widget, son).
@warning_ignore("unused_signal")
signal preferences_changed
