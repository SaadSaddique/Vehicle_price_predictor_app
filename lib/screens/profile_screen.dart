import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:textile_defect_app/models/UIHelper.dart';
import '../models/UserModel.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel userModel;
  final User firebaseUser;

  const ProfileScreen({
    Key? key,
    required this.userModel,
    required this.firebaseUser,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userModel.fullname ?? '';
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim() == widget.userModel.fullname) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userModel.uid)
          .update({
        "fullname": _nameController.text.trim(),
      });

      widget.userModel.fullname = _nameController.text.trim();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      UIHelper.showSnackBar(context, 'Error updating profile: $e',
          color: Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    final passwordController = TextEditingController();

    final passwordConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Confirm Password',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your password to confirm account deletion:',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[800],
                hintText: 'Password',
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.blue.shade700)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Next', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (passwordConfirmed != true) return;

    try {
      final cred = EmailAuthProvider.credential(
        email: widget.firebaseUser.email!,
        password: passwordController.text.trim(),
      );

      await widget.firebaseUser.reauthenticateWithCredential(cred);

      final finalConfirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Delete Account',
              style: TextStyle(color: Colors.white)),
          content: const Text(
            'Are you sure you want to permanently delete your account? This cannot be undone.',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  Text('Cancel', style: TextStyle(color: Colors.blue.shade700)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (finalConfirm != true) return;

      setState(() => _isLoading = true);

      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userModel.uid)
          .delete();

      await widget.firebaseUser.delete();

      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil("/login", (route) => false);
      }
    } catch (e) {
      UIHelper.showSnackBar(context, 'Account deletion failed: $e',
          color: Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
             CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue.shade700,
              child: const Icon(Icons.person, size: 80, color: Colors.white),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: const TextStyle(color: Colors.purple),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.purple),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.purple, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Email: ${widget.userModel.email}',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _updateProfile,
                icon: const Icon(Icons.update),
                label: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Update Profile',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _isLoading ? null : _deleteAccount,
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text(
                'Delete Account',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
