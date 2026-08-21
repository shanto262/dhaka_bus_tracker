import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  bool _isBangla = false;

  bool get isBangla => _isBangla;

  void toggleLanguage() {
    _isBangla = !_isBangla;
    notifyListeners(); 
  }

  String t(String key) {
    if (!_isBangla) return key; 

    const banglaDictionary = {
      // Navigation & Global
      'Map': 'ম্যাপ',
      'AI Assistant': 'এআই সহকারী',
      'Complaint': 'অভিযোগ',
      'Settings': 'সেটিংস',
      'Dhaka Bus Tracker': 'ঢাকা বাস ট্র্যাকার',
      
      // Map Screen
      'Upcoming Arrivals': 'আসন্ন বাসসমূহ',
      'No buses currently scheduled.': 'বর্তমানে কোনো বাসের শিডিউল নেই।',
      'LIVE TRACKING': 'লাইভ ট্র্যাকিং',
      'SCHEDULED': 'শিডিউলড',

      // Settings Screen
      'NOTIFICATIONS': 'নোটিফিকেশন',
      'Bus Arrival Alerts': 'বাস আসার এলার্ট',
      'Push alerts for nearby buses': 'কাছাকাছি বাসের জন্য এলার্ট',
      'Live Map Refresh': 'লাইভ ম্যাপ রিফ্রেশ',
      'Auto-update every 30 seconds': 'প্রতি ৩০ সেকেন্ডে অটো-আপডেট',
      'PREFERENCES': 'পছন্দসমূহ',
      'Dark Mode': 'ডার্ক মোড',
      'Easier on the eyes at night': 'রাতে চোখের জন্য আরামদায়ক',
      'Background Data Sync': 'ব্যাকগ্রাউন্ড ডেটা সিঙ্ক',
      'Keep route data fresh in background': 'ব্যাকগ্রাউন্ডে ডেটা রিফ্রেশ রাখুন',
      'Location Access': 'লোকেশন এক্সেস',
      'Used to find nearby stops': 'কাছাকাছি স্টপ খুঁজতে ব্যবহৃত হয়',
      'LANGUAGE': 'ভাষা',
      'App Language': 'অ্যাপের ভাষা',
      'English': 'ইংরেজি',
      'Bangladesh': 'বাংলাদেশ',
      'SAVED & FAVOURITES': 'সেভ ও ফেভারিট',
      'Favourite Stops': 'প্রিয় স্টপ',
      'Saved Routes': 'সেভ করা রুট',
      'SUPPORT & INFO': 'সাপোর্ট এবং তথ্য',
      'Help Center': 'হেল্প সেন্টার',
      'FAQs and usage guides': 'সাধারণ জিজ্ঞাসা ও ব্যবহার নির্দেশিকা',
      'Contact Us': 'যোগাযোগ করুন',
      'Privacy Policy': 'গোপনীয়তা নীতি',
      'Terms of Service': 'সেবার শর্তাবলী',
      'APP INFO': 'অ্যাপের তথ্য',
      'Version': 'সংস্করণ',
      'Data Source': 'ডেটা সোর্স',
      'Last Sync': 'শেষ সিঙ্ক',
      'Just now': 'এইমাত্র',
      'Build': 'বিল্ড',
      'Clear Cache': 'ক্যাশে ক্লিয়ার করুন',
      'Delete locally stored offline data': 'অফলাইন ডেটা মুছে ফেলুন',
      'Built for Dhaka · BRTC Approved': 'ঢাকার জন্য নির্মিত · বিআরটিসি অনুমোদিত',

      // AI Assistant Screen
      'AI Route Assistant': 'এআই রুট সহকারী',
      'Online - Live Traffic Data': 'অনলাইন - লাইভ ট্রাফিক ডেটা',
      'New chat': 'নতুন চ্যাট',
      'Hello! I\'m your AI Route Assistant for Dhaka. I can help you find the best bus routes, calculate fares, check student discounts, and give real-time traffic updates. Where would you like to go today?': 'হ্যালো! আমি ঢাকার জন্য আপনার এআই রুট সহকারী। আমি আপনাকে সেরা বাসের রুট খুঁজতে, ভাড়া হিসাব করতে, স্টুডেন্ট ডিসকাউন্ট চেক করতে এবং রিয়েল-টাইম ট্রাফিক আপডেট দিতে সাহায্য করতে পারি। আপনি আজ কোথায় যেতে চান?',
      'Standard fare': 'সাধারণ ভাড়া',
      'Student fare': 'স্টুডেন্ট ভাড়া',
      'Cheapest bus to Mirpur-10?': 'মিরপুর-১০ এর সবচেয়ে সস্তা বাস কোনটি?',
      'Next bus from Motijheel': 'মতিঝিল থেকে পরবর্তী বাস',
      'Type your question...': 'আপনার প্রশ্ন টাইপ করুন...',
      'Farmgate': 'ফার্মগেট',
      'Uttara': 'উত্তরা',

      // Complaint Screen
      'Submit Complaint': 'অভিযোগ জমা দিন',
      'Dhaka Bus Tracker · BRTC Authority': 'ঢাকা বাস ট্র্যাকার · বিআরটিসি কর্তৃপক্ষ',
      'Bus Information': 'বাসের তথ্য',
      'Bus Line Company *': 'বাস কোম্পানির নাম *',
      'Select a company': 'একটি কোম্পানি নির্বাচন করুন',
      'Please select a company': 'অনুগ্রহ করে একটি কোম্পানি নির্বাচন করুন',
      'Bus ID / License Plate Number *': 'বাস আইডি / লাইসেন্স প্লেট নম্বর *',
      'Please enter the Bus ID': 'অনুগ্রহ করে বাস আইডি লিখুন',
      'e.g. Dhaka Metro-Cha 11-2367': 'যেমন: ঢাকা মেট্রো-চ ১১-২৩৬৭',
      'Complaint Type': 'অভিযোগের ধরন',
      'Overcharging Fare': 'অতিরিক্ত ভাড়া আদায়',
      'Charged more than official fare': 'নির্ধারিত ভাড়ার চেয়ে বেশি নেওয়া হয়েছে',
      'Reckless Driving': 'বেপরোয়া ড্রাইভিং',
      'Dangerous or aggressive driving': 'বিপজ্জনক বা আক্রমণাত্মক ড্রাইভিং',
      'Other': 'অন্যান্য',
      'Other issues not listed above': 'উপরে উল্লেখিত নয় এমন অন্যান্য সমস্যা',
      'Details / Description': 'বিস্তারিত বিবরণ',
      'Be as specific as possible — it helps our review team.': 'যতটা সম্ভব সুনির্দিষ্ট হন — এটি আমাদের টিমকে সাহায্য করবে।',
      'Please provide details for your complaint': 'অনুগ্রহ করে আপনার অভিযোগের বিস্তারিত বিবরণ দিন',
      'Add Photo': 'ছবি যোগ করুন',
      'REPORT SUMMARY': 'রিপোর্টের সারসংক্ষেপ',
      'Company': 'কোম্পানি',
      'Bus ID': 'বাস আইডি',
      'Issue': 'সমস্যা',
      'By submitting, you agree to our Terms of Service and confirm this report is accurate.': 'জমা দেওয়ার মাধ্যমে, আপনি আমাদের সেবার শর্তাবলীতে সম্মত হচ্ছেন এবং রিপোর্টটি সঠিক বলে নিশ্চিত করছেন।',
      'SUBMIT REPORT': 'রিপোর্ট জমা দিন',
      'Thank you!': 'আপনাকে ধন্যবাদ!',
      'Your report ': 'আপনার রিপোর্ট ',
      ' has been sent to ': ' পাঠানো হয়েছে ',
      'BRTC authority will follow up within 48 hours.': 'বিআরটিসি কর্তৃপক্ষ ৪৮ ঘণ্টার মধ্যে ফলোআপ করবে।',
      'Done': 'সম্পন্ন',
    };

    return banglaDictionary[key] ?? key; 
  }
}