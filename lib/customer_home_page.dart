import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  List<Map<String, dynamic>> cart = [];
  late Stream<QuerySnapshot> _productsStream;

  final Color primaryColor = const Color(0xFF006D60); // Dark Teal from image
  final Color bgColor = const Color(0xFFF9F9F9); // Very light grey background

  @override
  void initState() {
    super.initState();
    _productsStream = firestore
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  void addToCart(Map<String, dynamic> product, String productId) {
    final index = cart.indexWhere((item) => item['productId'] == productId);

    setState(() {
      if (index >= 0) {
        cart[index]['quantity']++;
      } else {
        cart.add({
          'productId': productId,
          'name': product['name'],
          'price': product['price'],
          'imageUrl': product['imageUrl'] ?? '',
          'quantity': 1,
        });
      }
    });

    showMessage('تمت إضافة المنتج للسلة');
  }

  void incrementQuantity(
      int index, void Function(void Function()) setModalState) {
    setState(() {
      cart[index]['quantity']++;
    });
    setModalState(() {});
  }

  void decrementQuantity(
      int index, void Function(void Function()) setModalState) {
    setState(() {
      if (cart[index]['quantity'] > 1) {
        cart[index]['quantity']--;
      }
    });
    setModalState(() {});
  }

  void removeFromCart(int index, void Function(void Function()) setModalState) {
    setState(() {
      cart.removeAt(index);
    });
    setModalState(() {});
  }

  double getTotal() {
    double total = 0;
    for (var item in cart) {
      total += (item['price'] ?? 0) * (item['quantity'] ?? 1);
    }
    return total;
  }

  Future<void> sendOrder() async {
    if (cart.isEmpty) {
      showMessage('السلة فارغة');
      return;
    }

    if (nameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        addressController.text.isEmpty) {
      showMessage('أدخل بيانات العميل كاملة');
      return;
    }

    await firestore.collection('orders').add({
      'customerName': nameController.text.trim(),
      'phone': phoneController.text.trim(),
      'address': addressController.text.trim(),
      'items': cart,
      'total': getTotal(),
      'status': 'جديد',
      'createdAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      cart.clear();
      nameController.clear();
      phoneController.clear();
      addressController.clear();
    });

    showMessage('تم إرسال الطلب بنجاح');
    if (mounted) {
      Navigator.pop(context); // Close cart sheet
    }
  }

  void showCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return FractionallySizedBox(
              heightFactor: 0.9, // Almost full screen
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, size: 28),
                        ),
                        const Text(
                          'سلة المشتريات',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 48), // Balance for centering
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Cart Items
                    Expanded(
                      child: cart.isEmpty
                          ? const Center(child: Text('السلة فارغة'))
                          : ListView.separated(
                              itemCount: cart.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = cart[index];
                                return Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      // Right: Image
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF5F5F5),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: productImage(
                                            item['imageUrl'] ?? '',
                                            height: 64),
                                      ),
                                      const SizedBox(width: 12),
                                      // Center: Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['name'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${item['price']} ريال',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            // Quantity Controls
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                InkWell(
                                                  onTap: () =>
                                                      decrementQuantity(
                                                          index, setModalState),
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: Colors
                                                              .grey.shade300),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: const Text('-',
                                                        style: TextStyle(
                                                            fontSize: 16)),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 12),
                                                  child: Text(
                                                    '${item['quantity']}',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () =>
                                                      incrementQuantity(
                                                          index, setModalState),
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: Colors
                                                              .grey.shade300),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: const Text('+',
                                                        style: TextStyle(
                                                            fontSize: 16)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Left: Delete
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: Colors.red),
                                        onPressed: () => removeFromCart(
                                            index, setModalState),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),

                    const SizedBox(height: 16),
                    // Total
                    Row(
                      children: [
                        const Text(
                          'الإجمالي: ',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${getTotal().toStringAsFixed(0)} ريال',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Form Fields
                    _buildTextField('اسم العميل', 'أدخل اسمك', nameController),
                    const SizedBox(height: 12),
                    _buildTextField(
                        'رقم الهاتف', 'أدخل رقم هاتفك', phoneController,
                        isPhone: true),
                    const SizedBox(height: 12),
                    _buildTextField(
                        'العنوان', 'أدخل عنوانك', addressController),

                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        onPressed: sendOrder,
                        icon: const Icon(Icons.send, size: 20),
                        label: const Text(
                          'إرسال الطلب',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SizedBox(
                        height: MediaQuery.of(context).viewInsets.bottom + 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'جديد':
        return Colors.teal;
      case 'مقبول':
        return Colors.blue;
      case 'جاري التحضير':
        return Colors.orange;
      case 'تم التسليم':
        return Colors.green;
      case 'مرفوض':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void showMyOrdersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection('orders')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('حدث خطأ في تحميل الطلبات'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final orders = snapshot.data!.docs;

              if (orders.isEmpty) {
                return const Center(child: Text('لا توجد طلبات حالياً'));
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'تتبع طلباتي',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...orders.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'جديد';
                    final total = data['total'] ?? 0;
                    final items = data['items'] as List? ?? [];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'حالة الطلب: $status',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: getStatusColor(status),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('الإجمالي: $total ريال'),
                            const Divider(),
                            const Text(
                              'المنتجات:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ...items.map((item) {
                              return Text(
                                '- ${item['name']} | الكمية: ${item['quantity']}',
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTextField(
      String label, String hint, TextEditingController controller,
      {bool isPhone = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget productImage(String imageUrl, {double? height}) {
    if (imageUrl.isEmpty) {
      return Icon(Icons.image, size: 50, color: Colors.grey.shade400);
    }
    return Image.network(
      imageUrl,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.broken_image, size: 50, color: Colors.grey.shade400);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('متجر العميل',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
          IconButton(
            onPressed: showMyOrdersSheet,
            icon: const Icon(Icons.receipt_long),
            tooltip: 'تتبع الطلب',
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: showCartSheet,
                icon: const Icon(Icons.shopping_cart_outlined),
              ),
              if (cart.isNotEmpty)
                Positioned(
                  right: 4,
                  top: 8,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(
                      cart.length.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _productsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('حدث خطأ في تحميل المنتجات'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: primaryColor));
          }

          final products = snapshot.data!.docs;

          if (products.isEmpty) {
            return const Center(child: Text('لا توجد منتجات حالياً'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.6,
            ),
            itemBuilder: (context, index) {
              final doc = products[index];
              final product = doc.data() as Map<String, dynamic>;

              final name = product['name'] ?? 'بدون اسم';
              final price = product['price'] ?? 0;
              final category = product['category'] ?? '';
              final imageUrl = product['imageUrl'] ?? '';

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image Section
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFF5F5F5),
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: productImage(imageUrl),
                        ),
                      ),
                    ),
                    // Details Section
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  category,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$price ريال',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            SizedBox(
                              width: double.infinity,
                              height: 36,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: () {
                                  addToCart(product, doc.id);
                                },
                                child: const Text(
                                  'إضافة',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
