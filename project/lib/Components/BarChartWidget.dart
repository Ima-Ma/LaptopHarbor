import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalesBarChart extends StatefulWidget {
  const SalesBarChart({Key? key}) : super(key: key);

  @override
  _SalesBarChartState createState() => _SalesBarChartState();
}

class _SalesBarChartState extends State<SalesBarChart> {
  Map<String, int> orderCounts = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrderCounts();
  }

  Future<void> fetchOrderCounts() async {
    DateTime today = DateTime.now();
    DateTime sevenDaysAgo = today.subtract(const Duration(days: 6));

    Map<String, int> dailyCounts = {
      for (int i = 0; i < 7; i++)
        DateFormat.E().format(today.subtract(Duration(days: 6 - i))): 0
    };

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Orders')
          .where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
          .get();

      for (var doc in snapshot.docs) {
        Timestamp ts = doc['orderDate'];
        DateTime dt = ts.toDate();
        String day = DateFormat.E().format(dt);

        if (dailyCounts.containsKey(day)) {
          dailyCounts[day] = (dailyCounts[day] ?? 0) + 1;
        }
      }

      setState(() {
        orderCounts = dailyCounts;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : AspectRatio(
            aspectRatio: 1.7,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (orderCounts.values.isNotEmpty
                          ? (orderCounts.values.reduce((a, b) => a > b ? a : b) + 2).toDouble()
                          : 10.0),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                        reservedSize:10,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final keys = orderCounts.keys.toList();
                          if (value.toInt() < keys.length) {
                            return Text(
                              keys[value.toInt()],
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 2,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.white24,
                      strokeWidth: 0.5,
                    ),
                  ),
                  barGroups: orderCounts.entries
                      .toList()
                      .asMap()
                      .entries
                      .map(
                        (indexedEntry) => BarChartGroupData(
                          x: indexedEntry.key,
                          barRods: [
                        BarChartRodData(
                            toY: indexedEntry.value.value.toDouble(),
                            width: 20,
                            borderRadius: BorderRadius.zero, // <-- this removes the rounding
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF539b69),
                                Color(0xFF2a6b5e),
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: (orderCounts.values.reduce((a, b) => a > b ? a : b) + 2).toDouble(),
                              color: Colors.white10,
                            ),


                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          );
  }
}
