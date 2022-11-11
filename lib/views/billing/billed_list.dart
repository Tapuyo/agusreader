import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../constants/constant.dart';
import '../../models/billing_members_models.dart';

class BillingContentPage extends StatefulWidget {
  const BillingContentPage({Key? key}) : super(key: key);

  @override
  State<BillingContentPage> createState() => _OffilineReadingState();
}

class _OffilineReadingState extends State<BillingContentPage> {
  Future? fBilling;
  List<BillingMember> billingMember = [];

  //Printing
  BluetoothPrint bluetoothPrint = BluetoothPrint.instance;
  bool _connected = false;
  BluetoothDevice? _device;
  String tips = 'no device connect';

  @override
  void initState() {
    super.initState();
    fBilling = getMembersBilling();
    initBluetooth();
  }

  Future<void> initBluetooth() async {
    bluetoothPrint.startScan(timeout: Duration(seconds: 4));

    bool isConnected = await bluetoothPrint.isConnected ?? false;

    bluetoothPrint.state.listen((state) {
      print('******************* cur device status: $state');

      switch (state) {
        case BluetoothPrint.CONNECTED:
          setState(() {
            _connected = true;
            tips = 'connect success';
          });
          break;
        case BluetoothPrint.DISCONNECTED:
          setState(() {
            _connected = false;
            tips = 'disconnect success';
          });
          break;
        default:
          break;
      }
    });

    if (!mounted) return;

    if (isConnected) {
      setState(() {
        _connected = true;
      });
    }
  }

