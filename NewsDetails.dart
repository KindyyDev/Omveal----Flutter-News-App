import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:admob_flutter/admob_flutter.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart' as intl;
import 'package:news/Helper/AdHelper.dart';
import 'package:news/Helper/Color.dart';
import 'package:news/Helper/Constant.dart';
import 'package:news/Helper/String.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'Helper/Data_Helper.dart';
import 'Helper/Session.dart';
import 'Image_Preview.dart';
import 'Login.dart';
import 'Model/News.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' show parse;
import 'package:path/path.dart' as path;

class NewsDetails extends StatefulWidget {
  final News model;
  final int index;
  final Function(bool, int, String) updateParent;
  final String id;
  final bool isFav;

  const NewsDetails(
      {Key key, this.model, this.index, this.updateParent, this.id, this.isFav})
      : super(key: key);

  @override
  NewsDetailsState createState() => NewsDetailsState();
}

class NewsDetailsState extends State<NewsDetails> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool _isNetworkAvail = true;
  List<News> newsList = [];
  List<News> newsList1 = [];
  bool _isLoading = true;
  bool isLoadingmore = true;
  int offset = 0;
  int total = 0;
  final _pageController = PageController();
  int _curSlider = 0;
  AdmobInterstitial interstitialAd;
  AdmobReward rewardAd;
  var db = new DatabaseHelper();

  @override
  void initState() {
    getUserDetails();
    getNews();

    interstitialAd = AdmobInterstitial(
      adUnitId: AdHelper.interstitialAdUnitId,
      listener: (AdmobAdEvent event, Map<String, dynamic> args) {
        if (event == AdmobAdEvent.closed) interstitialAd.load();
        handleEvent(event, args, 'Interstitial');
      },
    );

    rewardAd = AdmobReward(
      adUnitId: AdHelper.rewardAdUnitId,
      listener: (AdmobAdEvent event, Map<String, dynamic> args) {
        if (event == AdmobAdEvent.closed) rewardAd.load();
        handleEvent(event, args, 'Reward');
      },
    );

    interstitialAd.load();
    rewardAd.load();

    super.initState();
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
      case AdmobAdEvent.rewarded:
        showDialog(
          context: _scaffoldKey.currentContext,
          builder: (BuildContext context) {
            return WillPopScope(
              child: AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('Reward callback fired. Thanks!'),
                    Text('Type: ${args['type']}'),
                    Text('Amount: ${args['amount']}'),
                  ],
                ),
              ),
              onWillPop: () async {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                return true;
              },
            );
          },
        );
        break;
      default:
    }
  }

  //get user prefrences set before
  getUserDetails() async {
    CUR_USERID = await getPrefrence(ID);
    CUR_USERNAME = await getPrefrence(NAME);
    CUR_USEREMAIL = await getPrefrence(EMAIL);
    setState(() {});
  }

  //get news list using api
  Future<void> getNews() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      var param = {
        ACCESS_KEY: access_key,
        LIMIT: (perPage + 1).toString(),
        OFFSET: offset.toString(),
        USER_ID: CUR_USERID != null && CUR_USERID != "" ? CUR_USERID : "0"
      };
      Response response =
          await post(Uri.parse(getNewsApi), body: param, headers: headers)
              .timeout(Duration(seconds: timeOut));
      var getdata = json.decode(response.body);

      String error = getdata["error"];

      if (error == "false") {
        String newsData = response.body.toString();
        total = int.parse(getdata["total"]);
        if ((offset) < total) {
          var data = getdata["data"];

          newsList.clear();
          List<News> tempList =
              (data as List).map((data) => new News.fromJson(data)).toList();
          newsList.addAll(tempList);

          for (int j = 0; j < newsList.length; j++) {
            if (widget.id == newsList[j].id) {
              newsList = List.from(newsList)..removeAt(j);
            } else {
              newsList1.add(newsList[j]);
            }
          }

          offset = offset + perPage;
          List<String> imageList = [];
          List<String> otherImageList = [];
          String id = "";

          if (mounted)
            setState(() {
              _isLoading = false;
            });
          for (int i = 0; i < tempList.length; i++) {
            id = tempList[i].id;
            var response = await get(Uri.parse(tempList[i].image));
            var filePathAndName;
            // documentDirectory is the unique device path to the area you'll be saving in
            var documentDirectory = await getApplicationDocumentsDirectory();
            var firstPath = documentDirectory.path + "/images";
            //You'll have to manually create subdirectories
            await Directory(firstPath).create(recursive: true);
            // Name the file, create the file, and save in byte form.
            filePathAndName = documentDirectory.path +
                '/images/${path.basename(tempList[i].image)}';

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

          for (int i = 0; i < tempList.length; i++) {
            id = tempList[i].id;
            otherImageList.clear();
            if (tempList[i].imageDataList.length != 0) {
              for (int j = 0; j < tempList[i].imageDataList.length; j++) {
                var response = await get(
                    Uri.parse(tempList[i].imageDataList[j].other_image));
                var filePathAndName1;
                // documentDirectory is the unique device path to the area you'll be saving in
                var documentDirectory =
                    await getApplicationDocumentsDirectory();
                var firstPath = documentDirectory.path + "/otherImages";
                //You'll have to manually create subdirectories
                await Directory(firstPath).create(recursive: true);
                // Name the file, create the file, and save in byte form.
                filePathAndName1 = documentDirectory.path +
                    '/otherImages/${path.basename(tempList[i].imageDataList[j].other_image)}';
                if (await File(filePathAndName1).exists()) {
                  print("File exists");
                  otherImageList.add(filePathAndName1.toString());
                } else {
                  File file2 = new File(filePathAndName1);
                  file2.writeAsBytesSync(response.bodyBytes);
                  otherImageList.add(filePathAndName1.toString());
                }
              }
              db.insertNewsOtherImage(id, otherImageList.join(',').toString());
            }
          }
        }
      } else {
        setState(() {
          _isLoading = true;
        });
      }
    } else {
      newsList = await db.getNews();
      for (int j = 0; j < newsList.length; j++) {
        if (widget.id == newsList[j].id) {
          newsList = List.from(newsList)..removeAt(j);
        } else {
          newsList1.add(newsList[j]);
        }
      }
      setState(() {
        _isLoading = false;
        isLoadingmore = false;
      });
      //setSnackbar(getTranslated(context, 'internetmsg'));
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
      backgroundColor: Colors.white,
      elevation: 1.0,
    ));
  }

  //page slider news list data
  Widget _slider() {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Container(
        height: height,
        width: width,
        child: PageView.builder(
            itemCount: newsList1.length == 0
                ? 1
                : newsList1.length >= perPage
                    ? perPage
                    : newsList1.length,
            controller: _pageController,
            onPageChanged: (index) async {
              setState(() {
                _curSlider = index;
              });
              _isNetworkAvail = await isNetworkAvailable();
              if (_isNetworkAvail) {
                if (index == 3) {
                  if (await interstitialAd.isLoaded) {
                    interstitialAd.show();
                  } else {
                    print('Interstitial ad is still loading...');
                  }
                }
                //option for another ad
                  // if (index == 12){r
                  //   if (await interstitialAd.isLoaded) {
                  //     interstitialAd.show();
                  //   } else {
                  //     print('Interstitial ad is still loading...');
                  //   }
                  // }
                //option ends
                if (index == 7) {
                  if (await rewardAd.isLoaded) {
                    rewardAd.show();
                  } else {
                    print('Reward ad is still loading...');
                  }
                }
              }
            },
            itemBuilder: (BuildContext context, int index) {
              return index == 0
                  ? NewsSubDetails(
                      model: widget.model,
                      index: widget.index,
                      updateParent: widget.updateParent,
                      id: widget.id)
                  : NewsSubDetails(
                      model: newsList1[index],
                      index: index,
                      updateParent: widget.updateParent,
                      id: newsList1[index].id);
            }));
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return Scaffold(key: _scaffoldKey, body: _slider());
  }
}

