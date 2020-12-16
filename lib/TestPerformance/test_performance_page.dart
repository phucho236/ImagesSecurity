import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/material.dart';
import 'package:images_security/profile_user_provider.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:provider/provider.dart';

class TestPerformancePage extends StatefulWidget {
  @override
  _TestPerformancePageState createState() => _TestPerformancePageState();
}

class _TestPerformancePageState extends State<TestPerformancePage> {
  List<Asset> assets = [];
  bool isLoading = false;
  int lengthProcess = 0;

  String googleId;

  int timeStampStart2;

  int timeStampStart3;

  int timeDone2 = 0;
  int timeDone3 = 0;
  @override
  void initState() {
    // TODO: implement initState
    Future.delayed(Duration.zero, () {
      googleId = context.read<ProfileUserProvider>().profileUser;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              loadAssets();
            },
            icon: Icon(
              Icons.add_photo_alternate,
              color: Colors.white,
            ),
          ),
        ],
        title: const Text('Test Performance'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Center(
                              child: Text(
                                  timeDone2.toString() + " Milliseconds"))),
                      Expanded(
                          child: Center(
                              child: Text(
                                  timeDone3.toString() + " Milliseconds"))),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                          child: FlatButton(
                        onPressed: () {
                          if (assets.length <= 0) {
                            _showMyDialog("Notify", "Images Is Empty");
                          } else {
                            setState(() {
                              lengthProcess = 0;
                              isLoading = true;
                            });
                            _start();
                          }
                        },
                        child: Text("Multi Thread\nself-generated"),
                      )),
                      Expanded(
                          child: FlatButton(
                        onPressed: () {
                          if (assets.length <= 0) {
                            _showMyDialog("Notify", "Images Is Empty");
                          } else {
                            setState(() {
                              lengthProcess = 0;
                              isLoading = true;
                            });
                            _single();
                          }
                        },
                        child: Text("Single Thread"),
                      )),
                    ],
                  )
                ],
              ),
            ),
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
    });
  }

  void _handleMessage(dynamic data) {
    lengthProcess = lengthProcess + 1;
    if (lengthProcess == assets.length) {
      setState(() {
        timeDone2 = DateTime.now().millisecondsSinceEpoch - timeStampStart2;
        isLoading = false;
      });
      _showMyDialog("Post Success", "Notify").then((value) {});
    }
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
    print("Thread " + threadParams.thread.toString() + " Done");
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

  void _single() async {
    setState(() {
      timeStampStart3 = DateTime.now().millisecondsSinceEpoch;
    });
    for (int i = 0; i < assets.length; i++) {
      ByteData a = await assets[i].getByteData(quality: 100);
      var buffer = a.buffer;
      var m = base64.encode(Uint8List.view(buffer));
      String token;

      // Create a json web token
      final jwt = JWT(
        {
          'ver': 0001,
          'NameImage': assets[i].name,
          'Base64': m,
        },
        issuer: 'https://github.com/jonasroussel/jsonwebtoken',
      );
      // Sign it
      token = jwt.sign(SecretKey(googleId));
      print(token);
    }
    setState(() {
      timeDone3 = DateTime.now().millisecondsSinceEpoch - timeStampStart3;
      isLoading = false;
    });
    _showMyDialog("Post Success", "Notify").then((value) {});
  }

  void _start() async {
    setState(() {
      timeStampStart2 = DateTime.now().millisecondsSinceEpoch;
    });
    for (int i = 0; i < assets.length; i++) {
      print("thread " + i.toString() + "Start");
      ReceivePort _receivePort = new ReceivePort();
      ByteData a = await assets[i].getByteData(quality: 100);
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
