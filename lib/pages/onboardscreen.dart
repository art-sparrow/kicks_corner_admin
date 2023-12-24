// ignore_for_file: sized_box_for_whitespace, prefer_const_constructors, library_private_types_in_public_api

import 'dart:async';
import 'package:flutter/material.dart';
import 'auth_page.dart';

class OnBoardScreen extends StatefulWidget {
  const OnBoardScreen({Key? key}) : super(key: key);

  @override
  _OnBoardScreenState createState() => _OnBoardScreenState();
}

class _OnBoardScreenState extends State<OnBoardScreen> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(Duration(seconds: 7), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthPage()),
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //stack with a logo at the centre, heading and subheading below the logo, and circular progress dialog at the bottom
    return Scaffold(
      backgroundColor: Colors.white, // Set the background color to white
      body: Stack(
        alignment: Alignment.center,
        children: [
          //logo showing a sneaker
          Center(
            child: Container(
              height: 300, // Set the desired height
              width: 300,  // Set the desired width
              child: Image.asset("assets/images/logo.png"),
            ),
          ),
          //heading saying "Hungry for sneakers?"
          Positioned(
            bottom: 240, // Adjust the position as needed
            child: Padding(
              padding: const EdgeInsets.all(8.0), // Add padding
              //bold text
              child: Text(
                "Hungry for Sneakers?",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),          
          //normal text saying "Explore a diverse collection of sneakers\nfor all ages and genders at Kicks Corner."
          Positioned(
            bottom: 190, //slightly below the heading
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              //using "\n" in the text adds a line break to ensure it occupies two lines
              child: Text(
                "Explore a diverse collection of sneakers\nfor all ages and genders at Kicks Corner.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          //circular progress dialog positioned at the bottom
          Positioned(
            bottom: 20,
            child: Container(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.0, //slightly thick 
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}