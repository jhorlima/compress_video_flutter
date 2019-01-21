import 'package:comprimir_videos/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission/permission.dart';

import 'package:comprimir_videos/screens/compress.dart';

void main() async {
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Permission.getPermissionStatus([
    PermissionName.Storage,
  ]);

  await Permission.requestPermissions([
    PermissionName.Storage,
  ]);

  runApp(MaterialApp(
    title: "Compressão de Vídeo",
    debugShowCheckedModeBanner: false,
    home: CompressScreen(),
  ));
}
