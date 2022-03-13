import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:admob_flutter/admob_flutter.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_admob/flutter_native_admob.dart';
import 'package:flutter_native_admob/native_admob_controller.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart' as intl;
import 'package:news/Favourite.dart';
import 'package:news/Helper/Color.dart';
import 'package:news/Helper/Constant.dart';
import 'package:news/Helper/CustomBoxShadow.dart';
import 'package:news/Helper/String.dart';
import 'package:news/Model/Category.dart';
import 'package:news/NewsDetails.dart';
import 'package:news/NotificationList.dart';
import 'package:news/main.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sqflite/sqflite.dart';
import 'Helper/AdHelper.dart';
import 'Helper/CircularBorder.dart';
import 'Helper/CustomText.dart';
import 'Helper/Data_Helper.dart';
import 'Helper/PushNotificationService.dart';
import 'Helper/Session.dart';
import 'Live.dart';
import 'Login.dart';
import 'Model/News.dart';
import 'Settings.dart';
import 'package:path/path.dart' as path;
import 'package:html/parser.dart' show parse;

class Home extends StatefulWidget {
  @override
  HomeState createState() => HomeState();
}

int _selectedIndex = 0;
bool _isNetworkAvail = true;
GlobalKey bottomNavigationKey = GlobalKey();

class HomeState extends State<Home> {
  List<Widget> fragments;
  String id, name, mobile, email, status, profile, type;
  DateTime currentBackPressTime;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  final GoogleSignIn googleSignIn = GoogleSignIn();
  FacebookLogin facebookSignIn = new FacebookLogin();
  File image;
  TextEditingController nameC;
  bool _folded = true;
  final TextEditingController _controller = TextEditingController();
  List<News> searchList = [];
  List<News> newsList = [];
  HomePage home;
  bool isInSearchMode = false;
  var db = new DatabaseHelper();
  var liveNews;

  //this function is used for when bottom navigator index and fragment widget chnaged.
  _onItemTapped(index) async {
    profile = await getPrefrence(PROFILE);
    getNews();
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Future<void> initState() {
    super.initState();
    getUserDetails();
    initDynamicLinks();
    getNews();
    // getLiveNews();
    fragments = [
      HomePage(updateHome, newsList),
      Favourite(
        updateHome(),
      ),
      NotificationList(),
      Settings(
        update: updateHome(),
      )
    ];
    firNotificationInitialize();
  }

  updateHome() {
    setState(() {});
  }

  updateParent() {

  }

  //to get the prefrences to save
  getUserDetails() async {
    CUR_USERID = await getPrefrence(ID);
    CUR_USERNAME = await getPrefrence(NAME);
    CUR_USEREMAIL = await getPrefrence(EMAIL);
    CATID = await getPrefrence(cur_catId);
    if (CATID == null) {
      CATID = "";
    }
    id = await getPrefrence(ID);
    mobile = await getPrefrence(MOBILE);
    name = await getPrefrence(NAME);
    email = await getPrefrence(EMAIL);
    profile = await getPrefrence(PROFILE);
    status = await getPrefrence(STATUS);
    type = await getPrefrence(TYPE);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: onWillPop,
        child: Scaffold(
            extendBody: true,
            resizeToAvoidBottomInset: false,
            key: scaffoldKey,
            body: Stack(fit: StackFit.passthrough, children: [
              fragments[_selectedIndex],
              !_folded ? searchBarView() : Container()
            ]),
            appBar: getAppBar(),
            bottomNavigationBar: getBottomBar()));
  }

  void firNotificationInitialize() {
    //for firebase push notification
    FlutterLocalNotificationsPlugin();
// initialise the plugin. ic_launcher needs to be a added as a drawable resource to the Android head project
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
            onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    final MacOSInitializationSettings initializationSettingsMacOS =
        MacOSInitializationSettings();
    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
            macOS: initializationSettingsMacOS);

