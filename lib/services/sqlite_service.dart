import 'package:agus_reader/models/area_model.dart';
import 'package:agus_reader/models/billing_models.dart';
import 'package:agus_reader/models/reader_model';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/members_billing_model.dart';
class SqliteService {
  static Future<Database> initizateDb() async {
    String path = await getDatabasesPath();
    
    return openDatabase(
      join(path, 'database.db'),
      onCreate: (database, version) async {
         await database.execute( "CREATE TABLE Billing(id INTEGER PRIMARY KEY AUTOINCREMENT,  billingID TEXT, month TEXT, year TEXT, status TEXT, creator TEXT)",);
         await database.execute( "CREATE TABLE MembersBillings(id INTEGER PRIMARY KEY AUTOINCREMENT,  billingID TEXT, billMemId TEXT, name TEXT, reading TEXT, status TEXT, areaid TEXT, deateread TEXT, prev TEXT, connectionId TEXT)",);
         await database.execute( "CREATE TABLE Areamap(id TEXT,code TEXT, description TEXT, name TEXT, status TEXT)",);
         await database.execute( "CREATE TABLE Readermap(id TEXT,address TEXT, contact TEXT, firstname TEXT, lastname TEXT, mname TEXT)",);

     },
     version: 1,
    );
  }

   static Future<bool> checkBillingExist(String billID) async {
    final db = await initizateDb();
    final List<Map<String, Object?>> queryResult = 
      await db.query('Billing',where: 'billingID = ?', whereArgs: [billID]);

    if(queryResult.isNotEmpty){
      return true;
    }else{
      return false;
    }
  }
   static Future<bool> checkAreaExist(String id) async {
    final db = await initizateDb();
    final List<Map<String, Object?>> queryResult = 
      await db.query('Areamap',where: 'id = ?', whereArgs: [id]);

    if(queryResult.isNotEmpty){
      return true;
    }else{
      return false;
    }
  }

static Future<bool> checkReaderExist(String id) async {
    final db = await initizateDb();
    final List<Map<String, Object?>> queryResult = 
      await db.query('Readermap',where: 'firstname = ?', whereArgs: [id]);

    if(queryResult.isNotEmpty){
      return true;
    }else{
      return false;
    }
}
  // static Future<Database> initizateDbarea() async {
  //   String path = await getDatabasesPath();
    
  //   return openDatabase(
  //     join(path, 'database.db'),
  //     onCreate: (database, version) async {
  //        await database.execute( "CREATE TABLE Area(id INTEGER PRIMARY KEY AUTOINCREMENT,  code TEXT, description TEXT, name TEXT, status TEXT)",);
  //      },
  //    version: 1,
  //   );
  // }

  static Future<List<MembersBilling>> getMemberBills(String billID) async {
    print(billID);
    final db = await initizateDb();
    final List<Map<String, Object?>> queryResult = 
     await db.query('MembersBillings',where: 'billingID = ?', whereArgs: [billID]);

    print(queryResult.length);
    return queryResult.map((e) => MembersBilling.fromMap(e)).toList();
  }

   static Future<List<Area>> getAreas() async {
    final db = await initizateDb();
    final List<Map<String, Object?>> queryResult = 
     await db.query('Areamap',);

    print(queryResult.length);
    return queryResult.map((e) => Area.fromMap(e)).toList();
  }
    

  static Future<List<Billing>> getItems() async {
    final db = await initizateDb();
    final List<Map<String, Object?>> queryResult = 
     await db.query('Billing');

    print(queryResult.length);
    return queryResult.map((e) => Billing.fromMap(e)).toList();
  }
    
  static Future<int> createItem(Billing note) async {
    final Database db = await initizateDb();
    final id = await db.insert(
      'Billing', note.toMap(), 
      conflictAlgorithm: ConflictAlgorithm.replace);

    return id;
   }

  static Future<int> downloadReading(MembersBilling membersBilling) async {
    final Database db = await initizateDb();
    final id = await db.insert(
      'MembersBillings', membersBilling.toMap(), 
      conflictAlgorithm: ConflictAlgorithm.replace);
    print('download result $id');
    return id;
   }
   
static Future<int> downloadArea(Area areamap) async {
    final Database db = await initizateDb();
    try {
       await db.delete("Areamap",);
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
    final id = await db.insert(
      'Areamap', areamap.toMap(), 
      conflictAlgorithm: ConflictAlgorithm.replace);
    print('download result $id');
    return id;
   }

   static Future<int> downloadReader(Reader readermap) async {
    print('im here');
    final Database db = await initizateDb();
    try {
       await db.delete("Readermap",);
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
    final id = await db.insert(
      'Readermap', readermap.toMap(), 
      conflictAlgorithm: ConflictAlgorithm.replace);
    print('download result $id');
    return id;
   }


  static Future<int> deleteItem(String id) async {
   final db = await SqliteService.initizateDb();
   int res = 0;
    try {
      res = await db.delete("Billing", where: "billingID = ?", whereArgs: [id]);
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
    return res;
  }

  static Future<int> updateItem(String id) async {
   final db = await SqliteService.initizateDb();
   int res = 0;
    
      res = await db.rawUpdate('UPDATE Billing SET month = ? WHERE billingID = ?', ['August',id]);
   
    return res;
  }


  static Future<int> updateBilling(String id, reading) async {
   final db = await SqliteService.initizateDb();
   int res = 0;
    
      res = await db.rawUpdate('UPDATE MembersBillings SET reading = ? WHERE billMemId = ?', [reading,id]);
   
    return res;
  }

    static Future<int> updateBillingStatus(String id) async {
   final db = await SqliteService.initizateDb();
   int res = 0;
    
      res = await db.rawUpdate('UPDATE MembersBillings SET status = ? WHERE billMemId = ?', ['upload',id]);
   
    return res;
  }

  

}