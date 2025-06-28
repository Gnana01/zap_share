import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _selectedFile;
  String? _downloadUrl;
  double _uploadProgress = 0.0;
  bool _isUploading = false;

  /// Picks a file using File Picker
  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  /// Starts the foreground service for file upload
  
  /// Uploads file to Cloudinary
  Future<void> uploadFile() async {
    if (_selectedFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    

    final cloudName = "dboejgdon"; // Your Cloudinary cloud name
    final uploadPreset = "Zap-Share"; // Your Cloudinary preset
    final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/raw/upload");
    final mimeType = lookupMimeType(_selectedFile!.path) ?? "application/octet-stream";

    var request = http.MultipartRequest("POST", url)
      ..fields["upload_preset"] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath(
        "file",
        _selectedFile!.path,
        contentType: MediaType.parse(mimeType),
      ));

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          _downloadUrl = jsonResponse["secure_url"];
        });
      } else {
        print("❌ Upload failed: ${response.reasonPhrase}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed. Please try again.")),
        );
      }
    } catch (e) {
      print("❌ Error during upload: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e")),
      );
    }

    setState(() {
      _isUploading = false;
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Zap Cloud Share",style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.black,
  
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_selectedFile == null)
                Text("No file selected", style: TextStyle(fontSize: 16, color: Colors.white))
              else
                Card(
                  color: Colors.yellow[700],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  elevation: 4,
                  child: ListTile(
                    leading: Icon(Icons.insert_drive_file, color: Colors.black),
                    title: Text(
                      _selectedFile!.path.split('/').last,
                      style: TextStyle(color: Colors.black),
                    ),
                    subtitle: Text("Tap to reselect", style: TextStyle(color: Colors.black54)),
                    onTap: pickFile,
                  ),
                ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: pickFile,
                icon: Icon(Icons.attach_file, color: Colors.black),
                label: Text("Pick File", style: TextStyle(color: Colors.black)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow[700],
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              SizedBox(height: 20),
              _isUploading
                  ? Column(
                      children: [
                        CircularProgressIndicator(color: Colors.yellow[700]),
                        SizedBox(height: 10),
                        Text("Uploading...", style: TextStyle(color: Colors.white)),
                      ],
                    )
                  : ElevatedButton.icon(
                      onPressed: uploadFile,
                      icon: Icon(Icons.upload, color: Colors.black),
                      label: Text("Upload File", style: TextStyle(color: Colors.black)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow[700],
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
              SizedBox(height: 20),
              if (_downloadUrl != null)
                Column(
                  children: [
                    Card(
                      color: Colors.yellow[700],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      elevation: 4,
                      child: ListTile(
                        leading: Icon(Icons.link, color: Colors.black),
                        title: SelectableText(_downloadUrl ?? "", style: TextStyle(color: Colors.black)),
                        subtitle: Text("Tap to copy", style: TextStyle(color: Colors.black54)),
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: _downloadUrl ?? ""));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Link copied to clipboard!")),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                    Text("Scan QR to Download", style: TextStyle(color: Colors.white, fontSize: 16)),
                    SizedBox(height: 10),
                    QrImageView(
                      data: _downloadUrl ?? "",
                      version: QrVersions.auto,
                      size: 200.0,
                      foregroundColor: Colors.yellow[700],
                      backgroundColor: Colors.black,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}