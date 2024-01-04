// ignore_for_file: prefer_const_constructors, deprecated_member_use, use_build_context_synchronously, unused_field, prefer_final_fields, unused_import, no_leading_underscores_for_local_identifiers, invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member, prefer_const_literals_to_create_immutables

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:page_transition/page_transition.dart';
import 'package:kickscorner_admin/pages/profile.dart';

class UpdateProfile extends StatefulWidget {
  const UpdateProfile({super.key});

  @override
  State<UpdateProfile> createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _fullNameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _locationController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();

  File? _profilePicture;
  final picker = ImagePicker();
  String _currentProfilePictureUrl = '';
  late String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    // Fetch and display the current user's information
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchCurrentUserInformation();
    });
  }

  void fetchCurrentUserInformation() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final user = _auth.currentUser;
    final email = user?.email;

    if (email != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('admins')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _currentUserId = snapshot.docs[0].id;
          Map<String, dynamic> userData = snapshot.docs[0].data();
          _fullNameController.text = userData['name'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _locationController.text = userData['city'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
          _currentProfilePictureUrl = userData['imageUrl'] ?? '';
        });
      } else {
        // User data not found in Firestore
        return;
      }
    } else {
      // User not logged in or email is null
      return;
    }
  }

  Future<void> _pickProfilePicture() async {
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _profilePicture = File(pickedImage.path);
      });
      //click save to update your profile once the profile picture is picked/selected
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Success! Click save!')),
      );
    }
  }

  Future<void> updateProfile() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          String? profilePictureUrl;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please wait...')),
          );

          if (_profilePicture != null) {
            // Upload profile picture to Firebase Storage
            Reference storageRef = FirebaseStorage.instance.ref().child('profile_pictures/${user.uid}.jpg');
            UploadTask uploadTask = storageRef.putFile(_profilePicture!);
            TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
            profilePictureUrl = await taskSnapshot.ref.getDownloadURL();
          } else {
            // Use previously fetched profile picture
            profilePictureUrl = _currentProfilePictureUrl;
          }

          //update firestore admin data
          await FirebaseFirestore.instance.collection('admins').doc(_currentUserId).update({
            'email': _emailController.text.trim(),
            'name': _fullNameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'city': _locationController.text.trim(),
            'imageUrl': profilePictureUrl,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile saved successfully!')),
          );
          //navigate to the profile screen using left to right animation
          Navigator.push(context, PageTransition(type: PageTransitionType.leftToRight, child: Profile(), isIos: false));
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save profile. Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: false, //ensure the title starts at the far left
        backgroundColor: Colors.white,
        elevation: 0,
        //back button
        leading: IconButton(
          onPressed: (){
            //navigate to profile screen using left to right animation
            Navigator.push(context, PageTransition(type: PageTransitionType.leftToRight, child: Profile(), isIos: false));
          },
          icon: const Icon(LineAwesomeIcons.angle_left), color: Colors.black,
        ),
        //edit profile
        title: Padding(
          padding: const EdgeInsets.all(0), //as close to the back arrow as possible
          child: Text(
            'Edit Profile',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(25),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                //profile picture
                Stack(
                  children: [
                    SizedBox(
                      width: 120, height: 120,
                      //profile picture
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: CircleAvatar(
                          backgroundImage: _currentProfilePictureUrl.isNotEmpty
                              ? NetworkImage(_currentProfilePictureUrl)
                              : AssetImage('assets/images/profile_pic.png') as ImageProvider,
                          radius: 50.0,
                        ),
                      ),
                    ), 
                    //pencil icon with black background for editing the profile picture
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        //fetch new profile picture 
                        onTap: (){
                          _pickProfilePicture();
                        },
                        child: Container(
                          width: 35, height: 35,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(100),color: Colors.black),                
                          child: const Icon(LineAwesomeIcons.alternate_pencil, size: 20.0, color: Colors.white)),
                      ),
                    ),                 
                  ],
                ),
                const SizedBox(height: 50),
                //Form for handling name, email, phone, and city
                Form(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _fullNameController,
                        decoration: InputDecoration(labelText: 'Full Name'),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(labelText: 'Email'),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter an email address';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(labelText: 'Phone Number'),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(labelText: 'City'),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter your city\'s name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      //edit profile button
                      SizedBox(
                        width: 200.0,
                        child: ElevatedButton(
                          //call function to add data to firebase
                          onPressed: updateProfile, 
                          style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black, side: BorderSide.none, shape: StadiumBorder()),
                        child: const Text('Save', style: TextStyle(color: Colors.white, fontSize: 14)),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}