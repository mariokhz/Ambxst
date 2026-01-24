#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(binding = 1) uniform sampler2D source;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 c1;
    vec4 c2;
    vec4 c3;
    vec4 c4;
    vec4 c5;
    vec4 c6;
} ubuf;

void main() {
    vec4 tex = texture(source, qt_TexCoord0);
    vec3 diff1 = tex.rgb - ubuf.c1.rgb;
    float d1 = dot(diff1, diff1);
    vec3 diff2 = tex.rgb - ubuf.c2.rgb;
    float d2 = dot(diff2, diff2);
    vec3 diff3 = tex.rgb - ubuf.c3.rgb;
    float d3 = dot(diff3, diff3);
    vec3 diff4 = tex.rgb - ubuf.c4.rgb;
    float d4 = dot(diff4, diff4);
    vec3 diff5 = tex.rgb - ubuf.c5.rgb;
    float d5 = dot(diff5, diff5);
    vec3 diff6 = tex.rgb - ubuf.c6.rgb;
    float d6 = dot(diff6, diff6);

    float minD = d1;
    vec3 res = ubuf.c1.rgb;
    if (d2 < minD) { minD = d2; res = ubuf.c2.rgb; }
    if (d3 < minD) { minD = d3; res = ubuf.c3.rgb; }
    if (d4 < minD) { minD = d4; res = ubuf.c4.rgb; }
    if (d5 < minD) { minD = d5; res = ubuf.c5.rgb; }
    if (d6 < minD) { minD = d6; res = ubuf.c6.rgb; }

    fragColor = vec4(res, tex.a) * ubuf.qt_Opacity;
}
