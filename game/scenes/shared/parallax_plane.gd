## Un plan du décor. Les plans défilent à des vitesses différentes quand on balaie le lieu ou
## qu'on bouge la souris : c'est ce qui donne sa profondeur à un décor plat.
extends Node2D

## 1 : suit le décor. Moins de 1 : plus loin, défile moins. Plus de 1 : plus près, défile plus.
var scroll_factor := 1.0
## Décalage maximal dû à la souris, en pixels.
var mouse_shift := 0.0


## `pan` : défilement du lieu, en pixels. `mouse` : écart de la souris au centre de l'écran, de -1 à 1.
func place(pan: float, mouse: Vector2) -> void:
	var target := Vector2(-pan * scroll_factor - mouse.x * mouse_shift, -mouse.y * mouse_shift * 0.5)
	# Rien n'est déplacé pour un écart imperceptible : un décor immobile n'est pas redessiné.
	if position.distance_to(target) > 0.05:
		position = target
