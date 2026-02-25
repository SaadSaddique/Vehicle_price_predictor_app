import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../models/UIHelper.dart';
import '../models/UserModel.dart';
import 'home_screen.dart';
import 'login.dart';

class Signup extends StatefulWidget {
  @override
  State<Signup> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<Signup> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController cPasswordController = TextEditingController();

  bool showPassword = true;
  bool showConfirmPassword = true;

  void signup() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = cPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      UIHelper.errordialoag(
          context, "Incomplete Data" + "Please fill all the fields");
    } else if (password != confirmPassword) {
      UIHelper.errordialoag(context,
          "Password Mismatch" + "The passwords you entered do not match!");
    } else {
      try {
        UIHelper.showLoadingDialog(context, "Please wait...");
        UserCredential credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        if (credential.user != null) {
          UIHelper.showLoadingDialog(context, "Creating Account....");
          String uid = credential.user!.uid;
          UserModel newUser = UserModel(
            uid,
            "",
            email,
          );
          await FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .set(newUser.toMap());
          Navigator.popUntil(context, (route) => route.isFirst);
          UIHelper.showSnackBar(context, "Account Created Sccessfully!!");
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(
                  firebaseuser: credential.user!,
                  userModel: newUser,
                ),
              ));
        }
      } on FirebaseAuthException catch (ex) {
        UIHelper.errordialoag(context, ex.message ?? "An error occurred");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: 30,
                  ),
                  Center(
                    child: Icon(
                      Icons.directions_car,
                      size: 120,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  SizedBox(height: 30),
                  SizedBox(height: 20),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                        labelText: "Email Address",
                        suffixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15))),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: showPassword,
                    decoration: InputDecoration(
                      labelText: "Password",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15)),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            showPassword = !showPassword;
                          });
                        },
                        icon: Icon(showPassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: cPasswordController,
                    obscureText: showConfirmPassword,
                    decoration: InputDecoration(
                      labelText: "Confirm Password",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15)),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            showConfirmPassword = !showConfirmPassword;
                          });
                        },
                        icon: Icon(showConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  CupertinoButton(
                    onPressed: signup,
                    color: Colors.blue.shade700,
                    child: Text(
                      "Sign Up",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Already have an account?",
              style: TextStyle(fontSize: 16),
            ),
            CupertinoButton(
              onPressed: () {
                emailController.clear();
                passwordController.clear();
                cPasswordController.clear();
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginPage(),
                    ));
              },
              child: Text(
                "Log In",
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
