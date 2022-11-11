import 'package:firebase_core/firebase_core.dart';

class Users{
  final String uid;
  
  Users({ required this.uid });
}
class UserData{

  final String uid;
  final String name;
  final String status;
  final int age;
UserData({required this.uid, required this.name,required this.status,required this.age});

}