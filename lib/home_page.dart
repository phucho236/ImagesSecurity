import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/material.dart';
import 'package:images_security/FiresStore/fires_store.dart';
import 'package:images_security/Model/data_assets_model.dart';
import 'package:images_security/TestPerformance/test_performance_page.dart';
import 'package:images_security/profile_user_provider.dart';
import 'package:images_security/push_images_page.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Asset> images = [];
  List<dynamic> base64Images = [];
  FiresStore firesStore = new FiresStore();
  String googleId;
  bool onLoading = true;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    Future.delayed(Duration.zero, () {
      googleId = context.read<ProfileUserProvider>().profileUser;
      extractImages(googleId);
    });
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
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => PerformancePage1()),
              // );
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
      body: onLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                Expanded(
                  child: buildGridView(),
                )
              ],
            ),
    );
  }

  Widget buildGridView() {
    return GridView.count(
      crossAxisCount: 3,
      children: List.generate(base64Images.length, (index) {
        Uint8List asset = base64.decode(base64Images[index]);
        return Image.memory(
          asset,
          width: 300,
          height: 300,
        );
      }),
    );
  }

  Future<void> loadAssets() async {
    List<Asset> resultList = [];
    String error = 'No Error Dectected';

    try {
      resultList = await MultiImagePicker.pickImages(
        maxImages: 300,
        enableCamera: true,
        selectedAssets: images,
        cupertinoOptions: CupertinoOptions(takePhotoIcon: "chat"),
        materialOptions: MaterialOptions(
          actionBarColor: "#abcdef",
          actionBarTitle: "Example App",
          allViewTitle: "All Photos",
          useDetailsView: false,
          selectCircleStrokeColor: "#000000",
        ),
      );
    } on Exception catch (e) {
      error = e.toString();
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      images = resultList;
    });
  }

  extractImages(googleId) async {
    List<dynamic> tmp = [];
    await firesStore.getAssetsToken(googleId).then((value) async {
      value.forEach((element) {
        try {
          // Verify a token
          final jwt = JWT.verify(element, SecretKey(googleId));
          PayLoad payLoad = PayLoad.fromJson(jwt.payload);
          tmp.add(payLoad.base64);
        } on JWTExpiredError {
          print('jwt expired');
        } on JWTError catch (ex) {
          print(ex.message); // ex: invalid signature
        }
      });
    });
    setState(() {
      base64Images = tmp;
      onLoading = false;
    });
  }
}
