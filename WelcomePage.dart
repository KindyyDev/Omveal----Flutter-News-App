import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:news/Helper/Constant.dart';
import 'Helper/Color.dart';
import 'Helper/Session.dart';
import 'Helper/String.dart';
import 'Login.dart';

class WelcomePage extends StatefulWidget {
  @override
  WelcomePageState createState() => WelcomePageState();
}

class WelcomePageState extends State<WelcomePage> {
  int _currentPage = 0;
  List slideList = [];
  final PageController _pageController = PageController(initialPage: 0);
  var isDarkTheme;



  @override
  void initState() {
    super.initState();
    new Future.delayed(Duration.zero,() {
      //slider list data
      slideList = [
        Slide(
          imageUrl: 'assets/images/redtitle_logo.png',
          imageUrl2: 'assets/images/introslider.png',
          title: getTranslated(context,'wel_title1'),
          description: getTranslated(context,'wel_des1'),
        ),
        Slide(
          imageUrl: 'assets/images/redtitle_logo.png',
          imageUrl2: 'assets/images/introslider.png',
          title: getTranslated(context,'wel_title2'),
          description: getTranslated(context,'wel_des2'),
        ),
        Slide(
          imageUrl: 'assets/images/redtitle_logo.png',
          imageUrl2: 'assets/images/introslider.png',
          title: getTranslated(context,'wel_title3'),
          description: getTranslated(context,'wel_des3'),
        ),
      ];
    });
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery
        .of(context)
        .size
        .height;
    deviceWidth = MediaQuery
        .of(context)
        .size
        .width;
    SystemChrome.setEnabledSystemUIOverlays([]);

    return Scaffold(
        body: Container(
          color: Colors.black,
            height: deviceHeight,
            width: deviceWidth,
            // decoration: getBackGround(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _slider(),
                _btn(),
              ],
            )));
  }

  //set when page changed
  _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  //set function to page changed
  List<T> map<T>(List list, Function handler) {
    List<T> result = [];
    for (var i = 0; i < list.length; i++) {
      result.add(handler(i, list[i]));
    }

    return result;
  }

//set page slider
  Widget _slider() {
    isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: PageView.builder(
        itemCount: slideList.length,
        scrollDirection: Axis.horizontal,
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemBuilder: (BuildContext context, int index) {
          return SingleChildScrollView(
            padding: EdgeInsetsDirectional.only(start: 10.0, end: 10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  padding: EdgeInsetsDirectional.only(top: 5.0),
                  height: MediaQuery
                      .of(context)
                      .size
                      .height * .3,
                  child: Image.asset(
                    slideList[index].imageUrl,
                  ),
                ),
                Container(
                  padding: EdgeInsetsDirectional.only(top: 5.0),
                  height: MediaQuery
                      .of(context)
                      .size
                      .height * .2,
                  child: Image.asset(
                    slideList[index].imageUrl2,
                  ),
                ),
                Padding(
                    padding: EdgeInsetsDirectional.only(top: 80.0),
                    child: Text(
                      slideList[index].title,
                      textAlign: TextAlign.center,
                      style: Theme
                          .of(context)
                          .textTheme
                          .headline6
                          .copyWith(
                          color: isDarkTheme?colors.backColor:colors.tempWhite, fontWeight: FontWeight.bold, fontSize: 30),
                    )),
                Padding(
                    padding: EdgeInsetsDirectional.only(top: 50.0),
                    child: Text(slideList[index].description,
                        textAlign: TextAlign.center,
                        style: Theme
                            .of(context)
                            .textTheme
                            .subtitle1
                            .copyWith(
                            color: isDarkTheme?colors.backColor:colors.tempWhite,
                            fontWeight: FontWeight.normal))),
              ],
            ),
          );
        },
      ),
    );
  }

  //dot btn to shown in page navigate
  //dot btn to shown in page navigate
  _btn() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              child: Text("Next..."),
              onPressed: () {
                if (_currentPage == 2) {
                  setPrefrenceBool(ISFIRSTTIME, true);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => Login()),
                  );
                }
                else {
                  _currentPage = _currentPage + 1;
                  _pageController.animateToPage(_currentPage,
                      curve: Curves.decelerate,
                      duration: Duration(milliseconds: 300));
                }
              },

              style: ElevatedButton.styleFrom(
                  primary: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.normal)),
            ),

            // Text(txt,textScaleFactor: 2),
          ],
        ),
      ),
    );


    // dot slider
    // isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    // return Row(
    //   mainAxisAlignment: MainAxisAlignment.center,
    //   mainAxisSize: MainAxisSize.min,
    //   children: [
    //     Padding(
    //         padding: EdgeInsetsDirectional.only(start: 100.0, bottom: 30.0),
    //         child: Row(
    //           children: map<Widget>(
    //             slideList,
    //                 (index, url) {
    //               return Container(
    //                   width: 10.0,
    //                   height: 10.0,
    //                   margin: EdgeInsets.symmetric(horizontal: 5.0),
    //                   decoration: BoxDecoration(
    //                     shape: BoxShape.circle,
    //                     color: _currentPage == index
    //                         ? isDarkTheme?colors.backColor:colors.headColor
    //                         : isDarkTheme?colors.backColor.withOpacity(0.5):colors.headColor.withOpacity((0.5)),
    //                   ));
    //             },
    //           ),
    //         )),
    //     Padding(
    //         padding: EdgeInsetsDirectional.only(start: 50.0, bottom: 30.0),
    //         child:
    //         InkWell(
    //             child: Text(
    //               getTranslated(context,'next_lbl'),
    //               style: Theme
    //                   .of(context)
    //                   .textTheme
    //                   .headline6
    //                   .copyWith(color:isDarkTheme?colors.backColor:colors.headColor),
    //             ),
    //             onTap: () {
    //               if (_currentPage == 2) {
    //                 setPrefrenceBool(ISFIRSTTIME, true);
    //                 Navigator.pushReplacement(
    //                   context,
    //                   MaterialPageRoute(builder: (context) => Login()),
    //                 );
    //               } else {
    //                 _currentPage = _currentPage + 1;
    //                 _pageController.animateToPage(_currentPage,
    //                     curve: Curves.decelerate,
    //                     duration: Duration(milliseconds: 300));
    //               }
    //             }))
    //   ],
    // );
    //End dot slider


  }
}

//slide class
class Slide {
  final String imageUrl;
  final String imageUrl2;
  final String title;
  final String description;

  Slide({
    @required this.imageUrl,
    @required this.imageUrl2,
    @required this.title,
    @required this.description,
  });
}
