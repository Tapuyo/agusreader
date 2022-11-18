// ignore_for_file: sort_child_properties_last

import 'dart:io';

import 'package:agus_reader/models/area_model.dart';
import 'package:agus_reader/models/billing_models.dart';
import 'package:agus_reader/services/sqlite_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/members_billing_model.dart';
import '../../../provider/billing_provider.dart';
import '../../../utils/custom_menu_button.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OffilineReading extends StatefulWidget {
  final String billID;
  const OffilineReading({
    Key? key,
    required this.billID,
  }) : super(key: key);

  @override
  State<OffilineReading> createState() => _OffilineReadingState();
}

class _OffilineReadingState extends State<OffilineReading> {
  
  late SqliteService _sqliteService;
  List<Billing> _bills = [];
  List<MembersBilling> billsOffline = [];
  List<Area> _areas = [];
List<MembersBilling> _foundUsers = [];
  String choosMenu = '';
  String areaCh = '';
  String readingText = '';
  TextEditingController _textFieldController = TextEditingController();
    TextEditingController _nameFieldController = TextEditingController();


  String? valDropdown;
  String? valDropdowna;
  bool valuea = false;
  bool value = false;
  bool all = false;

  @override
  void initState() {
    super.initState();
    getMenuBills();
    getList(widget.billID);
    getArea();
  }

  getList(String billID) async {
    choosMenu = billID;
    billsOffline.clear();
    billsOffline = await SqliteService.getMemberBills(choosMenu);
    _foundUsers = billsOffline;
  }

  getArea() async {
    _areas.clear();
    _areas = await SqliteService.getAreas();
    
  }

  getMenuBills() async {
    final data = await SqliteService.getItems();
    setState(() {
      _bills = data;
    });
  }

  uploadBills(String billID) async {
    final res = await SqliteService.getMemberBills(billID);
    // List<MembersBilling> temp = [];
    // temp = res
    //       .where((user) =>
    //           user.reading.contains('0'))
    //       .toList();
    // print(temp.length);
    // if(temp.isEmpty){
    for (var bill in res) {
      // print(temp.toString());
      var totalC = double.parse(bill.reading) - double.parse(bill.prev);
      updateReadingMember1(
          bill.billMemId, bill.reading, totalC, bill.connectionId);
    }
    print('Reading Uploaded');
    // }else{
    //   //TODO alert dialog display
    //   print('Please check members reading!');
    // }
  }

  Future<void> updateReadingMember(String id, String currentReading,
      double totalCubic, String connectionId) async {
    double totalPrice = await getTotalBill(connectionId, totalCubic);
    FirebaseFirestore.instance.collection('membersBilling').doc(id).update({
      'currentReading': double.parse(currentReading),
      'totalCubic': totalCubic, 
      'billingPrice': totalPrice,
      'flatRatePrice': 0,
      'flatRate': '',
      'dateRead': DateTime.now()
    }).then((value) async {
      await SqliteService.updateBillingStatus(id);
    });
  }
  Future<void> updateReadingMember1(String id, String currentReading,
      double totalCubic, String connectionId) async {
    bool checkPrice = await checkPriceValue(id);

    if(checkPrice){
    double totalPrice = await getTotalBill(connectionId, totalCubic);
    var collection = FirebaseFirestore.instance.collection('membersBilling').doc(id);
    collection.update({
      'currentReading': double.parse(currentReading),
      'totalCubic': totalCubic, 
      'billingPrice': totalPrice,
      'flatRatePrice': 0,
      'flatRate': '',
      'dateRead': DateTime.now()
    }).then((value) async {
      await SqliteService.updateBillingStatus(id);
    });
      }else{
        print('not upload');
      }
  }

