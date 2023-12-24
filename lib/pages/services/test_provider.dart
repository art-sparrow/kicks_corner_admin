// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors, must_be_immutable, unused_local_variable, avoid_print, prefer_final_fields, library_private_types_in_public_api, prefer_const_constructors_in_immutables, overridden_fields, annotate_overrides, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:kickscorner_admin/pages/home.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';

class VariationProvider extends ChangeNotifier {
  // Initialize _formKey starting from 1
  //this is crucial since for loading the initial "VariationValueField" is included when the "AddVariantWithoutOption" pops up
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
    // Increment the form key index for the next instance
    //_formKeyIndex++;
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
  final VariationProvider variationProvider; // Pass the provider as a parameter

  VariationValueField({required this.onValueChanged, required this.variationProvider});

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
                //widget.onValueChanged(_controller.text);
                // Increment the click to trigger the addition of another text field
                var variationProvider = Provider.of<VariationProvider>(context, listen: false);
                variationProvider.incrementfieldClickCount();
                variationProvider.addVariationValues(variationProvider._formKeyIndex - 1, [_controller.text]);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              setState(() {
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
  //internal function for adding variation values to the _scrollViewItems List which is similar to the 
  //one adding data to the _variationValuesList in the provider
  /* void addScrollViewItems(List<String> values) {
    setState(() {
      _scrollViewItems.addAll(values);
    });
    //print the internal List just to confirm all the values were added
    print('Scrollview List: $_scrollViewItems');
  } */

  @override
  void initState() {
    super.initState();
    var variationProvider = Provider.of<VariationProvider>(context, listen: false);
    // Clear the keys list for each new instance
    variationProvider._fieldKeysList.clear();
    // Reset fieldClickCount to 1 so that each instance starts with 1 textfield by default
    variationProvider._fieldClickCount = 1;
    // Initialize a new key for each instance of the widget
    variationProvider._fieldKeysList.add([GlobalKey<_VariationValueFieldState>()]);
  }

  @override
  Widget build(BuildContext context) {
    var variationProvider = Provider.of<VariationProvider>(context);

    // Get the index to identify the current form
    int index = variationProvider._formKeyIndex - 1;

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
              //doneClickCounter is incremented from 0 onwards so that we can extract data from the right List in _variationList.
              //(var item in variationProvider.variationList[variationProvider.doneClickCounter]) prints correctly based on the counter, 
              //but it resets the state of the previous instance such that if the previous instance has a state of "Colors, Blue, Green, Black, Grey" 
              //clicking "done" would update the doneClickCounter and show the next List "[Sizes, 41, 42, 43, 44]", but the previous instance would also change to show this new List.
              //Ultimately this is a visualization bug, and clicking "+ Add Product Without Option" would show that the 2 variants were correctly stored 
              // in this fashion --> [[Colors, Blue, Green, Black, Grey], [Sizes, 41, 42, 43, 44]]. For this reason I am commenting the code below, and displaying the entire variationList 
              //for a user to see exactly what they have added to the list. In other words, the instances would display the entire variation List showing the added data.

              /* if (variationProvider.doneClickCounter >= 0 &&
                  variationProvider.doneClickCounter < variationProvider.variationList.length) ...[
                for (var item in variationProvider.variationList[variationProvider.doneClickCounter])
                  Container(
                    padding: EdgeInsets.all(8.0),
                    margin: EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(item),
                  ),
              ], */

              //This approach correctly shows all the data stored in the _variationList. The main difference is each instance of "done" shows the entire variationList at the current moment.
              //The first instance would show "[Colors, Blue, Green, Black, Grey]", but adding the second instance will display an entire list in both instances with the updated data in 
              //this format "[Colors, Blue, Green, Black, Grey], [Sizes, 41, 42, 43, 44]" The advantage is this is visualization bug, and does not affect the data stored in the "_variationList" 
              // which correctly stored data from every instance in a List.
              /* for (var variationData in variationProvider.variationList)
                for (var item in variationData)
                  Container(
                    padding: EdgeInsets.all(8.0),
                    margin: EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(item),
                  ), */
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
                  value: variationProvider.selectedVariationName,
                  onChanged: (newValue) {
                    // update the selected variation name
                    variationProvider.setSelectedVariationName(newValue);
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
                  itemCount: variationProvider.fieldClickCount,
                  itemBuilder: (context, fieldIndex) {
                    return VariationValueField(
                      onValueChanged: (value) {
                        // pass data to the _variationValuesList using setState
                        setState(() {
                          // Add the variation value to _variationValuesList
                          variationProvider.addVariationValues(index, [value]);
                        });
                      },
                      variationProvider: variationProvider, // Pass the provider
                    );
                  },
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  //black button so that it looks different from the final one
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
                    //Neglecting the delayed resulted in "addVariations" List returning a blank list
                    Future.delayed(Duration(milliseconds: 50), () {
                      if (variationProvider.variationValuesList.isNotEmpty &&
                          variationProvider.selectedVariationName != null) {
                        //add variation values to the _scrollviewItems List
                        print('Variation Values List: ${variationProvider.variationValuesList}');
                        _scrollViewItems.addAll(variationProvider.variationValuesList);
                        //add the variation name and variation values to the _variationList using "addVariations()"
                        variationProvider.addVariations(
                          variationProvider.selectedVariationName!,
                          variationProvider.variationValuesList,
                        );
                        // variationProvider.variationValuesController.clear();
                        //show success message in scaffold
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Success! Variation Added...')),
                        );
                        //reveal the variationList in a single child scrollview
                        setState(() {
                          isDoneClicked = true; // Set the flag when "Done" is clicked
                          variationProvider.incrementDoneClickCounter(); //increment the _doneClickCounter to ensure we always point to the correct List in _variationList
                        });
                      }else{
                        //error message
                        //show success message in scaffold
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

//main class that calls other classes to add widgets to the screen dynamically
class AddVariations extends StatefulWidget {
  
  @override
  State<AddVariations> createState() => _AddVariationsState();
}

class _AddVariationsState extends State<AddVariations> {
  // Declare variationProvider so that you can use it in the AddVariations class to increment the _formkeyIndex
  late VariationProvider variationProvider;
  //control the display of widgets based on isChecked
  bool isChecked = false;
  //create a list of widgets which will keep track of the added option or variation widgets
  List<Widget> optionWidgets = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Initialize variationProvider 
    variationProvider = Provider.of<VariationProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Image.asset(
                'assets/icons/shoe_icon.png',
                width: 70,
                height: 70,
              ),
              const SizedBox(height: 20),
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
                      //variationProvider._formKeyIndex++;
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
              //Uncomment this ElevatedButton to see or check the status of the variationList
              ElevatedButton(
                //rounded elevated button
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 17, 168, 22), // button color
                  foregroundColor: Colors.white, // text color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                //print current items in the variation list using provider
                onPressed: (){
                  //selected variationName
                  print('Variation Name: ${Provider.of<VariationProvider>(context, listen: false).selectedVariationName}');
                  //variationValuesList
                  print('Variation Values: ${Provider.of<VariationProvider>(context, listen: false).variationValuesList}');
                  //final variationList
                  print('Variation List: ${Provider.of<VariationProvider>(context, listen: false).variationList}');
                  //show the variationList to the user
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Variation List: ${Provider.of<VariationProvider>(context, listen: false).variationList}')),
                  );
                }, 
                child: Text('Add Product'),
              ), 
            ],
          ),
        ),
      ),
    );
  }
}
