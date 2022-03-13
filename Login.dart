import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:apple_sign_in/apple_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart' as intl;
import 'package:news/ChooseCategory.dart';
import 'package:news/Helper/Color.dart';
import 'package:news/Helper/Constant.dart';
import 'package:news/Helper/Session.dart';
import 'Helper/AppBtn.dart';
import 'Helper/String.dart';
import 'PrivacyPolicy.dart';

class Login extends StatefulWidget {
  final String selectedUrl;

  Login({this.selectedUrl});

  @override
  LoginState createState() => LoginState();
}

class LoginState extends State<Login> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldState> _scaffoldKey1 = new GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  final GlobalKey<FormState> _formkey2 = GlobalKey<FormState>();
  final GlobalKey<FormState> _formkey3 = GlobalKey<FormState>();
  bool _isNetworkAvail = true;
  bool isLoading = false;
  FocusNode nameFocus, emailFocus, passFocus, confpassFocus = FocusNode();
  TextEditingController emailC, passC, confPassC, nameC;
  String id, name, email, pass, mobile, type, status, profile, confpass;
  String uid;
  String userEmail;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLogin = true;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  FacebookLogin facebookSignIn = new FacebookLogin();
  Animation buttonSqueezeanimation,
      buttonSqueezeanimation1,
      buttonSqueezeanimation2;

  AnimationController buttonController, buttonController1, buttonController2;

  @override
  void initState() {
    super.initState();

    buttonController = new AnimationController(
        duration: new Duration(milliseconds: 2000), vsync: this);
    buttonController1 = new AnimationController(
        duration: new Duration(milliseconds: 2000), vsync: this);
    buttonController2 = new AnimationController(
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
    buttonSqueezeanimation1 = new Tween(
      begin: deviceWidth * 0.36,
      end: 50.0,
    ).animate(new CurvedAnimation(
      parent: buttonController1,
      curve: new Interval(
        0.0,
        0.150,
      ),
    ));
    buttonSqueezeanimation2 = new Tween(
      begin: deviceWidth * 0.36,
      end: 50.0,
    ).animate(new CurvedAnimation(
      parent: buttonController2,
      curve: new Interval(
        0.0,
        0.150,
      ),
    ));
  }

  @override
  void dispose() {
    buttonController.dispose();
    buttonController1.dispose();
    buttonController2.dispose();
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    super.dispose();
  }

  //animation of btn
  Future<Null> _playAnimation() async {
    try {
      await buttonController.forward();
    } on TickerCanceled {}
  }

  //animation of btn1
  Future<Null> _playAnimation1() async {
    try {
      await buttonController1.forward();
    } on TickerCanceled {}
  }

  //animation of btn2
  Future<Null> _playAnimation2() async {
    try {
      await buttonController2.forward();
    } on TickerCanceled {}
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

  //check validation of form data
  bool validateAndSave() {
    final form = _formkey.currentState;
    form.save();
    if (form.validate()) {
      return true;
    }
    return false;
  }

  //apple sign in function to signIn in apple
  appleSignIn() async {
    try {
      final AuthorizationResult appleResult =
      await AppleSignIn.performRequests([
        AppleIdRequest(requestedScopes: [Scope.email, Scope.fullName])
      ]);

      if (appleResult.error != null) {
        // handle errors from Apple here
      }

      final AuthCredential credential = OAuthProvider('apple.com').credential(
        accessToken:
        String.fromCharCodes(appleResult.credential.authorizationCode),
        idToken: String.fromCharCodes(appleResult.credential.identityToken),
      );
      String name = appleResult.credential.fullName.familyName != "" &&
          appleResult.credential.fullName.familyName != null
          ? appleResult.credential.fullName.familyName
          : "Apple User";
      print("name****$name");

      final UserCredential authResult =
      await _auth.signInWithCredential(credential);
      final User user = authResult.user;

      if (user != null) {
        assert(!user.isAnonymous);

        assert(await user.getIdToken() != null);

        final User currentUser = _auth.currentUser;
        assert(user.uid == currentUser.uid);

        String email = user.email != null ? user.email : "";

        getLoginUser(user.uid, name, login_apple, email, "", "", true);
      }
    } catch (e) {
      String _errorMessage = e.message ?? e.toString();
      setSnackbar(_errorMessage);
    }
  }

  //sign in with google
  signInWithGoogle() async {
    try {
      await Firebase.initializeApp();
      final GoogleSignInAccount googleSignInAccount =
      await googleSignIn.signIn();
      final GoogleSignInAuthentication googleSignInAuthentication =
      await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      final UserCredential authResult =
      await _auth.signInWithCredential(credential);
      final User user = authResult.user;

      if (user != null) {
        assert(!user.isAnonymous);

        assert(await user.getIdToken() != null);

        final User currentUser = _auth.currentUser;
        assert(user.uid == currentUser.uid);

        String name = user.displayName != null ? user.displayName : "";

        String mobile = user.phoneNumber != null ? user.phoneNumber : "";

        String profile = user.photoURL != null ? user.photoURL : "";

        String email = user.email != null ? user.email : "";

        getLoginUser(user.uid, name, login_gmail, email, mobile, profile, true);
      }
    } catch (e) {
      String _errorMessage = e.message ?? e.toString();
      setSnackbar(_errorMessage);
    }
  }

  //sign in with facebook
  Future<String> _SignInWithFB() async {
    FacebookLogin _login = FacebookLogin();
    if (await _login.isLoggedIn) _login.logOut();

    final FacebookLoginResult result = await facebookSignIn.logIn(['email']);

    switch (result.status) {
      case FacebookLoginStatus.loggedIn:
        final FacebookAccessToken accessToken = result.accessToken;

        AuthCredential authCredential =
        FacebookAuthProvider.credential(accessToken.token);
        User user = (await _auth.signInWithCredential(authCredential)).user;

        assert(user.displayName != null);
        assert(!user.isAnonymous);
        assert(await user.getIdToken() != null);

        String name = user.displayName != null ? user.displayName : "";

        String mobile = user.phoneNumber != null ? user.phoneNumber : "";

        String profile = user.photoURL != null ? user.photoURL : "";

        String email = user.email != null ? user.email : "";

        getLoginUser(user.uid, name, login_fb, email, mobile, profile, true);

        break;
      case FacebookLoginStatus.cancelledByUser:
        setState(() {
          isLoading = false;
        });
        setSnackbar(getTranslated(context,'cancle_login'));

        break;
      case FacebookLoginStatus.error:
        setState(() {
          isLoading = false;
        });
        print('Something went wrong with the login process.\n'
            'Here\'s the error Facebook gave us: ${result.errorMessage}');
        setSnackbar(result.errorMessage);
        break;
    }
  }

  //sign in with email and password in firebase
  signInWithEmailPassword(String email, String password) async {
    try {
      final UserCredential userCredential =
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User user = userCredential.user;

      if (user != null) {
        // checking if uid or email is null
        assert(user.uid != null);
        assert(user.email != null);

        uid = user.uid;
        userEmail = user.email;

        assert(!user.isAnonymous);
        assert(await user.getIdToken() != null);

        final User currentUser = _auth.currentUser;
        assert(user.uid == currentUser.uid);

        String name = user.displayName;

        if (name == null || name.trim().length == 0) {
          name = email.split("@")[0];
        }
        print("uid***${user.uid}");
        await buttonController.reverse();
        if (userCredential.user.emailVerified) {
          getLoginUser(user.uid, name, login_email, email, null, null, false);
        } else {
          setSnackbar(getTranslated(context,'verify_email_msg'));
        }
      }
    } catch (e) {
      await buttonController.reverse();
      print('**Error: $e');
      String _errorMessage = e.message ?? e.toString();
      setSnackbar(_errorMessage);
    }
  }

  //reset form of data
  ResetForm() {
    setState(() {
      isLoading = false;
      emailC.text = "";
      passC.text = "";
      nameC.text = "";
      confPassC.text = "";
      _formkey.currentState.reset();
      _formkey3.currentState.reset();
    });
  }

  //login user using api
  Future<void> getLoginUser(String firebase_id1, String name1, String type1,
      String email1, String mobile1, String profile1, bool loading) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      var param = {
        FIREBASE_ID: firebase_id1,
        NAME: name1,
        EMAIL: email1,
        TYPE: type1,
        ACCESS_KEY: access_key,
      };

      if (isLoading == false) {
        setState(() {
          loading ? isLoading = true : isLoading = false;
        });
      }

      if (mobile1 != null && mobile1 != "") {
        param[MOBILE] = mobile1;
      }
      if (profile1 != null && profile1 != "") {
        param[PROFILE] = profile1;
      }

      Response response =
      await post(Uri.parse(getUserSignUpApi), body: param, headers: headers)
          .timeout(Duration(seconds: timeOut));

      var getdata = json.decode(response.body);

      String error = getdata["error"];
      String msg = getdata["message"];

      if (error == "false") {
        var i = getdata["data"];
        id = i[ID];
        name = i[NAME];
        email = i[EMAIL];
        mobile = i[MOBILE];
        profile = i[PROFILE];
        type = i[TYPE];
        status = i[STATUS];
        String isFirstLogin = i["is_login"];
        CUR_USERID = id;
        CUR_USERNAME = name;
        CUR_USEREMAIL = email;
        saveUserDetail(id, name, email, mobile, profile, type, status);

        if (status == "0") {
          setSnackbar(getTranslated(context,'deactive_msg'));
        } else {
          setSnackbar(getTranslated(context,'login_msg'));
          if (isFirstLogin == "1") {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (BuildContext context) => ChooseCategory(
                      title: getTranslated(context,'manage_prefrences'),
                      from: getTranslated(context,'login_lbl'),
                    )),
                    (Route<dynamic> route) => false);
          } else {
            getUserByCat().whenComplete(() {
              Navigator.of(context).pushNamedAndRemoveUntil(
                  "/home", (Route<dynamic> route) => false);
            });
          }
        }
      } else {
        if (_auth != null) _auth.signOut();
        setSnackbar(msg);
      }
      setState(() {
        isLoading = false;
      });
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
        setState(() {
          String catId = data[0]["category_id"];
          setPrefrence(cur_catId, catId);
        });
      }
    } else {
      setSnackbar(getTranslated(context,'internetmsg'));
    }
  }


  showContent() {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        flexibleSpace: Padding(
          padding: const EdgeInsets.only(top: 30, bottom: 10, right: 40, left: 60),
          child: Container(
            // color: Colors.lightBlue,
            height: 70,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/redtitle_logo2.png")
              )
            )
          ),
        ),
      ),
      body: Container(

        child: SingleChildScrollView(
            child: Form(
                key: _formkey,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.white,
                              boxShadow: [
                                BoxShadow(
                                    blurRadius: 10.0,
                                    offset: const Offset(0.0, 15.0),
                                    color: Theme.of(context)
                                        .colorScheme
                                        .fontColor2,
                                    spreadRadius: -9),
                              ],
                              borderRadius: new BorderRadius.only(
                                  bottomLeft: const Radius.circular(50.0),
                                  bottomRight: const Radius.circular(50.0))),
                          child: Column(children: <Widget>[
                            welcome_login_text(),
                            SizedBox(height: 10,),
                            loginTxt(),
                            setEmail(),
                            setPass(1),
                            forgotPassBtn(),
                            loginBtn(),
                            upperBtn(),
                            dontHaveAccTxt(),
                          ])),
                      dividerOr(),
                      Container(
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.white,
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .fontColor2
                                      .withOpacity(0.07),
                                  blurRadius: 10,
                                  spreadRadius: 5),
                            ],
                            borderRadius: new BorderRadius.only(
                                topLeft: const Radius.circular(80.0),
                                topRight: const Radius.circular(80.0))),
                        child: Column(children: [bottomBtn(), termPolicyTxt()]),
                      ),

                      //mistake i made
                      // Container(
                      //   height: MediaQuery.of(context).size.height,
                      //   decoration: BoxDecoration(
                      //       color: Theme.of(context).colorScheme.white,
                      //       boxShadow: <BoxShadow>[
                      //         BoxShadow(
                      //             color: Theme.of(context)
                      //                 .colorScheme
                      //                 .fontColor2,
                      //             blurRadius: 10,
                      //             spreadRadius: 3),
                      //       ],
                      //       borderRadius: new BorderRadius.only(
                      //           topLeft: const Radius.circular(50.0),
                      //           topRight: const Radius.circular(50.0))
                      //   ),
                      //   child: Column(children: [
                      //     bottomBtn(),
                      //     termPolicyTxt()]),
                      // ),

                    ]))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        body: Stack(
          children: <Widget>[
            showContent(),
            showCircularProgress(isLoading, colors.primary)
          ],
        ));
  }



  loginTxt() {
    return Container(
        alignment: Alignment.center,
        child: Text(
          getTranslated(context,'login_lbl'),
          style: Theme.of(context)
              .textTheme
              .headline5
              .copyWith(color: colors.headColor, fontWeight: FontWeight.bold),
        ));
  }


  registerTxt() {
    return Container(
      alignment: Alignment.center,
      child: Text(
        getTranslated(context,'signup_lbl'),
        style: Theme.of(context)
            .textTheme
            .headline5
            .copyWith(color: colors.headColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  _fieldFocusChange(
      BuildContext context, FocusNode currentFocus, FocusNode nextFocus) {
    currentFocus.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }


  setName() {
    return Padding(
        padding: EdgeInsetsDirectional.only(top: 40.0, end: 20.0, start: 20.0),
        child: Container(
          padding: EdgeInsetsDirectional.only(start: 5.0, end: 5.0),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                  blurRadius: 10.0,
                  offset: const Offset(0.0, 25.0),
                  color: Theme.of(context)
                      .colorScheme
                      .fontColor2
                      .withOpacity(0.13),
                  spreadRadius: -15),
            ],
            borderRadius: BorderRadius.circular(25.0),
          ),
          child: TextFormField(
            focusNode: nameFocus,
            textInputAction: TextInputAction.next,
            controller: nameC,
            style: Theme.of(this.context)
                .textTheme
                .subtitle1
                .copyWith(color: Colors.grey),
            validator:(val)=> nameValidation(val,context),
            onChanged: (String value) {
              setState(() {
                name = value;
              });
            },
            onFieldSubmitted: (v) {
              _fieldFocusChange(context, nameFocus, emailFocus);
              //FocusScope.of(context).requestFocus(emailFocus);
            },
            decoration: InputDecoration(
              icon: Icon(Icons.person, color: Colors.black,),
              hintText: getTranslated(context,'name_lbl'),
              hintStyle: Theme.of(this.context)
                  .textTheme
                  .subtitle1
                  .copyWith(color: Theme.of(context).colorScheme.fontColor),
              filled: true,
              fillColor: Theme.of(context).colorScheme.white,
              contentPadding:
              EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              focusedBorder: OutlineInputBorder(
                borderSide:
                BorderSide(color: Theme.of(context).colorScheme.white),
                borderRadius: BorderRadius.circular(25.0),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide:
                BorderSide(color: Theme.of(context).colorScheme.white),
                borderRadius: BorderRadius.circular(25.0),
              ),
            ),
          ),
        ));
  }


  setEmail() {
    return Padding(
        padding: EdgeInsetsDirectional.only(
            top: _isLogin ? 40.0 : 25.0, end: 20.0, start: 20.0),
        child: Container(
          padding: EdgeInsetsDirectional.only(start: 5.0, end: 5.0),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                  blurRadius: 10.0,
                  offset: const Offset(20.0, 25.0),
                  color: Theme.of(context)
                      .colorScheme
                      .fontColor2
                      .withOpacity(0.13),
                  spreadRadius: -15),
            ],
            borderRadius: BorderRadius.circular(25.0),
          ),
          child: TextFormField(
            focusNode: emailFocus,
            textInputAction: TextInputAction.next,
            controller: emailC,
            style: Theme.of(this.context)
                .textTheme
                .subtitle1
                .copyWith(color: Colors.grey),
            validator:(val)=> emailValidation(val,context),
            onChanged: (String value) {
              setState(() {
                email = value;
              });
            },
            onFieldSubmitted: (v) {
              _fieldFocusChange(context, emailFocus, passFocus);
            },
            decoration: InputDecoration(
              icon: Icon(Icons.mail, color: Colors.black,),
              hintText: getTranslated(context,'email_lbl'),
              hintStyle: Theme.of(this.context).textTheme.subtitle1.copyWith(color: Theme.of(context).colorScheme.fontColor),
              filled: true,
              fillColor: Theme.of(context).colorScheme.white,
              contentPadding:
              EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              focusedBorder: OutlineInputBorder(
                borderSide:
                BorderSide(color: Theme.of(context).colorScheme.white),
                borderRadius: BorderRadius.circular(25.0),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide:
                BorderSide(color: Theme.of(context).colorScheme.white),
                borderRadius: BorderRadius.circular(25.0),
              ),
            ),
          ),
        ));
  }


  setPass(int from) {
    return Padding(
        padding: EdgeInsetsDirectional.only(top: 25.0, end: 20.0, start: 20.0),
        child: Container(
          padding: EdgeInsetsDirectional.only(start: 5.0, end: 5.0),
          decoration: BoxDecoration(boxShadow: [
            BoxShadow(
                blurRadius: 10.0,
                offset: const Offset(20.0, 25.0),
                color:
                Theme.of(context).colorScheme.fontColor2.withOpacity(0.13),
                spreadRadius: -15)
          ]),
          child: TextFormField(
            obscureText: true,
            obscuringCharacter: "*",
            keyboardType: TextInputType.text,
            textInputAction: from==1?TextInputAction.done:TextInputAction.next,
            focusNode: passFocus,
            controller: passC,
            style: Theme.of(this.context)
                .textTheme
                .subtitle1
                .copyWith(color: Colors.black),
            validator:(val)=> passValidation(val,context),
            onChanged: (String value) {
              setState(() {
                pass = value;
              });
            },
            onFieldSubmitted: (v) {
              _fieldFocusChange(context, passFocus, confpassFocus);
            },
            decoration: InputDecoration(
              icon: Icon(Icons.lock, color: Colors.black,),
              hintText: getTranslated(context,'pass_lbl'),
              hintStyle: Theme.of(this.context)
                  .textTheme
                  .subtitle1
                  .copyWith(color: Theme.of(context).colorScheme.fontColor),
              filled: true,
              fillColor: Theme.of(context).colorScheme.white,
              contentPadding:
              EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              focusedBorder: OutlineInputBorder(
                borderSide:
                BorderSide(color: Theme.of(context).colorScheme.white),
                borderRadius: BorderRadius.circular(25.0),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide:
                BorderSide(color: Theme.of(context).colorScheme.white),
                borderRadius: BorderRadius.circular(25.0),
              ),
            ),
          ),
        ));
  }


  setConfPass() {
    return Padding(
        padding: EdgeInsetsDirectional.only(top: 25.0, end: 20.0, start: 20.0),
        child: Container(
          padding: EdgeInsetsDirectional.only(start: 5.0, end: 5.0),
          decoration: BoxDecoration(boxShadow: [
            BoxShadow(
                blurRadius: 10.0,
                offset: const Offset(0.0, 25.0),
                color:
                Theme.of(context).colorScheme.fontColor2.withOpacity(0.13),
                spreadRadius: -15)
          ]),
          child: TextFormField(
            obscureText: true,
            obscuringCharacter: "*",
            keyboardType: TextInputType.text,
            focusNode: confpassFocus,
            controller: confPassC,
            style: Theme.of(this.context)
                .textTheme
                .subtitle1
                .copyWith(color: Colors.grey),
            validator: (value) {
              if (value.length == 0) return getTranslated(context,'confpass_required');
              if (value != pass) {
                return confpass_not_match;
              } else {
                return null;
              }
            },
            onChanged: (String value) {
              confpass = value;
            },
            decoration: InputDecoration(
              icon: Icon(Icons.lock, color: Colors.black,),
              hintText: getTranslated(context,'confpass_lbl'),
              hintStyle: Theme.of(this.context)
                  .textTheme
                  .subtitle1
                  .copyWith(color: Colors.black),
              filled: true,
              fillColor: Theme.of(context).colorScheme.white,
              contentPadding:
              EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              focusedBorder: OutlineInputBorder(
                borderSide:
                BorderSide(color: Theme.of(context).colorScheme.white),
                borderRadius: BorderRadius.circular(25.0),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide:
                BorderSide(color: Theme.of(context).colorScheme.white),
                borderRadius: BorderRadius.circular(25.0),
              ),
            ),
          ),
        ));
  }


  forgotPassBtn() {
    return Padding(
        padding: EdgeInsetsDirectional.only(top: 10.0, end: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            InkWell(
              onTap: () {
                forgotPassBottomSheet();
              },
              child: Text(getTranslated(context,'forgot_pass_lbl'),
                  style: Theme.of(context).textTheme.subtitle2.copyWith(
                      color: colors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ));
  }


  bottomBtn() {
    return Padding(
        padding: EdgeInsetsDirectional.only(top: 25, start: 17.0, end: 17.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            googleAcc(),
            fbAcc(),
            appleAcc(),
          ],
        ));
  }


  loginBtn() {
    return AppBtn(
      title: getTranslated(context,'login_lbl'),
      btnAnim: buttonSqueezeanimation,
      btnCntrl: buttonController,
      onBtnSelected: () async {
        if (validateAndSave()) {
          _playAnimation();
          _isNetworkAvail = await isNetworkAvailable();
          if (_isNetworkAvail) {
            setState(() {
              isLoading = false;
            });
            signInWithEmailPassword(email.trim(), pass);
          } else {
            Future.delayed(Duration(seconds: 2)).then((_) async {
              await buttonController.reverse();
              setSnackbar(getTranslated(context,'internetmsg'));
            });
          }
        }
      },
    );
  }


  registerBtn() {
    return Center(
        child: AppBtn(
            title: getTranslated(context,'register_lbl'),
            btnAnim: buttonSqueezeanimation1,
            btnCntrl: buttonController1,
            onBtnSelected: () async {
              setState(() {
                _isLogin = true;
              });

              final form = _formkey3.currentState;
              if (form.validate()) {
                form.save();
                _playAnimation1();
                _isNetworkAvail = await isNetworkAvailable();
                if (_isNetworkAvail) {
                  registerWithEmailPassword(email.trim(), pass);
                } else {
                  Future.delayed(Duration(seconds: 1)).then((_) async {
                    await buttonController1.reverse();
                    setSnackbar(getTranslated(context,'internetmsg'));
                  });
                }
              }
            }));
  }


  registerWithEmailPassword(String email, String password) async {
    await _auth
        .createUserWithEmailAndPassword(
      email: email,
      password: password,
    )
        .then((user) async {
      await buttonController1.reverse();
      await user.user.sendEmailVerification().then((value) async {
        setSnackbar('${getTranslated(context,'varif_sent_mail')}+$email');
        await user.user.updateDisplayName(name.trim());
        await user.user.reload();
        final User updatedUser = _auth.currentUser;

        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context);
        });

        return user.user.uid;
      }).catchError((e) {
        print("An error occured while trying to send email verification");
        print(e.message);
        AuthCredential authCredential =
        EmailAuthProvider.credential(email: email, password: password);
        user.user.reauthenticateWithCredential(authCredential);
        user.user.delete();
      });
    }).catchError((e) async {
      print('**Error: $e');
      String _errorMessage = e.message ?? e.toString();
      await buttonController1.reverse();
      setSnackbar(_errorMessage);
    });
  }


  signUpBottomSheet() {
    showModalBottomSheet<dynamic>(
        context: context,
        isScrollControlled: true,
        elevation: 3.0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30), topRight: Radius.circular(30))),
        builder: (builder) {
          return
            // Container(
            //   padding: EdgeInsetsDirectional.only(bottom: 20.0, top: 5.0),
            //   decoration: BoxDecoration(
            //       borderRadius: BorderRadius.only(
            //           topLeft: Radius.circular(30),
            //           topRight: Radius.circular(30)),
            //       color: Theme.of(context).colorScheme.white),
            //   child:
              Scaffold(
                  appBar: AppBar(
                flexibleSpace: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10, right: 40, left: 60),
                  child: Container(
                    // color: Colors.lightBlue,
                      height: 70,
                      decoration: BoxDecoration(
                          image: DecorationImage(
                              image: AssetImage("assets/images/redtitle_logo2.png")
                          )
                      )
                  ),
                ),
              ),
                  resizeToAvoidBottomInset: false,
                  key: _scaffoldKey1,
                  body: Form(
                      key: _formkey3,
                      child: SingleChildScrollView(
                          padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Padding(
                                //     padding: EdgeInsetsDirectional.only(end: 10.0),
                                //     child: Align(
                                //         alignment: Alignment.bottomRight,
                                //         child: IconButton(
                                //             icon: Icon(
                                //               Icons.close,
                                //               textDirection:
                                //               Directionality.of(context),
                                //             ),
                                //             onPressed: () {
                                //               Navigator.pop(context);
                                //               setState(() {
                                //                 _isLogin = true;
                                //               });
                                //             }))),
                                registerTxt(),
                                setName(),
                                setEmail(),
                                setPass(2),
                                setConfPass(),
                                registerBtn(),
                                termPolicyTxt(),
                              ]))));
        });
  }


  forgotPassBottomSheet() {
    showModalBottomSheet<dynamic>(
        context: context,
        isScrollControlled: true,
        elevation: 3.0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30), topRight: Radius.circular(30))),
        builder: (builder) {
          return Container(
              padding: EdgeInsetsDirectional.only(
                  bottom: 20.0, top: 5.0, start: 20.0, end: 20.0),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30)),
                  color: Theme.of(context).colorScheme.white),
              child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: Form(
                      key: _formkey2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                  icon: Icon(Icons.close),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  })),
                          Padding(
                              padding: EdgeInsetsDirectional.only(top: 10.0),
                              child: Text(
                                getTranslated(context,'forgt_pass_head'),
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle1
                                    .copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .fontColor
                                      .withOpacity(0.8),
                                ),
                              )),
                          Padding(
                              padding: EdgeInsetsDirectional.only(top: 10.0),
                              child: Text(
                                getTranslated(context,'forgot_pass_sub'),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyText1
                                    .copyWith(
                                  fontWeight: FontWeight.normal,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .fontColor
                                      .withOpacity(0.8),
                                ),
                              )),
                          Container(
                            padding: EdgeInsetsDirectional.only(top: 25.0),
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                    blurRadius: 10.0,
                                    offset: const Offset(0.0, 25.0),
                                    color: Theme.of(context)
                                        .colorScheme
                                        .fontColor2
                                        .withOpacity(0.13),
                                    spreadRadius: -15),
                              ],
                              borderRadius: BorderRadius.circular(25.0),
                            ),
                            child: TextFormField(
                              controller: emailC,
                              style: Theme.of(this.context)
                                  .textTheme
                                  .subtitle1
                                  .copyWith(color: Colors.grey),
                              validator:(val)=> emailValidation(val,context),
                              onChanged: (String value) {
                                setState(() {
                                  email = value;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: getTranslated(context,'email_enter_lbl'),
                                hintStyle: Theme.of(this.context)
                                    .textTheme
                                    .subtitle1
                                    .copyWith(color: Colors.black),
                                filled: true,
                                fillColor: Theme.of(context).colorScheme.white,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 25, vertical: 15),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color:
                                      Theme.of(context).colorScheme.white),
                                  borderRadius: BorderRadius.circular(25.0),
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color:
                                      Theme.of(context).colorScheme.white),
                                  borderRadius: BorderRadius.circular(25.0),
                                ),
                              ),
                            ),
                          ),
                          Center(
                              child: AppBtn(
                                  title: getTranslated(context,'submit_btn'),
                                  btnAnim: buttonSqueezeanimation2,
                                  btnCntrl: buttonController2,
                                  onBtnSelected: () async {
                                    final form = _formkey2.currentState;
                                    if (form.validate()) {
                                      form.save();
                                      _playAnimation2();
                                      _isNetworkAvail =
                                      await isNetworkAvailable();
                                      if (_isNetworkAvail) {
                                        Future.delayed(Duration(seconds: 1))
                                            .then((_) async {
                                          buttonController2.reverse();
                                          _auth.sendPasswordResetEmail(
                                              email: email.trim());
                                          setSnackbar(getTranslated(context,'pass_reset'));
                                          Navigator.pop(context);
                                        });
                                      } else {
                                        Future.delayed(Duration(seconds: 1))
                                            .then((_) async {
                                          await buttonController2.reverse();
                                          setSnackbar(getTranslated(context,'internetmsg'));
                                        });
                                        return false;
                                      }
                                    }
                                  }))
                        ],
                      ))));
        });
  }


  dontHaveAccTxt() {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsetsDirectional.only(top: 10.0, bottom: 30.0),
      child: Column(
        children: <Widget>[
          Text(getTranslated(context,'donthaveacc_lbl'),
              style: Theme.of(context).textTheme.subtitle1.copyWith(
                  color:
                  Theme.of(context).colorScheme.fontColor,
                  fontWeight: FontWeight.bold)),
          InkWell(
              onTap: () async {
                setState(() {
                  _isLogin = false;
                });
                await signUpBottomSheet();
              },
              child: Text(
                getTranslated(context,'create_acc_lbl'),
                style: Theme.of(context).textTheme.subtitle1.copyWith(
                    color: colors.headColor, fontWeight: FontWeight.bold, fontSize: 20),
              )
          )
        ],
      ),
    );
  }


  welcome_login_text() {
    return Container(
        padding: EdgeInsetsDirectional.only(start: 30.0, top: 30),
        alignment: Alignment.centerLeft,
        child: Text(
          "Welcome \n Back!", style: TextStyle(fontWeight: FontWeight.bold,
            color: Colors.indigo[900],
            fontSize: 25
        ),
        ));
  }

  // dividerOr() {
  //   return Padding(
  //       padding: EdgeInsetsDirectional.only(
  //           top: 20.0, start: 20.0, end: 20.0, bottom: 20.0),
  //       child: Row(
  //         crossAxisAlignment: CrossAxisAlignment.center,
  //         children: [
  //           Expanded(
  //               child: Divider(
  //                 color: Colors.grey.withOpacity(0.3),
  //                 endIndent: 15,
  //                 thickness: 2.0,
  //               )),
  //           Text(
  //             getTranslated(context,'or_lbl'),
  //             style: Theme.of(context).textTheme.subtitle1.merge(TextStyle(
  //               color: Colors.grey,
  //             )),
  //           ),
  //           Expanded(
  //               child: Divider(
  //                 color: Colors.grey.withOpacity(0.3),
  //                 indent: 15,
  //                 thickness: 2.0,
  //               )),
  //         ],
  //       ));
  // }