    PushNotificationService.flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onSelectNotification: onSelectNotification);
  }

  Future onDidReceiveLocalNotification(
      int id, String title, String body, String payload) {
    return showDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(body),
        actions: <Widget>[
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('Ok'),
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyApp(),
                ),
              );
            },
          )
        ],
      ),
    );
  }

  Future onSelectNotification(String payload) {
    if (payload != null && payload.isNotEmpty) {
      debugPrint('notification payload: $payload');
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MyApp()),
    );
  }

  //when dynamic link share that's open in app used this function
  void initDynamicLinks() async {
    FirebaseDynamicLinks.instance.onLink(
        onSuccess: (PendingDynamicLinkData dynamicLink) async {
      final Uri deepLink = dynamicLink?.link;

      if (deepLink != null) {
        if (deepLink.queryParameters.length > 0) {
          String id = deepLink.queryParameters['id'];
          int index = int.parse(deepLink.queryParameters['index']);
          getNewsById(id, index);
        }
      }
    }, onError: (OnLinkErrorException e) async {
      print(e.message);
    });
  }

  //when open dynamic link news index and id can used for fetch specific news
  Future<void> getNewsById(String id, int index) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      var param = {
        NEWS_ID: id,
        ACCESS_KEY: access_key,
      };
      http.Response response = await http
          .post(Uri.parse(getNewsByIdApi), body: param, headers: headers)
          .timeout(Duration(seconds: timeOut));
      var getdata = json.decode(response.body);

      String error = getdata["error"];

      if (error == "false") {
        var data = getdata["data"];
        List<News> news = [];
        news = (data as List).map((data) => new News.fromJson(data)).toList();
        Navigator.of(context).push(MaterialPageRoute(
            builder: (BuildContext context) => NewsDetails(
                  model: news[0],
                  index: int.parse(id),
                  updateParent: updateParent(),
                  id: news[0].id,
                  isFav: false,
                )));
      }
    } else {
      setSnackbar(getTranslated(context, 'internetmsg'));
    }
  }

  //searchbar shown
  searchBarView() {
    return searchList.length != 0
        ? Padding(
            padding: EdgeInsetsDirectional.only(
                start: 11.0, end: 11.0, top: 10.0, bottom: 5.0),
            child: Card(
                elevation: 2.0,
                shadowColor:
                    Theme.of(context).colorScheme.fontColor.withOpacity(0.8),
                color: Theme.of(context).colorScheme.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                    padding: EdgeInsets.all(10.0),
                    child: ListView.builder(
                        shrinkWrap: true,
                        physics: BouncingScrollPhysics(),
                        itemCount: searchList.length,
                        itemBuilder: (context, index) {
                          return InkWell(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(children: [
                                  Expanded(
                                      flex: 1,
                                      child: Icon(Icons.search_rounded)),
                                  Expanded(
                                      flex: 10,
                                      child: Padding(
                                          padding: EdgeInsetsDirectional.only(
                                              start: 15.0, end: 15.0),
                                          child: Text(searchList[index].title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .subtitle1
                                                  .copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .fontColor)))),
                                  Expanded(
                                      flex: 1,
                                      child: Image.asset(
                                          "assets/images/search bar arrow.png"))
                                ]),
                                Divider(
                                  color:
                                      Theme.of(context).colorScheme.fontColor,
                                ),
                              ],
                            ),
                            onTap: () async {
                              _controller.clear();
                              _folded = true;
                              News model = searchList[index];
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (BuildContext context) =>
                                      NewsDetails(
                                        model: model,
                                        index: index,
                                        updateParent: updateParent(),
                                        id: model.id,
                                        isFav: false,
                                      )));
                            },
                          );
                        }))))
        : Container();
  }


  /*

  //get live news video
  Future<void> getLiveNews() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      var parameter = {ACCESS_KEY: access_key};

      http.Response response = await http
          .post(Uri.parse(getLiveStreamingApi),
              body: parameter, headers: headers)
          .timeout(Duration(seconds: timeOut));
      var getdata = json.decode(response.body);
      String error = getdata["error"];

      if (error == "false") {
        liveNews = getdata["data"];
      } else {
        liveNews = "";
        setState(() {
          isLoadingmore = false;
        });
      }
    } else
      setSnackbar(getTranslated(context, 'internetmsg'));
  }


   */

  //appbar shown
  getAppBar() {
    deviceWidth = MediaQuery.of(context).size.width;
    deviceHeight = MediaQuery.of(context).size.height;
    String title = _selectedIndex == 1
        ? getTranslated(context, 'bookmark_lbl')
        : getTranslated(context, 'notification_lbl');
    return AppBar(
      elevation: 0.0,
      leadingWidth: 67.0,
      leading: _selectedIndex == 3
          ? Container()
          : _folded
              ?
      // InkWell(
      //             child: _isNetworkAvail
      //                 ? liveNews != ""
      //                     ?
                      Container()
                      /*
                  CircularBorder(
                              width: 2,
                              size: 45,
                              // color: colors.primary,
                              icon: Icon(Icons.menu, size: 30, color: Colors.green[900])
                              // Image.asset(
                              //   "assets/images/live_icon.png",
                              // ),
                            )
                  */
                      //     : Image.asset("")
                      // : Image.asset(""),
                  // onTap: () {
                    // _getDrawer();

                   /* if (_isNetworkAvail) {
                      if (liveNews != "" && liveNews != null) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Live(
                                liveNews: liveNews,
                              ),
                            ));
                      } else {
                        setSnackbar(getTranslated(context, 'no_live_avail'));
                      }
                    } else {
                      setSnackbar(getTranslated(context, 'internetmsg'));
                    }*/
                  // }
                  // )



              : Container(),
      centerTitle: true,
      title: _folded
          ? _selectedIndex == 0 || _selectedIndex == 3
              ? Image.asset(
                  "assets/images/redtitle_logo2.png",
                  // color: colors.lightBlack,
                )
              : Text(title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headline6.copyWith(
                      color: colors.primary, fontWeight: FontWeight.bold))
          : Container(),
      shadowColor: Theme.of(context).colorScheme.fontColor.withOpacity(0.8),
      backgroundColor: Theme.of(context).colorScheme.white,
      actions: <Widget>[
        Padding(
            padding: EdgeInsetsDirectional.only(
                top: 8.0, bottom: 13.0, start: 15.0, end: 15.0),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 400),
              width: _folded ? 37 : deviceWidth - 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: _folded
                    ? BorderRadius.circular(30)
                    : BorderRadius.circular(70),
                color: Theme.of(context).colorScheme.white,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .fontColor
                        .withOpacity(0.4),
                    offset: Offset(0.0, 2), //(x,y)
                    blurRadius: 4.0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsetsDirectional.only(start: 12),
                      child: !_folded
                          ? TextField(
                              controller: _controller,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyText2
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor
                                          .withOpacity(0.7)),
                              autofocus: true,
                              onChanged: (value) {
                                if (_controller.text.trim().isNotEmpty) {
                                  searchOperation(_controller.text);
                                } else {
                                  setState(() {
                                    searchList.clear();
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                contentPadding:
                                    EdgeInsets.fromLTRB(0, 0.0, 0, 11.0),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color:
                                      Theme.of(context).colorScheme.fontColor,
                                  size: 20.0,
                                ),
                                hintText: getTranslated(context, 'search_lbl'),
                                hintStyle: Theme.of(context)
                                    .textTheme
                                    .bodyText2
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor
                                            .withOpacity(0.7)),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color:
                                          Theme.of(context).colorScheme.white),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color:
                                          Theme.of(context).colorScheme.white),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                  Container(
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(_folded ? 32 : 0),
                          topRight: Radius.circular(32),
                          bottomLeft: Radius.circular(_folded ? 32 : 0),
                          bottomRight: Radius.circular(32),
                        ),
                        child: Padding(
                            padding: EdgeInsetsDirectional.only(
                                start: 7.0, end: 7.0),
                            child: Icon(
                              _folded ? Icons.search_rounded : Icons.close,
                              color: Theme.of(context).colorScheme.fontColor,
                              size: _folded ? 23.0 : 20.0,
                            )),
                        onTap: () {
                          setState(() {
                            _controller.clear();
                            searchList.clear();
                            _folded = !_folded;
                          });
                        },
                      ),
                    ),
                  )
                ],
              ),
            )),
      ],
    );
  }




  //this function used for search news
  Future<void> searchOperation(String searchText) async {
    searchList.clear();
    for (int i = 0; i < newsList.length; i++) {
      News map = newsList[i];
      if (map.title.toLowerCase().contains(searchText) ||
          map.title.toUpperCase().contains(searchText)) {
        searchList.add(map);
      }
    }
    setState(() {});
  }

  //get search news list
  Future<void> getNews() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      var param = {
        ACCESS_KEY: access_key,
        USER_ID: CUR_USERID != null && CUR_USERID != "" ? CUR_USERID : "0",
      };
      http.Response response = await http
          .post(Uri.parse(getNewsApi), body: param, headers: headers)
          .timeout(Duration(seconds: timeOut));
      var getdata = json.decode(response.body);
      String error = getdata["error"];
      String newsData = response.body.toString();
      if (error == "false") {
        var data = getdata["data"];
        searchList.clear();
        newsList =
            (data as List).map((data) => new News.fromJson(data)).toList();
        List<String> imageList = [];
        for (int i = 0; i < newsList.length; i++) {
          var response = await http.get(Uri.parse(newsList[i].image));
          var filePathAndName;
          // documentDirectory is the unique device path to the area you'll be saving in
          var documentDirectory = await getApplicationDocumentsDirectory();
          var firstPath = documentDirectory.path + "/images";
          //You'll have to manually create subdirectories
          await Directory(firstPath).create(recursive: true);
          // Name the file, create the file, and save in byte form.
          filePathAndName = documentDirectory.path +
              '/images/${path.basename(newsList[i].image)}';
          if (await File(filePathAndName).exists()) {
            print("File exists");
            imageList.add(filePathAndName.toString());
          } else {
            File file2 = new File(filePathAndName);
            file2.writeAsBytesSync(response.bodyBytes);
            imageList.add(filePathAndName.toString());
          }
        }
        db.insertNews(newsData.toString(), imageList.join(',').toString());
      }
    } else {
      newsList = await db.getNews();
    }
  }

  _getDrawer() {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(

            ),
          ),
        ]
      ),
    );
  }

  //show snackbar msg
  setSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
      content: new Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.fontColor2),
      ),
      backgroundColor: Theme.of(context).colorScheme.white,
      elevation: 1.0,
    ));
  }

  //when home page in back click press
  Future<bool> onWillPop() {
    DateTime now = DateTime.now();
    if (_selectedIndex != 0) {
      _selectedIndex = 0;
      final CurvedNavigationBarState navBarState =
          bottomNavigationKey.currentState;
      navBarState.setPage(0);

      return Future.value(false);
    } else if (currentBackPressTime == null ||
        now.difference(currentBackPressTime) > Duration(seconds: 2)) {
      currentBackPressTime = now;
      setSnackbar(getTranslated(context, 'EXIT_WR'));

      return Future.value(false);
    }
    return Future.value(true);
  }

  //show bottombar
  getBottomBar() {
    return CurvedNavigationBar(
        key: bottomNavigationKey,
        backgroundColor: Colors.transparent,
        color: Theme.of(context).colorScheme.white,
        buttonBackgroundColor: _selectedIndex == 3
            ? Theme.of(context).colorScheme.white
            : Colors.transparent,
        height: 60,
        index: _selectedIndex,
        items: <Widget>[
          _selectedIndex == 0
              ? Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.white,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .fontColor
                            .withOpacity(0.4),
                        offset: Offset(0.0, 2), //(x,y)
                        blurRadius: 6.0,
                      ),
                    ],
                  ),
                  height: 55.0,
                  alignment: Alignment.center,
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.home,
                          color: colors.primary,
                          size: 20.0,
                        ),
                        Text(
                          getTranslated(context, 'home_lbl'),
                          style:
                              TextStyle(color: colors.primary, fontSize: 7.0),
                          textAlign: TextAlign.center,
                        ),
                      ]))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                      Padding(
                          padding: EdgeInsetsDirectional.only(top: 10.0),
                          child: Icon(
                            Icons.home,
                            color: Theme.of(context)
                                .colorScheme
                                .fontColor
                                .withOpacity(0.8),
                            size: 20.0,
                          )),
                      Text(
                        getTranslated(context, 'home_lbl'),
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .fontColor
                                .withOpacity(0.8),
                            fontSize: 11.0),
                        textAlign: TextAlign.center,
                      ),
                    ]),
          _selectedIndex == 1
              ? Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.white,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .fontColor
                            .withOpacity(0.4),
                        offset: Offset(0.0, 2), //(x,y)
                        blurRadius: 6.0,
                      ),
                    ],
                  ),
                  height: 55.0,
                  alignment: Alignment.center,
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bookmark_border_rounded,
                          color: colors.primary,
                          size: 20.0,
                        ),
                        Text(
                          getTranslated(context, 'bookmark_lbl'),
                          style:
                              TextStyle(color: colors.primary, fontSize: 7.0),
                          textAlign: TextAlign.center,
                        ),
                      ]))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                      Padding(
                          padding: EdgeInsetsDirectional.only(top: 10.0),
                          child: Icon(
                            Icons.bookmark_border_rounded,
                            color: Theme.of(context)
                                .colorScheme
                                .fontColor
                                .withOpacity(0.8),
                            size: 20.0,
                          )),
                      Text(
                        getTranslated(context, 'bookmark_lbl'),
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .fontColor
                                .withOpacity(0.8),
                            fontSize: 11.0),
                        textAlign: TextAlign.center,
                      ),
                    ]),
          _selectedIndex == 2
              ? Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.white,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .fontColor
                            .withOpacity(0.4),
                        offset: Offset(0.0, 2), //(x,y)
                        blurRadius: 6.0,
                      ),
                    ],
                  ),
                  height: 55.0,
                  alignment: Alignment.center,
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          color: colors.primary,
                          size: 20.0,
                        ),
                        Text(
                          getTranslated(context, 'notification_lbl'),
                          style:
                              TextStyle(color: colors.primary, fontSize: 7.0),
                          textAlign: TextAlign.center,
                        ),
                      ]))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                      Padding(
                          padding: EdgeInsetsDirectional.only(top: 10.0),
                          child: Icon(
                            Icons.notifications_outlined,
                            color: Theme.of(context)
                                .colorScheme
                                .fontColor
                                .withOpacity(0.8),
                            size: 20.0,
                          )),
                      Text(
                        getTranslated(context, 'notification_lbl'),
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .fontColor
                                .withOpacity(0.8),
                            fontSize: 11.0),
                        textAlign: TextAlign.center,
                      ),
                    ]),
          _selectedIndex == 3
              ? Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      CustomBoxShadow(
                        color: Colors.transparent,
                        offset: Offset(0.0, 2), //(x,y)
                        blurRadius: 6.0,
                        blurStyle: BlurStyle.outer,
                      )
                    ],
                  ),
                  height: 55.0,
                  alignment: Alignment.center,
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.settings,
                          color: colors.primary,
                          size: 20.0,
                        ),
                        CustomText()
                      ]))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                      Padding(
                          padding: EdgeInsetsDirectional.only(top: 10.0),
                          child: Icon(
                            Icons.settings_applications,
                            color: Theme.of(context)
                                .colorScheme
                                .fontColor
                                .withOpacity(0.8),
                            size: 20.0,
                          )),
                      Text(
                        getTranslated(context, 'setting_lbl'),
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .fontColor
                                .withOpacity(0.8),
                            fontSize: 11.0),
                        textAlign: TextAlign.center,
                      ),
                    ]),
        ],
        onTap: (int index) {
          setState(() {
            _folded = true;
          });
          _onItemTapped(index);
        });
  }
}

