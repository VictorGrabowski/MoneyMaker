// Face d'une coupure illustrée, plaquée sur son volume.
// Les illustrations arrivent sur fond blanc, avec un bord tracé à la main : la découpe est faite ici.
// - au-delà de la forme (disque pour une pièce, rectangle arrondi pour un billet) : rien ;
// - dans la bande du bord : le blanc du fond est retiré, le trait de contour est gardé ;
// - à l'intérieur : tout est gardé, y compris les blancs du dessin.
shader_type spatial;
render_mode cull_back, specular_disabled;

uniform sampler2D face : source_color, filter_linear_mipmap_anisotropic;
// Rayon (ou demi-hauteur) de la coupure dans son image, de 0 à 1.
uniform float fill = 0.92;
uniform bool is_bill = false;
// Largeur / hauteur du billet.
uniform float aspect = 2.0;

// Marge laissée au-delà du bord nominal, pour un contour irrégulier.
const float OUTER_MARGIN = 0.04;
// Largeur de la bande du bord où le blanc est considéré comme du fond.
const float EDGE_BAND = 0.10;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d;  // distance signée au bord nominal : négative à l'intérieur
	if (is_bill) {
		p.x *= aspect;
		float radius = 0.10;
		vec2 q = abs(p) - vec2(aspect, 1.0) * fill + radius;
		d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
	} else {
		d = length(p) - fill;
	}
	vec4 texel = texture(face, UV);
	float whiteness = smoothstep(0.88, 0.96, min(texel.r, min(texel.g, texel.b)));
	float near_edge = smoothstep(-EDGE_BAND, -0.02, d);
	float keep = step(d, OUTER_MARGIN) * (1.0 - whiteness * near_edge);
	ALBEDO = texel.rgb;
	ROUGHNESS = 1.0;
	ALPHA = texel.a * keep;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
