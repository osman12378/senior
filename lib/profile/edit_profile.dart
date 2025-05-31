import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'profile.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  TextEditingController _usernameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  String? _profileImageUrl;
  File? _selectedImage;
  bool _isLoading = true;
  String _selectedCountryCode = "+961"; // Default country code

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userData =
          await _firestore.collection('users').doc(user.uid).get();

      if (userData.exists) {
        setState(() {
          _usernameController.text = userData['username'] ?? '';
          String fullPhone = userData['phone'] ?? '';
          if (fullPhone.startsWith(_selectedCountryCode)) {
            _phoneController.text =
                fullPhone.replaceFirst(_selectedCountryCode, '').trim();
          } else {
            _phoneController.text = fullPhone;
          }

          _profileImageUrl = userData['image_url'];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    String? imageUrl = _profileImageUrl;
    if (_selectedImage != null) {
      Reference ref = _storage.ref().child('profiles/${user.uid}.jpg');
      await ref.putFile(_selectedImage!);
      imageUrl = await ref.getDownloadURL();
    }

    await _firestore.collection('users').doc(user.uid).update({
      "username": _usernameController.text,
      "phone": '$_selectedCountryCode ${_phoneController.text}',
      "image_url": imageUrl,
    });

    setState(() {
      _profileImageUrl = imageUrl;
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Profile updated successfully!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _openFullScreenImage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImagePage(
          imageFile: _selectedImage,
          imageUrl: _profileImageUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            );
          },
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile Picture with tap
                  GestureDetector(
                    onTap: _openFullScreenImage,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade300,
                          child: ClipOval(
                            child: _selectedImage != null
                                ? Image.file(
                                    _selectedImage!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  )
                                : CachedNetworkImage(
                                    imageUrl: _profileImageUrl ?? '',
                                    placeholder: (context, url) =>
                                        CircularProgressIndicator(),
                                    errorWidget: (context, url, error) =>
                                        Icon(Icons.person, size: 50),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: -5,
                          right: -5,
                          child: IconButton(
                            icon: Icon(Icons.camera_alt, size: 30),
                            onPressed: _pickImage,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Username
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: "Username",
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Phone Number
                  IntlPhoneField(
                    controller: _phoneController,
                    initialCountryCode: "LB",
                    decoration: InputDecoration(
                      labelText: "Phone Number",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    onChanged: (phone) {
                      setState(() {
                        _selectedCountryCode = phone.countryCode;
                      });
                    },
                  ),

                  SizedBox(height: 30),

                  // Save Button
                  ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                    ),
                    child: Text(
                      "Save Changes",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// Full screen image viewer page
class FullScreenImagePage extends StatelessWidget {
  final File? imageFile;
  final String? imageUrl;

  const FullScreenImagePage({Key? key, this.imageFile, this.imageUrl})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (imageFile != null) {
      imageWidget = Image.file(imageFile!, fit: BoxFit.contain);
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.contain,
        placeholder: (context, url) =>
            Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => Icon(Icons.error),
      );
    } else {
      imageWidget = Icon(Icons.person, size: 100);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(child: imageWidget),
    );
  }
}
