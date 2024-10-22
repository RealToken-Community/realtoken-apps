import 'package:real_token/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:real_token/app_state.dart'; // Import AppState

List<PieChartSectionData> buildDetailedDonutForOthers(
    List<MapEntry<String, int>> otherCitiesDetails, BuildContext context) {
  final appState = Provider.of<AppState>(context);
  int totalCount = otherCitiesDetails.fold(0, (sum, entry) => sum + entry.value);

  return otherCitiesDetails.map((entry) {
    final double percentage = (entry.value / totalCount) * 100;
    final int index = otherCitiesDetails.indexOf(entry);
    final Color baseColor = Colors.accents[index % Colors.accents.length];
    final Color lighterColor = Utils.shadeColor(baseColor, 1);
    final Color darkerColor = Utils.shadeColor(baseColor, 0.7);

    return PieChartSectionData(
      value: entry.value.toDouble(),
      title: '${percentage.toStringAsFixed(1)}%',
      gradient: LinearGradient(
        colors: [lighterColor, darkerColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      radius: 50,
      titleStyle: TextStyle(
        fontSize: 10 + appState.getTextSizeOffset(),
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }).toList();
}
