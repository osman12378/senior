import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:senior/screens/login.dart';

import 'approved.dart';
import 'manage_users.dart';
import 'pending.dart';
import 'rejected.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 0;

  // List of pages for each tab
  List<Widget> _pages = [
    PendingPage(),
    RejectedPage(),
    ApprovedPage(),
    ManageUsersPage(),
  ];

  // List of titles for each page
  List<String> _titles = [
    'Pending Payments',
    'Rejected Payments',
    'Approved Payments',
    'Manage Users',
  ];

  // This will be called when an item is selected from the Bottom Navigation Bar.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Logout function
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light(),
      child: Scaffold(backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: Text(
              _titles[_selectedIndex]), // Change title based on selected index
          automaticallyImplyLeading: false,
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.exit_to_app),
              color: Colors.red,
              onPressed:
                  _logout, // Call the logout function when the button is pressed
            ),
          ],
        ),
        body: Container(
          color: Colors.white, // Set the background color to white
          child: _pages[
              _selectedIndex], // Display the appropriate page based on the index
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.white,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.indigo,
          unselectedItemColor: Colors.black,
          type: BottomNavigationBarType.fixed,
          iconSize: 30,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.pending),
              label: 'Pending',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.cancel),
              label: 'Rejected',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle),
              label: 'Approved',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Manage Users',
            ),
          ],
        ),
      ),
    );
  }
}
