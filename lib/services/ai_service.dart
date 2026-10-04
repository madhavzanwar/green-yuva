import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_message.dart';
import '../utils/glm_config.dart';
import '../utils/env_config.dart';

class AIService {
  static final Map<String, List<Map<String, dynamic>>> _conversationContexts = {};

  static Future<AIResponse> sendMessage(String message, {String? conversationId}) async {
    try {
      if (conversationId != null) {
        if (!_conversationContexts.containsKey(conversationId)) {
          _conversationContexts[conversationId] = [];
        }
        _conversationContexts[conversationId]!.add({
          'role': 'user',
          'content': message,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      final prompt = _buildIntelligentPrompt(message, conversationId);

      try {
        final response = await _sendToAI(prompt);
        if (response != null && response.content.trim().isNotEmpty) {
          if (conversationId != null) {
            _conversationContexts[conversationId]!.add({
              'role': 'assistant',
              'content': response.content,
              'timestamp': DateTime.now().toIso8601String(),
            });
          }
          return response;
        }
      } catch (e) {
        print('❌ AI API failed: $e');
      }

      final fallbackResponse = _getContextualFallbackResponse(message, conversationId);

      if (conversationId != null) {
        _conversationContexts[conversationId]!.add({
          'role': 'assistant',
          'content': fallbackResponse.content,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      return fallbackResponse;
    } catch (e) {
      print('❌ Error in AI service: $e');
      return AIResponse(
        content: 'I apologize, but I\'m having trouble processing your request right now. Please try again in a moment.',
        isError: true,
        errorMessage: e.toString(),
      );
    }
  }

  static Future<AIResponse?> _sendToAI(String prompt) async {
    final priorityEndpoints = ['gemini', 'palm', 'local'];

    for (final endpointName in priorityEndpoints) {
      try {
        print('🔄 Trying $endpointName...');
        final response = await _tryEndpoint(endpointName, prompt);
        if (response != null && response.content.isNotEmpty) {
          print('✅ Success with $endpointName');
          return response;
        }
      } catch (e) {
        print('❌ $endpointName API failed: $e');
        continue;
      }
    }

    print('⚠️ All AI endpoints failed, using contextual fallback responses');
    return null;
  }

  static Future<AIResponse?> _tryEndpoint(String endpointName, String prompt) async {
    final config = GLMConfig.getEndpoint(endpointName);
    if (config == null) return null;

    try {
      final headers = Map<String, String>.from(config['headers']);
      if (endpointName == 'gemini') {
        final apiKey = EnvConfig.geminiApiKey;
        if (apiKey.isEmpty || apiKey == 'your_gemini_api_key_here') {
          return null;
        }
        final url = '${config['url']}?key=$apiKey';
        final response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode(_buildRequestBody(endpointName, prompt, config)),
        );
        return _handleResponse(response, endpointName, config);
      } else {
        if (config['url'] == 'local') return null;
        final response = await http.post(
          Uri.parse(config['url']),
          headers: headers,
          body: jsonEncode(_buildRequestBody(endpointName, prompt, config)),
        );
        return _handleResponse(response, endpointName, config);
      }
    } catch (e) {
      print('❌ $endpointName API error: $e');
      return null;
    }
  }

  static Future<AIResponse?> _handleResponse(http.Response response, String endpointName, Map<String, dynamic> config) async {
    try {
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = _extractContent(data, endpointName);

        if (content.isNotEmpty) {
          return AIResponse(
            content: _cleanAIResponse(content),
            metadata: {
              'model': config['model'],
              'source': '$endpointName-api',
            },
          );
        }
      } else {
        print('❌ $endpointName API error: ${response.statusCode} - ${response.body}');
      }

      return null;
    } catch (e) {
      print('❌ $endpointName API error: $e');
      return null;
    }
  }

  static Map<String, dynamic> _buildRequestBody(String endpointName, String prompt, Map<String, dynamic> config) {
    switch (endpointName) {
      case 'gemini':
        return {
          'contents': [
            {
              'parts': [
                {
                  'text': prompt
                }
              ]
            }
          ],
          'systemInstruction': {
            'parts': [
              {
                'text': GLMConfig.systemPrompt,
              }
            ]
          },
          'generationConfig': config['parameters'],
        };

      default:
        return {
          'inputs': prompt,
          'parameters': config['parameters'],
        };
    }
  }

  static String _extractContent(dynamic data, String endpointName) {
    switch (endpointName) {
      case 'gemini':
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          if (candidate['content'] != null && candidate['content']['parts'] != null) {
            final parts = candidate['content']['parts'] as List;
            if (parts.isNotEmpty && parts[0]['text'] != null) {
              return parts[0]['text'];
            }
          }
        }
        break;
      default:
        if (data is Map && data['generated_text'] != null) {
          return data['generated_text'];
        }
    }
    return '';
  }

  static String _buildIntelligentPrompt(String message, String? conversationId) {
    final context = conversationId != null ? _conversationContexts[conversationId] : null;
    final recentMessages = context?.take(4).map((m) => '${m['role'] == 'user' ? 'Student' : 'YuvaSathi'}: ${m['content']}').join('\n') ?? '';

    return '''
Recent conversation history:
$recentMessages

Student's current question: $message

Please provide a direct, helpful, and factually rich response. Explain key points clearly with relevant Indian climate context or Green Yuva platform guidance when applicable.
''';
  }

  static String _cleanAIResponse(String response) {
    // Only strip leading AI role tags (e.g. "ClimaAI:", "Assistant:"), NOT sentences with colons!
    response = response.replaceFirst(RegExp(r'^(?:AI|Model|Assistant|ClimaAI|YuvaSathi):\s*', caseSensitive: false), '').trim();
    response = response.replaceAll(RegExp(r'<\|.*?\|>'), '').trim();

    return response;
  }

  static AIResponse _getContextualFallbackResponse(String message, String? conversationId) {
    final contextualResponse = GLMConfig.getContextualFallbackResponse(message);

    return AIResponse(
      content: contextualResponse,
      metadata: {
        'source': 'clima-knowledge-engine',
        'note': 'YuvaSathi verified knowledge base',
      },
    );
  }

  static Future<AIConversation> getConversation(String conversationId) async {
    final messages = _conversationContexts[conversationId] ?? [];
    return AIConversation(
      id: conversationId,
      userId: 'current_user',
      title: 'Climate Chat',
      createdAt: DateTime.now(),
      messages: messages.map((msg) => AIMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: msg['content']?.toString() ?? '',
        type: msg['role'] == 'user' ? MessageType.user : MessageType.ai,
        timestamp: DateTime.tryParse(msg['timestamp']?.toString() ?? '') ?? DateTime.now(),
        status: MessageStatus.sent,
        conversationId: conversationId,
      )).toList(),
    );
  }

  static void clearConversation(String conversationId) {
    _conversationContexts.remove(conversationId);
  }
}
