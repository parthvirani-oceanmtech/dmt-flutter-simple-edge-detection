import 'package:flutter/material.dart';
import 'package:simple_edge_detection_example/image_cropper/src/crop_controller.dart';

import 'scan.dart';

CropController cropController = CropController(
  defaultCrop: Rect.fromLTRB(0.05, 0.05, 0.95, 0.95),
);

void main() {
  runApp(EdgeDetectionApp());
}

class EdgeDetectionApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scan(),
    );
  }
}
