shader_type spatial;
// Prevent the quad from being affected by lighting and fog. This also improves performance.
render_mode unshaded, fog_disabled;

uniform sampler2D depth_texture : source_color, hint_depth_texture;

void vertex() {
  //POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
  float depth = texture(depth_texture, SCREEN_UV).x;
  vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
  vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
  view.xyz /= view.w;
  float linear_depth = -view.z;

  vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
  vec3 world_position = world.xyz / world.w;

  vec3 colour = vec3(fract(linear_depth));
  float power = 0.09;
  float mult = 1.0;

  colour.r = cos(4.0 * PI * pow(colour.r, power) * mult - PI) * 0.5 + 0.5;
  colour.g = cos(6.0 * PI * pow(colour.g, power) * mult - PI) * 0.5 + 0.5;
  colour.b = cos(8.0 * PI * pow(colour.b, power) * mult - PI) * 0.5 + 0.5;
  
  // Visualize linear depth
  //ALBEDO.rgb = vec3(fract(linear_depth));

  // Visualize world coordinates
  //ALBEDO.rgb = fract(world_position).xyz;
  
  ALBEDO.rgb = pow(colour * 1.1, vec3(2.0));

  ALBEDO.rgb;
}

