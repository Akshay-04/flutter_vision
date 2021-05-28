import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'package:translator/translator.dart';

class DetailScreen extends StatefulWidget {
  final String imagePath;
  DetailScreen(this.imagePath);

  @override
  _DetailScreenState createState() => new _DetailScreenState(imagePath);
}

class _DetailScreenState extends State<DetailScreen> {
  _DetailScreenState(this.path);

  final String path;

  Size _imageSize;
  List<TextElement> _elements = [];
  String recognizedText = "Loading ...";
  String texttranslation = '';

  void _initializeVision() async {
    final File imageFile = File(path);

    if (imageFile != null) {
      await _getImageSize(imageFile);
    }

    final FirebaseVisionImage visionImage =
        FirebaseVisionImage.fromFile(imageFile);

    final TextRecognizer textRecognizer =
        FirebaseVision.instance.textRecognizer();

    final VisionText visionText =
        await textRecognizer.processImage(visionImage);

    String textfound = "";
    for (TextBlock block in visionText.blocks) {
      for (TextLine line in block.lines) {
        textfound += line.text + '\n';
        for (TextElement element in line.elements) {
          _elements.add(element);
        }
      }
    }
    final translator = GoogleTranslator();

    Translation translatedtext =
        await translator.translate(textfound, from: 'en', to: 'hi');

    if (this.mounted) {
      setState(() {
        recognizedText = textfound;
        texttranslation = translatedtext.text;
      });
    }
  }

  Future<void> _getImageSize(File imageFile) async {
    final Completer<Size> completer = Completer<Size>();

    final Image image = Image.file(imageFile);
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        ));
      }),
    );

    final Size imageSize = await completer.future;
    setState(() {
      _imageSize = imageSize;
    });
  }

  @override
  void initState() {
    _initializeVision();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    FlutterTts flutterTts = FlutterTts();
    Future speaktext() async {
      await flutterTts.setLanguage("hi-IN");

      await flutterTts.setSpeechRate(1.0);

      await flutterTts.setVolume(1.0);

      await flutterTts.setPitch(1.0);
      await flutterTts.setQueueMode(1);
      await flutterTts.speak(recognizedText);
      await flutterTts.speak(texttranslation);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Text Detection"),
      ),
      body: _imageSize != null
          ? Stack(
              children: <Widget>[
                Center(
                  child: Container(
                    width: double.maxFinite,
                    color: Colors.black,
                    child: CustomPaint(
                      foregroundPainter:
                          TextDetectorPainter(_imageSize, _elements),
                      child: AspectRatio(
                        aspectRatio: _imageSize.aspectRatio,
                        child: Image.file(
                          File(path),
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Card(
                    elevation: 8,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          ElevatedButton(
                              onPressed: () => speaktext(),
                              child: Text('Speak')),
                          Row(),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              "Identified text",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            height: 60,
                            child: SingleChildScrollView(
                              child: Text(
                                recognizedText,
                              ),
                            ),
                          ),
                          Container(
                            height: 60,
                            child: SingleChildScrollView(
                              child: Text(
                                texttranslation,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Container(
              color: Colors.black,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
    );
  }
}

class TextDetectorPainter extends CustomPainter {
  TextDetectorPainter(this.absoluteImageSize, this.elements);

  final Size absoluteImageSize;
  final List<TextElement> elements;

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / absoluteImageSize.width;
    final double scaleY = size.height / absoluteImageSize.height;

    Rect scaleRect(TextContainer container) {
      return Rect.fromLTRB(
        container.boundingBox.left * scaleX,
        container.boundingBox.top * scaleY,
        container.boundingBox.right * scaleX,
        container.boundingBox.bottom * scaleY,
      );
    }

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.red
      ..strokeWidth = 2.0;

    for (TextElement element in elements) {
      canvas.drawRect(scaleRect(element), paint);
    }
  }

  @override
  bool shouldRepaint(TextDetectorPainter oldDelegate) {
    return true;
  }
}
