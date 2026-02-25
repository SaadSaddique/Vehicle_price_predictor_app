# 🚗 Smart Vehicle Price Estimator (AI Powered)

An AI-powered Flutter mobile application that predicts vehicle prices using Google's Gemini Vision API based on vehicle details and uploaded images.

---

## 📱 Project Overview

Smart Vehicle Price Estimator is a mobile app that allows users to:

- Select vehicle type
- Select model year
- Upload vehicle image
- Get AI-generated price prediction
- View condition assessment
- Identify visible damages
- Save prediction history to Firebase

Unlike a dummy estimator, this version integrates **real AI-powered prediction using Gemini API**.

---

## 🧠 How It Works

1. User selects vehicle type and model year  
2. User uploads an image of the vehicle  
3. Image is converted to Base64  
4. Structured prompt + image is sent to **Gemini API**  
5. AI analyzes vehicle condition  
6. Price prediction is generated in PKR  
7. Result is saved in **Firebase Firestore**  
8. User can view prediction history  

---

## 🛠 Tech Stack

**Frontend**  
- Flutter  
- Dart  

**Backend Services**  
- Firebase Authentication  
- Firebase Firestore  
- Firebase Storage  

**AI Integration**  
- Google Gemini Vision API (`gemini-2.5-flash-lite`)  

**State Management**  
- Stateful Widgets  

**Other Packages**  
- `http`  
- `image_picker`  
- `flutter_dotenv`  
- `uuid`  
- `firebase_core`  
- `cloud_firestore`  
- `firebase_storage`  
- `firebase_auth`  

---


### 🧑‍💻 Author
**Saad Saddique**  
AI/ML Developer | NLP Enthusiast

### 📜 License
MIT License



