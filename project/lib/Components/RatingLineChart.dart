import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class RatingLineChart extends StatefulWidget {
  const RatingLineChart({Key? key}) : super(key: key);

  @override
  _RatingLineChartState createState() => _RatingLineChartState();
}

class _RatingLineChartState extends State<RatingLineChart> {
  Map<String, double> averageRatings = {};
  bool isLoading = true;
  int? touchedIndex;

  final List<Color> customColors = const [
     Color(0xFF539b69),
    Color.fromARGB(255, 234, 30, 53),
    Colors.blueAccent,
  ];

  @override
  void initState() {
    super.initState();
    fetchAverageRatings();
  }

  Future<void> fetchAverageRatings() async {
    try {
      final productsSnapshot =
          await FirebaseFirestore.instance.collection('products').get();
      final ratingsSnapshot =
          await FirebaseFirestore.instance.collection('reviews').get();

      final Map<String, String> productTitles = {
        for (var doc in productsSnapshot.docs) doc.id: doc['title']
      };

      final Map<String, List<int>> ratingMap = {};

      for (var doc in ratingsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final productId = data['productId'];
        final rating = data['rating'];
        if (productId != null && rating != null) {
          ratingMap.putIfAbsent(productId, () => []).add(rating);
        }
      }

      final Map<String, double> averages = {};
      ratingMap.forEach((productId, ratings) {
        final title = productTitles[productId] ?? 'Unknown';
        final avg = ratings.reduce((a, b) => a + b) / ratings.length;
        averages[title] = avg;
      });

      final sorted = Map.fromEntries(
        averages.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)),
      );

      setState(() {
        averageRatings = Map.fromEntries(sorted.entries.take(3));
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    final List<PieChartSectionData> sections = averageRatings.entries.map((entry) {
      final index = averageRatings.keys.toList().indexOf(entry.key);
      final isTouched = index == touchedIndex;
      final color = customColors[index % customColors.length];
      final double radius = isTouched ? 40 : 30; // Smaller radius

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${entry.value.toStringAsFixed(1)}',
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      );
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 120, // Smaller chart height
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 20,
              sectionsSpace: 1,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions || response == null || response.touchedSection == null) {
                      touchedIndex = null;
                      return;
                    }
                    touchedIndex = response.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: averageRatings.entries.map((entry) {
            final index = averageRatings.keys.toList().indexOf(entry.key);
            final color = customColors[index % customColors.length];

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Row(
                children: [
                  Container(width: 8, height: 8, color: color),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      entry.key,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
