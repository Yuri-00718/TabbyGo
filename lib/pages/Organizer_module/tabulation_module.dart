import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class TabulationModule extends StatefulWidget {
  final String eventName;

  const TabulationModule({Key? key, required this.eventName}) : super(key: key);

  @override
  _TabulationModuleState createState() => _TabulationModuleState();
}

class _TabulationModuleState extends State<TabulationModule> {
  bool _isLoading = true;
  Map<String, Map<String, dynamic>> _participantScores = {};

  @override
  void initState() {
    super.initState();
    _fetchScores();
  }

  Future<void> _fetchScores() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('scoresheets')
          .where('eventName', isEqualTo: widget.eventName)
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        String participantId = data['participantId'].toString();
        String name = data['participantName'] ?? 'Unknown';
        String photoUrl = data['participantPhoto'] ?? '';
        double totalScore = (data['totalScore'] ?? 0).toDouble();
        String judgeName =
            data['judgeName'] ?? 'Unknown Judge'; // Added judge name

        if (!_participantScores.containsKey(participantId)) {
          _participantScores[participantId] = {
            'name': name,
            'totalScore': 0.0,
            'participantPhoto': photoUrl,
            'judgeCount': 0,
            'categoryScores': {},
            'judges': {}, // To store judges for each category
          };
        }

        _participantScores[participantId]!['judgeCount'] += 1;
        _participantScores[participantId]!['totalScore'] += totalScore;

        if (data['categoryScores'] != null) {
          final categoryScores =
              data['categoryScores'] as Map<dynamic, dynamic>;
          categoryScores.forEach((category, score) {
            // Update category scores
            _participantScores[participantId]!['categoryScores'].update(
                category.toString(),
                (value) => value + (score as num).toDouble(),
                ifAbsent: () => (score as num).toDouble());

            // Update judges for each category
            if (!_participantScores[participantId]!['judges']
                .containsKey(category)) {
              _participantScores[participantId]!['judges'][category] = [];
            }
            _participantScores[participantId]!['judges'][category]!
                .add(judgeName);
          });
        }
      }

      // Average scores calculation
      _participantScores.forEach((participantId, scoreData) {
        int judgeCount = scoreData['judgeCount'] ?? 1;
        scoreData['totalScore'] =
            (scoreData['totalScore'] as double) / judgeCount;
        scoreData['totalScore'] =
            (scoreData['totalScore'] as double).clamp(0, 100);
      });

      setState(() {});
    } catch (e) {
      print("Failed to fetch scores: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tabulation - ${widget.eventName}"),
        backgroundColor: const Color(0xFF5144B6),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _participantScores.isEmpty
                ? const Center(child: Text("No scores found for this event."))
                : ListView.builder(
                    itemCount: _participantScores.length,
                    itemBuilder: (context, index) {
                      String participantId =
                          _participantScores.keys.elementAt(index);
                      final data = _participantScores[participantId]!;
                      final categoryScores =
                          data['categoryScores'] as Map<dynamic, dynamic>;
                      final judges = data['judges'] as Map<dynamic, dynamic>;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20.0),
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 5,
                              blurRadius: 7,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Display the participant's photo
                            ClipOval(
                              child: Image.network(
                                data['participantPhoto'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'Participant: ${data['name']}',
                              style: const TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'Average Score: ${data['totalScore'].toStringAsFixed(2)}',
                            ),
                            const SizedBox(height: 8.0),
                            // Display judges for each category
                            ...judges.entries.map((entry) {
                              String category = entry.key.toString();
                              List<String> judgeNames = entry.value;
                              return Text(
                                'Judges for $category: ${judgeNames.join(", ")}',
                                style: const TextStyle(fontSize: 14.0),
                              );
                            }).toList(),
                            const SizedBox(height: 16.0),
                            SfCartesianChart(
                              title: ChartTitle(
                                  text: 'Scores for ${data['name']}'),
                              legend: const Legend(isVisible: true),
                              primaryXAxis: CategoryAxis(
                                title: AxisTitle(text: 'Categories'),
                              ),
                              primaryYAxis: NumericAxis(
                                title: AxisTitle(text: 'Scores'),
                                minimum: 0,
                                maximum: 100,
                                interval: 10,
                              ),
                              tooltipBehavior: TooltipBehavior(enable: true),
                              series: <CartesianSeries>[
                                ColumnSeries<Map<String, dynamic>, String>(
                                  dataSource: categoryScores.entries
                                      .map((entry) => {
                                            'category': entry.key.toString(),
                                            'score':
                                                (entry.value as num).toDouble(),
                                          })
                                      .toList(),
                                  xValueMapper: (data, _) => data['category'],
                                  yValueMapper: (data, _) => data['score'],
                                  name: 'Category Score',
                                  dataLabelSettings:
                                      const DataLabelSettings(isVisible: true),
                                  color: const Color(0xFF77DD77),
                                ),
                                LineSeries<Map<String, dynamic>, String>(
                                  dataSource: categoryScores.entries
                                      .map((entry) => {
                                            'category': entry.key.toString(),
                                            'score':
                                                (entry.value as num).toDouble(),
                                          })
                                      .toList(),
                                  xValueMapper: (data, _) => data['category'],
                                  yValueMapper: (data, _) => data['score'],
                                  name: 'Score Trend',
                                  color: const Color(0xFFff6347), // Line color
                                  width: 2, // Width of the line
                                  markerSettings: const MarkerSettings(
                                    isVisible: true,
                                    shape: DataMarkerType.circle,
                                    color: Color(0xFFff6347), // Marker color
                                    borderColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
