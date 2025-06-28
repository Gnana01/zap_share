import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';

class DeviceDetailScreen extends StatefulWidget {
  final String deviceName;
  final String deviceAddress;
  final FlutterP2pConnection p2pPlugin;

  const DeviceDetailScreen({
    super.key,
    required this.deviceName,
    required this.deviceAddress,
    required this.p2pPlugin,
  });

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  List<String> history = [];
  List<PlatformFile> selectedFiles = [];

  Future<void> pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
      withReadStream: true,
    );

    if (result != null) {
      setState(() {
        selectedFiles = result.files; // Store selected files
      });
    }
  }

  Future<void> sendFiles() async {
    if (selectedFiles.isEmpty) return; // No files selected

    List<String> filePaths = selectedFiles.map((file) => file.path!).toList();
    List<String> fileNames = selectedFiles.map((file) => file.name).toList();

    List<TransferUpdate>? updates =
        await widget.p2pPlugin.sendFiletoSocket(filePaths);

    if (updates != null) {
      for (var name in fileNames) {
        history.add("Sent: $name");
      }
      setState(() {
        selectedFiles.clear(); // Clear selection after sending
      });
    }

    FilePicker.platform.clearTemporaryFiles();
  }

  void removeFile(int index) {
    setState(() {
      selectedFiles.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.deviceName,
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
                SizedBox(height: 20),

                // Connection Icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone_iphone, size: 50, color: Colors.white),
                    Container(width: 50, height: 2, color: Colors.white),
                    Icon(Icons.phone_iphone, size: 50, color: Colors.white),
                  ],
                ),

                SizedBox(height: 40),

                // File Selection & Preview
                ElevatedButton(
                  onPressed: pickFiles,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  child: Text("Select Files", style: TextStyle(fontSize: 16)),
                ),

                SizedBox(height: 10),

                // Display selected files
                if (selectedFiles.isNotEmpty)
                  Container(
                    padding: EdgeInsets.all(10),
                    height: 120,
                    child: ListView.builder(
                      itemCount: selectedFiles.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(
                            selectedFiles[index].name,
                            style: TextStyle(color: Colors.white),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.close, color: Colors.red),
                            onPressed: () => removeFile(index),
                          ),
                        );
                      },
                    ),
                  ),

                SizedBox(height: 10),

                // Send Button
                ElevatedButton(
                  onPressed: sendFiles,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: Text("Send", style: TextStyle(fontSize: 18)),
                ),

                SizedBox(height: 40),

                Icon(Icons.bolt, size: 80, color: Colors.white),
              ],
            ),

            // Transfer History Icon
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: Icon(Icons.history, color: Colors.white, size: 30),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.black,
                      title: Text("Transfer History", style: TextStyle(color: Colors.white)),
                      content: history.isEmpty
                          ? Text("No transfers yet", style: TextStyle(color: Colors.white))
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: history.map((item) => Text(item, style: TextStyle(color: Colors.white))).toList(),
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
