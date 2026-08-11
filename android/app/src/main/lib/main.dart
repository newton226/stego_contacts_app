import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MaterialApp(
    home: StegoApp(),
    debugShowCheckedModeBanner: false,
  ));
}

class StegoApp extends StatefulWidget {
  const StegoApp({super.key});

  @override
  State<StegoApp> createState() => _StegoAppState();
}

class _StegoAppState extends State<StegoApp> {
  List<Contact> _contacts = [];
  Contact? _selectedContact;
  File? _selectedImage;
  final TextEditingController _passwordController = TextEditingController();
  String _status = "";

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    if (await FlutterContacts.requestPermission()) {
      List<Contact> contacts =
          await FlutterContacts.getContacts(withProperties: true);
      setState(() {
        _contacts = contacts;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  String _encrypt(String text, String pass) {
    final key = enc.Key.fromUtf8(pass.padRight(32, '*').substring(0, 32));
    final iv = enc.IV.fromLength(16);
    final encrypter = enc.Encrypter(enc.AES(key));
    return encrypter.encrypt(text, iv: iv).base64;
  }

  Future<void> _hideContact() async {
    if (_selectedContact == null ||
        _selectedImage == null ||
        _passwordController.text.isEmpty) {
      setState(() {
        _status = "Tafadhali chagua contact, picha, na uweke password!";
      });
      return;
    }

    setState(() {
      _status = "Inaficha data kwenye picha...";
    });

    String phoneNumber = _selectedContact!.phones.isNotEmpty
        ? _selectedContact!.phones.first.number
        : '';
    String rawData = "${_selectedContact!.displayName}:$phoneNumber";
    String encryptedData = _encrypt(rawData, _passwordController.text);

    final bytes = await _selectedImage!.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return;

    String binary = "";
    for (var char in encryptedData.codeUnits) {
      binary += char.toRadixString(2).padLeft(8, '0');
    }
    binary += "1111111111111110"; // Delimiter

    int bitIndex = 0;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        if (bitIndex >= binary.length) break;
        img.Pixel pixel = image.getPixel(x, y);
        int r = pixel.r.toInt();
        r = (r & ~1) | int.parse(binary[bitIndex]);
        bitIndex++;
        image.setPixelRgb(x, y, r, pixel.g, pixel.b);
      }
      if (bitIndex >= binary.length) break;
    }

    final dir = await getApplicationDocumentsDirectory();
    final outputFile = File(
        '${dir.path}/stego_contact_${DateTime.now().millisecondsSinceEpoch}.png');
    await outputFile.writeAsBytes(img.encodePng(image));

    setState(() {
      _status = "Imefanikiwa! Picha imehifadhiwa:\n${outputFile.path}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Stego Contacts Vault")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButton<Contact>(
              hint: const Text("Chagua Contact ya Kuficha"),
              value: _selectedContact,
              isExpanded: true,
              items: _contacts.map((c) {
                return DropdownMenuItem(value: c, child: Text(c.displayName));
              }).toList(),
              onChanged: (val) => setState(() => _selectedContact = val),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text(_selectedImage == null
                  ? "Chagua Picha"
                  : "Picha Imechaguliwa"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: "Weka Password ya Siri"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _hideContact,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white),
              child: const Text("Ficha Contact Ndani ya Picha"),
            ),
            const SizedBox(height: 20),
            Text(_status,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
      ),
    );
  }
}
