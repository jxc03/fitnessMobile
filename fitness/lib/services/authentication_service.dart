// Importing packages
import 'package:firebase_auth/firebase_auth.dart'; // Imports Firebase Authentication package
import 'package:cloud_firestore/cloud_firestore.dart'; // Imports Cloud Firestore package

class AuthService {
  // Declaring instances
  final FirebaseAuth _auth = FirebaseAuth.instance; // Assigns irebase Authentication instance to _auth
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firebase Firestore instance

  // Stream to listen for authstate changes
  Stream<User?> get authStateChanges => _auth.authStateChanges(); 
  // Getting the current user
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
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      // Create user document in Firestore
      if(userCredential.user != null) {
        await _createUserDocument(userCredential.user!, displayName); 
        await userCredential.user!.updateDisplayName(displayName); // Update the display name
      }
      return userCredential; // Return the user credential
      
    // Error handling
    } catch (err) { // Catch an error If it occurs
      rethrow; // Handle error
    }
  }


}