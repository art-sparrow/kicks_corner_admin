// ignore_for_file: unnecessary_null_comparison, prefer_final_fields, prefer_const_constructors, use_build_context_synchronously, non_constant_identifier_names, sized_box_for_whitespace, avoid_unnecessary_containers, prefer_for_elements_to_map_fromiterable, prefer_const_literals_to_create_immutables, unused_field

import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickscorner_admin/pages/models/cart.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:page_transition/page_transition.dart';
import 'package:kickscorner_admin/pages/home.dart';

class Promotions extends StatefulWidget {
  const Promotions({super.key});

  @override
  State<Promotions> createState() => _PromotionsState();
}

class _PromotionsState extends State<Promotions> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  //store the current user's information --> used when validating a promo code
  late String _currentUserId = '';
  String _currentUserName = '';
  String _phone = '';
  //keep track of the form status
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  //promo code text editing controllers -> discount type, discount code
  TextEditingController _discountTypeController = TextEditingController();
  TextEditingController _codeController = TextEditingController();
  //bottom sheet text editing controllers --> discount type, discount code, percentage discount, expiry date, usage limit
  TextEditingController b_discountTypeController = TextEditingController();
  TextEditingController b_codeController = TextEditingController();
  TextEditingController _percentageController = TextEditingController();
  TextEditingController _expiryDateController = TextEditingController();
  TextEditingController _usageLimitController = TextEditingController();

  //track the selected discount type in the sreen
  String? _selectedType;
  //track the selected discount type in the bottomsheet
  String? b_selectedType;

  @override
  void initState() {
    super.initState();
    //fetch user data
    _initializeCurrentUser().then((_) {
      // Call _fetchUserData only after _initializeCurrentUser is completed
      _fetchUserData();
    });
  }

  @override
  void dispose() {
    // Cancel any Stream subscriptions here if you have any.
    super.dispose();
  }

  //fetch current user's ID --> _currentUserID
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

  //fetch the current user's information --> username and phone
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
            _currentUserName = data['name'];
            _phone = data['phone'];
          });
        }
      }
    }
  }

  //add promotion to firestore for storage in the "promotions" collection
  Future<void> _AddCodeToPromotions() async {
    //ensure all promo code details were provided
    if (b_discountTypeController.text.isEmpty ||
        b_codeController.text.isEmpty ||
        _percentageController.text.isEmpty ||
        _expiryDateController.text.isEmpty ||
        _usageLimitController.text.isEmpty) {
      
      // Show an error message if any field is empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all promo code details!')),
      );
      //pop current context to reveal the error message
      Navigator.pop(context);
      return;
    }

    // Parse the expiry date text into a DateTime object --> timestamp 
    DateTime expiryDate = DateTime.parse(_expiryDateController.text);
    //start promo code insertion into firestore
    try {     
      //update the promotions collection and add the promo-code
      await FirebaseFirestore.instance.collection('promotions').add({
        'discountType': b_discountTypeController.text,
        'discountCode': b_codeController.text,
        'discountPercentage': int.parse(_percentageController.text),
        'expiryDate': expiryDate,
        'usageLimit': int.parse(_usageLimitController.text),
      });

      //show success message once the promo code is created
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Promo code created successfully!')),
      );
      //redirect to home page using left to right transition
      Navigator.push(context, PageTransition(type: PageTransitionType.leftToRight, child: Home(), isIos: false));
    } catch (e) {
      //show error message if an error occurs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create promo code. Error: $e')),
      );
    }
  }

  //add the promotion to the users/admins collection
  Future<void> _ApplyPromotionCode() async {
    //ensure all promo code details were provided
    if (_discountTypeController.text.isEmpty ||
        _codeController.text.isEmpty) {      
      // Show an error message if any field is empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all promo code details!')),
      );
      return;
    }

    //start promo code insertion into current user's firestore collection
    try {
      //check if the promo-code is valid --> it is available in "promotions" collection and is still valid to use; 
      // 1. Check if the promo code is valid and can be applied
      QuerySnapshot<Map<String, dynamic>> promoSnapshot =
          await FirebaseFirestore.instance
              .collection('promotions')
              .where('discountCode', isEqualTo: _codeController.text)
              .limit(1)
              .get();

      if (promoSnapshot.docs.isNotEmpty) {
        // Get the promo code data
        Map<String, dynamic> promoData = promoSnapshot.docs[0].data();
        DateTime expiryDate = promoData['expiryDate'].toDate();

        // 2. Check if the promo code is not expired --> only proceed if expiry date is after today
        if (expiryDate.isAfter(DateTime.now())) {
          // 3. Check if the discount type matches
          if (promoData['discountType'] == _selectedType) { //_selectedType is similar to _discountTypeController
            // 4. Check if the usage limit is not exceeded
            int currentUsage = await FirebaseFirestore.instance
                .collection('admins')
                .where('promocode', isEqualTo: _codeController.text)
                .get()
                .then((querySnapshot) => querySnapshot.size);

            if (currentUsage < promoData['usageLimit']) {
              // If all conditions are met, apply the promo code

              // Update the user's collection --> create a new promocode if the user didn't have it 
              //or update the previous promocode
              await FirebaseFirestore.instance
                  .collection('admins')
                  .doc(_currentUserId)
                  .set({'promocode': _codeController.text}, SetOptions(merge: true));

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Promo code applied successfully!')),
              );

              // Navigate to the cart screen
              Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.rightToLeft,
                  child: Cart(),
                  isIos: false,
                ),
              );
              return;
            } else {
              // Show usage limit exceeded message
              throw 'Usage Limit Exceeded';
            }
          } else {
            // Show invalid discount type message
            throw 'Invalid Discount Type';
          }
        } else {
          // Show promo code expired message
          throw 'Promo Code Expired';
        }
      } else {
        // Show promo code not found message
        throw 'Invalid Promo Code';
      }
    } catch (e) {
      //show error message if an error occurs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to apply promo code. Error: $e')),
      );
    }
  }

  //function to select the expiry date
  void _selectExpiryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.white, // Background color of the header
            backgroundColor: Colors.white, // Background color of the calendar
            textTheme: TextTheme(
              bodyText1: TextStyle(color: Colors.black), // Text color
              subtitle1: TextStyle(color: Colors.black), // Year and month text color
              headline6: TextStyle(color: Colors.black), // Day of the week text color
            ),
            colorScheme: ColorScheme.light(
              primary: Colors.black, // Selected date background color
              onPrimary: Colors.white, // Selected date text color
            ),
            buttonTheme: ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != DateTime.now()) {
      setState(() {
        _expiryDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  //build the bottom sheet where a user can create a new promo code
  void _showPromoBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      //useSafeArea: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      builder: (BuildContext context) {
        return SizedBox(
          height: 682, //occupy about 85% of available space
          child: SingleChildScrollView(//ensure the bottom sheet is scrollable
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, //center 
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // promo code heading
                  Text(
                    'New Promotion Code',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  //promo code details section --> discount type, discount code, percentage discount, expiry date, usage limit
                  //discount type --> controllers: b_discountTypeController and b_selectedType; Promo code/Referral code
                  Container(
                    width: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Padding(
                      //padding prevents the dropdown menu from expanding 
                      //and touching the edges of the screen
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: DropdownButtonFormField<String>(
                        dropdownColor: Colors.white, // Set the background color
                        value: b_selectedType,
                        onChanged: (String? newValue) {
                          setState(() {
                            b_selectedType = newValue;
                            b_discountTypeController.text = newValue ?? '';
                          });
                        },
                        items: [
                          'Promo Code',
                          'Referral Code',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(fontWeight: FontWeight.normal),
                              ),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          labelText: 'Discount type',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                        //ensure a discount type was picked
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please choose the discount\'s type';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  //discount code --> controllers: b_codeController
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: TextFormField(
                      controller: b_codeController,
                      decoration: InputDecoration(
                        labelText: 'Discount code',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                      //ensure a discount code was provided
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter the discount code';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 15),
                  //percentage discount --> controllers: _percentageController; keyboard type - numbers
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: TextFormField(
                      keyboardType: TextInputType.numberWithOptions(),
                      controller: _percentageController,
                      decoration: InputDecoration(
                        labelText: 'Percentage discount',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                      //ensure a percentage discount was provided
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter the percentage discount';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 15),
                  //usage limit --> controllers: _usageLimitController; keyboard type - numbers
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: TextFormField(
                      keyboardType: TextInputType.numberWithOptions(),
                      controller: _usageLimitController,
                      decoration: InputDecoration(
                        labelText: 'Usage limit',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                      //ensure a usage limit was provided
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter the usage limit';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 15),
                  //expiry date --> controllers: _expiryDateController
                  //calendar view
                  Text(
                    'Expiry date',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                  ),
                  const SizedBox(height: 5),
                  //date time picker --> 2024-01-31 (yyyy-mm-dd)
                  GestureDetector(
                    onTap: () => _selectExpiryDate(context),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: TextFormField(
                        controller: _expiryDateController,
                        enabled: false,
                        style: TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Pick expiry date',
                          labelStyle: TextStyle(color: Colors.black),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ),
                  ),                             
                  const SizedBox(height: 20),
                  //create code button at the bottom center
                  Container(
                    alignment: Alignment.bottomCenter,
                    child: ElevatedButton(
                      onPressed: (){
                        // Print the selected expiry date for verification --> 2024-01-31 (yyyy-mm-dd)
                        //print("Selected Expiry Date: ${_expiryDateController.text}"); 
                        //create the promo code
                        _AddCodeToPromotions();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        minimumSize: Size(200, 40),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Create code',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
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
      //appbar containing a back icon and a Create promo code text
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        //back button on the top-left for navigating to the home screen
        leading: IconButton(
          onPressed: () {
            //Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
            //navigate to the Home Screen using left to right transition which is more visually appealing
            Navigator.push(context, PageTransition(type: PageTransitionType.leftToRight, child: Home(), isIos: false));
          },
          icon: const Icon(LineAwesomeIcons.angle_left),//LineAwesomeIcons have a great look and feel
          color: Colors.black,
        ),
        actions: [
          GestureDetector(
            onTap: (){
              //create new promo/referral code in the bottom sheet
              _showPromoBottomSheet();
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0.0, 10.0, 22.0 ,0.0),
              child: Text(
              'Create Promo Code',
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
      //implement the body with a form for adding the product and its variations(color and size)
      //ensure the page is scrollable
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            //Use a form to collect the promo code data --> promo type and code
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //lord icon asset
                  Image.asset(
                    'assets/icons/promo-code.png',
                    width: 70,
                    height: 70,
                  ),
                  const SizedBox(height: 30),
                  //drop-down menu with code categories --> Promo Code or Referral Code
                  Container(
                    width: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Padding(
                      //padding prevents the dropdown menu from expanding 
                      //and touching the edges of the screen
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: DropdownButtonFormField<String>(
                        dropdownColor: Colors.white, // Set the background color
                        value: _selectedType,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedType = newValue;
                            _discountTypeController.text = newValue ?? '';
                          });
                        },
                        items: [
                          'Promo Code',
                          'Referral Code',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(fontWeight: FontWeight.normal),
                              ),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          labelText: 'Discount type',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                        //ensure a discount type was picked
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please choose the discount\'s type';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  //discount code textfield
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: TextFormField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        labelText: 'Discount code',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                      //ensure a discount code was provided
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter the discount code';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20), 
                  //apply the promo or referral code
                  ElevatedButton(
                    //rounded elevated button
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black, // button color
                      foregroundColor: Colors.white, // text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    onPressed: (){
                      //add promo code to the users/admins firestore database
                      _ApplyPromotionCode();
                    }, 
                    child: Text('Apply code'),
                  ),
                ],
              ),
            ),        
          ),
        ),
      ),
    );
  }
}
