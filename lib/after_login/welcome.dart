import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'explore.dart';

class WelcomePage extends StatefulWidget {
  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  String? username;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(seconds: 2));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _fetchUsername();
  }

  Future<void> _fetchUsername() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        setState(() {
          username = userDoc['username'] ?? "User";
        });

        _controller.forward(); // Start the fade-in animation

        Future.delayed(Duration(seconds: 2), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ExplorePage()),
          );
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white10, // Set background to white
        child: Center(
          child: username == null
              ? SizedBox()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    "Hello, $username!👋",
                    style: GoogleFonts.pacifico(
                      fontSize: 35,
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo, // Set font color to indigo
                      shadows: [
                        Shadow(
                          blurRadius: 5.0,
                          color: Colors.black26,
                          offset: Offset(3, 3),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
