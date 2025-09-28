import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:google_fonts/google_fonts.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GlobalKey<FormState> _loginkey = GlobalKey<FormState>();
  final TextEditingController EmailController = TextEditingController();
  final TextEditingController PasswordController = TextEditingController();
  final users = FirebaseFirestore.instance.collection("users");
  bool _obscurePassword = true;

  void LoginUser() async {
    if (_loginkey.currentState!.validate()) {
      try {
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: EmailController.text,
          password: PasswordController.text,
        );

        String uid = credential.user!.uid;
        DocumentSnapshot userData = await users.doc(uid).get();
        Map<String, dynamic> userDetails = userData.data() as Map<String, dynamic>;

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool("isLoggedin", true);
        prefs.setString("role", userDetails["role"]);
        prefs.setString("UserName", userDetails["UserName"]);
        prefs.setString("id", uid);
        prefs.setString("email", userDetails["email"]);

        await Flushbar(
          message: "Signed in! ${EmailController.text}",
          icon: Icon(Icons.check_circle, color: Colors.white),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
          margin: EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(8),
          flushbarPosition: FlushbarPosition.TOP,
        ).show(context);

        if (userDetails["role"] == "admin") {
          Navigator.pushReplacementNamed(context, "/Admin");
        } else {
          Navigator.pushReplacementNamed(context, "/MainHome");
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = "Login failed";
        if (e.code == 'user-not-found') {
          errorMessage = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Wrong password provided.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: TextStyle(color: Colors.red)),
            backgroundColor: Colors.black,
          ),
        );
      }
    }
  }

  void forgotPassword() async {
    if (EmailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Enter your email first")),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: EmailController.text.trim());

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Password Reset", style: GoogleFonts.merriweather()),
          content: Text("Check your email to reset your password.", style: GoogleFonts.merriweather()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK", style: GoogleFonts.merriweather()),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor:Color(0xFF539b69) ,
      body: Column(
        children: [
          // Top 30% Green Section
          Container(
            height: size.height * 0.3,
            width: double.infinity,
            color: Color(0xFF539b69),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/images/main.png", height: 80),
                SizedBox(height: 10),
                Text(
                  "Login Account",
                  style: GoogleFonts.merriweather(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Bottom 70% White Form Section
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: SingleChildScrollView(
                child: Form(
                  key: _loginkey,
                  child: Column(
                    children: [
                      SizedBox(height: 10),
                      TextFormField(
                        controller: EmailController,
                        style: GoogleFonts.merriweather(),
                        validator: (value) {
                          if (value!.isEmpty) return "Email is required";
                          if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-z]+\.[a-z]+$').hasMatch(value)) {
                            return "Invalid email";
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: PasswordController,
                        obscureText: _obscurePassword,
                        style: GoogleFonts.merriweather(),
                        validator: (value) {
                          if (value!.isEmpty) return "Password is required";
                          if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$').hasMatch(value)) {
                            return "Use upper, lower, number & special char";
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: forgotPassword,
                          child: Text(
                            "Forgot Password?",
                            style: GoogleFonts.merriweather(
                              color: Color.fromARGB(255, 234, 30, 53),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF539b69),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: LoginUser,
                          child: Text(
                            "Login Now",
                            style: GoogleFonts.merriweather(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, "/signup"),
                        child: Text(
                          "New User? Create Account",
                          style: GoogleFonts.merriweather(
                            fontSize: 15,
                            color:Color.fromARGB(255, 234, 30, 53),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        
        
        ],
      ),
    );
  }
}
