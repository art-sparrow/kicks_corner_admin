// ignore_for_file: unnecessary_null_comparison, prefer_final_fields, prefer_const_constructors, use_build_context_synchronously, non_constant_identifier_names, sized_box_for_whitespace, avoid_unnecessary_containers

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:page_transition/page_transition.dart';
import 'package:kickscorner_admin/pages/home.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  //keep track of the form status
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  //text editing controllers -> name, price, description, category, quantity, alcohol%
  TextEditingController _brandnameController = TextEditingController();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _sellingPriceController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _categoryController = TextEditingController();

  //track the selected brandname
  String? _selectedBrand;
  //track the state of the product variants or options checkbox
  bool isChecked = false;

  //handle picking and storing picked pictures in a List
  List<File> _productPictures = [];
  final picker = ImagePicker();
  bool _productPicturesAdded = false; //track whether property pictures have been added

  //pick multiple product images using XFile 
  Future<void> _pickProductPictures() async {
    List<XFile>? pickedImages = await picker.pickMultiImage();
    if (pickedImages != null) {
      setState(() {
        _productPictures = pickedImages.map((image) => File(image.path)).toList();
        _productPicturesAdded = true; // Set the flag to true once pictures are added
      });
    }
  }

  //upload the picked images to firebase storage in a bucket called product_pictures
  Future<void> _uploadProductPictures(String productId) async {
    List<String> pictureUrls = [];
    for (int i = 0; i < _productPictures.length; i++) {
      Reference storageRef = FirebaseStorage.instance.ref().child('product_pictures/$productId/$i.jpg');
      await storageRef.putFile(_productPictures[i]);
      String pictureUrl = await storageRef.getDownloadURL();
      pictureUrls.add(pictureUrl);
    }
    await FirebaseFirestore.instance.collection('services').doc(productId).update({
      'pictures': pictureUrls,
    });
  }

  //add products to firestore for storage
  Future<void> _AddProduct() async {
    //only add product if the (form is complete or validated) and (pictures are added)
    if (_formKey.currentState!.validate()) {
      if (!_productPicturesAdded) {
        //ask the user to add product images
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Please add all product pictures!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
        return;
      }
      //start product insertion into firestore
      try {
        //show progress message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Adding! Please wait...')),
        );
        //store product information in Firestore 'products' collection
        DocumentReference productRef = await FirebaseFirestore.instance.collection('products').add({
          'brandname':_brandnameController.text.trim(),
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'cost': _sellingPriceController.text.trim(),
          'category': _categoryController.text.trim(),
          //add variations from the provider "_variationList" --> [[Colors, White, Black, Green, Yellow],[Sizes, 41, 42, 43, 44]]
        });

        String productId = productRef.id;

        await _uploadProductPictures(productId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product added successfully!')),
        );
        //redirect to home page using left to right transition
        //Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
        Navigator.push(context, PageTransition(type: PageTransitionType.leftToRight, child: Home(), isIos: false));
      } catch (e) {
        //show error message if an error occurs
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add product. Error: $e')),
        );
      }
    }
  }

  //function for deleting a product based on the provided name
  Future<void> deleteProductByName(String productName) async {
    //fetch the document in the firestore 'products' collection where the name is equal to productName
    //limit the fetch to only 1 document since the assumption is all products have a unique name
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('name', isEqualTo: productName)
        .limit(1)
        .get();
    //delete that document if it exists
    if (snapshot.docs.isNotEmpty) {
      final propertyDoc = snapshot.docs.first;
      await propertyDoc.reference.delete();
      //success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item was deleted')),
      );
      //redirect to home page using left to right transition
      //Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
      Navigator.push(context, PageTransition(type: PageTransitionType.leftToRight, child: Home(), isIos: false));
    } else {
      //product was not found since the name does not exist in the 'products' collection
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid item name')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appbar containing a back icon and a delete icon
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
        //delete icon on the top-right for handling product deletion requests
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                //delete product icon and its red circular dot to the right
                IconButton(
                  //call function that handles deleting of items
                  onPressed: () {
                    //pass the _nameController as a parameter to the deleteProductByName function
                    //the _nameController stores the product name written in the name textfield
                    deleteProductByName(_nameController.text.trim());
                  },
                  icon: const Icon(Icons.delete),
                  color: Colors.black,
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    top: 6,
                    right: 6,
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.red,
                    radius: 5,
                  ),
                ), 
              ],
            ),
          ),
        ],
      ),
      //implement the body with a form for adding the product and its variations(color and size)
      //ensure the page is scrollable
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(10.0),
          //Use a form to collect the product information (6 categories) which includes:
          //Brand, shoe name, selling price, description, pictures, and variations
          //A shoe can have the same name and numerous variations (colors and sizes)
          //This form allows you to specify the product information first,
          //followed by its variations.
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                // shoe icon or logo
                Image.asset(
                  'assets/icons/shoe_icon.png',
                  width: 70,
                  height: 70,
                ),
                const SizedBox(height: 20),
                //drop-down menu with brand names
                //brand names to select from are: "Adidas", "Air Jordan", "Alexander McQueen", 
                //"Converse", "New Balance", "Nike", "Puma", "Vans", and "Extras"
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Padding(
                    //padding prevents the dropdown menu from expanding 
                    //and touching the edges of the screen
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: DropdownButtonFormField<String>(
                      dropdownColor: Colors.white, // Set the background color
                      value: _selectedBrand,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedBrand = newValue;
                          _brandnameController.text = newValue ?? '';
                        });
                      },
                      items: [
                        'Adidas',
                        'Air Jordan',
                        'Alexander McQueen',
                        'Converse',
                        'New Balance',
                        'Nike',
                        'Puma',
                        'Vans',
                        'Extras',
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
                        labelText: 'Brand name',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                      //ensure a brand name was picked
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please choose the brand\'s name';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                //product name textfield
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Product name',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    //ensure a product name was provided
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter the product\'s name';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 10),
                //selling price of the product
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: TextFormField(
                    keyboardType: TextInputType.number,//digits only
                    controller: _sellingPriceController,
                    decoration: InputDecoration(
                      labelText: 'Selling price',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter the product\'s selling price';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 10),
                //description of the product
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,//larger textfield to accomodate lengthy descriptions
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    //ensure a product description is given
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter the product\'s description';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 10),
                //product pictures icon
                //show an empty container in the horizontal listview if no images are selected
                //otherwise show the images stored in the "List<File> _productPictures = [];" 
                //after the "_pickProductPictures" function is called 
                //Wrap the entire row with a singlechildscrollview whose axis is horizontal 
                //since we cannot predict the total number of products a user will pick
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // First container with the product pictures selection option
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  'Product pictures:',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _pickProductPictures,
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Color.fromARGB(255, 17, 168, 22)),
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/icons/add_picture.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Second container displaying the fetched pictures in a listview
                      Container(
                        margin: EdgeInsets.only(top: 25.0), // Add margin to move it down to the level of the circle in the first container
                        height: 80,
                        child: _productPictures.isEmpty
                            ? Container()
                            : ListView.separated(
                                scrollDirection: Axis.horizontal,
                                shrinkWrap: true,
                                itemCount: _productPictures.length,
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
                                      radius: 30, // Adjust the radius of the product picture as needed
                                      backgroundImage: FileImage(_productPictures[index]),
                                      backgroundColor: Colors.white, // white background color to be visible before the image is fetched
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.0,), 
                //Add the variations or options logic for each product
                //access the added variations using provider
                //AddVariations(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            checkColor: Colors.white,
                            activeColor: isChecked ? Color.fromARGB(255, 17, 168, 22) : Colors.black,
                            value: isChecked,
                            onChanged: (newValue) {
                              //change appearance of the checkbox between checked an unchecked
                              setState(() {
                                isChecked = newValue!; // Set isChecked to either true or false
                              });
                            },
                          ),
                          Text(
                            'This product has options like Color and Size',
                            style: TextStyle(
                              color: Color.fromARGB(255, 17, 168, 22),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),                 
                //store the property in Firestore under "properties" collection --> _AddProduct
                ElevatedButton(
                  //rounded elevated button
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 17, 168, 22), // button color
                    foregroundColor: Colors.white, // text color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onPressed: _AddProduct, //add products to the firestore database
                  child: Text('Add Product'),
                ),
              ],
            ),
          ),        
        ),
      ),
    );
  }
}
