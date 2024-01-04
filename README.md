# kickscorner_admin

Kicks Corner is poised to revolutionize the shoe-selling industry in Kenya. Offering access to high-quality products from renowned brands worldwide, including Adidas, Air Jordan, Alexander McQueen, Converse, New Balance, Nike, Puma, and Vans, we stand as the first app in Kenya to provide shoe deals at competitive rates.

## Interview Scope

The task is then to simply develop a Flutter app that allows a user to add product variants as shown in the video. The focus is on the product options and variants so you can safely assume a product has already been added. Also, consuming a web service is out of scope. We just need the UI (User Interface) and logic for capturing product option names, values, and logic for generating the variants when a user is done entering the product options.

## Solution Screenshot and explanation
![add_variants](https://github.com/art-sparrow/kicks_corner_admin/assets/63036221/3e4dfe8c-dbcd-4170-860a-d01dee017c68)
![splashscreen](https://github.com/art-sparrow/kicks_corner_admin/assets/63036221/11b9b420-ea8e-4b26-8f16-fbaa0d07a30f)

To recreate the attached solution follow these steps: 
1. Download and install the kickscorner_admin "app-debug.apk" file using this link ( https://drive.google.com/file/d/1b4qspGB87PjbywOZyLE9jAfZIWVGIyUC/view?usp=sharing )
2. Sign up using this super key "Sn3ak3r!24". Your data, excluding the passwords, will be stored in Firebase, and you will be redirected to the home screen. 
3. Navigate to the "Add Variant" page and add two variants of your choice i.e., Colors and Sizes.
4. Click the "Add Product" button to see the added variants or options.

The solution uses a Provider to manage the state of different variants of the "AddVariantWithoutOption" widget. Here is an in-depth breakdown of the solution stored in the "test_provider.dart" file or "Add Variant" page which implements the first screenshot:

1. VariationProvider Class:

- Manages the state related to variations using the ChangeNotifier pattern.
- Keeps track of the form key index (_formKeyIndex), which represents the current form being filled out.
- Maintains a list of form keys (_fieldKeysList) for each form to manage the state of VariationValueField widgets.
- Keeps counters (_fieldClickCount and _doneClickCounter) to track the number of clicks on the "+" icon and "Done" button, respectively.
- Stores variation names, variation values, and the final variation list (_variationList).

2. VariationValueField Class:

- A stateful widget representing a text field for entering a variation value.
- Dynamically adds a new text field when the user clicks the "+" icon.
- Clicking the "delete" icon clears the text input on the current text field. 
- Updates the state of the VariationProvider when a value is added or cleared. New values are stored in a "_variationValuesList" before they are migrated to the final "_variationList" together with the "_variationName" selected by the user.

3. AddVariantWithoutOption Class:

- A stateful widget representing a form for adding variations i.e., adds one "_variationName" dropdown and "VariationValueField" text field when the checkbox is clicked.
- Allows users to select a variation name and input variation values.
- Dynamically adds more text fields for variation values based on the user's clicks on the "+" icon.
- Displays the selected variations when the "Done" button is clicked.

4. AddVariations Class:

- The main screen which is seen in the attached screenshot where users can add variations to a product. By default, it shows a checkbox that adds the "AddVariantWithoutOption" class onValueChanged, and an ElevatedButton that prints the added "Variants" or "Options" stored in the "_variationList" for the user to see.
- Uses the VariationProvider to manage state across different widgets.
- Allows users to indicate whether the product has options (e.g., colour and size) using a checkbox.
- Conditionally displays the AddVariantWithoutOption widget based on the checkbox status.
- Users can add multiple instances of AddVariantWithoutOption dynamically by clicking the "+ Add Another Option" button.
- Includes an ElevatedButton to print and check the status of the variation list.

## Projections
This solution was uploaded to this repo as-is on 25-12-2023 and its link was submitted for review on 26-12-2023. By the time you review this repo, there may be updates to the Kicks Corner app relating to other areas of the app as enunciated below:

1. Integrate the "test_provider.dart" solution in the "add_product.dart" screen. This will allow the user/admin to store product and variant information in Firestore. At the moment "add_product.dart" has the logic for adding a product, and the "test_provider.dart" provides the solution for capturing variant information. --> Successfully implemented this step (view attached "add products" video).   ![add products](https://github.com/art-sparrow/kicks_corner_admin/assets/63036221/c5d2297c-a004-4108-949c-be87a6691987)

2. Fetch and display the stored "products" on the "home.dart" in categories with a scroll view. The home screen will also add a salutation text saying "Good morning $username" or "Good evening $username" based on the time and stored "name" in Firestore. --> Successfully implemented this step (view attached pictures)
![kicks_corner_addtocart-min](https://github.com/art-sparrow/kicks_corner_admin/assets/63036221/00b7c7fc-5068-4e8a-a97e-11767075b8d9)

3. Implement a "cart.dart" screen that fetches the products added by the user to the cart. To access the "add to cart" button, a user will pick a product from the home screen and will be redirected to a "product_details.dart" screen where the current product and variant information will be viewed. The "view_product.dart" screen will also have a product counter that adds or decreases the product count which scales the price respectively. The "Add to cart" button will add the products and selected variant to the current user's cart and display the product image, quantity/product count, price and a delete button on the "cart.dart" screen. Additionally, the cart icon on the home screen will update the total number of items in the cart. On the same "cart.dart" screen there will be a checkout button that will redirect the user to a Google Map where they will specify their delivery address. --> successfully implemented this step (view attached picture)
![kicks_corner_cart](https://github.com/art-sparrow/kicks_corner_admin/assets/63036221/912fe943-c6d3-42a9-b5bb-f7c85fae2e6d)

4. Payments can be handled by integrating mpesa stk push in the app or the user can opt to pay for the products on-delivery.
5. The "profile.dart" screen will be added to allow a user to view their information, update their information, reset their password, and logout.
6. The "orders.dart" screen will be integrated to show the previous orders of a user when they click "My Orders" on the menu.
7. Integration of the local notifications to alert a user when an order is received or shipped --> successfully implemented this step (view picture attached on step 3 or cart.dart)
8. Code reviews and maintenance to ensure the app operates at maximum efficiency.

## Contact
Feel free to reach out to the developer through the email that submitted this solution in case you have any queries or suggestions regarding how to make "KicksCorner" a one-of-a-kind shoe-selling app in the Republic of Kenya. Cheers!
