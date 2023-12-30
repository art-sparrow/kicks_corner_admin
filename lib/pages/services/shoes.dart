// ignore_for_file: unused_local_variable, prefer_const_constructors, unused_field, prefer_final_fields

//import 'package:kickscorner_admin/services/viewshoe.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kickscorner_admin/pages/models/view_product.dart';
import 'package:page_transition/page_transition.dart';

class Shoes extends StatefulWidget {
  const Shoes({Key? key}) : super(key: key);

  @override
  State<Shoes> createState() => _ShoesState();
}

class _ShoesState extends State<Shoes> {
  //This code fetches the products based on the selected category
  //A more advanced approach would be fetching data using pagination/batches to reduce database read costs
  
  //String? _profilePictureUrl;
  String? _currentUserId; //each user has a unique id on firestore which we can store here
  String? _username; //store the current username stored in "name" on Firestore
  String _selectedCategory = 'Nike'; // Set 'Nike' as the default selected category

  @override
  void initState() {
    super.initState();
    _initializeCurrentUser();
  }
  
  Future<void> _initializeCurrentUser() async {
    //fetch admin's username which will be displayed alongside the salutation text on the homescreen
    //fetch admin's current user id and update the "_currentUserId" variable
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
          //_profilePictureUrl = snapshot.docs[0].data()['imageUrl'];
          _username = snapshot.docs[0].data()['name'];
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

  //Fetch all products based on the selected category
  Future<List<DocumentSnapshot>> _fetchProductsByCategory(String category) async {
    //fetch data from the "products" collection
    Query query = FirebaseFirestore.instance.collection('products');

    //fetch products where Firestore's "brandname" is equal to the selected "category"
    //There was an inital "All" category that fetched products from all the categories.
    //At the moment that category is redacted since it is better to categorize products
    if (category != 'All') {
      query = query.where('brandname', isEqualTo: category);
    }

    final snapshot = await query.get();
    return snapshot.docs;
  }

  //change or update the selected category
  void _changeCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  //greet the user based on the current time
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 18) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  //build a menu/category widget with a thin grey outline border that changes to green when selected. 
  //Additionally, display a brand logo at the center of the outline border
  Widget _buildCategoryItem(String category, String logoPath) {
    bool isSelected = _selectedCategory == category;

    return GestureDetector(
      //change the category name onTap
      onTap: () {
        _changeCategory(category);
      },
      child: Padding(
        padding: EdgeInsets.all(5),
        child: Container(
          width: 90, // outline border width
          height: 45, // outline border height
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Color.fromARGB(255, 17, 168, 22) : Colors.grey,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Image.asset(
              logoPath,
              width: 40, // logo width
              height: 40, // logo height
            ),
          ),
        ),
      ),
    );
  }

  //implement the category/menu and products display logic
  @override
  Widget build(BuildContext context) {
    //greeting variable that is based on the time
    final greeting = _getGreeting();
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(10.0),//ensure the content does not touch the edges of the screen
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //show a greeting text on one line below the appbar
            Text(
              '$greeting $_username.',
              style: TextStyle(
                fontSize: 20,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            //brands text
            Text(
              'Brands',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
                fontWeight: FontWeight.normal,
              ),
            ),
            SizedBox(height: 10),
            // Show a horizontal menu with shoe brand icons that a user can select 
            // and the data will be populated on card views in a single child scrollview
            //pass the new category in the "_changeCategory" function which will fetch the new products 
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryItem('Nike', 'assets/images/nike_logo.png'),
                  // Build all categories in order
                  _buildCategoryItem('Air Jordan', 'assets/images/air_jordan_logo.png'),
                  _buildCategoryItem('New Balance', 'assets/images/new_balance_logo.png'),
                  _buildCategoryItem('Vans', 'assets/images/vans_logo.png'),
                  _buildCategoryItem('Puma', 'assets/images/puma_logo.png'),
                  _buildCategoryItem('Adidas', 'assets/images/adidas_logo.png'),
                  _buildCategoryItem('Converse', 'assets/images/converse_logo.png'),
                  _buildCategoryItem('Alexander McQueen', 'assets/images/alex_mcqueen_logo.png'),
                  _buildCategoryItem('Extras', 'assets/images/extras_logo.png'),
                ],
              ),
            ),
            SizedBox(height: 20),
            //sneakers text
            Text(
              'Products',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
                fontWeight: FontWeight.normal,
              ),
            ),
            SizedBox(height: 10),
            //display the products in the selected menu
            FutureBuilder<List<DocumentSnapshot>>(
              future: _fetchProductsByCategory(_selectedCategory),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final products = snapshot.data!;
                  if (products.isEmpty) {
                    return Container();//return an empty container if no products match the selected category
                  }

                  // Update the _lastDocument with the last fetched document in the current page
                  //_lastDocument = products[products.length - 1];

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final productPrice = product['cost'];
                      final description = product['description'];
                      final productName = product['name'];
                      final productImages = List<String>.from(product['pictures']); // Convert the list of images to a List<String>
                      //fetch variations map from "variation" in Firestore and convert it to a dynamic List 
                      //Here's how it is stored in variations --> [{Colors: [Triple Black]}, {Sizes: [41, 42, 43, 44]}]
                      final variations = product['variation'] as List<dynamic>;

                      return GestureDetector(
                        onTap: () {
                          //print the variations List to ensure data is stored correctly.
                          //print(variations);
                          // Handle product selection/tapping by passing product information to a model --> ViewProductScreen()
                          //pass brandName, productName, cost, description, variationMap, productPictures as productImages
                          Navigator.push(context, PageTransition(
                            type: PageTransitionType.rightToLeft,
                            child: ViewProductScreen(
                              productName: productName,
                              productPrice: productPrice,
                              description: description,
                              productImages: productImages,
                              variations: variations, 
                            ), 
                            isIos: false)
                          );
                        },
                        //cardview showing the shoe/product picture, product name, price and shopping cart icon
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  //product picture --> 1st picture in the list
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(10),
                                        topRight: Radius.circular(10),
                                      ),
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: Image.network(
                                          productImages[0], // Use the first image URL from the list
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  //product name
                                  Align(
                                    alignment: Alignment.center, //Alignment.centerLeft
                                    child: Padding(
                                      padding: EdgeInsets.all(10),
                                      child: Text(
                                        '$productName',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                  //product cost or price
                                  Align(
                                    alignment: Alignment.center, //Alignment.centerLeft
                                    child: Padding(
                                      padding: EdgeInsets.only(left: 10, right: 10, bottom: 10),
                                      child: Text(
                                        'KES. $productPrice',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              //shopping cart icon positioned at the top-right
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Icon(
                                  Icons.shopping_cart_outlined,
                                  color: Colors.black,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');//error fetching products
                } else {
                  return Container();//loading indicator or white container
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}