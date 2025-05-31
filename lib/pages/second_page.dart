import 'package:flutter/material.dart';
import 'third_page.dart'; // Import the third page

class SecondPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white
      body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            padding:
                EdgeInsets.all(16.0), // Optional: add padding to the list view
            children: <Widget>[
              // Title: "Find & Rent with Ease" in purple, centered
              Text(
                'Find & Rent\nwith Ease', // Combined title text
                textAlign: TextAlign.center, // Center the title text
                style: TextStyle(
                  fontSize: 48, // Big font size
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo, // Purple color
                ),
              ),
              SizedBox(height: 50), // Add some spacing
              // Body text as a single block
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 30,
                    color: Colors.black, // Black color for the body text
                    fontWeight: FontWeight.bold, // Make the body text bold
                  ),
                  children: [
                    TextSpan(
                      text:
                          'Looking for a room, house, car, or unique travel experience?\n',
                    ),
                    TextSpan(
                      text: 'Rent',
                    ),
                    TextSpan(
                      text: 'X',
                      style: TextStyle(
                        color: Colors.orange, // Orange color for "X"
                      ),
                    ),
                    TextSpan(
                      text:
                          ' brings everything into one place, saving you time and effort. No more searching\n'
                          'across multiple platforms',
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20), // Add some spacing
              // Next button with purple background and white text
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ThirdPage()),
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
          )),
    );
  }
}
