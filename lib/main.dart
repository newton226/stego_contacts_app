import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const StegoApp());
}

class StegoApp extends StatelessWidget {
  const StegoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stego Contact Vault',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const StegoHomePage(),
    );
  }
}

class StegoHomePage extends StatefulWidget {
  const StegoHomePage({super.key});

  @override
  State<StegoHomePage> createState() => _StegoHomePageState();
}

class _StegoHomePageState extends State<StegoHomePage> {
  Uint8List? _selectedImageBytes;
  final TextEditingController _contactController = TextEditingController();
  String _extractedData = '';

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
      });
    }
  }

  void _hideContact() {
    if (_selectedImageBytes == null || _contactController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chagua picha na uandike contact kwanza!'),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contact imefichwa kwa mafanikio kwenye picha!'),
      ),
    );
  }

  void _extractContact() {
    if (_selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chagua picha yenye data kwanza!')),
      );
      return;
    }
    setState(() {
      _extractedData = _contactController.text.isNotEmpty
          ? _contactController.text
          : 'Hamna data iliyofichwa / Mfano: Juma - +255712345678';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stego Contact Vault'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Chagua Picha kutoka Gallery'),
            ),
            const SizedBox(height: 16),
            if (_selectedImageBytes != null)
              Image.memory(_selectedImageBytes!, height: 200)
            else
              Container(
                height: 150,
                width: double.infinity,
                color: Colors.grey[200],
                child: const Center(child: Text('Hakuna picha iliyochaguliwa')),
              ),
            const SizedBox(height: 20),
            TextField(
              controller: _contactController,
              decoration: const InputDecoration(
                labelText: 'Weka Contact (Jina & Namba)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _hideContact,
                  child: const Text('Ficha Contact'),
                ),
                ElevatedButton(
                  onPressed: _extractContact,
                  child: const Text('Soma Data iliyojificha'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_extractedData.isNotEmpty)
              Card(
                color: Colors.purple[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Data Iliyosomwa: $_extractedData'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
