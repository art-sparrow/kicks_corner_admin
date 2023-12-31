// ignore_for_file: prefer_const_constructors, unused_field, use_build_context_synchronously, sort_child_properties_last, use_key_in_widget_constructors, deprecated_member_use, unused_import, library_private_types_in_public_api, prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';
import 'package:kickscorner_admin/pages/models/cart.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:page_transition/page_transition.dart';
import 'package:kickscorner_admin/pages/home.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViewProductScreen extends StatefulWidget {
  final String productName;
  final String productPrice;
  final String description;
  final List<String> productImages; //List showing productImages
  final List<dynamic> variations; //Dynamic List of variations --> [{Colors: [Triple Black]}, {Sizes: [41, 42, 43, 44]}]

  ViewProductScreen({
    required this.productName,
    required this.productPrice,
    required this.description,
    required this.productImages,
    required this.variations,
  });

  @override
  _ViewProductScreenState createState() => _ViewProductScreenState();
}

class _ViewProductScreenState extends State<ViewProductScreen> {
  //store the product quantity or count
  int itemCount = 1;
  //store user information which will be added to the order
  late String _currentUserId;
  late String _username;
  late String _phone;
  //store the selected size and color returned by the widgets
  String _selectedSize = "";
  String _selectedColor = "";

  void increaseItemCount() {
    setState(() {
      itemCount++;
    });
  }

