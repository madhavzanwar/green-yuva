import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ai_message.dart';
import '../models/user.dart';
import '../services/ai_service.dart';
import '../widgets/ai_message_bubble.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';
import '../services/language_service.dart';

class AIChatScreen extends StatefulWidget {
  final AppUser user;

  const AIChatScreen({
    super.key,
    required this.user,
  });

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AIMessage> _messages = [];
  bool _isLoading = false;
  String _conversationId = '';

  @override
  void initState() {
    super.initState();
    _conversationId = DateTime.now().millisecondsSinceEpoch.toString();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    final bool isHindi = LanguageService.instance.isHindi;
    final welcomeMessage = AIMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: isHindi
          ? 'नमस्ते! मैं युवा साथी (YuvaSathi) हूँ, आपका ग्रीन युवा पर्यावरण गाइड और जलवायु ट्यूटर। मुझसे भारतीय कैंपस स्थिरता, पर्यावरण मिशन, आपदा प्रबंधन या इको क्विज़ के बारे में कुछ भी पूछें! 🌿'
          : 'Namaste! I am ClimaAI (YuvaSathi), your Green Yuva climate tutor and environmental guide. Ask me about Indian campus sustainability, climate action missions, disaster resilience, or quiz preparation! 🌿',
      type: MessageType.ai,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      conversationId: _conversationId,
    );
    setState(() {
      _messages.add(welcomeMessage);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _navigateHome() {
    final mainScreenState = context.findAncestorStateOfType<MainScreenState>();
    if (mainScreenState != null) {
      mainScreenState.onItemTapped(0);
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paperCream,
      appBar: AppBar(
        backgroundColor: AppColors.paperCream,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: NeoBackButton(
              onPressed: _navigateHome,
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.butterYellow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.solidBlack, width: 2.0),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: AppColors.solidBlack, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'YuvaSathi AI',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: AppColors.solidBlack,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: const [SizedBox(width: 50)],
      ),
      body: PaperGridBackground(
        child: Column(
          children: [
            // Suggestion chips
            Container(
              height: 38,
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildQuickPromptChip('Explain Solar Hubs ☀️'),
                  const SizedBox(width: 8),
                  _buildQuickPromptChip('Tips to reduce campus waste ♻️'),
                  const SizedBox(width: 8),
                  _buildQuickPromptChip('Quiz preparation quiz 📚'),
                  const SizedBox(width: 8),
                  _buildQuickPromptChip('Maharashtra flood prep 🌧️'),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return AIMessageBubble(message: _messages[index]);
                },
              ),
            ),

            if (_isLoading)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.solidBlack, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.solidBlack),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'YuvaSathi is thinking...',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.solidBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPromptChip(String prompt) {
    return InkWell(
      onTap: () => _sendMessage(prompt),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.solidBlack, width: 1.5),
          boxShadow: const [
            BoxShadow(color: AppColors.solidBlack, offset: Offset(1.5, 2), blurRadius: 0),
          ],
        ),
        child: Text(
          prompt,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.solidBlack,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 85),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AppColors.solidBlack, width: 2.0),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.solidBlack,
                    offset: Offset(2, 2.5),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: TextField(
                controller: _messageController,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: AppColors.solidBlack,
                ),
                decoration: InputDecoration(
                  hintText: 'Ask YuvaSathi anything...',
                  border: InputBorder.none,
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                onSubmitted: (text) => _sendMessage(text),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _sendMessage(_messageController.text),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.butterYellow,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.solidBlack, width: 2.0),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.solidBlack,
                    offset: Offset(2, 2.5),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_upward_rounded,
                color: AppColors.solidBlack,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty || _isLoading) return;

    final userMessage = AIMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text.trim(),
      type: MessageType.user,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      conversationId: _conversationId,
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    AIService.sendMessage(text, conversationId: _conversationId).then((response) {
      final aiMessage = AIMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response.content,
        type: MessageType.ai,
        timestamp: DateTime.now(),
        status: response.isError ? MessageStatus.error : MessageStatus.sent,
        conversationId: _conversationId,
      );

      if (mounted) {
        setState(() {
          _messages.add(aiMessage);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }).catchError((error) {
      final errorMessage = AIMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Sorry, I encountered an error connecting to the AI tutor. Please try again.',
        type: MessageType.ai,
        timestamp: DateTime.now(),
        status: MessageStatus.error,
        conversationId: _conversationId,
      );

      if (mounted) {
        setState(() {
          _messages.add(errorMessage);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
