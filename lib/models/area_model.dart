
import 'package:cloud_firestore/cloud_firestore.dart';

class Area{
  final String code;
  final Timestamp date;
  final String description;
  final String name;
  final String status;

  Area(this.code, this.date, this.description, this.name, this.status);
Area.fromMap(Map<String, dynamic> item): 
    code=item["code"], date= item["date"], description= item["description"], name= item["name"], status= item["status"];
  
  Map<String, Object> toMap(){
    return {'code':code,'date': date, 'descriotion':description, 'name':name, 'status':status};
  }
}