#!/usr/bin/env dart
// ignore_for_file: avoid_print
// Script de herramienta — no forma parte de la app.
// Genera el ícono PNG para flutter_launcher_icons.
// Ejecutar con: dart tool/generate_icon.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

Future<void> main() async {
  // Crear directorio si no existe
  final dir = Directory('assets/icon');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  // Generar ícono 1024x1024
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const size = 1024.0;

  // Fondo degradado azul oscuro
  final bgPaint = Paint()
    ..shader = const LinearGradient(
      colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(const Rect.fromLTWH(0, 0, size, size));

  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, size, size),
      const Radius.circular(200),
    ),
    bgPaint,
  );

  // Rayo ⚡ centrado
  final textPainter = TextPainter(
    text: const TextSpan(
      text: '⚡',
      style: TextStyle(fontSize: 580, color: Colors.white),
    ),
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset(
      (size - textPainter.width) / 2,
      (size - textPainter.height) / 2,
    ),
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();

  File('assets/icon/app_icon.png').writeAsBytesSync(bytes);
  File('assets/icon/app_icon_foreground.png').writeAsBytesSync(bytes);
  print('✅ Íconos generados en assets/icon/');
}