  Future<bool> checkPriceValue(String docid)async{
    bool res = false;
    List months =
['January', 'February', 'March', 'April', 'May','June','July','August','September','October','November','December'];

     var formatter = new DateFormat('MM'); 
     var formatter1 = new DateFormat('yyyy'); 
     var month = formatter. format(DateTime.now());
     String year = formatter1. format(DateTime.now());
     String currentmonth = months[int.parse(month)-1];
     print('$currentmonth, $year ');

    try{
       await FirebaseFirestore.instance
        .collection('membersBilling')
        .get()
        .then((QuerySnapshot querySnapshot) => {
              querySnapshot.docs.forEach((doc) async {
                if(doc.id == docid){
                    if(doc['billingPrice'] > 0 && doc['month'] == currentmonth && doc['year'] == year){
                      res = true;
                    }else{
                      res = false;
                    }
                }
          })
        });

    }catch(e){
      return false;
    }

    return res;
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
    if (provider.isRefresh) {
      getList(widget.billID);
      getMenuBills();
      provider.billRefresh();
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          // Text('Provider result: ${provider.isRefresh.toString()}'),
          Container(
            child: Row(
              children: [
                dropMenu(),
              ],
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
            width: MediaQuery.of(context).size.width,
            child: Row(
              children: <Widget>[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Name',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                const Spacer(
                  // width: 117,
                  flex: 10,
                ),
                const Text(
                  'Previous',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18.0,
                  ),
                ),
                const Spacer(
                    // width: 12,
                    ),
                const Text(
                  'Current',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18.0,
                  ),
                ),
                IconButton(
                    onPressed: () {
                      uploadBills(choosMenu);
                    },
                    icon: const Icon(Icons.upload)),
              ],
            ),
          ),
          const Divider(
            color: Colors.black,
            height: 0.0,
            thickness: 1,
            indent: 0.0,
            endIndent: 10.0,
          ),
          Container(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
              child: readingOfflineList()),
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
    return Row(
      children: [
        Container(
            padding: const EdgeInsets.fromLTRB(5, 20, 5, 10),
            width: MediaQuery.of(context).size.width - 90,
            height: 70,
            child: TextField(
              controller: _nameFieldController,
              onChanged: (value) => onSearchTextChanged(value),
              decoration: InputDecoration(
                suffixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                labelText: 'Search Name',
              ),
            )),
        IconButton(
            onPressed: () {
              _displayFilterDialog(context);
            },
            icon: const Icon(Icons.open_in_browser)),
      ],
    );
  }

  void onSearchTextChanged(String text) async {
    List<MembersBilling> results = [];
    if (text.isEmpty) {
        results = _foundUsers;
    } else {
        results = _foundUsers
          .where((user) =>
              user.name.toLowerCase().contains(text.toLowerCase()))
          .toList();
    }
    setState(() {
      billsOffline = results;
    });
  }
  void onStatusUnreadChanged(bool text) async {
    List<MembersBilling> results = [];
        results = _foundUsers
          .where((user) =>
              user.reading.toString() == '0')
          .toList();
    setState(() {
      billsOffline = results;
    });
  }
  void onStatusReadChanged(bool text) async {
    List<MembersBilling> results = [];
        results = _foundUsers
          .where((user) =>
              user.reading.toString() != '0')
          .toList();
    setState(() {
      billsOffline = results;
    });
  }
  void onAllChanged() async {
    List<MembersBilling> results = [];
        results = _foundUsers;
    setState(() {
      billsOffline = results;
    });
  }
   void onSearchBrgyChanged(String text) async {
    List<MembersBilling> results = [];
    print(text);
    print(_foundUsers);
    if(billsOffline.isEmpty){
    print('I am empty');
    }else{
      if (text.isEmpty) {
        results = _foundUsers;
    } else {
        results = _foundUsers
          .where((user) =>
              user.areaid.toLowerCase().contains(text.toLowerCase()))
          .toList();
    }
    }
    setState(() {
      billsOffline = results;
    });
  }

  Widget readingOfflineList() {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height - 342,
          child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
              shrinkWrap: false,
              itemCount: billsOffline.length,
              itemBuilder: (BuildContext context, int index) {
                return GestureDetector(
                  onTap: () {
                    _displayReadingDialog(
                      context,
                      billsOffline[index].billMemId,
                    );
                  },
                  child: Container(
                    color: billsOffline[index].status == 'upload'
                        ? Colors.green.shade400.withOpacity(.5)
                        : Colors.blueAccent.shade100.withOpacity(.2),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 10, 60, 10),
                      child: Row(children: [
                        Text(
                          billsOffline[index].name,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18.0,
                          ),
                        ),
                        const Spacer(
                          flex: 3,
                        ),
                        Text(
                          billsOffline[index].prev,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18.0,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          billsOffline[index].reading,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18.0,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ]),
                    ),
                  ),
                );
              }),
        ),
      ),
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
              decoration: const InputDecoration(hintText: "Input reading"),
            ),
            actions: <Widget>[
              FlatButton(
                color: Colors.green,
                textColor: Colors.white,
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

  Future<void> _displayFilterDialog(BuildContext context) async {
    return showModalBottomSheet<void>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter newsetState) {
            return Container(
              child: Column(
                children: [
                  const SizedBox(height: 2), //SizedBox
                  const Text(
                    'Filter Reading',
                    textAlign: TextAlign.start,
                    style: TextStyle(fontSize: 17.0),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.fromLTRB(5, 15, 5, 10),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    width: MediaQuery.of(context).size.width - 40,
                    height: 80,
                    child: Column(
                      children: [
                        //Checkbox
                        const SizedBox(
                          height: 1,
                        ),
                        const Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Choose Barangay",
                                style: TextStyle(
                                  color: Colors.black54,
                                ))),
                        Container(
                          height: 35,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.black54,
                              )),
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 4,
                              right: 4,
                            ),
                            child:DropdownButton(
                                    isExpanded: true,
                                    underline: Container(),
                                    alignment: Alignment.bottomRight,
                                    elevation: 0,
                                    borderRadius: BorderRadius.circular(5),
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down,
                                    ),
                                    value: valDropdowna,
                                    items: _areas
                                        .map(
                                          (map) => DropdownMenuItem(
                                            child: Text(map.description,
                                                style: const TextStyle(
                                                    color: Colors.black),
                                                textAlign: TextAlign.right),
                                            value: map.id,
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      newsetState(() {
                                        print(value);
                                        onSearchBrgyChanged(value.toString());
                                        valDropdowna = value.toString();
                                        setState(() {
                                        valDropdowna = value.toString();
                                      });
                                      });
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    width: MediaQuery.of(context).size.width - 40,
                    height: 80,
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 1,
                        ),
                        const Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Month of Billing",
                                style: TextStyle(
                                  color: Colors.black54,
                                ))),
                        Container(
                          height: 35,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.black54,
                              )),
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 4,
                              right: 4,
                            ),
                            child: DropdownButton(
                              underline: Container(),
                              isExpanded: true,
                              alignment: Alignment.bottomRight,
                              elevation: 0,
                              borderRadius: BorderRadius.circular(5),
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                              ),
                              value: valDropdown,
                              items: _bills
                                  .map(
                                    (map) => DropdownMenuItem(
                                      child: Text(
                                          'Bill: ${map.month} ${map.year}',
                                          style: const TextStyle(
                                              color: Colors.black),
                                          textAlign: TextAlign.right),
                                      value: map.billingID,
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                newsetState(() {
                                  choosMenu = value.toString();
                                  getList(value.toString());
                                  valDropdown = value.toString();
                                });
                                setState(() {
                                  choosMenu = value.toString();
                                  getList(value.toString());
                                  valDropdown = value.toString();
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(5, 10, 5, 010),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    width: MediaQuery.of(context).size.width - 40,
                    height: 87,
                    child: Column(
                      children: [
                        const Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Status of Reading",
                                style: TextStyle(
                                  color: Colors.black54,
                                ))),
                        Row(
                          children: <Widget>[
                            /** Checkbox Widget **/
                            Checkbox(
                              value: valuea,
                              onChanged: (bool? newvalue) {
                                 newsetState(() {
                                  onStatusUnreadChanged(newvalue!);
                                  valuea = newvalue;
                                  all = false;
                                  value = false;

                                });
                              },
                            ), //Checkbox//SizedBox
                             const Text( 'Unread',
                              style:  TextStyle(fontSize: 17.0),
                            ), //Text
                           const SizedBox( width: 3,),
                            Checkbox(
                              value: value,
                              onChanged: (bool? newvalue) {
                                 newsetState(() {
                                  onStatusReadChanged(newvalue!);
                                  value = newvalue;
                                  all = false;
                                  valuea = false;

                                });
                              },
                            ), //Checkbox//SizedBox
                           const  Text( 'Read',
                              style:  TextStyle(fontSize: 17.0),
                            ), //Text
                           const SizedBox( width: 3,),
                            Checkbox(
                              value: all,
                              onChanged: (bool? newvalueme) {
                                 newsetState(() {
                                  onAllChanged();
                                  all = newvalueme!;
                                  value = false;
                                  valuea = false;


                                });
                              },
                            ), //Checkbox//SizedBox
                            const Text( 'All',
                              style:  TextStyle(fontSize: 17.0),
                            ), //Text
                          ], //<Widget>[]
                        ),
                      ],
                    ),
                  ),
                  FlatButton(
                    color: Colors.green,
                    textColor: Colors.white,
                    child: const Text('Close'),
                    onPressed: () {
                      setState(() {
                        Navigator.pop(context);
                      });
                    },
                  ),
                  // FlatButton(
                  //   color: Colors.green,
                  //   textColor: Colors.white,
                  //   child: const Text('Filter'),
                  //   onPressed: () {
                  //     setState(() {
                  //       // UpdateItemBill(id);
                  //       Navigator.pop(context);
                  //     });
                  //   },
                  // ),
                ],
              ),
            );
          });
        });
  }
   static Route<Object?> _dialogBuilder(
      BuildContext context, Object? arguments) {
    return DialogRoute<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('PIWAS READING'),
          content: const Text('Please select monthly billing!'),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
      }

  Future<int> UpdateItemBill(String id) async {
    print(id);
    String readVal = _textFieldController.text;
    final result = await SqliteService.updateBilling(id, readVal);
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
