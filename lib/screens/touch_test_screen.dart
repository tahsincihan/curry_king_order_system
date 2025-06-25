import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class TouchTestScreen extends StatefulWidget {
  const TouchTestScreen({Key? key}) : super(key: key);

  @override
  _TouchTestScreenState createState() => _TouchTestScreenState();
}

class _TouchTestScreenState extends State<TouchTestScreen> 
    with TickerProviderStateMixin {
  
  List<TouchPoint> touchPoints = [];
  int completedTargets = 0;
  int totalTargets = 9;
  bool isTestComplete = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  final List<Offset> targetPositions = [
    const Offset(0.1, 0.1),   // Top-left
    const Offset(0.5, 0.1),   // Top-center
    const Offset(0.9, 0.1),   // Top-right
    const Offset(0.1, 0.5),   // Middle-left
    const Offset(0.5, 0.5),   // Center
    const Offset(0.9, 0.5),   // Middle-right
    const Offset(0.1, 0.9),   // Bottom-left
    const Offset(0.5, 0.9),   // Bottom-center
    const Offset(0.9, 0.9),   // Bottom-right
  ];
  
  List<bool> targetHit = List.filled(9, false);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _addTouchPoint(details.globalPosition);
    HapticFeedback.lightImpact();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _addTouchPoint(details.globalPosition);
  }

  void _addTouchPoint(Offset position) {
    setState(() {
      touchPoints.add(TouchPoint(
        position: position,
        timestamp: DateTime.now(),
      ));
      
      // Keep only recent touch points
      if (touchPoints.length > 100) {
        touchPoints.removeAt(0);
      }
    });
    
    _checkTargetHit(position);
  }

  void _checkTargetHit(Offset touchPosition) {
    final screenSize = MediaQuery.of(context).size;
    
    for (int i = 0; i < targetPositions.length; i++) {
      if (targetHit[i]) continue;
      
      final targetPos = Offset(
        targetPositions[i].dx * screenSize.width,
        targetPositions[i].dy * screenSize.height,
      );
      
      final distance = (touchPosition - targetPos).distance;
      if (distance < 30) { // 30px tolerance
        setState(() {
          targetHit[i] = true;
          completedTargets++;
          
          if (completedTargets == totalTargets) {
            isTestComplete = true;
          }
        });
        
        HapticFeedback.mediumImpact();
        break;
      }
    }
  }

  void _resetTest() {
    setState(() {
      touchPoints.clear();
      completedTargets = 0;
      isTestComplete = false;
      targetHit = List.filled(9, false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: const Text('Touch Screen Test'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetTest,
            tooltip: 'Reset Test',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showInstructions,
            tooltip: 'Instructions',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main touch area
          GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onTap: () {
              final RenderBox renderBox = context.findRenderObject() as RenderBox;
              final localPosition = renderBox.globalToLocal(
                renderBox.localToGlobal(Offset.zero),
              );
              _addTouchPoint(localPosition);
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent,
              child: CustomPaint(
                painter: TouchTrailPainter(touchPoints),
              ),
            ),
          ),
          
          // Target circles
          ...targetPositions.asMap().entries.map((entry) {
            final index = entry.key;
            final position = entry.value;
            final isHit = targetHit[index];
            
            return Positioned(
              left: position.dx * MediaQuery.of(context).size.width - 25,
              top: position.dy * MediaQuery.of(context).size.height - 25,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isHit ? 1.0 : _pulseAnimation.value,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isHit ? Colors.green : Colors.orange[600],
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isHit ? Colors.green : Colors.orange[600]!)
                                .withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: isHit
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 24,
                              )
                            : Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
          
          // Status overlay
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    isTestComplete 
                        ? '🎉 Touch Test Complete!' 
                        : 'Touch Screen Calibration Test',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isTestComplete
                        ? 'Your touch screen is working perfectly!'
                        : 'Touch all numbered targets: $completedTargets/$totalTargets',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (isTestComplete) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _resetTest,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Test Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.check),
                          label: const Text('Done'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Touch info
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Active touches: ${touchPoints.length}\n'
                'Tap, hold, and drag to test responsiveness\n'
                'Touch all numbered targets to complete test',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Touch Screen Test Instructions'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '1. Touch Accuracy Test:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• Touch all numbered targets (1-9)'),
                Text('• Targets will turn green when hit'),
                SizedBox(height: 12),
                
                Text(
                  '2. Touch Responsiveness:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• Tap anywhere to create touch points'),
                Text('• Drag your finger to draw trails'),
                Text('• Test multi-touch by using multiple fingers'),
                SizedBox(height: 12),
                
                Text(
                  '3. Edge Detection:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• Test corners and edges of screen'),
                Text('• Ensure all areas respond to touch'),
                SizedBox(height: 12),
                
                Text(
                  '4. Calibration Check:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• Touch should register exactly where you tap'),
                Text('• No offset or delay should occur'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }
}

class TouchPoint {
  final Offset position;
  final DateTime timestamp;
  
  TouchPoint({required this.position, required this.timestamp});
  
  bool get isExpired {
    return DateTime.now().difference(timestamp).inMilliseconds > 2000;
  }
  
  double get opacity {
    final age = DateTime.now().difference(timestamp).inMilliseconds;
    return math.max(0.0, 1.0 - (age / 2000.0));
  }
}

class TouchTrailPainter extends CustomPainter {
  final List<TouchPoint> touchPoints;
  
  TouchTrailPainter(this.touchPoints);

  @override
  void paint(Canvas canvas, Size size) {
    // Remove expired points
    touchPoints.removeWhere((point) => point.isExpired);
    
    // Draw touch trails
    for (int i = 0; i < touchPoints.length; i++) {
      final point = touchPoints[i];
      final paint = Paint()
        ..color = Colors.orange.withOpacity(point.opacity)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      
      // Draw point
      canvas.drawCircle(point.position, 4, paint);
      
      // Draw line to next point
      if (i < touchPoints.length - 1) {
        final nextPoint = touchPoints[i + 1];
        canvas.drawLine(point.position, nextPoint.position, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}