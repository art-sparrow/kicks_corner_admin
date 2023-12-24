// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:page_transition/page_transition.dart';
import 'package:kickscorner_admin/pages/home.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
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
      //write-up about Kicks Corner and its privacy policy
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About Kicks Corner',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Kicks Corner is poised to revolutionize the shoe-selling industry in Kenya. Offering access to high-quality products from renowned brands worldwide, including Adidas, Air Jordan, Alexander McQueen, Converse, New Balance, Nike, Puma, and Vans, we stand as the first app in Kenya to provide shoe deals at competitive rates. Our commitment is to bring unparalleled choices and value to shoe enthusiasts, setting a new standard in the Kenyan market.',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'At Kicks Corner, we prioritize the privacy and security of our users. Your data is held dearly, and we strictly adhere to guidelines ensuring that it is not shared with third-party entities. Trust us for a seamless and secure shoe-shopping experience, where your privacy remains a top priority.',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
