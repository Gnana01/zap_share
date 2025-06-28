import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FileReceiverScreen extends StatefulWidget {
  final String fileName;
  final String url;

  const FileReceiverScreen({
    super.key,
    required this.fileName,
    required this.url,
  });

  @override
  _FileReceiverScreenState createState() => _FileReceiverScreenState();
}



class _FileReceiverScreenState extends State<FileReceiverScreen> {
  final TextEditingController _urlController = TextEditingController();
  double _progress = 0;
  bool _isDownloading = false;
  String? _statusMessage;

  Future<void> _downloadFile(String url) async {
  try {
    setState(() {
      _isDownloading = true;
      _progress = 0;
      _statusMessage = null;
    });

    final client = http.Client();
    final request = http.Request('GET', Uri.parse(url));
    final response = await client.send(request);

    final totalBytes = response.contentLength ?? 0;
    int receivedBytes = 0;

    final fileName = widget.fileName; // Use this from widget



    final dir = Directory('/storage/emulated/0/Download');
    if (!await dir.exists()) await dir.create(recursive: true);
    final filePath = '${dir.path}/${widget.fileName}';
    final file = File(filePath);
    final sink = file.openWrite();


    response.stream.listen(
      (chunk) {
        receivedBytes += chunk.length;
        sink.add(chunk);
        setState(() {
          _progress = receivedBytes / totalBytes;
        });
      },
      onDone: () async {
        await sink.close();
        setState(() {
          _isDownloading = false;
          _statusMessage = "Download complete!";
        });
        OpenFile.open(file.path);
      },
      onError: (e) async {
        await sink.close();
        setState(() {
          _isDownloading = false;
          _statusMessage = "Error during download: $e";
        });
      },
      cancelOnError: true,
    );
  } catch (e) {
    setState(() {
      _isDownloading = false;
      _statusMessage = "Download failed: $e";
    });
  }
}
Future<void> requestPermissions() async {
  if (await Permission.manageExternalStorage.isGranted == false) {
    await Permission.manageExternalStorage.request();
  }

  final status = await Permission.storage.request();
  if (!status.isGranted) {
    throw Exception("Storage permission not granted");
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Receive File"),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: "Enter File URL",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            _isDownloading
                ? Column(
                    children: [
                      LinearProgressIndicator(
                        value: _progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade300,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.yellow.shade700),
                      ),
                      SizedBox(height: 8),
                      Text("Downloading... ${(100 * _progress).toStringAsFixed(1)}%"),
                    ],
                  )
                : ElevatedButton.icon(
                    onPressed: () {
                      final url = _urlController.text.trim();
                      if (url.isNotEmpty) {
                        _downloadFile(url);
                      }
                    },
                    icon: Icon(Icons.download),
                    label: Text("Download File"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow.shade700,
                      foregroundColor: Colors.black,
                    ),
                  ),
            if (_statusMessage != null) ...[
              SizedBox(height: 16),
              Text(
                _statusMessage!,
                style: TextStyle(
                  color: _statusMessage!.contains("complete")
                      ? Colors.green
                      : Colors.red,
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
