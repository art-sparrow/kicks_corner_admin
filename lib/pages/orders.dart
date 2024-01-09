// ignore_for_file: prefer_const_constructors, unused_field, unused_local_variable, must_be_immutable, unused_import, depend_on_referenced_packages, use_build_context_synchronously, prefer_final_fields, prefer_const_constructors_in_immutables, prefer_const_literals_to_create_immutables, unused_element, prefer_const_declarations, avoid_unnecessary_containers, sized_box_for_whitespace

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kickscorner_admin/pages/models/timeline_tile.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:page_transition/page_transition.dart';
import 'package:kickscorner_admin/pages/home.dart';
import 'package:intl/intl.dart'; //handle date conversion in the bottom sheet
//add a custom order progress timeline

class Orders extends StatefulWidget {
  Orders({Key? key}) : super(key: key);

  @override
  State<Orders> createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  //fetch user data --> for the admin app, we won't fetch data based on the current username and phone
  //because the admin should see all the orders. However, a user should only see their orders
  //and that's where we will use the _username and _phone variables. In both scenarios, orders should be 
  //organized in a descending manner based on the date
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

  //function to update the order status on Firestore
  void _updateOrderStatus(Map<String, dynamic> orderData, String newStatus) {
    // Retrieve fields to identify the current order
    final name = orderData['name'] as String;
    final phone = orderData['phone'] as String;
    final city = orderData['city'] as String;
    final orderStatus = orderData['orderStatus'] as String;
    final totalPrice = orderData['totalPrice'] as double;
    //final deliveryAddress = orderData['deliveryAddress'] as String;
    // Retrieve date as Timestamp --> if a user has more than one order on the same day 
    //this is the unique id since it stores the milliseconds
    final Timestamp dateTimestamp = orderData['date'];

    // Assuming you have a Firestore instance and a collection named 'orders'
    final firestore = FirebaseFirestore.instance;

    // Query the Firestore collection to find the document with matching fields
    firestore.collection('orders')
        .where('name', isEqualTo: name)
        .where('phone', isEqualTo: phone)
        .where('city', isEqualTo: city)
        .where('orderStatus', isEqualTo: orderStatus)
        .where('totalPrice', isEqualTo: totalPrice)
        //.where('deliveryAddress', isEqualTo: deliveryAddress)
        .where('date', isEqualTo: dateTimestamp)
        .get()
        .then((QuerySnapshot querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        // Update the 'orderStatus' field in Firestore for the first matching document
        final orderId = querySnapshot.docs.first.id;
        firestore.collection('orders').doc(orderId).update({
          'orderStatus': newStatus,
        });

        //show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order status was changed to $newStatus')),
        );
        // Close the bottom sheet after updating the order status
        Navigator.pop(context);
      } else {
        // Handle the case where no matching document is found (optional)
        //This may never run since the bottomsheet already has such an order
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No matching order was found!')),
        );
      }
    });
  }

  //show the bottomsheet where a user can view order data
  void _showBottomSheet(Map<String, dynamic> orderData) {
    //extract data from orderData
    //--> Strings (city, date, deliveryAddress, name, phone, orderStatus)
    //--> Numbers (totalPrice)
    final name = orderData['name'] as String;
    final phone = orderData['phone'] as String;
    final city = orderData['city'] as String;
    final orderStatus = orderData['orderStatus'] as String;
    //keep track of the selectedOrderStatus used to update the orderStatus. 
    //Update it each time the 'Update status' button is clicked
    String selectedOrderStatus = 'Received'; 
    final totalPrice = orderData['totalPrice'] as double;
    //fetch discountValue
    final discountValue = orderData['discountValue'] as double;
    //calculate the expectedCost --> totalPrice minus the discountValue
    final expectedCost = totalPrice - discountValue;
    //fetch the delivery address
    final deliveryAddress = orderData['deliveryAddress'] as String;
    // Retrieve date as Timestamp
    final Timestamp dateTimestamp = orderData['date'];
    // Convert Timestamp to DateTime so that you can show it on a text widget
    final DateTime date = dateTimestamp.toDate();
    //--> Arrays (Quantities, productNames, productPictures, selectedColors, selectedSizes)
    //--> Quantities is an array storing numbers, while the rest store Strings
    // Skip productPictures since it's not used in the bottom sheet
    // final productPictures = (orderData['productPictures'] as List?)?.cast<String>() ?? <String>[];
    final quantities = (orderData['Quantities'] as List?)?.cast<int>() ?? <int>[];
    final productNames = (orderData['productNames'] as List?)?.cast<String>() ?? <String>[];
    final selectedColors = (orderData['selectedColors'] as List?)?.cast<String>() ?? <String>[];
    final selectedSizes = (orderData['selectedSizes'] as List?)?.cast<String>() ?? <String>[];

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
                  // Client details section
                  //rows showing the client's name, phone, city, date
                  Row(
                    children: [
                      Text(
                        'Customer -',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 5),
                      Text(name, style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        'Phone -',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 5),
                      Text(phone, style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        'City -',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 5),
                      Text(city, style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        'Date -',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 5),
                      Text('$date', style: const TextStyle(fontSize: 15)),
                    ],
                  ),                
                  const SizedBox(height: 20),
                  // container showing the Cash order --> Background Color.fromARGB(255, 17, 168, 22).withopacity(0.1)
                  //text can be written in Color.fromARGB(255, 17, 168, 22)
                  Container(
                    width: double.infinity, // Match the width of the bottom sheet
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    margin: const EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 17, 168, 22).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.attach_money_rounded,
                          color: Color.fromARGB(255, 17, 168, 22),
                        ),
                        SizedBox(width: 10),
                        //ensure the text occupies 2-3 lines
                        Text(
                          'Cash Order - prepare Kes $expectedCost. \n You are at liberty to tip the \n courier.',
                          style: TextStyle(
                            color: Color.fromARGB(255, 17, 168, 22),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  // order progress text and timeline
                  Text(
                    'Order progress',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  //timeline
                  //an order can have the following status --> Received --> Packed --> Ready --> Shipped --> cancelled
                  _buildUpdatedTimeline(orderStatus),

                  const SizedBox(height: 10),
                  const Divider(thickness: 0.5),
                  const SizedBox(height: 20),
                  // Order details section
                  //Bold row showing order text and #KC$date "Order #KC20240105" --> timestamp including millisecond for uniqueness
                  Row(
                    children: [
                      Text(
                        'Order -',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 5),
                      Text('#KC$date', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  //Use a Listview to display all the productNames, Quantities, selectedSizes, selectedColors
                  //Assumption - all lists have an equal number of elements which are related based on their 
                  //position i.e., items at position 0 in all lists refer to a similar product and can be
                  //displayed on one line/text --> Air Max 270 (x1) - Size 41, Color Triple Black
                  Text(
                    'Items:',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: productNames.length, // Assuming all arrays have the same length
                    itemBuilder: (context, index) {
                      final productName = productNames[index];
                      final quantity = quantities[index];
                      final selectedSize = selectedSizes[index];
                      final selectedColor = selectedColors[index];

                      return Text(
                        '$productName (x$quantity) - Size $selectedSize, Color $selectedColor',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.grey),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 10),
                  const Divider(thickness: 0.5),
                  const SizedBox(height: 20),
                  // Payment details section
                  //Ensure each row occupies the entire width of the bottom sheet by wrapping the first child in
                  //each row with an expanded widget. With this approach you don't have to use width to space out
                  //the row's children.
                  //Discount, Subtotal/TotalPrice(Bold), Service fee, Delivery fee, Total(Bold), Cash/M-pesa
                  //replace the Discount with an actual Discount percentage
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Discount',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
                        ),
                      ),
                      //const SizedBox(width: 40),
                      Text('- Kes $discountValue', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Subtotal',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text('Kes $totalPrice', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Service fee',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
                        ),
                      ),
                      Text(' Kes 0', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Delivery fee',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
                        ),
                      ),
                      Text(' Added', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  //either add a very light divider or some extra space
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text('Kes $expectedCost', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Payment method',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
                        ),
                      ),
                      Text(
                        ' Cash/M-pesa',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Color.fromARGB(255, 17, 168, 22)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(thickness: 0.5),
                  const SizedBox(height: 20),
                  // Delivery address section
                  //show the delivery address --> for now you can show the city until we integrate the 
                  //googlemap 
                  Text(
                    'Delivery address',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    city,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
                  ),
                  const SizedBox(height: 10),
                  const Divider(thickness: 0.5),
                  const SizedBox(height: 20),
                  // Store details section
                  //show the "Kicks Corner" bold text followed by a short order message
                  Text(
                    'Kicks Corner',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'We deliver the most authentic apparel in town.',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
                  ),
                  const SizedBox(height: 10),
                  const Divider(thickness: 0.5),
                  const SizedBox(height: 20),
                  // Update order status information
                  //Row saying --> Order status: $orderStatus
                  //Row saying --> Update status: DropdownMenu --> Received --> Packed --> Ready --> Shipped --> cancelled
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Order status',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        orderStatus,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.normal,
                          color: orderStatus == 'Cancelled' ? Colors.red : Color.fromARGB(255, 17, 168, 22),
                        ),
                      ),
                    ],
                  ), 
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Update status',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        width: 150,
                        child: DropdownButtonFormField<String>(
                          value: selectedOrderStatus,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedOrderStatus = newValue!;
                            });
                          },
                          items: <String>['Received', 'Packed', 'Ready', 'Shipped', 'Cancelled']
                              .map<DropdownMenuItem<String>>((String value) {
                            //print('Dropdown item: $value'); // Print each dropdown item value
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  //update status button at the bottom center
                  Container(
                    alignment: Alignment.bottomCenter,
                    child: ElevatedButton(
                      onPressed: (){
                        //update orderStatus using the orderData and selectedOrderStatus
                        if (selectedOrderStatus.isNotEmpty) {
                          // Call a function to update order status on Firestore
                          _updateOrderStatus(orderData, selectedOrderStatus);                          
                        }
                        else if(selectedOrderStatus.isEmpty){
                          //ask the admin to select an order status
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error! First pick an order status from the dropdown')),
                          );
                        }
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
                            'Update status',
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

  //build the updated timeline
  //timeline should have this color --> Color.fromARGB(255, 17, 168, 22)
  //accomplished statuses should have this color --> Color.fromARGB(255, 17, 168, 22)
  //unaccomplished statuses should have this color --> Colors.grey
  //an order can have the following status --> Received --> Packed --> Ready --> Shipped --> cancelled
  //if the fetched _orderStatus is "Received" the contentsBuilder will show "Kicks Corner received your order"
  //if the fetched _orderStatus is "Packed" the contentsBuilder will show "Your order was packed"
  //if the fetched _orderStatus is "Ready" the contentsBuilder will show "Looking for a courier"
  //if the fetched _orderStatus is "Shipped" the contentsBuilder will show "Your order was shipped"
  Widget _buildUpdatedTimeline(String orderStatus) {
    bool isFirstPast = false;
    bool isSecondPast = false;
    bool isThirdPast = false;
    bool isLastPast = false;

    // Determine isPast based on orderStatus
    //true == show the timeline and indicator with dark green shade
    //false == show the timeline and indicator with light green shade
    switch (orderStatus) {
      case "Received":
        isFirstPast = true;
        break;
      case "Cancelled":
        isFirstPast = true;
        break;
      case "Packed":
        isFirstPast = true;
        isSecondPast = true;
        break;
      case "Ready":
        isFirstPast = true;
        isSecondPast = true;
        isThirdPast = true;
        break;
      case "Shipped":
        isFirstPast = true;
        isSecondPast = true;
        isThirdPast = true;
        isLastPast = true;
        break;
      // Add more cases as needed

      // Default case (handles any other status)
      default:
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: ListView(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        //Timelines --> Received, Packed, Ready, Shipped
        children: [
          // Received
          customTimelineTile(isFirst: true, isLast: false, isPast: isFirstPast, customTimelineCard: Text('Kicks Corner received your order')),
          // Packed
          customTimelineTile(isFirst: false, isLast: false, isPast: isSecondPast, customTimelineCard: Text('Your order was packed')),
          // Ready
          customTimelineTile(isFirst: false, isLast: false, isPast: isThirdPast, customTimelineCard: Text('Looking for a courier')),
          // Shipped
          customTimelineTile(isFirst: false, isLast: true, isPast: isLastPast, customTimelineCard: Text('Your order was shipped')),
        ],
      ),
    );
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
        //use a Future builder that returns a ListTile of all the items in the "orders" collection
        //contents of the orders collection --> Arrays (Quantities, productNames, productPictures, selectedColors, selectedSizes)
        //--> Strings (city, date, deliveryAddress, name, phone, totalPrice, orderStatus)
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
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    final orderItems = snapshot.data?.docs ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            "My Orders",
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
                              itemCount: orderItems.length,
                              padding: EdgeInsets.all(12),
                              itemBuilder: (context, index) {
                                final orderData = (orderItems[index].data() as Map<String, dynamic>);
                                //Arrays (Quantities, productNames, productPictures, selectedColors, selectedSizes)
                                //Strings (city, date, deliveryAddress, name, phone, totalPrice, orderStatus)
                                //for the ListTile extract --> productPictures, name, city, orderStatus
                                final productPictures = (orderData['productPictures'] as List?)?.cast<String>() ?? <String>[];
                                final orderStatus = orderData['orderStatus'] as String;
                                final name = orderData['name'] as String;
                                final city = orderData['city'] as String;
      
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
                                    //ListTile showing the productPicture, OrderStatus, client's name and client's city
                                    child: ListTile(
                                      leading: Image.network(
                                        productPictures[0], //show the first picture in the productPictures List
                                        height: 36,
                                      ),
                                      title: Text( // status --> Received, Packed, Ready, Shipped and Cancelled
                                        'Order $orderStatus',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          //change the title's text color to red if an order is cancelled. Otherwise use green.
                                          color: orderStatus == 'Cancelled' ? Colors.red : Color.fromARGB(255, 17, 168, 22),
                                        ),
                                      ),
                                      subtitle: Row(
                                        children: [
                                          Text(
                                            '$name -',
                                            style: const TextStyle(fontSize: 15),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(city, style: const TextStyle(fontSize: 15)),
                                        ],
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.keyboard_arrow_right_rounded),
                                        onPressed: () {
                                          //pass the orderData to a bottomsheet function
                                          _showBottomSheet(orderData);
                                        }
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
    );
  }
}
