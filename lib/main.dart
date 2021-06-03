import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

main() {
  runApp(CameraApp());
}

class CameraApp extends StatefulWidget {
  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  List<String> _fileNameList = [];

  Future<CameraController> useCamera() async {
    WidgetsFlutterBinding.ensureInitialized();
    List<CameraDescription> cameras = await availableCameras();
    CameraController controller =
        CameraController(cameras[0], ResolutionPreset.max);
    await controller.initialize();
    return controller;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: FutureBuilder<CameraController>(
          future: useCamera(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              print("나실행중");
              return CircularProgressIndicator();
            } else {
              print("나 이제 실행됨");
              return SafeArea(
                child: ListView(
                  children: [
                    Text(
                      "카메라 프리뷰",
                      style: TextStyle(fontSize: 30),
                    ),
                    SizedBox(
                      height: 300,
                      child: CameraPreview(snapshot.data!),
                    ),
                    Text(
                      "최근 사진 불러오기",
                      style: TextStyle(fontSize: 30),
                    ),
                    FutureBuilder<List<File>>(
                      future: getFileImages(),
                      builder: (context, snapshot) {
                        return SizedBox(
                            height: 300,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: snapshot.hasData
                                  ? snapshot.data!
                                      .map((e) => Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Image.file(e),
                                          ))
                                      .toList()
                                  : [],
                            ));
                      },
                    ),
                    ElevatedButton(
                        onPressed: () {
                          takePhoto(snapshot.data!);
                        },
                        child: Text("촬영")),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> takePhoto(CameraController controller) async {
    var uuid = Uuid();
    final _fileName = "${uuid.v1()}.jpg";

    final directory = await getApplicationDocumentsDirectory();

    XFile xFile = await controller.takePicture();
    await xFile.saveTo("${directory.path}/$_fileName");
    print("사진 찍힘 ${directory.path}/$_fileName");

    await _fileNameMemSave("${directory.path}/$_fileName");
  }

  // CAP1089117287322915032.jpg
  Future<List<File>> getFileImages() async {
    List<String> imageFileList = await _fileNameMemSelect();
    List<File> files = imageFileList.map((e) => File("$e")).toList();
    try {
      return files;
    } catch (e) {
      throw "파일 읽기 실패";
    }
  }

  _fileNameMemSave(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      _fileNameList = [..._fileNameList, "$value"];
      print(_fileNameList.toString());
    });
    await prefs.setStringList('fileNameList', _fileNameList);
  }

  Future<List<String>> _fileNameMemSelect() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList("fileNameList")!;
  }
}
