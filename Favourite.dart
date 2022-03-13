import 'dart:async';
import 'dart:convert';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart' as intl;
import 'package:share/share.dart';
import 'package:shimmer/shimmer.dart';
import 'Helper/Constant.dart';
import 'Helper/Session.dart';
import 'Helper/String.dart';
import 'package:news/Helper/Color.dart';
import 'Login.dart';
import 'Model/News.dart';
import 'NewsDetails.dart';

class Favourite extends StatefulWidget {
  Function update;

  Favourite(this.update);

  @override
  FavouriteState createState() => FavouriteState();
}

List bookMarkValue = [];
List<News> bookmarkList = [];
int offset = 0;
int total = 0;
bool isLoadingmore = true;
bool _isLoading = true;

class FavouriteState extends State<Favourite> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  List<News> tempList = [];
  bool _isNetworkAvail = true;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  ScrollController controller = new ScrollController();
  bool enabled = true;
  var isDarkTheme;

  @override
  void initState() {
    offset = 0;
    total = 0;
    _getBookmark();
    controller.addListener(_scrollListener);
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  //set bookmook api here
  _setBookmark(String status, String id, int index) async {
    if (bookMarkValue.contains(id)) {
      setState(() {
        bookmarkList = List.from(bookmarkList)..removeAt(index);
        bookMarkValue = List.from(bookMarkValue)..remove(id);
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
      Response response =
          await post(Uri.parse(setBookmarkApi), body: param, headers: headers)
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

  //get bookmark api here
  _getBookmark() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      if (CUR_USERID != null && CUR_USERID != "") {
        try {
          var param = {
            ACCESS_KEY: access_key,
            USER_ID: CUR_USERID,
            LIMIT: perPage.toString(),
            OFFSET: offset.toString(),
          };
          Response response = await post(Uri.parse(getBookmarkApi),
                  body: param, headers: headers)
              .timeout(Duration(seconds: timeOut));

          var getdata = json.decode(response.body);

          String error = getdata["error"];
          if (error == "false") {
            total = int.parse(getdata["total"]);

            if ((offset) < total) {
              var data = getdata["data"];
              tempList.clear();
              tempList = (data as List)
                  .map((data) => new News.fromJson(data))
                  .toList();
              if (offset == 0) bookmarkList.clear();
              bookmarkList.addAll(tempList);
              bookMarkValue.clear();
              for (int i = 0; i < bookmarkList.length; i++) {
                bookMarkValue.add(bookmarkList[i].newsId);
              }
              offset = offset + perPage;
            }

            if (this.mounted)
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
        }
      } else {
        setState(() {
          isLoadingmore = false;
          _isLoading = false;
        });
      }
    } else {
      setSnackbar(getTranslated(context, 'internetmsg'));
    }
  }

  //set likes of news using api
  _setLikesDisLikes(String status, String id) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      var param = {
        ACCESS_KEY: access_key,
        USER_ID: CUR_USERID,
        NEWS_ID: id,
        STATUS: status,
      };

      Response response = await post(Uri.parse(setLikesDislikesApi),
              body: param, headers: headers)
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

  //set snackbar here
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

  updateFav(bool like, int from, String id) {
    if (from == 1) {
      setState(() {
        offset = 0;
        total = 0;
        bookmarkList.clear();
        bookMarkValue.clear();
        _getBookmark();
      });
    } else {
      if (like) {
        setState(() {
          for (int i = 0; i < bookmarkList.length; i++) {
            if (bookmarkList[i].newsId == id) {
              bookmarkList[i].totalLikes =
                  (int.parse(bookmarkList[i].totalLikes) + 1).toString();
              bookmarkList[i].like = "1";
            }
          }
        });
      } else {
        setState(() {
          for (int i = 0; i < bookmarkList.length; i++) {
            if (bookmarkList[i].newsId == id) {
              bookmarkList[i].totalLikes =
                  (int.parse(bookmarkList[i].totalLikes) - 1).toString();
              bookmarkList[i].like = "0";
            }
          }
        });
      }
    }
  }

  callApi() {
    offset = 0;
    total = 0;
    _getBookmark();
  }

  //refresh function to refresh page
  Future<String> _refresh() async {
    setState(() {
      _isLoading = true;
    });
    return callApi();
  }

  _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if (this.mounted) {
        setState(() {
          isLoadingmore = true;

          if (offset < total) _getBookmark();
        });
      }
    }
  }

  //create here to dynamic link to share news id, index and title
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

    Share.share(shortenedLink.shortUrl.toString(), subject: str);
  }

  //show bookmarklist
  getBookmarkList() {
    double width = MediaQuery.of(context).size.width;
    return RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refresh,
        child: ListView.builder(
            controller: controller,
            shrinkWrap: true,
            physics: AlwaysScrollableScrollPhysics(),
            itemCount: bookmarkList.length,
            itemBuilder: (context, index) {
              DateTime time1 = DateTime.parse(bookmarkList[index].date);

              return (index == bookmarkList.length && isLoadingmore)
                  ? favShimmer()
                  : Padding(
                      padding: EdgeInsetsDirectional.only(top: 15.0),
                      child: Hero(
                          tag: bookmarkList[index].id,
                          child: AbsorbPointer(
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
                                          child:  Center(
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
                                            image: NetworkImage(
                                                bookmarkList[index].image),
                                            height: 250.0,
                                            width: double.infinity,
                                            fit: BoxFit.fill,
                                            placeholder: placeHolder(),
                                            imageErrorBuilder:
                                                (context, error, stackTrace) {
                                              return errorWidget(250.0);
                                            }),
                                      )))),
                                  Positioned.directional(
                                      textDirection: Directionality.of(context),
                                      top: 7.0,
                                      end: 9.0,
                                      child: Row(children: [
                                        Text(
                                          bookmarkList[index].totalLikes == "0"
                                              ? ""
                                              : bookmarkList[index].totalLikes,
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle2
                                              .copyWith(
                                                color: colors.tempWhite,
                                              ),
                                        ),
                                        Padding(
                                            padding: EdgeInsetsDirectional.only(
                                                start: 5.0),
                                            child: InkWell(
                                              child: bookmarkList[index].like ==
                                                      "1"
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
                                                if (CUR_USERID != null &&
                                                    CUR_USERID != "") {
                                                  _isNetworkAvail =
                                                      await isNetworkAvailable();
                                                  if (_isNetworkAvail) {
                                                    if (bookmarkList[index]
                                                            .like ==
                                                        "1") {
                                                      _setLikesDisLikes(
                                                          "2",
                                                          bookmarkList[index]
                                                              .newsId);
                                                      bookmarkList[index].like =
                                                          "0";
                                                      bookmarkList[index]
                                                              .totalLikes =
                                                          (int.parse(bookmarkList[
                                                                          index]
                                                                      .totalLikes) -
                                                                  1)
                                                              .toString();
                                                      setState(() {});
                                                    } else {
                                                      _setLikesDisLikes(
                                                          "1",
                                                          bookmarkList[index]
                                                              .newsId);
                                                      bookmarkList[index].like =
                                                          "1";
                                                      bookmarkList[index]
                                                              .totalLikes =
                                                          (int.parse(bookmarkList[
                                                                          index]
                                                                      .totalLikes) +
                                                                  1)
                                                              .toString();
                                                      setState(() {});
                                                    }
                                                  } else {
                                                    setSnackbar(getTranslated(
                                                        context,
                                                        'internetmsg'));
                                                  }
                                                } else {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            Login(),
                                                      ));
                                                }
                                              },
                                            ))
                                      ])),
                                  Positioned.directional(
                                      textDirection: Directionality.of(context),
                                      bottom: 7.0,
                                      start: 9.0,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(convertToAgo(time1, 0),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .caption
                                                  .copyWith(
                                                      color: colors.tempWhite,
                                                      fontSize: 13.0)),
                                          Text(bookmarkList[index].categoryName,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .caption
                                                  .copyWith(
                                                      color: colors.tempWhite,
                                                      fontSize: 11.0)),
                                          Padding(
                                              padding:
                                                  EdgeInsetsDirectional.only(
                                                      top: 4.0),
                                              child: SizedBox(
                                                  width: width / 1.7,
                                                  child: Text(
                                                      bookmarkList[index].title,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      textScaleFactor: 1.2,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .subtitle2
                                                          .copyWith(
                                                              color: colors
                                                                  .tempWhite,
                                                              height: 1.0)))),
                                        ],
                                      )),
                                  Positioned.directional(
                                      textDirection: Directionality.of(context),
                                      bottom: 7.0,
                                      end: 9.0,
                                      child: Row(children: [
                                        InkWell(
                                            child: Container(
                                                height: 30.0,
                                                alignment: Alignment.center,
                                                padding: EdgeInsets.all(2.0),
                                                decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .white,
                                                    border: Border.all(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .white)),
                                                child: Icon(
                                                  bookMarkValue.contains(
                                                          bookmarkList[index]
                                                              .newsId)
                                                      ? Icons.bookmark
                                                      : Icons.bookmark_border,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .fontColor,
                                                  size: 20.0,
                                                )),
                                            onTap: () async {
                                              if (CUR_USERID != null) {
                                                _isNetworkAvail =
                                                    await isNetworkAvailable();
                                                if (_isNetworkAvail) {
                                                  _setBookmark(
                                                      "0",
                                                      bookmarkList[index]
                                                          .newsId,
                                                      index);
                                                } else {
                                                  setSnackbar(getTranslated(
                                                      context, 'internetmsg'));
                                                }
                                              } else {
                                                Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          Login()),
                                                );
                                              }
                                            }),
                                        Padding(
                                            padding: EdgeInsetsDirectional.only(
                                                start: 7.0, end: 7.0),
                                            child: InkWell(
                                                child: Container(
                                                    height: 30.0,
                                                    alignment: Alignment.center,
                                                    padding:
                                                        EdgeInsets.all(2.0),
                                                    decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .white,
                                                        border: Border.all(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .white)),
                                                    child: Icon(
                                                      Icons.share_sharp,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .fontColor,
                                                      size: 18.0,
                                                    )),
                                                onTap: () async {
                                                  _isNetworkAvail =
                                                      await isNetworkAvailable();
                                                  if (_isNetworkAvail) {
                                                    createDynamicLink(
                                                        bookmarkList[index]
                                                            .newsId,
                                                        index,
                                                        bookmarkList[index]
                                                            .title);
                                                  } else {
                                                    setSnackbar(getTranslated(
                                                        context,
                                                        'internetmsg'));
                                                  }
                                                })),
                                      ])),
                                ],
                              ),
                              onTap: () async {
                                setState(() {
                                  enabled = false;
                                });
                                News model = bookmarkList[index];
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (BuildContext context) =>
                                        NewsDetails(
                                          model: model,
                                          index: index,
                                          updateParent: updateFav,
                                          id: model.newsId,
                                          isFav: true,
                                        )));
                                setState(() {
                                  enabled = true;
                                });
                              },
                            ),
                          )));
            }));
  }

