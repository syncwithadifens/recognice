// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class ImagePage extends StatefulWidget {
  const ImagePage({super.key});

  @override
  State<ImagePage> createState() => _ImagePageState();
}

class KontainerModel {
  final String owner;
  final String serialNumber;
  final String checkDigit;

  KontainerModel({
    required this.owner,
    required this.serialNumber,
    required this.checkDigit,
  });
}

class _ImagePageState extends State<ImagePage> {
  File? imageFile;

  Future<KontainerModel> recognizeText(File? file) async {
    final InputImage inputImage = InputImage.fromFile(file!);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    // String text = recognizedText.text;
    // List<String> resblock = [];
    // List<String> resline = [];
    List<String> reselement = [];
    for (TextBlock block in recognizedText.blocks) {
      // final String text = block.text;
      // resblock.add(block.text);
      // debugPrint('block text: $text');
      for (TextLine line in block.lines) {
        // final String lineText = line.text;
        // resline.add(line.text);
        // Same getters as TextBlock
        for (TextElement element in line.elements) {
          String clear = element.text.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
          reselement.add(clear);
        }
      }
    }

    // debugPrint('blok text: $resblock');
    // debugPrint('line text: $resline');
    // debugPrint('element text: ${reselement[1]} ${reselement[2]}');
    textRecognizer.close();
    return KontainerModel(
        owner: reselement[0],
        serialNumber: reselement[1],
        checkDigit: reselement[2]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion(
        value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 20, top: 20),
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: imageFile != null ? null : Colors.yellow,
                    image: imageFile != null
                        ? DecorationImage(
                            image: FileImage(imageFile!), fit: BoxFit.cover)
                        : null),
              ),
            ),
            ElevatedButton.icon(
                onPressed: () async {
                  XFile? selectedImg = await ImagePicker()
                      .pickImage(source: ImageSource.gallery);
                  if (selectedImg != null) {
                    setState(() {
                      imageFile = File(selectedImg.path);
                    });
                  }
                },
                icon: const Icon(Icons.image),
                label: const Text('Pick')),
            FutureBuilder(
              future: recognizeText(imageFile),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 20,
                      ),
                      const Text(
                        'Detected Text from image:',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Text.rich(TextSpan(
                          text: "Owner: ",
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                          children: [
                            TextSpan(
                              text: snapshot.data!.owner,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w400, fontSize: 14),
                            )
                          ])),
                      Text.rich(TextSpan(
                          text: "Serial Number: ",
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                          children: [
                            TextSpan(
                              text: snapshot.data!.serialNumber,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w400, fontSize: 14),
                            )
                          ])),
                      Text.rich(TextSpan(
                          text: "Check Digit: ",
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                          children: [
                            TextSpan(
                              text: snapshot.data!.checkDigit,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w400, fontSize: 14),
                            )
                          ])),
                    ],
                  );
                }
                return Container();
              },
            ),
          ],
        ),
      ),
    );
  }
}
