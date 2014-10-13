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

uniform float time;

void main() {
  vec2 scale = resolution / displayAspect;

  vec2 p = vec2(gl_FragCoord.x, resolution.y - gl_FragCoord.y) / scale;
  vec2 uv = gl_FragCoord.xy / resolution.xy;

  vec3 color = vec3(1.0);

  for (int i = 0; i < MAX_SPRITES; ++i) {
    if (i >= spritesLength) break;

    Sprite sprite = sprites[i];
    sprite.pos = floor(sprite.pos);
    if (
      all(lessThanEqual(sprite.pos, p)) &&
      all(greaterThan(sprite.pos + sprite.size, p))
    ) {
      vec2 sampleUV = (floor(sprite.uv + p - sprite.pos) + vec2(0.5)) / atlasAspect;
      vec4 spriteColor = texture2D(atlas, vec2(sampleUV.x, 1.0 - sampleUV.y));
      color = mix(color, spriteColor.rgb, spriteColor.a);
    }
  }

  gl_FragColor = vec4(color.rgb * texture2D(overlay, uv).rgb, 1.0);
}
