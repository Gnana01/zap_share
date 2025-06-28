import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';

class HttpFileShareScreen extends StatefulWidget {
  const HttpFileShareScreen({super.key});

  @override
  _HttpFileShareScreenState createState() => _HttpFileShareScreenState();
}

class _HttpFileShareScreenState extends State<HttpFileShareScreen>
    with SingleTickerProviderStateMixin {
  HttpServer? _server;
  String? _localIp;
  String? _filePath;
  String? _fileName;
  int _downloadCount = 0;
  bool _isLoading = false;
  bool _isSharing = false;
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _getLocalIp();
    _blinkController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  Future<void> _getLocalIp() async {
    final info = NetworkInfo();
    String? ip = await info.getWifiIP();
    setState(() {
      _localIp = ip;
    });
  }

  Future<void> _startServer() async {
    setState(() {
      _isLoading = true;
      _isSharing = true;
    });
    _server?.close();
    _server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);

    _server!.listen((HttpRequest request) async {
      if (_filePath != null) {
        File file = File(_filePath!);
        request.response.headers.add(HttpHeaders.contentTypeHeader, "application/octet-stream");
        request.response.headers.add('Content-Disposition', 'attachment; filename="$_fileName"');
        await request.response.addStream(file.openRead());
        await request.response.close();
        setState(() => _downloadCount++);
      }
    });

    setState(() => _isLoading = false);
  }

  Future<void> _selectFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _filePath = result.files.single.path;
        _fileName = result.files.single.name;
      });
      _startServer();
    }
  }

  @override
  void dispose() {
    _server?.close();
    _blinkController.dispose();
    super.dispose();
  }

  void _copyLink() {
    if (_localIp != null) {
      Clipboard.setData(ClipboardData(text: "http://$_localIp:8080"));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Link copied to clipboard!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String? fileShareUrl = _localIp != null ? "http://$_localIp:8080" : null;

    return Scaffold(
      appBar: AppBar(
        title: Text("ZapShare"),
        actions: [
          if (_isSharing)
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: FadeTransition(
                opacity: _blinkController,
                child: Icon(Icons.wifi, color: Colors.green),
              ),
            ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) CircularProgressIndicator(),
              if (fileShareUrl != null)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  elevation: 4,
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.0),
                          child: QrImageView(
                            data: fileShareUrl,
                            version: QrVersions.auto,
                            size: 300.0,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton.icon(
                          
                          onPressed: _copyLink,
                          icon: Icon(Icons.copy),
                          label: Text("Copy Link"),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_filePath != null)
                Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: AnimatedOpacity(
                    duration: Duration(milliseconds: 500),
                    opacity: 1.0,
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      elevation: 4,
                      color: Colors.white,
                      child: ListTile(
                        leading: Icon(Icons.insert_drive_file, color: Colors.black),
                        title: Text(_fileName ?? "Unknown File", style: TextStyle(color: Colors.black)),
                        subtitle: Text("Tap to reselect", style: TextStyle(color: Colors.black54)),
                        onTap: _selectFile,
                      ),
                    ),
                  ),
                ),
              if (_downloadCount > 0)
                Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Column(
                    children: [
                      Text("Downloads: $_downloadCount", style: TextStyle(color: Colors.white)),
                      SizedBox(height: 5),
                      LinearProgressIndicator(value: _downloadCount / 10),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _selectFile,
        backgroundColor: Colors.blueAccent,
        child: Icon(Icons.attach_file),
      ),
    );
  }
}