// ignore_for_file: unused_local_variable, unused_field, deprecated_member_use, use_build_context_synchronously, prefer_const_constructors, prefer_const_literals_to_create_immutables, sized_box_for_whitespace, prefer_final_fields, no_leading_underscores_for_local_identifiers

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:lottie/lottie.dart';
import 'package:kickscorner_admin/pages/home.dart';
import 'package:page_transition/page_transition.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;

  const RegisterPage({Key? key, required this.onTap}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  //if password reveal icon is pressed
  //show the password based on the result of this variable
  bool isPasswordVisible = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  // text editing controllers
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final townController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final superkeyController = TextEditingController();

  //detect selection of a text field to allow for color change onFocus
  //create focus nodes for each text field
  FocusNode _nameFocusNode = FocusNode();
  FocusNode _phoneFocusNode = FocusNode();
  FocusNode _townFocusNode = FocusNode();
  FocusNode _emailFocusNode = FocusNode();
  FocusNode _passwordFocusNode = FocusNode();
  FocusNode _cpasswordFocusNode = FocusNode();
  FocusNode _skeyFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameFocusNode.addListener(_onFocusChange);
    _phoneFocusNode.addListener(_onFocusChange);
    _townFocusNode.addListener(_onFocusChange);
    _emailFocusNode.addListener(_onFocusChange);
    _passwordFocusNode.addListener(_onFocusChange);
    _cpasswordFocusNode.addListener(_onFocusChange);
    _skeyFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    //remove listeners
    _nameFocusNode.removeListener(_onFocusChange);
    _phoneFocusNode.removeListener(_onFocusChange);
    _townFocusNode.removeListener(_onFocusChange);
    _emailFocusNode.removeListener(_onFocusChange);
    _passwordFocusNode.removeListener(_onFocusChange);
    _cpasswordFocusNode.removeListener(_onFocusChange);
    _skeyFocusNode.removeListener(_onFocusChange);
    
    //dispose listeners
    _nameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _townFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _cpasswordFocusNode.dispose();
    _skeyFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      // Empty setState to trigger a rebuild to update the label color
    });
  }

  //handle profile picture info
  File? _profilePicture;
  final picker = ImagePicker();
  //pick profile picture from gallery
  Future<void> _pickProfilePicture() async {
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _profilePicture = File(pickedImage.path);
      });
    }
  }

  Future<void> addUserDetails(String name, String phone, String email, String town, String url) async {
    //date variable
    var date = DateTime.now().toString();
    var dateparse = DateTime.parse(date);
    var formattedDate =
        "${dateparse.day}-${dateparse.month}-${dateparse.year}";

    //add user data to firestore under the 'admins' collection
    //for regular users switch the collection to 'users'
    await FirebaseFirestore.instance.collection('admins').add({
      //change collection to 'users' for the users app
      'name': name,
      'phone': phone,
      'email': email,
      'imageUrl': url,
      'joinedOn': formattedDate,
      'city': town
    });
  }

  // error message to user
  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Center(
            child: Text(
              message,
              style: const TextStyle(color: Colors.black),
            ),
          ),
        );
      },
    );
  }

  Future<void> signUp() async {
    //user cannot sign up without profile picture
    if (_profilePicture == null) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Error'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset("assets/icons/error.json"),
                  SizedBox(height: 10),
                  Text('Choose profile picture.'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }
    //check if super key is correct, then store user information.
    if (superkeyController.text == 'Sn3ak3r!24') {
      if(passwordController.text == confirmPasswordController.text){
        //include superkey for admin app --> Sn3ak3r!24
        //show progress dialogue or please wait text on the ScaffoldMessenger 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signing up. Please wait!')),
        );
        //create user with email and password for authentication
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        // Upload profile picture to Firebase Storage
        Reference storageRef = FirebaseStorage.instance 
            .ref()
            .child('profile_pictures/${userCredential.user!.uid}.jpg');
        await storageRef.putFile(_profilePicture!);
        String profilePictureUrl = await storageRef.getDownloadURL();

        //get current user's id
        FirebaseAuth _auth = FirebaseAuth.instance;
        final User? user = _auth.currentUser;
        final _uid = user!.uid;

        //add user details to firestore using addUserDetails()
        // profilePictureUrl represents the url for the user's profile picture
        addUserDetails(
          nameController.text.trim(),
          phoneController.text.trim(),
          emailController.text.trim(),
          townController.text.trim(),
          profilePictureUrl,
        );

        //show progress dialogue or redirecting message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Redirecting!')),
        );
        
        //navigate to home page using homescreen()
        /* Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Home()),
        ); */ 
        //default animation is basic so we can use the PageTransition package to use the right to left animation
        Navigator.push(context, PageTransition(type: PageTransitionType.rightToLeft, child: Home(), isIos: false));
      } else{
        // show error message saying passwords don't match
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Passwords do not match!')),
        );
      }
    } else {
      // show error message saying super key is invalid
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid super key!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                // heading
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Create an account ',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),

                const SizedBox(height: 10),

                // let's create an account for you
                Text(
                  'Sign up to join Kicks Corner',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 20),

                // name textfield 
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: TextField(
                    controller: nameController,
                    obscureText: false,
                    style: TextStyle(color: Colors.black), // Set the default text color of the TextField
                    cursorColor: Colors.black, // Set the cursor color to black
                    focusNode: _nameFocusNode, // Set the focus node
                    decoration: InputDecoration(
                      labelText: 'Full name',
                      labelStyle: TextStyle(
                        color: _nameFocusNode.hasFocus ? Color.fromARGB(255, 17, 168, 22) : Colors.grey, // Change the label color based on focus --> 
                        fontWeight: FontWeight.normal,
                        fontSize: 18,
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.auto, // Show the label as floating label
                      enabledBorder: OutlineInputBorder( // Rounded border for the initial state
                        borderSide: BorderSide(
                          color: Colors.grey, // Initial border color
                        ),
                        borderRadius: BorderRadius.circular(25.0), // Adjust the border radius as needed
                      ),
                      focusedBorder: OutlineInputBorder( // Rounded border for the focused state
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 17, 168, 22), // Change border color on focus
                        ),
                        borderRadius: BorderRadius.circular(25.0), // Adjust the border radius as needed
                      ),
                      prefixIcon: Icon(Icons.person_outline_rounded, color: _nameFocusNode.hasFocus ? Color.fromARGB(255, 17, 168, 22) : Colors.grey), // Change the icon color based on focus
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // phone textfield 
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: TextField(
                    controller: phoneController,
                    obscureText: false,
                    style: TextStyle(color: Colors.black), // Set the default text color of the TextField
                    cursorColor: Colors.black, // Set the cursor color to black
                    focusNode: _phoneFocusNode, // Set the focus node
                    decoration: InputDecoration(
                      labelText: 'Phone number',
                      labelStyle: TextStyle(
                        color: _phoneFocusNode.hasFocus ? Color.fromARGB(255, 17, 168, 22) : Colors.grey, // Change the label color based on focus
                        fontWeight: FontWeight.normal,
                        fontSize: 18,
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.auto, // Show the label as floating label
                      enabledBorder: OutlineInputBorder( // Rounded border for the initial state
                        borderSide: BorderSide(
                          color: Colors.grey, // Initial border color
                        ),
                        borderRadius: BorderRadius.circular(25.0), // Adjust the border radius as needed
                      ),
                      focusedBorder: OutlineInputBorder( // Rounded border for the focused state
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 17, 168, 22), // Change border color on focus
                        ),
                        borderRadius: BorderRadius.circular(25.0), // Adjust the border radius as needed
                      ),
                      prefixIcon: Icon(Icons.phone_outlined, color: _phoneFocusNode.hasFocus ? Color.fromARGB(255, 17, 168, 22) : Colors.grey), // Change the icon color based on focus
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // town textfield townController
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: TextField(
                    controller: townController,
                    obscureText: false,
                    style: TextStyle(color: Colors.black), // Set the default text color of the TextField
                    cursorColor: Colors.black, // Set the cursor color to black
                    focusNode: _townFocusNode, // Set the focus node
                    decoration: InputDecoration(
                      labelText: 'City',
                      labelStyle: TextStyle(
                        color: _townFocusNode.hasFocus ? Color.fromARGB(255, 17, 168, 22) : Colors.grey, // Change the label color based on focus
                        fontWeight: FontWeight.normal,
                        fontSize: 18,
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.auto, // Show the label as floating label
                      enabledBorder: OutlineInputBorder( // Rounded border for the initial state
                        borderSide: BorderSide(
                          color: Colors.grey, // Initial border color
                        ),
                        borderRadius: BorderRadius.circular(25.0), // Adjust the border radius as needed
                      ),
                      focusedBorder: OutlineInputBorder( // Rounded border for the focused state
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 17, 168, 22), // Change border color on focus
                        ),
                        borderRadius: BorderRadius.circular(25.0), // Adjust the border radius as needed
                      ),
                      prefixIcon: Icon(Icons.location_on_outlined, color: _townFocusNode.hasFocus ? Color.fromARGB(255, 17, 168, 22) : Colors.grey), // Change the icon color based on focus
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // email textfield emailController
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: TextField(
                    controller: emailController,
                    obscureText: false,
                    style: TextStyle(color: Colors.black), // Set the default text color of the TextField
                    cursorColor: Colors.black, // Set the cursor color to black
                    focusNode: _emailFocusNode, // Set the focus node
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(
                        color: _emailFocusNode.hasFocus ? Color.fromARGB(255, 17, 168, 22) : Colors.grey, // Change the label color based on focus
                        fontWeight: FontWeight.normal,
                        fontSize: 18,
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.auto, // Show the label as floating label
                      enabledBorder: OutlineInputBorder( // Rounded border for the initial state
                        borderSide: BorderSide(
                          color: Colors.grey, // Initial border color
                        ),
                        borderRadius: BorderRadius.circular(25.0), // Adjust the border radius as needed
                      ),
                      focusedBorder: OutlineInputBorder( // Rounded border for the focused state
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 17, 168, 22), // Change border color on focus
                        ),
                        borderRadius: BorderRadius.circular(25.0), // Adjust the border radius as needed
                      ),
                      prefixIcon: Icon(Icons.email_outlined, color: _emailFocusNode.hasFocus ? Color.fromARGB(255, 17, 168, 22) : Colors.grey), // Change the icon color based on focus
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // password textfield passwordController
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: passwordController,
                        obscureText: !isPasswordVisible,
                        style: TextStyle(color: Colors.black), // Set the default text color of the TextField
                        cursorColor: Colors.black, // Set the cursor color to black
                        focusNode: _passwordFocusNode, // Set the focus node
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(
                            color: _passwordFocusNode.hasFocus ? Color.fromARGB(255, 17, 168, 22) : Colors.grey, // Change the label color based on focus
                            fontWeight: FontWeight.normal,
                            fontSize: 18,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.auto, // Show the label as floating label
                          enabledBorder: OutlineInputBorder( // Rounded border for the initial state
                            borderSide: BorderSide(
                              color: Colors.grey, // Initial border color
                            ),
                            borderRadius: BorderRadius.circular(25.0), // Adjust the border radius as needed
                          ),
                          focusedBorder: OutlineInputBorder( // Rounded border for the focused state
                            borderSide: BorderSide(
                              color: Color.fromARGB(255, 17, 168, 22), // Change border color on focus
                            ),
                            borderRadius: BorderRadius.circular(25.0), // Adjust the border radius as needed
                          ),
                          prefixIcon: Icon(Icons.lock_outline_rounded, color: _passwordFocusNode.hasFocus ? Color.fromARGB(255, 17, 168, 22) : Colors.grey), // Change the icon color based on focus
                          suffixIcon: GestureDetector(
                            onTap: () {
                              setState(() {
                                isPasswordVisible = !isPasswordVisible;
                              });
                            },
                            child: Icon(
                              isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey, // Set a specific color for the trailing icon
                            ),
                          ),
                        ),
                      ),
                      if (passwordController.text.length < 8)
                        Text(
                          'Password should be 8 characters or more',
                          style: TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // confirm password textfield confirmPasswordController
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: !isPasswordVisible,
                        style: TextStyle(color: Colors.black), // Set the default text color of the TextField
                        cursorColor: Colors.black, // Set the cursor color to black
                        focusNode: _cpasswordFocusNode, // Set the focus node
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          labelStyle: TextStyle(
                            color: _cpasswordFocusNode.hasFocus ? Color.fromARGB(255, 17, 168, 22) : Colors.grey, // Change the label color based on focus
                            fontWeight: FontWeight.normal,
                            fontSize: 18,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.auto, // Show the label as floating label
                          enabledBorder: OutlineInputBorder( // Rounded border for the initial state
                            borderSide: BorderSide(
                              color: Colors.grey, // Initial border color
                            ),
                            borderRadius: BorderRadius.circular(25.0), // Adjust the border radius as needed
                          ),
                          focusedBorder: OutlineInputBorder( // Rounded border for the focused state
                            borderSide: BorderSide(
                              color: Color.fromARGB(255, 17, 168, 22), // Change border color on focus
                            ),
                            borderRadius: BorderRadius.circular(25.0), // Adjust the border radius as needed
                          ),
                          prefixIcon: Icon(Icons.lock_outline_rounded, color: _cpasswordFocusNode.hasFocus ? Color.fromARGB(255, 17, 168, 22) : Colors.grey), // Change the icon color based on focus
                          suffixIcon: GestureDetector(
                            onTap: () {
                              setState(() {
                                isPasswordVisible = !isPasswordVisible;
                              });
                            },
                            child: Icon(
                              isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey, // Set a specific color for the trailing icon
                            ),
                          ),
                        ),
                      ),
                      if (confirmPasswordController.text.length < 8)
                        Text(
                          'Password should be 8 characters or more',
                          style: TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                //super key textfield superkeyController
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: TextField(
                    controller: superkeyController,
                    obscureText: true,
                    style: TextStyle(color: Colors.black), // Set the default text color of the TextField
                    cursorColor: Colors.black, // Set the cursor color to black
                    focusNode: _skeyFocusNode, // Set the focus node
                    decoration: InputDecoration(
                      labelText: 'Super key',
                      labelStyle: TextStyle(
                        color: _skeyFocusNode.hasFocus ? Color.fromARGB(255, 17, 168, 22) : Colors.grey, // Change the label color based on focus
                        fontWeight: FontWeight.normal,
                        fontSize: 18,
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.auto, // Show the label as floating label
                      enabledBorder: OutlineInputBorder( // Rounded border for the initial state
                        borderSide: BorderSide(
                          color: Colors.grey, // Initial border color
                        ),
                        borderRadius: BorderRadius.circular(25.0), // Adjust the border radius as needed
                      ),
                      focusedBorder: OutlineInputBorder( // Rounded border for the focused state
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 17, 168, 22), // Change border color on focus
                        ),
                        borderRadius: BorderRadius.circular(25.0), // Adjust the border radius as needed
                      ),
                      prefixIcon: Icon(Icons.key_rounded, color: _skeyFocusNode.hasFocus ? Color.fromARGB(255, 17, 168, 22) : Colors.grey), // Change the icon color based on focus
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                //select profile picture and pass it to _pickProfilePicture() function
                //also display the profile picture to the user in a circular container
                _profilePicture != null
                    ? CircleAvatar(
                        radius: 50,
                        backgroundImage: FileImage(_profilePicture!),
                      )
                    : Container(),
                InkWell(
                  onTap: _pickProfilePicture,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color.fromARGB(255, 209, 209, 209)),
                    ),
                    child: Text(
                      'Choose Profile Picture',
                      style: TextStyle(
                        color: Color.fromARGB(255, 17, 168, 22),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // sign up button onTap: signUp
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ElevatedButton(
                    onPressed: signUp,
                    style: ElevatedButton.styleFrom(
                      primary: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      minimumSize: Size(300, 50),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Sign up',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // not a member? register now
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Have an account?',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      //navigate to login page
                      onTap: widget.onTap,
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Color.fromARGB(255, 17, 168, 22),  //Color(0xFF4C79FE)
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}