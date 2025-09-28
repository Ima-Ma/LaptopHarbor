import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductStock {
  final String name;
  final int quantity;

  ProductStock(this.name, this.quantity);
}

class StockHistogramChart extends StatefulWidget {
  const StockHistogramChart({Key? key}) : super(key: key);

  @override
  State<StockHistogramChart> createState() => _StockHistogramChartState();
}

class _StockHistogramChartState extends State<StockHistogramChart> {
  List<ProductStock> _stocks = [];
  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    fetchProductStocks();
  }

  Future<void> fetchProductStocks() async {
    final snapshot = await FirebaseFirestore.instance.collection('products').get();
    final data = snapshot.docs.map((doc) {
      final title = doc['title'] ?? 'Unknown';
      final quantity = doc['StockQuantity'] ?? 0;
      return ProductStock(title, quantity);
    }).toList();

    // Sort and take the 5 with lowest stock
    data.sort((a, b) => a.quantity.compareTo(b.quantity));
    final lowestFive = data.take(4).toList();

    setState(() {
      _stocks = lowestFive;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_stocks.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    final maxY = _stocks.map((s) => s.quantity).reduce((a, b) => a > b ? a : b).toDouble();
    final minY = _stocks.map((s) => s.quantity).reduce((a, b) => a < b ? a : b).toDouble();

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY + 5,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Colors.black87,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${_stocks[groupIndex].name}\nQty: ${rod.toY.round()}',
                      const TextStyle(color: Colors.white),
                    );
                  },
                ),
                touchCallback: (event, response) {
                  setState(() {
                    touchedIndex = response?.spot?.touchedBarGroupIndex ?? -1;
                  });
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= _stocks.length) return const SizedBox.shrink();
                      return Padding(
                          padding: const EdgeInsets.only(top: 1.0),
                          child: SizedBox(
                            width: 40, // Adjust this width if needed
                            child: Text(
                              _stocks[index].name,
                              style: const TextStyle(color: Colors.white, fontSize: 8),
                              textAlign: TextAlign.center,
                              maxLines: 2, // Allow two lines
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                            ),
                          ),
                        );
                    },
                    reservedSize: 20,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    reservedSize: 20,
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
             
             
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: false),
              barGroups: _stocks.asMap().entries.map((entry) {
                final index = entry.key;
                final stock = entry.value;

                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: stock.quantity.toDouble(),
                      width: 18,
                      color: touchedIndex == index
                          ? const Color.fromARGB(255, 20, 47, 51)
                          : const Color(0xFF539b69),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ],
                );
              }).toList(),
              extraLinesData: ExtraLinesData(horizontalLines: [
                HorizontalLine(
                  y: minY,
                  color: Color.fromARGB(255, 190, 2, 2),
                  strokeWidth: 2,
                  dashArray: [5, 5],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.bottomRight,
                    style: const TextStyle(color: Colors.white),
                    labelResolver: (line) => 'Min: ${minY.toInt()}',
                  ),
                )
              ]),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // 🔵 Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            LegendItem(color: Color(0xFF539b69), label: "Stock"),
            SizedBox(width: 12),
            LegendItem(color: Color.fromARGB(255, 190, 2, 2), label: "Min Stock"),
          ],
        )
      ],
    );
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const LegendItem({Key? key, required this.color, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 8)), // Font size 8px
      ],
    );
  }
}
