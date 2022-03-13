import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:news/ChooseCategory.dart';
import 'package:news/PrivacyPolicy.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';
import 'Helper/Constant.dart';
import 'Helper/Session.dart';
import 'Helper/String.dart';
import 'package:news/Helper/Color.dart';

import 'Helper/Theme.dart';
import 'Login.dart';
import 'main.dart';

class Settings extends StatefulWidget {
  final Function update;

  const Settings({this.update});

  @override
  SettingsState createState() => SettingsState();
}

class SettingsState extends State<Settings> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  String profile, name;
  File image;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  FacebookLogin facebookSignIn = new FacebookLogin();
  final InAppReview _inAppReview = InAppReview.instance;
  bool _isLoading = false;
  bool _isNetworkAvail = true;
  TextEditingController nameC;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  int selectedIndex;
  String theme;
  int selectLan;
  List<String> languageList = [eng_lbl, span_lbl, hin_lbl, turk_lbl];
  List<String> themeList=[
    system_lbl,light_lbl,dark_lbl
  ];
  List<String> langCode = ["en", "es", "hi", "tr", "pt"];
  ThemeNotifier themeNotifier;

  @override
  void initState() {
    getUserDetails();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getSavedTheme();
    });
    nameC = new TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    nameC?.dispose();
    super.dispose();
  }

  _getSavedTheme() async {
    theme = await getPrefrence(APP_THEME);
    if(theme==SYSTEM)
      {
        selectedIndex=0;
      }
    else if(theme==LIGHT)
      {
        selectedIndex=1;
      }
    else
      {
        selectedIndex=2;
      }
    setState(() {});
  }

  _updateState(int position) {
    setState(() {
      selectedIndex = position;
    });
    onThemeChanged(position);
  }



  void onThemeChanged(int value) async {
    if (value == 0) {
      themeNotifier.setThemeMode(ThemeMode.system);
      var brightness = SchedulerBinding.instance.window.platformBrightness;
      setState(() {
        isDark = brightness == Brightness.dark;
      });
      setPrefrence(APP_THEME, SYSTEM);
    } else if (value == 1) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
      themeNotifier.setThemeMode(ThemeMode.light);
      setState(() {
        isDark = false;
      });
      setPrefrence(APP_THEME, LIGHT);
    } else if (value == 2) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
      themeNotifier.setThemeMode(ThemeMode.dark);
      setState(() {
        isDark = true;
      });
      setPrefrence(APP_THEME, DARK);
    }
    theme = await getPrefrence(APP_THEME);
  }

  //get prefrences of user
  getUserDetails() async {
    CUR_USERID = await getPrefrence(ID);
    CUR_USERNAME = await getPrefrence(NAME);
    CUR_USEREMAIL = await getPrefrence(EMAIL);
    profile = await getPrefrence(PROFILE);
    if (await getPrefrence(LANGUAGE_CODE) == null) {
      selectLan = 0;
    } else {
      selectLan = langCode.indexOf(await getPrefrence(LANGUAGE_CODE));
    }
    nameC.text = CUR_USERNAME;
    setState(() {});
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

  //set header data shown
  getHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Stack(children: [
          profile != null && profile != ""
              ? Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(width: 4.0, color: colors.backColor)),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(100.0),
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(profile),
                        radius: 32,
                      )))
              : Container(
                  height: 80,
                  width: 80,
                  child: Icon(
                    Icons.account_circle,
                    color: Theme.of(context).colorScheme.fontColor,
                    size: 80,
                  ),
                ),
          CUR_USERID != null && CUR_USERID != ""
              ? Positioned(
                  bottom: 1,
                  right: 5,
                  child: Container(
                    height: 25,
                    width: 25,
                    child: InkWell(
                      child: Icon(
                        Icons.edit,
                        color: colors.backColor,
                        size: 15,
                      ),
                      onTap: () {
                        setState(() {
                          _showPicker();
                        });
                      },
                    ),
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.white,
                        borderRadius: BorderRadius.all(
                          Radius.circular(20),
                        ),
                        border: Border.all(
                            color: Theme.of(context).colorScheme.white)),
                  ))
              : Container(),
        ]),
        Expanded(
            child: Padding(
                padding: EdgeInsetsDirectional.only(start: 10.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                        padding: EdgeInsetsDirectional.only(top: 5.0),
                        child: Text(
                          getTranslated(context, 'welcome_lbl'),
                          style: Theme.of(context).textTheme.headline5,
                        )),
                    CUR_USERNAME == "" || CUR_USERNAME == null
                        ? Padding(
                            padding: EdgeInsetsDirectional.only(top: 5.0),
                            child: Row(
                              //mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(getTranslated(context, 'notLogin_lbl'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle2
                                        .copyWith(
                                            fontSize: 15,
                                            fontWeight: FontWeight.normal,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .fontColor
                                                .withOpacity(0.7))),
                                Expanded(
                                    child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Login(),
                                        ));
                                  },
                                  child: Text(
                                      "\t" +
                                          getTranslated(
                                              context, 'loginnow_lbl'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle2
                                          .copyWith(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .fontColor)),
                                ))
                              ],
                            ))
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                CUR_USERNAME,
                                style: Theme.of(context)
                                    .textTheme
                                    .headline6
                                    .copyWith(
                                        color: colors.primary.withOpacity(0.9),
                                        fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    size: 19.0,
                                  ),
                                  onPressed: () {
                                    nameEditTxt();
                                  })
                            ],
                          ),
                  ],
                )))
      ],
    );
  }

  //set name edit text
  nameEditTxt() {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            contentPadding: const EdgeInsets.all(0),
            elevation: 2.0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(5.0))),
            content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                      padding: EdgeInsets.fromLTRB(20.0, 20.0, 0, 2.0),
                      child: Text(
                        getTranslated(context, 'name_change_lbl'),
                        style: Theme.of(this.context)
                            .textTheme
                            .subtitle1
                            .copyWith(
                                color: Theme.of(context).colorScheme.fontColor),
                      )),
                  Divider(color: colors.lightBlack),
                  Form(
                      key: _formkey,
                      child: Padding(
                          padding: EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                          child: TextFormField(
                            keyboardType: TextInputType.text,
                            style: Theme.of(this.context)
                                .textTheme
                                .subtitle1
                                .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .fontColor2,
                                    fontWeight: FontWeight.normal),
                            validator: (val) => nameValidation(val, context),
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            controller: nameC,
                            onChanged: (v) => setState(() {
                              name = v;
                            }),
                          )))
                ]),
            actions: <Widget>[
              new TextButton(
                  child: Text(getTranslated(context, 'cancel_btn'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.fontColor2,
                        fontSize: 15,
                      )),
                  onPressed: () {
                    setState(() {
                      Navigator.pop(context);
                    });
                  }),
              new TextButton(
                  child: Text(getTranslated(context, 'save_btn'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.fontColor,
                        fontSize: 15,
                      )),
                  onPressed: () {
                    final form = _formkey.currentState;
                    if (form.validate()) {
                      form.save();
                      setState(() {
                        name = nameC.text;
                        Navigator.pop(context);
                      });
                      _setUpdateProfile();
                    }
                  })
            ],
          );
        });
  }

  //google sign out function
  void signOutGoogle() async {
    await googleSignIn.signOut();

    print("User Signed Out");
  }

  //set logout dialogue
  logOutDailog() async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setStater) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0))),
              content: Text(
                getTranslated(context, 'LOGOUTTXT'),
                style: Theme.of(this.context)
                    .textTheme
                    .subtitle1
                    .copyWith(color: Theme.of(context).colorScheme.fontColor),
              ),
              actions: <Widget>[
                new TextButton(
                    child: Text(
                      getTranslated(context, 'NO'),
                      style: Theme.of(this.context)
                          .textTheme
                          .subtitle2
                          .copyWith(
                              color: Theme.of(context).colorScheme.fontColor,
                              fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    }),
                new TextButton(
                    child: Text(
                      getTranslated(context, 'YES'),
                      style: Theme.of(this.context)
                          .textTheme
                          .subtitle2
                          .copyWith(
                              color: Theme.of(context).colorScheme.fontColor,
                              fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      clearUserSession();
                      signOutGoogle();
                      await _auth.signOut();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => Login()),
                      );
                    })
              ],
            );
          });
        });
  }

  //set divider between drawer
  _getDivider() {
    return Divider(
      height: 1,
      color: Colors.red,
    );
  }

  //set drawer list
  _getDrawer() {
    return ListView(
      padding: EdgeInsetsDirectional.only(top: 30.0),
      shrinkWrap: true,
      physics: BouncingScrollPhysics(),
      children: <Widget>[
        _getDrawerItem(
            0,
            getTranslated(context, 'change_theme'),
            getTranslated(context, 'darkmode_sub'),
            "assets/images/mode_icon.png",
            null),
        _getDivider(),
        _getDrawerItem(
            1,
            getTranslated(context, 'change_lan_lbl'),
            getTranslated(context, 'choose_ur_lan'),
            "assets/images/Language_icon.png",
            null),
        _getDivider(),
        _getDrawerItem(
            2,
            getTranslated(context, 'termSer_lbl'),
            getTranslated(context, 'termSer_sub'),
            "assets/images/aboutus_icon.png",
            null),
        _getDivider(),
        _getDrawerItem(
            3,
            getTranslated(context, 'contactus_lbl'),
            getTranslated(context, 'contactus_sub'),
            "assets/images/contactus_icon.png",
            null),
        _getDivider(),
        _getDrawerItem(
            4,
            getTranslated(context, 'aboutus_lbl'),
            getTranslated(context, 'aboutus_sub'),
            "assets/images/terms_icon.png",
            null),
        _getDivider(),
        _getDrawerItem(
            5,
            getTranslated(context, 'pri_policy'),
            getTranslated(context, 'privacypolicy_sub'),
            "assets/images/privacy_icon.png",
            null),
        _getDivider(),
        _getDrawerItem(
            6,
            getTranslated(context, 'rateus_lbl'),
            getTranslated(context, 'rateus_sub'),
            "assets/images/rate_icon.png",
            null),
        _getDivider(),
        CUR_USERID != "" && CUR_USERID != null
            ? _getDrawerItem(
                7,
                getTranslated(context, 'manage_prefrences'),
                getTranslated(context, 'manage_sub_prefrences'),
                "",
                Icons.category_outlined)
            : Container(),
        CUR_USERID != "" && CUR_USERID != null ? _getDivider() : Container(),
        _getDrawerItem(
            8, getTranslated(context, 'share_lbl'), "", "", Icons.share_sharp),
        CUR_USERID != "" && CUR_USERID != null ? _getDivider() : Container(),
        CUR_USERID != "" && CUR_USERID != null
            ? _getDrawerItem(
                9, getTranslated(context, 'logout'), "", "", Icons.logout)
            : Container(),
      ],
    );
  }

  //set drawer item list press
  _getDrawerItem(
      int index, String title, String subTitle, String img, IconData icn) {
    themeNotifier = Provider.of<ThemeNotifier>(context);
    var brightness = SchedulerBinding.instance.window.platformBrightness;
    return ListTile(
      dense: true,
      leading: index == 7 || index == 8 || index == 9
          ? Icon(
              icn,
              color: Theme.of(context).colorScheme.fontColor,
            )
          : Image.asset(
              img,
              color: Theme.of(context).colorScheme.fontColor,
            ),
      title: Text(title,
          style: Theme.of(context).textTheme.subtitle1.copyWith(
                color: Theme.of(context).colorScheme.fontColor,
              )),
      subtitle: Text(subTitle,
          style: Theme.of(context).textTheme.caption.copyWith(
              color: Theme.of(context).colorScheme.fontColor.withOpacity(0.6),
              fontWeight: FontWeight.normal)),
      onTap: () async {
        if (title == getTranslated(context, 'change_theme')) {
         themeDialog();
        } else if (title == getTranslated(context, 'contactus_lbl')) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => PrivacyPolicy(
                        title: getTranslated(context, 'contactus_lbl'),
                        from: getTranslated(context, 'home_lbl'),
                      )));
        } else if (title == getTranslated(context, 'aboutus_lbl')) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => PrivacyPolicy(
                        title: getTranslated(context, 'aboutus_lbl'),
                        from: getTranslated(context, 'home_lbl'),
                      )));
        } else if (title == getTranslated(context, 'termSer_lbl')) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => PrivacyPolicy(
                        title: getTranslated(context, 'termSer_lbl'),
                        from: getTranslated(context, 'home_lbl'),
                      )));
        } else if (title == getTranslated(context, 'pri_policy')) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => PrivacyPolicy(
                        title: getTranslated(context, 'pri_policy'),
                        from: getTranslated(context, 'home_lbl'),
                      )));
        } else if (title == getTranslated(context, 'rateus_lbl')) {
          _openStoreListing();
        } else if (title == getTranslated(context, 'manage_prefrences')) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => ChooseCategory(
                        title: getTranslated(context, 'manage_prefrences'),
                        from: getTranslated(context, 'home_lbl'),
                      )));
        } else if (title == getTranslated(context, 'share_lbl')) {
          var str =
              "$appName\n\n$APPFIND$androidLink$packageName\n\n $IOSLBL\n$iosLink\t$iosPackage";
          Share.share(str);
        } else if (title == getTranslated(context, 'change_lan_lbl')) {
          languageDialog();
        } else if (title == getTranslated(context, 'logout')) {
          logOutDailog();
        }
      },
    );
  }

  themeDialog() async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setStater) {
                return AlertDialog(
                  contentPadding: const EdgeInsets.all(0.0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0))),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                          padding: EdgeInsets.fromLTRB(20.0, 20.0, 0, 2.0),
                          child: Text(
                            getTranslated(context, 'choose_theme_lbl'),
                            style: Theme.of(this.context)
                                .textTheme
                                .subtitle1
                                .copyWith(
                                color:
                                Theme.of(context).colorScheme.fontColor2),
                          )),
                      Divider(color: colors.lightBlack),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: getThemeList()),
                        ),
                      ),
                    ],
                  ),
                );
              });
        });
  }

  //rate app function
  Future<void> _openStoreListing() => _inAppReview.openStoreListing(
        appStoreId: appStoreId,
        microsoftStoreId: 'microsoftStoreId',
      );

  languageDialog() async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setStater) {
            return AlertDialog(
              contentPadding: const EdgeInsets.all(0.0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5.0))),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                      padding: EdgeInsets.fromLTRB(20.0, 20.0, 0, 2.0),
                      child: Text(
                        getTranslated(context, 'choose_lan_lbl'),
                        style: Theme.of(this.context)
                            .textTheme
                            .subtitle1
                            .copyWith(
                                color:
                                    Theme.of(context).colorScheme.fontColor2),
                      )),
                  Divider(color: colors.lightBlack),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: getLngList()),
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                new TextButton(
                    child: Text(
                      getTranslated(context, 'save_btn'),
                      style: Theme.of(this.context)
                          .textTheme
                          .subtitle2
                          .copyWith(
                              color: Theme.of(context).colorScheme.fontColor2,
                              fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    })
              ],
            );
          });
        });
  }

  void _changeLan(String language) async {
    Locale _locale = await setLocale(language);

    MyApp.setLocale(context, _locale);
  }

  List<Widget> getLngList() {
    return languageList
        .asMap()
        .map(
          (index, element) => MapEntry(
              index,
              InkWell(
                onTap: () {
                  setState(() {
                    selectLan = index;
                    _changeLan(langCode[index]);
                  });
                },
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 5),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 25.0,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selectLan == index
                                    ? colors.primary
                                    : colors.tempWhite,
                                border: Border.all(color: colors.primary)),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: selectLan == index
                                  ? Icon(
                                      Icons.check,
                                      size: 17.0,
                                      color: colors.tempWhite,
                                    )
                                  : Icon(
                                      Icons.check_box_outline_blank,
                                      size: 15.0,
                                      color: colors.tempWhite,
                                    ),
                            ),
                          ),
                          Padding(
                              padding: EdgeInsets.only(
                                left: 15.0,
                              ),
                              child: Text(
                                languageList[index],
                                style: Theme.of(this.context)
                                    .textTheme
                                    .subtitle1
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor2),
                              ))
                        ],
                      ),
                      Divider(
                        color: colors.lightBlack,
                      ),
                    ],
                  ),
                ),
              )),
        )
        .values
        .toList();
  }

  List<Widget> getThemeList() {
    return themeList
        .asMap()
        .map(
          (index, element) => MapEntry(
          index,
          InkWell(
            onTap: () {
              setState(() {
                selectedIndex = index;
                _updateState(selectedIndex);
              });
            },
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 5),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        height: 25.0,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selectedIndex == index
                                ? colors.primary
                                : colors.tempWhite,
                            border: Border.all(color: colors.primary)),
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: selectedIndex == index
                              ? Icon(
                            Icons.check,
                            size: 17.0,
                            color: colors.tempWhite,
                          )
                              : Icon(
                            Icons.check_box_outline_blank,
                            size: 15.0,
                            color: colors.tempWhite,
                          ),
                        ),
                      ),
                      Padding(
                          padding: EdgeInsets.only(
                            left: 15.0,
                          ),
                          child: Text(
                            themeList[index],
                            style: Theme.of(this.context)
                                .textTheme
                                .subtitle1
                                .copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .fontColor2),
                          ))
                    ],
                  ),
                  Divider(
                    color: colors.header,
                  ),
                ],
              ),
            ),
          )),
    )
        .values
        .toList();
  }

  //user profile upload function
  void _showPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)), //this end here
            child: Container(
                height: 130,
                width: 80,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                      start: 50.0, end: 50.0, top: 10.0, bottom: 10.0),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton.icon(
                            icon: Icon(
                              Icons.photo_library,
                              color: Theme.of(context).colorScheme.fontColor2,
                            ),
                            label: Text(
                              getTranslated(context, 'photo_lib_lbl'),
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.fontColor2,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              _getFromGallery();
                              Navigator.of(context).pop();
                            }),
                        TextButton.icon(
                          icon: Icon(
                            Icons.photo_camera,
                            color: Theme.of(context).colorScheme.fontColor2,
                          ),
                          label: Text(
                            getTranslated(context, 'camera_lbl'),
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.fontColor2,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            _getFromCamera();
                            Navigator.of(context).pop();
                          },
                        )
                      ]),
                )));
      },
    );
  }

  //set image camera
  _getFromCamera() async {
    PickedFile pickedFile = await ImagePicker().getImage(
      source: ImageSource.camera,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    if (pickedFile != null) {
      setState(() {
        image = File(pickedFile.path);
      });

      setProfilePic(image);
    }
  }

// set image gallery
  _getFromGallery() async {
    PickedFile pickedFile = await ImagePicker().getImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    if (pickedFile != null) {
      setState(() {
        image = File(pickedFile.path);
      });
      setProfilePic(image);
    }
  }

//set profile using api
  Future<void> setProfilePic(File _image) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      setState(() {
        _isLoading = true;
      });
      try {
        var request = http.MultipartRequest('POST', Uri.parse(setProfileApi));
        request.headers.addAll(headers);
        request.fields[USER_ID] = CUR_USERID;
        request.fields[ACCESS_KEY] = access_key;
        var pic = await http.MultipartFile.fromPath(IMAGE, _image.path);
        request.files.add(pic);

        var response = await request.send();
        var responseData = await response.stream.toBytes();
        var responseString = String.fromCharCodes(responseData);
        if (response.statusCode == 200) {
          var getdata = json.decode(responseString);

          String error = getdata["error"];
          String msg = getdata['message'];
          profile = getdata['file_path'];
          if (error == "false") {
            setSnackbar(getTranslated(context, 'profile_success'));
            setState(() {
              setPrefrence(PROFILE, profile);
            });
            String img1 = await getPrefrence(PROFILE);
          } else {
            setSnackbar(msg);
          }
          setState(() {
            _isLoading = false;
          });
        } else {
          return null;
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg'));
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isNetworkAvail = false;
      });
    }
  }

  //set user update their name using api
  _setUpdateProfile() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      setState(() {
        _isLoading = true;
      });
      var param = {
        ACCESS_KEY: access_key,
        USER_ID: CUR_USERID,
        NAME: name,
      };

      http.Response response = await http
          .post(Uri.parse(setUpdateProfileApi), body: param, headers: headers)
          .timeout(Duration(seconds: timeOut));

      var getdata = json.decode(response.body);

      String error = getdata["error"];

      if (error == "false") {
        setSnackbar(getTranslated(context, 'name_update_msg'));

        setState(() {
          _isLoading = false;
          CUR_USERNAME = name;
          setPrefrence(NAME, name);
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setSnackbar(getTranslated(context, 'internetmsg'));
    }
  }

  //show header and drawer data shown
  _showContent() {
    return SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsetsDirectional.only(
            start: 20.0, end: 20.0, top: 30.0, bottom: 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            getHeader(),
            _getDrawer()
            //signOutBtn(),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        body: Stack(
          children: <Widget>[
            _showContent(),
            showCircularProgress(_isLoading, colors.primary)
          ],
        ));
  }
}
