import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/supabase_service.dart';
import 'product_model.dart';

class EditProductPage extends StatefulWidget {
  final Product product;
  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;

  File? _imageFile;              // Mobile
  Uint8List? _webImageBytes;     // Web
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _descController = TextEditingController(text: widget.product.description);
    _priceController =
        TextEditingController(text: widget.product.price.toString());
  }

  // ================= PICK IMAGE =================
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (picked == null) return;

    if (kIsWeb) {
      _webImageBytes = await picked.readAsBytes();
    } else {
      _imageFile = File(picked.path);
    }
    setState(() {});
  }

  // ================= IMAGE BUILDER =================
  Widget buildImage() {
    if (kIsWeb) {
      if (_webImageBytes != null) {
        return Image.memory(_webImageBytes!, fit: BoxFit.cover);
      } else if (widget.product.imageUrl != null &&
          widget.product.imageUrl!.isNotEmpty) {
        return Image.network(widget.product.imageUrl!, fit: BoxFit.cover);
      }
    } else {
      if (_imageFile != null) {
        return Image.file(_imageFile!, fit: BoxFit.cover);
      } else if (widget.product.imageUrl != null &&
          widget.product.imageUrl!.isNotEmpty) {
        return Image.network(widget.product.imageUrl!, fit: BoxFit.cover);
      }
    }

    return const Center(
      child: Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
    );
  }

  // ================= UPDATE PRODUCT =================
  Future<void> updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (!SupabaseService.isAdmin()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Access Denied')),
      );
      return;
    }

    setState(() => _loading = true);

    String? imageUrl = widget.product.imageUrl;

    if (kIsWeb && _webImageBytes != null) {
      imageUrl =
          await SupabaseService.uploadWebImage(_webImageBytes!, 'products');
    } else if (_imageFile != null) {
      imageUrl =
          await SupabaseService.uploadImage(_imageFile!, 'products');
    }

    final updatedProduct = Product(
      id: widget.product.id,
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      price: double.tryParse(_priceController.text.trim()) ?? 0,
      imageUrl: imageUrl,
    );

    final success = await SupabaseService.updateProduct(updatedProduct);

    setState(() => _loading = false);

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update product')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Product')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          color: Colors.grey[200],
                        ),
                        child: buildImage(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nameController,
                      decoration:
                          const InputDecoration(labelText: 'Product Name'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter product name' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter description' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _priceController,
                      decoration:
                          const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || double.tryParse(v) == null
                              ? 'Enter valid price'
                              : null,
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: updateProduct,
                      child: const Text('Update Product'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
