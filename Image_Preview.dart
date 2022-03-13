import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:news/Model/News.dart';
import 'package:photo_view/photo_view.dart';

import 'Helper/Color.dart';
import 'Helper/Session.dart';

class ImagePreview extends StatefulWidget {
  final int index;
  final List<String> imgList;
  bool isNetworkAvail;

   ImagePreview({Key key, this.index, this.imgList,this.isNetworkAvail}) : super(key: key);

  @override
  State<StatefulWidget> createState() => StatePreview();
}

class StatePreview extends State<ImagePreview> {
  int curPos;
  @override
  void initState() {
    super.initState();
    checkNet();
    curPos = widget.index;

  }


  checkNet()
  async {
    widget.isNetworkAvail=await isNetworkAvailable();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Hero(
      tag: "${widget.index}",
      child: Stack(
        children: <Widget>[
          PageView.builder(
              itemCount: widget.imgList.length,
              controller: PageController(initialPage: curPos),
              onPageChanged: (index) async {
                setState(() {
                  curPos = index;
                });
                widget.isNetworkAvail=await isNetworkAvailable();
              },
              itemBuilder: (BuildContext context, int index) {
                return PhotoView(
                    backgroundDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.white),
                    initialScale: PhotoViewComputedScale.contained * 0.9,
                    minScale: PhotoViewComputedScale.contained * 0.9,
                    imageProvider: widget.isNetworkAvail
                        ? NetworkImage(widget.imgList[index])
                        : FileImage((File(widget.imgList[index]))));
              }),
          Padding(
            padding: const EdgeInsets.only(top: 30.0),
            child: InkWell(
              child: Image.asset(
                "assets/images/back_icon.png",
              ),
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
              bottom: 10.0,
              left: 25.0,
              right: 25.0,
              child: SelectedPhoto(
                numberOfDots: widget.imgList.length,
                photoIndex: curPos,
              )),
        ],
      ),
    ));
  }
}

class SelectedPhoto extends StatelessWidget {
  final int numberOfDots;
  final int photoIndex;

  SelectedPhoto({this.numberOfDots, this.photoIndex});

  Widget _inactivePhoto() {
    return Container(
      child: Padding(
        padding: EdgeInsets.only(left: 3.0, right: 3.0),
        child: Container(
          height: 8.0,
          width: 8.0,
          decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.4),
              borderRadius: BorderRadius.circular(4.0)),
        ),
      ),
    );
  }

  Widget _activePhoto() {
    return Container(
      child: Padding(
        padding: EdgeInsets.only(left: 5.0, right: 5.0),
        child: Container(
          height: 10.0,
          width: 10.0,
          decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey, spreadRadius: 0.0, blurRadius: 2.0)
              ]),
        ),
      ),
    );
  }

  List<Widget> _buildDots() {
    List<Widget> dots = [];
    for (int i = 0; i < numberOfDots; i++) {
      dots.add(i == photoIndex ? _activePhoto() : _inactivePhoto());
    }
    return dots;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _buildDots(),
      ),
    );
  }
}
