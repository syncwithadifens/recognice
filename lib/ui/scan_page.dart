// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

import '../utils/box.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({
    Key? key,
    required this.cameras,
  }) : super(key: key);
  final List<CameraDescription> cameras;

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  late CameraController controller;
  bool isBusy = false;
  dynamic objectDetector;
  late Size size;
  dynamic _scanResults;
  CameraImage? img;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
    objectDetector.close();
  }

  // Future<String> getModelPath(String asset) async {
  //   final path = '${(await getApplicationSupportDirectory()).path}/$asset';
  //   await Directory(dirname(path)).create(recursive: true);
  //   final file = File(path);
  //   if (!await file.exists()) {
  //     final byteData = await rootBundle.load(asset);
  //     await file.writeAsBytes(byteData.buffer
  //         .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
  //   }
  //   return file.path;
  // }

  // loadModel() async {
  //   final modelPath = await getModelPath('assets/ml/best_float32.tflite');
  //   final options = LocalObjectDetectorOptions(
  //     mode: DetectionMode.stream,
  //     modelPath: modelPath,
  //     classifyObjects: true,
  //     multipleObjects: true,
  //   );
  //   objectDetector = ObjectDetector(options: options);
  // }

  initializeCamera() async {
    const mode = DetectionMode.stream;
    final options = ObjectDetectorOptions(
        mode: mode, classifyObjects: true, multipleObjects: true);
    objectDetector = ObjectDetector(options: options);
    // loadModel();

    controller = CameraController(widget.cameras[0], ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888);
    await controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      controller.startImageStream((image) => {
            if (!isBusy)
              {isBusy = true, img = image, doObjectDetectionOnFrame()}
          });
    });
  }

  doObjectDetectionOnFrame() async {
    var frameImg = _inputImageFromCameraImage(img!);
    List<DetectedObject> objects = await objectDetector.processImage(frameImg);
    setState(() {
      _scanResults = objects;
      isBusy = false;
    });
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = widget.cameras[0];
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[controller.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    // get image format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    // validate format depending on platform
    // only supported formats:
    // * nv21 for Android
    // * bgra8888 for iOS
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    // since format is constraint to nv21 or bgra8888, both only have one plane
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    // compose InputImage using bytes
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
  }

//Show rectangles around detected objects
  Widget buildResult() {
    if (_scanResults == null || !controller.value.isInitialized) {
      return const Text('');
    }

    final Size imageSize = Size(
      controller.value.previewSize!.height,
      controller.value.previewSize!.width,
    );
    CustomPainter painter = ObjectDetectorPainter(imageSize, _scanResults);
    return CustomPaint(
      painter: painter,
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> content = [];
    size = MediaQuery.of(context).size;
    content.add(
      Positioned(
        top: 0.0,
        left: 0.0,
        width: size.width,
        height: size.height,
        child: Container(
          child: (controller.value.isInitialized)
              ? AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: CameraPreview(controller),
                )
              : Container(),
        ),
      ),
    );

    content.add(
      Positioned(
          top: 0.0,
          left: 0.0,
          width: size.width,
          height: size.height,
          child: buildResult()),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Object detector"),
      ),
      backgroundColor: Colors.black,
      body: Container(
          margin: const EdgeInsets.only(top: 0),
          color: Colors.black,
          child: Stack(
            children: content,
          )),
    );
  }
}
