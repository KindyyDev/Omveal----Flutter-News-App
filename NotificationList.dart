import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart' as intl;
import 'package:news/Helper/Constant.dart';
import 'package:news/Helper/Session.dart';
import 'package:news/Helper/Color.dart';
import 'Helper/String.dart';
import 'Model/News.dart';

class NotificationList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => StateNoti();
}

List<News> notiList = [];
int offset = 0;
int total = 0;
bool isLoadingmore = true;
bool _isLoading = true;

class StateNoti extends State<NotificationList> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  ScrollController controller = new ScrollController();
  List<News> tempList = [];
  bool _isNetworkAvail = true;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    getNotification();
    controller.addListener(_scrollListener);

    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  //refresh function used in refresh notification
  Future<String> _refresh() async {
    setState(() {
      _isLoading = true;
    });
    offset = 0;
    total = 0;
    notiList.clear();
    return getNotification();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        body: _isLoading
            ? shimmer(context)
            : notiList.length == 0
                ? Padding(
                    padding:
                        const EdgeInsetsDirectional.only(top: kToolbarHeight),
                    child: Center(child: Text(getTranslated(context,'noti_nt_avail'))))
                : RefreshIndicator(
                    key: _refreshIndicatorKey,
                    onRefresh: _refresh,
                    child: Padding(
                        padding: EdgeInsetsDirectional.only(
                            start: 15.0, end: 15.0, top: 10.0, bottom: 10.0),
                        child: ListView.builder(
                          controller: controller,
                          itemCount: notiList.length,
                          physics: AlwaysScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            return (index == notiList.length && isLoadingmore)
                                ? shimmer(context)
                                : listItem(index);
                          },
                        ))));
  }

  //list of notification shown
  Widget listItem(int index) {
    News model = notiList[index];

    DateTime time1 = DateTime.parse(
        model.date_sent);


    return Hero(
        tag: model.id,
        child: Padding(
            padding: EdgeInsetsDirectional.only(
              top: 5.0,
              bottom: 5.0,
            ),
            child: InkWell(
              child: Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.white,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .fontColor
                              .withOpacity(0.16),
                          blurRadius: 10,
                          spreadRadius: 5),
                    ],
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: EdgeInsets.all(5.0),
                  child: Row(
                    children: <Widget>[
                      model.image != null && model.image != ''
                          ? Expanded(
                              flex: 2,
                              child: Container(
                                  width: 20.0,
                                  color: Theme.of(context).colorScheme.white,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5.0),
                                    child: new FadeInImage(
                                        fadeInDuration:
                                            Duration(milliseconds: 150),
                                        image: NetworkImage(
                                          model.image,
                                        ),
                                        height: 80.0,
                                        fit: BoxFit.fill,
                                        placeholder: placeHolder(),
                                        imageErrorBuilder:
                                            (context, error, stackTrace) {
                                          return errorWidget(80);
                                        }),
                                  )))
                          : Container(
                              height: 0,
                            ),
                      Expanded(
                          flex: 5,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(
                                start: 8.0, end: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(model.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle1
                                        .copyWith(
                                            fontWeight: FontWeight.bold,
                                            height: 1.1)),
                                Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                        top: 3.0),
                                    child: Text(model.message,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle2
                                            .copyWith(
                                                fontWeight: FontWeight.normal,
                                                color: Colors.grey,
                                                height: 0.95))),
                                Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                        top: 2.0),
                                    child: Text(convertToAgo(time1, 2),
                                        style: Theme.of(context)
                                            .textTheme
                                            .caption
                                            .copyWith(
                                                fontWeight: FontWeight.normal,
                                                color: Colors.grey,
                                                fontSize: 10)))
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              onTap: () {
                News model = notiList[index];
                detailsBottomSheet(model, index);
              },
            )));
  }

  //get notification using api
  Future<Null> getNotification() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      var parameter = {
        LIMIT: perPage.toString(),
        OFFSET: offset.toString(),
        ACCESS_KEY: access_key
      };

      Response response = await post(Uri.parse(getNotificationApi),
              headers: headers, body: parameter)
          .timeout(Duration(seconds: timeOut));
      var getdata = json.decode(response.body);
      String error = getdata["error"];

      if (error == "false") {
        total = int.parse(getdata["total"]);

        if ((offset) < total) {
          tempList.clear();
          notiList.clear();
          var data = getdata["data"];
          tempList =
              (data as List).map((data) => new News.fromJson(data)).toList();

          notiList.addAll(tempList);

          offset = offset + perPage;
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
    } else
      setSnackbar(getTranslated(context,'internetmsg'));

    return null;
  }

  //set snackbar msg
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

  _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if (this.mounted) {
        setState(() {
          isLoadingmore = true;

          if (offset < total) getNotification();
        });
      }
    }
  }

  //show notification details bottomsheet
  detailsBottomSheet(News model, int index) {
    showModalBottomSheet<dynamic>(
        context: context,
        isScrollControlled: true,
        elevation: 3.0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30), topRight: Radius.circular(30))),
        builder: (builder) {
          return Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30)),
                  color: Theme.of(context).colorScheme.white),
              child: SingleChildScrollView(
                  padding: EdgeInsetsDirectional.only(bottom: 10.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(children: <Widget>[
                          Container(
                              child: Hero(
                                  tag: model.title,
                                  child: ClipRRect(
                                      borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(30),
                                          topRight: Radius.circular(30)),
                                      child: Image.network(
                                        model.image,
                                        fit: BoxFit.fill,
                                        height: 200,
                                        width: deviceWidth,
                                      )))),
                          Positioned.directional(
                              textDirection: Directionality.of(context),
                              top: 20.0,
                              end: 10.0,
                              child: InkWell(
                                child: Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5.0),
                                      color:
                                          Theme.of(context).colorScheme.white),
                                  child: Icon(Icons.close),
                                ),
                                onTap: () {
                                  Navigator.of(context).pop();
                                },
                              )),
                        ]),
                        Padding(
                            padding: EdgeInsetsDirectional.only(
                                top: 10, start: 10.0, end: 10.0),
                            child: Text(
                              model.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor,
                                      fontWeight: FontWeight.bold),
                            )),
                        Padding(
                            padding: EdgeInsetsDirectional.only(
                                start: 10.0, end: 10.0, top: 5.0, bottom: 5.0),
                            child: Text(model.message,
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle2
                                    .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor,
                                    ))),
                      ])));
        });
  }
}
