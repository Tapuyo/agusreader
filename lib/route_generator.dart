
import 'package:agus_reader/sample/sample.dart';
import 'package:agus_reader/views/billing/bill.dart';
import 'package:agus_reader/views/home/home.dart';
import 'package:agus_reader/routes.dart';
import 'package:agus_reader/splash.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    //final args = settings.arguments;

    switch (settings.name) {
      case Routes.splash:
        return CupertinoPageRoute(builder: (_) => const SplashScreen());
      case Routes.home:
        return CupertinoPageRoute(builder: (_) => const MyHomePage());
        // return CupertinoPageRoute(builder: (_) =>  BillingPage());

      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return CupertinoPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: const Center(
          child: Text('Error'),
        ),
      );
    });
  }
}