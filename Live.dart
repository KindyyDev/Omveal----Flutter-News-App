import 'dart:async';
import 'dart:convert';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart' as intl;
import 'package:news/Helper/Constant.dart';
import 'package:news/Helper/Session.dart';
import 'package:news/Helper/Color.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'Helper/String.dart';
import 'Model/News.dart';

class Live extends StatefulWidget {
  var liveNews;

  Live({Key key, this.liveNews}) : super(key: key);

  @override
  State<StatefulWidget> createState() => StateLive();
}

class StateLive extends State<Live> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  YoutubePlayerController _yc;
  FlickManager flickManager;
  bool _isNetworkAvail=true;

  @override
  void initState() {
    super.initState();
    checkNet();
    if (widget.liveNews[0][TYPE] == "url_youtube") {
      _yc = YoutubePlayerController(
        initialVideoId: YoutubePlayer.convertUrlToId(widget.liveNews[0]["url"]),
        flags: YoutubePlayerFlags(
          autoPlay: false,
          isLive: true,
        ),
      );
    } else {
      flickManager = FlickManager(
          videoPlayerController:
              VideoPlayerController.network(widget.liveNews[0]["url"]),
          autoPlay: false);
    }
  }

  checkNet()
  async {
    _isNetworkAvail=await isNetworkAvailable();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        body: Stack(children: <Widget>[
          Padding(
            padding: EdgeInsetsDirectional.only(
                start: 15.0, end: 15.0, top: 10.0, bottom: 10.0),
            child: _isNetworkAvail?widget.liveNews[0][TYPE] == "url_youtube"
                ? YoutubePlayerBuilder(
                    player: YoutubePlayer(
                      controller: _yc,
                    ),
                    builder: (context, player) {
                      return Center(child: player);
                    })
                : FlickVideoPlayer(flickManager: flickManager):Center(child:Text(getTranslated(context, 'internetmsg'))),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 30.0),
            child: InkWell(
              child: Image.asset(
                "assets/images/back_icon.png",
              ),
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
        ]));
  }
}
