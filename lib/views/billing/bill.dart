import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';

import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BillingPage extends StatefulWidget {
  const BillingPage({Key? key}) : super(key: key);

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  BluetoothPrint bluetoothPrint = BluetoothPrint.instance;

  bool _connected = false;
  BluetoothDevice? _device;
  String tips = 'no device connect';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => initBluetooth());
  }

    Future<void> initBluetooth() async {
    bluetoothPrint.startScan(timeout: Duration(seconds: 4));

    bool isConnected=await bluetoothPrint.isConnected??false;

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

    if(isConnected) {
      setState(() {
        _connected=true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Column(
          children: [
            const SizedBox(height: 50,),
            printerWidget()
          ],
        ),
    );
  }

  Widget printerWidget(){
    return Expanded(
      child: RefreshIndicator(
              onRefresh: () =>
                  bluetoothPrint.startScan(timeout: Duration(seconds: 4)),
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                          child: Text(tips),
                        ),
                      ],
                    ),
                    Divider(),
                    StreamBuilder<List<BluetoothDevice>>(
                      stream: bluetoothPrint.scanResults,
                      initialData: [],
                      builder: (c, snapshot) => Column(
                        children: snapshot.data!.map((d) => ListTile(
                          title: Text(d.name??''),
                          subtitle: Text(d.address??''),
                          onTap: () async {
                            setState(() {
                              _device = d;
                            });
                          },
                          trailing: _device!=null && _device!.address == d.address?Icon(
                            Icons.check,
                            color: Colors.green,
                          ):null,
                        )).toList(),
                      ),
                    ),
                    Divider(),
                    Container(
                      padding: EdgeInsets.fromLTRB(20, 5, 20, 10),
                      child: Column(
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              OutlinedButton(
                                child: Text('connect'),
                                onPressed:  _connected?null:() async {
                                  if(_device!=null && _device!.address !=null){
                                    setState(() {
                                      tips = 'connecting...';
                                    });
                                    await bluetoothPrint.connect(_device!);
                                  }else{
                                    setState(() {
                                      tips = 'please select device';
                                    });
                                    print('please select device');
                                  }
                                },
                              ),
                              SizedBox(width: 10.0),
                              OutlinedButton(
                                child: Text('disconnect'),
                                onPressed:  _connected?() async {
                                  setState(() {
                                    tips = 'disconnecting...';
                                  });
                                  await bluetoothPrint.disconnect();
                                }:null,
                              ),
                            ],
                          ),
                          Divider(),
                          OutlinedButton(
                            child: Text('print receipt(esc)'),
                            onPressed:  _connected?() async {
                              Map<String, dynamic> config = Map();
                              List<LineText> list = [];
    
                              list.add(LineText(type: LineText.TYPE_TEXT, content: '**********************************************', weight: 1, align: LineText.ALIGN_CENTER,linefeed: 1));
                              list.add(LineText(type: LineText.TYPE_TEXT, content: 'Piwas', weight: 1, align: LineText.ALIGN_CENTER, fontZoom: 2, linefeed: 1));
                              list.add(LineText(linefeed: 1));
    
    
                              list.add(LineText(type: LineText.TYPE_TEXT, content: '混凝土C30', align: LineText.ALIGN_LEFT, relativeX: 0,y: 0, linefeed: 0));
                              list.add(LineText(type: LineText.TYPE_TEXT, content: 'Billing date: ${DateTime.now()}', align: LineText.ALIGN_LEFT, relativeX: 350, y: 0, linefeed: 0));
                              list.add(LineText(type: LineText.TYPE_TEXT, content: 'Agus ph', align: LineText.ALIGN_LEFT, relativeX: 500, y: 0, linefeed: 1));
    
                              list.add(LineText(type: LineText.TYPE_TEXT, content: '**********************************************', weight: 1, align: LineText.ALIGN_CENTER,linefeed: 1));
                              list.add(LineText(linefeed: 1));
    
                              // ByteData data = await rootBundle.load("assets/images/bluetooth_print.png");
                              // List<int> imageBytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
                              // String base64Image = base64Encode(imageBytes);
                              // list.add(LineText(type: LineText.TYPE_IMAGE, content: base64Image, align: LineText.ALIGN_CENTER, linefeed: 1));
    
                              await bluetoothPrint.printReceipt(config, list);
                            }:null,
                          ),
                          OutlinedButton(
                            child: Text('print label(tsc)'),
                            onPressed:  _connected?() async {
                              Map<String, dynamic> config = Map();
                              config['width'] = 40; // 标签宽度，单位mm
                              config['height'] = 70; // 标签高度，单位mm
                              config['gap'] = 2; // 标签间隔，单位mm
    
                              // x、y坐标位置，单位dpi，1mm=8dpi
                              List<LineText> list = [];
                              list.add(LineText(type: LineText.TYPE_TEXT, x:10, y:10, content: 'A Title'));
                              list.add(LineText(type: LineText.TYPE_TEXT, x:10, y:40, content: 'this is content'));
                              list.add(LineText(type: LineText.TYPE_QRCODE, x:10, y:70, content: 'qrcode i\n'));
                              list.add(LineText(type: LineText.TYPE_BARCODE, x:10, y:190, content: 'qrcode i\n'));
    
                              // List<LineText> list1 = [];
                              // ByteData data = await rootBundle.load("assets/images/guide3.png");
                              // List<int> imageBytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
                              // String base64Image = base64Encode(imageBytes);
                              // list1.add(LineText(type: LineText.TYPE_IMAGE, x:10, y:10, content: base64Image,));
    
                              await bluetoothPrint.printLabel(config, list);
                              // await bluetoothPrint.printLabel(config, list1);
                            }:null,
                          ),
                          OutlinedButton(
                            child: Text('print selftest'),
                            onPressed:  _connected?() async {
                              await bluetoothPrint.printTest();
                            }:null,
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}