import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final double _videoLimit = Duration(seconds: 15).inMilliseconds.toDouble();

  CameraController controller;

  String _videoPath;
  double _progessVideo = 0.0;
  double _videoTime = 0.0;

  bool _loopActive = false;
  bool _buttonPressed = false;
  bool isRecordingVideo = false;

  Future cameraInit;

  @override
  initState() {
    super.initState();
    cameraInit = cameraInitialize();
  }

  @override
  dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          FutureBuilder(
            future: cameraInit,
            builder: (BuildContext context, AsyncSnapshot camera) {

              if (!camera.hasData) {
                return Text("A camera ainda não foi iniciada!");
              }

              final Size sizeScreen = MediaQuery.of(context).size;

              final double maxWidth = sizeScreen.width;
              final double maxHeight = sizeScreen.height;

              double scale = 1.0 + (maxWidth / maxHeight);

              return Transform.scale(
                scale: scale,
                child: AspectRatio(
                  aspectRatio: controllerAspectRatio(controller),
                  child: CameraPreview(controller),
                ),
              );
            },
          ),
          Container(
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 35.0),
            child: Text(
              "Restante: ${msToSecond(_videoLimit - _videoTime)}",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontSize: 24.0,
              ),
            ),
          ),
          Container(
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.only(bottom: 25.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    SizedBox(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.all(Radius.circular(115.0)),
                        ),
                      ),
                      height: 115.0,
                      width: 115.0,
                    ),
                    SizedBox(
                      child: CircularProgressIndicator(
                        value: _progessVideo,
                        strokeWidth: 10.0,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.purple.withOpacity(0.7),
                        ),
                      ),
                      height: 105.0,
                      width: 105.0,
                    ),
                    SizedBox(
                      height: 95.0,
                      width: 95.0,
                      child: Listener(
                        onPointerDown: (details) {
                          _buttonPressed = true;
                          _increaseCounterWhilePressed();
                        },
                        onPointerUp: (details) {
                          _buttonPressed = false;
                        },
                        child: FloatingActionButton(
                          elevation: 2.0,
                          onPressed: () => null,
                          child: Icon(
                            Icons.videocam,
                            color: Colors.purple,
                            size: 42.0,
                          ),
                          backgroundColor: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _increaseCounterWhilePressed() async {
    // make sure that only one loop is active
    if (controller.value.isRecordingVideo || _loopActive)
      return;

    _loopActive = true;

    isRecordingVideo = controller.value.isRecordingVideo;

    await controller.startVideoRecording(_videoPath);

    while (_buttonPressed && _videoTime <= _videoLimit) {

      const fps = 150;

      setState(() {
        _videoTime += fps;
        _progessVideo = _videoTime / _videoLimit;
        print(_progessVideo);
      });
      // wait a bit
      await Future.delayed(Duration(milliseconds: fps));
    }

    await controller.stopVideoRecording();

    _loopActive = false;

    setState(() {
      _progessVideo = _videoTime = 0.0;
    });

    print("Gravou!");
  }

  Future<List<CameraDescription>> get cameras async {
    return await availableCameras();
  }

  Future<CameraDescription> cameraInitialize() async {

    List<CameraDescription> cameras = await this.cameras;

//    CameraDescription camera = cameras.firstWhere((CameraDescription camera) {
//      return camera.lensDirection == CameraLensDirection.front;
//    });

    CameraDescription camera = cameras.first;

    this.controller = CameraController(camera, ResolutionPreset.high);

    if (controller.value.isInitialized) {
      return camera;
    }

    await controller.initialize();

    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Movies/flutter_test';
    await Directory(dirPath).create(recursive: true);
    _videoPath = '$dirPath/${timestamp()}.mp4';
    print(dirPath);

    return camera;
  }

  double controllerAspectRatio(CameraController controller) {
    return controller.value.aspectRatio;
  }

  String msToSecond(num ms) {
    Duration duration = Duration(milliseconds:ms.toInt());
    return duration.inSeconds.toString().padLeft(2, "0");
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();
}
