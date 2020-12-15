import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:images_security/FiresStore/fires_store.dart';
import 'package:images_security/profile_user_provider.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:provider/provider.dart';

class PushImagesPage extends StatefulWidget {
  @override
  _PushImagesPageState createState() => _PushImagesPageState();
}

class _PushImagesPageState extends State<PushImagesPage> {
  List<Asset> assets = [];
  List<String> assetsToken = [];
  FiresStore firesStore = new FiresStore();

  int lengthProcess = 0;
  bool onDone = false;
  bool isLoading = false;
  String _message = '';
  static String googleId;
  void _handleMessage(dynamic data) {
    lengthProcess = lengthProcess + 1;
    assetsToken.add(data);
    if (lengthProcess == assets.length) {
      firesStore.pushAssetsToken(googleId, assetsToken).then((value) {
        _showMyDialog("Post Success", "Notify").then((value) {
          Navigator.pop(context);
        });
      });
    }
    // setState(() {
    //   _message = data;
    // });
  }

  static void _isolateHandler(ThreadParams threadParams) async {
    heavyOperation(threadParams);
  }

  static void heavyOperation(ThreadParams threadParams) async {
    var buffer = threadParams.byteDataImage.buffer;
    var m = base64.encode(Uint8List.view(buffer));
    String token;

    // Create a json web token
    final jwt = JWT(
      {
        'ver': 0001,
        'NameImage': threadParams.nameImage,
        'Base64': m,
      },
      issuer: 'https://github.com/jonasroussel/jsonwebtoken',
    );
    // Sign it
    token = jwt.sign(SecretKey(threadParams.secretKey));
    threadParams.sendPort.send(token);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(Duration.zero, () {
      googleId = context.read<ProfileUserProvider>().profileUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.add_photo_alternate,
              color: Colors.white,
            ),
            onPressed: loadAssets,
          ),
          IconButton(
            icon: Icon(
              Icons.send,
              color: Colors.white,
            ),
            onPressed: () {
              if (assets.length <= 0) {
                _showMyDialog("Notify", "Images Is Empty");
              } else {
                setState(() {
                  isLoading = true;
                });
                _start();
              }
            },
          )
        ],
        title: const Text('Push Images'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                Expanded(
                    child: ListView(
                  children: <Widget>[
                    Text(
                      "ABCD" + _message,
                      style: TextStyle(
                        fontSize: 20.0,
                        color: Colors.green,
                      ),
                    ),
                  ],
                )),
                assets.length > 0
                    ? Expanded(
                        child: buildGridView(),
                      )
                    : Expanded(
                        child: Center(
                          child: Text("Please Choose Images"),
                        ),
                      )
              ],
            ),
    );
  }

  Widget buildGridView() {
    return GridView.count(
      crossAxisCount: 3,
      children: List.generate(assets.length, (index) {
        Asset asset = assets[index];
        return AssetThumb(
          asset: asset,
          width: 300,
          height: 300,
        );
      }),
    );
  }

  Future<void> loadAssets() async {
    List<Asset> resultList = [];
    try {
      resultList = await MultiImagePicker.pickImages(
        maxImages: 300,
        enableCamera: true,
        selectedAssets: assets,
        cupertinoOptions: CupertinoOptions(takePhotoIcon: "chat"),
        materialOptions: MaterialOptions(
          actionBarTitle: "Images Picker".toUpperCase(),
          allViewTitle: "All Photos",
          useDetailsView: false,
          selectCircleStrokeColor: "#000000",
        ),
      );
    } on Exception catch (e) {
      print(e.toString());
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      assets = resultList;
      onDone = false;
    });
  }

  Future<void> _showMyDialog(String title, String content) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title.toUpperCase()),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(content),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('YES'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _start() async {
    for (int i = 0; i < assets.length; i++) {
      print("thread " + i.toString() + "Start");
      ReceivePort _receivePort = new ReceivePort();
      ByteData a = await assets[i].getByteData(quality: 10);
      ThreadParams threadParams = ThreadParams(
          byteDataImage: a,
          secretKey: googleId,
          sendPort: _receivePort.sendPort,
          thread: i,
          nameImage: assets[i].name);
      Isolate _isolate = await Isolate.spawn(
        _isolateHandler,
        threadParams,
      );
      _receivePort.listen(_handleMessage, onDone: () {
        print("thread " + i.toString() + "Done");
        _receivePort.close();
        _isolate.kill(priority: Isolate.immediate);
        _isolate = null;
      });
    }
  }
}

class ThreadParams {
  ThreadParams(
      {this.byteDataImage,
      this.sendPort,
      this.thread,
      this.secretKey,
      this.nameImage});
  int thread;
  ByteData byteDataImage;
  SendPort sendPort;
  String secretKey;
  String nameImage;
}
