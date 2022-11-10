// ignore_for_file: sort_child_properties_last

import 'package:agus_reader/models/area_model.dart';
import 'package:agus_reader/models/billing_models.dart';
import 'package:agus_reader/services/sqlite_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:provider/provider.dart';

import '../../../models/members_billing_model.dart';
import '../../../provider/billing_provider.dart';
import '../../../utils/custom_menu_button.dart';

class OffilineReading extends StatefulWidget {
  final String billID;
  const OffilineReading({Key? key, required this.billID}) : super(key: key);

  @override
  State<OffilineReading> createState() => _OffilineReadingState();
}

class _OffilineReadingState extends State<OffilineReading> {
  late SqliteService _sqliteService;
  List<Billing> _bills = [];
  List<MembersBilling> billsOffline = [];
  List<Area> _areas = [];
  String choosMenu = '';
  String readingText = '';
  TextEditingController _textFieldController =  TextEditingController();

  String? valDropdown;
  String? valDropdowna;

  @override
  void initState() {
    super.initState();
    getMenuBills();
    getList(widget.billID);
  }

  getList(String billID) async {
    choosMenu = billID;
    billsOffline.clear();
    billsOffline = await SqliteService.getMemberBills(choosMenu);
  }

  getMenuBills() async {
    final data = await SqliteService.getItems();
    setState(() {
      _bills = data;
    });
  }

  uploadBills(String billID) async {
    final res = await SqliteService.getMemberBills(billID);
    for(var bill in res){
        var totalC = double.parse(bill.reading) - double.parse(bill.prev);
        updateReadingMember(bill.billMemId, bill.reading, totalC, bill.connectionId);
    }
  }

  Future<void> updateReadingMember(
      String id,
      String currentReading,
      double totalCubic,
      String connectionId) async {
      double totalPrice = await getTotalBill(connectionId, totalCubic);
      FirebaseFirestore.instance
          .collection('membersBilling')
          .doc(id)
          .update({
        'currentReading': double.parse(currentReading),
        'totalCubic': totalCubic,
        'billingPrice': totalPrice,
        'flatRatePrice': 0,
        'flatRate': '',
        'dateRead': DateTime.now()
      }).then((value) async{
          await SqliteService.updateBillingStatus(id);
      });
    
  }

  Future<double> getTotalBill(String connectionId, double totalCubic) async {
    double totalBill = 0;
    double price = 0;
    print(connectionId);
    await FirebaseFirestore.instance
        .collection('connection')
        .get()
        .then((QuerySnapshot querySnapshot) => {
              querySnapshot.docs.forEach((doc) async {
                //  debugPrint(doc.id);
                if (doc.id == connectionId) {
                  price = double.parse(doc['price'].toString());
                }
              })
            });
    totalBill = price * totalCubic;
    return totalBill;
  }

