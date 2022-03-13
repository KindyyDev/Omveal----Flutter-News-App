import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Helper/Color.dart';
import 'Helper/Constant.dart';
import 'Helper/Session.dart';
import 'Helper/String.dart';
import 'Login.dart';

class PrivacyPolicy extends StatefulWidget {
  final String title;
  final String from;

  const PrivacyPolicy({Key key, this.title, this.from}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StatePrivacy();
  }
}

class StatePrivacy extends State<PrivacyPolicy> with TickerProviderStateMixin {
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  String privacy;
  String url = "";
  Animation buttonSqueezeanimation;
  AnimationController buttonController;
  bool _isNetworkAvail = true;

  @override
  void initState() {
    super.initState();
    getSetting();
  }



  //set appbar
  getAppBar() {
    return AppBar(
      leadingWidth: 60.0,
      elevation: 0.0,
      centerTitle: true,
      title: Padding(
          padding: EdgeInsetsDirectional.only(bottom: 5.0),
          child: Text(widget.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headline6.copyWith(
                  color: colors.primary, fontWeight: FontWeight.bold))),
      leading: Builder(builder: (BuildContext context) {
        return InkWell(
          onTap: () {
            if (widget.from == getTranslated(context,'login_lbl')) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Login()),
              );
            } else {
              Navigator.of(context).pop();
            }
          },
          child: Image.asset(
            "assets/images/back_icon.png",
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return _isLoading
        ? Scaffold(
            key: _scaffoldKey,
            appBar: getAppBar(),
            body: Container(
              height: height,
              width: width,
              child: showCircularProgress(_isLoading, colors.primary),
            ))
        : Scaffold(
            key: _scaffoldKey,
            appBar: getAppBar(),
            body: Container(
                height: height,
                width: width,
                padding: EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
                child: Html(
                  data: privacy,
                  customTextAlign: (_) => TextAlign.start,
                  defaultTextStyle: Theme.of(context)
                      .textTheme
                      .subtitle2
                      .copyWith(color: Theme.of(context).colorScheme.fontColor),
                  onLinkTap:
                      (String url) async {
                    if (await canLaunch(
                        url)) {
                      await launch(
                        url,
                        forceSafariVC:
                        false,
                        forceWebView: false,
                      );
                    } else {
                      throw 'Could not launch $url';
                    }
                  },
                )));
  }

  //get setting api in fetch privacy data
  Future<void> getSetting() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      var param = {
        ACCESS_KEY: access_key,
      };
      Response response =
          await post(Uri.parse(getSettingApi), body: param, headers: headers)
              .timeout(Duration(seconds: timeOut));

      var getdata = json.decode(response.body);
      String error = getdata["error"];
      if (error == "false") {
        if (widget.title == getTranslated(context,'pri_policy'))
          privacy = getdata["data"][PRIVACY_POLICY].toString();
        else if (widget.title == getTranslated(context,'termSer_lbl'))
          privacy = getdata["data"][TERMS_CONDITIONS].toString();
        else if (widget.title == getTranslated(context,'aboutus_lbl'))
          privacy = getdata["data"][ABOUT_US].toString();
        else if (widget.title == getTranslated(context,'contactus_lbl'))
          privacy = getdata["data"][CONTACT_US].toString();
      }
      setState(() {
        _isLoading = false;
      });
    } else {
      setSnackbar(getTranslated(context,'internetmsg'));
    }
  }

//set snackbar msg
  setSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
      content: new Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.fontColor),
      ),
      backgroundColor: Theme.of(context).colorScheme.white,
      elevation: 1.0,
    ));
  }
}