class HomePage extends StatefulWidget {
  Function updateHome;
  List<News> newsList = [];

  HomePage(this.updateHome, this.newsList);

  @override
  HomePageState createState() => HomePageState();
}

List<Category> catList = [];

class HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey1 = GlobalKey<ScaffoldState>();
  bool _isNetworkAvail = true;
  List<Category> tempCatList = [];
  ScrollController controller = new ScrollController();
  String id, name, mobile, email, status, profile, type;
  TabController _tc;
  List<Map<String, dynamic>> _tabs1 = [];
  int total = 0;
  int offset = 0;
  bool isLoadingmore = true;
  var db = new DatabaseHelper();
  var isDarkTheme;

  @override
  void initState() {
    super.initState();

    catList.length != 0 ? this._addInitailTab() : null;
    getUserDetails().whenComplete(() {
      callApi();
    });
    controller.addListener(_scrollListener);
  }

  Future<void> callApi() {
    if (catList.length != 0) {
      CATID != ""
          ? catList[0].categoryName = "For You"
          : catList[0].categoryName = "Latest News";
    }
    _tabs1.clear();
    _addInitailTab();

    getSetting().whenComplete(() {
      getCat();
    });
  }

  updateHomePage() {
    setState(() {});
  }

  //get prefrences that set before
  Future<void> getUserDetails() async {
    CUR_USERID = await getPrefrence(ID);
    CUR_USERNAME = await getPrefrence(NAME);
    CUR_USEREMAIL = await getPrefrence(EMAIL);
    CATID = await getPrefrence(cur_catId);
    if (CATID == null) {
      CATID = "";
    }
    id = await getPrefrence(ID);
    mobile = await getPrefrence(MOBILE);
    name = await getPrefrence(NAME);
    email = await getPrefrence(EMAIL);
    profile = await getPrefrence(PROFILE);
    status = await getPrefrence(STATUS);
    type = await getPrefrence(TYPE);

    setState(() {});
  }

  @override
  void dispose() {
    _tc.dispose();
    controller.removeListener(() {});
    super.dispose();
  }

  _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if (this.mounted) {
        setState(() {
          isLoadingmore = true;

          if (offset < total) getCat();
        });
      }
    }
  }

  //add tab bar category title
  _addInitailTab() async {
    setState(() {
      for (int i = 0; i < catList.length; i++) {
        _tabs1.add({
          'text': catList[i].categoryName,
        });
      }

      _tc = TabController(
        vsync: this,
        length: _tabs1.length,
      );
    });
  }




  // tab bar view news list set
  List<Widget> _TabBarViewList() {
    List<Widget> _list = [];

    for (var i = 0; i < catList.length; i++) {
      Widget tabbarview = SubHomePage(
        curTabId: catList[i].id,
        catName: catList[i].categoryName,
        catIndex: i,
      );
      _list.add(tabbarview);
    }
    return _list;
  }




  //show snackbar msg
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

  //get settings api
  Future<void> getSetting() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      var param = {
        ACCESS_KEY: access_key,
      };
      http.Response response = await http
          .post(Uri.parse(getSettingApi), body: param, headers: headers)
          .timeout(Duration(seconds: timeOut));

      var getdata = json.decode(response.body);
      String error = getdata["error"];
      if (error == "false") {
        var data = getdata["data"];
        category_mode = data["category_mode"];
        comments_mode = data["comments_mode"];
        db.insertSettings(category_mode, comments_mode);
      }
    } else {
      await db.getSettings();
    }
  }

  //get all category using api
  Future<void> getCat() async {
    if (category_mode == "1") {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        var param = {
          ACCESS_KEY: access_key,
          LIMIT: perPage.toString(),
          OFFSET: offset.toString()
        };
        http.Response response = await http
            .post(Uri.parse(getCatApi), body: param, headers: headers)
            .timeout(Duration(seconds: timeOut));
        var getdata = json.decode(response.body);
        String catData = response.body.toString();
        String error = getdata["error"];

        if (error == "false") {
          total = int.parse(getdata["total"]);

          if ((offset) < total) {
            tempCatList.clear();
            catList.clear();
            var data = getdata["data"];
            tempCatList = (data as List)
                .map((data) => new Category.fromJson(data))
                .toList();
            catList.addAll(tempCatList);

            catList.insert(
                0,
                Category(
                    id: "${catList.length + 1}",
                    categoryName: CATID != "" ? "For You" : "Latest News"));

            offset = offset + perPage;
            db.insertCat(catData.toString());
            _tabs1.clear();
            this._addInitailTab();
          }
        } else {
          setState(() {
            isLoadingmore = false;
          });
        }
      } else {
        catList = await db.getCat();
        catList.insert(
            0,
            Category(
                id: "${catList.length + 1}",
                categoryName: CATID != "" ? "For You" : "Latest News"));
        _tabs1.clear();
        this._addInitailTab();

        setState(() {
          isLoadingmore = false;
        });
      }
    } else {
      setState(() {
        isLoadingmore = false;
      });
    }
  }

  //set category load shimmer
  Widget catShimmer() {
    isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    return Container(
        width: double.infinity,
        child: Shimmer.fromColors(
            baseColor:
                isDarkTheme ? Colors.grey.withOpacity(0.7) : Colors.grey[300],
            highlightColor:
                isDarkTheme ? Colors.grey.withOpacity(0.7) : Colors.grey[300],
            child: SingleChildScrollView(
                padding: EdgeInsetsDirectional.only(end: 15.0),
                child: Column(children: [
                  SingleChildScrollView(
                    padding: EdgeInsetsDirectional.only(start: 5.0, top: 15.0),
                    scrollDirection: Axis.horizontal,
                    child: Row(
                        children: [0, 1, 2, 3]
                            .map((_) => Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50.0),
                                      color: Colors.grey),
                                  margin: EdgeInsets.symmetric(horizontal: 10),
                                  width: 100.0,
                                  height: 25.0,
                                ))
                            .toList()),
                  ),
                  Padding(
                      padding:
                          EdgeInsetsDirectional.only(start: 15.0, top: 10.0),
                      child: Column(children: [
                        Container(
                          height: 10.0,
                          color: Colors.grey,
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.only(
                              top: 7.0, bottom: 20.0),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: BouncingScrollPhysics(),
                            itemBuilder: (_, __) => Padding(
                                padding: EdgeInsetsDirectional.only(top: 7.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15.0),
                                      color: Colors.grey),
                                  height: 180.0,
                                )),
                            itemCount: 5,
                          ),
                        )
                      ]))
                ]))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey1,
        appBar: catList.length != 0
            ? category_mode == "1"
                ? PreferredSize(
                    preferredSize: Size.fromHeight(61.0),
                    child: Padding(
                        padding: EdgeInsetsDirectional.only(
                            top: 10.0, start: 15.0, end: 15.0),
                        child: TabBar(
                          labelStyle: Theme.of(context).textTheme.subtitle2,
                          unselectedLabelColor:
                              Theme.of(context).colorScheme.fontColor,
                          isScrollable: true,
                          indicatorPadding:
                              EdgeInsetsDirectional.only(top: 7.0, bottom: 7.0),
                          indicator: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(50), // Creates border
                              color: colors.primary),
                          tabs: _tabs1
                              .map((tab) => Tab(
                                    text: tab['text'],
                                  ))
                              .toList(),
                          controller: _tc,
                        )))
                : PreferredSize(
                    preferredSize: Size.fromHeight(0.0),
                    child: Center(
                        child: Text(getTranslated(context, 'cat_no_avail'))))
            : PreferredSize(
                preferredSize: Size.fromHeight(0.0), child: Container()),
        body: catList.length != 0
            ? category_mode == "1"
                ? TabBarView(controller: _tc, children: _TabBarViewList())
                : Center(child: Text(getTranslated(context, 'cat_no_avail')))
            : catShimmer());
  }
}

