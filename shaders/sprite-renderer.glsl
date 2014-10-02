#ifdef GL_ES
precision lowp float;
#endif

#define MAX_SPRITES 16

struct Sprite {
  vec2 pos;
  vec2 size;
  vec2 uv;
};

uniform vec2 resolution;

uniform sampler2D atlas;
uniform sampler2D overlay;

uniform vec2 displayAspect;
uniform vec2 atlasAspect;

uniform Sprite sprites[MAX_SPRITES];
uniform int spritesLength;

void main() {
  vec2 scale = resolution / displayAspect;

  vec2 p = vec2(gl_FragCoord.x, resolution.y - gl_FragCoord.y) / scale;
  vec2 uv = gl_FragCoord.xy / resolution.xy;

  vec4 bg = vec4(1.0);
  vec4 color = vec4(0.0);

  for (int i = 0; i < MAX_SPRITES; ++i) {
    if (i >= spritesLength) break;

    Sprite sprite = sprites[i];
    if (!all(lessThanEqual(sprite.pos, p))) continue;
    if (!all(greaterThan(sprite.pos + sprite.size, p))) continue;

    vec2 sampleUV = (floor(sprite.uv + p - sprite.pos) + vec2(0.5)) / atlasAspect;
    color = texture2D(atlas, vec2(sampleUV.x, 1.0 - sampleUV.y));
  }

  gl_FragColor = vec4(mix(bg.rgb, color.rgb, color.a) * texture2D(overlay, uv).rgb, 1.0);
}