  @override
  Widget build(BuildContext context) {
     BillingProvider provider = context.read<BillingProvider>();
     if(provider.isRefresh){
      getList(widget.billID);
      getMenuBills();
      provider.billRefresh();
     }
    return SingleChildScrollView(
      child: Column(
        children: [
          Text('Provider result: ${provider.isRefresh.toString()}'),
          Container(
            child: Row(
              children: [
                 dropMenu(),
                IconButton(onPressed: (){
                    uploadBills(choosMenu);
                }, icon: const Icon(Icons.upload))
                
              ],
            ),
          ),
          const SizedBox(width: 10,),
          Row(
            children: const <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Name', style: TextStyle(
                  color: Colors.black,
                  fontSize: 18.0,
                ),),
              ),
              SizedBox(width: 150,),
              Text('Previous', style: TextStyle(
                  color: Colors.black,
                  fontSize: 18.0,
                ),),
                SizedBox(width: 15,),
                Text('Current', style: TextStyle(
                  color: Colors.black,
                  fontSize: 18.0,
                ),),
            ],
          ),
          const Divider(
            color: Colors.black,
            height: 0.0,
            thickness: 1,
            indent: 0.0,
            endIndent: 10.0,
          ),
          readingOfflineList(),
        ],
      ),
    );
    // return Column(children: [
    //   // MenuButton(
    //   //     isSelect: true,
    //   //     onPressed: () async {
    //   //       await addItem();
    //   //     },
    //   //     text: 'Add db sql',
    //   //     elevation: 0,
    //   //     textSize: 12,
    //   //     padding: const EdgeInsets.fromLTRB(2, 0, 2, 0)),
    //   // MenuButton(
    //   //     isSelect: true,
    //   //     onPressed: () async {
    //   //       final result = await SqliteService.getItems();
    //   //       for(var name in result){
    //   //           print(name.billingID);
    //   //           print(name.month);
    //   //       }
    //   //     },
    //   //     text: 'Show db sql',
    //   //     elevation: 0,
    //   //     textSize: 12,
    //   //     padding: const EdgeInsets.fromLTRB(2, 0, 2, 0)),
    //   //  MenuButton(
    //   //     isSelect: true,
    //   //     onPressed: () async {
    //   //       deleteItem();
    //   //     },
    //   //     text: 'Delete db sql',
    //   //     elevation: 0,
    //   //     textSize: 12,
    //   //     padding: const EdgeInsets.fromLTRB(2, 0, 2, 0)),
    //   //      MenuButton(
    //   //     isSelect: true,
    //   //     onPressed: () async {
    //   //       UpdateItem();
    //   //     },
    //   //     text: 'Update db sql',
    //   //     elevation: 0,
    //   //     textSize: 12,
    //   //     padding: const EdgeInsets.fromLTRB(2, 0, 2, 0))
    //   readingOfflineList()
    // ]);
  }

  Widget dropMenu() {
   return Column(
     children: [
      Container(
        width: 260,
        height: 40,
        child:  TextField(
        decoration: InputDecoration(
          suffixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15)
          ),
          labelText: 'Search'
        ),
      )),
       DropdownButton(
        value: valDropdowna,
  items: _areas.map((map) => DropdownMenuItem(
          child: Text('Bill: ${map.description} ',style: TextStyle(color: Colors.black),),
          value: map.description,
        ),
  ).toList(), onChanged: (value) { 
        setState(() {
          choosMenu = value.toString();
          valDropdowna = value.toString();
        });
       },
),
       DropdownButton(
        value: valDropdown,
  items: _bills.map((map) => DropdownMenuItem(
          child: Text('Bill: ${map.month} ${map.year}',style: TextStyle(color: Colors.black),),
          value: map.billingID,
        ),
  ).toList(), onChanged: (value) { 
        setState(() {
          choosMenu = value.toString();
          getList(value.toString());
          valDropdown = value.toString();
        });
       },
),
     ],
   );
  }
  
  Widget floatingButton() {
    return const FloatingActionButton.extended(onPressed: null, label:  Text('Upload Billing'));
  }

  Widget readingOfflineList() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height - 231,
      child: ListView.builder(
          shrinkWrap: false,
          itemCount: billsOffline.length,
          itemBuilder: (BuildContext context, int index) {
            return GestureDetector(
              onTap: (){
                _displayReadingDialog(context, billsOffline[index].billMemId,);
              },
              child: Card(
                color: billsOffline[index].status == 'upload' ? Colors.green.shade400.withOpacity(.5):Colors.blueAccent.shade100.withOpacity(.5),
                child: Padding(padding: EdgeInsets.fromLTRB(10, 20, 10, 20),
                child: Row(children: [
                  Text(billsOffline[index].name, 
                  style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18.0,
                ),),
                  Spacer(),
                  Text(billsOffline[index].prev,
                  style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18.0,
                ),),
                 Spacer(),
                  Text(billsOffline[index].reading,
                  style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18.0,
                ),),
                ]),),
              ),
            );
          }),
    );
  }

  

  Future<void> _displayReadingDialog(BuildContext context, String id) async {
   return showDialog(
       context: context,
       builder: (context) {
         return AlertDialog(
           title: const Text('Update Reading'),
           content: TextField(
             onChanged: (value) {
               setState(() {
                 readingText = value;
               });
             },
             controller: _textFieldController,
             decoration: InputDecoration(hintText: "Input reading"),
           ),
           actions: <Widget>[
             TextButton(
               child: const Text('Save'),
               onPressed: () {
                 setState(() {
                  UpdateItemBill(id);
                   Navigator.pop(context);
                 });
               },
             ),
  
           ],
         );
       });
  }

   Future<int> UpdateItemBill(String id) async {
    String readVal = _textFieldController.text;
    final result = await SqliteService.updateBilling(id,readVal);
    print(result);
    getList(choosMenu);
    return result;
  }

  Future<int> addItem() async {
    Billing bills = Billing('0912312', 'January', '2019', 'close', 'admin');
    final result = await SqliteService.createItem(bills);
    return result;
  }

  Future<int> deleteItem() async {
    final result = await SqliteService.deleteItem('g1RAEN5iDRoA015pD9L0');
    return result;
  }

  Future<int> UpdateItem() async {
    final result = await SqliteService.updateItem('0912312');
    print(result);
    return result;
  }
}
