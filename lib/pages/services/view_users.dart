// ignore_for_file: prefer_const_constructors, library_private_types_in_public_api, use_key_in_widget_constructors

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:page_transition/page_transition.dart';
import 'package:kickscorner_admin/pages/home.dart';

class ViewUsers extends StatefulWidget {
  @override
  _ViewUsersState createState() => _ViewUsersState();
}

class _ViewUsersState extends State<ViewUsers> {
  final user = FirebaseAuth.instance.currentUser;
  int totalUsers = 0;
  List<DocumentSnapshot> usersData = [];
  bool isLoading = false;
  int batchSize = 10; //data is fetched in batches

  @override
  void initState() {
    super.initState();
    getTotalUsers();
    fetchUsers();
  }

  Future<void> getTotalUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    setState(() {
      totalUsers = snapshot.docs.length;
    });
  }

  Future<void> fetchUsers() async {
    setState(() {
      isLoading = true;
    });

    QuerySnapshot snapshot;
    if (usersData.isEmpty) {
      snapshot = await FirebaseFirestore.instance
          .collection('users')
          .limit(batchSize)
          .get();
    } else {
      final lastDocument = usersData.last;
      snapshot = await FirebaseFirestore.instance
          .collection('users')
          .startAfterDocument(lastDocument)
          .limit(batchSize)
          .get();
    }

    if (snapshot.docs.isEmpty) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    setState(() {
      usersData.addAll(snapshot.docs);
      isLoading = false;
    });
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
      //fetch all users information and display it in a container showing the profile picture, name, phone number and city or town
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              Stack(
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Image.asset(
                        'assets/icons/users.png',
                        width: 60,
                        height: 60,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              Text(
                'Total users: $totalUsers',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return CircularProgressIndicator();
                  }

                  final users = usersData;

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(), //list view content should not be scrollable
                    itemCount: users.length + 1,
                    itemBuilder: (c, index) {
                      if (index < users.length) {
                        final user = users[index];
                        final imageUrl = user['imageUrl'];
                        final name = user['name'];
                        final phone = user['phone'];
                        final court = user['court'];

                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                tileColor: Colors.grey[200], //Color.fromARGB(255, 231, 230, 230) --> grey
                                leading: Container(
                                  padding: const EdgeInsets.all(8.0),
                                  width: 56,
                                  height: 56,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(28),
                                    child: imageUrl != null
                                        ? Image.network(
                                      imageUrl,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Image.asset(
                                          'assets/icons/icon.png',
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    )
                                        : Image.asset(
                                      'assets/icons/icon.png',
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      phone,
                                    ),
                                    Text(
                                      court,//town or estate stored in the firestore "users" collection
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                          ],
                        );
                      } else if (isLoading) {
                        //show a circular progress dialogue when the data is loading or being retrieved
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      } else {
                        //if no data exists just return an empty container
                        return Container();
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}