//show shimmer effets
  Widget favShimmer() {
    isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    return Container(
        width: double.infinity,
        child: Shimmer.fromColors(
            baseColor: isDarkTheme?Colors.grey.withOpacity(0.7):Colors.grey[300],
            highlightColor: isDarkTheme?Colors.grey.withOpacity(0.7):Colors.grey[300],
            child: SingleChildScrollView(
                padding: EdgeInsetsDirectional.only(
                    top: 10.0, bottom: 20.0, start: 15.0, end: 15.0),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: BouncingScrollPhysics(),
                  itemBuilder: (_, __) => Column(
                    children: [
                      Padding(
                          padding: EdgeInsetsDirectional.only(top: 20.0),
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15.0),
                                color: Colors.grey),
                            height: 180.0,
                          ))
                    ],
                  ),
                  itemCount: 5,
                ))));
  }

//user not login then show this function used to navigate login screen
  Widget loginMsg() {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Container(
        height: height,
        width: width,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              getTranslated(context, 'bookmark_login'),
              style: Theme.of(context).textTheme.subtitle2,
              textAlign: TextAlign.center,
            ),
            InkWell(
                child: Text(
                  getTranslated(context, 'loginnow_lbl'),
                  style: Theme.of(context)
                      .textTheme
                      .subtitle2
                      .copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Login(),
                      ));
                }),
          ],
        ));
  }

//news bookmark list have no news then call this function
  Widget getNoItem() {
    return Center(child: Text(getTranslated(context, 'bookmark_nt_avail')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: _isLoading
          ? favShimmer()
          : CUR_USERID != null && CUR_USERID != ""
              ? Padding(
                  padding: EdgeInsetsDirectional.only(
                      top: 10.0, bottom: 10.0, start: 13.0, end: 13.0),
                  child: bookmarkList.length == 0
                      ? getNoItem()
                      : getBookmarkList())
              : loginMsg(),
    );
  }
}
