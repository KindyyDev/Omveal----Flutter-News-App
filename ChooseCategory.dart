import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'Helper/AppBtn.dart';
import 'Helper/Color.dart';
import 'Helper/Constant.dart';
import 'Helper/Session.dart';
import 'Helper/String.dart';
import 'Model/Category.dart';

class ChooseCategory extends StatefulWidget {
  final String title;
  final String from;

  const ChooseCategory({Key key, this.title, this.from}) : super(key: key);

  @override
  ChooseCategoryState createState() => ChooseCategoryState();
}

class ChooseCategoryState extends State<ChooseCategory>
    with TickerProviderStateMixin {
  List<Category> catList = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isNetworkAvail = true;
  bool isLoadingmore = true;
  bool _isLoading = true;
  List<String> selectedReportList = [];
  ScrollController controller = new ScrollController();
  Animation buttonSqueezeanimation;
  AnimationController buttonController;
  String selCatId = "";
  bool isChange = false;
  String catId = "";

  @override
  void initState() {
    super.initState();
    getUserDetails();
    getSetting().then((value) {
      getCat();
      getUserByCat();
    });
    buttonController = new AnimationController(
        duration: new Duration(milliseconds: 2000), vsync: this);
    buttonSqueezeanimation = new Tween(
      begin: deviceWidth * 0.36,
      end: 50.0,
    ).animate(new CurvedAnimation(
      parent: buttonController,
      curve: new Interval(
        0.0,
        0.150,
      ),
    ));
  }

  Future<Null> _playAnimation() async {
    try {
      await buttonController.forward();
    } on TickerCanceled {}
  }

  getUserDetails() async {
    CUR_USERID = await getPrefrence(ID);
    CUR_USERNAME = await getPrefrence(NAME);
    CUR_USEREMAIL = await getPrefrence(EMAIL);
    setState(() {});
  }

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
        var data = getdata["data"];
        category_mode = data["category_mode"];
        comments_mode = data["comments_mode"];
      }
      setState(() {
        _isLoading = false;
      });
    } else {
      setSnackbar(getTranslated(context,'internetmsg'));
    }
  }

  Future<void> getCat() async {
    if (category_mode == "1") {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        var param = {
          ACCESS_KEY: access_key,
        };
        Response response =
            await post(Uri.parse(getCatApi), body: param, headers: headers)
                .timeout(Duration(seconds: timeOut));
        var getdata = json.decode(response.body);

        String error = getdata["error"];

        if (error == "false") {
          catList.clear();
          var data = getdata["data"];
          catList = (data as List)
              .map((data) => new Category.fromJson(data))
              .toList();

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
      } else {
        setSnackbar(getTranslated(context,'internetmsg'));
      }
    } else {
      setState(() {
        isLoadingmore = false;
        _isLoading = false;
      });
    }
  }

  _setUserCat() async {
    if (isChange) {
      if (selectedReportList.length == 1) {
        setState(() {
          selCatId = selectedReportList.join();
        });
      } else {
        setState(() {
          selCatId = selectedReportList.join(',');
        });
      }
    } else {
      setState(() {
        selCatId = catId;
      });
    }

    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      var param = {
        ACCESS_KEY: access_key,
        USER_ID: CUR_USERID,
        CATEGORY_ID: selCatId,
      };
      Response response =
          await post(Uri.parse(setUserCatApi), body: param, headers: headers)
              .timeout(Duration(seconds: timeOut));

      var getdata = json.decode(response.body);

      String error = getdata["error"];
      String msg = getdata["message"];

      if (error == "false") {
        setSnackbar(getTranslated(context,'prefrence_save'));

        if (selCatId == "0") {
          String catId = "";
          setPrefrence(cur_catId, catId);
        } else {
          String catId = selCatId;
          setPrefrence(cur_catId, catId);
        }
        await buttonController.reverse();
        Navigator.of(context)
            .pushNamedAndRemoveUntil("/home", (Route<dynamic> route) => false);
      } else {
        setSnackbar(getTranslated(context,'prefrence_save'));

        String catId = selCatId;
        setPrefrence(cur_catId, catId);
        await buttonController.reverse();
        Navigator.of(context)
            .pushNamedAndRemoveUntil("/home", (Route<dynamic> route) => false);
      }
    } else {
      Future.delayed(Duration(seconds: 2)).then((_) async {
        await buttonController.reverse();
        setSnackbar(getTranslated(context,'internetmsg'));
      });
    }
  }

  Future<void> getUserByCat() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      var param = {
        ACCESS_KEY: access_key,
        USER_ID: CUR_USERID,
      };
      Response response = await post(Uri.parse(getUserByCatIdApi),
              body: param, headers: headers)
          .timeout(Duration(seconds: timeOut));

      var getdata = json.decode(response.body);

      String error = getdata["error"];
      if (error == "false") {
        var data = getdata["data"];

        for (int i = 0; i < data.length; i++) {
          catId = data[i]["category_id"];
        }
      }
    } else {
      setSnackbar(getTranslated(context,'internetmsg'));
    }
  }

  skipBtn() {
    return widget.from !=  getTranslated(context,'home_lbl')
        ? Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: EdgeInsetsDirectional.only(end: 13.0),
              child: Card(
                  color: Theme.of(context).colorScheme.white,
                  shadowColor:
                      Theme.of(context).colorScheme.fontColor.withOpacity(0.5),
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: InkWell(
                    child: Padding(
                        padding: EdgeInsets.all(7.0),
                        child: Text(
                          getTranslated(context,'skip_lbl'),
                          style: Theme.of(context).textTheme.subtitle2.copyWith(
                              color: Theme.of(context).colorScheme.fontColor2),
                        )),
                    onTap: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          "/home", (Route<dynamic> route) => false);
                    },
                  )),
            ))
        : Container();
  }

  selectCatText() {
    return Padding(
        padding: EdgeInsetsDirectional.only(
            top: widget.from ==  getTranslated(context,'home_lbl') ? 0.0 : 30.0),
        child: Text(
          getTranslated(context,'sel_pref_cat'),
          style: Theme.of(context)
              .textTheme
              .subtitle1
              .copyWith(color: Theme.of(context).colorScheme.fontColor2),
          textAlign: TextAlign.center,
        ));
  }

  multiSelectChipShow() {
    return _isLoading
        ? getProgress()
        : category_mode == "1"
            ? SingleChildScrollView(
                padding: EdgeInsetsDirectional.only(
                    top: widget.from == getTranslated(context,'login_lbl') ? 20.0 : 5.0,
                    start: 13.0,
                    end: 13.0,
                    bottom: 5.0),
                child: Container(
                    padding: EdgeInsetsDirectional.only(
                        top: 10.0, bottom: 10.0, start: 5.0, end: 5.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
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
                    child: MultiSelectChip(
                      catList,
                      onSelectionChanged: (selectedList) {
                        setState(() {
                          selectedReportList = selectedList;
                          isChange = true;
                        });
                      },
                    )))
            : Center(child: Text(getTranslated(context,'cat_no_avail')));
  }

  saveBtn() {
    return !_isLoading
        ? AppBtn(
            title: getTranslated(context,'save_btn'),
            btnAnim: buttonSqueezeanimation,
            btnCntrl: buttonController,
            onBtnSelected: () async {
              _playAnimation();
              setState(() {
                _isLoading = false;
              });
              _setUserCat();
            })
        : Container();
  }

  _showContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Expanded(flex: 1, child: skipBtn()),
        Expanded(flex: 1, child: selectCatText()),
        Expanded(flex: 8, child: multiSelectChipShow()),
        Expanded(flex: 2, child: saveBtn())
      ],
    );
  }

  getAppBar() {
    return widget.from ==  getTranslated(context,'home_lbl')
        ? AppBar(
            leadingWidth: 55.0,
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
                  Navigator.of(context).pop();
                },
                child: Image.asset(
                  "assets/images/back_icon.png",
                ),
              );
            }),
          )
        : PreferredSize(
            preferredSize: Size.fromHeight(0.0), child: Container());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey, appBar: getAppBar(), body: _showContent());
  }
}

