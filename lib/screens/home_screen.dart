import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:textile_defect_app/models/UIHelper.dart';
import 'package:textile_defect_app/screens/login.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

import '../models/UserModel.dart';

class HomeScreen extends StatefulWidget {
  final UserModel userModel;
  final User firebaseuser;

  const HomeScreen({
    Key? key,
    required this.userModel,
    required this.firebaseuser,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedVehicleType;
  String? selectedModelYear;
  File? _image;
  List<Map<String, String>> messages = [];
  bool isLoading = false;

  final List<String> vehicleTypes = [
    'Toyota Corolla',
    'Honda Civic',
    'Suzuki Swift',
    'Toyota Camry',
    'Honda City',
    'Suzuki Alto',
    'Toyota Prius',
    'Honda Accord',
    'Suzuki Wagon R',
    'Toyota Yaris',
    'Hyundai Elantra',
    'Kia Sportage',
    'Hyundai Sonata',
    'Kia Seltos',
    'Nissan Altima',
  ];

  final List<String> modelYears = [
    '2024',
    '2023',
    '2022',
    '2021',
    '2020',
    '2019',
    '2018',
    '2017',
    '2016',
    '2015',
  ];

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800, // Optimize image size
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }

  String? _validateApiKey() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_api_key_here') {
      return 'Invalid API key. Please check your .env file.';
    }
    return null;
  }

  Future<void> _predictPrice() async {
    // Validate prerequisites
    final apiKeyError = _validateApiKey();
    if (apiKeyError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiKeyError)),
      );
      return;
    }

    if (selectedVehicleType == null) {
      UIHelper.showSnackBar(context, 'Please select a vehicle type first',
          color: Colors.red);
      return;
    }

    if (selectedModelYear == null) {
      UIHelper.showSnackBar(context, 'Please select a model year first',
          color: Colors.red);
      return;
    }

    if (_image == null) {
      UIHelper.showSnackBar(context, 'Please select an image first',
          color: Colors.red);
      return;
    }

    setState(() {
      isLoading = true;
      messages.add({
        'role': 'user',
        'content': 'Predicting price for ${selectedVehicleType!} ${selectedModelYear!}...',
      });
    });

    try {
      // Generate a unique ID for this analysis
      final String analysisId = const Uuid().v4();

      // Upload image to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('defect_images')
          .child('${analysisId}.jpg');

      await storageRef.putFile(_image!);
      final imageUrl = await storageRef.getDownloadURL();

      final bytes = await _image!.readAsBytes();
      final base64Image = base64Encode(bytes);
      final prompt = '''
You are a vehicle price prediction expert. Analyze the provided vehicle image and predict its price.

Vehicle Details:
- Vehicle Type: ${selectedVehicleType!}
- Model Year: ${selectedModelYear!}

Please analyze the image and provide the following information in a structured format:

1. Price Prediction: Estimate the current market price of this vehicle in Pakistani Rupees (PKR). Provide the price in a clear format like "PKR 2,500,000" or "Rs. 25,00,000".

2. Vehicle Condition Assessment: Based on the image, assess the visible condition of the vehicle (exterior, interior if visible, overall appearance).

3. Drawbacks/Issues: List any visible drawbacks, damages, wear and tear, or issues that would decrease the vehicle's value. Be specific about:
   - Exterior damages (scratches, dents, rust, paint issues)
   - Interior condition (if visible: seats, dashboard, wear)
   - Mechanical concerns (if visible)
   - Any other factors affecting the price negatively

4. Price Impact: Explain how these drawbacks affect the price and why the price might be lower than expected for this vehicle type and model year.

Format your response clearly, separating each section. Do not use bold formatting. Keep descriptions concise but informative.
''';

      final response = await http.post(
        Uri.parse(
            'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash-lite:generateContent?key=${dotenv.env['GEMINI_API_KEY']}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
                {
                  "inline_data": {
                    "mime_type": "image/jpeg",
                    "data": base64Image
                  }
                }
              ]
            }
          ]
        }),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final generatedText =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'];  

/*
            {
  "candidates": [
    {
      "content": {
        "parts": [
          {
            "text": "This is the generated response from the model."
          }
        ]
      }
    }
  ]
} */

        if (generatedText != null) {
          // Save to Firestore - keeping same collection name 'TextileUsers' and field name 'department'
          await FirebaseFirestore.instance.collection('TextileUsers').add({
            'userId': widget.firebaseuser.uid,
            'userName': widget.userModel.fullname,
            'userEmail': widget.userModel.email,
            'department': selectedVehicleType, // Storing vehicle type in 'department' field
            'description': selectedModelYear, // Storing model year in 'description' field
            'imageUrl': imageUrl,
            'analysis': generatedText,
            'timestamp': FieldValue.serverTimestamp(),
            'analysisId': analysisId,
          });

          setState(() {
            messages.add({
              'role': 'assistant',
              'content': generatedText,
            });
          });

          // Show success message
          UIHelper.showSnackBar(
              context, "Price prediction completed and saved successfully!");
        } else {
          throw Exception('No valid response content from API');
        }
      } else if (response.statusCode == 400) {
        throw Exception(
            'Invalid request. Please check your image and try again.');
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key. Please check your configuration.');
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please try again later.');
      } else {
        throw Exception(
            'Failed to predict price. Status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        messages.add({
          'role': 'assistant',
          'content': 'Error: ${e.toString()}',
        });
      });

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Vehicle Price Predictor'),
          backgroundColor: Colors.blue.shade700,
          elevation: 0,
        ),
        drawer: Drawer(
          backgroundColor: Colors.black,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.account_circle,
                        size: 60,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      (widget.userModel.fullname?.isNotEmpty ?? false)
                          ? widget.userModel.fullname!
                          : 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.userModel.email!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Icons.person, color: Colors.blue.shade700),
                title: const Text(
                  'Profile',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                        userModel: widget.userModel,
                        firebaseUser: widget.firebaseuser,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.history, color: Colors.blue.shade700),
                title: const Text(
                  'History',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HistoryScreen(
                        userId: widget.firebaseuser.uid,
                      ),
                    ),
                  );
                },
              ),
              const Divider(color: Colors.grey),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginPage(),
                        ));
                  }
                },
              ),
            ],
          ),
        ),
        body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedVehicleType,
                      items: vehicleTypes
                          .map((vehicle) => DropdownMenuItem<String>(
                                value: vehicle,
                                child: Text(vehicle),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedVehicleType = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Select Vehicle Type',
                        labelStyle: const TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: Colors.white12,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      dropdownColor: Colors.black,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedModelYear,
                      items: modelYears
                          .map((year) => DropdownMenuItem<String>(
                                value: year,
                                child: Text(year),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedModelYear = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Select Model Year',
                        labelStyle: const TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: Colors.white12,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      dropdownColor: Colors.black,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white10,
                            border: Border.all(color: Colors.blue.shade700),
                          ),
                          child: _image == null
                              ? const Center(
                                  child: Text(
                                    'Tap to select image',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 16),
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _image!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : _predictPrice,
                        icon: const Icon(Icons.price_check),
                        label: isLoading
                            ? const Text(
                                'Predicting...',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              )
                            : const Text('Predict Price',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white38),
                    const SizedBox(height: 10),
                    const Text(
                      'Prediction History:',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isUser = message['role'] == 'user';

                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isUser ? Colors.blue.shade700 : Colors.grey[900],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              message['content'] ?? '',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        })));
  }
}
