// ignore_for_file: prefer_const_constructors, unused_field, unused_local_variable, must_be_immutable, unused_import, depend_on_referenced_packages, use_build_context_synchronously, prefer_final_fields, prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:page_transition/page_transition.dart';
//Once the map screen is integrated, the order received notification will be handled there
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kickscorner_admin/pages/services/notification_handler.dart'; //import notification handler
import 'package:kickscorner_admin/pages/home.dart';

class Cart extends StatefulWidget {
  Cart({Key? key}) : super(key: key);

  @override
  State<Cart> createState() => _CartState();
}

//create an instance of the FlutterLocalNotificationsPlugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class _CartState extends State<Cart> {
  //fetch user data
  String _currentUserId = '';
  String _username = '';
  String _phone = '';

  @override
  void initState() {
    super.initState();
    //initialize the flutterLocalNotificationsPlugin using the LocalNotification created in the "notification_handler.dart"
    LocalNotification.initialize(flutterLocalNotificationsPlugin);
  }

  @override
  void dispose() {
    // Cancel any Stream subscriptions here if you have any.
    super.dispose();
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

  //function that deletes an item from the current user's cart when the delete icon is pressed
  void deleteFromCart(String productName, String totalPrice) async {
    await FirebaseFirestore.instance
        .collection('cart')
        .where('username', isEqualTo: _username)
        .where('phone', isEqualTo: _phone)
        .where('productName', isEqualTo: productName)
        .where('totalPrice', isEqualTo: totalPrice)
        .get()
        .then((snapshot) {
      for (DocumentSnapshot doc in snapshot.docs) {
        doc.reference.delete();
      }
    });
  }

  //total price is equal to sum of all total prices and standard delivery fee
  double calculateTotalPrice(List<QueryDocumentSnapshot> cartItems) {
    double totalPrice = 0;
    double deliveryFee = 500;
    int itemCount = 0;

    for (final cartItem in cartItems) {
      final cartData = (cartItem.data() as Map<String, dynamic>);
      final totalPriceValue = double.parse(cartData['totalPrice'] ?? '0');
      final itemCountValue = cartData['Quantity'] ?? 0;

      totalPrice += totalPriceValue;
      itemCount += (itemCountValue as int);
    }

    //only add the delivery fee when the itemcount is greater than 0 - if not return 0
    //this way 0 items in the cart will also have 0 as the delivery fee
    totalPrice += (itemCount > 0 ? deliveryFee : 0);

    return totalPrice;
  }

  //add cart items to "orders" collection in Firestore and navigate to Payment screen
  void addtoOrders(List<QueryDocumentSnapshot> cartItems, BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;

    if (email != null) {
      // Fetch current user's information from admins collection based on their email.
      final userSnapshot = await FirebaseFirestore.instance
          .collection('admins')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        final userName = userSnapshot.docs[0].data()['name'];
        final userCity = userSnapshot.docs[0].data()['city'];
        final userPhone = userSnapshot.docs[0].data()['phone'];

        final currentDate = DateTime.now();

        //return snackbar error if the cart is empty
        if (cartItems.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Your cart is empty.'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

        //extract the "cart" collection data which will be added to the "orders" collection
        //items that recur are stored in separate Lists --> productName, itemCount/Quantity, selectedColor, 
        //selectedSize.
        List<String> productNames = [];
        List<int> itemCounts = [];
        List<String> selectedColors = [];
        List<String> selectedSizes = [];
        List<String> productPictures = [];
        double totalPrice = calculateTotalPrice(cartItems); //add the delivery fee as well
        //add productPicture as well

        //use a for loop to fetch the recurring items and store them in Lists
        for (final cartItem in cartItems) {
          final cartData = (cartItem.data() as Map<String, dynamic>);
          final productName = cartData['productName'];
          final itemCount = cartData['Quantity'];
          final selectedColor = cartData['selectedColor'];
          final selectedSize = cartData['selectedSize'];
          final productPicture = cartData['productPicture'];

          //add each fetched "cart" item to the "orders" Lists
          productNames.add(productName);
          itemCounts.add(itemCount);
          selectedSizes.add(selectedSize);
          selectedColors.add(selectedColor);
          productPictures.add(productPicture);
        }

        //insert all the "cart" items to the "orders" collection for the current user
        await FirebaseFirestore.instance.collection('orders').add({
          'name': userName,
          'city': userCity,
          'phone': userPhone,
          'date': currentDate,
          'productNames': productNames, // store all product names in an array
          'productPictures': productPictures, //store all product pictures in an array
          'selectedSizes': selectedSizes, //store all selected sizes in an array
          'selectedColors': selectedColors, //store all selected colors in an array
          'Quantities': itemCounts, // store all item counts in an array
          'totalPrice': totalPrice, // store the total price
          'deliveryAddress': '', //later integrate the google map for deliver address addition
          'orderStatus': 'Received', //update the status of the order to "Received" --> Preparing --> Delivering --> Delivered
        });

        //delete or clear all the "cart" collection items since they were successfully added 
        //to the "orders" collection
        await deleteCartItems();

        //show order success local notification using notification_handler.dart
        LocalNotification.showBigTextNotification(title: 'Kicks Corner Admin', body: 'Order received', flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin);

        //navigate straight to the map screen or integrate m-pesa and go to the payment screen then map screen
        //Navigator.push(context, PageTransition(type: PageTransitionType.rightToLeft, child: DeliveryAddress(), isIos: false));

        //in the mean time navigate to home screen using left to right animation
        Navigator.push(context, PageTransition(type: PageTransitionType.leftToRight, child: Home(), isIos: false));
      }
    }
  }

  //delete all cart items for the current user once the user confirms an order
  Future<void> deleteCartItems() async {
    final cartSnapshot = await FirebaseFirestore.instance
        .collection('cart')
        .where('username', isEqualTo: _username)
        .where('phone', isEqualTo: _phone)
        .get();

    for (final cartItem in cartSnapshot.docs) {
      await cartItem.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        //redirect to home page 
        leading: IconButton(
          onPressed: () {
            //Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
            Navigator.push(context, PageTransition(type: PageTransitionType.leftToRight, child: Home(), isIos: false));
          },
          icon: Icon(LineAwesomeIcons.angle_left),
          color: Colors.black,
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        //use a Future builder that returns a ListTile of all the items in the "cart" collection
        child: FutureBuilder<void>(
          future: _initializeCurrentUser(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: Container());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('cart')
                    .where('username', isEqualTo: _username)
                    .where('phone', isEqualTo: _phone)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    final cartItems = snapshot.data?.docs ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            "My Cart",
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: ListView.builder(
                              itemCount: cartItems.length,
                              padding: EdgeInsets.all(12),
                              itemBuilder: (context, index) {
                                final cartData = (cartItems[index].data() as Map<String, dynamic>);
                                final productName = cartData['productName'];
                                final productPicture = cartData['productPicture'];
                                final totalPrice = cartData['totalPrice'];
                                final itemCount = cartData['Quantity'];
      
                                //container showing each "cart" item in a ListTile
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
                                    child: ListTile(
                                      leading: Image.network(
                                        productPicture!,
                                        height: 36,
                                      ),
                                      title: Text(
                                        productName!,
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                      subtitle: Row(
                                        children: [
                                          Text(
                                            'KES. ${double.parse(totalPrice!.toString()).toStringAsFixed(2)}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          const SizedBox(width: 5),
                                          Text('($itemCount item(s))'),
                                        ],
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_rounded),
                                        onPressed: () => deleteFromCart(
                                          //delete the product where the name and total price match the current item
                                          productName!,
                                          double.parse(totalPrice!.toString()).toStringAsFixed(2),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        //bottom checkout container showing --> Total Price and checkout button
                        Padding(
                          padding: const EdgeInsets.all(36.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.black,
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Price',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'KES. ${calculateTotalPrice(cartItems).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      '(Delivery fee inclusive)',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white),
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: GestureDetector(
                                    onTap: () {
                                      //call the addtoOrders function here. Pass the cartItems and current context 
                                      //passing the current context allows us to access the 
                                      //Navigation and switch pages to the next screen
                                      addtoOrders(cartItems, context);                                   
                                    },
                                    child: Row(
                                      children: const [
                                        Text(
                                          'Checkout',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 17,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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
    );
  }
}
