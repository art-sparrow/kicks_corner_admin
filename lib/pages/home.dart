// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, library_private_types_in_public_api, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:page_transition/page_transition.dart';
//test the dynamic addition of widgets to the screen using provider
import 'package:kickscorner_admin/pages/services/test_provider.dart';
import 'package:kickscorner_admin/pages/services/add_product.dart';
import 'package:kickscorner_admin/pages/about.dart';
import 'package:kickscorner_admin/pages/services/view_users.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  //fetch the user's id and use it to fetch the profile 
  //picture and user name
  late String _currentUserId = '';
  String _currentUserImageUrl = '';
  String _currentUserName = '';

  @override
  void initState() {
    super.initState();
    _initializeCurrentUser();
  }

  @override
  void dispose() {
    // Cancel any Stream subscriptions here if you have any.
    super.dispose();
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
        if (mounted) {
          setState(() {
            _currentUserId = snapshot.docs[0].id;
          });
        }
        await _fetchUserData(); // Fetch user's data after setting the _currentUserId
      } else {
        // User data not found in Firestore
        return;
      }
    } else {
      // User not logged in or email is null
      return;
    }
  }

  Future<void> _fetchUserData() async {
    if (_currentUserId.isNotEmpty) {
      final snapshot = await FirebaseFirestore.instance
          .collection('admins')
          .doc(_currentUserId)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _currentUserImageUrl = data['imageUrl'];
            _currentUserName = data['name'];
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //define an app bar with a shopping cart icon and a drawer for the menu
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0, //let the app bar appear to be part of the screen.
        iconTheme: IconThemeData(color: Colors.black), // Set the drawer icon color to black
        actions: [ 
          //shopping bag icon with item count badge
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  onPressed: () {
                    //Navigate to cart screen
                  },
                  icon: Image.asset(
                    'assets/icons/shopping_bag.png', //custom cart icon
                    height: 25,
                    width: 25,
                    //fit: BoxFit.contain,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    top: 3,
                    right: 4,
                  ),
                  child: CircleAvatar(//show total number of items in the cart
                    backgroundColor: Color.fromARGB(255, 17, 168, 22),
                    radius: 10,
                    child: Text(
                      '10',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      //define a drawer or side menu on the homescreen
      drawer: Drawer(
        child: Container(
          color: Colors.white, // Set the background color
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    //drawer header with the profile picture, name and view profile text
                    DrawerHeader(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            margin: EdgeInsets.only(right: 16.0), // Add some spacing between the image and text
                            // Add circular border around the fetched image
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Color.fromARGB(255, 17, 168, 22).withOpacity(0.5), // Light green
                                width: 2.0,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundImage: _currentUserImageUrl.isNotEmpty
                                  ? NetworkImage(_currentUserImageUrl)
                                  : null,
                              backgroundColor: Colors.white, // Colors.white 
                            ),
                          ),
                          SizedBox(height: 8), //space between the image and the greeting text
                          //column with the greeting text and view profile text aligned vertically
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Hi, $_currentUserName 👋",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 4), // Add some spacing between the greeting text and "View profile" text
                              Text(
                                "View profile",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color.fromARGB(255, 17, 168, 22), // Light green
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      // orders screen
                      leading: Icon(Icons.access_time_rounded, color: Colors.grey, size: 25,),
                      title: Text(
                        'My Orders',
                        style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.normal),
                      ),
                      onTap: () {
                        //navigate to Orders screen
                      },
                    ),
                    ListTile(
                      // promotions screen
                      leading: Icon(Icons.discount_outlined, color: Colors.grey, size: 25,),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Promotions',
                            style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.normal),
                          ),
                          Text(
                            'Enter promo code',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      onTap: () {
                        //navigate to Promotions screen
                        //todo: implement the promotions or promo code feature 
                      },
                      trailing: Image.asset(
                        'assets/icons/new_tag.png', //new tag
                        height: 25,
                        width: 25,
                        fit: BoxFit.contain,
                      ),
                    ),
                    // add product screen
                    ListTile(
                      leading: Image.asset(
                        'assets/icons/add_product.png', //custom add product icon
                        height: 25,
                        width: 25,
                        fit: BoxFit.contain,
                      ),
                      title: Text(
                        'Add Product',
                        style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.normal),
                      ),
                      onTap: () {
                        //navigate to add product screen using right to left transition
                        Navigator.push(context, PageTransition(type: PageTransitionType.rightToLeft, child: AddProduct(), isIos: false));
                      },
                    ),
                    // add variant screen --> go to this screen to interact with the variants provider
                    // print statements are used to show you the final "_variationList" comprising of the added variants (colors and sized)
                    // In the final app, this ListTile will be commented since outside the test environment, the add variants logic should be 
                    // accessed through the add_product.dart page.
                    ListTile(
                      leading: Image.asset(
                        'assets/icons/add_product.png', //custom add product icon
                        height: 25,
                        width: 25,
                        fit: BoxFit.contain,
                      ),
                      title: Text(
                        'Add Variant',
                        style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.normal),
                      ),
                      onTap: () {
                        //navigate to test_provider to test the dynamic addition of widgets on the screen
                        Navigator.push(context, PageTransition(type: PageTransitionType.rightToLeft, child: AddVariations(), isIos: false));
                      },
                    ),
                    // view users screen
                    ListTile(
                      leading: Icon(Icons.person_search_outlined, color: Colors.grey, size: 25,),
                      title: Text(
                        'View Users',
                        style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.normal),
                      ),
                      onTap: () {
                        //navigate to view users screen
                        Navigator.push(context, PageTransition(type: PageTransitionType.rightToLeft, child: ViewUsers(), isIos: false));
                      },
                    ),
                    //Grey divider or line or boundary
                    Divider(
                      color: Colors.grey, 
                      thickness: 0.5, //Slightly Thick
                    ),
                    // support screen
                    ListTile(
                      leading: Icon(Icons.support_agent_rounded, color: Colors.grey, size: 25,),
                      title: Text(
                        'Support',
                        style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.normal),
                      ),
                      onTap: () {
                        //navigate to support screen
                      },
                    ),
                    // About screen
                    ListTile(
                      leading: Icon(Icons.info_outline_rounded, color: Colors.grey, size: 25,),
                      title: Text(
                        'About',
                        style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.normal),
                      ),
                      onTap: () {
                        //navigate to about screen
                        Navigator.push(context, PageTransition(type: PageTransitionType.rightToLeft, child: AboutScreen(), isIos: false));
                      },
                    ),
                  ],
                ),
              ),
              // Footnote aligned to the bottom center
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  alignment: Alignment.center,
                  child: Text(
                    'We value your comfort',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  //home screen
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
