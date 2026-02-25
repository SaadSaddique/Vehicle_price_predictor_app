import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:textile_defect_app/models/UIHelper.dart';
import 'package:textile_defect_app/screens/signup.dart';

class ForgotPassword extends StatefulWidget {
  ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();

  void resetPassword(String email) async {
    // Check if the email is empty
    if (email.isEmpty) {
      UIHelper.ShowSnackBar1(context, "Please enter your email first!");
      return;
    }

    try {
      // Attempt to send the password reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // Inform the user that the reset email is sent (whether the email exists or not)
      UIHelper.ShowSnackBar1(context,
          "If an account with this email exists, a password reset link has been sent.");
    } on FirebaseAuthException catch (ex) {
      // Handle FirebaseAuthException specifically
      if (ex.code == 'invalid-email') {
        // If email is invalid
        UIHelper.ShowSnackBar1(context, "Invalid email format!");
      } else {
        // Handle other errors
        UIHelper.ShowSnackBar1(
            context, ex.message ?? "An error occurred while sending the email");
      }
    } catch (e) {
      // Catch other unexpected errors
      UIHelper.ShowSnackBar1(context, "An unexpected error occurred!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              Center(
                child: Text(
                  'Password Recovery',
                  style: TextStyle(
                      color: Colors.grey.shade300,
                      fontWeight: FontWeight.bold,
                      fontSize: 28),
                ),
              ),
              SizedBox(height: 15),
              Center(
                child: Text(
                  'Enter Your Email',
                  style: TextStyle(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
              ),
              SizedBox(height: 25),
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Form(
                  key: _formKey,
                  child: TextFormField(
                    cursorColor: Colors.white,
                    controller: emailController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.person,
                        color: Colors.grey.shade300,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  // Check if form is valid
                  if (_formKey.currentState?.validate() ?? false) {
                    resetPassword(emailController.text.trim());
                  }
                },
                child: Container(
                  height: 50,
                  width: 150,
                  child: Center(
                    child: Text(
                      "Send Email",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15)),
                ),
              ),
              SizedBox(height: 80),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Do not have an account?',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Signup()),
                      );
                    },
                    child: Text(
                      ' Create',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 20, // You can adjust the font size as needed
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
