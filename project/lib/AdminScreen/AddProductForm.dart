import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class AddProductForm extends StatefulWidget {
  const AddProductForm({Key? key}) : super(key: key);

  @override
  State<AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends State<AddProductForm> {
  final _formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final stockQtyController = TextEditingController();

  final processorController = TextEditingController();
  final osController = TextEditingController();
  final gpuController = TextEditingController();
  final memoryController = TextEditingController();
  final storageController = TextEditingController();
  final displayController = TextEditingController();
  final cameraController = TextEditingController();
  final colorController = TextEditingController();
  final usbController = TextEditingController();
  final warrantyController = TextEditingController();
  final wifiController = TextEditingController();
  final keyboardController = TextEditingController();
  final audioController = TextEditingController();
  final batteryController = TextEditingController();

  bool hdmi = false;
  bool touchscreen = false;
  bool fingerprintReader = false;
  bool inStock = true;

  List<String> uploadedImageUrls = [];
  String? selectedBrandId;
  String? selectedCategoryId;
  String? selectedSeriesId;
  String? selectedLaptopTypeId;

  List<Map<String, dynamic>> brands = [];
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> seriesList = [];
  List<Map<String, dynamic>> laptopTypes = [];

  @override
  void initState() {
    super.initState();
    fetchBrands();
    fetchCategories();
    fetchLaptopTypes();
  }

  Future<void> fetchBrands() async {
    final snapshot = await FirebaseFirestore.instance.collection('brands').get();
    setState(() {
      brands = snapshot.docs.map((doc) => {
        'id': doc.id,
        'BrandName': doc['BrandName'],
      }).toList();
    });
  }

  Future<void> fetchCategories() async {
    final snapshot = await FirebaseFirestore.instance.collection('category').get();
    setState(() {
      categories = snapshot.docs.map((doc) => {
        'id': doc.id,
        'categoryname': doc['categoryname'],
      }).toList();
    });
  }

  Future<void> fetchLaptopTypes() async {
    final snapshot = await FirebaseFirestore.instance.collection('LaptopType').get();
    setState(() {
      laptopTypes = snapshot.docs.map((doc) => {
        'id': doc.id,
        'TypeName': doc['TypeName'],
      }).toList();
    });
  }

  Future<void> fetchSeriesByBrand(String brandId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('series')
        .where('brandId', isEqualTo: brandId)
        .get();
    setState(() {
      seriesList = snapshot.docs.map((doc) => {
        'id': doc.id,
        'seriesName': doc['seriesName'],
      }).toList();
      selectedSeriesId = null;
    });
  }

  Future<void> pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null && pickedFiles.length <= 4) {
      List<String> newUrls = [];

      for (final file in pickedFiles) {
        final extension = file.name.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png'].contains(extension)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Unsupported format: .$extension. Only JPG, JPEG, PNG allowed.")),
          );
          continue;
        }

        final bytes = await file.readAsBytes();
        final base64Image = base64Encode(bytes);

        final response = await http.post(
          Uri.parse("https://api.imgbb.com/1/upload?key=df7fc15917811f032f515db141875a3d"),
          body: {"image": base64Image},
        );

        final jsonResponse = jsonDecode(response.body);
        if (response.statusCode == 200 && jsonResponse['success']) {
          newUrls.add(jsonResponse['data']['url']);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to upload one of the images.")),
          );
        }
      }

      setState(() {
        uploadedImageUrls.addAll(newUrls);
      });
    } else if (pickedFiles.length > 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please pick up to 4 images.")),
      );
    }
  }

  Future<void> addProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (uploadedImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please select at least one image.")));
      return;
    }

    final productData = {
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'price': double.tryParse(priceController.text.trim()) ?? 0.0,
      'brandId': selectedBrandId,
      'categoryId': selectedCategoryId,
      'seriesId': selectedSeriesId,
      'laptopTypeId': selectedLaptopTypeId,
      'color': colorController.text.trim(),
      'images': uploadedImageUrls,
      'inStock': inStock,
      'StockQuantity': int.tryParse(stockQtyController.text.trim()) ?? 0,
      'rating': 0.0,
      'specification': {
        'Processor': processorController.text.trim(),
        'OS': osController.text.trim(),
        'GPU': gpuController.text.trim(),
        'Memory': memoryController.text.trim(),
        'Storage': storageController.text.trim(),
        'Display': displayController.text.trim(),
        'Camera': cameraController.text.trim(),
        'USB': usbController.text.trim(),
        'Warranty': warrantyController.text.trim(),
        'Wifi': wifiController.text.trim(),
        'Keyboard': keyboardController.text.trim(),
        'Audio': audioController.text.trim(),
        'Battery': batteryController.text.trim(),
        'HDMI': hdmi,
        'Touchscreen': touchscreen,
        'Fingerprint Reader': fingerprintReader,
      },
      'createdAt': Timestamp.now(),
    };

    await FirebaseFirestore.instance.collection('products').add(productData);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Product added successfully")));

    _formKey.currentState!.reset();
    setState(() {
      uploadedImageUrls.clear();
      selectedBrandId = null;
      selectedCategoryId = null;
      selectedSeriesId = null;
      selectedLaptopTypeId = null;
      hdmi = false;
      touchscreen = false;
      fingerprintReader = false;

      titleController.clear();
      descriptionController.clear();
      priceController.clear();
      stockQtyController.clear();
      processorController.clear();
      osController.clear();
      gpuController.clear();
      memoryController.clear();
      storageController.clear();
      displayController.clear();
      cameraController.clear();
      colorController.clear();
      usbController.clear();
      warrantyController.clear();
      wifiController.clear();
      keyboardController.clear();
      audioController.clear();
      batteryController.clear();
    });
  }
  Widget sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(top: 20.0, bottom: 8),
    child: Text(
      title,
      style: GoogleFonts.merriweather(
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
    ),
  );

  Widget customTextField(String label, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          labelStyle: TextStyle(color: Colors.white),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(2)),
        ),
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget customDropdown(String label, String? selectedValue, List<Map<String, dynamic>> items, String itemLabel, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        onChanged: onChanged,
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item['id'],
            child: Text(item[itemLabel]),
          );
        }).toList(),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          labelStyle: TextStyle(color: Colors.white),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(2)),
        ),
        style: TextStyle(color: Colors.white),
        dropdownColor: Colors.teal.shade900,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(0),
      child: Card(
        color: Colors.white.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    "Add New Laptop",
                    style: GoogleFonts.merriweather(
                            textStyle: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                  ),
                ),
                sectionTitle("Laptop Info" ),
                customTextField("Enter Laptop Title", titleController),
                customTextField("Enter Description", descriptionController, maxLines: 3),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionTitle("Pricing & Stock"),

                    // Price & Stock Quantity - Side-by-side
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final double fieldWidth = constraints.maxWidth * 0.48;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: fieldWidth,
                              child: customTextField("Enter Price", priceController, keyboardType: TextInputType.number),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: customTextField("Enter Stock Quantity", stockQtyController, keyboardType: TextInputType.number),
                            ),
          ],
        );
      },
    ),

    const SizedBox(height: 24),
    sectionTitle("Dropdowns"),

    // Dropdowns (Responsive using LayoutBuilder)
    LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final double fieldWidth = constraints.maxWidth * 0.48;

        if (isWide) {
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: fieldWidth,
                    child: customDropdown("Category", selectedCategoryId, categories, 'categoryname', (val) => setState(() => selectedCategoryId = val)),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: customDropdown("Type", selectedLaptopTypeId, laptopTypes, 'TypeName', (val) => setState(() => selectedLaptopTypeId = val)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: fieldWidth,
                    child: customDropdown("Brand", selectedBrandId, brands, 'BrandName', (val) {
                      setState(() {
                        selectedBrandId = val;
                        selectedSeriesId = null;
                        seriesList = [];
                      });
                      fetchSeriesByBrand(val!);
                    }),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: customDropdown("Series", selectedSeriesId, seriesList, 'seriesName', (val) => setState(() => selectedSeriesId = val)),
                  ),
                ],
              ),
            ],
          );
        } else {
          return Column(
            children: [
              customDropdown("Category", selectedCategoryId, categories, 'categoryname', (val) => setState(() => selectedCategoryId = val)),
              customDropdown("Type", selectedLaptopTypeId, laptopTypes, 'TypeName', (val) => setState(() => selectedLaptopTypeId = val)),
              customDropdown("Brand", selectedBrandId, brands, 'BrandName', (val) {
                setState(() {
                  selectedBrandId = val;
                  selectedSeriesId = null;
                  seriesList = [];
                });
                fetchSeriesByBrand(val!);
              }),
              customDropdown("Series", selectedSeriesId, seriesList, 'seriesName', (val) => setState(() => selectedSeriesId = val)),
            ],
          );
        }
      },
    ),

    const SizedBox(height: 24),
    sectionTitle("Specifications"),

    // Specifications (Half width each)
    ...[
      [processorController, osController, "Processor", "OS"],
      [gpuController, memoryController, "GPU", "Memory"],
      [storageController, displayController, "Storage", "Display"],
      [cameraController, colorController, "Camera", "Color"],
      [usbController, warrantyController, "USB", "Warranty"],
      [wifiController, keyboardController, "Wifi", "Keyboard"],
      [audioController, batteryController, "Audio", "Battery"],
    ].map((pair) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final double fieldWidth = constraints.maxWidth * 0.48;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: fieldWidth,
                  child: customTextField(pair[2] as String, pair[0] as TextEditingController),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: customTextField(pair[3] as String, pair[1] as TextEditingController),
                ),
              ],
            ),
          );
        },
      );
    }).toList(),
  ],
),

                
                SwitchListTile(
                  title: Text("HDMI", style: GoogleFonts.merriweather(fontSize: 16, color: Colors.white)),
                  value: hdmi,
                  onChanged: (val) => setState(() => hdmi = val),
                ),
                SwitchListTile(
                  title: Text("Touchscreen", style: GoogleFonts.merriweather(fontSize: 16, color: Colors.white)),
                  value: touchscreen,
                  onChanged: (val) => setState(() => touchscreen = val),
                ),
                SwitchListTile(
                  title: Text("Fingerprint Reader", style: GoogleFonts.merriweather(fontSize: 16, color: Colors.white)),
                  value: fingerprintReader,
                  onChanged: (val) => setState(() => fingerprintReader = val),
                ),
                 SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: pickImages,
                    icon: Icon(Icons.image, color: Colors.white),
                    label: Text("Pick Images", style: TextStyle(color: Colors.white)),
                   style: ElevatedButton.styleFrom(
                      backgroundColor:Color.fromARGB(255, 234, 30, 53),
                       padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                  ),
                ),
                if (uploadedImageUrls.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: uploadedImageUrls.map((url) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(url, height: 60, width: 60, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: IconButton(
                              icon: Icon(Icons.cancel, color: Color.fromARGB(255, 234, 30, 53), size: 20),
                              onPressed: () => setState(() => uploadedImageUrls.remove(url)),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: addProduct,
                    child: Text("Add Laptop", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF539b69),
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(height: 24),
            FutureBuilder<QuerySnapshot>(
  future: FirebaseFirestore.instance
      .collection('products')
      .orderBy('createdAt', descending: true)
      .get(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return const Center(
        child: Text(
          "No products found.",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    final products = snapshot.data!.docs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: products.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final spec = data['specification'] ?? {};
        final List images = data['images'] ?? [];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 10),
          color: Colors.white.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isMobile
                        ? Column(
                            children: [
                              _buildImage(images),
                              const SizedBox(height: 16),
                              _buildProductInfo(data, spec),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildImage(images),
                              const SizedBox(width: 16),
                              Expanded(child: _buildProductInfo(data, spec)),
                            ],
                          ),
                  ],
                );
              },
            ),
          ),
        );
      }).toList(),
    );
  },
),

              ],
            ),
          ),
        ),
      ),
    );
  }
}