  void decreaseItemCount() {
    if (itemCount > 1) {
      setState(() {
        itemCount--;
      });
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
      if (mounted && snapshot.docs.isNotEmpty) {
        setState(() {
          _currentUserId = snapshot.docs[0].id;
          _username = snapshot.docs[0].data()['name'];
          _phone = snapshot.docs[0].data()['phone'];
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

  //add the product to the Firestore "cart" collection
  void addtoCart() async {
    // Check if size and color are selected
    if (_selectedSize.isEmpty || _selectedColor.isEmpty) {
      // Show a SnackBar message if size or color is not selected
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Select the size and color.')),
      );
      return; // Exit the function if size or color is not selected
    }

    //fetch user data if everything checks out
    await _initializeCurrentUser();

    final currentDate = DateTime.now();
    final username = _username;
    final date = currentDate.toString();
    final productName = widget.productName;
    final productPicture = widget.productImages[0];
    final totalPrice = double.parse(widget.productPrice) * itemCount;

    //combine user data and product data to create a unique cart for the current user
    //you can add as many documents to the cart collection based on the number of products
    //added to the cart
    final cartData = {
      'username': username,
      'phone': _phone,
      'date': date,
      'productName': productName,
      'productPicture': productPicture,
      'selectedColor': _selectedColor,
      'selectedSize': _selectedSize,
      'Quantity': itemCount,
      'totalPrice': totalPrice.toStringAsFixed(2),
    };

    //add the cartData to cart
    await FirebaseFirestore.instance.collection('cart').add(cartData);

    //success message in a scaffold
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$productName was added to cart...')),
    );
    //redirect to home page using left to right transition
    //Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
    Navigator.push(context, PageTransition(type: PageTransitionType.leftToRight, child: Home(), isIos: false));
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = double.parse(widget.productPrice) * itemCount;

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
        //redirect to cart screen with right to left animation
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, PageTransition(type: PageTransitionType.rightToLeft, child: Cart(), isIos: false));
            },
            icon: Icon(Icons.shopping_cart_outlined),
            color: Colors.black,
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //container with product images in an automated scroll view
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(widget.productImages[0]),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 3),
            //bottom section with product information
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //row showing the product name and 5 star rating badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.productName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '⭐ 5.0',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey, //5.0 should be black/grey
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  //description text
                  Text(
                    widget.description,
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 10),
                  //item count with 1 as the default and least value
                  Row(
                    //ensure the row starts at the center and not left
                    mainAxisAlignment: MainAxisAlignment.center, 
                    children: [
                      Text(
                        "Quantity",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Color.fromARGB(255, 17, 168, 22)
                        ),
                      ),
                      SizedBox(width: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            onPressed: decreaseItemCount,
                            icon: Icon(Icons.remove),
                            color: Colors.black,
                          ),
                          Container(
                            width: 30,
                            alignment: Alignment.center,
                            child: Text(
                              itemCount.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 17, 168, 22),
                                fontSize: 20,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: increaseItemCount,
                            icon: Icon(Icons.add),
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ],
                  ),
                  //add quantity
                  SizedBox(height: 10),
                  //sizes text and sizes in a single childscrollview row below it.
                  //sizes in a horizontal scrollview with the first size in the List selected as the default option
                  buildSizesCardsWidget(widget.variations),
                  SizedBox(height: 5),
                  //colors text and colors in a single childscrollview row below it.            
                  //colors in a horizontal scrollview with the first color in the List selected as the default option
                  buildColorsCardsWidget(widget.variations),
                  SizedBox(height: 10),
                  //pictures title
                  Text(
                    'Pictures',
                    style: TextStyle(
                      color: Color.fromARGB(255, 17, 168, 22),
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  SizedBox(height: 5),
                  //product pictures in a horizontal scrollview
                  Container(
                    margin: EdgeInsets.all(5.0),
                    height: 80,
                    child: widget.productImages.isEmpty
                        ? Container()
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            shrinkWrap: true,
                            itemCount: widget.productImages.length,
                            separatorBuilder: (context, index) => SizedBox(width: 4.0),
                            itemBuilder: (context, index) {
                              return Container(
                                margin: EdgeInsets.symmetric(vertical: 2.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Color.fromARGB(255, 17, 168, 22),
                                    width: 1.0,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 35, // Adjust the radius of the product picture as needed
                                  backgroundImage: NetworkImage(widget.productImages[index]),
                                  backgroundColor: Colors.white, // white background color to be visible before the image is fetched
                                ),
                              );
                            },
                          ),
                    ),
                  SizedBox(height: 10),
                  //Row showing the total cost of the products and an add to cart button
                  //Increase the width of the "Add to Cart" button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "KES. ${totalPrice.toStringAsFixed(2)}",
                        style: TextStyle(
                          color: Color.fromARGB(255, 17, 168, 22),
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: ElevatedButton(
                          onPressed: addtoCart,
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(Colors.black),
                          ),
                          child: Text(
                            'Add to Cart',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  //sizes widget
  Widget buildSizesCardsWidget(List<dynamic> variations) {
    List<dynamic> sizes = _getVariationList(variations, 'Sizes');
    return _buildVariationCards(sizes, "Sizes", (selectedSize) {
      setState(() {
        _selectedSize = selectedSize;
      });
    });
  }

  //colors widget
  Widget buildColorsCardsWidget(List<dynamic> variations) {
    List<dynamic> colors = _getVariationList(variations, 'Colors');
    return _buildVariationCards(colors, "Colors", (selectedColor) {
      setState(() {
        _selectedColor = selectedColor;
      });
    });
  }

  //return a list based on the passed key --> If the key is Colors it will return the list with Colors
  //[{Colors: [Triple Black]}, {Sizes: [41, 42, 43, 44]}] will return the Colors List
  List<dynamic> _getVariationList(List<dynamic> variations, String key) {
    for (var variation in variations) {
      if (variation.containsKey(key)) {
        return variation[key];
      }
    }
    return [];
  }

  //show the title of the current List and below it build a singlechildscrollview for the items in the List.
  //Colors followed by "Triple Black"
  Widget _buildVariationCards(List<dynamic> variationList, String title, Function(String) onSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10),
        Text(
          title,
          style: TextStyle(
            color: Color.fromARGB(255, 17, 168, 22),
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: variationList.map<Widget>((variation) {
              String variationString = variation.toString();
              bool isSelected = title == "Sizes" ? _selectedSize == variationString : _selectedColor == variationString;
              return _buildVariationCard(variationString, isSelected, onSelected);
            }).toList(),
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  //build the cards showing the variations and ensure when a card is selected its fill color is green
  //and the text color is white. If a card is unselected, its fill color is transparent, border color  
  //is grey and the text color is black.
  Widget _buildVariationCard(String variation, bool isSelected, Function(String) onSelected) {
    return GestureDetector(
      onTap: () {
        onSelected(variation);
        //print the variation, selected color and size to check if the code works correctly.
        /* print('Selected Variation: $variation');
        print('Selected Size: ${_selectedSize}');
        print('Selected Color: ${_selectedColor}'); */
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color.fromARGB(255, 17, 168, 22) : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          variation,
          style: TextStyle(
            fontSize: 16,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
