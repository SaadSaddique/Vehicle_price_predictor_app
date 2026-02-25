class UserModel {
  String? uid;
  String? fullname;
  String? email;

  UserModel(this.uid, this.fullname, this.email);

// Map to data
  UserModel.fromMap(Map<String, dynamic> map) {
    uid = map["uid"];
    fullname = map["fullname"];
    email = map["email"];
  }

// data to Map
  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "fullname": fullname,
      "email": email,
    };
  }
}
