// ignore_for_file: prefer_const_constructors, deprecated_member_use, use_build_context_synchronously, prefer_const_literals_to_create_immutables, unused_field, prefer_final_fields

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kickscorner_admin/pages/home.dart';
import 'package:page_transition/page_transition.dart';

class Login extends StatefulWidget {
  final Function()? onTap;

  const Login({Key? key, required this.onTap}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool _isDisposed = false;
  // text editing controllers
  final resetemailController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isPasswordVisible = false;

  //detect selection of a text field 
  //to allow for color change
  //create focus nodes for each text field
  FocusNode _emailFocusNode = FocusNode();
  FocusNode _passwordFocusNode = FocusNode();
  FocusNode _rpasswordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(_onFocusChange);
    _passwordFocusNode.addListener(_onFocusChange);
    _rpasswordFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _isDisposed = true;
    //remove listeners
    _emailFocusNode.removeListener(_onFocusChange);
    _passwordFocusNode.removeListener(_onFocusChange);
    _rpasswordFocusNode.removeListener(_onFocusChange);
    //dispose listeners
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _rpasswordFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      // Empty setState to trigger a rebuild to update the label color
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

  // sign user in method
  void signUserIn() async {
    // show loading circle
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    // sign in with provided email and password
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );     
      Navigator.pop(context); // Close the loading circle dialog
      // show notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Redirecting. Please wait!')),
      );
      // Only navigate if the widget is not disposed
      if (mounted) {
        //Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Home()));
        //navigate to the Home Screen using right to left transition which is more visually appealing
        Navigator.push(context, PageTransition(type: PageTransitionType.rightToLeft, child: Home(), isIos: false));
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); // Close the loading circle dialog
      showErrorMessage(e.code);
    }
  }

  //send reset password link via email
  Future forgotPass() async{
    try{
      //send reset link to email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: resetemailController.text.trim());
      //return to login screen
      Navigator.pop(context);
      //check spam or inbox folder NOTIFICATION   
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Success! Check your email...')),
      );   
    } on FirebaseAuthException catch(e){
      //show error message
      showErrorMessage(e.toString());
    }
  }

  // Function to show the bottom sheet
  void _showBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Container(
            height: 1100, //increase or reduce the size of the bottom sheet
            decoration: BoxDecoration(
              color: Colors.white, //Color.fromARGB(255, 17, 168, 22).withOpacity(0.1)
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Heading with bold text
                  Text(
                    'Reset password',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Image
                  Image.asset(
                    'assets/images/forgot_password.png',
                    width: 100, // Set the desired width
                    height: 100, // Set the desired height
                  ),
                  const SizedBox(height: 20),
                  // Email textfield
                  TextField(
                    controller: resetemailController,
                    obscureText: false,
                    style: TextStyle(color: Colors.black),
                    cursorColor: Colors.black,
                    focusNode: _rpasswordFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(
                        color: _rpasswordFocusNode.hasFocus ? Color.fromARGB(255, 17, 168, 22) : Colors.grey, // Change the label color based on focus
                        fontWeight: FontWeight.normal,
                        fontSize: 18,
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.auto, // Show label on focus (click)
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
                      prefixIcon: Icon(Icons.email_outlined, color: _rpasswordFocusNode.hasFocus ? Color.fromARGB(255, 17, 168, 22) : Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Reset button
                  ElevatedButton(
                    onPressed: forgotPass,
                    style: ElevatedButton.styleFrom(
                      primary: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      minimumSize: Size(150, 40),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Reset',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      clipBehavior: Clip.antiAliasWithSaveLayer, // Add this line to clip the container's content
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center( //start the screen at the centre
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Align widgets to the center
            crossAxisAlignment: CrossAxisAlignment.start, // Align widgets to the left 
            children: [
              // heading
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Row(
                  children: [
                    Text(
                      'Welcome back ',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    //shoe icon 
                    Image.asset(
                      'assets/icons/shoe_icon.png', // Replace with the path to your shoe icon
                      height: 24,
                      width: 24,
                    ),
                  ],
                ),
              ),
      
              const SizedBox(height: 10),
      
              // welcome back, you've been missed!
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Text(
                  'Enter your credentials to continue',
                  style: TextStyle(
                    color: Color.fromARGB(255, 124, 122, 122),
                    fontSize: 16,
                  ),
                ),
              ),
      
              const SizedBox(height: 50),
      
              // email textfield with email icon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: TextField(
                  controller: emailController,
                  obscureText: false,
                  style: TextStyle(color: Colors.black), // Set the default text color of the TextField
                  cursorColor: Colors.black, // Set the cursor color to black
                  focusNode: _emailFocusNode, // Set the focus node
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(vertical: 25), // Adjust the vertical padding for the desired textfield height
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
      
              const SizedBox(height: 30),
      
              // password textfield with lock icon and trailing icon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: TextField(
                  controller: passwordController,
                  obscureText: !isPasswordVisible,
                  style: TextStyle(color: Colors.black), // Set the default text color of the TextField
                  cursorColor: Colors.black, // Set the cursor color to black
                  focusNode: _passwordFocusNode, // Set the focus node
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(vertical: 25), // Adjust the vertical padding for the desired textfield height
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
              ),
      
              const SizedBox(height: 20),
      
              //forgot password opens the modal bottom sheet
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: GestureDetector(
                  //onTap: _showBottomSheet,
                  onTap: _showBottomSheet,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align to the right
                    children: [
                      SizedBox(width: 30), // Add some space to the right
                      Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: Color.fromARGB(255, 17, 168, 22), 
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      
              const SizedBox(height: 30),
      
              // sign in button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ElevatedButton(
                  onPressed: signUserIn,
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
                        'Login',
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
                    'Don\'t have an account?',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    // navigate to the register screen
                    onTap: widget.onTap,
                    child: const Text(
                      'Register',
                      style: TextStyle(
                        color: Color.fromARGB(255, 17, 168, 22),  //Color(0xFF4C79FE)
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}