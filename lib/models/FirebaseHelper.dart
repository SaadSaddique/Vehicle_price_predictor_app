import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'UserModel.dart';

class FirebaseHelper {
  static Future<UserModel?> getUserModelById(String id) async {
    UserModel? userModel;

    DocumentSnapshot snapshot =
    await FirebaseFirestore.instance.collection("users").doc(id).get();

    if (snapshot.data() != null) {
      userModel = UserModel.fromMap(snapshot.data() as Map<String, dynamic>);
    }
    return userModel;
  }
}
