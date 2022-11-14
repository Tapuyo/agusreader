import 'package:agus_reader/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:agus_reader/models/reader_model';
import 'package:agus_reader/services/sqlite_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SignIn());
}

class SignIn extends StatelessWidget {
  const SignIn({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: MyStatefulWidget(),
      ),
    );
  }
}

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({Key? key}) : super(key: key);

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  @override
  void initState() {
    super.initState();
    getReader();
  }

  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  String email = '';
  String password = '';
  String error = '';
  String readerID = '';

  List<Reader> reader = [];

  Future<List<Reader>> getReader() async {
    final ConnectivityResult result = await Connectivity().checkConnectivity();
    if (result != ConnectivityResult.none) {
      await FirebaseFirestore.instance
          .collection('reader')
          .get()
          .then((QuerySnapshot querySnapshot) => {
                querySnapshot.docs.forEach((doc) async {
                  debugPrint(doc.data().toString());
                  setState(() {
                    readerID = doc.id;
                  });
                  await downloadReader(doc.id, doc['address'], doc['contact'],
                      doc['firstname'], doc['lastname'], doc['mname']);
                })
              });
    } else {
      print('Please check your connection');
    }
    return reader;
  }

  Future<int> downloadReader(String id, String address, String contact,
      String firstname, String lastname, String mname) async {
    Reader reader = Reader(id, address, contact, firstname, lastname, mname);
    print(reader.toString());
    final result = await SqliteService.downloadReader(reader);

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
            color: Colors.transparent, borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          child: Stack(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 20, 15, 0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'PIWAS READER',
                            style: TextStyle(
                                color: Colors.blue[500],
                                fontWeight: FontWeight.w600,
                                fontSize: 25),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
                          Text(
                            'Agus App',
                            style: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                                fontSize: 15),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              padding: const EdgeInsets.all(10),
                              child: Text(
                                'Sign in',
                                style: TextStyle(
                                    color: Colors.blue[500],
                                    fontWeight: FontWeight.w700,
                                    fontSize: 45),
                                textAlign: TextAlign.right,
                              )),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          labelText: 'Enter email',
                        ),
                        validator: (val) =>
                            val!.isEmpty ? 'Enter an email' : null,
                        onChanged: (val) {
                          setState(() {
                            email = val;
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: TextFormField(
                        obscureText: true,
                        controller: passwordController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          labelText: 'Password',
                        ),
                        validator: (val) => val!.length < 6
                            ? 'Enter a 6+ valid password'
                            : null,
                        onChanged: (val) {
                          setState(() {
                            password = val;
                          });
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: TextButton(
                        onPressed: () {
                          //forgot password screen
                        },
                        child: const Text(
                          'Forgot Password',
                          style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                              fontSize: 20),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width,
                      height: 90,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          primary: Colors.blue[500],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ), // Background color
                        ),
                        onPressed: () async {
                          checkAreaExist(email);
                        },
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 25),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
                      child: SizedBox(
                        child: Image.asset(
                          'assets/images/piwas.png',
                          height: 250,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ],
// )
            ],
          ),
        ));
  }

  Future<void> checkAreaExist(String billID) async {
    var res = await SqliteService.checkReaderExist(billID);
    setState(() {
      if (res) {
        print('user found');
      } else {
        print('not found');
      }
    });
  }
}
