import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:simple_edge_detection/edge_detection.dart' as sed;
import 'package:simple_edge_detection_example/cropping_preview.dart';

import 'camera_view.dart';
import 'image_view.dart';
import 'main.dart';

class Scan extends StatefulWidget {
  @override
  _ScanState createState() => _ScanState();
}

class _ScanState extends State<Scan> {
  CameraController? controller;
  late List<CameraDescription> cameras;
  String? imagePath;
  String? croppedImagePath;
  EdgeDetectionResult? edgeDetectionResult;
  Image? image;

  @override
  void initState() {
    super.initState();
    checkForCameras().then((value) {
      _initializeController();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          _getMainWidget(),
          _getBottomBar(),
        ],
      ),
    );
  }

  Widget _getMainWidget() {
    if (image != null) {
      return image!;
    }

    if (croppedImagePath != null) {
      return ImageView(imagePath: croppedImagePath);
    }

    if (imagePath == null && edgeDetectionResult == null) {
      return CameraView(controller: controller);
    }

    return ImagePreview(
      imagePath: imagePath,
      edgeDetectionResult: edgeDetectionResult,
    );
  }

  Future<void> checkForCameras() async {
    cameras = await availableCameras();
  }

  void _initializeController() {
    checkForCameras();
    if (cameras.length == 0) {
      log('No cameras detected');
      return;
    }

    controller = CameraController(cameras[0], ResolutionPreset.veryHigh, enableAudio: false);
    controller!.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Widget _getButtonRow() {
    if (imagePath != null) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: FloatingActionButton(
          child: Icon(Icons.check),
          onPressed: () async {
            if (croppedImagePath == null) {
              return await _processImage(imagePath, edgeDetectionResult);
            }

            setState(() {
              image = null;
              imagePath = null;
              edgeDetectionResult = null;
              croppedImagePath = null;
            });
          },
        ),
      );
    }

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      FloatingActionButton(
        foregroundColor: Colors.white,
        child: Icon(Icons.camera_alt),
        onPressed: onTakePictureButtonPressed,
      ),
      SizedBox(width: 16),
      FloatingActionButton(
        foregroundColor: Colors.white,
        child: Icon(Icons.image),
        onPressed: _onGalleryButtonPressed,
      ),
    ]);
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  Future<String?> takePicture() async {
    if (!controller!.value.isInitialized) {
      log('Error: select a camera first.');
      return null;
    }

    final Directory extDir = await getTemporaryDirectory();
    final String dirPath = '${extDir.path}/Pictures/flutter_test';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.jpg';

    if (controller!.value.isTakingPicture) {
      return null;
    }

    try {
      await controller!.takePicture();
    } on CameraException catch (e) {
      log(e.toString());
      return null;
    }
    return filePath;
  }

  Future _detectEdges(String? filePath) async {
    if (!mounted || filePath == null) {
      return;
    }

    setState(() {
      imagePath = filePath;
    });

    sed.EdgeDetectionResult result = await sed.EdgeDetector().detectEdges(filePath);

    print(result.topLeft);
    print(result.topRight);
    print(result.bottomLeft);
    print(result.bottomRight);

    setState(() {
      edgeDetectionResult = EdgeDetectionResult(
        topLeft: Offset(0.2, 0.3),
        topRight: Offset(0.8, 0.3),
        bottomLeft: Offset(0.2, 0.8),
        bottomRight: Offset(0.8, 0.8),
      );
    });
  }

  // late ui.Image _bitmap;
  // late Size _bitmapSize;

  // Future<ui.Image> croppedBitmap({ui.FilterQuality quality = FilterQuality.high}) async {
  //   final pictureRecorder = ui.PictureRecorder();
  //   Canvas(pictureRecorder).drawImage(
  //     _bitmap,
  //     ui.Offset(1, 1),
  //     Paint()..filterQuality = quality,
  //   );
  //   return await pictureRecorder.endRecording().toImage(cropSize.width.round(), cropSize.height.round());
  // }

  Future<void> _processImage(String? filePath, EdgeDetectionResult? edgeDetectionResult) async {
    if (!mounted || filePath == null) {
      return;
    }

    double rotation = 0;

    image = await cropController.croppedImage();

    //  image = await Image(
    //    image: UiImageProvider(await croppedBitmap(quality: FilterQuality.medium)),
    //    fit: BoxFit.contain,
    //  );

  //  bool result = await sed.EdgeDetector().processImage(filePath, edgeDetectionResult!, rotation);

    // if (result == false) {
    //   return;
    // }

    setState(() {
      imageCache.clearLiveImages();
      imageCache.clear();
      croppedImagePath = imagePath;
    });
  }

  void onTakePictureButtonPressed() async {
    String? filePath = (await ImagePicker().pickImage(source: ImageSource.camera))?.path;

    log('Picture saved to $filePath');

    await _detectEdges(filePath);
  }

  void _onGalleryButtonPressed() async {
    final filePath = (await ImagePicker().pickImage(source: ImageSource.gallery))?.path;

    log('Picture saved to $filePath');

    _detectEdges(filePath);
  }

  Padding _getBottomBar() {
    return Padding(
      padding: EdgeInsets.only(bottom: 32),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: _getButtonRow(),
      ),
    );
  }
}

class EdgeDetectionResult {
  EdgeDetectionResult({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  Offset topLeft;
  Offset topRight;
  Offset bottomLeft;
  Offset bottomRight;
}

class UiImageProvider extends ImageProvider<UiImageProvider> {
  /// The [ui.Image] from which the image will be fetched.
  final ui.Image image;

  const UiImageProvider(this.image);

  @override
  Future<UiImageProvider> obtainKey(ImageConfiguration configuration) => SynchronousFuture<UiImageProvider>(this);

  @override
  ImageStreamCompleter load(UiImageProvider key, DecoderCallback decode) =>
      OneFrameImageStreamCompleter(_loadAsync(key));

  Future<ImageInfo> _loadAsync(UiImageProvider key) async {
    assert(key == this);
    return ImageInfo(image: image);
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final UiImageProvider typedOther = other;
    return image == typedOther.image;
  }

  @override
  int get hashCode => image.hashCode;
}
