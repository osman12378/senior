import 'package:flutter/material.dart';
import 'fouth_page.dart';

class ThirdPage extends StatelessWidget {
  const ThirdPage({super.key});

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
              'List & Earn\nSeamlessly', // Combined title text
              textAlign: TextAlign.center, // Center the title text
              style: TextStyle(
                fontSize: 55, // Big font size
                fontWeight: FontWeight.bold,
                color: Colors.indigo, // Purple color
              ),
            ),
            SizedBox(height: 80), // Add some spacing
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
                        'Owners can list properties or\n vehicles in just in few\n taps.',
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
                  TextSpan(
                      text:
                          ' ensures\n maximum visibility,secure transactions,and an easy-to-use interface'),
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
                  MaterialPageRoute(builder: (context) => Fourthpage()),
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
