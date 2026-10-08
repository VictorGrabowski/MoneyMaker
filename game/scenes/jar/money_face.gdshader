// Face provisoire d'une pièce ou d'un billet, façon encre et aquarelle.
// Sert de bouche-trou tant que les illustrations définitives ne sont pas là.
shader_type canvas_item;

uniform vec4 fill_color : source_color = vec4(0.88, 0.69, 0.29, 1.0);
uniform vec4 ring_color : source_color = vec4(0.88, 0.69, 0.29, 1.0);
// Largeur de la couronne des pièces bicolores, en fraction du rayon. 0 = pièce unie.
uniform float ring_width = 0.0;
uniform vec4 ink_color : source_color = vec4(0.227, 0.149, 0.094, 1.0);
uniform float seed = 0.0;
uniform bool is_bill = false;
// Largeur / hauteur du billet.
uniform float aspect = 1.0;

// Rayon (ou demi-hauteur) du dessin dans sa texture. Doit rester égal à FACE_FILL dans jar_view.gd.
const float FACE_FILL = 0.93;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		value += amplitude * value_noise(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

// Distance signée au bord : négative à l'intérieur.
float shape(vec2 p) {
	if (is_bill) {
		float radius = 0.10;
		vec2 q = abs(p) - vec2(aspect, 1.0) * FACE_FILL + radius;
		return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
	}
	return length(p) - FACE_FILL;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	if (is_bill) {
		p.x *= aspect;
	}
	// Bord tremblé, comme un trait à main levée.
	float wobble = (fbm(p * 2.5 + seed) - 0.5) * 0.045;
	float d = shape(p) + wobble;
	float aa = max(fwidth(d), 0.004);
	float inside = 1.0 - smoothstep(-aa, aa, d);

	vec3 color = fill_color.rgb;
	if (!is_bill && ring_width > 0.0) {
		float ring_edge = -ring_width * FACE_FILL;
		color = mix(fill_color.rgb, ring_color.rgb, smoothstep(ring_edge - 0.015, ring_edge + 0.015, d));
	}

	// Lavis : pigment inégal, auréoles claires, pigment accumulé près du bord, grain du papier.
	color *= mix(0.80, 1.10, fbm(p * 2.0 + seed * 3.1));
	float bloom = smoothstep(0.55, 0.85, fbm(p * 1.2 - seed * 1.7));
	color = mix(color, vec3(1.0, 0.98, 0.93), bloom * 0.22);
	color *= mix(1.0, 0.86, smoothstep(-0.30, -0.05, d));
	color *= 0.97 + 0.06 * hash(floor(UV * 220.0) + seed);

	// Trait d'encre d'épaisseur variable, et filet intérieur.
	// Le trait est épais : une pièce ne fait qu'une cinquantaine de pixels à l'écran.
	float ink_width = 0.085 + 0.04 * fbm(p * 6.0 + seed * 7.0);
	float ink = smoothstep(-ink_width - aa, -ink_width + aa, d);
	float inner_at = is_bill ? -0.28 : -0.26;
	float inner = 1.0 - smoothstep(0.014, 0.014 + aa * 2.0, abs(d - inner_at));
	color = mix(color, ink_color.rgb, max(ink * 0.94, inner * 0.50));

	COLOR = vec4(color, inside);
}
