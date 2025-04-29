import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_profile.dart'; // Import EditProfile page

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _changePassword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      User? user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = "User not found!";
          _isLoading = false;
        });
        return;
      }

      if (_newPasswordController.text != _confirmPasswordController.text) {
        setState(() {
          _errorMessage = "New passwords do not match!";
          _isLoading = false;
        });
        return;
      }

      // Reauthenticate the user
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _oldPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPasswordController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password changed successfully!")),
      );

      // Navigate back to Edit Profile page after success
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => EditProfile()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to change password: $e";
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Change Password',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "enter your old Password",
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 23),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "enter a new Password",
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 23),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Confirm New Password",
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
            ),
            if (_errorMessage != null) ...[
              SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
            ],
            SizedBox(height: 40),

            // Change Password Button
            Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.indigo)
                    : Text(
                        "Change Password",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
