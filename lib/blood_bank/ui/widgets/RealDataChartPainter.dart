import 'dart:math';
import 'package:flutter/material.dart';
import '../../../apps/config/theme/ColorPages.dart';

class RealDataChartPainter extends CustomPainter {
  final List<num> collectedValues;
  final List<num> distributedValues;
  final List<String> dateLabels;
  
  RealDataChartPainter({
    required this.collectedValues,
    required this.distributedValues,
    required this.dateLabels,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (collectedValues.isEmpty || distributedValues.isEmpty) {
      // No data to display
      return;
    }
    
    final width = size.width;
    final height = size.height;
    
    // Calculate scaling factors
    final allValues = [...collectedValues, ...distributedValues];
    final rawMax = allValues.isEmpty ? 0 : allValues.reduce((max, value) => max > value ? max : value);
    final maxValue = (rawMax == 0 ? 100 : rawMax) * 1.2;
    final xStep = width / (collectedValues.length - 1 > 0 ? collectedValues.length - 1 : 1);
    final yScale = height / maxValue;
    
    // Draw axes
    final axesPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    
    // Draw X axis
    canvas.drawLine(
      Offset(0, height),
      Offset(width, height),
      axesPaint,
    );
    
    // Draw dashed horizontal lines for Y-axis reference
    final dashPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;
    
    for (int i = 1; i <= 4; i++) {
      final y = height - (i * height / 4);
      drawDashedLine(canvas, Offset(0, y), Offset(width, y), dashPaint);
    }
    
    // Draw collection line (primary color)
    if (collectedValues.length > 1) {
      final collectionPaint = Paint()
        ..color = ColorPages.COLOR_PRINCIPAL
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      
      final collectionPath = Path();
      for (int i = 0; i < collectedValues.length; i++) {
        final x = i * xStep;
        final y = height - (collectedValues[i].toDouble() * yScale);
        
        if (i == 0) {
          collectionPath.moveTo(x, y);
        } else {
          collectionPath.lineTo(x, y);
        }
      }
      canvas.drawPath(collectionPath, collectionPaint);
      
      // Draw data points on collection line
      final pointPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      
      final pointStrokePaint = Paint()
        ..color = ColorPages.COLOR_PRINCIPAL
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      for (int i = 0; i < collectedValues.length; i++) {
        final x = i * xStep;
        final y = height - (collectedValues[i].toDouble() * yScale);
        
        // Only draw points for every second data point to avoid clutter
        if (i % 2 == 0) {
          canvas.drawCircle(Offset(x, y), 4, pointStrokePaint);
          canvas.drawCircle(Offset(x, y), 3, pointPaint);
        }
      }
    }
    
    // Draw distribution line (orange)
    if (distributedValues.length > 1) {
      final distributionPaint = Paint()
        ..color = Colors.orange
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      
      final distributionPath = Path();
      for (int i = 0; i < distributedValues.length; i++) {
        final x = i * xStep;
        final y = height - (distributedValues[i].toDouble() * yScale);
        
        if (i == 0) {
          distributionPath.moveTo(x, y);
        } else {
          distributionPath.lineTo(x, y);
        }
      }
      canvas.drawPath(distributionPath, distributionPaint);
      
      // Draw data points on distribution line
      final pointPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
        
      final distPointStrokePaint = Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      for (int i = 0; i < distributedValues.length; i++) {
        final x = i * xStep;
        final y = height - (distributedValues[i].toDouble() * yScale);
        
        // Only draw points for every second data point to avoid clutter
        if (i % 2 == 0) {
          canvas.drawCircle(Offset(x, y), 4, distPointStrokePaint);
          canvas.drawCircle(Offset(x, y), 3, pointPaint);
        }
      }
    }
  }

  void drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final dashWidth = 5;
    final dashSpace = 5;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final count = sqrt(dx * dx + dy * dy) / (dashWidth + dashSpace);
    final x = dx / count;
    final y = dy / count;
    
    Offset p = start;
    for (int i = 0; i < count; i++) {
      canvas.drawLine(p, Offset(p.dx + x * dashWidth / (dashWidth + dashSpace), p.dy + y * dashWidth / (dashWidth + dashSpace)), paint);
      p = Offset(p.dx + x, p.dy + y);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}