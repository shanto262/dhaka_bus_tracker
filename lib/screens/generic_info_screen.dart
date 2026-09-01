import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class GenericInfoScreen extends StatelessWidget {
  final String title;
  
  const GenericInfoScreen({super.key, required this.title});

  String _getContentForTitle(String title, bool isBangla) {
    // Check key patterns or titles in both languages
    if (title.contains('Privacy Policy') || title.contains('গোপনীয়তা নীতি')) {
      return isBangla
          ? 'বাংলাদেশ রোড ট্রান্সপোর্ট অথরিটি (BRTA) আপনার গোপনীয়তা সুরক্ষায় প্রতিশ্রুতিবদ্ধ। ঢাকা শহরের কাছাকাছি বিআরটিএ-অনুমোদিত বাস স্টপ শনাক্ত করতে, লাইভ ভেহিকল টেলিমেট্রি ট্র্যাক করতে এবং পাবলিক ট্রানজিট রুট অপ্টিমাইজ করতে লোকেশন ডেটা কঠোরভাবে রিয়েল-টাইমে ব্যবহার করা হয়। আপনার ব্যক্তিগত ডেটা জাতীয় ডেটা সুরক্ষা নির্দেশিকা মেনে সুরক্ষিতভাবে পরিচালনা করা হয় এবং এটি কখনই বাণিজ্যিক তৃতীয় পক্ষের কাছে বিক্রি বা শেয়ার করা হয় না।'
          : 'The Bangladesh Road Transport Authority (BRTA) is committed to protecting your privacy. Location data is used strictly in real-time to assist commuters with identifying nearby BRTA-approved bus stops, tracking live vehicle telemetry, and optimizing public transit routes across Dhaka. Your personal data is securely handled in compliance with national data protection guidelines and is never sold or shared with commercial third parties.';
    } else if (title.contains('Terms of Service') || title.contains('সেবার শর্তাবলী')) {
      return isBangla
          ? 'বাংলাদেশ রোড ট্রান্সপোর্ট অথরিটি (BRTA) কর্তৃক পরিচালিত অফিসিয়াল ঢাকা বাস ট্র্যাকার অ্যাপ্লিকেশনটিতে প্রবেশ করে এবং ব্যবহার করার মাধ্যমে, আপনি ব্যক্তিগত জনপরিবহন পরিকল্পনার জন্য রিয়েল-টাইম ট্রানজিট সময়সূচী, অফিসিয়াল ভাড়া ম্যাট্রিক্স এবং অপারেশনাল ডেটা ব্যবহার করতে সম্মত হচ্ছেন। পৌঁছানোর আনুমানিক সময় (ETAs) এবং যানবাহনের স্থিতি লাইভ ট্রাফিক অবস্থা এবং বিআরটিএ নিয়ন্ত্রকদের রক্ষণাবেক্ষণ করা ট্রানজিট টেলিমেট্রির উপর নির্ভরশীল।'
          : 'By accessing and using the official Dhaka Bus Tracker application, maintained by the Bangladesh Road Transport Authority (BRTA), you agree to utilize real-time transit schedules, official fare matrices, and operational data for personal public transportation planning. Estimated times of arrival (ETAs) and vehicle statuses are subject to live traffic conditions and transit telemetry maintained by BRTA regulators.';
    } else if (title.contains('Help Center') || title.contains('হেল্প সেন্টার')) {
      return isBangla
          ? '• কিভাবে বাস ট্র্যাক করবেন: ম্যাপে যেকোনো সক্রিয় বিআরটিএ বাস স্টপ আইকনে ট্যাপ করুন অথবা সরাসরি রুট খুঁজতে এআই রুট সহকারী ব্যবহার করুন।\n\n• অফিসিয়াল ভাড়া: সমস্ত স্ট্যান্ডার্ড এবং স্টুডেন্ট টিকিটের ম্যাট্রিক্স কঠোরভাবে অফিসিয়াল বিআরটিএ ভাড়া কাঠামো এবং দূরত্ব-ভিত্তিক প্রবিধান মেনে চলে।\n\n• অভিযোগ রিপোর্টিং: যানবাহনের স্টাফ, সময়সূচী বা ভাড়া সংক্রান্ত অসঙ্গতি সরাসরি বিআরটিএ তদারককারীদের কাছে জানাতে ইন্টিগ্রেটেড অ্যাডমিনিস্ট্রেটিভ রিপোর্টিং পোর্টাল ব্যবহার করুন।'
          : '• How to track a bus: Tap on any active BRTA bus stop icon on the map or use the AI Route Assistant to query direct routes.\n\n• Official Fares: All standard and student ticket matrices comply strictly with official BRTA fare structures and distance-based regulations.\n\n• Reporting Misconduct: Use the integrated administrative reporting portal to log grievances regarding vehicle staff, scheduling, or fare discrepancies directly to BRTA overseers.';
    } else if (title.contains('Contact Us') || title.contains('যোগাযোগ করুন')) {
      return isBangla
          ? 'বাংলাদেশ রোড ট্রান্সপোর্ট অথরিটি (BRTA)\nঅফিসিয়াল ঢাকা বাস ট্র্যাকার সাপোর্ট ডেস্ক\n\nইমেইল: support@brta.gov.bd\nহটলাইন: ১৬১০৮ / +৮৮০ ৯৬১২-৩৪৫৬৭৮\nপ্রধান কার্যালয়: বিআরটিএ ভবন, নতুন ইস্কাটন, ঢাকা-১০০০, বাংলাদেশ'
          : 'Bangladesh Road Transport Authority (BRTA)\nOfficial Dhaka Bus Tracker Support Desk\n\nEmail: support@brta.gov.bd\nHotline: 16108 / +880 9612-345678\nHeadquarters: BRTA Bhaban, New Eskaton, Dhaka-1000, Bangladesh';
    }
    return isBangla 
        ? '$title সম্পর্কিত বিস্তারিত তথ্য এখানে প্রদর্শিত হবে।' 
        : 'Detailed information regarding $title will appear here.';
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(langProvider.t(title), style: const TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              langProvider.t(title),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 32),
            Text(
              _getContentForTitle(title, langProvider.isBangla),
              style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}