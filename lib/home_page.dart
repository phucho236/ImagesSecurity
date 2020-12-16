import 'dart:async';
import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/material.dart';
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
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  List<dynamic> base64Images = [];
  FiresStore firesStore = new FiresStore();
  String googleId;
  bool onLoading = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    init();
  }

  init() {
    Future.delayed(Duration.zero, () {
      googleId = context.read<ProfileUserProvider>().profileUser;
      extractImages(googleId);
    });
  }

  Widget buildCtn() {
    return GridView.builder(
      physics: ClampingScrollPhysics(),
      padding: EdgeInsets.only(bottom: 15, left: 15, right: 15),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: (0.55),
      ),
      itemBuilder: (c, i) => Padding(
        padding: EdgeInsets.only(
            top: 15, left: i % 2 == 0 ? 0 : 7.5, right: i % 2 == 0 ? 7.5 : 0),
        child: Image.memory(
          base64.decode(base64Images[i]),
          fit: BoxFit.cover,
        ),
      ),
      itemCount: base64Images.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          RotatedBox(
            quarterTurns: 1,
            child: Container(
              decoration: new BoxDecoration(
                  image: DecorationImage(
                image: new AssetImage("assets/images/background-3.gif"),
                fit: BoxFit.cover,
              )),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 15, left: 15, right: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onLongPress: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => TestPerformancePage()),
                        );
                      },
                      child: Row(
                        children: [
                          Text(
                            "Images Security",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PushImagesPage()),
                        );
                      },
                      icon: Icon(
                        Icons.verified_user,
                        color: Colors.white,
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child: SmartRefresher(
                  controller: _refreshController,
                  enablePullUp: false,
                  enablePullDown: true,
                  child: buildCtn(),
                  header: WaterDropMaterialHeader(),
                  onRefresh: () async {
                    extractImages(googleId);
                    if (mounted) setState(() {});
                    _refreshController.refreshCompleted();
                  },
                ),
              ),
            ],
          ),
        ],
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