class SubHomePage extends StatefulWidget {
  final Function updateHome;
  final String curTabId;
  final int index, catIndex;
  final String catName;

  const SubHomePage(
      {Key key,
      this.updateHome,
      this.curTabId,
      this.index,
      this.catName,
      this.catIndex})
      : super(key: key);

  @override
  SubHomePageState createState() => SubHomePageState();
}

bool _isLoading = true;
bool isLoadingmore = true;
int offset = 0;
int total = 0;

class SubHomePageState extends State<SubHomePage>
    with AutomaticKeepAliveClientMixin<SubHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey2 = GlobalKey<ScaffoldState>();
  bool _isNetworkAvail = true;

  ScrollController controller = new ScrollController();
  bool enabled = true;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  AdmobBannerSize bannerSize;
  List<News> tempList = [];
  List bookMarkValue = [];
  List<News> bookmarkList = [];
  List<News> newsList = [];
  final _nativeAdController = NativeAdmobController();
  var db = new DatabaseHelper();
  double progress = 0;
  String fileSave = "";
  String otherImageSave = "";
  var isDarkTheme;

  @override
  void initState() {
    _isLoading = true;
    getUserDetails().whenComplete(() {
      callApi();
    });

    super.initState();
  }

  callApi() {
    offset = 0;
    total = 0;
    _isLoading = true;
    getNewsByCat();
    getUserByCatNews();
    getNews();
    _getBookmark(1);
  }

  @override
  void dispose() {
    controller.removeListener(() {});
    super.dispose();
  }

  updateHomePage(bool like, int from, String id) {
    if (from == 1) {
      setState(() {
        bookmarkList.clear();
        bookMarkValue.clear();
        _getBookmark(2);
      });
    } else {
      if (like) {
        setState(() {
          for (int i = 0; i < newsList.length; i++) {
            if (newsList[i].id == id) {
              newsList[i].totalLikes =
                  (int.parse(newsList[i].totalLikes) + 1).toString();
              newsList[i].like = "1";
            }
          }
        });
      } else {
        setState(() {
          for (int i = 0; i < newsList.length; i++) {
            if (newsList[i].id == id) {
              newsList[i].totalLikes =
                  (int.parse(newsList[i].totalLikes) - 1).toString();
              newsList[i].like = "0";
            }
          }
        });
      }
    }
  }

  Future<void> getUserDetails() async {
    _isLoading = true;
    CUR_USERID = await getPrefrence(ID);
    CUR_USERNAME = await getPrefrence(NAME);
    CUR_USEREMAIL = await getPrefrence(EMAIL);
    CATID = await getPrefrence(cur_catId);
    if (CATID == null) {
      CATID = "";
    }
    setState(() {});
  }

