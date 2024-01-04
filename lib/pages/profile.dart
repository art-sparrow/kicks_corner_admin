// ignore_for_file: prefer_const_constructors, use_build_context_synchronously, avoid_returning_null_for_void, non_constant_identifier_names, prefer_const_literals_to_create_immutables, prefer_final_fields, unused_element, sized_box_for_whitespace

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickscorner_admin/pages/auth_page.dart';
import 'package:kickscorner_admin/pages/home.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kickscorner_admin/pages/update_profile.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:page_transition/page_transition.dart';

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String _currentUserId = '';
  //controller for the reset password bottom sheet
  final resetemailController = TextEditingController();

  //focus node to change textfield color on focus
  FocusNode _rpasswordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeCurrentUser();
    _rpasswordFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    //remove listeners
    _rpasswordFocusNode.removeListener(_onFocusChange);
    //dispose listeners
    _rpasswordFocusNode.dispose();
    super.dispose();
  }

  //reset the state of the focus node 
  void _onFocusChange() {
    setState(() {
      // Empty setState to trigger a rebuild to update the label color
    });
  }

  Future<void> _initializeCurrentUser() async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // Function to show the reset password bottom sheet
  void _rPasswordBottomSheet() {
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
                    width: 80, // Set the desired width
                    height: 80, // Set the desired height
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
                      backgroundColor: Colors.black,
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        //back button
        leading: IconButton(
          onPressed: (){
            //navigate to home screen using left to right animation
            Navigator.push(context, PageTransition(type: PageTransitionType.leftToRight, child: Home(), isIos: false));
          }, 
          icon: const Icon(LineAwesomeIcons.angle_left), color: Colors.black,
        ),
        //edit profile trailing text
        actions: [
          GestureDetector(
            onTap: (){
              //navigate to update profile screen using right to left animation
              Navigator.push(context, PageTransition(type: PageTransitionType.rightToLeft, child: UpdateProfile(), isIos: false));
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0.0, 10.0, 22.0 ,0.0),
              child: Text(
              'Edit Profile',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 17, 168, 22),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    //final Storage storage = Storage();
    if (_currentUserId.isEmpty) {
      // User ID not available yet, show loading indicator
      return Center(
        child: CircularProgressIndicator(),
      );
    } else {
      // User ID available, fetch user data
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('admins')
            .doc(_currentUserId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Data is still loading, show loading indicator
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            // Error occurred or user data not found, display error message
            return Center(
              child: Text('User data not found'),
            );
          } else {
            // User data available, build Profile screen
            final userData =
                snapshot.data!.data() as Map<String, dynamic>?;
            if (userData == null) {
              return Center(
                child: Text('User data not available'),
              );
            }

            // Extract the required user data fields --> profile picture, name, email and phone
            final ProfilePictureUrl = userData['imageUrl'] as String?;
            final name = userData['name'] as String?;
            final email = userData['email'] as String?;
            final phone = userData['phone'] as String?;

            //return error if either of those values is empty or null
            if (ProfilePictureUrl == null || name == null || email == null || phone == null) {
              return Center(
                child: Text('User data is incomplete'),
              );
            }

            // Build the user Profile screen
            return SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    //stack with the profile picture at the center
                    Stack(
                      children: [
                        Container(
                          // Add circular border around the fetched image
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Color.fromARGB(255, 17, 168, 22).withOpacity(0.5), // Light green
                              width: 2.0,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundImage: ProfilePictureUrl.isNotEmpty
                                ? NetworkImage(ProfilePictureUrl)
                                : null,
                            backgroundColor: Colors.white, // white background
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Row for the star rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center, //align the row horizontally at the center
                      children: [
                        Icon(
                          Icons.star,
                          color: Color.fromARGB(255, 17, 168, 22),
                        ),
                        Text(
                          ' 5.00 Rating',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    //row with phone icon and phone number
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone_outlined, color: Colors.grey,), // Leading icon for phone
                        SizedBox(width: 8), // Add some width between the icon and text
                        Text(
                          phone,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    //row with email icon and email
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mark_email_read_outlined, color: Colors.grey,), // Leading icon for email
                        SizedBox(width: 8), // Add some width between the icon and text
                        Text(
                          email,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    //add spacing and a divider
                    const SizedBox(height: 10),
                    const Divider(thickness: 0.3), //slightly thin divider
                    const SizedBox(height: 10),
                    //change password menu widget
                    ProfileMenuWidget(
                        title: "Change password",
                        icon: Icons.lock_outline_rounded,
                        onPressed: () {
                          //reveal the password reset bottom sheet
                          _rPasswordBottomSheet();
                        },
                        endIcon: false),
                    //contact us menu widget
                    ProfileMenuWidget(
                        title: "Give us a shout",
                        icon: Icons.phone_outlined,
                        onPressed: () async {
                          //open phone and call the app manager
                          await FlutterPhoneDirectCaller.callNumber("+254743665919"); 
                        },
                        endIcon: false),
                    //slightly thin divider
                    const Divider(thickness: 0.3), 
                    const SizedBox(height: 10),
                    //sign out menu widget without trailing icon
                    ProfileMenuWidget(
                        title: "Log out",
                        icon: Icons.logout_rounded,
                        onPressed: () {
                          //call the sign out function
                          signUserOut();
                        },
                        endIcon: false),
                    //add delete account menu widget without trailing icon
                  ],
                ),
              ),
            );
          }
        },
      );
    }
  }

  // Sign out
  void signUserOut() {
    //sign out of firebase
    FirebaseAuth.instance.signOut();
    //use the authpage to redirect the user to the login screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AuthPage()),
    );
  }
}

//profile menu widget with leading icon and menu text
class ProfileMenuWidget extends StatelessWidget {
  const ProfileMenuWidget({
    super.key,
    required this.title, 
    required this.icon,
    required this.onPressed,
    this.endIcon = true
  }); 

  //use values that were passed when the ProfileMenuWidget() was called
  //It basically changes the menu's title, icon, endicon, and the associated ontap function.
  final String title;
  final IconData icon;
  final VoidCallback onPressed;
  final bool endIcon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onPressed,
      leading: Icon(icon, color: Colors.grey,),
      title: Text(title, style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w400)),
      //check if endicon was selected for this menu, otherwise ignore it or leave it as null
      trailing: endIcon? Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: Colors.grey.withOpacity(0.1),
        ),                
        child: const Icon(LineAwesomeIcons.angle_right, size: 18.0, color: Colors.grey)) : null,
    );
  }
}