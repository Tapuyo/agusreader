import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/animation/animation_controller.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/ticker_provider.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../models/billing_models.dart';

class OnlineReading extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final val = useState<int>(0);

    useEffect(
      () {
        Future.microtask(() async{
          await getBilling(val);
        });

        return;
      },
      [],
    );

    return Scaffold(
      body: Column(children: [
        const SizedBox(
          height: 100,
        ),
        IconButton(
          onPressed: () {
            val.value = val.value + 1;
          },
          icon: const Icon(Icons.add),
        ),
        Text(val.value.toString())
      ]),
    );
  }


  Future<List<Billing>> getBilling(ValueNotifier melvin) async {
    List<Billing> bills = [];
    await FirebaseFirestore.instance
        .collection('billing')
        .orderBy('date', descending: true)
        .get()
        .then((QuerySnapshot querySnapshot) => {
              querySnapshot.docs.forEach((doc) async {
                debugPrint(doc.id);
                if (doc['status'] == 'open') {
                
                  Billing bill = Billing(doc.id, doc['month'], doc['year'],
                      doc['status'], doc['user']);
                  bills.add(bill);
                }
              })
            });
    melvin.value = bills.length;
    return bills;
  }
}
