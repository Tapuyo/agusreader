class MembersBilling{
  final String billingID;
  final String billMemId;
  final String name;
  final String reading;
  final String status;
  final String areaid;
  final String deateread;
  final String prev;
  final String connectionId;



  MembersBilling(this.billingID,this.billMemId, this.name, this.reading, this.status, this.areaid, this.deateread,this.prev,this.connectionId);

  MembersBilling.fromMap(Map<String, dynamic> item): 
    billingID=item["billingID"], billMemId=item["billMemId"], name= item["name"], reading= item["reading"], status= item["status"], areaid= item["areaid"], deateread= item["deateread"], prev= item["prev"], connectionId= item["connectionId"];
  
  Map<String, Object> toMap(){
    return {'billingID':billingID, 'billMemId': billMemId, 'name': name, 'reading':reading, 'status':status, 'areaid':areaid, 'deateread':deateread, 'prev':prev, 'connectionId':connectionId};
  }
}