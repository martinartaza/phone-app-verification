import 'dart:math';
import 'package:flutter/material.dart';

class PentagonChart extends StatelessWidget {
  final Map<String, double> skills;
  final double size;

  const PentagonChart({
    Key? key,
    required this.skills,
    this.size = 200,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: HexagonPainter(skills),
    );
  }
}

class HexagonPainter extends CustomPainter {
  final Map<String, double> skills;
  final List<String> skillOrder = ['velocidad', 'resistencia', 'tiro', 'gambeta', 'pases', 'defensa'];
  final List<String> skillLabels = ['Velocidad', 'Resistencia', 'Tiro a arco', 'Gambeta', 'Pases', 'Defensa'];

  HexagonPainter(this.skills);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;
    
    // Colores del tema
    final primaryColor = const Color(0xFF6366F1); // Indigo
    final backgroundColor = Colors.grey.shade200;

    // Dibujar líneas de fondo (hexágono base)
    _drawBackgroundHexagon(canvas, center, radius, backgroundColor);

    // Dibujar hexágono de habilidades
    _drawSkillsHexagon(canvas, center, radius, primaryColor);

    // Dibujar labels
    _drawLabels(canvas, center, radius * 1.2, Colors.grey.shade700);
  }

  void _drawBackgroundHexagon(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Dibujar 5 niveles del hexágono (20%, 40%, 60%, 80%, 100%)
    for (int level = 1; level <= 5; level++) {
      final levelRadius = radius * (level / 5);
      final path = _createHexagonPath(center, levelRadius);
      canvas.drawPath(path, paint);
    }

    // Dibujar líneas desde el centro a cada vértice
    for (int i = 0; i < 6; i++) {
      final angle = (i * 2 * pi / 6) - (pi / 2); // Empezar desde arriba
      final endPoint = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      canvas.drawLine(center, endPoint, paint);
    }
  }

  void _drawSkillsHexagon(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final path = Path();
    bool isFirst = true;

    for (int i = 0; i < 6; i++) {
      final skillName = skillOrder[i];
      final skillValue = skills[skillName] ?? 0;
      final normalizedValue = skillValue / 100; // Normalizar a 0-1
      
      final angle = (i * 2 * pi / 6) - (pi / 2); // Empezar desde arriba
      final skillRadius = radius * normalizedValue;
      
      final point = Offset(
        center.dx + skillRadius * cos(angle),
        center.dy + skillRadius * sin(angle),
      );

      if (isFirst) {
        path.moveTo(point.dx, point.dy);
        isFirst = false;
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    
    path.close();
    
    // Dibujar el área rellena
    canvas.drawPath(path, paint);
    
    // Dibujar el borde
    canvas.drawPath(path, strokePaint);

    // Dibujar puntos en cada vértice
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 6; i++) {
      final skillName = skillOrder[i];
      final skillValue = skills[skillName] ?? 0;
      final normalizedValue = skillValue / 100;
      
      final angle = (i * 2 * pi / 6) - (pi / 2);
      final skillRadius = radius * normalizedValue;
      
      final point = Offset(
        center.dx + skillRadius * cos(angle),
        center.dy + skillRadius * sin(angle),
      );

      canvas.drawCircle(point, 4, pointPaint);
    }
  }

  void _drawLabels(Canvas canvas, Offset center, double radius, Color textColor) {
    for (int i = 0; i < 6; i++) {
      final angle = (i * 2 * pi / 6) - (pi / 2);
      final labelPosition = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: skillLabels[i],
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      // Ajustar posición del texto para centrarlo
      final textOffset = Offset(
        labelPosition.dx - textPainter.width / 2,
        labelPosition.dy - textPainter.height / 2,
      );

      textPainter.paint(canvas, textOffset);
    }
  }

  Path _createHexagonPath(Offset center, double radius) {
    final path = Path();
    
    for (int i = 0; i < 6; i++) {
      final angle = (i * 2 * pi / 6) - (pi / 2);
      final point = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}