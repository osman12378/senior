import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:senior/screens/login.dart';
import 'package:intl_phone_field/intl_phone_field.dart'; // Import IntlPhoneField
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool showspinner = false;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _passwordError;
  File? _selectedImage;
  String phoneNumber = "";

  void _validatePassword() {
    setState(() {
      if (_confirmPasswordController.text.isNotEmpty &&
          _confirmPasswordController.text != _passwordController.text) {
        _passwordError = "Passwords do not match";
      } else {
        _passwordError = null;
      }
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image, String userId) async {
    try {
      // Create a reference to the 'profiles' folder in Firebase Storage
      Reference ref = _storage.ref().child('profiles/$userId.jpg');

      // Upload the image to Firebase Storage
      await ref.putFile(image);

      // Retrieve the download URL of the uploaded image
      String downloadUrl = await ref.getDownloadURL();
      print("Image uploaded successfully, URL: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  Future<void> _signUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _passwordError = "Passwords do not match";
      });
      return;
    }

    setState(() {
      showspinner = true; // Show spinner while signing up
    });

    try {
      // Create a user with email and password
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      String? imageUrl; // Default to null in case no image is selected

      // Upload image if selected
      if (_selectedImage != null) {
        String userId = userCredential.user!.uid;
        print("Uploading image for user with ID: $userId");
        imageUrl =
            await _uploadImage(_selectedImage!, userId); // Upload and get URL
        if (imageUrl == null) {
          print("Image upload failed");
          // Handle upload failure (e.g., show error to user)
        }
      }

      // Store user data in Firestore
      await _firestore.collection("users").doc(userCredential.user!.uid).set({
        "username": _usernameController.text,
        "email": _emailController.text,
        "phone": phoneNumber,
        "address": _addressController.text,
        "role": "renter",
        "status": true,
        // Only add image_url if an image was uploaded successfully
        if (imageUrl != null) "image_url": imageUrl,
      });

      // Navigate to the login page after successful sign-up
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = "An error occurred. Please try again.";

      if (e.code == 'email-already-in-use') {
        errorMessage = "This email is already registered. Please log in.";
      } else if (e.code == 'weak-password') {
        errorMessage = "Your password is too weak. Try a stronger one.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "The email address is not valid.";
      } else if (e.code == 'operation-not-allowed') {
        errorMessage = "Sign up with email/password is not allowed.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() {
        showspinner = false; // Hide spinner after sign-up attempt
      });
    }
  }

  Widget _buildTextField(
      TextEditingController controller, String hintText, IconData icon,
      {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextField(
        controller: controller,
        obscureText: isPassword
            ? (controller == _passwordController
                ? _obscurePassword
                : _obscureConfirmPassword)
            : false,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: Colors.indigo),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(controller == _passwordController
                      ? _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility
                      : _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      if (controller == _passwordController) {
                        _obscurePassword = !_obscurePassword;
                      } else {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      }
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ModalProgressHUD(
        inAsyncCall: showspinner,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 50),
                Text("Sign Up",
                    style: TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo)),
                SizedBox(height: 30),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.purple.shade50,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : null,
                      child: _selectedImage == null
                          ? Icon(Icons.person, size: 50, color: Colors.indigo)
                          : null,
                    ),
                    Positioned(
                      bottom: -15,
                      right: -17,
                      child: IconButton(
                        icon: Icon(Icons.add, size: 40, color: Colors.black),
                        onPressed: _pickImage,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                _buildTextField(
                    _usernameController, "Enter your username", Icons.person),
                _buildTextField(
                    _emailController, "Enter your email", Icons.mail),
                _buildTextField(
                    _passwordController, "Enter your password", Icons.lock,
                    isPassword: true),
                _buildTextField(_confirmPasswordController,
                    "Confirm your password", Icons.lock,
                    isPassword: true),
                // Replace this with IntlPhoneField

                _buildTextField(_addressController, "Enter your address",
                    Icons.location_on),
                IntlPhoneField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    hintText: "Enter your phone number",
                    prefixIcon: Icon(Icons.phone,
                        color: Colors.indigo), // Prefix icon like the others
                    filled: true,
                    fillColor: Colors.white70, // Set background to white
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          10), // Rounded corners like the other fields
                      borderSide: BorderSide(
                        color: Colors.indigo, // Border color
                        width: 1.0, // Border width
                      ),
                    ),
                  ),
                  initialCountryCode: 'LB',
                  onChanged: (phone) {
                    setState(() {
                      phoneNumber = phone.completeNumber;
                    });
                  },
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      showspinner = true; // Show spinner before sign up process
                    });

                    await _signUp(); // Perform the sign-up operation

                    setState(() {
                      showspinner = false; // Hide spinner after sign up attempt
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: Text("Sign Up",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),

                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
