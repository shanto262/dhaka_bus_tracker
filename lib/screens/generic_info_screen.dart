import 'package:flutter/material.dart';

class GenericInfoScreen extends StatelessWidget {
  final String title;
  
  const GenericInfoScreen({super.key, required this.title});

  String _getContentForTitle(String title) {
    if (title.contains('Privacy Policy') || title.contains('প্রাইভেসি পলিসি')) {
      return 'The Bangladesh Road Transport Authority (BRTA) is committed to protecting your privacy. Location data is used strictly in real-time to assist commuters with identifying nearby BRTA-approved bus stops, tracking live vehicle telemetry, and optimizing public transit routes across Dhaka. Your personal data is securely handled in compliance with national data protection guidelines and is never sold or shared with commercial third parties.';
    } else if (title.contains('Terms of Service') || title.contains('শর্তাবলী')) {
      return 'By accessing and using the official Dhaka Bus Tracker application, maintained by the Bangladesh Road Transport Authority (BRTA), you agree to utilize real-time transit schedules, official fare matrices, and operational data for personal public transportation planning. Estimated times of arrival (ETAs) and vehicle statuses are subject to live traffic conditions and transit telemetry maintained by BRTA regulators.';
    } else if (title.contains('Help Center') || title.contains('সাহায্য কেন্দ্র')) {
      return '• How to track a bus: Tap on any active BRTA bus stop icon on the map or use the AI Route Assistant to query direct routes.\n\n• Official Fares: All standard and student ticket matrices comply strictly with official BRTA fare structures and distance-based regulations.\n\n• Reporting Misconduct: Use the integrated administrative reporting portal to log grievances regarding vehicle staff, scheduling, or fare discrepancies directly to BRTA overseers.';
    } else if (title.contains('Contact Us') || title.contains('যোগাযোগ')) {
      return 'Bangladesh Road Transport Authority (BRTA)\nOfficial Dhaka Bus Tracker Support Desk\n\nEmail: support@brta.gov.bd\nHotline: 16108 / +880 9612-345678\nHeadquarters: BRTA Bhaban, New Eskaton, Dhaka-1000, Bangladesh';
    }
    return 'Detailed information regarding $title will appear here.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 32),
            Text(
              _getContentForTitle(title),
              style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}