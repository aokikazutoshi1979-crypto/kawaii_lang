import 'package:flutter/material.dart';
import '../services/tts_service.dart';

class FeedbackScreen extends StatelessWidget {
  final String improvement;
  final String accuracy;
  final String modelAnswer;
  final String variation;

  const FeedbackScreen({
    required this.improvement,
    required this.accuracy,
    required this.modelAnswer,
    required this.variation,
  });

  Widget _buildFeedbackItem(String title, String content, {bool hasSpeaker = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(content),
        trailing: hasSpeaker
            ? IconButton(
                icon: Icon(Icons.volume_up),
                onPressed: () => TtsService.speak(content),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('フィードバック')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildFeedbackItem('改善点の有無', improvement),
            _buildFeedbackItem('的確性', accuracy),
            _buildFeedbackItem('模範解答', modelAnswer, hasSpeaker: true),
            _buildFeedbackItem('言い換え例', variation, hasSpeaker: true),
          ],
        ),
      ),
    );
  }
}
