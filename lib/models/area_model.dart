class Area{
  final String id;
  final String code;
  final String description;
  final String name;
  final String status;

  Area(this.id, this.code, this.description, this.name, this.status);
Area.fromMap(Map<String, dynamic> item): 
    id=item["id"],code=item["code"], description= item["description"], name= item["name"], status= item["status"];
  
  Map<String, Object> toMap(){
    return {'id':id, 'code':code, 'description':description, 'name':name, 'status':status};
  }
}