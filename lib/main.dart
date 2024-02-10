import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:recognice/ui/image_page.dart';
import 'package:recognice/ui/scan_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ChooseMethod(),
    );
  }
}

late List<CameraDescription> cameras;
Future<void> getAllCamera() async {
  cameras = await availableCameras();
}

class ChooseMethod extends StatelessWidget {
  const ChooseMethod({super.key});

  @override
  Widget build(BuildContext context) {
    getAllCamera();
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const ImagePage(),
                      )),
                  icon: const Icon(Icons.image),
                  label: const Text('Pick Image')),
              const SizedBox(
                width: 20,
              ),
              ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ScanPage(
                          cameras: cameras,
                        ),
                      )),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Scanning'))
            ],
          ),
        ],
      ),
    );
  }
}
