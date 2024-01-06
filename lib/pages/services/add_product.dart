// ignore_for_file: unnecessary_null_comparison, prefer_final_fields, prefer_const_constructors, use_build_context_synchronously, non_constant_identifier_names, sized_box_for_whitespace, avoid_unnecessary_containers, prefer_for_elements_to_map_fromiterable

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart'; //provider for adding variants
import 'package:kickscorner_admin/pages/home.dart';

class ProductVariationProvider extends ChangeNotifier {
  // Initialize _formKey starting from 1
  //this is crucial since the first or initial "VariationValueField" is included when the "AddVariantWithoutOption" pops up
  //if you set it 0 the "AddVariantWithoutOption" won't include the textfield and the user won't add Variant Values
  int _formKeyIndex = 1;
  // Updated _fieldKeys to manage keys for each form
  List<List<GlobalKey<_VariationValueFieldState>>> _fieldKeysList = [];
  
  //Keep track of the number of "+" icon button clicks 
  int _fieldClickCount = 1;

  // Getter for fieldClickCount
  int get fieldClickCount => _fieldClickCount;

  // Increment fieldClickCount
  void incrementfieldClickCount() {
    _fieldClickCount++;
    notifyListeners();
  }

  // Counter to track the number of "Done" button clicks
  int _doneClickCounter = -1;

  // Getter for doneClickCounter
  int get doneClickCounter => _doneClickCounter;

  // Increment doneClickCounter
  void incrementDoneClickCounter() {
    _doneClickCounter++;
    notifyListeners();
  }

  //store the variation name
  String? selectedVariationName;
  //store the variation values
  TextEditingController variationValuesController = TextEditingController();
  
  // variationvalueslist
  List<String> _variationValuesList = [];
  //final list containing the variation names and variation values
  List<List<String>> _variationList = [];

  // getters for viewing data stored in the lists
  //get all the currently stored variation values
  List<String> get variationValuesList => _variationValuesList;
  //get the current data stored in the _variationList
  List<List<String>> get variationList => _variationList;

  // get the next form key to load a subsequent textfield
  GlobalKey<_VariationValueFieldState> getNextFormKey() {
    var key = GlobalKey<_VariationValueFieldState>();
    _fieldKeysList.add([key]);
    return key;
  }

  //add variation names or values to the _variationValuesList
  void addVariationValues(int index, List<String> values) {
    _variationValuesList.addAll(values);

    // Ensure that the index exists in _fieldKeysList
    while (_fieldKeysList.length <= index) {
      _fieldKeysList.add([]);
    }

    _fieldKeysList[index].add(getNextFormKey());
    notifyListeners();
  }

  //add variationValuesList and variationName to the _variationList
  //example: addVariations("Color", ["white", "black", "red", "green", "blue"])
  //will be added to the _variationList as ["Color", "white", "black", "red", "green", "blue"] 
  //after all the data is copied from the variationValuesList you can safely clear the list in preparation for the next batch of information 
  //not clearing the list will result to persistence of data from the first variation to the second variation which is undesirable
  //Here's how instances of Color and Sizes will be added to the list using this function
  /* I/flutter (10096): Variation Name: Sizes
  I/flutter (10096): Variation Values: []
  I/flutter (10096): Variation List: [[Colors, Black, Blue, Grey], [Sizes, 40, 42, 43]] */
  void addVariations(String name, List<String> values) {
    // Extract items in the list values and add them to the List together with the name
    List<String> variationWithValues = [name, ...values];
    _variationList.add(variationWithValues);
    // Clear the previous Variation Values list so that the next batch of values is added to a blank list
    _variationValuesList.clear(); 
    notifyListeners();
  }

  void clearVariations() {
    _variationList.clear();
    selectedVariationName = null;
    variationValuesController.clear();
    notifyListeners();
  }

  // Function to reset the variationList
  void resetVariationList() {
    _variationList = [];
    notifyListeners();
  }

  // Add this method to set the selected variation name
  void setSelectedVariationName(String? name) {
    selectedVariationName = name;
    notifyListeners();
  }
}

//class implementation of a Variation Value textfield widget 
//to be added dynamically in the AddVariantWithoutOption class
class VariationValueField extends StatefulWidget {
  final Function(String) onValueChanged;
  final ProductVariationProvider productVariationProvider; // Pass the provider as a parameter

  VariationValueField({required this.onValueChanged, required this.productVariationProvider});

  @override
  _VariationValueFieldState createState() => _VariationValueFieldState();
}