  Future<String> getBilling() async {
    String docID = '';
    await FirebaseFirestore.instance
        .collection('billing')
        .orderBy('date', descending: true)
        .get()
        .then((QuerySnapshot querySnapshot) => {
              querySnapshot.docs.forEach((doc) async {
                debugPrint(doc.id);
                if (doc['status'] == 'open') {
                  docID = doc.id;
                }
              })
            });
    return docID;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                  onPressed: () {
                    showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return StatefulBuilder(builder: (BuildContext context, StateSetter nstate){
                            return SizedBox(
                            height: 300,
                            child: Expanded(
                              child: RefreshIndicator(
                                onRefresh: () => bluetoothPrint.startScan(
                                    timeout: Duration(seconds: 4)),
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: <Widget>[
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: <Widget>[
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 10, horizontal: 10),
                                            child: Text(tips),
                                          ),
                                        ],
                                      ),
                                      Divider(),
                                      StreamBuilder<List<BluetoothDevice>>(
                                        stream: bluetoothPrint.scanResults,
                                        initialData: [],
                                        builder: (c, snapshot) => Column(
                                          children: snapshot.data!
                                              .map((d) => ListTile(
                                                    title: Text(d.name ?? ''),
                                                    subtitle: Text(d.address ?? ''),
                                                    onTap: () async {
                                                      nstate(() {
                                                        _device = d;
                                                      });
                                                    },
                                                    trailing: _device != null &&
                                                            _device!.address ==
                                                                d.address
                                                        ? Icon(
                                                            Icons.check,
                                                            color: Colors.green,
                                                          )
                                                        : null,
                                                  ))
                                              .toList(),
                                        ),
                                      ),
                                      Divider(),
                                      Container(
                                        padding: EdgeInsets.fromLTRB(20, 5, 20, 10),
                                        child: Column(
                                          children: <Widget>[
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: <Widget>[
                                                OutlinedButton(
                                                  child: Text('connect'),
                                                  onPressed: _connected
                                                      ? null
                                                      : () async {
                                                          if (_device != null &&
                                                              _device!.address !=
                                                                  null) {
                                                            nstate(() {
                                                              tips =
                                                                  'connecting...';
                                                            });
                                                            await bluetoothPrint
                                                                .connect(_device!);
                                                          } else {
                                                            nstate(() {
                                                              tips =
                                                                  'please select device';
                                                            });
                                                            print(
                                                                'please select device');
                                                          }
                                                        },
                                                ),
                                                SizedBox(width: 10.0),
                                                OutlinedButton(
                                                  child: Text('disconnect'),
                                                  onPressed: _connected
                                                      ? () async {
                                                          nstate(() {
                                                            tips =
                                                                'disconnecting...';
                                                          });
                                                          await bluetoothPrint
                                                              .disconnect();
                                                        }
                                                      : null,
                                                ),
                                              ],
                                            ),
                                           
                                            OutlinedButton(
                                              child: Text('print selftest'),
                                              onPressed: _connected
                                                  ? () async {
                                                      await bluetoothPrint
                                                          .printTest();
                                                    }
                                                  : null,
                                            )
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                          });
                        });
                  },
                  icon: const Icon(Icons.settings_applications)),
                  const Spacer(),
                  GestureDetector(
                    onTap: (){
                      printAll('');
                    },
                    child: Row(
                      children: const [
                        Text('Print All'),
                        SizedBox(width: 10,),
                        Icon(Icons.print)
                      ],
                    ),
                  ),
                  
            ],
          ),
          billMemberList(context),
        ],
      ),
    );
  }

  Future<List<BillingMember>> getMembersBilling() async {
    billingMember.clear();
    String docID = await getBilling();

    await FirebaseFirestore.instance
        .collection('membersBilling')
        .where('billingId', isEqualTo: docID)
        .get()
        .then((QuerySnapshot querySnapshot) => {
              querySnapshot.docs.forEach((doc) async {
                if (doc['toBill'] == true) {
                  DateTime dateBill = (doc['dateBill'] as Timestamp).toDate();
                  DateTime dueBalance =
                      (doc['dueDateBalance'] as Timestamp).toDate();
                  BillingMember bill = BillingMember(
                      doc.id,
                      doc['memberId'].toString(),
                      doc['name'].toString(),
                      doc['areaId'].toString(),
                      doc['connectionId'].toString(),
                      double.parse(doc['previousReading'].toString()),
                      double.parse(doc['currentReading'].toString()),
                      doc['dateRead'].toString(),
                      double.parse(doc['totalCubic'].toString()),
                      double.parse(doc['billingPrice'].toString()),
                      doc['flatRate'].toString(),
                      double.parse(doc['flatRatePrice'].toString()),
                      doc['status'].toString(),
                      doc['toBill'],
                      double.parse(doc['balance'].toString()),
                      dateBill.toString(),
                      dueBalance.toString());

                  billingMember.add(bill);
                }
              })
            });
    return billingMember;
  }

  Widget billMemberList(BuildContext context) {
    return FutureBuilder(
        future: fBilling,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.data.length <= 0) {
              // ignore: avoid_unnecessary_containers
              return Center(
                child: Column(
                  // ignore: prefer_const_literals_to_create_immutables
                  children: [
                    const Icon(
                      Icons.folder_outlined,
                      color: kColorDarkBlue,
                      size: 70,
                    ),
                    const Text('No area found.'),
                  ],
                ),
              );
            } else {
              return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        Container(
                          color: Colors.transparent,
                          child: GestureDetector(
                            onTap: () {},
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 2, 20, 2),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      snapshot.data[index].name,
                                      style: kTextStyleHeadline2Dark,
                                    ),
                                  ),
                                  IconButton(
                                      onPressed: () {
                                          printAll(snapshot.data[index].id);
                                      }, icon: Icon(Icons.print))
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  });
            }
          } else {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                Center(
                  child: Text('loading.'),
                ),
              ],
            );
          }
        });
  }

  printAll(String docID) async {
    Map<String, dynamic> config = Map();
    List<LineText> list = [];
    if(docID == ''){
      for (var v in billingMember) {
      if(v.id == docID){
        list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: '********************************',
          weight: 1,
          align: LineText.ALIGN_CENTER,
          linefeed: 1));
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'PIWAS BILLING',
          weight: 1,
          align: LineText.ALIGN_CENTER,
          linefeed: 1));
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'Name: ${v.name.toString()}',
          weight: 1,
          align: LineText.ALIGN_LEFT,
          linefeed: 1));
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'Billing Date: ${v.dateBill.toString()}',
          weight: 1,
          align: LineText.ALIGN_LEFT,
          linefeed: 1));
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: '\n',
          weight: 1,
          align: LineText.ALIGN_CENTER,
          linefeed: 1));
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'Previous meter: ${v.previousReading.toString()}',
          weight: 1,
          align: LineText.ALIGN_LEFT,
          linefeed: 1));
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'Current meter: ${v.currentReading.toString()}',
          weight: 1,
          align: LineText.ALIGN_LEFT,
          linefeed: 1));
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'Total meter: ${v.totalCubic.toString()}',
          weight: 1,
          align: LineText.ALIGN_LEFT,
          linefeed: 1));
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: '\n',
          weight: 1,
          align: LineText.ALIGN_CENTER,
          linefeed: 1));
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'Balance w/ 2%:  ${v.balance.toString()}',
          weight: 1,
          align: LineText.ALIGN_LEFT,
          linefeed: 1));
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: '\n',
          weight: 1,
          align: LineText.ALIGN_CENTER,
          linefeed: 1));
      list.add(LineText(
          underline: 1,
          type: LineText.TYPE_TEXT,
          content: 'Payable:         ${v.billingPrice}',
          weight: 1,
          align: LineText.ALIGN_LEFT,
          linefeed: 1));
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: '\n',
          weight: 3,
          align: LineText.ALIGN_LEFT,
          linefeed: 1));
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'Please pay on or before:',
          weight: 3,
          align: LineText.ALIGN_LEFT,
          linefeed: 1));
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: '${v.dateBill}',
          weight: 3,
          align: LineText.ALIGN_LEFT,
          linefeed: 1));
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: '********************************',
          weight: 1,
          align: LineText.ALIGN_CENTER,
          linefeed: 1));
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: '\n',
          weight: 3,
          align: LineText.ALIGN_LEFT,
          linefeed: 1));
      }
    }
    }else{
    for (var v in billingMember) {
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: '********************************',
          weight: 1,
          align: LineText.ALIGN_CENTER,
          linefeed: 1));
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'PIWAS BILLING',
          weight: 1,
          align: LineText.ALIGN_CENTER,
          linefeed: 1));
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'Name: ${v.name.toString()}',
          weight: 1,
          align: LineText.ALIGN_LEFT,
          linefeed: 1));
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'Billing Date: ${v.dateBill.toString()}',
          weight: 1,
          align: LineText.ALIGN_LEFT,
          linefeed: 1));
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: '\n',
          weight: 1,
          align: LineText.ALIGN_CENTER,
          linefeed: 1));
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'Previous meter: ${v.previousReading.toString()}',
          weight: 1,
          align: LineText.ALIGN_LEFT,
          linefeed: 1));
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'Current meter: ${v.currentReading.toString()}',
          weight: 1,
          align: LineText.ALIGN_LEFT,
          linefeed: 1));
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'Total meter: ${v.totalCubic.toString()}',
          weight: 1,
          align: LineText.ALIGN_LEFT,
          linefeed: 1));
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: '\n',
          weight: 1,
          align: LineText.ALIGN_CENTER,
          linefeed: 1));
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'Balance w/ 2%:  ${v.balance.toString()}',
          weight: 1,
          align: LineText.ALIGN_LEFT,
          linefeed: 1));
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: '\n',
          weight: 1,
          align: LineText.ALIGN_CENTER,
          linefeed: 1));
      list.add(LineText(
          underline: 1,
          type: LineText.TYPE_TEXT,
          content: 'Payable:         ${v.billingPrice}',
          weight: 1,
          align: LineText.ALIGN_LEFT,
          linefeed: 1));
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: '\n',
          weight: 3,
          align: LineText.ALIGN_LEFT,
          linefeed: 1));
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'Please pay on or before:',
          weight: 3,
          align: LineText.ALIGN_LEFT,
          linefeed: 1));
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: '${v.dateBill}',
          weight: 3,
          align: LineText.ALIGN_LEFT,
          linefeed: 1));
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: '********************************',
          weight: 1,
          align: LineText.ALIGN_CENTER,
          linefeed: 1));
      list.add(LineText(
          type: LineText.TYPE_TEXT,
          content: '\n',
          weight: 3,
          align: LineText.ALIGN_LEFT,
          linefeed: 1));
    }}

    await bluetoothPrint.printReceipt(config, list);
  }
}
