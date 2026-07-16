import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// An optional in-app action a chat answer can point the user to.
class ChatbotAction {
  final String label;
  final String route;

  const ChatbotAction({required this.label, required this.route});

  factory ChatbotAction.fromJson(Map<String, dynamic> json) {
    return ChatbotAction(
      label: json['label'] as String? ?? 'Open',
      route: json['route'] as String? ?? 'home',
    );
  }
}

class FaqEntry {
  final String id;
  final String question;
  final List<String> keywords;
  final String answer;
  final ChatbotAction? action;
  final List<String> related;

  const FaqEntry({
    required this.id,
    required this.question,
    required this.keywords,
    required this.answer,
    this.action,
    this.related = const [],
  });

  factory FaqEntry.fromJson(Map<String, dynamic> json) {
    return FaqEntry(
      id: json['id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      keywords: (json['keywords'] as List<dynamic>? ?? [])
          .map((e) => e.toString().toLowerCase())
          .toList(),
      answer: json['answer'] as String? ?? '',
      action: json['action'] is Map<String, dynamic>
          ? ChatbotAction.fromJson(json['action'] as Map<String, dynamic>)
          : null,
      related: (json['related'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class ChatbotReply {
  final String text;
  final ChatbotAction? action;
  final List<String> suggestions;

  /// Whether we matched a real FAQ entry (vs. a safety block or fallback).
  final bool matched;

  const ChatbotReply({
    required this.text,
    this.action,
    this.suggestions = const [],
    this.matched = false,
  });
}

/// Offline FAQ assistant.
///
/// Loads a curated knowledge base from `assets/knowledge_base.json` and answers
/// questions by scoring the user's message against each entry's keywords and
/// question text. There are no network calls, so nothing the user types leaves
/// the device. The design leaves room for an online LLM mode later (see
/// `ChatbotDesign.md`), but offline mode is fully self-contained.
class ChatbotService {
  ChatbotService._();
  static final ChatbotService instance = ChatbotService._();

  static const String _assetPath = 'assets/knowledge_base.json';

  // Terms we deliberately refuse to reason about, per the safety layer.
  static const List<String> _sensitiveTerms = [
    'password is',
    'my password',
    'credit card',
    'social security',
    'lawsuit',
    'sue ',
    'legal advice',
  ];

  Map<String, dynamic>? _cache;

  Future<Map<String, dynamic>> _load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(_assetPath);
    _cache = json.decode(raw) as Map<String, dynamic>;
    return _cache!;
  }

  Future<List<FaqEntry>> _entries() async {
    final data = await _load();
    return (data['faqs'] as List<dynamic>? ?? [])
        .map((e) => FaqEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> greeting() async {
    final data = await _load();
    return data['greeting'] as String? ??
        "Hi! Ask me anything about using Trini Hub.";
  }

  Future<String> disclaimer() async {
    final data = await _load();
    return data['disclaimer'] as String? ?? '';
  }

  /// The first few FAQ questions, used to seed starter suggestion chips.
  Future<List<String>> starterTopics({int limit = 4}) async {
    final entries = await _entries();
    return entries.take(limit).map((e) => e.question).toList();
  }

  Future<ChatbotReply> ask(String message) async {
    final data = await _load();
    final query = message.toLowerCase().trim();

    if (query.isEmpty) {
      return ChatbotReply(
        text: data['fallback'] as String? ?? 'Try asking a question.',
        suggestions: await starterTopics(),
      );
    }

    if (_sensitiveTerms.any(query.contains)) {
      return const ChatbotReply(
        text:
            "I can't help with sensitive personal, financial, or legal matters. "
            "Please reach out to the support team through the User Support Hub for "
            "anything account-specific.",
      );
    }

    final entries = await _entries();
    final queryTokens = _tokenize(query);

    FaqEntry? best;
    var bestScore = 0;
    for (final entry in entries) {
      final score = _score(entry, query, queryTokens);
      if (score > bestScore) {
        bestScore = score;
        best = entry;
      }
    }

    // Require at least one keyword-level hit to avoid confident nonsense.
    if (best == null || bestScore < 2) {
      return ChatbotReply(
        text: data['fallback'] as String? ??
            "I'm not sure about that yet — try one of these topics.",
        suggestions: await starterTopics(),
      );
    }

    return ChatbotReply(
      text: best.answer,
      action: best.action,
      suggestions: best.related,
      matched: true,
    );
  }

  int _score(FaqEntry entry, String query, Set<String> queryTokens) {
    var score = 0;
    for (final keyword in entry.keywords) {
      if (query.contains(keyword)) {
        score += 2;
      }
    }
    for (final token in _tokenize(entry.question.toLowerCase())) {
      if (token.length > 3 && queryTokens.contains(token)) {
        score += 1;
      }
    }
    return score;
  }

  Set<String> _tokenize(String text) {
    return text
        .replaceAll(RegExp(r"[^a-z0-9\s]"), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toSet();
  }
}
