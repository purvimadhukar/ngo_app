import 'package:flutter/material.dart';

class VolunteerHome extends StatelessWidget {
  const VolunteerHome({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Volunteer Dashboard"),
      ),

      body: const Center(
        child: Text(
          "Volunteer Activities will appear here",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}