class MultiSelectChip extends StatefulWidget {
  final List<Category> catList;
  final Function(List<String>) onSelectionChanged;

  MultiSelectChip(this.catList, {this.onSelectionChanged});

  @override
  _MultiSelectChipState createState() => _MultiSelectChipState();
}

class _MultiSelectChipState extends State<MultiSelectChip> {
  List<String> selectedChoices = [];
  String catId = "";
  bool _isNetworkAvail = true;

  @override
  void initState() {
    super.initState();
    getUserByCat();
  }

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

  Future<void> getUserByCat() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      var param = {
        ACCESS_KEY: access_key,
        USER_ID: CUR_USERID,
      };
      Response response = await post(Uri.parse(getUserByCatIdApi),
              body: param, headers: headers)
          .timeout(Duration(seconds: timeOut));

      var getdata = json.decode(response.body);

      String error = getdata["error"];
      if (error == "false") {
        var data = getdata["data"];

        for (int i = 0; i < data.length; i++) {
          catId = data[i]["category_id"];
        }
        setState(() {
          selectedChoices = catId == "" ? catId.split('') : catId.split(',');
        });
      }
    } else {
      setSnackbar(getTranslated(context,'internetmsg'));
    }
  }

  _buildChoiceList() {
    List<Widget> choices = [];

    widget.catList.forEach((item) {
      choices.add(
        ChoiceChip(
          label: Text(
            item.categoryName,
            style: Theme.of(context).textTheme.subtitle2.copyWith(
                color: selectedChoices.contains(item.id)
                    ? Theme.of(context).colorScheme.white
                    : Theme.of(context).colorScheme.fontColor2),
          ),
          selected: selectedChoices.contains(item.id),
          disabledColor: Theme.of(context).colorScheme.fontColor,
          selectedColor: colors.primary,
          onSelected: (selected) {
            setState(() {
              selectedChoices.contains(item.id)
                  ? selectedChoices.remove(item.id)
                  : selectedChoices.add(item.id);

              if (selectedChoices.length == 0) {
                setState(() {
                  selectedChoices.add("0");
                });
                widget.onSelectionChanged(selectedChoices);
              } else {
                if (selectedChoices.contains("0")) {
                  selectedChoices = List.from(selectedChoices)..remove("0");
                }

                widget.onSelectionChanged(selectedChoices);
              }
            });
          },
        ),
      );
    });

    return choices;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      // gap between adjacent chips
      runSpacing: 5.0,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: _buildChoiceList(),
    );
  }
}
