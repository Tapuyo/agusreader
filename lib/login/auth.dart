// ignore_for_file: avoid_print

import 'package:agus_reader/login/database.dart';
import 'package:agus_reader/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  //create user obj based on firebaseuser
 Users? _userFromFirebaseUser(User? user){
    // ignore: unnecessary_null_comparison
    if (user != null){
       return Users(uid: user.uid);
    }
    return null;
}


  //auth change user stream
  Stream<Users?> get user{
    print('This is the auth: $_auth');
return _auth.authStateChanges().map(_userFromFirebaseUser);
  }

  // sign w/ anon
  Future signInAnon() async {
    try{
      UserCredential result =  await _auth.signInAnonymously();
      User? user = result.user;
      return _userFromFirebaseUser(user!);
    }catch(e){
      print(e.toString());
      return null;
    }
  }
  
  Future signOutAnon() async {
    try{
    return await _auth.signOut();
    }catch(e){
      print(e.toString());
      return null;
    }
  }
  //sign in w/email and password
  Future signinwEmailandPassword(String email, String password) async {
    try{
    UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
    User? user = result.user;
    return _userFromFirebaseUser(user);
    }catch(e){
      print(e.toString());
      return null;
    }
  }
  // register with email and password
  Future registerwEmailandPassword(String email, String password) async {
    try{
    UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    User? user = result.user;

    //create a new document for the user with the uid
    await DatabaseService(uid: user!.uid).updateUserData('new name', 'new status', 100);
    return _userFromFirebaseUser(user);
    }catch(e){
      print(e.toString());
      return null;
    }
  }
  }