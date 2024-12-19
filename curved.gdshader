shader_type canvas_item;

// Corner radius (0.0 to 0.5)
uniform float corner_radius : hint_range(0.0, 0.5) = 0.1;
// Border width (0.0 to 0.5)
uniform float border_width : hint_range(0.0, 0.5) = 0.0;
// Border color
uniform vec4 border_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// Smoothness of the corner transition
uniform float smoothness : hint_range(0.0, 0.1) = 0.01;

float rounded_rect_mask(vec2 uv, float radius, float smooth_edges) {
    // Convert radius from 0-0.5 range to 0-1 range
    radius = min(radius, 0.5);

    // Calculate distances to edges
    vec2 center_dist = abs(uv - vec2(0.5));
    vec2 half_size = vec2(0.5);

    // Calculate corner mask
    vec2 corner_dist = max(center_dist - half_size + radius, vec2(0.0));
    float dist = length(corner_dist);

    // Apply smoothness
    return 1.0 - smoothstep(radius - smooth_edges, radius, dist);
}

void fragment() {
    // Get the texture color
    vec4 texture_color = texture(TEXTURE, UV);

    // Calculate the rounded rectangle mask
    float mask = rounded_rect_mask(UV, corner_radius, smoothness);

    // Calculate the border mask if border_width > 0
    float border_mask = 0.0;
    if (border_width > 0.0) {
        border_mask = rounded_rect_mask(UV, corner_radius, smoothness) -
                     rounded_rect_mask(UV, corner_radius - border_width, smoothness);
    }

    // Mix the texture color with border color based on masks
    vec4 final_color = mix(vec4(0.0), texture_color, mask);
    final_color = mix(final_color, border_color, border_mask);

    // Output the final color
    COLOR = final_color;
}