//show snackbar msg
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


  //get user selected category newslist
  Future<void> getUserByCatNews() async {
    if (widget.catIndex == 0 && CATID != "") {
      setState(() {
        _isLoading = true;
      });
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        var param = {
          ACCESS_KEY: access_key,
          CATEGORY_ID: CATID,
          USER_ID: CUR_USERID,
          LIMIT: perPage.toString(),
          OFFSET: offset.toString(),
        };
        http.Response response = await http
            .post(Uri.parse(getNewsByUserCatApi), body: param, headers: headers)
            .timeout(Duration(seconds: timeOut));
        var getdata = json.decode(response.body);
        String newsData = response.body.toString();
        String error = getdata["error"];

        if (error == "false") {
          total = int.parse(getdata["total"]);
          if ((offset) < total) {
            tempList.clear();
            newsList.clear();
            var data = getdata["data"];
            tempList =
                (data as List).map((data) => new News.fromJson(data)).toList();

            newsList.addAll(tempList);

            offset = offset + perPage;
            if (mounted)
              setState(() {
                _isLoading = false;
              });

            List<String> imageList = [];
            List<String> otherImageList = [];
            String id = "";
            for (int i = 0; i < newsList.length; i++) {
              var response = await http.get(Uri.parse(newsList[i].image));
              var filePathAndName;
              // documentDirectory is the unique device path to the area you'll be saving in
              var documentDirectory = await getApplicationDocumentsDirectory();
              var firstPath = documentDirectory.path + "/images";
              //You'll have to manually create subdirectories
              await Directory(firstPath).create(recursive: true);
              // Name the file, create the file, and save in byte form.
              filePathAndName = documentDirectory.path +
                  '/images/${path.basename(newsList[i].image)}';
              if (await File(filePathAndName).exists()) {
                print("File exists");
                imageList.add(filePathAndName.toString());
              } else {
                File file2 = new File(filePathAndName);
                file2.writeAsBytesSync(response.bodyBytes);
                imageList.add(filePathAndName.toString());
              }
            }
            db.insertUserCatNews(newsData.toString(),
                imageList.join(',').toString(), CATID, CUR_USERID);
            for (int i = 0; i < newsList.length; i++) {
              id = newsList[i].id;
              otherImageList.clear();

              if (newsList[i].imageDataList.length != 0) {
                for (int j = 0; j < newsList[i].imageDataList.length; j++) {

                  var response = await http
                      .get(Uri.parse(newsList[i].imageDataList[j].other_image));
                  var filePathAndName1;
                  // documentDirectory is the unique device path to the area you'll be saving in
                  var documentDirectory =
                      await getApplicationDocumentsDirectory();
                  var firstPath = documentDirectory.path + "/otherImages";
                  //You'll have to manually create subdirectories
                  await Directory(firstPath).create(recursive: true);
                  // Name the file, create the file, and save in byte form.
                  filePathAndName1 = documentDirectory.path +
                      '/otherImages/${path.basename(newsList[i].imageDataList[j].other_image)}';
                  if (await File(filePathAndName1).exists()) {
                    print("File exists");
                    otherImageList.add(filePathAndName1.toString());
                  } else {
                    File file2 = new File(filePathAndName1);
                    file2.writeAsBytesSync(response.bodyBytes);
                    otherImageList.add(filePathAndName1.toString());
                  }

                }
                await db.insertNewsOtherImage(
                    id, otherImageList.join(',').toString());
              }
            }
          }
        } else {
          setState(() {
            isLoadingmore = false;
            _isLoading = false;
          });
        }
      } else {
        newsList = await db.getUserCatNews(CATID, CUR_USERID);
        setState(() {
          isLoadingmore = false;
          _isLoading = false;
        });
        //setSnackbar(getTranslated(context, 'internetmsg'));
      }
    }
  }

  //get latest news data list
  Future<void> getNews() async {
    if (widget.catIndex == 0 && CATID == "") {
      setState(() {
        _isLoading = true;
      });
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        var param = {
          ACCESS_KEY: access_key,
          LIMIT: perPage.toString(),
          OFFSET: offset.toString(),
          USER_ID: CUR_USERID != null && CUR_USERID != "" ? CUR_USERID : "0"
        };
        http.Response response = await http
            .post(Uri.parse(getNewsApi), body: param, headers: headers)
            .timeout(Duration(seconds: timeOut));
        var getdata = json.decode(response.body);

        String error = getdata["error"];
        if (error == "false") {
          String newsData = response.body.toString();
          total = int.parse(getdata["total"]);
          if ((offset) < total) {
            tempList.clear();
            newsList.clear();
            var data = getdata["data"];
            tempList =
                (data as List).map((data) => new News.fromJson(data)).toList();

            newsList.addAll(tempList);
            offset = offset + perPage;
            List<String> imageList = [];
            List<String> otherImageList = [];
            String id = "";

            if (mounted)
              setState(() {
                _isLoading = false;
              });
            for (int i = 0; i < newsList.length; i++) {
              var response = await http.get(Uri.parse(newsList[i].image));
              var filePathAndName;
              // documentDirectory is the unique device path to the area you'll be saving in
              var documentDirectory = await getApplicationDocumentsDirectory();
              var firstPath = documentDirectory.path + "/images";
              //You'll have to manually create subdirectories
              await Directory(firstPath).create(recursive: true);
              // Name the file, create the file, and save in byte form.
              filePathAndName = documentDirectory.path +
                  '/images/${path.basename(newsList[i].image)}';
              if (await File(filePathAndName).exists()) {
                print("File exists");
                imageList.add(filePathAndName.toString());
              } else {
                File file2 = new File(filePathAndName);
                file2.writeAsBytesSync(response.bodyBytes);
                imageList.add(filePathAndName.toString());
              }
            }

            db.insertNews(newsData.toString(), imageList.join(',').toString());

            for (int i = 0; i < newsList.length; i++) {
              id = newsList[i].id;
              otherImageList.clear();

              if (newsList[i].imageDataList.length != 0) {
                for (int j = 0; j < newsList[i].imageDataList.length; j++) {
                  var response = await http
                      .get(Uri.parse(newsList[i].imageDataList[j].other_image));
                  var filePathAndName1;
                  // documentDirectory is the unique device path to the area you'll be saving in
                  var documentDirectory =
                      await getApplicationDocumentsDirectory();
                  var firstPath = documentDirectory.path + "/otherImages";
                  //You'll have to manually create subdirectories
                  await Directory(firstPath).create(recursive: true);
                  // Name the file, create the file, and save in byte form.
                  filePathAndName1 = documentDirectory.path +
                      '/otherImages/${path.basename(newsList[i].imageDataList[j].other_image)}';
                  if (await File(filePathAndName1).exists()) {
                    print("File exists");
                    otherImageList.add(filePathAndName1.toString());
                  } else {
                    File file2 = new File(filePathAndName1);
                    file2.writeAsBytesSync(response.bodyBytes);
                    otherImageList.add(filePathAndName1.toString());
                  }

                }
                await db.insertNewsOtherImage(
                    id, otherImageList.join(',').toString());
              }
            }
          }
        } else {
          setState(() {
            isLoadingmore = false;
            _isLoading = false;
          });
        }
      } else {
        newsList = await db.getNews();
        setState(() {
          _isLoading = false;
          isLoadingmore = false;
        });
      }
    }
  }

