import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/Components/AdminAppBar.dart';
import 'package:project/Components/AdminBottomNav.dart';
import 'package:project/Components/BarChartWidget.dart';
import 'package:project/Components/RatingLineChart.dart';
import 'package:project/Components/StockHistogramChart.dart';

class Admin extends StatefulWidget {
  const Admin({Key? key}) : super(key: key);

  @override
  _AdminState createState() => _AdminState();
}

class _AdminState extends State<Admin> {
  int userCount = 0;
  int productCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCounts();
  }

  Future<void> fetchCounts() async {
    try {
      final userSnap = await FirebaseFirestore.instance.collection('userprofile').get();
      final productSnap = await FirebaseFirestore.instance.collection('products').get();

      setState(() {
        userCount = userSnap.docs.length;
        productCount = productSnap.docs.length;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true, // 👈 Important for transparent AppBar
      backgroundColor: const Color.fromARGB(255, 15, 20, 26),
      appBar: AdminAppBar(),
      bottomNavigationBar: GlassBottomNavBar(selectedIndex: 0),
      body: DashboardPage(
          userCount: userCount,
          productCount: productCount,
          isLoading: isLoading,
        ),
    );
  }
}


class DashboardPage extends StatefulWidget {
  final int userCount;
  final bool isLoading;
  final int productCount;

  const DashboardPage({
    Key? key,
    required this.userCount,
    required this.isLoading,
    required this.productCount,
  }) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool showHelpIcons = false;

  Widget glassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(2),
      
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),

        child: ListView(
          children: [
              Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: glassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text("Stock Analytics", style: GoogleFonts.merriweather(
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),),
                        const SizedBox(height: 5),
                        SizedBox(height: 200, child: StockHistogramChart()),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: glassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text("Top Rated", style: GoogleFonts.merriweather(
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),),
                        const SizedBox(height: 5),
                        SizedBox(height: 200, child: RatingLineChart()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            glassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text("Sales Overview", style: GoogleFonts.merriweather(
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(flex: 3, child: SizedBox(height: 200, child: SalesBarChart())),
                  //     const SizedBox(width: 16),
                  //     Expanded(flex: 2, child: Image.asset('assets/images/person.png', height: 200)),
                    ],
                  ),
                ],
              ),
            ),
           
            glassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text("Customer Support", style: GoogleFonts.merriweather(
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),),
                  const SizedBox(height: 2),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('supportReq').where('status', isEqualTo: 'Pending').limit(5).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(color: Colors.white)));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Padding(padding: EdgeInsets.all(8.0), child: Text("No pending activities.", style: TextStyle(color: Colors.white)));
                      }
                      return Column(
                        children: snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final subject = data['description'] ?? 'Support request';
                          return ListTile(
                            leading: const Icon(Icons.pending_actions, color: Color(0xFF36d677)),
                            title: Text(" Issue: $subject", style: GoogleFonts.merriweather(
                            textStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),),
                            trailing: IconButton(
                              icon: const Icon(Icons.reply, color: Color(0xFF36d677)),
                              onPressed: () {
                                Navigator.pushNamed(context, '/SupportReq');
                              },
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          
          
          ],
        ),
      ),
    );
  }
}
