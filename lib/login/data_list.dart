// ignore_for_file: avoid_print

import 'package:agus_reader/login/data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DataList extends StatefulWidget {
  const DataList({Key? key}) : super(key: key);

  @override
  State<DataList> createState() => _DataListState();
}

class _DataListState extends State<DataList> {
  @override
  Widget build(BuildContext context) {
    
    final members = Provider.of<List<memData>>(context);
    // print(members.docs);
    // for (var mem in members.docs){
    //   print(mem.data());
    // }
    // members!.forEach((members){
    //   print(members.name);
    //   print(members.status);
    //   print(members.age.toString());
    // });
    return ListView.builder(
      itemCount: members.length,
      itemBuilder: (context, index){
        // return DataTile(members: members[index]);
        return const Text('data');
      }
    );
  }
}