//mistake
  dividerOr() {
    return Padding(
        padding: EdgeInsetsDirectional.only(
            top: 20.0, start: 20.0, end: 20.0, bottom: 20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
                child: Divider(
                  // color: Colors.indigo[900],
                  indent: 5,
                  endIndent: 5,
                  thickness: 2.0,
                )),
          ],
        ));
  }

  //set apple account btn
  appleAcc() {
    return Platform.isIOS
        ? CupertinoButton(
      child: Image.asset(
        "assets/images/Apple_button.png",
        height: 50,
      ),
      onPressed: () async {
        AppleSignIn.isAvailable();
        appleSignIn();
      },
    )
        : Container();
  }

  //set google acc btn
  googleAcc() {
    return CupertinoButton(
      child: SvgPicture.asset(
        "assets/images/Google_button.svg",
        color: colors.primary,
        semanticsLabel: 'Google Btn',
        height: 50,
      ),
      onPressed: () async {
        signInWithGoogle();
      },
    );
  }

  //set facebook account btn
  fbAcc() {
    return CupertinoButton(
      child: SvgPicture.asset(
        "assets/images/Facebook_button.svg",
        color: Colors.indigo,
        semanticsLabel: 'Google Btn',
        height: 50,
      ),
      onPressed: () async {
        //facebookLogin();
        _SignInWithFB();
      },
    );
  }

  //set back btn
  backBtn() {
    return Platform.isIOS
        ? Container(
      height: 53,
      width: 53,
      child: Card(
          color: Theme.of(context).colorScheme.white,
          shadowColor:
          Theme.of(context).colorScheme.fontColor.withOpacity(0.5),
          elevation: 4.0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          child: InkWell(
            child: Icon(
              Icons.keyboard_backspace_outlined,
              size: 35,
              color: colors.primary,
            ),
            onTap: () {
              Navigator.of(context).pop();
            },
          )),
    )
        : Container();
  }

  //upper both btn
  upperBtn() {
    return Padding(
        padding: EdgeInsetsDirectional.only(end: 20.0, top: 5.0, start: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            backBtn(),
            skipBtn(),
          ],
        ));
  }

  //set skip login btn
  skipBtn() {
    return Container(
      height: 53,
      width: 100,
      child: Row(
        children: [
          Text("SKIP",
            style: TextStyle(
              decoration: TextDecoration.underline,
                fontSize: 20,
                fontWeight:
                FontWeight.bold,
                color: Colors.indigo[900]),),
          Card(
            color: Theme.of(context).colorScheme.white,
            elevation: 0.0,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: InkWell(
              child: Icon(
                Icons.arrow_forward,
                size: 40,
                color: colors.primary,
              ),
              onTap: () {
                setPrefrenceBool(ISFIRSTTIME, true);
                Navigator.of(context).pushNamedAndRemoveUntil(
                    "/home", (Route<dynamic> route) => false);
              },
            )
    ),
    ]
      ),
    );
  }

  //set term and policy text
  termPolicyTxt() {
    return Container(
        padding: EdgeInsetsDirectional.only(bottom: 30.0),
        alignment: Alignment.bottomCenter,
        child: Column(children: [
          Text(
            getTranslated(context, 'agreeTermPolicy_lbl'),
            style: Theme
                .of(context)
                .textTheme
                .bodyText1
                .copyWith(
                color: Theme
                    .of(context)
                    .colorScheme
                    .fontColor
                    .withOpacity(0.9),
                fontWeight: FontWeight.normal),
            textAlign: TextAlign.center,
          ),
          Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                InkWell(
                  child: Text(
                    getTranslated(context, 'term_lbl'),
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodyText1
                        .copyWith(
                        color: Theme
                            .of(context)
                            .colorScheme
                            .fontColor
                            .withOpacity(0.9),
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  onTap: () {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (BuildContext context) =>
                                PrivacyPolicy(
                                  title: getTranslated(context, 'aboutus_lbl'),
                                  from: getTranslated(context, 'login_lbl'),
                                )));
                  },
                ),
                Text(
                  getTranslated(context, 'and_lbl'),
                  style: Theme
                      .of(context)
                      .textTheme
                      .bodyText1
                      .copyWith(
                      color: Theme
                          .of(context)
                          .colorScheme
                          .fontColor
                          .withOpacity(0.9),
                      fontWeight: FontWeight.normal),
                  textAlign: TextAlign.center,
                ),
                InkWell(
                  child: Text(
                    getTranslated(context, 'pri_policy'),
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodyText1
                        .copyWith(
                        color: Theme
                            .of(context)
                            .colorScheme
                            .fontColor
                            .withOpacity(0.9),
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  onTap: () {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (BuildContext context) =>
                                PrivacyPolicy(
                                  title: getTranslated(context, 'pri_policy'),
                                  from: getTranslated(context, 'login_lbl'),
                                )));
                  },
                ),
              ])
        ]));
  }

  }
