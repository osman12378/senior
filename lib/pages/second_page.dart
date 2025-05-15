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
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
            children: <Widget>[
              // Title
              Center(
                child: Text(
                  'Find & Rent\nwith Ease',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ),
              SizedBox(height: 20),

              // RichText body
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 33,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text:
                            'Looking for a room, house, car, or unique travel experience?\n',
                      ),
                      TextSpan(text: 'Rent'),
                      TextSpan(
                        text: 'X',
                        style: TextStyle(color: Colors.orange),
                      ),
                      TextSpan(
                        text:
                            ' brings everything into one place, saving you time and effort. No more searching\nacross multiple platforms',
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Next button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ThirdPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                  child: Text(
                    'Next',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 100),
            ],
          )),
    );
  }
}
