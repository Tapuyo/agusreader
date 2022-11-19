import 'package:agus_reader/models/area_model.dart';
import 'package:agus_reader/models/members_billing_model.dart';
import 'package:agus_reader/services/sqlite_service.dart';
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
  late Future<List<BillingMember>> fBilling;
  List<BillingMember> billingMember = [];

  //Printing
  BluetoothPrint bluetoothPrint = BluetoothPrint.instance;
  bool _connected = false;
  BluetoothDevice? _device;
  String tips = 'no device connect';

  //for search
  TextEditingController _nameController = TextEditingController();
  List<BillingMember> _foundUsers = [];
  Future<List<BillingMember>>? billingOffline;

  //for dropdown
  List<Area> _areas = [];
  String? valDropdown;

  @override
  void initState() {
    super.initState();
    fBilling = getMembersBilling();
    WidgetsBinding.instance.addPostFrameCallback((_) => initBluetooth());
    getArea();
  }

  Future<void> initBluetooth() async {
    try {
      bluetoothPrint.startScan(timeout: const Duration(seconds: 4));

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
    } catch (e) {
      debugPrint('Bluetooth error');
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
            width: MediaQuery.of(context).size.width - 40,
            height: 70,
            child: TextField(
              controller: _nameController,
              onChanged: (value) {
                fBilling = onMembersBilling(value);
              },
              decoration: InputDecoration(
                suffixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                labelText: 'Search Name',
              ),
            )),
        // ignore: prefer_const_constructors
        Row(
          children: [
            Container(
              width: MediaQuery.of(context).size.width - 98,
              height: 40,
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
                  items: _areas
                      .map(
                        (map) => DropdownMenuItem(
                          child: Text(map.description,
                              style: const TextStyle(color: Colors.black),
                              textAlign: TextAlign.right),
                          value: map.id,
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    // newsetState(() {
                    //   choosMenu = value.toString();
                    //   getList(value.toString());
                    //   valDropdown = value.toString();
                    // });
                    setState(() {
                      fBilling = onBarangayBilling(value.toString());
                      valDropdown = value.toString();
                    });
                  },
                ),
              ),
            ),
            IconButton(
                onPressed: () {
                  showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return StatefulBuilder(builder:
                            (BuildContext context, StateSetter nstate) {
                          return SizedBox(
                            height: 300,
                            child: Expanded(
                              child: RefreshIndicator(
                                onRefresh: () => bluetoothPrint.startScan(
                                    timeout: const Duration(seconds: 4)),
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: <Widget>[
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10, horizontal: 10),
                                            child: Text(tips),
                                          ),
                                        ],
                                      ),
                                      const Divider(),
                                      StreamBuilder<List<BluetoothDevice>>(
                                        stream: bluetoothPrint.scanResults,
                                        initialData: const [],
                                        builder: (c, snapshot) => Column(
                                          children: snapshot.data!
                                              .map((d) => ListTile(
                                                    title: Text(d.name ?? ''),
                                                    subtitle:
                                                        Text(d.address ?? ''),
                                                    onTap: () async {
                                                      nstate(() {
                                                        _device = d;
                                                      });
                                                    },
                                                    trailing: _device != null &&
                                                            _device!.address ==
                                                                d.address
                                                        ? const Icon(
                                                            Icons.check,
                                                            color: Colors.green,
                                                          )
                                                        : null,
                                                  ))
                                              .toList(),
                                        ),
                                      ),
                                      const Divider(),
                                      Container(
                                        padding: const EdgeInsets.fromLTRB(
                                            20, 5, 20, 10),
                                        child: Column(
                                          children: <Widget>[
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: <Widget>[
                                                OutlinedButton(
                                                  child: const Text('connect'),
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
                                                                .connect(
                                                                    _device!);
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
                                                const SizedBox(width: 10.0),
                                                OutlinedButton(
                                                  child:
                                                      const Text('disconnect'),
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
                                              child:
                                                  const Text('print selftest'),
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
          ],
        ),
        SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
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
                      'Amount',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18.0,
                      ),
                    ),
                    const Spacer(
                      // width: 117,
                      flex: 4,
                    ),
                    GestureDetector(
                      onTap: () {
                        printAll('');
                      },
                      child: Row(
                        children: const [
                          Text(
                            'Print All',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 18.0,
                            ),
                          ),
                          Icon(Icons.print)
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(
                color: Colors.black,
                height: 0.0,
                thickness: 1,
                indent: 0.0,
                endIndent: 0.0,
              ),
              Container(
                // padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                child: billMemberList(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  getArea() async {
    _areas.clear();
    _areas = await SqliteService.getAreas();
  }

  Future<List<BillingMember>> onMembersBilling(String text) async {
    billingMember.clear();
    String docID = await getBilling();

    await FirebaseFirestore.instance
        .collection('membersBilling')
        .where('billingId', isEqualTo: docID)
        .get()
        .then((QuerySnapshot querySnapshot) => {
              querySnapshot.docs.forEach((doc) async {
                if (text.isEmpty) {
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
                } else {
                  if (doc['toBill'] == true) {
                    print(doc['name'].toString());
                    //   String username = doc['name'].toLowerCase.toString();
                    if (doc['name']
                        .toLowerCase()
                        .contains(text.toLowerCase())) {
                      DateTime dateBill =
                          (doc['dateBill'] as Timestamp).toDate();
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
                  }
                }
              })
            });
    return billingMember;
  }

  Future<List<BillingMember>> onBarangayBilling(String text) async {
    billingMember.clear();
    String docID = await getBilling();

    await FirebaseFirestore.instance
        .collection('membersBilling')
        .where('billingId', isEqualTo: docID)
        .get()
        .then((QuerySnapshot querySnapshot) => {
              querySnapshot.docs.forEach((doc) async {
                if (text.isEmpty) {
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
                } else {
                  if (doc['toBill'] == true) {
                    print(doc['areaId'].toString());
                    //   String username = doc['name'].toLowerCase.toString();
                    if (doc['areaId'].toLowerCase().toString() ==
                        text.toLowerCase().toString()) {
                      DateTime dateBill =
                          (doc['dateBill'] as Timestamp).toDate();
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
                  }
                }
              })
            });
    return billingMember;
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
              return SingleChildScrollView(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height - 342,
                    child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: snapshot.data.length,
                        itemBuilder: (context, index) {
                          return Column(
                            children: [
                              Container(
                                color: Colors.transparent,
                                child: GestureDetector(
                                  onTap: () {},
                                  child: Row(
                                    // mainAxisAlignment:
                                    //     MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: Text(
                                          snapshot.data[index].name,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 18.0,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          snapshot.data[index].balance
                                              .toString(),
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 18.0,
                                          ),
                                        ),
                                      ),
                                      Spacer(),
                                      IconButton(
                                          onPressed: () {
                                            printAll(snapshot.data[index].id);
                                          },
                                          icon: const Icon(Icons.print))
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                  ),
                ),
              );
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
    if (docID == '') {
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
      }
    } else {
      for (var v in billingMember.where((element) => element.id == docID)) {
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

    await bluetoothPrint.printReceipt(config, list);
  }
}
