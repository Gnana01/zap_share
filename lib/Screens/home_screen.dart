import 'package:flutter/material.dart';
import 'package:flutter_swiper_null_safety/flutter_swiper_null_safety.dart';
import 'package:zap_share/Screens/HttpFileShareScreen.dart';
import 'package:zap_share/Screens/any_where_share.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0; // Track active page
  bool isTapped = false;

  final List<String> labels = ["global", "settings"];
  final List<IconData> icons = [
 // Local screen icon
    Icons.computer, // Global screen icon
    Icons.public, // Settings screen icon
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "ZapShare",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Swiper(
            itemBuilder: (BuildContext context, int index) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTapDown: (_) => setState(() => isTapped = true),
                    onTapUp: (_) {
                      Future.delayed(Duration(milliseconds: 150), () {
                        setState(() => isTapped = false);
                        if (index == 0) {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              transitionDuration: Duration(milliseconds: 200),
                              pageBuilder: (context, animation, secondaryAnimation) => HttpFileShareScreen(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                var scaleTween = Tween<double>(begin: 0.8, end: 1.0)
                                    .chain(CurveTween(curve: Curves.easeInOut));

                                return ScaleTransition(
                                  scale: animation.drive(scaleTween),
                                  child: child,
                                );
                              },
                            ),
                          );
                        }else if (index == 1) {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              transitionDuration: Duration(milliseconds: 200),
                              pageBuilder: (context, animation, secondaryAnimation) => UploadScreen(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                var scaleTween = Tween<double>(begin: 0.8, end: 1.0)
                                    .chain(CurveTween(curve: Curves.easeInOut));

                                return ScaleTransition(
                                  scale: animation.drive(scaleTween),
                                  child: child,
                                );
                              },
                            ),
                          );
                        }
                      });
                    },
                    onTapCancel: () => setState(() => isTapped = false),
                    child: _animatedButton(index),
                  ),
                ],
              );
            },
            itemCount: 2, // Exactly 3 pages
            loop: false, // No infinite swiping
            onIndexChanged: (index) {
              setState(() {
                currentIndex = index; // Update active page index
              });
            },
          ),

          // Labels & Indicator Dots
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  2,
                      (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Icon(
                      Icons.circle,
                      size: 10,
                      color: i == currentIndex ? Colors.white : Colors.grey, // Correct color logic
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _animatedButton(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 150),
      height: isTapped ? 200 : 220,
      width: isTapped ?  200 : 220,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: isTapped ? 8.0 : 12.0,
            offset: Offset(0.0, 5.0),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icons[index],
          size: 90,
          color: Colors.black,
        ),
      ),
    );
  }
}
