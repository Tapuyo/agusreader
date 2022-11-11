import 'package:agus_reader/login/data.dart';
import 'package:agus_reader/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService{

  final String uid;
  DatabaseService({required this.uid});

  //collection reference
  final CollectionReference dataCollection = FirebaseFirestore.instance.collection('users');

  Future updateUserData(String name, String status, int age)async{
    return await dataCollection.doc(uid).set({
      'name': name,
      'status': status,
      'age': age,
    });
  }
//data from list from sn
List<memData> _dataListfromSnapshot(QuerySnapshot snapshot){
  return snapshot.docs.map((datadoc){
    return memData(
      name: datadoc['name']?? '',
      status: datadoc['status']?? '',
      age: datadoc['age']?? 0,
    );
  }).toList();
}
//user data from snapshot
UserData _userdatafromSnapshot(DocumentSnapshot snapshot){
 
    return UserData(
      uid: uid,
      name: snapshot['name']?? '',
      status: snapshot['status']?? '',
      age: snapshot['age']?? 0,
    );
}
//
Stream<List<memData>> get member{
  return dataCollection.snapshots().map(_dataListfromSnapshot);
  
}
//get user doc stream
Stream<UserData> get userdata{
  return dataCollection.doc(uid).snapshots().map(_userdatafromSnapshot);
  
}

}