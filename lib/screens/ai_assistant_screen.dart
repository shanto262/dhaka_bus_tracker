import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  
  final List<Map<String, dynamic>> _messages = [
    {
      'isBot': true,
      'type': 'text',
      'text': 'Hello! I\'m your AI Route Assistant for Dhaka. I can help you find the best bus routes, calculate fares, check student discounts, and give real-time traffic updates. Where would you like to go today?'
    },
  ];

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    
    setState(() {
      _messages.add({
        'isBot': false,
        'type': 'text',
        'text': _controller.text.trim(),
      });
      _controller.clear();
      
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _messages.add({
            'isBot': true,
            'type': 'route_card',
            'origin': 'Farmgate',
            'destination': 'Uttara',
            'standardFare': 35,
            'studentFare': 18,
            'eta': '45 min',
          });
        });
      });
    });
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
                Text(langProvider.t('Online - Live Traffic Data'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            )
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 16),
            label: Text(langProvider.t('New chat'), style: const TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
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
    bool isBot = msg['isBot'];
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
          langProvider.t(msg['text']),
          style: TextStyle(color: isBot ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87) : Colors.white),
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
              Text('${langProvider.t(msg['origin'])} ➔ ${langProvider.t(msg['destination'])}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
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
                  Text(msg['eta'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildChip(langProvider.t('Cheapest bus to Mirpur-10?'), langProvider),
          const SizedBox(width: 8),
          _buildChip(langProvider.t('Next bus from Motijheel'), langProvider),
        ],
      ),
    );
  }

  Widget _buildChip(String text, LanguageProvider langProvider) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      onPressed: () {
        _controller.text = text;
        _sendMessage();
      },
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
                  hintText: langProvider.t('Type your question...'),
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
              icon: const Icon(Icons.send),
              color: Theme.of(context).colorScheme.primary,
              onPressed: _sendMessage,
            )
          ],
        ),
      ),
    );
  }
}