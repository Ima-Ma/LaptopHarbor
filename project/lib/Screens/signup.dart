import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_flushbar/flushbar.dart';

class Signup extends StatefulWidget {
  const Signup({Key? key}) : super(key: key);

  @override
  _SignupState createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final GlobalKey<FormState> _signupKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  bool _obscurePassword = true;

  final users = FirebaseFirestore.instance.collection("users");

  Future<void> signupWithEmail() async {
    if (_signupKey.currentState!.validate()) {
      try {
        UserCredential credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
                email: emailController.text,
                password: passwordController.text);

        await users.doc(credential.user!.uid).set({
          "UserName": usernameController.text,
          "email": emailController.text,
          "role": "user"
        });

        final prefs = await SharedPreferences.getInstance();
        prefs.setBool("isLoggedin", true);
        prefs.setString("UserName", usernameController.text);
        prefs.setString("email", emailController.text);
        prefs.setString("role", "user");
        prefs.setString("id", credential.user!.uid);

        await Flushbar(
          message: "Account created! Welcome, ${usernameController.text}",
          icon: Icon(Icons.check_circle, color: Colors.white),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
          margin: EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(8),
          flushbarPosition: FlushbarPosition.TOP,
        ).show(context);

        Navigator.pushReplacementNamed(context, "/MainHome");
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> signupWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      User? user = userCredential.user;

      // Save to Firestore if new user
      final userDoc = await users.doc(user!.uid).get();
      if (!userDoc.exists) {
        await users.doc(user.uid).set({
          "UserName": user.displayName ?? "",
          "email": user.email,
          "role": "user",
        });
      }

      final prefs = await SharedPreferences.getInstance();
      prefs.setBool("isLoggedin", true);
      prefs.setString("UserName", user.displayName ?? "");
      prefs.setString("email", user.email ?? "");
      prefs.setString("role", "user");
      prefs.setString("id", user.uid);

      Navigator.pushReplacementNamed(context, "/MainHome");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Sign-In failed: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Color(0xFF539b69),
      body: Column(
        children: [
          // Green Top Section
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
                  "Create Account",
                  style: GoogleFonts.merriweather(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // White Form Section
          Expanded(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _signupKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: usernameController,
                        style: GoogleFonts.merriweather(),
                        decoration: InputDecoration(
                          labelText: "Username",
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) return "Username required";
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: emailController,
                        style: GoogleFonts.merriweather(),
                        decoration: InputDecoration(
                          labelText: "Email",
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) return "Email required";
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}')
                              .hasMatch(value)) return "Enter valid email";
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        style: GoogleFonts.merriweather(),
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) return "Password required";
                          if (value.length < 8)
                            return "Minimum 8 characters required";
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: signupWithEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF539b69),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                          ),
                          child: Text(
                            "Sign Up",
                            style: GoogleFonts.merriweather(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 15),
                      Divider(),
                      Text("OR", style: GoogleFonts.merriweather()),
                      SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: signupWithGoogle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Color(0xFF539b69)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        icon: Image.asset("assets/images/google.png", height: 24),
                        label: Text(
                          "Continue with Google",
                          style: GoogleFonts.merriweather(
                              color: Colors.black, fontWeight: FontWeight.w600),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, "/login"),
                        child: Text(
                          "Already have an account? Login",
                          style: GoogleFonts.merriweather(
                            color: Color.fromARGB(255, 234, 30, 53),
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
