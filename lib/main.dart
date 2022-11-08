import 'package:agus_reader/constants/constant.dart';
import 'package:agus_reader/provider/billing_provider.dart';
import 'package:agus_reader/route_generator.dart';
import 'package:agus_reader/routes.dart';
import 'package:agus_reader/services/sqlite_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => BillingProvider()),
    ],child: const MyApp(),)
  
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SqliteService.initizateDb();
    return MaterialApp(
      title: 'Agus',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Agus'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);


  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: MyBehavior(),
          child: child!,
        );
      },
      title: 'Agus Pilar Water Billing System',
      initialRoute: Routes.splash,
      onGenerateRoute: RouteGenerator.generateRoute,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        platform: TargetPlatform.iOS,
        scaffoldBackgroundColor: Colors.white,
        toggleableActiveColor: kColorPrimary,
        appBarTheme: const AppBarTheme(
          elevation: 1,
          color: Colors.white,
          iconTheme: IconThemeData(
            color: kColorPrimary,
          ),
          actionsIconTheme: IconThemeData(
            color: kColorPrimary,
          ), systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        dividerColor: Colors.grey[300],
       
        // ignore: prefer_const_constructors
        iconTheme: IconThemeData(
          color: kColorBlue,
        ),
        fontFamily: 'NunitoSans',
        cardTheme: CardTheme(
          elevation: 0,
          color: const Color(0xffEBF2F5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            //side: BorderSide(width: 1, color: Colors.grey[200]),
          ),
        ),
      ),
    );
  }
}

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}