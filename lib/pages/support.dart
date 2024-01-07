// ignore_for_file: prefer_const_constructors, unused_field, sized_box_for_whitespace, avoid_unnecessary_containers
// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kickscorner_admin/pages/about.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:page_transition/page_transition.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:kickscorner_admin/pages/home.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  //fetch the current user's info using the _initializeCurrentUser function
  //In the user's app, you should only display the current user's data. The admin
  //can view all the orders
  String _currentUserId = '';
  String _username = '';
  String _phone = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // Cancel any Stream subscriptions here if you have any.
    super.dispose();
  }

  void openWhatsApp() async {
    String whatsappNumber = '+254704275787';
    String url = 'https://wa.me/$whatsappNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      await FlutterWebBrowser.openWebPage(
        url: url,
        customTabsOptions: CustomTabsOptions(
          toolbarColor: Colors.white,
          showTitle: false,
        ),
      );
    }
  }

  Future<void> _initializeCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (email != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('admins')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        _currentUserId = snapshot.docs[0].id;
        _username = snapshot.docs[0].data()['name'];
        _phone = snapshot.docs[0].data()['phone'];
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            //navigate back to the home screen
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.leftToRight,
                child: Home(),
                isIos: false,
              ),
            );
          },
          icon: const Icon(LineAwesomeIcons.angle_left),
          color: Colors.black,
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How can we help?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Support cases',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: 10),
              //list tile with a chat icon on circular grey background, WhatsApp title and right-arrow trailing icon
              //You can also integrate the Firebase cloud messaging to have an independent chat functionality
              ListTile(
                leading: Icon(LineAwesomeIcons.what_s_app),
                title: Text(
                  'Inbox',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                  ),
                ),
                subtitle: Text(
                  'Talk to our team',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.keyboard_arrow_right_rounded, color: Colors.grey,),
                  onPressed: () {
                    //open a whatsapp conversation with one of the team leads
                    openWhatsApp();
                  }
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Get help with a recent purchase',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: 1),
              //fetch 2 most recent orders --> order by time and limit to 2.
              Container(
                height: MediaQuery.of(context).size.height * 0.3, //30% of the screen
                child: FutureBuilder<void>(
                  future: _initializeCurrentUser(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: Container());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else {
                      //fetch all orders in descending order --> newest to oldest
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('orders')
                            //.where('username', isEqualTo: _username)
                            //.where('phone', isEqualTo: _phone)
                            .orderBy('date', descending: true)
                            .limit(2)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          } else {
                            final orderItems = snapshot.data?.docs ?? [];
                            //check if the user has no order yet --> empty snapshot
                            if (orderItems.isEmpty) {
                              // Display a message for users with no orders
                              return Center(
                                child: Text(
                                  'Make your first purchase today!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 17, 168, 22),
                                  ),
                                ),
                              );
                            }
                            //if the user has an existing order(s) --> show it/them in a List view
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                //List view with 2 orders
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: ListView.builder(
                                      physics: NeverScrollableScrollPhysics(), //should not be scrollable
                                      shrinkWrap: true,//fit in the container/available space
                                      itemCount: orderItems.length,
                                      padding: EdgeInsets.all(12),
                                      itemBuilder: (context, index) {
                                        final orderData = (orderItems[index].data() as Map<String, dynamic>);
                                        //Arrays (Quantities, productNames, productPictures, selectedColors, selectedSizes)
                                        //Strings (city, date, deliveryAddress, name, phone, totalPrice, orderStatus)
                                        //for the ListTile extract --> productPictures, productNames, date, totalPrice, orderStatus
                                        final productPictures = (orderData['productPictures'] as List?)?.cast<String>() ?? <String>[];
                                        final productNames = (orderData['productNames'] as List?)?.cast<String>() ?? <String>[];
                                        // Retrieve date as Timestamp
                                        final Timestamp dateTimestamp = orderData['date'];
                                        // Convert Timestamp to DateTime so that you can show it on a text widget
                                        final DateTime date = dateTimestamp.toDate();
                                        //only show the totalPrice if the orderStatus is not "Cancelled". 
                                        //Otherwise, show the orderStatus
                                        final totalPrice = orderData['totalPrice'] as double;
                                        final orderStatus = orderData['orderStatus'] as String;
                            
                                        //container showing each "orders" in separate ListTiles
                                        return Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white, // Change background color to white
                                              borderRadius: BorderRadius.circular(15),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey.withOpacity(0.5), // Add grey drop shadow
                                                  spreadRadius: 2,
                                                  blurRadius: 5,
                                                  offset: Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            //ListTile showing the product picture, product name, order id/date, total price
                                            child: ListTile(
                                              leading: Image.network(
                                                productPictures[0], //show the first picture in the productPictures List
                                                height: 36,
                                              ),
                                              title: Text( //show the first product name in the order
                                                productNames[0],
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black) 
                                              ),
                                              subtitle: Text('#KC$date', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal, color: Colors.grey)),
                                              //show the orderStatus if it is equal to "Cancelled". Otherwise, show the totalPrice
                                              trailing: orderStatus == 'Cancelled'
                                                ? Text(
                                                    orderStatus,
                                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red),
                                                  )
                                                : Text(
                                                    'Kes $totalPrice',
                                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                                  ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      );
                    }
                  },
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Get help with something else',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: 10),
              //row showing --> About Kicks Corner, Rate the app, Using Kicks Corner
              //seperate the rows with sizedBoxes and dividers.
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'About Kicks Corner',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
                    ),
                  ),
                  //const SizedBox(width: 40),
                  IconButton(
                    onPressed: () {
                      //navigate to the About screen
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          child: AboutScreen(),
                          isIos: false,
                        ),
                      );
                    },
                    icon: const Icon(Icons.keyboard_arrow_right_rounded),
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 1),
              const Divider(thickness: 0.2),
              const SizedBox(height: 1),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Rate the app',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
                    ),
                  ),
                  //const SizedBox(width: 40),
                  IconButton(
                    onPressed: () {
                      //navigate back to playstore or appstore
                    },
                    icon: const Icon(Icons.keyboard_arrow_right_rounded),
                    color: Colors.grey,
                  ),
                ],
              ),
              /* const SizedBox(height: 1),
              const Divider(thickness: 0.2),
              const SizedBox(height: 1),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Using Kicks Corner',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
                    ),
                  ),
                  //const SizedBox(width: 40),
                  IconButton(
                    onPressed: () {
                      //navigate back to user guide screen
                    },
                    icon: const Icon(Icons.keyboard_arrow_right_rounded),
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 5),
              //Add a footnote positioned at the bottom-center saying "Made with \u2764 in Kenya"
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  alignment: Alignment.center,
                  child: Text(
                    'Made with \u2764 in Kenya',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ), */
            ],
          ),
        ),
      ),
    );
  }
}
