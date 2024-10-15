import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _judgingHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchJudgingHistory();
  }

  Future<void> _fetchJudgingHistory() async {
    try {
      final judgeEmail = FirebaseAuth.instance.currentUser?.email;
      if (judgeEmail == null) {
        _showErrorSnackBar(
            'Unable to fetch judging history, no judge logged in.');
        return;
      }

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('scoresheets')
          .where('judgeEmail', isEqualTo: judgeEmail)
          .get();

      if (mounted) {
        if (snapshot.docs.isNotEmpty) {
          setState(() {
            _judgingHistory = snapshot.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();
            _isLoading = false;
          });
        } else {
          _showErrorSnackBar('No judging history found.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error fetching judging history: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAE6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAE6FA),
        elevation: 0,
        title: const Text('Judging History',
            style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _judgingHistory.isNotEmpty
                ? ListView.builder(
                    itemCount: _judgingHistory.length,
                    itemBuilder: (context, index) {
                      var history = _judgingHistory[index];
                      return _buildHistoryCard(history);
                    },
                  )
                : const Center(
                    child: Text('No judging history available.',
                        style: TextStyle(fontSize: 18))),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> history) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const ShapeDecoration(
                  shape: OvalBorder(
                      side: BorderSide(width: 1.50, color: Color(0xFFE6E6E6))),
                ),
                child: Center(
                  child: Text(
                    history['participantId'].toString(),
                    style:
                        const TextStyle(color: Color(0xFF7A798B), fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(width: 2.0, color: const Color(0xFFE6E6E6)),
                ),
                child: ClipOval(
                  child: Image.network(
                    history['participantPhoto'] ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.error),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(history['participantName'] ?? 'N/A',
                        style:
                            const TextStyle(color: Colors.black, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(history['eventName'] ?? 'N/A',
                        style: const TextStyle(
                            color: Color(0xFF7A798B), fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Scores:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildScoreDetails(history['scores'] ?? []),
          const SizedBox(height: 12),
          _buildTotalScoreField(history['totalScore'] ?? 0),
        ],
      ),
    );
  }

  Widget _buildScoreDetails(List<dynamic> scores) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: scores.asMap().entries.map((entry) {
        int index = entry.key;
        int score = entry.value;
        return Text('Criterion ${index + 1}: $score',
            style: const TextStyle(fontSize: 14));
      }).toList(),
    );
  }

  Widget _buildTotalScoreField(int totalScore) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total Score:',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          Text(totalScore.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }
}
