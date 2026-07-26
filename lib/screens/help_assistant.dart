import 'package:flutter/material.dart';
import 'package:local_app_tt/navigation/app_navigation.dart';
import 'package:local_app_tt/screens/civsnap_portal.dart';
import 'package:local_app_tt/screens/dog_registration.dart';
import 'package:local_app_tt/screens/forms/forms_hub.dart';
import 'package:local_app_tt/services/chatbot_service.dart';
import 'package:local_app_tt/widgets/breadcrumbs.dart';

class HelpAssistantScreen extends StatefulWidget {
  const HelpAssistantScreen({super.key});

  @override
  State<HelpAssistantScreen> createState() => _HelpAssistantScreenState();
}

class _ChatMessage {
  final String text;
  final bool fromUser;
  final ChatbotAction? action;
  final List<String> suggestions;

  const _ChatMessage({
    required this.text,
    required this.fromUser,
    this.action,
    this.suggestions = const [],
  });
}

class _HelpAssistantScreenState extends State<HelpAssistantScreen> {
  final ChatbotService _bot = ChatbotService.instance;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  String _disclaimer = '';
  bool _thinking = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final greeting = await _bot.greeting();
    final disclaimer = await _bot.disclaimer();
    final topics = await _bot.starterTopics();
    if (!mounted) return;
    setState(() {
      _disclaimer = disclaimer;
      _messages.add(_ChatMessage(
        text: greeting,
        fromUser: false,
        suggestions: topics,
      ));
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _thinking) return;
    _controller.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, fromUser: true));
      _thinking = true;
    });
    _scrollToBottom();

    final reply = await _bot.ask(text);
    if (!mounted) return;
    setState(() {
      _thinking = false;
      _messages.add(_ChatMessage(
        text: reply.text,
        fromUser: false,
        action: reply.action,
        suggestions: reply.suggestions,
      ));
    });
    _scrollToBottom();
  }

  void _runAction(ChatbotAction action) {
    switch (action.route) {
      case 'dog_registration':
        Navigator.of(context).push(DogRegistrationScreen.route());
        break;
      case 'civsnap':
        Navigator.of(context).push(CivSnapPortalScreen.route());
        break;
      case 'forms':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const FormsHubScreen(
              scope: 'public',
              title: 'Public Forms',
            ),
          ),
        );
        break;
      case 'settings':
        AppNavigation.goToTab(context, AppNavigation.tabSettings);
        break;
      case 'home':
      default:
        AppNavigation.goHome(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Breadcrumbs(
                    items: [
                      BreadcrumbItem('Home', onTap: () => AppNavigation.goHome(context)),
                      const BreadcrumbItem('Help Assistant'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.14),
                        child: Icon(Icons.support_agent, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Help Assistant',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'Answers from the Trini Hub help guide',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_disclaimer.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: theme.hintColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _disclaimer,
                          style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                itemCount: _messages.length + (_thinking ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _messages.length) {
                    return const _TypingIndicator();
                  }
                  final message = _messages[index];
                  return _MessageBubble(
                    message: message,
                    onSuggestionTap: _send,
                    onActionTap: _runAction,
                  );
                },
              ),
            ),
            _Composer(
              controller: _controller,
              enabled: !_thinking,
              onSend: () => _send(_controller.text),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final ValueChanged<String> onSuggestionTap;
  final ValueChanged<ChatbotAction> onActionTap;

  const _MessageBubble({
    required this.message,
    required this.onSuggestionTap,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fromUser = message.fromUser;
    final bubbleColor = fromUser ? theme.colorScheme.primary : theme.colorScheme.surface;
    final textColor = fromUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Align(
            alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(fromUser ? 16 : 4),
                  bottomRight: Radius.circular(fromUser ? 4 : 16),
                ),
                border: fromUser ? null : Border.all(color: Colors.black.withOpacity(0.06)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
              ),
            ),
          ),
          if (message.action != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: () => onActionTap(message.action!),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(message.action!.label),
              ),
            ),
          ],
          if (message.suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: message.suggestions.map((suggestion) {
                return ActionChip(
                  label: Text(suggestion),
                  onPressed: () => onSuggestionTap(suggestion),
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
                  side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.25)),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: theme.hintColor),
              ),
              const SizedBox(width: 10),
              Text('Thinking…', style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Ask a question…',
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: enabled ? onSend : null,
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(14),
            ),
            child: const Icon(Icons.send_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}
