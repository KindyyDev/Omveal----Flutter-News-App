import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:news/WelcomePage.dart';
import 'Helper/Session.dart';
import 'Helper/String.dart';






class SplashScreen extends StatefulWidget {
  @override
  _SplashScreen createState() => _SplashScreen();
}

class _SplashScreen extends State<SplashScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    startTime();
    super.initState();
  }

  @override
  void dispose() {
    // SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // SystemChrome.setEnabledSystemUIOverlays([]);
    return Scaffold(
      key: _scaffoldKey,
      body: Container(
        color: Colors.black,
        width: double.infinity,
        height: double.infinity,
        // decoration: getBackGround(context),
        child: Center(
          child: Image.asset(
            'assets/images/redtitle_logo.png',
          ),
        ),
      ),
    );
  }

  //set timer of navigate the page
  startTime() async {
    var _duration = Duration(seconds: 2);
    return Timer(_duration, navigationPage);
  }

  //navigate page route
  Future<void> navigationPage() async {
    bool isFirstTime = await getPrefrenceBool(ISFIRSTTIME);
    if (isFirstTime) {
      Navigator.pushReplacementNamed(context, "/home");
    } else {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WelcomePage(),
          )
      );
    }
  }
}
