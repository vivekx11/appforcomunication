import 'package:flutter/material.dart';
import 'services/meeting_service.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController purposeCtrl = TextEditingController();
  final TextEditingController pinCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final meetingService = MeetingService();

    return Scaffold(
      appBar: AppBar(title: Text("Choose Role")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: Text("I am Host"),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text("Create Meeting"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameCtrl,
                          decoration: InputDecoration(labelText: "Your Name"),
                        ),
                        TextField(
                          controller: purposeCtrl,
                          decoration: InputDecoration(
                            labelText: "Meeting Purpose",
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      ElevatedButton(
                        child: Text("Create"),
                        onPressed: () async {
                          await meetingService.createMeeting(
                            nameCtrl.text,
                            purposeCtrl.text,
                            context,
                          );
                          if (!context.mounted) return;
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text("I am Guest"),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text("Join Meeting"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameCtrl,
                          decoration: InputDecoration(labelText: "Your Name"),
                        ),
                        TextField(
                          controller: pinCtrl,
                          decoration: InputDecoration(labelText: "Meeting PIN"),
                        ),
                      ],
                    ),
                    actions: [
                      ElevatedButton(
                        child: Text("Join"),
                        onPressed: () async {
                          await meetingService.joinMeeting(
                            nameCtrl.text,
                            pinCtrl.text,
                            context,
                          );
                          if (!context.mounted) return;
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
