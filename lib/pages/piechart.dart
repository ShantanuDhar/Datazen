import 'package:datazen/core/globalvariables.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class InteractiveSectorPieChart extends StatefulWidget {
  @override
  _InteractiveSectorPieChartState createState() =>
      _InteractiveSectorPieChartState();
}

class _InteractiveSectorPieChartState extends State<InteractiveSectorPieChart> {
  int touchedIndex = -1;

  // Replace this with your parser method.
  List<String> get sectorData => _parseSectorAllocation(GlobalVariable.message);

  // Helper to get a blue shade for each section.
  Color getBlueShade(int index, bool isTouched) {
    if (isTouched) {
      // When touched, return a darker blue.
      return Colors.blue.shade900;
    } else {
      // Different blue shades based on index.
      List<Color> shades = [
        Colors.blue.shade200,
        Colors.blue.shade300,
        Colors.blue.shade400,
        Colors.blue.shade500,
        Colors.blue.shade600,
        Colors.blue.shade700,
        Colors.blue.shade800,
      ];
      return shades[index % shades.length];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback:
                (FlTouchEvent event, PieTouchResponse? pieTouchResponse) {
              if (!event.isInterestedForInteractions ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                return;
              }
              if (event is FlTapUpEvent) {
                final newIndex =
                    pieTouchResponse.touchedSection!.touchedSectionIndex;
                setState(() {
                  touchedIndex = newIndex;
                });
                final title = sectorData[newIndex].split(":")[0];
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      title,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.blueGrey[700],
                  ),
                );
              }
            },
          ),
          sections: sectorData.asMap().entries.map((entry) {
            // Extract the sector name and percentage from the string.
            final parts = entry.value.split(":");
            final sectorName = parts[0];
            final percentage =
                double.tryParse(parts[1].replaceAll("%", "").trim()) ?? 0.0;
            final bool isTouched = entry.key == touchedIndex;
            return PieChartSectionData(
              color: getBlueShade(entry.key, isTouched),
              value: percentage,
              title: sectorName,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              radius: 80,
              titlePositionPercentageOffset: 1,
            );
          }).toList(),
          centerSpaceRadius: 60,
          sectionsSpace: 4,
        ),
      ),
    );
  }
}

// Example parser function - replace or adapt according to your data format.
List<String> _parseSectorAllocation(String message) {
  // This parser expects sector allocation lines in the format:
  // "• SectorName: xx% (Cum: ...)"
  final regex = RegExp(r"• (.+?): ([\d.]+%) \(Cum: [\d.]+%\)");
  final matches = regex.allMatches(message);
  return matches.map((m) => "${m.group(1)}: ${m.group(2)}").toList();
}
