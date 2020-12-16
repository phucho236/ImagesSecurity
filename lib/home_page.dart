import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:images_security/FiresStore/fires_store.dart';
import 'package:images_security/Model/data_assets_model.dart';
import 'package:images_security/TestPerformance/test_performance_page.dart';
import 'package:images_security/profile_user_provider.dart';
import 'package:images_security/push_images_page.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> base64Images = [];
  FiresStore firesStore = new FiresStore();
  String googleId;
  bool onLoading = true;
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    init();
  }

  init() async {
    Future.delayed(Duration.zero, () {
      googleId = context.read<ProfileUserProvider>().profileUser;
      extractImages(googleId);
    });
  }

  Widget buildCtn() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: StaggeredGridView.countBuilder(
        physics: ClampingScrollPhysics(),
        crossAxisCount: 2,
        itemBuilder: (c, i) {
          Uint8List asset = base64.decode(base64Images[i]);
          return Image.memory(asset);
        },
        staggeredTileBuilder: (int index) =>
            new StaggeredTile.count(1, index.isEven ? 2 : 2),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        itemCount: base64Images.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PushImagesPage()),
              );
            },
            icon: Icon(
              Icons.verified_user,
              color: Colors.white,
            ),
          )
        ],
        title: GestureDetector(
            onLongPress: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TestPerformancePage()),
              );
            },
            child: const Text('Images Security')),
      ),
      body: SmartRefresher(
        controller: _refreshController,
        enablePullUp: false,
        child: base64Images.length > 0
            ? buildCtn()
            : Center(
                child: Text("You don't have Image !"),
              ),
        header: WaterDropHeader(),
        onRefresh: () async {
          init();

          _refreshController.refreshCompleted();
        },
      ),
    );
  }

  extractImages(googleId) async {
    List<dynamic> tmp = [];
    await firesStore.getAssetsToken(googleId).then((value) async {
      if (value.length > 0) {
        print(value.length);
        value.forEach((element) {
          try {
            final jwt = JWT.verify(element, SecretKey(googleId));
            PayLoad payLoad = PayLoad.fromJson(jwt.payload);
            tmp.add(payLoad.base64);
          } on JWTExpiredError {
            print('jwt expired');
          } on JWTError catch (ex) {
            print(ex.message); // ex: invalid signature
          }
        });
      }
    });
    setState(() {
      base64Images = tmp;
      onLoading = false;
    });
  }
}
