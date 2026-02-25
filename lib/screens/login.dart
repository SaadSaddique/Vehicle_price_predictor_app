import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:textile_defect_app/screens/forgotpassword.dart';
import 'package:textile_defect_app/screens/signup.dart';
import '../models/UIHelper.dart';
import '../models/UserModel.dart';
import 'home_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  bool showpassword = false;
  Color color = Colors.blue.shade700;

  void login() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      UIHelper.errordialoag(context, "Please fill all the fields!!!");
    } else {
      try {
        UIHelper.showLoadingDialog(context, "Please wait...");
        UserCredential credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        UIHelper.showLoadingDialog(context, "Logging in....");
        if (credential != null) {
          String uid = credential.user!.uid;

          DocumentSnapshot userdata = await FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .get();

          if (userdata.exists) {
            UserModel usermodel =
                UserModel.fromMap(userdata.data() as Map<String, dynamic>);

            Navigator.popUntil(context, (route) => route.isFirst);
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeScreen(
                    userModel: usermodel,
                    firebaseuser: credential.user!,
                  ),
                ));
          } else {
            UIHelper.errordialoag(context, "User Data Doesn't exist!!");
          }
        }
      } on FirebaseAuthException catch (ex) {
        UIHelper.errordialoag(context, ex.message.toString());
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
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 110,
                  ),
                  Center(
                    child: Icon(
                      Icons.directions_car,
                      size: 120,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: "Email Address",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15)),
                      suffixIcon: Icon(Icons.email),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: !showpassword,
                    decoration: InputDecoration(
                      labelText: "Password",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15)),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            showpassword = !showpassword;
                          });
                        },
                        icon: Icon(showpassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  CupertinoButton(
                    onPressed: login,
                    color: Colors.blue.shade700,
                    child: const Text(
                      "Log In",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0, top: 15),
                    child: TextButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ForgotPassword(),
                              ));
                        },
                        child: Text(
                          "Forgot password ?",
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold),
                        )),
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
              "Don't have an account?",
              style: TextStyle(fontSize: 16),
            ),
            CupertinoButton(
              onPressed: () {
                emailController.clear();
                passwordController.clear();
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Signup(),
                    ));
              },
              child: Text(
                "Sign Up",
                style: TextStyle(
                    fontSize: 16, color: color, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
