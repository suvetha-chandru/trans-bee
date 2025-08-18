import 'package:flutter/material.dart';
import 'package:trans_bee/screens/add_item_page.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFB3E5FC),
                  Color(0xFF81D4FA),
                  Color(0xFF4FC3F7),
                ],
              ),
            ),
          ),

          // Floating decorative circles
          const Positioned(
            top: 50,
            left: 30,
            child: AnimatedCircle(radius: 40, color: Colors.blueAccent),
          ),
          const Positioned(
            bottom: 100,
            right: 50,
            child: AnimatedCircle(radius: 60, color: Colors.lightBlueAccent),
          ),
          const Positioned(
            top: 200,
            right: 80,
            child: AnimatedCircle(radius: 30, color: Colors.blueAccent),
          ),

          // Top-left and top-right images (minimal/no animation)
          Positioned(
            top: 0,
            left: 0,
            child: SizedBox(
              width: 100,
              height: 100,
              child: Image.asset('assets/tl.png'), // static image
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: SizedBox(
              width: 100,
              height: 100,
              child: Image.asset('assets/tr.png'), // static image
            ),
          ),

          // Main content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),

                  // Top animated image before Welcome text
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(seconds: 2),
                    curve: Curves.easeOut,
                    builder: (context, double value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 50 * (1 - value)),
                          child: SizedBox(
                            width: 150,
                            height: 150,
                            child: Image.asset('assets/top_animated.jpeg'),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // Welcome Text
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(seconds: 1),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Text(
                            "Welcome to Trans-Bee",
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                              shadows: [
                                Shadow(
                                  blurRadius: 15,
                                  color: Colors.black26,
                                  offset: Offset(3, 3),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Subtitle
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Text(
                            "Transporting goods all over Tamilnadu",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.blue.shade800,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),

                  // Book Now button
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddItemPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 50, vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(35),
                            ),
                            elevation: 10,
                            shadowColor: Colors.blueAccent.withOpacity(0.5),
                          ),
                          child: const Text(
                            "Book Now",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Floating animated circles remain the same
class AnimatedCircle extends StatefulWidget {
  final double radius;
  final Color color;
  const AnimatedCircle({super.key, required this.radius, required this.color});

  @override
  State<AnimatedCircle> createState() => _AnimatedCircleState();
}

class _AnimatedCircleState extends State<AnimatedCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 15).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _animation.value),
            child: Container(
              width: widget.radius,
              height: widget.radius,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          );
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
