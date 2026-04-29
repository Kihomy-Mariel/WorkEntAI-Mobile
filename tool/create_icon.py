#!/usr/bin/env python3
"""
Genera el ícono de WorkEntAI como PNG usando solo la librería estándar de Python.
Ejecutar: python tool/create_icon.py
"""
import os
import struct
import zlib

def create_png(width, height, pixels):
    """Crea un PNG desde una lista de píxeles RGBA."""
    def chunk(name, data):
        c = name + data
        return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)
    
    # IHDR
    ihdr = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
    
    # IDAT - datos de imagen
    raw = b''
    for y in range(height):
        raw += b'\x00'  # filter type none
        for x in range(width):
            r, g, b = pixels[y][x]
            raw += bytes([r, g, b])
    
    compressed = zlib.compress(raw, 9)
    
    return (
        b'\x89PNG\r\n\x1a\n' +
        chunk(b'IHDR', ihdr) +
        chunk(b'IDAT', compressed) +
        chunk(b'IEND', b'')
    )

def lerp_color(c1, c2, t):
    """Interpolación lineal entre dos colores."""
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))

def draw_icon(size=1024):
    """Dibuja el ícono de WorkEntAI."""
    pixels = [[(0, 0, 0)] * size for _ in range(size)]
    
    # Colores del degradado
    color_top_left = (30, 58, 95)    # #1E3A5F
    color_bot_right = (37, 99, 235)  # #2563EB
    
    # Rayo ⚡ — coordenadas normalizadas (0-1)
    # Definir el rayo como polígono
    bolt_points = [
        (0.50, 0.18),  # punta superior
        (0.34, 0.50),  # izquierda media
        (0.47, 0.50),  # centro izquierda
        (0.38, 0.82),  # punta inferior izquierda
        (0.66, 0.46),  # derecha media
        (0.53, 0.46),  # centro derecha
    ]
    
    # Convertir a píxeles
    bolt_px = [(int(x * size), int(y * size)) for x, y in bolt_points]
    
    for y in range(size):
        for x in range(size):
            # Degradado de fondo
            t = (x + y) / (2 * size)
            bg = lerp_color(color_top_left, color_bot_right, t)
            
            # Verificar si el punto está dentro del rayo
            if point_in_polygon(x, y, bolt_px):
                pixels[y][x] = (255, 255, 255)  # blanco
            else:
                pixels[y][x] = bg
    
    return pixels

def point_in_polygon(x, y, polygon):
    """Ray casting algorithm para punto en polígono."""
    n = len(polygon)
    inside = False
    px, py = x, y
    j = n - 1
    for i in range(n):
        xi, yi = polygon[i]
        xj, yj = polygon[j]
        if ((yi > py) != (yj > py)) and (px < (xj - xi) * (py - yi) / (yj - yi) + xi):
            inside = not inside
        j = i
    return inside

def main():
    os.makedirs('assets/icon', exist_ok=True)
    
    print('Generando ícono 1024x1024...')
    size = 1024
    pixels = draw_icon(size)
    png_data = create_png(size, size, pixels)
    
    with open('assets/icon/app_icon.png', 'wb') as f:
        f.write(png_data)
    
    with open('assets/icon/app_icon_foreground.png', 'wb') as f:
        f.write(png_data)
    
    print('✅ Íconos generados:')
    print('   assets/icon/app_icon.png')
    print('   assets/icon/app_icon_foreground.png')
    print()
    print('Ahora ejecuta:')
    print('   dart run flutter_launcher_icons')

if __name__ == '__main__':
    main()
