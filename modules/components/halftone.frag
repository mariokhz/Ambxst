#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float angle;
    float dotMinSize;
    float dotMaxSize;
    float gradientStart;
    float gradientEnd;
    vec4 dotColor;
    vec4 backgroundColor;
    float canvasWidth;
    float canvasHeight;
    float dotSpread;
} ubuf;

#define PI 3.14159265359

void main() {
    vec2 pixelPos = qt_TexCoord0 * vec2(ubuf.canvasWidth, ubuf.canvasHeight);
    
    float angleRad = radians(ubuf.angle);
    
    // Tamaño de celda basado en spread
    float cellSize = ubuf.dotMaxSize * ubuf.dotSpread;
    
    // Matriz de rotación
    mat2 rotation = mat2(
        cos(angleRad), -sin(angleRad),
        sin(angleRad), cos(angleRad)
    );
    
    vec2 center = vec2(ubuf.canvasWidth * 0.5, ubuf.canvasHeight * 0.5);
    
    // Rotar posición para la grilla
    vec2 rotatedPos = rotation * (pixelPos - center);
    
    // Grid y celda
    vec2 gridPos = rotatedPos / cellSize;
    vec2 cellIndex = floor(gridPos);
    vec2 cellCenter = (cellIndex + 0.5) * cellSize;
    vec2 posInCell = rotatedPos - cellCenter;
    
    float distToCenter = length(posInCell);
    
    // Calcular posición del gradiente
    // El gradiente debe rotar con el ángulo
    // angle=0 -> vertical (arriba a abajo), angle=90 -> horizontal (izq a der)
    // Vector del gradiente perpendicular al ángulo
    vec2 gradientDir = vec2(sin(angleRad), cos(angleRad));
    
    // Proyectar el pixel en la dirección del gradiente
    vec2 relativePos = pixelPos - center;
    float projection = dot(relativePos, gradientDir);
    
    // Calcular el rango de proyección proyectando las esquinas del canvas
    vec2 corners[4];
    corners[0] = vec2(0.0, 0.0) - center;
    corners[1] = vec2(ubuf.canvasWidth, 0.0) - center;
    corners[2] = vec2(0.0, ubuf.canvasHeight) - center;
    corners[3] = vec2(ubuf.canvasWidth, ubuf.canvasHeight) - center;
    
    float minProj = dot(corners[0], gradientDir);
    float maxProj = minProj;
    for (int i = 1; i < 4; i++) {
        float proj = dot(corners[i], gradientDir);
        minProj = min(minProj, proj);
        maxProj = max(maxProj, proj);
    }
    
    // Normalizar: 0 = inicio del canvas, 1 = final del canvas
    float gradientPos = (projection - minProj) / (maxProj - minProj);
    
    // Aplicar start y end
    float adjustedPos = (gradientPos - ubuf.gradientStart) / (ubuf.gradientEnd - ubuf.gradientStart);
    adjustedPos = clamp(adjustedPos, 0.0, 1.0);
    
    // Interpolar tamaño del dot: start = max, end = min
    float dotRadius = mix(ubuf.dotMaxSize, ubuf.dotMinSize, adjustedPos);
    
    // Bordes sólidos sin antialiasing
    float alpha = step(distToCenter, dotRadius);
    
    // Mezclar colores
    vec4 finalColor = mix(ubuf.backgroundColor, ubuf.dotColor, alpha);
    
    fragColor = vec4(finalColor.rgb, finalColor.a * ubuf.qt_Opacity);
}

