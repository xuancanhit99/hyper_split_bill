import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert'; // For jsonDecode if needed later
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/chat_message_entity.dart'; // Import ChatMessageEntity
import 'package:hyper_split_bill/features/bill_splitting/domain/usecases/send_chat_message_usecase.dart'; // Import UseCase
import 'package:hyper_split_bill/injection_container.dart'; // Import sl for GetIt
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations

class ChatbotPage extends StatefulWidget {
  final String billJson; // Receive the final bill JSON

  const ChatbotPage({super.key, required this.billJson});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController =
      ScrollController(); // To scroll to bottom
  final List<ChatMessageEntity> _messages = []; // List to hold chat messages
  List<String> _suggestions = []; // List for suggestions
  bool _isLoading = false; // To track bot response loading
  bool _isChatInitializing = true; // Flag to ensure init runs once

  // Get UseCase instance
  late final SendChatMessageUseCase _sendChatMessageUseCase;

  @override
  void initState() {
    super.initState();
    _sendChatMessageUseCase =
        sl<SendChatMessageUseCase>(); // Get instance from GetIt
    // _initializeChat(); // Moved to didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize chat here where context is available
    if (_isChatInitializing) {
      _initializeChat();
      _isChatInitializing = false; // Ensure it only runs once
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    // Scroll to the bottom after a short delay to allow the list to update
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

  Future<void> _initializeChat() async {
    print("ChatbotPage initialized with Bill JSON:\n${widget.billJson}");
    setState(() {
      _isLoading = true; // Show loading for initial message
      _messages.add(ChatMessageEntity(
          sender: ChatMessageSender.bot,
          text: AppLocalizations.of(context)!
              .chatbotPageAnalyzingMessage, // Use l10n
          timestamp: DateTime.now()));
    });
    _scrollToBottom();

    // Call the UseCase with an empty message to get initial suggestions/greeting
    final result = await _sendChatMessageUseCase(
      newMessage: "", // Empty message for initialization
      history: [], // No history initially
      billContextJson: widget.billJson,
    );

    setState(() {
      _isLoading = false;
      // Remove the "Analyzing..." message
      _messages.removeLast();

      result.fold(
        (failure) {
          _messages.add(ChatMessageEntity(
            sender: ChatMessageSender.bot,
            text: AppLocalizations.of(context)!
                .chatbotPageErrorStartingChat(failure.message), // Use l10n
            timestamp: DateTime.now(),
          ));
        },
        (chatResponse) {
          _messages.add(ChatMessageEntity(
            sender: ChatMessageSender.bot,
            text: chatResponse.botMessage,
            timestamp: DateTime.now(),
          ));
          _suggestions = chatResponse.suggestions;
        },
      );
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage({String? text}) async {
    final messageText = text ?? _messageController.text.trim();
    if (messageText.isEmpty) return;

    // Add user message
    final userMessage = ChatMessageEntity(
      sender: ChatMessageSender.user,
      text: messageText,
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages.add(userMessage);
      _isLoading = true; // Show loading for bot response
      _suggestions = []; // Clear suggestions while bot is thinking
    });
    _messageController.clear();
    _scrollToBottom();

    print("User sent message: $messageText");

    // Call the UseCase
    // Pass the current messages list as history (excluding the latest user message temporarily if needed by API)
    final historyToSend = List<ChatMessageEntity>.from(_messages);
    final result = await _sendChatMessageUseCase(
      newMessage: messageText,
      history: historyToSend,
      billContextJson: widget.billJson, // Pass the bill context every time
    );

    setState(() {
      _isLoading = false; // Hide loading
      result.fold(
        (failure) {
          _messages.add(ChatMessageEntity(
            sender: ChatMessageSender.bot,
            text: AppLocalizations.of(context)!
                .chatbotPageErrorSendingMessage(failure.message), // Use l10n
            timestamp: DateTime.now(),
          ));
        },
        (chatResponse) {
          _messages.add(ChatMessageEntity(
            sender: ChatMessageSender.bot,
            text: chatResponse.botMessage,
            timestamp: DateTime.now(),
          ));
          _suggestions = chatResponse.suggestions;
        },
      );
    });
    _scrollToBottom();
  }

  void _onSuggestionTap(String suggestion) {
    print("Suggestion tapped: $suggestion");
    // Send the suggestion as a user message
    _sendMessage(text: suggestion);
  }

  @override
  Widget build(BuildContext context) {
    // Get the localization instance
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chatbotPageTitle), // Use l10n
      ),
      body: SafeArea(
        // Added SafeArea
        child: Column(
          children: [
            // --- Chat Messages Area ---
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8.0),
                itemCount: _messages.length, // Use actual message list length
                itemBuilder: (context, index) {
                  final message = _messages[index]; // Get actual message
                  return _buildMessageBubble(
                      message); // Use helper to build bubble
                },
              ),
            ),
            const Divider(height: 1.0),

            // --- Suggestions Area ---
            if (_suggestions.isNotEmpty &&
                !_isLoading) // Show only when not loading
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  alignment: WrapAlignment.center, // Center suggestions
                  children: _suggestions
                      .map((s) => ActionChip(
                            label: Text(s),
                            onPressed: () => _onSuggestionTap(s),
                            tooltip: l10n
                                .chatbotPageSuggestionTooltip(s), // Use l10n
                          ))
                      .toList(),
                ),
              ),
            if (_suggestions.isNotEmpty && !_isLoading)
              const Divider(
                  height: 1.0), // Divider above input if suggestions shown

            // --- Input Area ---
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        // Remove const
                        hintText: l10n.chatbotPageInputHint, // Use l10n
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 8.0), // Adjust padding
                      ),
                      textInputAction: TextInputAction.send, // Add send action
                      onSubmitted: _isLoading
                          ? null
                          : (_) =>
                              _sendMessage(), // Send on submit, disable if loading
                      enabled: !_isLoading, // Disable input field when loading
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  // Show loading indicator or send button
                  _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2)) // Loading indicator
                      : IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _sendMessage,
                          tooltip:
                              l10n.chatbotPageSendButtonTooltip, // Use l10n
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build message bubbles
  Widget _buildMessageBubble(ChatMessageEntity message) {
    bool isUser = message.sender == ChatMessageSender.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        decoration: BoxDecoration(
          // Custom blue for user, theme color for bot
          color: isUser
              ? const Color(0xFF0084FF) // Facebook Messenger blue
              : Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16.0),
            topRight: const Radius.circular(16.0),
            bottomLeft: isUser ? const Radius.circular(16.0) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(16.0),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            // White text for user bubble, theme color for bot
            color: isUser
                ? Colors.white
                : Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
