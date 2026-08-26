import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../providers/language_provider.dart';
import '../providers/transit_provider.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isTyping = false;
  
  static const String _geminiApiKey = 'AQ.Ab8RN6Ii_33xLe-4_wSaQQfILPwB0BKgQFvL_btUXEYjZy3zfQ'; 
  
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _initWelcomeMessage();
  }

  void _initWelcomeMessage() {
    _messages.clear();
    _messages.add({
      'isBot': true,
      'type': 'welcome',
    });
  }

  Future<void> _sendMessage([String? presetText]) async {
    final userText = (presetText ?? _controller.text).trim();
    if (userText.isEmpty) return;
    
    setState(() {
      _messages.add({'isBot': false, 'type': 'text', 'text': userText});
      _isTyping = true;
    });
    _controller.clear();

    try {
      final transitProvider = Provider.of<TransitProvider>(context, listen: false);
      final langProvider = Provider.of<LanguageProvider>(context, listen: false);
      final targetLanguage = langProvider.isBangla ? 'Bangla' : 'English';

      final availableRoutes = transitProvider.buses.map((b) {
        final stopNames = b.stopIds.map((id) {
          final match = transitProvider.stops.where((s) => s.id == id);
          return match.isNotEmpty 
              ? (langProvider.isBangla ? match.first.nameBn : match.first.nameEn)
              : '';
        }).where((name) => name.isNotEmpty).toList();

        final busName = langProvider.isBangla ? b.companyBn : b.company;
        final routeTitle = langProvider.isBangla ? b.routeName : b.routeName;

        return '$busName ($routeTitle, Tag: ${b.routeTag}, Stops: ${stopNames.join(" -> ")}, Standard Fare: ৳${b.standardFare}, Student Fare: ৳${b.studentFare})';
      }).join(' | ');

      final model = GenerativeModel(
        model: 'gemini-3.6-flash',
        apiKey: _geminiApiKey,
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
        systemInstruction: Content.system('''
          You are a friendly Dhaka transit AI assistant. You have access to these live bus routes: $availableRoutes.
          
          RULES:
          - You must ALWAYS respond in pure JSON format.
          - ALWAYS provide your response (origin, destination, busName, and conversational text) in $targetLanguage.
          - To calculate "eta", count the number of stops between the origin and destination in the route sequence and multiply by 6 minutes.
          - If the user asks for a route from place A to place B (e.g. "Mirpur 10 to Farmgate" or "মিরপুর ১০ থেকে ফার্মগেট"), return this exact JSON structure:
            {"isBot": true, "type": "route_card", "origin": "Start Location", "destination": "End Location", "busName": "Company Name (Tag)", "standardFare": 35, "studentFare": 18, "eta": "18 min"}
          - If the user asks a casual question or makes small talk, be conversational and friendly. Return this exact JSON structure:
            {"isBot": true, "type": "text", "text": "Your response in $targetLanguage here."}
        '''),
      );

      final response = await model.generateContent([Content.text(userText)]);
      
      final String rawJson = response.text?.trim() ?? '{}';
      final Map<String, dynamic> parsedData = jsonDecode(rawJson);

      setState(() {
        _messages.add(parsedData);
        _isTyping = false;
      });

    } catch (e) {
      debugPrint('AI Error: $e'); 
      setState(() {
        _isTyping = false;
        _messages.add({
          'isBot': true, 
          'type': 'text', 
          'text': Provider.of<LanguageProvider>(context, listen: false).isBangla
              ? 'দুঃখিত, ট্রানজিট নেটওয়ার্কের সাথে সংযোগ করতে সমস্যা হচ্ছে।'
              : 'Sorry, I am having trouble connecting to the transit network right now.'
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(langProvider.t('AI Route Assistant'), style: const TextStyle(color: Colors.white, fontSize: 18)),
            Row(
              children: [
                const Icon(Icons.circle, color: Colors.greenAccent, size: 10),
                const SizedBox(width: 5),
                Text(
                  langProvider.isBangla ? 'সক্রিয় - লাইভ ট্রাফিক ডেটা' : 'Online - Live Traffic Data', 
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            )
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                _initWelcomeMessage();
              });
            },
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 16),
            label: Text(langProvider.isBangla ? 'নতুন চ্যাট' : 'New chat', style: const TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final msg = _messages[index];
                if (msg['type'] == 'route_card') {
                  return _buildRouteCard(msg, langProvider);
                }
                return _buildChatBubble(msg, langProvider);
              },
            ),
          ),
          _buildSuggestionChips(langProvider),
          _buildChatInput(langProvider),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg, LanguageProvider langProvider) {
    bool isBot = msg['isBot'] ?? true;
    bool isWelcome = msg['type'] == 'welcome';

    String displayText = '';
    if (isWelcome) {
      displayText = langProvider.isBangla
          ? 'হ্যালো! আমি আপনার ঢাকা বাস সহকারী।\n\nএকটি রুট খুঁজতে শুরু ও গন্তব্যের নাম লিখুন। যেমন: "মিরপুর ১০ থেকে ফার্মগেট"'
          : 'Hello! I\'m your AI Route Assistant for Dhaka.\n\nTo find a bus, specify your start and destination. For example: "Mirpur 10 to Farmgate"';
    } else {
      displayText = msg['text'] ?? '';
    }

    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isBot ? Theme.of(context).cardColor : Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: isBot ? const Radius.circular(0) : const Radius.circular(16),
            bottomRight: !isBot ? const Radius.circular(0) : const Radius.circular(16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]
        ),
        child: Text(
          displayText,
          style: TextStyle(
            color: isBot 
                ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87) 
                : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> msg, LanguageProvider langProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${msg['origin'] ?? ''} ➔ ${msg['destination'] ?? ''}', 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (msg['busName'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.directions_bus, color: Colors.greenAccent, size: 16),
                const SizedBox(width: 8),
                Text(
                  msg['busName'], 
                  style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFareBox(langProvider.isBangla ? 'সাধারণ ভাড়া' : 'Standard fare', '৳${msg['standardFare']}'),
              _buildFareBox(langProvider.isBangla ? 'শিক্ষার্থী ভাড়া' : 'Student fare', '৳${msg['studentFare']}'),
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${msg['eta'] ?? '--'}', 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFareBox(String label, String amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        Text(amount, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSuggestionChips(LanguageProvider langProvider) {
    final chip1 = langProvider.isBangla ? 'মিরপুর ১২ থেকে আজিমপুর' : 'Mirpur 12 to Azimpur';
    final chip2 = langProvider.isBangla ? 'ফার্মগেট থেকে উত্তরা' : 'Farmgate to Uttara';
    final chip3 = langProvider.isBangla ? 'মিরপুর ১০ থেকে মতিঝিল' : 'Mirpur 10 to Motijheel';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildChip(chip1),
          const SizedBox(width: 8),
          _buildChip(chip2),
          const SizedBox(width: 8),
          _buildChip(chip3),
        ],
      ),
    );
  }

  Widget _buildChip(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      onPressed: () => _sendMessage(text),
    );
  }

  Widget _buildChatInput(LanguageProvider langProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: const Border(top: BorderSide(color: Colors.black12)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: langProvider.isBangla ? 'যেমন: মিরপুর ১০ থেকে ফার্মগেট...' : 'e.g., Mirpur 10 to Farmgate...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: _isTyping 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              color: Theme.of(context).colorScheme.primary,
              onPressed: _isTyping ? null : () => _sendMessage(),
            )
          ],
        ),
      ),
    );
  }
}