//get news by category id using api
  Future<void> getNewsByCat() async {
    if (widget.catIndex != 0) {
      setState(() {
        _isLoading = true;
      });
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        var param = {
          ACCESS_KEY: access_key,
          CATEGORY_ID: widget.curTabId,
          LIMIT: perPage.toString(),
          OFFSET: offset.toString(),
          USER_ID: CUR_USERID != null && CUR_USERID != "" ? CUR_USERID : "0"
        };
        http.Response response = await http
            .post(Uri.parse(getNewsByCatApi), body: param, headers: headers)
            .timeout(Duration(seconds: timeOut));
        var getdata = json.decode(response.body);

        String error = getdata["error"];
        String newsData = response.body.toString();

        if (error == "false") {
          total = int.parse(getdata["total"]);

          if ((offset) < total) {
            tempList.clear();
            newsList.clear();
            var data = getdata["data"];

            tempList =
                (data as List).map((data) => new News.fromJson(data)).toList();

            newsList.addAll(tempList);

            offset = offset + perPage;
            if (mounted)
              setState(() {
                _isLoading = false;
              });
            List<String> imageList = [];
            String id = "";
            List<String> otherImageList = [];
            for (int i = 0; i < newsList.length; i++) {
              var response = await http.get(Uri.parse(newsList[i].image));
              var filePathAndName;
              // documentDirectory is the unique device path to the area you'll be saving in
              var documentDirectory = await getApplicationDocumentsDirectory();
              var firstPath = documentDirectory.path + "/images";
              //You'll have to manually create subdirectories
              await Directory(firstPath).create(recursive: true);
              // Name the file, create the file, and save in byte form.
              filePathAndName = documentDirectory.path +
                  '/images/${path.basename(newsList[i].image)}';
              if (await File(filePathAndName).exists()) {
                print("File exists");
                imageList.add(filePathAndName.toString());
              } else {
                File file2 = new File(filePathAndName);
                file2.writeAsBytesSync(response.bodyBytes);
                imageList.add(filePathAndName.toString());
              }
            }
            db.insertCatWiseNews(newsData.toString(),
                imageList.join(',').toString(), widget.curTabId);
            for (int i = 0; i < newsList.length; i++) {
              id = newsList[i].id;
              otherImageList.clear();
              if (newsList[i].imageDataList.length != 0) {
                for (int j = 0; j < newsList[i].imageDataList.length; j++) {
                  var response = await http
                      .get(Uri.parse(newsList[i].imageDataList[j].other_image));
                  var filePathAndName1;
                  // documentDirectory is the unique device path to the area you'll be saving in
                  var documentDirectory =
                      await getApplicationDocumentsDirectory();
                  var firstPath = documentDirectory.path + "/otherImages";
                  //You'll have to manually create subdirectories
                  await Directory(firstPath).create(recursive: true);
                  // Name the file, create the file, and save in byte form.
                  filePathAndName1 = documentDirectory.path +
                      '/otherImages/${path.basename(newsList[i].imageDataList[j].other_image)}';
                  if (await File(filePathAndName1).exists()) {
                    print("File exists");
                    otherImageList.add(filePathAndName1.toString());
                  } else {
                    File file2 = new File(filePathAndName1);
                    file2.writeAsBytesSync(response.bodyBytes);
                    otherImageList.add(filePathAndName1.toString());
                  }
                }
                await db.insertNewsOtherImage(
                    id, otherImageList.join(',').toString());
              }
            }
          }
        } else {
          setState(() {
            isLoadingmore = false;
            _isLoading = false;
          });
        }
      } else {
        newsList = await db.getCatWiseNews(widget.curTabId);
        setState(() {
          _isLoading = false;
          isLoadingmore = false;
        });
      }
    }
  }

  //set likes of news using api
  _setLikesDisLikes(String status, String id, int index) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      var param = {
        ACCESS_KEY: access_key,
        USER_ID: CUR_USERID,
        NEWS_ID: id,
        STATUS: status,
      };

      http.Response response = await http
          .post(Uri.parse(setLikesDislikesApi), body: param, headers: headers)
          .timeout(Duration(seconds: timeOut));

      var getdata = json.decode(response.body);

      String error = getdata["error"];

      String msg = getdata["message"];

      if (error == "false") {
        if (status == "1") {
          setSnackbar(getTranslated(context, 'like_succ'));
        } else if (status == "2") {
          setSnackbar(getTranslated(context, 'dislike_succ'));
        }
      }
    } else {
      setSnackbar(getTranslated(context, 'internetmsg'));
    }
  }

//set bookmark of news using api
  _setBookmark(String status, String id) async {
    if (bookMarkValue.contains(id)) {
      setState(() {
        bookMarkValue = List.from(bookMarkValue)..remove(id);
      });
    } else {
      setState(() {
        bookMarkValue = List.from(bookMarkValue)..add(id);
      });
    }

    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      var param = {
        ACCESS_KEY: access_key,
        USER_ID: CUR_USERID,
        NEWS_ID: id,
        STATUS: status,
      };

      http.Response response = await http
          .post(Uri.parse(setBookmarkApi), body: param, headers: headers)
          .timeout(Duration(seconds: timeOut));

      var getdata = json.decode(response.body);

      String error = getdata["error"];

      String msg = getdata["message"];

      if (error == "false") {
        if (status == "0") {
          setSnackbar(msg);
        } else {
          setSnackbar(msg);
        }
      }
    } else {
      setSnackbar(getTranslated(context, 'internetmsg'));
    }
  }

//get bookmark news list id using api
  Future<void> _getBookmark(int from) async {
    if (CUR_USERID != null && CUR_USERID != "") {
      if (from == 1) {
        setState(() {
          _isLoading = true;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          var param = {
            ACCESS_KEY: access_key,
            USER_ID: CUR_USERID,
          };
          http.Response response = await http
              .post(Uri.parse(getBookmarkApi), body: param, headers: headers)
              .timeout(Duration(seconds: timeOut));

          var getdata = json.decode(response.body);

          String error = getdata["error"];
          if (error == "false") {
            bookmarkList.clear();
            var data = getdata["data"];

            bookmarkList =
                (data as List).map((data) => new News.fromJson(data)).toList();
            bookMarkValue.clear();

            for (int i = 0; i < bookmarkList.length; i++) {
              setState(() {
                bookMarkValue.add(bookmarkList[i].newsId);
              });
            }
            if (mounted)
              setState(() {
                _isLoading = false;
              });
          } else {
            setState(() {
              isLoadingmore = false;
              _isLoading = false;
            });
          }
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg'));
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setSnackbar(getTranslated(context, 'internetmsg'));
      }
    }
  }

//refresh function used in refresh page
  Future<String> _refresh() async {
    setState(() {
      _isLoading = true;
    });
    return callApi();
  }

//create dynamic link that used in share specific news
  Future<void> createDynamicLink(String id, int index, String title) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: deepLinkUrlPrefix,
      link: Uri.parse('https://$deepLinkName/?id=$id&index=$index'),
      androidParameters: AndroidParameters(
        packageName: packageName,
        minimumVersion: 1,
      ),
      iosParameters: IosParameters(
        bundleId: iosPackage,
        minimumVersion: '1',
        appStoreId: appStoreId,
      ),
    );

    final Uri longDynamicUrl = await parameters.buildUrl();
    final ShortDynamicLink shortenedLink =
        await DynamicLinkParameters.shortenUrl(
      longDynamicUrl,
      new DynamicLinkParametersOptions(
          shortDynamicLinkPathLength: ShortDynamicLinkPathLength.unguessable),
    );
    var str =
        "${title}\n\n$appName\n\nYou can find our app from below url\n\nAndroid:\n"
        "$androidLink$packageName\n\n iOS:\n$iosLink$iosPackage";

    final Uri shortUrl = shortenedLink.shortUrl;

    Share.share(shortUrl.toString(), subject: str);
  }

