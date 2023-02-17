import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:simple_edge_detection_example/image_cropper/src/crop_controller.dart';
import 'package:simple_edge_detection_example/image_cropper/src/crop_image.dart';
import 'package:simple_edge_detection_example/scan.dart';

import 'edge_detection_shape/edge_detection_shape.dart';
import 'main.dart';

class ImagePreview extends StatefulWidget {
  ImagePreview({this.imagePath, this.edgeDetectionResult});

  final String? imagePath;
  final EdgeDetectionResult? edgeDetectionResult;

  @override
  _ImagePreviewState createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview> {
  GlobalKey imageWidgetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    cropController = CropController(
      defaultCrop: Rect.fromLTRB(0.05, 0.05, 0.95, 0.95),
    );
  }

  @override
  Widget build(BuildContext mainContext) {
    return Center(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Center(child: Text('Loading ...')),
          // CropImage(
          //   alwaysShowThirdLines: true,
          //   controller: cropController,
          //   image: Image.file(File(widget.imagePath!), fit: BoxFit.contain, key: imageWidgetKey),
          // ),
          Image.file(File(widget.imagePath!), fit: BoxFit.contain, key: imageWidgetKey),
          FutureBuilder<ui.Image>(
              future: loadUiImage(widget.imagePath!),
              builder: (BuildContext context, AsyncSnapshot<ui.Image> snapshot) {
                return _getEdgePaint(snapshot, context);
              }),
        ],
      ),
    );
  }

  Widget _getEdgePaint(AsyncSnapshot<ui.Image> imageSnapshot, BuildContext context) {
    if (imageSnapshot.connectionState == ConnectionState.waiting) return Container();

    if (imageSnapshot.hasError) return Text('Error: ${imageSnapshot.error}');

    if (widget.edgeDetectionResult == null) return Container();

    final keyContext = imageWidgetKey.currentContext;

    if (keyContext == null) {
      return Container();
    }

    final box = keyContext.findRenderObject() as RenderBox;

    return EdgeDetectionShape(
      originalImageSize: Size(imageSnapshot.data!.width.toDouble(), imageSnapshot.data!.height.toDouble()),
      renderedImageSize: Size(box.size.width, box.size.height),
      edgeDetectionResult: widget.edgeDetectionResult,
    );
  }

  Future<ui.Image> loadUiImage(String imageAssetPath) async {
    final Uint8List data = await File(imageAssetPath).readAsBytes();
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(Uint8List.view(data.buffer), (ui.Image image) {
      return completer.complete(image);
    });
    return completer.future;
  }
}