class _VariationValueFieldState extends State<VariationValueField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Variation Value',
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              if (_controller.text.isNotEmpty) {
                // Add variation value and increment the click count to trigger the addition of another text field
                var productVariationProvider = Provider.of<ProductVariationProvider>(context, listen: false);
                productVariationProvider.incrementfieldClickCount();
                productVariationProvider.addVariationValues(productVariationProvider._formKeyIndex - 1, [_controller.text]);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              setState(() {
                //clear the text on the current textfield
                _controller.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    //dispose text controllers after use
    _controller.dispose();
    super.dispose();
  }
}

// Class to implement the AddVariant or AddOptions when the checkbox is clicked
class AddVariantWithoutOption extends StatefulWidget {
  
  @override
  State<AddVariantWithoutOption> createState() => _AddVariantWithoutOptionState();
}

class _AddVariantWithoutOptionState extends State<AddVariantWithoutOption> {
  bool isDoneClicked = false; // Track if the "Done" button is clicked
  List _scrollViewItems = []; //internal list for storing selected variation name and values

  @override
  void initState() {
    super.initState();
    var productVariationProvider = Provider.of<ProductVariationProvider>(context, listen: false);
    // Clear the keys list for each new instance
    productVariationProvider._fieldKeysList.clear();
    // Reset fieldClickCount to 1 so that each instance starts with 1 textfield by default
    productVariationProvider._fieldClickCount = 1;
    // Initialize a new key for each instance of the widget
    productVariationProvider._fieldKeysList.add([GlobalKey<_VariationValueFieldState>()]);
  }

  @override
  Widget build(BuildContext context) {
    var productVariationProvider = Provider.of<ProductVariationProvider>(context);

    // Get the index to identify the current form
    int index = productVariationProvider._formKeyIndex - 1;

    if (isDoneClicked) {
      // If "Done" is clicked, show a container with _variationList
      return Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              //extract data from the _variationList which is stored in Lists --> [[Colors, Blue, Green, Black, Grey], [Sizes, 41, 42, 43, 44]]
              //The final solution applies an internal List called "_scrollviewItems" to store the selected variation Name and variation Values. This List is purely used to show the selected variation 
              //items in a scrollview when "done" is clicked. The "_variationList" is an external equivalent of this List but it stored the data of all instances of this "AddVariantWithoutOption". For 
              //internal visualization we can rely on the "_scrollviewItems" list to show the items selected by the user. That's the solution I picked for this exercise and although it is slightly complex, 
              //it correctly serves the intended purpose of visualization.
              for (var item in _scrollViewItems)
                Container(
                  padding: EdgeInsets.all(8.0),
                  margin: EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(item),
                ),
            ],
          ),
        ),
      );
    }

    // If "Done" is not clicked, show the input fields
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  dropdownColor: Colors.white, // Set the background color
                  decoration: InputDecoration(
                    labelText: 'Variation Name',
                  ),
                  value: productVariationProvider.selectedVariationName,
                  onChanged: (newValue) {
                    // update the selected variation name
                    productVariationProvider.setSelectedVariationName(newValue);
                    //add the selected variation name to the _scrollviewItems List
                    setState(() {
                      _scrollViewItems.add(newValue);
                    });
                  },
                  items: ['Colors', 'Sizes'].map((name) {
                    return DropdownMenuItem<String>(
                      value: name,
                      child: Text(name, style: TextStyle(fontWeight: FontWeight.normal),),
                    );
                  }).toList(),
                ),
                SizedBox(height: 10.0),
                // Use a listview to print as many textfields as the number of "+" icon clicks
                ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: productVariationProvider.fieldClickCount,
                  itemBuilder: (context, fieldIndex) {
                    return VariationValueField(
                      onValueChanged: (value) {
                        // pass data to the _variationValuesList using setState
                        setState(() {
                          // Add the variation value to _variationValuesList
                          productVariationProvider.addVariationValues(index, [value]);
                        });
                      },
                      productVariationProvider: productVariationProvider, // Pass the provider
                    );
                  },
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  //black "done" button so that it looks different from the final one
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, // button color
                    foregroundColor: Colors.white, // text color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onPressed: () {
                    // Validate and add the selectedVariationName and variationValuesList to _variationList
                    //Delay the proces a bit so that the getters update the Lists
                    //Neglecting the "delayed" resulted in "addVariations" List returning a blank list
                    Future.delayed(Duration(milliseconds: 50), () {
                      if (productVariationProvider.variationValuesList.isNotEmpty &&
                          productVariationProvider.selectedVariationName != null) {
                        //add variation values to the _scrollviewItems List
                        //print('Variation Values List: ${productVariationProvider.variationValuesList}');
                        _scrollViewItems.addAll(productVariationProvider.variationValuesList);
                        //add the variation name and variation values to the _variationList using "addVariations()"
                        productVariationProvider.addVariations(
                          productVariationProvider.selectedVariationName!,
                          productVariationProvider.variationValuesList,
                        );
                        // ProductVariationProvider.variationValuesController.clear();
                        //show success message in scaffold
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Success! Variation Added...')),
                        );
                        //reveal the container with the selected variation name and values
                        setState(() {
                          isDoneClicked = true; // Set the flag when "Done" is clicked
                          productVariationProvider.incrementDoneClickCounter(); //increment the _doneClickCounter to ensure we always point to the correct List in _variationList
                        });
                      }else{
                        //show error message in scaffold
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error! Complete all fields...')),
                        );
                      }
                    });
                  },
                  child: Text('Done'),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.0),
        ],
      ),
    );
  }
}