//set category list load shimmer
  Widget catShimmer() {
    isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    return Container(
        width: double.infinity,
        child: Shimmer.fromColors(
            baseColor:
                isDarkTheme ? Colors.grey.withOpacity(0.7) : Colors.grey[300],
            highlightColor:
                isDarkTheme ? Colors.grey.withOpacity(0.7) : Colors.grey[300],
            child: SingleChildScrollView(
                padding: EdgeInsetsDirectional.only(
                    start: 15.0, end: 15.0, top: 5.0),
                child: Column(children: [
                  Container(
                    height: 20.0,
                    color: Colors.grey,
                  ),
                  Padding(
                    padding: EdgeInsetsDirectional.only(top: 7.0, bottom: 20.0),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: BouncingScrollPhysics(),
                      itemBuilder: (_, __) => Padding(
                          padding: EdgeInsetsDirectional.only(top: 20.0),
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15.0),
                                color: Colors.grey),
                            height: 180.0,
                          )),
                      itemCount: 5,
                    ),
                  )
                ]))));
  }

  void handleEvent(
      AdmobAdEvent event, Map<String, dynamic> args, String adType) {
    switch (event) {
      case AdmobAdEvent.loaded:
        print('New Admob $adType Ad loaded!');
        break;
      case AdmobAdEvent.opened:
        print('Admob $adType Ad opened!');
        break;
      case AdmobAdEvent.closed:
        print('Admob $adType Ad closed!');
        break;
      case AdmobAdEvent.failedToLoad:
        print('Admob $adType failed to load. :(');
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        key: _scaffoldKey2,
        body: _isLoading
            ? catShimmer()
            : newsList.length != 0
                ? RefreshIndicator(
                    key: _refreshIndicatorKey,
                    onRefresh: _refresh,
                    child: SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: Padding(
                            padding: EdgeInsetsDirectional.only(
                                top: 7.0, bottom: 20.0, start: 15.0, end: 15.0),
                            child: Column(children: [
                              Row(
                                children: [
                                  Text(widget.catName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle2
                                          .copyWith()),
                                  Expanded(
                                      child: Divider(
                                      color: Colors.red,
                                    thickness: 1.0,
                                    indent: 10.0,
                                  ))
                                ],
                              ),
                              Padding(
                                  padding: EdgeInsetsDirectional.only(top: 5.0),
                                  child: ListView.builder(
                                      controller: controller,
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: newsList.length,
                                      itemBuilder: (context, index) {
                                        DateTime time1 = DateTime.parse(
                                            newsList[index].date);
                                        return (index == newsList.length &&
                                                isLoadingmore)
                                            ? Center(
                                                child:
                                                    CircularProgressIndicator())
                                            : Padding(
                                                padding:
                                                    EdgeInsetsDirectional.only(
                                                        top: 15.0),
                                                child: Column(
                                                    children: <Widget>[
                                                      _isNetworkAvail
                                                          ? index == 2 ||
                                                                  index == 5 || index == 7 || index == 9 || index == 12 || index == 14 || index == 17 || index == 19
                                                              ? Padding(
                                                                  padding: EdgeInsets
                                                                      .only(
                                                                          bottom:
                                                                              15.0),
                                                                  child: Column(
                                                                    children:[
                                                                      Container(
                                                                        padding: EdgeInsets.all(7.0),
                                                                        height: 180,
                                                                        width: double.infinity,
                                                                        decoration: BoxDecoration(
                                                                          color: Theme.of(context)
                                                                              .colorScheme
                                                                              .white,
                                                                          borderRadius:
                                                                              BorderRadius.circular(15.0),
                                                                          boxShadow: [
                                                                            BoxShadow(
                                                                                color: Theme.of(context).colorScheme.fontColor2.withOpacity(0.37),
                                                                                spreadRadius: 1.8,
                                                                                blurRadius: 4.0)
                                                                          ],
                                                                        ),
                                                                        child: NativeAdmob(
                                                                          // Your ad unit id
                                                                          adUnitID:
                                                                              AdHelper.nativeAdUnitId,
                                                                          numberAds:
                                                                              3,
                                                                          controller:
                                                                              _nativeAdController,
                                                                          type: NativeAdmobType
                                                                              .full,
                                                                        )),
                                                                      // Padding(
                                                                      //   padding: EdgeInsets
                                                                      //       .only(
                                                                      //       bottom:
                                                                      //       15.0),
                                                                      //   child: Container(
                                                                      //       padding: EdgeInsets.all(7.0),
                                                                      //       height: 180,
                                                                      //       width: double.infinity,
                                                                      //       decoration: BoxDecoration(
                                                                      //         color: Theme.of(context)
                                                                      //             .colorScheme
                                                                      //             .white,
                                                                      //         borderRadius:
                                                                      //         BorderRadius.circular(15.0),
                                                                      //         boxShadow: [
                                                                      //           BoxShadow(
                                                                      //               color: Theme.of(context).colorScheme.fontColor2.withOpacity(0.37),
                                                                      //               spreadRadius: 1.8,
                                                                      //               blurRadius: 4.0)
                                                                      //         ],
                                                                      //       ),
                                                                      //       child: NativeAdmob(
                                                                      //         // Your ad unit id
                                                                      //         adUnitID:
                                                                      //         AdHelper.nativeAdUnitId,
                                                                      //         numberAds:
                                                                      //         1,
                                                                      //         controller:
                                                                      //         _nativeAdController,
                                                                      //         type: NativeAdmobType
                                                                      //             .full,
                                                                      //       )),
                                                                      // )
                                                                  ]))
                                                              : Container()
                                                          : Container(),
                                                      AbsorbPointer(
                                                        absorbing: !enabled,
                                                        child: InkWell(
                                                          child: Stack(
                                                            children: [
                                                              Container(
                                                                  decoration:
                                                                      BoxDecoration(
                                                                          color: Theme.of(context)
                                                                              .colorScheme
                                                                              .white,
                                                                          boxShadow: [
                                                                            BoxShadow(
                                                                                color: Theme.of(context).colorScheme.fontColor.withOpacity(0.37),
                                                                                spreadRadius: 1.8,
                                                                                blurRadius: 4.0)
                                                                          ],
                                                                          borderRadius:
                                                                              BorderRadius.circular(15)),
                                                                  child: ClipRRect(
                                                                      borderRadius: BorderRadius.circular(15),
                                                                      child: ShaderMask(
                                                                          shaderCallback: (rect) {
                                                                            return LinearGradient(
                                                                              begin: Alignment.topCenter,
                                                                              end: Alignment.bottomCenter,
                                                                              colors: [
                                                                                Colors.transparent,
                                                                                Colors.black.withOpacity(0.87)
                                                                              ],
                                                                            ).createShader(rect);
                                                                          },
                                                                          blendMode: BlendMode.darken,
                                                                          child: FadeInImage(
                                                                            fadeInDuration:
                                                                                Duration(milliseconds: 150),
                                                                            image:
                                                                                NetworkImage(newsList[index].image),
                                                                           //My real height
                                                                            height:
                                                                                180.0,
                                                                            width:
                                                                                double.infinity,
                                                                            fit:
                                                                                BoxFit.fill,
                                                                            placeholder:
                                                                                placeHolder(),
                                                                            imageErrorBuilder: (context,
                                                                                error,
                                                                                stackTrace) {
                                                                              return Image.file(
                                                                                File(newsList[index].image),
                                                                                height: 180.0,
                                                                                width: double.infinity,
                                                                                fit: BoxFit.fill,
                                                                              );
                                                                            },
                                                                          )))),


                                                              //Like
                                                              Positioned
                                                                  .directional(
                                                                      textDirection:
                                                                          Directionality.of(
                                                                              context),
                                                                      top: 7.0,
                                                                      end: 9.0,
                                                                      child: Row(
                                                                          children: [
                                                                            Text(
                                                                              newsList[index].totalLikes == "0" ? "" : newsList[index].totalLikes,
                                                                              style: Theme.of(context).textTheme.subtitle2.copyWith(
                                                                                    color: colors.tempWhite,
                                                                                  ),
                                                                            ),
                                                                            Padding(
                                                                                padding: EdgeInsetsDirectional.only(start: 5.0),
                                                                                child: InkWell(
                                                                                  child: newsList[index].like == "1"
                                                                                      ? Image.asset(
                                                                                          "assets/images/liked_icon.png",
                                                                                          color: colors.tempWhite,
                                                                                          height: 25.0,
                                                                                          width: 25.0,
                                                                                        )
                                                                                      : Image.asset(
                                                                                          "assets/images/unlike_icon.png",
                                                                                          color: colors.tempWhite,
                                                                                          height: 25.0,
                                                                                          width: 25.0,
                                                                                        ),
                                                                                  onTap: () async {
                                                                                    _isNetworkAvail = await isNetworkAvailable();

                                                                                    if (CUR_USERID != null && CUR_USERID != "") {
                                                                                      if (_isNetworkAvail) {
                                                                                        if (newsList[index].like == "1") {
                                                                                          _setLikesDisLikes("2", newsList[index].id, index);
                                                                                          newsList[index].like = "0";
                                                                                          newsList[index].totalLikes = (int.parse(newsList[index].totalLikes) - 1).toString();
                                                                                          setState(() {});
                                                                                        } else {
                                                                                          _setLikesDisLikes("1", newsList[index].id, index);
                                                                                          newsList[index].like = "1";
                                                                                          newsList[index].totalLikes = (int.parse(newsList[index].totalLikes) + 1).toString();
                                                                                          setState(() {});
                                                                                        }
                                                                                      } else {
                                                                                        setSnackbar(getTranslated(context, 'internetmsg'));
                                                                                      }
                                                                                    } else {
                                                                                      Navigator.push(
                                                                                          context,
                                                                                          MaterialPageRoute(
                                                                                            builder: (context) => Login(),
                                                                                          ));
                                                                                    }
                                                                                  },
                                                                                ))
                                                                          ])),


                                                              //Title
                                                              Positioned
                                                                  .directional(
                                                                      textDirection:
                                                                          Directionality.of(
                                                                              context),
                                                                      bottom:
                                                                          7.0,
                                                                      start:
                                                                          9.0,
                                                                      child:
                                                                          Column(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          SizedBox(
                                                                              width: deviceWidth / 1.7,
                                                                              child: Padding(padding: EdgeInsetsDirectional.only(top: 5.0), child: Text(newsList[index].title, maxLines: 2, overflow: TextOverflow.ellipsis, textScaleFactor: 1.2, style: Theme.of(context).textTheme.subtitle2.copyWith(color: colors.tempWhite, height: 1.0)))),
                                                                          Text(
                                                                              convertToAgo(time1, 0),
                                                                              style: Theme.of(context).textTheme.caption.copyWith(color: colors.tempWhite, fontSize: 13.0)),

                                                                        ],
                                                                      )),

                                                              //Bookmark
                                                              Positioned
                                                                  .directional(
                                                                      textDirection:
                                                                          Directionality.of(
                                                                              context),
                                                                      bottom:
                                                                          7.0,
                                                                      end: 9.0,
                                                                      child: Row(
                                                                          children: [
                                                                            InkWell(
                                                                                child: Container(
                                                                                    height: 30.0,
                                                                                    alignment: Alignment.center,
                                                                                    padding: EdgeInsets.all(2.0),
                                                                                    decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.white, border: Border.all(color: Theme.of(context).colorScheme.white)),
                                                                                    child: Icon(
                                                                                      bookMarkValue.contains(newsList[index].id) ? Icons.bookmark : Icons.bookmark_border,
                                                                                      color: Theme.of(context).colorScheme.fontColor,
                                                                                      size: 20.0,
                                                                                    )),
                                                                                onTap: () async {
                                                                                  _isNetworkAvail = await isNetworkAvailable();
                                                                                  if (CUR_USERID != null && CUR_USERID != "") {
                                                                                    if (_isNetworkAvail) {
                                                                                      setState(() {
                                                                                        bookMarkValue.contains(newsList[index].id) ? _setBookmark("0", newsList[index].id) : _setBookmark("1", newsList[index].id);
                                                                                      });
                                                                                    } else {
                                                                                      setSnackbar(getTranslated(context, 'internetmsg'));
                                                                                    }
                                                                                  } else {
                                                                                    Navigator.push(
                                                                                        context,
                                                                                        MaterialPageRoute(
                                                                                          builder: (context) => Login(),
                                                                                        ));
                                                                                  }
                                                                                }),


                                                                            //Share button

                                                                            // Padding(
                                                                            //     padding: EdgeInsetsDirectional.only(start: 7.0),
                                                                            //     child: InkWell(
                                                                            //       child: Container(
                                                                            //           height: 30.0,
                                                                            //           alignment: Alignment.center,
                                                                            //           padding: EdgeInsets.all(2.0),
                                                                            //           decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.white, border: Border.all(color: Theme.of(context).colorScheme.white)),
                                                                            //           child: Icon(
                                                                            //             Icons.share_sharp,
                                                                            //             color: Theme.of(context).colorScheme.fontColor,
                                                                            //             size: 18.0,
                                                                            //           )),
                                                                            //       onTap: () async {
                                                                            //         _isNetworkAvail = await isNetworkAvailable();
                                                                            //         if (_isNetworkAvail) {
                                                                            //           createDynamicLink(newsList[index].id, index, newsList[index].title);
                                                                            //         } else {
                                                                            //           setSnackbar(getTranslated(context, 'internetmsg'));
                                                                            //         }
                                                                            //       },
                                                                            //     )),
                                                                          ])),
                                                            ],
                                                          ),
                                                          onTap: () async {
                                                            setState(() {
                                                              enabled = false;
                                                            });
                                                            News model =
                                                                newsList[index];
                                                            Navigator.of(context).push(
                                                                MaterialPageRoute(
                                                                    builder: (BuildContext
                                                                            context) =>
                                                                        NewsDetails(
                                                                          model:
                                                                              model,
                                                                          index:
                                                                              index,
                                                                          updateParent:
                                                                              updateHomePage,
                                                                          id: model
                                                                              .id,
                                                                          isFav:
                                                                              false,
                                                                        )));
                                                            setState(() {
                                                              enabled = true;
                                                            });
                                                          },
                                                        ),
                                                      )
                                                    ]));
                                      }))
                            ]))))
                : Center(child: Text(getTranslated(context, 'no_news'))));
  }

  @override
  bool get wantKeepAlive => true;
}
