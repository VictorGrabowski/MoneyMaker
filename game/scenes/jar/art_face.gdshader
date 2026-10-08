// Face d'une coupure illustrée, plaquée sur son volume.
// Les illustrations arrivent sur fond blanc : la découpe est faite ici, par la forme
// (disque pour une pièce, rectangle arrondi pour un billet), pas par la transparence de l'image.
shader_type spatial;
render_mode cull_back, specular_disabled;

uniform sampler2D face : source_color, filter_linear_mipmap_anisotropic;
// Rayon (ou demi-hauteur) de la coupure dans son image, de 0 à 1.
uniform float fill = 0.90;
uniform bool is_bill = false;
// Largeur / hauteur du billet.
uniform float aspect = 2.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d;
	if (is_bill) {
		p.x *= aspect;
		float radius = 0.10;
		vec2 q = abs(p) - vec2(aspect, 1.0) * fill + radius;
		d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
	} else {
		d = length(p) - fill;
	}
	vec4 texel = texture(face, UV);
	ALBEDO = texel.rgb;
	ROUGHNESS = 1.0;
	ALPHA = texel.a * step(d, 0.0);
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
