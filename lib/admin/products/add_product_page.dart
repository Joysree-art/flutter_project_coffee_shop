import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../services/supabase_service.dart';
import 'product_model.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _onlineUrlController = TextEditingController();

  File? _imageFile;             // Mobile image
  Uint8List? _webImageBytes;    // Web image
  bool _loading = false;

  // ================= PICK LOCAL IMAGE =================
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      if (kIsWeb) {
        _webImageBytes = await picked.readAsBytes();
      } else {
        _imageFile = File(picked.path);
      }
      setState(() {});
    }
  }

  // ================= DOWNLOAD ONLINE IMAGE =================
  Future<File?> downloadImage(String url) async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) return null;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(res.bodyBytes);
      return file;
    } catch (e) {
      print('Download image error: $e');
      return null;
    }
  }

  // ================= SAVE PRODUCT =================
  Future<void> saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (!SupabaseService.isAdmin()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Access Denied')),
      );
      return;
    }

    setState(() => _loading = true);

    String? imageUrl;

    if (kIsWeb && _webImageBytes != null) {
      // Upload Web image
      imageUrl = await SupabaseService.uploadWebImage(_webImageBytes!, 'products');
    } else if (_imageFile != null) {
      // Upload mobile local image
      imageUrl = await SupabaseService.uploadImage(_imageFile!, 'products');
    } else if (_onlineUrlController.text.isNotEmpty) {
      // Online URL → download and upload
      final file = await downloadImage(_onlineUrlController.text.trim());
      if (file != null) {
        imageUrl = await SupabaseService.uploadImage(file, 'products');
      }
    }

    final product = Product(
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      price: double.tryParse(_priceController.text.trim()) ?? 0,
      imageUrl: imageUrl,
    );

    final success = await SupabaseService.addProduct(product);

    setState(() => _loading = false);

    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add product')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // ===== PICK LOCAL IMAGE =====
                    GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          color: Colors.grey[200],
                        ),
                        child: kIsWeb
                            ? (_webImageBytes != null
                                ? Image.memory(_webImageBytes!, fit: BoxFit.cover)
                                : const Center(child: Icon(Icons.add_a_photo, size: 50)))
                            : (_imageFile != null
                                ? Image.file(_imageFile!, fit: BoxFit.cover)
                                : const Center(child: Icon(Icons.add_a_photo, size: 50))),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ===== ONLINE URL INPUT =====
                    TextFormField(
                      controller: _onlineUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Online Image URL (optional)',
                        hintText: 'https://example.com/image.png',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ===== PRODUCT NAME =====
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Product Name'),
                      validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
                    ),
                    const SizedBox(height: 16),

                    // ===== PRODUCT DESCRIPTION =====
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      validator: (v) => v == null || v.isEmpty ? 'Enter description' : null,
                    ),
                    const SizedBox(height: 16),

                    // ===== PRODUCT PRICE =====
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || double.tryParse(v) == null
                          ? 'Enter valid price'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // ===== SAVE BUTTON =====
                    ElevatedButton(
                      onPressed: saveProduct,
                      child: const Text('Save Product'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
