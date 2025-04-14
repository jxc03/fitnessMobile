// Importing packages
import 'package:firebase_auth/firebase_auth.dart'; // Imports Firebase Authentication package
import 'package:cloud_firestore/cloud_firestore.dart'; // Imports Cloud Firestore package
import 'dart:developer'; // Imports the log function

class AuthService {
  // Declaring instances
  final FirebaseAuth _auth = FirebaseAuth.instance; // Assigns irebase Authentication instance to _auth
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firebase Firestore instance

  // Stream to listen for authstate changes
  Stream<User?> get authStateChanges => _auth.authStateChanges(); 
  // Get the current user
  User? get currentUser => _auth.currentUser;  

  // Function to sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );

      // Update the last active time in Firestore
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).update({
          'lastActive': FieldValue.serverTimestamp(),
        });
      }
      // Return the user credential
      return userCredential;
    // Error handling
    } catch (err) { // Catch an errror If it occurs
      rethrow; // Handle error
    }
  }

  // Function to register with email and password
  Future <UserCredential> registerWithEmailAndPassword(String email, String password, String displayName) async {
    try {
      // Create the user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );

      // Create user document in Firestore
      if(userCredential.user != null) {
        await userCredential.user!.updateDisplayName(displayName); // Update the display name
        await _createUserDocument(userCredential.user!, displayName); // Then create the Firestore document
      }
      return userCredential; // Return the user credential
      
    // Error handling
    } catch (err) { // Catch an error If it occurs
      rethrow; // Handle error
    }
  }

  // Create user document 
  Future<void> _createUserDocument(User user, String displayName) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'displayName': displayName,
        'email': user.email,
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
        'settings': {
          'unitSystem': 'metric',
          'notifications': true,
        },
        'profile': {
          'height': null,
          'weight': null,
          'birthdate': null,
          'fitnessGoals': [],
          'fitnessLevel': 'beginner',
        }
      });
      log('User document created successfully for ${user.uid}');
    } catch (e) {
      log('Error creating user document: $e');
    }
  }


  // Function to sign out the user
  Future<void> signOut() async {
    try {
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'lastActive': FieldValue.serverTimestamp(),
        });
      }
      await _auth.signOut(); // Sign out the user
      // Error handling
    } catch (err) { // Catch an error If it occurs
      rethrow; // Handle error
    }
  }

  // Function to send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email); // Send password reset email
    // Error handling
    } catch (err) { // Catch an error If it occurs
      rethrow; // Handle error
    }
  }

  // Function to update user profile
  Future<void> updateUserProfile({String? displayName, String? photoURL, Map<String, dynamic>? profileData}) async {
    try {
      if (currentUser == null) {
        throw Exception('User not logged in'); // Throw an error if user is not logged in
      }

      // Update user profile in Firebase Auth if needed
      if (displayName != null || photoURL != null) { // Check if displayName or photoURL is provided
        await currentUser!.updateProfile(displayName: displayName, photoURL: photoURL); // Update user profile
        if (photoURL != null) { // Check if photoURL is provided
          await currentUser!.updatePhotoURL(photoURL); // Update user photo URL
        }
      }

      // Update user document in Firestore
      final userRef = _firestore.collection('users').doc(currentUser!.uid); // Get user document reference
      Map<String, dynamic> updateData = {}; // Create a map to hold update data
      if (displayName != null) { // Check if displayName is provided
        updateData['displayName'] = displayName; // Update display name
      }
      if (photoURL != null) { // Check if photoURL is provided
        updateData['photoURL'] = photoURL; // Update photo URL
      }
      if (profileData != null) { // Check if profileData is provided
        for (var entry in profileData.entries) { // Loop through profile data entries
          updateData['profile.${entry.key}'] = entry.value; // Update profile data
        }
      }
      await userRef.update(updateData); // Update user document in Firestore

      // Error handling
    } catch (error) { // Catch an error If it occurs
      rethrow; // Handle error
    }
  }

  // Update user settings
  Future<void> updateUserSettings(Map<String, dynamic> settings) async {
    try {
      if (currentUser == null) {
        throw Exception('No user is currently signed in');
      }

      final userRef = _firestore.collection('users').doc(currentUser!.uid);
      
      Map<String, dynamic> updateData = {};
      
      for (var entry in settings.entries) {
        updateData['settings.${entry.key}'] = entry.value;
      }
      
      await userRef.update(updateData);
    } catch (e) {
      rethrow;
    }
  }
  
  // Function to change user password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      if (currentUser == null || currentUser!.email == null) { // Check if user is logged in
        throw Exception('User not logged in'); // Throw an error if user is not logged in
      }

      // Reauthenticate the user with the current password
      AuthCredential credential = EmailAuthProvider.credential( // Create email auth credential
        email: currentUser!.email!, // Get the current user's email
        password: currentPassword, // Get the current password
      );
      await currentUser!.reauthenticateWithCredential(credential); // Reauthenticate the user
      await currentUser!.updatePassword(newPassword); // Then update the password

      // Error handling
    } catch (error) { // Catch an error If it occurs
      rethrow; // Handle error
    }
  }

  // Function to delete user account1
  Future<void> deleteAccount(String password) async {
    try {
      if (currentUser == null || currentUser!.email == null) { // Check if user is logged in
        throw Exception('User not logged in'); // Throw an error if user is not logged in
      }

      // Reauthenticate the user with the current password
      AuthCredential credential = EmailAuthProvider.credential( // Create email auth credential
        email: currentUser!.email!, // Get the current user's email
        password: password, // Get the current password
      );
      await currentUser!.reauthenticateWithCredential(credential); // Reauthenticate the user
      await _firestore.collection('users').doc(currentUser!.uid).delete(); // Delete user document from Firestore
      await currentUser!.delete(); // Then delete user account 

    // Error handling
    } catch (error) { // Catch an error If it occurs
      rethrow; // Handle error
    }
  }
}