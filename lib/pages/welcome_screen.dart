import 'package:flutter/material.dart';
import 'package:senior/screens/login.dart';
import 'package:senior/screens/signup.dart';

class WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Welcome text at the top
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                    fontSize: 55,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
                children: [
                  TextSpan(
                      text: 'Welcome\n',
                      style: TextStyle(color: Colors.indigo)),
                  TextSpan(text: 'to ', style: TextStyle(color: Colors.indigo)),
                  TextSpan(
                      text: 'Rent',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(
                      text: 'X',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.orange)),
                ],
              ),
            ),
            Column(
              children: [
                // Find. Rent. Connect.
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                    children: [
                      TextSpan(text: 'Find. '),
                      TextSpan(
                          text: 'Rent. ',
                          style: TextStyle(color: Colors.orange)),
                      TextSpan(
                          text: 'Connect.',
                          style: TextStyle(color: Colors.indigo)),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                // Description text
                Text(
                  'Start your hassle-\nfree rental\nexperience today!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 30),
                // Sign Up Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignUpPage()),
                    );
                  },
                  child: Text('Sign Up',
                      style: TextStyle(
                          fontSize: 21,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
                SizedBox(height: 20),
                // Login Text
                Text(
                  'Already have an account? Log in to continue your journey',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 50),
                // Log In Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  child: Text('Log In',
                      style: TextStyle(
                          fontSize: 21,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            // Footer text
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Text(
                'Your next rental is just a tap away!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
