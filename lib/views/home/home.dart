// ignore_for_file: prefer_const_constructors

import 'package:agus_reader/constants/constant.dart';
import 'package:agus_reader/models/area_model.dart';
import 'package:agus_reader/provider/billing_provider.dart';
import 'package:agus_reader/utils/custom_menu_button.dart';
import 'package:agus_reader/utils/custom_menu_label_button.dart';
import 'package:agus_reader/views/home/offline_reading/offline_reading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

import '../../models/billing_models.dart';
import '../../models/members_billing_model.dart';
import '../../services/sqlite_service.dart';
import '../billing/bill.dart';

class MyHomePage extends StatefulWidget {
  _BillingPayDialog createState() => _BillingPayDialog();

  const MyHomePage({Key? key}) : super(key: key);
}

class _BillingPayDialog extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  List<Billing> bills = [];
  List<Area> areas = [];
  Future? fbills;
  String docID = '';
  late AnimationController _animationController;
  bool offline = true;
  bool showDownLoadinBtn = true;
  String menuChoose = 'offlineReading';

  @override
  void initState() {
    super.initState();
    fbills = getBilling();
    getAreas();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));
  }

  _toggleAnimation() {
    _animationController.isDismissed
        ? _animationController.forward()
        : _animationController.reverse();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> checkBillingExist(String billID)async{

    var res = await SqliteService.checkBillingExist(billID);
    setState(() {
      if(res){
      showDownLoadinBtn = false;
    }else{
       showDownLoadinBtn = true;
    }
    });
  }

  

  @override
  Widget build(BuildContext context) {
    final rightSlide = MediaQuery.of(context).size.width * -.5;
    return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          double slide = rightSlide * _animationController.value;
          double scale = 1 - (_animationController.value * 0.3);
          return Stack(
            children: [
              // Works as Drawer
              GestureDetector(
                onTap: () {
                  _toggleAnimation();
                },
                child: Scaffold(
                  backgroundColor: kColorBlue,
                  body: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 200, 30, 0),
                    child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          // ignore: prefer_const_literals_to_create_immutables
                          children: [
                            GestureDetector(
                                onTap: () {
                                  setState(() {
                                    menuChoose = 'offlineReading';
                                    offline = !offline;
                                  });
                                  _toggleAnimation();
                                },
                                child: Text(
                                    offline ? 'Online Mode' : 'Offline Mode',
                                    style: BluekTextStyleHeadline5white)),
                            SizedBox(
                              height: 30,
                            ),
                            GestureDetector(
                              onTap: ()async{
                                  setState(() {
                                    showDownLoadinBtn = false;
                                    menuChoose = 'billing';
                                  });
                                  _toggleAnimation();
                              },
                              child: Text('Reading',
                                  style: BluekTextStyleHeadline5white),
                            ),
                            SizedBox(
                              height: 30,
                            ),
                            Text('Print Bills',
                                style: BluekTextStyleHeadline5white),
                            SizedBox(
                              height: 30,
                            ),
                            Text('Settings',
                                style: BluekTextStyleHeadline5white),
                            SizedBox(
                              height: 30,
                            ),
                            Text('Help?', style: BluekTextStyleHeadline5white),
                          ],
                        )),
                  ),
                ),
              ),

              Transform(
                transform: Matrix4.identity()
                  ..translate(slide)
                  ..scale(scale),
                alignment: Alignment.center,
                child: Container(
                   decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                        topRight: Radius.circular(10.0),
                        topLeft: Radius.circular(10.0),
                        bottomRight: Radius.circular(10.0)
                        
                        ),
                        
                    color: Colors.white,
                  ),
                  child: Scaffold(
                    backgroundColor: Colors.white,
                    body: Stack(
                      children: [
                        Expanded(
                          // height: MediaQuery.of(context).size.height,
                          // width: MediaQuery.of(context).size.width,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        // ignore: prefer_const_literals_to_create_immutables
                                        children: [
                                          Text(
                                            'Welcome',
                                            style: kTextStyleHeadline5,
                                          ),
                                          SizedBox(
                                            height: 12,
                                          ),
                                          Text('John', style: kTextStyleHeadline4)
                                        ],
                                      ),
                                      Spacer(),
                                      IconButton(
                                        onPressed: () => _toggleAnimation(),
                                        icon: AnimatedIcon(
                                          icon: AnimatedIcons.menu_close,
                                          progress: _animationController,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if(menuChoose == 'offlineReading')...[
                                    OffilineReading(billID: docID,),
                                  ]else if(menuChoose == 'billing')...[
                                    BillingPage()
                                  ]else...[
                                    OffilineReading(billID: docID,),
                                  ]
                                  
                                ]),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (offline) ...[
                                      openBills(context),
                                    ] else ...[
                                      liveBilling(context)
                                    ]
                                  ]),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              )
            ],
          );
        });
  }

  Future<List<Billing>> getBilling() async {
    await FirebaseFirestore.instance
        .collection('billing')
        .orderBy('date', descending: true)
        .get()
        .then((QuerySnapshot querySnapshot) => {
              querySnapshot.docs.forEach((doc) async {
                debugPrint(doc.id);
                if (doc['status'] == 'open') {
                  setState(() {
                    docID = doc.id;
                  });
                  Billing bill = Billing(doc.id, doc['month'], doc['year'],
                      doc['status'], doc['user']);
                  bills.add(bill);
                }
              })
            });
    return bills;
  }
  Future<List<Area>> getAreas() async {
    await FirebaseFirestore.instance
        .collection('area')
        .get()
        .then((QuerySnapshot querySnapshot) => {
              querySnapshot.docs.forEach((doc) async {
                debugPrint(doc.data().toString());

                  Area areasS = Area( doc['code'], doc['date'],
                      doc['description'], doc['name'], doc['status']);
                  areas.add(areasS);
                })
              });
    return areas;
  }

  downloadBills(String docID)async{
    print('This is the ID: $docID');
    await FirebaseFirestore.instance
        .collection('membersBilling').where('billingId',isEqualTo: docID)
        .get()
        .then((QuerySnapshot querySnapshot) => {
              querySnapshot.docs.forEach((doc) async {
                print(doc.id);
                //for download area
                      await downloadBilling(doc['billingId'],doc.id,doc['name'],'0','active',doc['areaId'].toString(),DateTime.now().toString(),doc['previousReading'].toString(),doc['connectionId'].toString());
              })
            });
    setState(() {

      docID = docID;
    });
  }
  // downloadArea() async{
  //   await FirebaseFirestore.instance
  //       .collection('area')
  //       .get()
  //       .then((QuerySnapshot querySnapshot) => {
  //             querySnapshot.docs.forEach((doc) async {
  //               print(doc.id);
  //                     await downloadBilling(doc.id, doc['name'],'0','active',doc['areaId'].toString(),DateTime.now().toString(),doc['previousReading'].toString(),doc['connectionId'].toString());
  //             })
  //           });
  // }
  Future<int> downloadAreas(String code,date,description,name,status) async {
    Area areas = Area(code,date,description,name,status);
    print(bills.toString());
    final result = await SqliteService.downloadArea(areas);
  
  
    return result;
  }

  Future<int> downloadBilling(String billingID,billMemId,name,reading,status,areaid,deateread, prev, connId) async {
    MembersBilling bills = MembersBilling(billingID,billMemId,name,reading,status,areaid,deateread,prev,connId);
    print(bills.billingID.toString());
    final result = await SqliteService.downloadReading(bills);
  
  
    return result;
  }

  Widget openBills(BuildContext context) {
    
    return FutureBuilder(
        future: fbills,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.data.length <= 0) {
              return Expanded(
                child: Center(
                  child: Text('No billing found.'),
                ),
              );
            } else {
              return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data.length,
                  itemBuilder: (context, index) {
                    checkBillingExist(snapshot.data[index].billingID);
                    return Visibility(
                      visible: menuChoose == 'offlineReading' ? showDownLoadinBtn:false,
                      child: MenuButton(
                          isSelect: true,
                          onPressed: () async{
                            print(snapshot.data[index].billingID);
                            final res = await addItem(snapshot.data[index].billingID, snapshot.data[index].month,
                             snapshot.data[index].year ,snapshot.data[index].status, snapshot.data[index].creator);
                             //if(res == 1){
                                downloadBills(snapshot.data[index].billingID);
                                print(snapshot.data[index].billingID);
                                //use to call provider
                              //  BillingProvider provider = context.read<BillingProvider>();
                              //   provider.billRefresh();
                            // }
                             
                          },
                          text:
                              'Download ${snapshot.data[index].month} ${snapshot.data[index].year} reading',
                          elevation: 0,
                          textSize: 12,
                          padding: const EdgeInsets.fromLTRB(2, 0, 2, 0)),
                    );
                  });
            }
          } else {
            // ignore: avoid_unnecessary_containers
            return Container(
              child: Center(
                child: Text('loading.'),
              ),
            );
          }
        });
  }

  Widget liveBilling(BuildContext context) {
    return FutureBuilder(
        future: fbills,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.data.length <= 0) {
              return Expanded(
                child: Center(
                  child: Text('No billing found.'),
                ),
              );
            } else {
              return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data.length,
                  itemBuilder: (context, index) {
                    return MenuButton(
                        isSelect: true,
                        onPressed: () {},
                        text:
                            'Live reading ${snapshot.data[index].month} ${snapshot.data[index].year}',
                        elevation: 0,
                        textSize: 12,
                        padding: const EdgeInsets.fromLTRB(5, 0, 5, 0));
                  });
            }
          } else {
            // ignore: avoid_unnecessary_containers
            return Container(
              child: Center(
                child: Text('loading.'),
              ),
            );
          }
        });
  }

    Future<int> addItem(String billID, mo, yr, stat, creator) async {
    Billing bills = Billing(billID,  mo, yr, stat, creator);
    final result = await SqliteService.createItem(bills);
    return result;
  }
}
