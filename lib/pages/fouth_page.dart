import 'package:flutter/material.dart';
import 'welcome_screen.dart';

class Fourthpage extends StatelessWidget {
  const Fourthpage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // Center the content vertically
          crossAxisAlignment:
              CrossAxisAlignment.center, // Center the content horizontally
          children: <Widget>[
            // Title: "Find & Rent with Ease" in purple, centered
            Text(
              'In-App\nChat\nSupport', // Combined title text
              textAlign: TextAlign.center, // Center the title text
              style: TextStyle(
                fontSize: 48, // Big font size
                fontWeight: FontWeight.bold,
                color: Colors.indigo, // Purple color
              ),
            ),
            SizedBox(height: 15), // Add some spacing
            // Body text as a single block
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 33,
                  color: Colors.black, // Black color for the body text
                  fontWeight: FontWeight.bold, // Make the body text bold
                ),
                children: [
                  TextSpan(
                    text:
                        'Need help or have questions? Renters and owners can chat instantly within the app. Resolve issues, discuss details, and ensure a smooth rental experience, all in one place',
                  ),
                  TextSpan(
                    text: ' Rent',
                  ),
                  TextSpan(
                    text: 'X',
                    style: TextStyle(
                      color: Colors.orange, // Orange color for "X"
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20), // Add some spacing
            Spacer(), // Push the button to the bottom
            // Next button with purple background and white text
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WelcomePage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.indigo, // Purple background for the button
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: Text(
                'Next',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white, // White text for the button
                ),
              ),
            ),
            SizedBox(height: 100), // Add some spacing at the bottom
          ],
        ),
      ),
    );
  }
}
