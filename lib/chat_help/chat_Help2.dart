import 'dart:convert';
import 'package:datazen/core/globalvariables.dart';
import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:http/http.dart' as http;
import 'package:glass_kit/glass_kit.dart';


class FinanceAdvisorChat extends StatefulWidget {
  const FinanceAdvisorChat({super.key});

  @override
  State<FinanceAdvisorChat> createState() => _FinanceAdvisorChatState();
}

class _FinanceAdvisorChatState extends State<FinanceAdvisorChat>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  ChatUser myself = ChatUser(id: '1', firstName: 'User ');
  ChatUser bot = ChatUser(
    id: '2',
    firstName: 'Chanakya',
    profileImage: 'assets/images/advisor_avatar.png',
  );

  List<ChatMessage> allMessages = [];
  List<ChatUser> typing = [];

  // Update this line with your friend's ngrok URL
  final String ragBotUrl = '${GlobalVariable.url}/chatbot';
  final Map<String, String> headers = {
    "Content-Type": "application/json",
    // Add any additional headers if required
    // 'Authorization': 'Bearer your-token-if-needed',
  };

  // Finance-related keywords
  List<String> financeKeywords = [
    'sectors'
        'stock',
    'market',
    'investment',
    'trading',
    'portfolio',
    'dividend',
    'equity',
    'bond',
    'mutual fund',
    'crypto',
    'bitcoin',
    'forex',
    'finance',
    'bank',
    'interest',
    'profit',
    'loss',
    'risk',
    'asset',
    'liability',
    'bull',
    'bear',
    'market cap',
    'volatility',
    'hedge'
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.forward();

    // Add welcome message
    allMessages.insert(
        0,
        ChatMessage(
          text:
              "Namaste! I am Chanakya, your personal finance advisor. How may I assist you with your investment journey today?",
          user: bot,
          createdAt: DateTime.now(),
        ));
  }

  bool isFinanceRelated(String message) {
    return financeKeywords.any(
        (keyword) => message.toLowerCase().contains(keyword.toLowerCase()));
  }

  getdata(ChatMessage m) async {
    typing.add(bot);
    allMessages.insert(0, m);
    setState(() {});

    var data = {
      "query": m.text // Format the request as specified
    };

    try {
      final response = await http.post(
        Uri.parse(ragBotUrl),
        headers: headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        // Extract cohere_output from the response
        String botResponse =
            result['cohere_output'] ?? 'Sorry, I could not process that.';

        ChatMessage m1 = ChatMessage(
            text: botResponse, user: bot, createdAt: DateTime.now());
        allMessages.insert(0, m1);
      } else {
        throw Exception('Failed to get response');
      }
    } catch (e) {
      ChatMessage m1 = ChatMessage(
          text:
              "I apologize, but I'm having trouble connecting to my knowledge base. Please try again in a moment.",
          user: bot,
          createdAt: DateTime.now());
      allMessages.insert(0, m1);
    }

    typing.remove(bot);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, Color(0xFF0D1B2A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: GlassContainer(
                  height: double.infinity,
                  width: double.infinity,
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  borderGradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  blur: 20,
                  borderRadius: BorderRadius.circular(30),
                  borderWidth: 1.5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: DashChat(
                      typingUsers: typing,
                      currentUser: myself,
                      onSend: (ChatMessage m) {
                        getdata(m);
                      },
                      messages: allMessages,
                      messageOptions: MessageOptions(
                        currentUserContainerColor: Colors.blue.withOpacity(0.7),
                        containerColor: Colors.grey.withOpacity(0.3),
                        textColor: Colors.white,
                        showTime: true,
                      ),
                      inputOptions: InputOptions(
                        inputDecoration: InputDecoration(
                          hintText: "Ask about finance...",
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        sendButtonBuilder: (onSend) => IconButton(
                          icon: Icon(
                            Icons.send_rounded,
                            color: Colors.blue,
                          ),
                          onPressed: onSend,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Image.asset(
              "assets/images/advisor_avatar.png",
              width: 40,
              height: 40,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chanakya Dhan Niti',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Your Financial Wisdom Guide',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.white70),
            onPressed: () => _showInfoDialog(),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassContainer(
            height: 300,
            width: double.infinity,
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderGradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
            ),
            blur: 20,
            borderRadius: BorderRadius.circular(20),
            borderWidth: 1.5,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'About Chanakya Dhan Niti',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Chanakya Dhan Niti combines ancient financial wisdom with modern market intelligence to provide you with comprehensive financial guidance. Ask about investments, market analysis, trading strategies, and more.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text('Got it'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
