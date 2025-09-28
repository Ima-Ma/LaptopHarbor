import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:project/AdminScreen/Admin.dart';
import 'package:project/AdminScreen/CustomerOrder.dart';
import 'package:project/AdminScreen/ManageProduct.dart';
import 'package:project/AdminScreen/ReplacementResponse.dart';
import 'package:project/AdminScreen/SupportReqResponse.dart';
import 'package:project/Components/Explore.dart';
import 'package:project/UserScreen/EditProfile.dart';
import 'package:project/UserScreen/MainHome.dart';
import 'package:project/Screens/Welcome.dart';
import 'package:flutter/foundation.dart';
import 'package:project/Screens/login.dart';
import 'package:project/Screens/signup.dart';
import 'package:project/UserScreen/PaymentScreen.dart';
import 'package:project/UserScreen/Replacement.dart';
import 'package:project/UserScreen/SupportRequests.dart';
import 'package:project/UserScreen/Tracking.dart';
import 'package:project/UserScreen/alldeals.dart';
import 'package:project/UserScreen/cart.dart';
import 'package:project/UserScreen/chat.dart';
import 'package:project/UserScreen/exploreproducts.dart';
import 'package:project/UserScreen/userbrands.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';
import 'firebase_options.dart';

void main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedin = prefs.getBool("isLoggedin") ?? false;
  bool isAdmin = prefs.getBool("isAdmin") ?? false;

  // Web platform registration for WebView
  if (kIsWeb) {
    WebViewPlatform.instance = WebWebViewPlatform();
  }
  runApp(MyApp(isAdmin: isAdmin, isLoggedin: isLoggedin));
}

class MyApp extends StatelessWidget {
  final bool isLoggedin, isAdmin;
  MyApp({super.key, required this.isAdmin, required this.isLoggedin});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Laptop-Harbor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // home: MainHome(),
      home: MainHome(),
      // home: Admin(),


      routes: {
        "/signup": (context) => Signup(),
        "/Admin": (context) => Admin(),
        '/login': (context) => Login(),
        "/MainHome": (context) => MainHome(),
        "/Welcome": (context) => Home(),
        "/TrackingOrder": (context) => TrackingOrder(),
        "/CustomerOrder": (context) => CustomerOrder(),
        "/ManageProduct": (context) => ManageProduct(),
        "/Replacement": (context) => Replacement(),
        "/ChatPage": (context) => ChatPage(),
        "/SupportRequests": (context) => SupportRequests(),
        "/explore": (context) => Explore(),
        "/Cart": (context) => Cart(),
        "/EditProfile": (context) => EditProfile(),
        "/deals": (context) => Alldeals(),
        "/userbrands": (context) => Userbrands(),
        "/exploreproduct": (context) => ExploreProductsPage(),
        "/ReplacementRequest": (context) => ReplacementResponse(),
        "/SupportReq": (context) => SupportReqResponse(),
        "/PaymentScreen": (context) => PaymentScreen(),



        // HomePage.routeName: (context) => const HomePage(),
        ChatPage.routeName: (context) => const ChatPage(),
      },
    );
  }
}
