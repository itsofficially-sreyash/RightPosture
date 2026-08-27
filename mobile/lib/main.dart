import 'package:flutter/material.dart';

import 'pose_camera_page.dart';

void main() => runApp(const RightPostureApp());

class RightPostureApp extends StatelessWidget {
  const RightPostureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PoseCameraPage(),
    );
  }
}