class NewsSubDetails extends StatefulWidget {
  final News model;
  final int index;
  final Function(bool, int, String) updateParent;
  final String id;

  const NewsSubDetails(
      {Key key, this.model, this.index, this.updateParent, this.id})
      : super(key: key);

  @override
  NewsSubDetailsState createState() => NewsSubDetailsState();
}

class NewsSubDetailsState extends State<NewsSubDetails>
    with TickerProviderStateMixin {
  final _scaffoldKey1 = GlobalKey<ScaffoldState>();

  bool _isNetworkAvail = true;
  int _fontValue = 18;
  List<News> newsList = [];
  List<News> bookmarkList = [];
  List<News> commentList = [];
  List<News> newsList1 = [];
  bool _isBookmark = false;
  TextEditingController _commentC = new TextEditingController();
  TextEditingController reportC = new TextEditingController();
  FlickManager flickManager;
  FlickManager flickManager1;
  YoutubePlayerController _yc;
  String profile;
  String comTotal = "";
  bool _isLoading = true;
  bool isLoadingmore = true;
  bool comBtnEnabled = false;
  int offset = 0;
  int total = 0;
  bool _isDetails = true;
  ScrollController controller = new ScrollController();
  bool _isVideoAvail = false;
  bool _isFirstTime = true;
  double startPos = -1.0;
  double endPos = 0.0;
  Curve curve = Curves.elasticOut;
  AnimationController animationController, animationController1;
  bool _isYouTubeVideo = false;
  bool isPlaying = false;
  FlutterTts _flutterTts;

  List<String> allImage = [];
  int _curSlider = 0;
  final PageController _pageController = PageController(initialPage: 0);
  PersistentBottomSheetController _controller;

  @override
  void initState() {
    getUserDetails();
    _getBookmark();
    _getComment();
    // initializeTts();
    allImage.clear();
    allImage.add(widget.model.image);
    if (widget.model.imageDataList.length != 0) {
      for (int i = 0; i < widget.model.imageDataList.length; i++) {
        allImage.add(widget.model.imageDataList[i].other_image);
      }
    }

    if (widget.model.contentValue != "" || widget.model.contentValue != null) {
      if (widget.model.contentType == "video_upload") {
        flickManager = FlickManager(
            videoPlayerController:
                VideoPlayerController.network(widget.model.contentValue),
            autoPlay: false);
      } else if (widget.model.contentType == "video_youtube") {
        _yc = YoutubePlayerController(
          initialVideoId:
              YoutubePlayer.convertUrlToId(widget.model.contentValue),
          flags: YoutubePlayerFlags(
            autoPlay: false,
          ),
        );
      } else if (widget.model.contentType == "video_other") {
        flickManager1 = FlickManager(
            videoPlayerController:
                VideoPlayerController.network(widget.model.contentValue),
            autoPlay: false);
      }
    }

    super.initState();
  }

  @override
  void dispose() {
    if (widget.model.contentType == "video_upload") {
      flickManager.dispose();
    } else if (widget.model.contentType == "video_youtube") {
      _yc.dispose();
    } else if (widget.model.contentType == "video_other") {
      flickManager1.dispose();
    }
    _flutterTts.stop();
    super.dispose();
  }

  /*
  initializeTts() {
    _flutterTts = FlutterTts();

    _flutterTts.setStartHandler(() {
      setState(() {
        isPlaying = true;
      });
    });

    _flutterTts.setCompletionHandler(() {
      setState(() {
        isPlaying = false;
      });
    });

    _flutterTts.setErrorHandler((err) {
      setState(() {
        print("error occurred: " + err);
        isPlaying = false;
      });
    });
  }
  */

  //get prefrences
  getUserDetails() async {
    CUR_USERID = await getPrefrence(ID);
    CUR_USERNAME = await getPrefrence(NAME);
    CUR_USEREMAIL = await getPrefrence(EMAIL);
    profile = await getPrefrence(PROFILE);
    setState(() {});
  }

  //get comment list using api
  Future<void> _getComment() async {
    if (comments_mode == "1") {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          var param = {
            ACCESS_KEY: access_key,
            NEWS_ID: widget.model.id,
            LIMIT: perPage.toString(),
            OFFSET: offset.toString()
          };
          Response response = await post(Uri.parse(getCommnetByNewsApi),
                  body: param, headers: headers)
              .timeout(Duration(seconds: timeOut));

          var getdata = json.decode(response.body);

          comTotal = getdata["total"];

          String error = getdata["error"];
          if (error == "false") {
            total = int.parse(getdata["total"]);

            if ((offset) < total) {
              var data = getdata["data"];
              commentList = (data as List)
                  .map((data) => new News.fromJson(data))
                  .toList();
              offset = offset + perPage;
            }

            if (mounted)
              setState(() {
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

  //set bookmark of news using api
  _setBookmark(String status) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      var param = {
        ACCESS_KEY: access_key,
        USER_ID: CUR_USERID,
        NEWS_ID: widget.id,
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

          setState(() {
            _isBookmark = false;
          });
          widget.updateParent(false, 1, "0");
        } else {
          setSnackbar(msg);
          setState(() {
            _isBookmark = true;
          });
          widget.updateParent(false, 1, "0");
        }
      }
    } else {
      setSnackbar(getTranslated(context, 'internetmsg'));
    }
  }

  //get bookmark news list using api
  _getBookmark() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      if (CUR_USERID != null && CUR_USERID != "") {
        try {
          var param = {
            ACCESS_KEY: access_key,
            USER_ID: CUR_USERID,
          };
          Response response = await post(Uri.parse(getBookmarkApi),
                  body: param, headers: headers)
              .timeout(Duration(seconds: timeOut));

          var getdata = json.decode(response.body);

          String error = getdata["error"];
          if (error == "false") {
            var data = getdata["data"];
            bookmarkList.clear();
            bookmarkList =
                (data as List).map((data) => new News.fromJson(data)).toList();

            for (int i = 0; i < bookmarkList.length; i++) {
              if (bookmarkList[i].newsId == (widget.id)) {
                setState(() {
                  _isBookmark = true;
                });
              }
            }
            if (mounted)
              setState(() {
                _isLoading = false;
              });
          }
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg'));
        }
      }
    } else {
      setSnackbar(getTranslated(context, 'internetmsg'));
    }
  }

  setDeleteComment(String id, int index) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      var param = {
        ACCESS_KEY: access_key,
        USER_ID: CUR_USERID,
        COMMENT_ID: id,
      };
      Response response = await post(Uri.parse(setCommentDeleteApi),
              body: param, headers: headers)
          .timeout(Duration(seconds: timeOut));

      var getdata = json.decode(response.body);
      String error = getdata["error"];

      String msg = getdata["message"];
      if (error == "false") {
        setState(() {
          commentList = List.from(commentList)..removeAt(index);
          comTotal = (int.parse(comTotal) - 1).toString();
        });

        setSnackbar(getTranslated(context, 'com_del_succ'));
      } else {
        setSnackbar(msg);
      }
    } else {
      setSnackbar(getTranslated(context, 'internetmsg'));
    }
  }

  //set comment by user using api
  Future<void> _setComment(String message) async {
    if (comments_mode == "1") {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        var param = {
          ACCESS_KEY: access_key,
          USER_ID: CUR_USERID,
          NEWS_ID: widget.id,
          MESSAGE: message,
        };
        Response response =
            await post(Uri.parse(setCommentApi), body: param, headers: headers)
                .timeout(Duration(seconds: timeOut));

        var getdata = json.decode(response.body);

        String error = getdata["error"];

        String msg = getdata["message"];

        comTotal = getdata["total"];

        if (error == "false") {
          setSnackbar(msg);
          var data = getdata["data"];

          setState(() {
            commentList =
                (data as List).map((data) => new News.fromJson(data)).toList();
          });
          comBtnEnabled = false;
          _commentC.text = "";
        } else {
          setSnackbar(msg);
        }
      } else {
        setSnackbar(getTranslated(context, 'internetmsg'));
      }
    }
  }

  //set comment by user using api
  Future<void> _setFlag(String message, String com_id) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      var param = {
        ACCESS_KEY: access_key,
        USER_ID: CUR_USERID,
        NEWS_ID: widget.id,
        MESSAGE: message,
        COMMENT_ID: com_id
      };
      Response response =
          await post(Uri.parse(setFlagApi), body: param, headers: headers)
              .timeout(Duration(seconds: timeOut));

      var getdata = json.decode(response.body);

      String error = getdata["error"];

      String msg = getdata["message"];
      if (error == "false") {
        setSnackbar(getTranslated(context, 'report_success'));
        reportC.text = "";
        setState(() {});
      } else {
        setSnackbar(msg);
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
          widget.updateParent(true, 2, id);
          setSnackbar(getTranslated(context, 'like_succ'));
        } else if (status == "2") {
          widget.updateParent(false, 2, id);
          setSnackbar(getTranslated(context, 'dislike_succ'));
        }
        if (this.mounted)
          setState(() {
            _isLoading = false;
          });
      }
    } else {
      setSnackbar(getTranslated(context, 'internetmsg'));
    }
  }

  //set not comment of news text
  Widget getNoItem() {
    return Text(
      getTranslated(context, 'com_nt_avail'),
      textAlign: TextAlign.center,
    );
  }

  //create dynamic link which can used to specif news share
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

    Share.share(
      shortenedLink.shortUrl.toString(),
      subject: str,
    );
  }

  //set snackbar msg
  setSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
      content: new Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.fontColor),
      ),
      backgroundColor: Colors.white,
      elevation: 1.0,
    ));
  }

  //news video link set
  viewVideo() {
    return widget.model.contentType == "video_upload"
        ? Container(child: FlickVideoPlayer(flickManager: flickManager))
        : widget.model.contentType == "video_youtube"
            ? YoutubePlayerBuilder(
                onExitFullScreen: () {
                  setState(() {
                    _isYouTubeVideo = false;
                  });
                },
                onEnterFullScreen: () {
                  setState(() {
                    _isYouTubeVideo = true;
                  });
                  // The player forces portraitUp after exiting fullscreen. This overrides the behaviour.
                  SystemChrome.setPreferredOrientations(
                      DeviceOrientation.values);
                },
                player: YoutubePlayer(
                  controller: _yc,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: colors.primary,
                ),
                builder: (context, player) {
                  return Column(
                    children: [
                      player,
                    ],
                  );
                })
            : widget.model.contentType == "video_other"
                ? Container(
                    child: FlickVideoPlayer(flickManager: flickManager1))
                : Container();
  }

  //news comment shown
  commentView() {
    return comments_mode == "1"
        ? CUR_USERID != null || CUR_USERID != "" || commentList.length == 0
            ? SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(-1, 0),
                  end: Offset.zero,
                ).animate(animationController1),
                child: FadeTransition(
                    opacity: animationController1,
                    child: Padding(
                        padding:
                            EdgeInsets.only(top: 30.0, left: 10.0, right: 10.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            comTotal != null && comTotal != 0
                                ? Text(
                                    "${getTranslated(context, 'view_all_lbl')}\t$comTotal\t${getTranslated(context, 'comments_lbl')}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle1
                                        .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .fontColor
                                                .withOpacity(0.8)),
                                  )
                                : Text(
                                    getTranslated(context, 'befirst_comment'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle1
                                        .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .fontColor
                                                .withOpacity(0.8)),
                                  ),
                            CUR_USERID != null || CUR_USERID != ""
                                ? Row(
                                    children: [
                                      Expanded(
                                          flex: 1,
                                          child: profile != null &&
                                                  profile != ""
                                              ? Container(
                                                  height: 30,
                                                  width: 35,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              100.0),
                                                      child: CircleAvatar(
                                                        backgroundImage:
                                                            NetworkImage(
                                                                profile),
                                                        radius: 32,
                                                      )))
                                              : Container(
                                                  height: 35,
                                                  width: 35,
                                                  child: Icon(
                                                    Icons.account_circle,
                                                    color: colors.backColor,
                                                    size: 35,
                                                  ),
                                                )),
                                      Expanded(
                                          flex: 9,
                                          child: Padding(
                                              padding:
                                                  EdgeInsetsDirectional.only(
                                                      start: 5.0),
                                              child: TextField(
                                                controller: _commentC,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .subtitle2,
                                                onChanged: (String val) {
                                                  if (_commentC.text
                                                      .trim()
                                                      .isNotEmpty) {
                                                    setState(() {
                                                      comBtnEnabled = true;
                                                    });
                                                  } else {
                                                    setState(() {
                                                      comBtnEnabled = false;
                                                    });
                                                  }
                                                },
                                                keyboardType:
                                                    TextInputType.multiline,
                                                maxLines: null,
                                                decoration: InputDecoration(
                                                    contentPadding:
                                                        EdgeInsets.only(
                                                            top: 10.0,
                                                            bottom: 2.0),
                                                    isDense: true,
                                                    suffixIconConstraints:
                                                        BoxConstraints(
                                                      maxHeight: 35,
                                                      maxWidth: 30,
                                                    ),
                                                    hintText: getTranslated(
                                                        context, 'review_lbl'),
                                                    hintStyle: Theme.of(context)
                                                        .textTheme
                                                        .subtitle2
                                                        .copyWith(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .fontColor
                                                                .withOpacity(
                                                                    0.8)),
                                                    suffixIcon: IconButton(
                                                      icon: Icon(
                                                        Icons.send,
                                                        color: comBtnEnabled
                                                            ? Theme.of(context)
                                                                .colorScheme
                                                                .fontColor
                                                                .withOpacity(
                                                                    0.8)
                                                            : Colors
                                                                .transparent,
                                                        size: 20.0,
                                                      ),
                                                      onPressed: () async {
                                                        if (CUR_USERID !=
                                                                null &&
                                                            CUR_USERID != "") {
                                                          setState(() {
                                                            _setComment(
                                                                _commentC.text);
                                                            FocusScopeNode
                                                                currentFocus =
                                                                FocusScope.of(
                                                                    context);

                                                            if (!currentFocus
                                                                .hasPrimaryFocus) {
                                                              currentFocus
                                                                  .unfocus();
                                                            }
                                                          });
                                                        } else {
                                                          setSnackbar(getTranslated(
                                                              context,
                                                              'login_req_msg'));
                                                        }
                                                      },
                                                    )),
                                              )))
                                    ],
                                  )
                                : Container(),
                            SingleChildScrollView(
                                child: ListView.separated(
                                    separatorBuilder:
                                        (BuildContext context, int index) =>
                                            Divider(color: Theme.of(context).colorScheme.fontColor.withOpacity(0.5),),
                                    shrinkWrap: true,
                                    padding: EdgeInsets.only(top: 20.0),
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: commentList.length,
                                    itemBuilder: (context, index) {
                                      DateTime time1 = DateTime.parse(
                                          commentList[index].date);

                                      return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            commentList[index].profile !=
                                                        null ||
                                                    commentList[index]
                                                            .profile !=
                                                        ""
                                                ? Container(
                                                    height: 30,
                                                    width: 35,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                    100.0),
                                                        child: CircleAvatar(
                                                          backgroundImage:
                                                              NetworkImage(
                                                                  commentList[
                                                                          index]
                                                                      .profile),
                                                          radius: 32,
                                                        )))
                                                : Container(
                                                    height: 35,
                                                    width: 35,
                                                    child: Icon(
                                                      Icons.account_circle,
                                                      color: colors.backColor,
                                                      size: 35,
                                                    ),
                                                  ),
                                            Expanded(
                                                child: Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .only(start: 5.0),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Text(
                                                                commentList[
                                                                        index]
                                                                    .name,
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .bodyText2
                                                                    .copyWith(
                                                                        color: Theme.of(context)
                                                                            .colorScheme
                                                                            .fontColor,fontSize: 13)),
                                                            Padding(
                                                                padding: EdgeInsetsDirectional
                                                                    .only(
                                                                        start:
                                                                            10.0),
                                                                child: Text(
                                                                  convertToAgo(
                                                                      time1, 1),
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .caption
                                                                      .copyWith(
                                                                          color: Theme.of(context)
                                                                              .colorScheme
                                                                              .fontColor
                                                                              .withOpacity(0.5),fontSize: 10),
                                                                )),
                                                          ],
                                                        ),
                                                        Row(
                                                          children: <Widget>[
                                                            Expanded(
                                                                child: Text(
                                                              commentList[index]
                                                                  .message,
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .subtitle2
                                                                  .copyWith(
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .fontColor
                                                                          .withOpacity(
                                                                              0.7),
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .normal),
                                                            )),
                                                            CUR_USERID !=
                                                                        null &&
                                                                    CUR_USERID !=
                                                                        ""
                                                                ? InkWell(
                                                                    child: Icon(
                                                                      Icons
                                                                          .more_vert_outlined,
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .fontColor
                                                                          .withOpacity(
                                                                              0.7),
                                                                      size: 23,
                                                                    ),
                                                                    onTap: () {
                                                                      delAndReportCom(
                                                                          commentList[index]
                                                                              .id,
                                                                          index);
                                                                    },
                                                                  )
                                                                : Container()
                                                          ],
                                                        )
                                                      ],
                                                    ))),
                                          ]);
                                    }))
                          ],
                        ))))
            : getNoItem()
        : getNoItem();
  }

  delAndReportCom(String com_id, int index) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
              contentPadding: const EdgeInsets.all(20),
              elevation: 2.0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15.0))),
              content: SingleChildScrollView(
                  //padding: EdgeInsets.all(15.0),
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CUR_USERID == commentList[index].userId
                      ? Row(
                          children: <Widget>[
                            Text(
                              getTranslated(context, 'delete_txt'),
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor
                                          .withOpacity(0.9),
                                      fontWeight: FontWeight.bold),
                            ),
                            Spacer(),
                            InkWell(
                              child: Image.asset(
                                "assets/images/delete_icon.png",
                                color: Theme.of(context).colorScheme.fontColor2,
                                height: 20,
                                width: 20,
                              ),
                              onTap: () async {
                                setDeleteComment(com_id, index);
                                await Navigator.pop(context);
                              },
                            ),
                          ],
                        )
                      : Container(),
                  CUR_USERID != commentList[index].userId
                      ? Padding(
                          padding: EdgeInsets.only(top: 15),
                          child: Row(
                            children: <Widget>[
                              Text(
                                getTranslated(context, 'report_txt'),
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle1
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor
                                            .withOpacity(0.9),
                                        fontWeight: FontWeight.bold),
                              ),
                              Spacer(),
                              Image.asset(
                                "assets/images/flag_icon.png",
                                color: Theme.of(context).colorScheme.fontColor2,
                                height: 20,
                                width: 20,
                              ),
                            ],
                          ))
                      : Container(),
                  CUR_USERID != commentList[index].userId
                      ? Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: TextField(
                            controller: reportC,
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            style: Theme.of(context).textTheme.caption.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .fontColor
                                      .withOpacity(0.7),
                                ),
                            decoration: new InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .fontColor2
                                        .withOpacity(0.7),
                                    width: 0.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .fontColor2
                                        .withOpacity(0.7),
                                    width: 0.5),
                              ),
                            ),
                          ))
                      : Container(),
                  CUR_USERID != commentList[index].userId
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  getTranslated(context, 'cancel_btn'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1
                                      .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .fontColor
                                              .withOpacity(0.9),
                                          fontWeight: FontWeight.bold),
                                )),
                            TextButton(
                                onPressed: () {
                                  if (reportC.text.trim().isNotEmpty) {
                                    _setFlag(reportC.text, com_id);
                                    Navigator.pop(context);
                                  } else {
                                    setSnackbar(getTranslated(
                                        context, 'first_fill_data'));
                                  }
                                },
                                child: Text(
                                  getTranslated(context, 'submit_btn'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1
                                      .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .fontColor
                                              .withOpacity(0.9),
                                          fontWeight: FontWeight.bold),
                                )),
                          ],
                        )
                      : Container()
                ],
              )));
        });
  }

  //set back btn press
  Future<bool> onWillPop() {
    if (!_isDetails) {
      animationController1.dispose();
      setState(() {
        _isDetails = true;
        _isFirstTime = false;
      });
      animationController = AnimationController(
          vsync: this, duration: Duration(milliseconds: 150));
      Timer(Duration(milliseconds: 200), () => animationController.forward());
    } else {
      Navigator.pop(context, true);
    }
  }

  Future _speak(String text) async {
    if (text != null && text.isNotEmpty) {
      var result = await _flutterTts.speak(text);
      if (result == 1)
        setState(() {
          isPlaying = true;
        });
    }
  }

  Future _stop() async {
    var result = await _flutterTts.stop();
    if (result == 1)
      setState(() {
        isPlaying = false;
      });
  }

  Future _pause() async {
    var result = await _flutterTts.pause();
    if (result == 1)
      setState(() {
        isPlaying = false;
      });
  }

  void setTtsLanguage() async {
    await _flutterTts.setLanguage("en-US");
  }

  List<T> map<T>(List list, Function handler) {
    List<T> result = [];
    for (var i = 0; i < list.length; i++) {
      result.add(handler(i, list[i]));
    }

    return result;
  }

  changeSize() async {
    _fontValue = int.parse(await getPrefrence(font_value));
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    changeSize();
    return WillPopScope(
        onWillPop: onWillPop,
        child: Scaffold(
            key: _scaffoldKey1,
            backgroundColor: Theme.of(context).colorScheme.white,
            body: Column(mainAxisSize: MainAxisSize.min, children: [
              Expanded(
                  child: SingleChildScrollView(
                      child: Stack(children: <Widget>[
                !_isYouTubeVideo
                    ? Hero(
                        tag: "${widget.index}${widget.model.id}",
                        child: Container(
                            height: height * 0.391,
                            width: double.infinity,
                            child: PageView.builder(
                              itemCount: allImage.length,
                              controller: _pageController,
                              onPageChanged: (index) {
                                setState(() {
                                  _curSlider = index;
                                });
                              },
                                itemBuilder: (BuildContext context, int index) {
                                  return InkWell(
                                      child: ShaderMask(
                                        shaderCallback: (rect) {
                                          return LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black
                                            ],
                                          ).createShader(rect);
                                        },
                                        blendMode: BlendMode.darken,
                                        child: FadeInImage(
                                            fadeInDuration:
                                            Duration(milliseconds: 150),
                                            image: NetworkImage(allImage[index]),
                                            fit: BoxFit.fill,
                                            height: height * 0.391,
                                            width: double.infinity,
                                            placeholder: placeHolder(),
                                            imageErrorBuilder:
                                                (context, error, stackTrace) {
                                              return Image.file(
                                                File(allImage[index]),
                                                height: height * 0.391,
                                                width: double.infinity,
                                                fit: BoxFit.fill,
                                              );
                                            }),
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              pageBuilder: (_, __, ___) =>
                                                  ImagePreview(
                                                      index: index,
                                                      imgList: allImage,
                                                      isNetworkAvail:
                                                      _isNetworkAvail),
                                            ));
                                      });
                                },
                            )))
                    : Container(),
                !_isYouTubeVideo
                    ? Positioned.directional(
                        textDirection: Directionality.of(context),
                        top: 30.0,
                        start: 0.0,
                        child: InkWell(
                          child: Image.asset(
                            "assets/images/back_icon.png",
                          ),
                          onTap: () {
                            if (!_isDetails) {
                              animationController1.dispose();
                              setState(() {
                                _isDetails = true;
                                _isFirstTime = false;
                              });
                              animationController = AnimationController(
                                  vsync: this,
                                  duration: Duration(milliseconds: 150));
                              Timer(Duration(milliseconds: 200),
                                  () => animationController.forward());
                            } else {
                              Navigator.pop(context, true);
                            }
                          },
                        ))
                    : Container(),

                //set ytVideo
                !_isYouTubeVideo
                    ? widget.model.contentType == "video_upload" ||
                            widget.model.contentType == "video_youtube" ||
                            widget.model.contentType == "video_other"
                        ? Positioned.directional(
                            textDirection: Directionality.of(context),
                            start: 175.0,
                            top: 100.0,
                            width: 50.0,
                            height: 75.0,
                            child: InkWell(
                              child: Image.asset(
                                "assets/images/watchvideo_icon.png",
                                width: 100.0,
                              ),
                              onTap: () async {
                                _isNetworkAvail = await isNetworkAvailable();
                                if (_isNetworkAvail) {
                                  setState(() {
                                    _isVideoAvail = !_isVideoAvail;
                                  });
                                } else {
                                  setSnackbar(
                                      getTranslated(context, 'internetmsg'));
                                }
                              },
                            ))
                        : Container()
                    : Container(),
                !_isYouTubeVideo
                    ? Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                            margin: EdgeInsets.only(
                                top: widget.model.imageDataList.length != 0
                                    ? (height / 2.6) - 128
                                    : (height / 2.6) - 108,
                                left: 30,
                                right: 30.0),
                            child: Column(children: [
                              Text(
                                widget.model.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle1
                                    .copyWith(
                                        color: colors.tempWhite,
                                        //fontWeight: FontWeight.bold,
                                        height: 1.1),
                                textScaleFactor: 1.1,
                                textAlign: TextAlign.start,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              !_isYouTubeVideo
                                  ? widget.model.imageDataList.length != 0
                                      ? Padding(
                                          padding: EdgeInsets.only(top: 5.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: map<Widget>(
                                              allImage,
                                              (index, url) {
                                                return Container(
                                                    width: _curSlider == index
                                                        ? 10.0
                                                        : 8.0,
                                                    height: _curSlider == index
                                                        ? 10.0
                                                        : 8.0,
                                                    margin:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 1.0),
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: _curSlider == index
                                                          ? colors.tempWhite
                                                          : colors.tempWhite
                                                              .withOpacity(
                                                                  (0.5)),
                                                    ));
                                              },
                                            ),
                                          ))
                                      : Container()
                                  : Container()
                            ])))
                    : Container(),
                Padding(
                    padding: EdgeInsets.only(
                        top: !_isYouTubeVideo ? height / 3.1 : 0),
                    child: Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 400),
                          //height: height / 1.8,
                          width: width,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(5),
                              topRight: Radius.circular(5),
                            ),
                          ),
                          child: _isDetails
                              ? !_isFirstTime
                                  ? SlideTransition(
                                      position: Tween<Offset>(
                                        begin: Offset(-1, 0),
                                        end: Offset.zero,
                                      ).animate(animationController),
                                      child: FadeTransition(
                                          opacity: animationController,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _isVideoAvail
                                                  ? Padding(
                                                      padding: EdgeInsets.only(
                                                          left: 15.0,
                                                          right: 15.0,
                                                          top: 30),
                                                      child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      10.0),
                                                          child: viewVideo()))
                                                  : Container(),
                                              !_isYouTubeVideo
                                                  ? Padding(
                                                      padding: EdgeInsets.only(
                                                          left: 15.0,
                                                          right: 15.0,
                                                          top: _isVideoAvail
                                                              ? 7.0
                                                              : 20.0),
                                                      child: Html(
                                                        data: widget.model.desc,
                                                        useRichText: true,
                                                        customTextAlign: (_) =>
                                                            TextAlign.start,
                                                        customTextStyle: (_,
                                                            TextStyle
                                                                baseStyle) {
                                                          return baseStyle.merge(Theme
                                                                  .of(context)
                                                              .textTheme
                                                              .subtitle2
                                                              .copyWith(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .fontColor,
                                                                  fontSize:
                                                                      _fontValue
                                                                          .toDouble()));
                                                        },
                                                        onLinkTap:
                                                            (String url) async {
                                                          if (await canLaunch(
                                                              url)) {
                                                            await launch(
                                                              url,
                                                              forceSafariVC:
                                                                  false,
                                                              forceWebView:
                                                                  false,
                                                            );
                                                          } else {
                                                            throw 'Could not launch $url';
                                                          }
                                                        },
                                                      ))
                                                  : Container()
                                            ],
                                          )))
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _isVideoAvail
                                            ? Padding(
                                                padding: EdgeInsets.only(
                                                    left: 15.0,
                                                    right: 15.0,
                                                    top: 30),
                                                child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10.0),
                                                    child: viewVideo()))
                                            : Container(),
                                        !_isYouTubeVideo
                                            ? Padding(
                                                padding: EdgeInsets.only(
                                                    left: 15.0,
                                                    right: 15.0,
                                                    top: _isVideoAvail
                                                        ? 7.0
                                                        : 20.0),
                                                child: Html(
                                                  data: widget.model.desc,
                                                  useRichText: true,
                                                  customTextAlign: (_) =>
                                                      TextAlign.start,
                                                  customTextStyle:
                                                      (dom.Node node,
                                                          TextStyle baseStyle) {
                                                    return baseStyle.merge(Theme
                                                            .of(context)
                                                        .textTheme
                                                        .subtitle2
                                                        .copyWith(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .fontColor,
                                                            fontSize: _fontValue
                                                                .toDouble()));
                                                  },
                                                  onLinkTap:
                                                      (String url) async {
                                                    if (await canLaunch(url)) {
                                                      await launch(
                                                        url,
                                                        forceSafariVC: false,
                                                        forceWebView: false,
                                                      );
                                                    } else {
                                                      throw 'Could not launch $url';
                                                    }
                                                  },
                                                ))
                                            : Container()
                                      ],
                                    )
                              : commentView(),
                        )))
              ]))),
              _isDetails
                  ? !_isYouTubeVideo
                      ? Align(
                          alignment: FractionalOffset.bottomCenter,
                          child: Padding(
                              padding: EdgeInsets.all(2.0),
                              child: Container(
                                  height: 55,
                                  padding:
                                      EdgeInsets.only(right: 20.0, left: 20.0),
                                  width: double.maxFinite,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50.0),
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor
                                          .withOpacity(0.08)),
                                  child: Row(
                                    children: <Widget>[
                                      InkWell(
                                        child: widget.model.like == "1"
                                            ? Image.asset(
                                                "assets/images/liked_icon.png",
                                                height: 25.0,
                                                width: 25.0,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .fontColor,
                                              )
                                            : Image.asset(
                                                "assets/images/unlike_icon.png",
                                                height: 25.0,
                                                width: 25.0,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .fontColor,
                                              ),
                                        onTap: () async {
                                          if (CUR_USERID != null &&
                                              CUR_USERID != "") {
                                            _isNetworkAvail =
                                                await isNetworkAvailable();
                                            if (_isNetworkAvail) {
                                              if (widget.model.like == "1") {
                                                _setLikesDisLikes(
                                                    "2", widget.id);
                                                widget.model.like = "0";
                                                setState(() {});
                                              } else {
                                                _setLikesDisLikes(
                                                    "1", widget.id);
                                                widget.model.like = "1";
                                                setState(() {});
                                              }
                                            } else {
                                              setSnackbar(getTranslated(
                                                  context, 'internetmsg'));
                                            }
                                          } else {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => Login(),
                                                ));
                                          }
                                        },
                                      ),
                                      Spacer(),
                                      InkWell(
                                        child: Image.asset(
                                          "assets/images/textsize_icon.png",
                                          height: 25.0,
                                          width: 25.0,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .fontColor,
                                        ),
                                        onTap: () {
                                          changeFontSizeSheet();
                                          //demo();
                                          //changeFontSize();
                                        },
                                      ),
                                      SizedBox(width: 10,),
                                      Padding(
                                          padding: EdgeInsetsDirectional.only(
                                              start: 15.0),
                                          child: InkWell(
                                            child: Image.asset(
                                              "assets/images/comment_icon.png",
                                              height: 25.0,
                                              width: 25.0,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .fontColor,
                                            ),
                                            onTap: () {
                                              animationController1 =
                                                  AnimationController(
                                                      vsync: this,
                                                      duration: Duration(
                                                          milliseconds: 150));
                                              Timer(
                                                  Duration(milliseconds: 200),
                                                  () => animationController1
                                                      .forward());
                                              setState(() {
                                                _isDetails = false;
                                              });
                                            },
                                          )),

                                      // Padding(
                                      //     padding: EdgeInsetsDirectional.only(
                                      //         start: 30.0),
                                           Expanded(child: Container()),
                                          InkWell(
                                            child: Image.asset(
                                              "assets/images/share_icon.png",
                                              height: 25.0,
                                              width: 25.0,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .fontColor,
                                            ),
                                            onTap: () async {
                                              _isNetworkAvail =
                                                  await isNetworkAvailable();
                                              if (_isNetworkAvail) {
                                                createDynamicLink(
                                                  widget.model.id,
                                                  widget.index,
                                                  widget.model.title,
                                                );
                                              } else {
                                                setSnackbar(getTranslated(
                                                    context, 'internetmsg'));
                                              }
                                            },
                                          ),
                                      // Spacer(),
                                      // InkWell(
                                      //   child: Image.asset(
                                      //     "assets/images/textsize_icon.png",
                                      //     height: 25.0,
                                      //     width: 25.0,
                                      //     color: Theme.of(context)
                                      //         .colorScheme
                                      //         .fontColor,
                                      //   ),
                                      //   onTap: () {
                                      //     changeFontSizeSheet();
                                      //     //demo();
                                      //     //changeFontSize();
                                      //   },
                                      // ),
                                      // Padding(
                                      //     padding: EdgeInsetsDirectional.only(
                                      //         start: 15.0),
                                      //     child: InkWell(
                                      //         child: isPlaying
                                      //             ? Image.asset(
                                      //                 "assets/images/audio_icon.png",
                                      //                 height: 25.0,
                                      //                 width: 25.0,
                                      //                 color: Colors.blueAccent,
                                      //               )
                                      //             : Image.asset(
                                      //                 "assets/images/audio_icon.png",
                                      //                 height: 25.0,
                                      //                 width: 25.0,
                                      //                 color: Theme.of(context)
                                      //                     .colorScheme
                                      //                     .fontColor,
                                      //               ),
                                      //         onTap: () {
                                      //           if (isPlaying) {
                                      //             _stop();
                                      //           } else {
                                      //             final document =
                                      //                 parse(widget.model.desc);
                                      //             String parsedString =
                                      //                 parse(document.body.text)
                                      //                     .documentElement
                                      //                     .text;
                                      //
                                      //             _speak(parsedString);
                                      //           }
                                      //         })),
                                      // Padding(
                                      //     padding: EdgeInsetsDirectional.only(
                                      //         start: 15.0),
                                      //     child: InkWell(
                                      //       child: _isBookmark
                                      //           ? Image.asset(
                                      //               "assets/images/bookmark_icon.png",
                                      //               height: 25.0,
                                      //               width: 25.0,
                                      //               color: Theme.of(context)
                                      //                   .colorScheme
                                      //                   .fontColor,
                                      //             )
                                      //           : Image.asset(
                                      //               "assets/images/uncheckbookmark_icon.png",
                                      //               height: 25.0,
                                      //               width: 25.0,
                                      //               color: Theme.of(context)
                                      //                   .colorScheme
                                      //                   .fontColor,
                                      //             ),
                                      //       onTap: () async {
                                      //         if (CUR_USERID != null) {
                                      //           _isNetworkAvail =
                                      //               await isNetworkAvailable();
                                      //           if (_isNetworkAvail) {
                                      //             _isBookmark
                                      //                 ? _setBookmark("0")
                                      //                 : _setBookmark("1");
                                      //           } else {
                                      //             setSnackbar(getTranslated(
                                      //                 context, 'internetmsg'));
                                      //           }
                                      //         } else {
                                      //           Navigator.push(
                                      //               context,
                                      //               MaterialPageRoute(
                                      //                 builder: (context) =>
                                      //                     Login(),
                                      //               ));
                                      //         }
                                      //       },
                                      //     )),
                                    ],
                                  ))))
                      : Container()
                  : Container()
            ])));
  }

  changeFontSizeSheet() {
   showModalBottomSheet<dynamic>(
        context: context,
        elevation: 5.0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(50), topRight: Radius.circular(50))),
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (BuildContext context, setStater) {
            return Container(
                padding: EdgeInsetsDirectional.only(
                    bottom: 20.0, top: 5.0, start: 20.0, end: 20.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                        padding: EdgeInsets.only(top: 30.0, bottom: 30.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Image.asset(
                              "assets/images/textsize_icon.png",
                              height: 23.0,
                              width: 23.0,
                            ),
                            Padding(
                                padding:
                                    EdgeInsetsDirectional.only(start: 15.0),
                                child: Text(
                                  getTranslated(context, 'text_size'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headline6
                                      .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .fontColor),
                                )),
                          ],
                        )),
                    SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.red[700],
                          inactiveTrackColor: Colors.red[100],
                          trackShape: RoundedRectSliderTrackShape(),
                          trackHeight: 4.0,
                          thumbShape:
                              RoundSliderThumbShape(enabledThumbRadius: 12.0),
                          thumbColor: Colors.redAccent,
                          overlayColor: Colors.red.withAlpha(32),
                          overlayShape:
                              RoundSliderOverlayShape(overlayRadius: 28.0),
                          tickMarkShape: RoundSliderTickMarkShape(),
                          activeTickMarkColor: Colors.red[700],
                          inactiveTickMarkColor: Colors.red[100],
                          valueIndicatorShape:
                              PaddleSliderValueIndicatorShape(),
                          valueIndicatorColor: Colors.redAccent,
                          valueIndicatorTextStyle: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        child: Slider(
                          label: '${_fontValue}',
                          value: _fontValue.toDouble(),
                          activeColor: colors.primary,
                          min: 18,
                          max: 40,
                          divisions: 10,
                          onChanged: (value) {
                            setStater(() {
                              setState(() {
                                _fontValue = value.round();
                                setPrefrence(font_value, _fontValue.toString());
                              });
                            });
                          },
                        )),
                  ],
                ));
          });
        });
  }


}
