import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/material.dart';

class PerformancePage1 extends StatefulWidget {
  final String title = "Isolates Demo";

  @override
  _PerformancePage1State createState() => _PerformancePage1State();
}

class _PerformancePage1State extends State<PerformancePage1> {
  //
  Isolate _isolate;
  bool _running = false;
  bool _paused = false;
  String _message = '';
  String _threadStatus = '';
  ReceivePort _receivePort;
  Capability _capability;

  void _start() async {
    if (_running) {
      return;
    }
    setState(() {
      _running = true;
      _message = 'Starting...';
      _threadStatus = 'Running...';
    });
    _receivePort = ReceivePort();
    ThreadParams threadParams = ThreadParams(2000, _receivePort.sendPort);
    _isolate = await Isolate.spawn(
      _isolateHandler,
      threadParams,
    );
    _receivePort.listen(_handleMessage, onDone: () {
      setState(() {
        _threadStatus = 'Stopped';
      });
    });
  }

  void _pause() {
    if (null != _isolate) {
      _paused ? _isolate.resume(_capability) : _capability = _isolate.pause();
      setState(() {
        _paused = !_paused;
        _threadStatus = _paused ? 'Paused' : 'Resumed';
      });
    }
  }

  void _stop() {
    if (null != _isolate) {
      setState(() {
        _running = false;
      });
      _receivePort.close();
      _isolate.kill(priority: Isolate.immediate);
      _isolate = null;
    }
  }

  void _handleMessage(dynamic data) {
    setState(() {
      _message = data;
    });
  }

  static void _isolateHandler(ThreadParams threadParams) async {
    heavyOperation(threadParams);
  }

  static void heavyOperation(ThreadParams threadParams) async {
    int count = 10000;
    while (true) {
      int sum = 0;
      for (int i = 0; i < count; i++) {
        sum += await computeSum(1000);
      }
      count += threadParams.val;
      threadParams.sendPort.send(sum.toString());
    }
  }

  static Future<int> computeSum(int num) {
    Random random = Random();
    return Future(() {
      int sum = 0;
      for (int i = 0; i < num; i++) {
        sum += random.nextInt(100);
      }
      return sum;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new Container(
        padding: EdgeInsets.all(20.0),
        alignment: Alignment.center,
        child: new Column(
          children: <Widget>[
            !_running
                ? OutlineButton(
                    child: Text('Start Isolate'),
                    onPressed: () {
                      _start();
                    },
                  )
                : SizedBox(),
            _running
                ? OutlineButton(
                    child: Text(_paused ? 'Resume Isolate' : 'Pause Isolate'),
                    onPressed: () {
                      _pause();
                    },
                  )
                : SizedBox(),
            _running
                ? OutlineButton(
                    child: Text('Stop Isolate'),
                    onPressed: () {
                      _stop();
                    },
                  )
                : SizedBox(),
            SizedBox(
              height: 20.0,
            ),
            Text(
              _threadStatus,
              style: TextStyle(
                fontSize: 20.0,
              ),
            ),
            SizedBox(
              height: 20.0,
            ),
            Text(
              _message,
              style: TextStyle(
                fontSize: 20.0,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ThreadParams {
  ThreadParams(this.val, this.sendPort);
  int val;
  SendPort sendPort;
}
