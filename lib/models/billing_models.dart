class Billing{
  final String billingID;
  final String month;
  final String year;
  final String status;
  final String creator;


  Billing(this.billingID, this.month, this.year, this.status, this.creator);

  Billing.fromMap(Map<String, dynamic> item): 
    billingID=item["billingID"], month= item["month"], year= item["year"], status= item["status"], creator= item["creator"];
  
  Map<String, Object> toMap(){
    return {'billingID':billingID,'month': month, 'year':year, 'status':status, 'creator':creator};
  }
}