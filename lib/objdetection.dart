import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'package:translator/translator.dart';

class ObjectScreen extends StatefulWidget {
  final String imagePath;
  ObjectScreen(this.imagePath);

  @override
  _DetailScreenState createState() => new _DetailScreenState(imagePath);
}

class _DetailScreenState extends State<ObjectScreen> {
  _DetailScreenState(this.path);

  final String path;

  Size _imageSize;
  List<TextElement> _elements = [];
  String recognizedText = "Loading ...";
  String finalresult = "Loading";
  String texttranslation = '';

  void _initializeVision() async {
    final File imageFile = File(path);

    if (imageFile != null) {
      await _getImageSize(imageFile);
    }

    final FirebaseVisionImage visionImage =
        FirebaseVisionImage.fromFile(imageFile);

    final ImageLabeler textRecognizer = FirebaseVision.instance.imageLabeler();

    final List<ImageLabel> visionText =
        await textRecognizer.processImage(visionImage);
    String result = "";
    String obj = visionText[0].text;
    for (ImageLabel block in visionText) {
      result += block.text + "  " + '\n';
    }
    final translator = GoogleTranslator();

    Translation translatedtext =
        await translator.translate(result, from: 'en', to: 'hi');

    if (this.mounted) {
      setState(() {
        recognizedText = result;
        finalresult = obj;
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
      await flutterTts.setQueueMode(1);
      await flutterTts.setPitch(1.0);
      await flutterTts.speak(finalresult);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Object Detection"),
      ),
      body: _imageSize != null
          ? Stack(
              children: <Widget>[
                Center(
                  child: Container(
                    width: double.maxFinite,
                    color: Colors.black,
                    child: CustomPaint(
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
                              "Identified Objects",
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
