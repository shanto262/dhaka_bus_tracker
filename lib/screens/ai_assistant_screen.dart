import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../providers/language_provider.dart';
import '../providers/transit_provider.dart';

class AiAssistantScreen extends StatefulWidget {
  final VoidCallback? onNavigateToMap;

  const AiAssistantScreen({super.key, this.onNavigateToMap});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isTyping = false;
  
  static const String _geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'YOUR_API_KEY_HERE',
  ); 
  
  final List<Map<String, dynamic>> _messages = [];

  // In-memory cache to save responses and prevent redundant free-tier API calls
  final Map<String, Map<String, dynamic>> _responseCache = {};

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
    
    // Normalize text for reliable cache matching
    final String cacheKey = userText.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    setState(() {
      _messages.add({'isBot': false, 'type': 'text', 'text': userText});
      _isTyping = true;
    });
    _controller.clear();

    // Check if we already have this response cached locally
    if (_responseCache.containsKey(cacheKey)) {
      await Future.delayed(const Duration(milliseconds: 150));
      setState(() {
        _messages.add(Map<String, dynamic>.from(_responseCache[cacheKey]!));
        _isTyping = false;
      });
      return;
    }

    try {
      final transitProvider = Provider.of<TransitProvider>(context, listen: false);
      final langProvider = Provider.of<LanguageProvider>(context, listen: false);
      final targetLanguage = langProvider.isBangla ? 'Bangla' : 'English';

      // 1. Build the Route Context
      final availableRoutes = transitProvider.buses.map((b) {
        final stopNames = b.stopIds.map((id) {
          final match = transitProvider.stops.where((s) => s.id == id);
          return match.isNotEmpty 
              ? (langProvider.isBangla ? match.first.nameBn : match.first.nameEn)
              : '';
        }).where((name) => name.isNotEmpty).toList();

        final busName = langProvider.isBangla ? b.companyBn : b.company;
        final routeTitle = langProvider.isBangla ? b.routeName : b.routeName;

        return '$busName ($routeTitle, Tag: ${b.routeTag}, Stops: ${stopNames.join(" -> ")})';
      }).join(' | ');

      // 2. Build the Fare Matrix Context
      String fareMatrixContext = '';
      try {
        fareMatrixContext = jsonEncode(transitProvider.fareMatrices);
      } catch (_) {
        fareMatrixContext = '[]';
      }

      final model = GenerativeModel(
        model: 'gemini-3.6-flash',
        apiKey: _geminiApiKey,
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
        systemInstruction: Content.system('''
          You are a friendly Dhaka transit AI assistant. 
          
          You have access to these live bus routes and their exact routeTags and stop sequences: $availableRoutes.
          You also have access to specific point-to-point fare matrices: $fareMatrixContext.
          
          RULES:
          - You must ALWAYS respond in pure JSON format.
          - ALWAYS provide your response location names and text in $targetLanguage.
          - To calculate "eta", count the total number of stops across the journey and multiply by 6 minutes.
          - DIRECT ROUTE: If a single bus connects origin to destination, use the "route_card" format. Ensure the "busName" includes the routeTag in parentheses (e.g., "Bikash Paribahan (bk-101)").
          - MULTI-LEG ROUTE: If no single bus connects them directly, find a logical intermediate transfer stop where the user can switch from Leg 1 to Leg 2. Use the "multi_leg_card" format.
          
          FARE CALCULATION FOR DIRECT ROUTES:
          - Look for the exact key matching "Origin_Destination" in the matrix. If found, use standard and student values. If not, estimate Tk 2.53/stop (minimum 10). Student is 50% if standard >= 20, else minimum 10.

          JSON RESPONSE FORMATS:
          - Direct Route Request:
            {"isBot": true, "type": "route_card", "origin": "Start Location", "destination": "End Location", "busName": "Company Name (bk-101)", "standardFare": 10, "studentFare": 10, "eta": "18 min"}
          
          - Transfer / Multi-Leg Request (NO FARES REQUIRED HERE, CODE WILL CALCULATE THEM):
            {"isBot": true, "type": "multi_leg_card", "origin": "Start", "destination": "End", "transferStop": "Transfer Location", "leg1Bus": "Bus A (bk-101)", "leg2Bus": "Bus B (bk-202)", "eta": "72 min"}

          - Casual Conversation/Small Talk:
            {"isBot": true, "type": "text", "text": "Your conversational response here."}
        '''),
      );

      final response = await model.generateContent([Content.text(userText)]);
      
      final String rawJson = response.text?.trim() ?? '{}';
      final Map<String, dynamic> parsedData = jsonDecode(rawJson);

      // If it's a multi-leg card, calculate exact deterministic fares via code
      if (parsedData['type'] == 'multi_leg_card') {
        final origin = parsedData['origin'] ?? '';
        final transfer = parsedData['transferStop'] ?? '';
        final destination = parsedData['destination'] ?? '';

        final calculatedFares = _calculateMultiLegFares(origin, transfer, destination, transitProvider);
        
        parsedData['totalStandardFare'] = calculatedFares['standard']?.toInt();
        parsedData['totalStudentFare'] = calculatedFares['student']?.toInt();
      }

      // Store in local cache
      _responseCache[cacheKey] = parsedData;

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

  Map<String, double> _calculateMultiLegFares(String origin, String transfer, String destination, TransitProvider provider) {
    double getLegFare(String org, String dest) {
      for (var matrixDoc in provider.fareMatrices) {
        final Map<String, dynamic> matrixMap = matrixDoc['matrix'] ?? {};
        final String key1 = '${org}_${dest}';
        final String key2 = '${dest}_${org}';
        
        if (matrixMap.containsKey(key1)) {
          return (matrixMap[key1]['standard'] as num?)?.toDouble() ?? 10.0;
        } else if (matrixMap.containsKey(key2)) {
          return (matrixMap[key2]['standard'] as num?)?.toDouble() ?? 10.0;
        }
      }
      return 15.0; 
    }

    double leg1Standard = getLegFare(origin, transfer);
    double leg2Standard = getLegFare(transfer, destination);
    double totalStandard = leg1Standard + leg2Standard;

    double totalStudent = totalStandard < 20.0 ? 10.0 : (totalStandard / 2).roundToDouble();
    if (totalStudent < 10.0) totalStudent = 10.0;

    return {
      'standard': totalStandard,
      'student': totalStudent,
    };
  }

  void _onRouteCardTapped(String busNameString) {
    final transitProvider = Provider.of<TransitProvider>(context, listen: false);

    final RegExp regExp = RegExp(r'\(([^)]+)\)');
    final match = regExp.firstMatch(busNameString);
    
    if (match != null) {
      final String routeTag = match.group(1)!;
      
      final matchingBus = transitProvider.buses.firstWhere(
        (b) => b.routeTag.toLowerCase() == routeTag.toLowerCase(),
        orElse: () => transitProvider.buses.isNotEmpty ? transitProvider.buses.first : throw('No buses available'),
      );

      transitProvider.selectBus(matchingBus);

      if (widget.onNavigateToMap != null) {
        widget.onNavigateToMap!();
      }
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
                } else if (msg['type'] == 'multi_leg_card') {
                  return _buildMultiLegCard(msg, langProvider);
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
    final String busNameStr = msg['busName'] ?? '';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _onRouteCardTapped(busNameStr),
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                      const Icon(Icons.touch_app, color: Colors.white70, size: 18),
                    ],
                  ),
                  if (busNameStr.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.directions_bus, color: Colors.greenAccent, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          busNameStr, 
                          style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFareBox(langProvider.t('Standard fare'), '৳${msg['standardFare']}'),
                      _buildFareBox(langProvider.t('Student fare'), '৳${msg['studentFare']}'),
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMultiLegCard(Map<String, dynamic> msg, LanguageProvider langProvider) {
    final String leg1Bus = msg['leg1Bus'] ?? '';
    final String origin = msg['origin'] ?? '';
    final String destination = msg['destination'] ?? '';
    final String transferStop = msg['transferStop'] ?? '';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _onRouteCardTapped(leg1Bus),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.alt_route, color: Colors.orangeAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$origin ➔ $destination', 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                        child: Text(langProvider.t('1 Transfer'), style: const TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  
                  // Leg 1
                  Row(
                    children: [
                      const Icon(Icons.directions_bus, color: Colors.greenAccent, size: 14),
                      const SizedBox(width: 6),
                      Text('${langProvider.t('Leg 1')}: $leg1Bus', style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${langProvider.t('Board at')} $origin ➔ ${langProvider.t('Get down at')} $transferStop', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Icon(Icons.arrow_downward, color: Colors.white54, size: 16),
                  ),

                  // Leg 2
                  Row(
                    children: [
                      const Icon(Icons.directions_bus, color: Colors.greenAccent, size: 14),
                      const SizedBox(width: 6),
                      Text('${langProvider.t('Leg 2')}: ${msg['leg2Bus']}', style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${langProvider.t('Board at')} $transferStop ➔ ${langProvider.t('Arrive at')} $destination', style: const TextStyle(color: Colors.white70, fontSize: 12)),

                  const SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFareBox(langProvider.t('Total Standard'), '৳${msg['totalStandardFare']}'),
                      _buildFareBox(langProvider.t('Total Student'), '৳${msg['totalStudentFare']}'),
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
            ),
          ),
        ),
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