Widget _buildImage(List images) {
  return images.isNotEmpty
      ? ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            images[0],
            height: 150,
            width: 150,
            fit: BoxFit.cover,
          ),
        )
      : Container(
          height: 150,
          width: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[800],
          ),
          child: const Icon(Icons.image, color: Colors.white38),
        );
}

Widget _buildProductInfo(Map<String, dynamic> data, Map spec) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(data['title'] ?? '',
                style: const TextStyle(
                    color: Color(0xFF539b69),
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
          Text("PKR ${data['price'].toStringAsFixed(0)}",
              style:
                  const TextStyle(color: Color(0xFF539b69), fontSize: 16)),
        ],
      ),
      const SizedBox(height: 10),
      Text(data['description'] ?? '',
          style: const TextStyle(color: Colors.white70)),
      const SizedBox(height: 6),
      Text(
        "Stock: ${data['StockQuantity']} | In Stock: ${data['inStock'] ? 'Yes' : 'No'}",
        style: const TextStyle(color: Colors.white),
      ),
      const Divider(color: Colors.white38),
      Wrap(
        spacing: 10,
        runSpacing: 6,
        children: [
          Text("Processor: ${spec['Processor']}",
              style: const TextStyle(color: Colors.white70)),
          Text("GPU: ${spec['GPU']}",
              style: const TextStyle(color: Colors.white70)),
          Text("Storage: ${spec['Storage']}",
              style: const TextStyle(color: Colors.white70)),
          Text("Display: ${spec['Display']}",
              style: const TextStyle(color: Colors.white70)),
          Text("Color: ${data['color']}",
              style: const TextStyle(color: Colors.white70)),
        ],
      ),
    ],
  );
}
