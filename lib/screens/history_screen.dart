import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:textile_defect_app/models/UIHelper.dart';

class HistoryScreen extends StatelessWidget {
  final String userId;

  const HistoryScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Prediction History'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('TextileUsers')
            .where('userId', isEqualTo: userId)
            // Removed .orderBy('timestamp') to prevent index error
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: Colors.blue.shade700),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    color: Colors.blue.shade700,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No History Yet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your analysis history will appear here',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
            );
          }

          // Sort documents locally by timestamp descending
          final sortedDocs = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final timeA = (a['timestamp'] as Timestamp).toDate();
              final timeB = (b['timestamp'] as Timestamp).toDate();
              return timeB.compareTo(timeA);
            });

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) {
              final doc = sortedDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final timestamp = (data['timestamp'] as Timestamp).toDate();
              final formattedDate =
                  DateFormat('MMM d, yyyy h:mm a').format(timestamp);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.grey[900],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  title: Text(
                    '${data['department']} ${data['description'] ?? ''}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    formattedDate,
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      data['imageUrl'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child:
                              CircularProgressIndicator(color: Colors.blue.shade700),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.error, color: Colors.red),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (data['description']?.isNotEmpty ?? false) ...[
                            Text(
                              'Description:',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['description'],
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Text(
                            'Analysis Result:',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['analysis'],
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('TextileUsers')
                                        .doc(doc.id)
                                        .delete();
                                    UIHelper.showSnackBar(context,
                                        'Prediction deleted successfully');
                                  } catch (e) {
                                    UIHelper.showSnackBar(
                                        context, 'Error deleting analysis: $e',
                                        color: Colors.red);
                                  }
                                },
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ],
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
