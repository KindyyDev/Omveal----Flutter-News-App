import 'package:admob_flutter/admob_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:news/Helper/Constant.dart';
import 'package:news/Helper/Session.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:news/Helper/Color.dart';
import 'Helper/Demo_Localization.dart';
import 'Helper/PushNotificationService.dart';
import 'Helper/String.dart';
import 'Helper/Theme.dart';
import 'Home.dart';
import 'Splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //firebase initialization
  Admob.initialize();

  await Firebase.initializeApp();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // status bar color
  ));
  Future<SharedPreferences> prefs = SharedPreferences.getInstance();
  prefs.then((value) {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeNotifier>(create: (BuildContext context) {
            String theme = value.getString(APP_THEME);
            if (theme == DARK) {
              isDark = true;
              value.setString(APP_THEME, DARK);
            }
            else if (theme == LIGHT) {
              isDark = false;
              value.setString(APP_THEME, LIGHT);
            }

            if (theme == null || theme == "" || theme == SYSTEM) {
              value.setString(APP_THEME, SYSTEM);
              var brightness =
                  SchedulerBinding.instance.window.platformBrightness;
              isDark = brightness == Brightness.dark;

              return ThemeNotifier(ThemeMode.system);
            }
            return ThemeNotifier(
                theme == LIGHT ? ThemeMode.light : ThemeMode.dark);
          }),
        ],
        child: MyApp(),
      ),
    );
  });
}

class MyApp extends StatefulWidget {
  const MyApp({Key key}) : super(key: key);

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState state = context.findAncestorStateOfType<_MyAppState>();
    state.setLocale(newLocale);
  }

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale;
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  void didChangeDependencies() {
    getLocale().then((locale) {
      setState(() {
        this._locale = locale;
      });
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    //notification service
    final pushNotificationService = PushNotificationService(_firebaseMessaging);
    pushNotificationService.initialise();
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    if (this._locale == null) {
      return Container(
        child: Center(child: CircularProgressIndicator()),
      );
    } else {
      return MaterialApp(
        locale: _locale,
        supportedLocales: [
          Locale("en", "US"),
          Locale("es", "ES"),
          Locale("hi", "IN"),
          Locale("tr", "TR"),
          Locale("pt", "PT"),
        ],
        localizationsDelegates: [
          DemoLocalization.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        localeResolutionCallback: (locale, supportedLocales) {
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale.languageCode &&
                supportedLocale.countryCode == locale.countryCode) {
              return supportedLocale;
            }
          }
          return supportedLocales.first;
        },
        title: appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            fontFamily: 'poppins',
            primarySwatch: colors.primary_app,
            primaryColor: colors.primary,
            canvasColor: colors.tempWhite,
            appBarTheme: AppBarTheme(backgroundColor: colors.tempWhite),
            visualDensity: VisualDensity.adaptivePlatformDensity,
            accentColor: colors.tempWhite,
            brightness: Brightness.light,
            bottomAppBarColor: colors.tempWhite,
            cardColor: colors.tempWhite,
            dialogTheme:
            DialogTheme(backgroundColor: colors.tempWhite, elevation: 5.0)),
        darkTheme: ThemeData(
            fontFamily: 'poppins',
            primarySwatch: colors.primary_app,
            primaryColor: colors.primary,
            brightness: Brightness.dark,
            canvasColor: colors.darkColor,
            appBarTheme: AppBarTheme(backgroundColor: colors.darkColor),
            accentColor: colors.darkColor,
            bottomAppBarColor: colors.darkColor,
            cardColor: colors.darkColor,
            dialogTheme:
            DialogTheme(backgroundColor: Colors.grey, elevation: 5.0)),
        initialRoute: '/',
        routes: {
          '/': (context) => SplashScreen(),
          '/home': (context) => Home(),
        },
        themeMode: themeNotifier.getThemeMode(),
      );
    }
  }
}
