import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dart_sd_lib/dart_sd_lib.dart';
import 'package:image/image.dart' as img;

void main() {
  runApp(const MyApp());
}

/// ======================
/// TASK
/// ======================
class SdTask {
  final String modelPath;
  final String prompt;
  final SendPort sendPort;

  SdTask({
    required this.modelPath,
    required this.prompt,
    required this.sendPort,
  });
}

/// ======================
/// ISOLATE WORKER
/// ======================
Future<void> _sdWorker(SdTask task) async {
  final sd = StableDiffusion(modelPath: task.modelPath, nThreads: 4);

  task.sendPort.send({"type": "log", "data": sd.systemInfo});

  try {
    final sw = Stopwatch()..start();

    // final result = img.Image(width: 512, height: 512);

    final images = await sd.generateImg(task.prompt, sampleSteps: 1, width: 64, height: 64);
    final result = sd.toImage(images[0], 64, 64, 3);

    sw.stop();

    final debugString =
        "time: ${sw.elapsedMilliseconds}ms | ver: ${sd.version}";

    // envia imagem
    final pngBytes = Uint8List.fromList(img.encodePng(result!));
    task.sendPort.send({"type": "image", "data": pngBytes});

    // envia log
    task.sendPort.send({"type": "log", "data": debugString});
  } catch (e) {
    task.sendPort.send({"type": "log", "data": 'Isolate error: $e'});
  } finally {
    // sd.dispose();
  }
}

/// ======================
/// APP
/// ======================
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _response = '';
  String? _modelPath;
  bool _isLoading = false;
  bool _modelLoaded = false;

  Uint8List? _imageBytes;
  final List<String> _logs = [];

  final TextEditingController _textController = TextEditingController();

  StreamSubscription? _subscription;

  /// ======================
  /// PICK MODEL
  /// ======================
  Future<void> _pickModelFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['gguf', 'bin', 'model'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        setState(() {
          _modelPath = path;
          _modelLoaded = true;
          _response = 'Model selected successfully!';
        });
      }
    } catch (e) {
      setState(() {
        _response = 'Error selecting model: $e';
      });
    }
  }

  /// ======================
  /// GENERATE IMAGE
  /// ======================
  Future<void> _sendText() async {
    if (!_modelLoaded || _modelPath == null) {
      setState(() {
        _response = '⚠️ Load a model first!';
      });
      return;
    }

    final input = _textController.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _isLoading = true;
      _response = 'Generating...';
      _imageBytes = null;
      _logs.clear();
    });

    final receivePort = ReceivePort();

    try {
      _subscription = receivePort.listen((message) {
        if (message is Map) {
          final type = message["type"];
          final data = message["data"];

          setState(() {
            if (type == "image" && data is Uint8List) {
              _imageBytes = data;
              _response = 'Image generated successfully!';
              _isLoading = false;
            } else if (type == "log" && data is String) {
              _logs.add(data);
            }
          });

          if (type == "image") {
            receivePort.close();
            _subscription?.cancel();
          }
        } else if (message is String) {
          setState(() {
            _logs.add(message);
          });
        }
      });

      await Isolate.spawn(
        _sdWorker,
        SdTask(
          modelPath: _modelPath!,
          prompt: input,
          sendPort: receivePort.sendPort,
        ),
      );
    } catch (e) {
      setState(() {
        _response = 'Processing error on Isolate: $e';
        _isLoading = false;
      });
    }
  }

  /// ======================
  /// UI
  /// ======================
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Stable Diffusion Example')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pickModelFile,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Select a model'),
                ),

                if (_modelPath != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Model: ${_modelPath!.split('/').last}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],

                const SizedBox(height: 30),

                TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Prompt...',
                  ),
                ),

                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: _isLoading ? null : _sendText,
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Generate Image'),
                ),

                const SizedBox(height: 20),

                /// IMAGEM
                if (_imageBytes != null) ...[
                  const Text(
                    'Generated Image:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Image.memory(_imageBytes!, width: 512, height: 512),
                  const SizedBox(height: 20),
                ],

                /// LOGS / STRINGS
                if (_logs.isNotEmpty) ...[
                  const Text(
                    'Logs:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _logs.map((e) => Text(e)).toList(),
                  ),
                ],

                const SizedBox(height: 10),

                Text(
                  _response.isEmpty ? '(no response)' : _response,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
