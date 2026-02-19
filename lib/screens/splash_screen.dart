import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main_menu_screen.dart'; // Ensure this import is correct based on your project structure

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _exhaustController;
  
  // Animations
  late Animation<double> _rocketPositionAnim;
  late Animation<double> _starSpeedAnim;
  late Animation<double> _backgroundFadeAnim;
  late Animation<double> _titleFadeAnim;
  late Animation<double> _titleScaleAnim;

  final List<SplashStar> _stars = [];
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();

    // Main sequence controller (5 seconds)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    // Exhaust flickering controller (infinite loop)
    _exhaustController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat(reverse: true);

    // Rocket moves from bottom (1.2) to top (-0.5)
    // Starts moving at 10% of timeline, ends at 95%
    _rocketPositionAnim = Tween<double>(begin: 1.4, end: -0.5).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.05, 0.95, curve: Curves.easeInOutQuart),
      ),
    );

    // Background fades from black to space color
    _backgroundFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Star speed increases as rocket accelerates
    _starSpeedAnim = Tween<double>(begin: 0.0, end: 20.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.1, 0.9, curve: Curves.easeIn),
      ),
    );

    // Title animations
    _titleFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.6, curve: Curves.easeIn),
      ),
    );

    _titleScaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.7, curve: Curves.elasticOut),
      ),
    );

    _mainController.forward();
    _mainController.addListener(_updateStars);

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToHome();
      }
    });

    // Initialize stars
    for (int i = 0; i < 100; i++) {
      _stars.add(SplashStar(_rnd));
    }
  }

  Widget _buildExhaust() {
    return AnimatedBuilder(
      animation: _exhaustController,
      builder: (context, _) {
        return CustomPaint(
          painter: ExhaustPainter(_exhaustController.value),
          size: const Size(40, 100),
        );
      },
    );
  }

  void _updateStars() {
    setState(() {
      for (var star in _stars) {
        star.y += star.speed * _starSpeedAnim.value;
        if (star.y > 1.0) {
          star.y = 0.0;
          star.x = _rnd.nextDouble();
        }
      }
    });
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MainMenuScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _exhaustController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine background color based on fade animation
    // From Black (0xFF000000) to Deep Space (0xFF050D1A)
    final bgColor = Color.lerp(
      Colors.black,
      const Color(0xFF050D1A),
      _backgroundFadeAnim.value,
    );

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Starfield
          CustomPaint(
            painter: StarfieldPainter(_stars, _backgroundFadeAnim.value),
            size: MediaQuery.of(context).size,
          ),
          
          // Rocket & Exhaust
          AnimatedBuilder(
            animation: _rocketPositionAnim,
            builder: (context, child) {
              final screenHeight = MediaQuery.of(context).size.height;
              // Rocket position: 1.0 = bottom, 0.0 = top (reversed for alignment?)
              // Actually alignment y: 1.0 is bottom, -1.0 is top.
              // Let's use Positioned
              final bottomPos = (1.0 - _rocketPositionAnim.value) * screenHeight - (screenHeight * 0.2); // adjusting offset
              
              // Align approach: 
              // Value 1.2 (below screen) -> -0.2 (above screen)
              // We want to map this to Alignment(0, y)
              // 1.0 -> Alignment(0, 1.0)
              // -1.0 -> Alignment(0, -1.0)
              
              // Let's stick to Alignment for smoother resizing support
              return Align(
                alignment: Alignment(0.0, _rocketPositionAnim.value * 2 - 1), // Map 0..1 to -1..1 logic approx? 
                // Wait, if begin=1.2, end=-0.2.
                // At 1.2: y = 1.2 * 2 - 1 = 1.4 (off screen bottom)
                // At -0.2: y = -0.2 * 2 - 1 = -1.4 (off screen top)
                // This seems correct for Alignment
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.65,
                  height: MediaQuery.of(context).size.width * 0.85,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Glowing Background behind ship
                      Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.width * 0.8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.15 * (1.0 - _rocketPositionAnim.value.abs().clamp(0, 1))),
                              blurRadius: 100,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                      ),
                      // Dual Exhausts for the new ship
                      Positioned(
                        top: 160,
                        left: 45,
                        child: _buildExhaust(),
                      ),
                      Positioned(
                        top: 160,
                        right: 45,
                        child: _buildExhaust(),
                      ),
                      // Rocket / Logo
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.7,
                        height: MediaQuery.of(context).size.width * 0.7,
                        child: Image.asset(
                          'assets/images/splashship.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Start Button (Optional, maybe hidden since it's auto-play)
          // User requested "When the user taps a button, a rocket ship sprite appears..."
          // My implementation automatically starts. Let's add the button to triggers start.
          if (!_mainController.isAnimating && !_mainController.isCompleted)
            Center(
              child: ElevatedButton(
                onPressed: () {
                  _mainController.forward();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  side: BorderSide(color: Colors.blue.withOpacity(0.5), width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: Text(
                  "LAUNCH",
                  style: GoogleFonts.orbitron(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 4,
                    shadows: [
                      const Shadow(
                        color: Colors.blue,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Title
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return Opacity(
                  opacity: _titleFadeAnim.value,
                  child: Transform.scale(
                    scale: _titleScaleAnim.value,
                    child: Column(
                      children: [
                        Text(
                          "SPACE",
                          style: GoogleFonts.orbitron(
                            fontSize: 50,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 10,
                            shadows: [
                              Shadow(color: Colors.blue.withOpacity(0.8), blurRadius: 20),
                              Shadow(color: Colors.cyan.withOpacity(0.5), blurRadius: 40),
                            ],
                          ),
                        ),
                        Text(
                          "ESCAPER",
                          style: GoogleFonts.orbitron(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade200,
                            letterSpacing: 15,
                            shadows: [
                              Shadow(color: Colors.blue.withOpacity(0.5), blurRadius: 10),
                              Shadow(color: Colors.cyan.withOpacity(0.3), blurRadius: 25),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Progress Bar at bottom
          Positioned(
            bottom: 50,
            left: 50,
            right: 50,
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _mainController.value,
                        backgroundColor: Colors.white.withOpacity(0.05),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.withOpacity(0.5)),
                        minHeight: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "INITIALIZING SYSTEMS...",
                      style: GoogleFonts.orbitron(
                        fontSize: 10,
                        color: Colors.blue.withOpacity(0.4),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SplashStar {
  double x;
  double y;
  double size;
  double speed;
  double opacity;
  Color color;

  SplashStar(Random rnd)
      : x = rnd.nextDouble(),
        y = rnd.nextDouble(),
        size = rnd.nextDouble() * 2 + 0.5,
        speed = rnd.nextDouble() * 0.05 + 0.01,
        opacity = rnd.nextDouble() * 0.5 + 0.3,
        color = rnd.nextBool() ? Colors.white : (rnd.nextBool() ? Colors.blue.shade200 : Colors.cyan.shade100);
}

class StarfieldPainter extends CustomPainter {
  final List<SplashStar> stars;
  final double progress; // 0..1, helps with opacity spawn

  StarfieldPainter(this.stars, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (var star in stars) {
      // Fade in stars based on progress
      final finalOpacity = (star.opacity * progress).clamp(0.0, 1.0);
      final paint = Paint()..color = star.color.withOpacity(finalOpacity);

      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        paint,
      );
      
      // Add a small glow to some stars
      if (star.size > 2.0) {
        canvas.drawCircle(
          Offset(star.x * size.width, star.y * size.height),
          star.size * 2,
          Paint()..color = star.color.withOpacity(finalOpacity * 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant StarfieldPainter oldDelegate) => true;
}

class ExhaustPainter extends CustomPainter {
  final double animationValue; // 0..1 from controller

  ExhaustPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.blue.shade400,
          Colors.cyanAccent,
          Colors.blue.shade200,
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final w = size.width;
    final h = size.height;
    
    // Create a jagged flame shape
    path.moveTo(w * 0.2, 0);
    
    // Left side jagged
    path.quadraticBezierTo(w * 0.1, h * 0.3, 0, h * 0.5 + sin(animationValue * pi * 4) * 10);
    
    // Bottom tip
    path.lineTo(w * 0.5, h * (0.8 + animationValue * 0.2));
    
    // Right side jagged
    path.lineTo(w, h * 0.5 + cos(animationValue * pi * 4) * 10);
    path.quadraticBezierTo(w * 0.9, h * 0.3, w * 0.8, 0);
    
    path.close();

    canvas.drawPath(path, paint);
    
    // Inner white core
    final corePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white,
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.6));
      
    final corePath = Path();
    corePath.moveTo(w * 0.35, 0);
    corePath.lineTo(w * 0.5, h * 0.4);
    corePath.lineTo(w * 0.65, 0);
    corePath.close();
    
    canvas.drawPath(corePath, corePaint);
  }

  @override
  bool shouldRepaint(covariant ExhaustPainter oldDelegate) => true;
}