//main screen that adds a product based on its name and also uses the ProductVariationProvider to add the variationList logic.
class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  // Declare productVariationProvider so that you can use it in the AddVariations class to increment the _formkeyIndex
  late ProductVariationProvider productVariationProvider;
  //track the state of the product variants or options checkbox
  bool isChecked = false;
  //create a list of widgets which will keep track of the added option or variation widgets
  List<Widget> optionWidgets = [];

  //keep track of the form status
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  //text editing controllers -> brand, name, price, description, category, "quantity"
  TextEditingController _brandnameController = TextEditingController();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _sellingPriceController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();

  //track the selected brandname
  String? _selectedBrand;

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
    await FirebaseFirestore.instance.collection('products').doc(productId).update({
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
        // Extract variationList data and store it in a separate variationsList [[Colors, White, Black, Green, Yellow],[Sizes, 41, 42, 43, 44]]
        //List<List<dynamic>> variationsList = Provider.of<ProductVariationProvider>(context, listen: false).variationList;
        //Since Firestore does not support the storage of nested arrays, we need to convert the variationList to a map. The map would look like this: 
        /* 
            [
              {'Colors': 'White', 'Black': 'Green', 'Green': 'Yellow'},
              {'Sizes': 41, 42: 43, 44:},
            ] 
        */
        // Extract variationList data from the provider and convert it into a list of maps as illustrated above
        // Extract variationList data and convert it into a list of maps 
        List<Map<String, dynamic>> variationsList = Provider.of<ProductVariationProvider>(context, listen: false)
            .variationList
            .map((variation) {
              String category = variation[0];
              List<dynamic> values = variation.sublist(1);
              return {
                category: values,
              };
            })
            .toList();
            
        //store product information in Firestore 'products' collection
        DocumentReference productRef = await FirebaseFirestore.instance.collection('products').add({
          'brandname':_brandnameController.text.trim(),
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'cost': _sellingPriceController.text.trim(),
          'variation': variationsList,
        });

        String productId = productRef.id;

        await _uploadProductPictures(productId);

        //Format the provider's "variationList" to avoid scenarios where adding a subsequent product includes variation data from a previous product. 
        //This way you will always have an empty "variationList" for each new product addition. Formatting the List is handled by "resetVariationList()" in the provider
        Provider.of<ProductVariationProvider>(context, listen: false).resetVariationList();

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
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Initialize productVariationProvider 
    productVariationProvider = Provider.of<ProductVariationProvider>(context);

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
                  width: 300,
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
                SizedBox(height: 10.0),
                // Conditionally add AddVariantWithoutOption based on isChecked
                if (isChecked) ...[
                  //preload the first option or variant menu
                  AddVariantWithoutOption(),
                  SizedBox(height: 10.0),
                  //load another variant or option menu when the "+ Add Another Option" is clicked
                  //wrapping with a builder rebuilds the screen and shows the newly added widget
                  ListView.builder(
                    physics: NeverScrollableScrollPhysics(), //none of the options should be scrollable
                    shrinkWrap: true,
                    itemCount: optionWidgets.length,
                    itemBuilder: (context, index) {
                      return optionWidgets[index];
                    },
                  ),
                  SizedBox(height: 10.0),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        optionWidgets.add(AddVariantWithoutOption());
                      });
                    },
                    child: Text(
                      '+ Add Another Option',
                      style: TextStyle(
                        color: Color.fromARGB(255, 17, 168, 22),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],             
                SizedBox(height: 10.0), 
                //see or check the status of the variationList               
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
                  onPressed: (){
                    //check status of the variationList
                    //selected variationName
                    /* print('Variation Name: ${Provider.of<ProductVariationProvider>(context, listen: false).selectedVariationName}');
                    //variationValuesList
                    print('Variation Values: ${Provider.of<ProductVariationProvider>(context, listen: false).variationValuesList}');
                    //final variationList
                    print('Variation List: ${Provider.of<ProductVariationProvider>(context, listen: false).variationList}');
                    //show the variationList to the user
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Variation List: ${Provider.of<ProductVariationProvider>(context, listen: false).variationList}')),
                    ); */

                    //add products to the firestore database
                    _AddProduct();
                  }, 
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
