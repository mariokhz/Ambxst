#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float phase;
    float amplitude;
    float frequency;
    vec4 shaderColor;
    float lineWidth;
    float canvasWidth;
    float canvasHeight;
    float fullLength;
} ubuf;

#define PI 3.14159265359

// Función de antialiasing suave
float smoothCoverage(float dist, float radius) {
    float aaWidth = 1.5;
    float edgeStart = radius - aaWidth;
    float edgeEnd = radius + aaWidth;
    return 1.0 - smoothstep(edgeStart, edgeEnd, dist);
}

// Calcula Y de la onda en una posición X
float waveY(float x, float centerY) {
    float k = ubuf.frequency * 2.0 * PI / ubuf.fullLength;
    return centerY + ubuf.amplitude * sin(k * x + ubuf.phase);
}

// Calcula el factor de reducción del grosor en los extremos usando círculo unitario
float edgeTaper(float x) {
    float startX = 0.0;
    float endX = ubuf.canvasWidth;
    float taperDistance = ubuf.lineWidth * 0.5; // Distancia del fade
    
    // Fade en el extremo izquierdo
    if (x < startX + taperDistance) {
        float t = (x - startX) / taperDistance; // Normalizar a [0, 1]
        // Usar función de círculo: y = sqrt(1 - (1-x)^2)
        float u = 1.0 - t;
        return sqrt(1.0 - u * u);
    }
    
    // Fade en el extremo derecho
    if (x > endX - taperDistance) {
        float t = (endX - x) / taperDistance; // Normalizar a [0, 1]
        // Usar función de círculo: y = sqrt(1 - (1-x)^2)
        float u = 1.0 - t;
        return sqrt(1.0 - u * u);
    }
    
    return 1.0;
}

// Distancia a la onda
float distanceToWave(vec2 pos, float centerY) {
    float startX = 0.0;
    float endX = ubuf.canvasWidth;
    
    // Buscar el punto más cercano en la curva
    float minDist = 99999.0;
    float searchStart = max(startX, pos.x - ubuf.fullLength / ubuf.frequency);
    float searchEnd = min(endX, pos.x + ubuf.fullLength / ubuf.frequency);
    
    float steps = 30.0;
    float stepSize = (searchEnd - searchStart) / steps;
    
    for (float i = 0.0; i <= steps; i += 1.0) {
        float testX = searchStart + i * stepSize;
        if (testX >= startX && testX <= endX) {
            vec2 curvePoint = vec2(testX, waveY(testX, centerY));
            float dist = distance(pos, curvePoint);
            minDist = min(minDist, dist);
        }
    }
    
    return minDist;
}

void main() {
    vec2 pixelPos = qt_TexCoord0 * vec2(ubuf.canvasWidth, ubuf.canvasHeight);
    float centerY = ubuf.canvasHeight * 0.5;
    float baseRadius = ubuf.lineWidth * 0.5;
    
    // Supersampling 5x5
    float alpha = 0.0;
    float samples = 0.0;
    float offset = 0.4;
    
    for (float dy = -2.0 * offset; dy <= 2.0 * offset; dy += offset) {
        for (float dx = -2.0 * offset; dx <= 2.0 * offset; dx += offset) {
            vec2 samplePos = pixelPos + vec2(dx, dy);
            float dist = distanceToWave(samplePos, centerY);
            
            // Aplicar reducción de grosor en los extremos
            float taper = edgeTaper(samplePos.x);
            float effectiveRadius = baseRadius * taper;
            
            alpha += smoothCoverage(dist, effectiveRadius);
            samples += 1.0;
        }
    }
    
    alpha /= samples;
    
    if (alpha < 0.01) {
        discard;
    }
    
    fragColor = vec4(ubuf.shaderColor.rgb, ubuf.shaderColor.a * alpha * ubuf.qt_Opacity);
}
