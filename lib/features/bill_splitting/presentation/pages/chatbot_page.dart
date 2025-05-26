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

class _ChatbotPageState extends State<ChatbotPage>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController =
      ScrollController(); // To scroll to bottom
  final List<ChatMessageEntity> _messages = []; // List to hold chat messages
  List<String> _suggestions = []; // List for suggestions
  bool _isLoading = false; // To track bot response loading
  bool _isChatInitializing = true; // Flag to ensure init runs once
  bool _isDisposed = false; // Flag to check if widget is disposed

  // Animation controllers for modern UI
  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;

  // Get UseCase instance
  late final SendChatMessageUseCase _sendChatMessageUseCase;

  @override
  void initState() {
    super.initState();
    _sendChatMessageUseCase =
        sl<SendChatMessageUseCase>(); // Get instance from GetIt

    // Initialize animation controller for typing indicator
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _typingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _typingAnimationController, curve: Curves.easeInOut),
    );

    // _initializeChat(); // Moved to didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize chat here where context is available
    if (_isChatInitializing && !_isDisposed) {
      _initializeChat();
      _isChatInitializing = false; // Ensure it only runs once
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _messageController.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    // Scroll to the bottom after a short delay to allow the list to update
    if (_isDisposed) return; // Safety check

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && !_isDisposed) {
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
    if (_isDisposed) return; // Safety check

    setState(() {
      _isLoading = true; // Show loading for initial message
    });
    _typingAnimationController.repeat(); // Start typing animation
    _scrollToBottom();

    // Call the UseCase with an empty message to get initial suggestions/greeting
    final result = await _sendChatMessageUseCase(
      newMessage: "", // Empty message for initialization
      history: [], // No history initially
      billContextJson: widget
          .billJson, // Use the original JSON (already filtered in BillEditPage)
    );

    if (_isDisposed) return; // Safety check

    setState(() {
      _isLoading = false;
      _typingAnimationController.stop(); // Stop typing animation

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
    _typingAnimationController.repeat(); // Start typing animation
    _scrollToBottom();

    print("User sent message: $messageText");

    // Call the UseCase
    // Pass the current messages list as history (excluding the latest user message temporarily if needed by API)
    final historyToSend = List<ChatMessageEntity>.from(_messages);
    final result = await _sendChatMessageUseCase(
      newMessage: messageText,
      history: historyToSend,
      billContextJson: widget
          .billJson, // Pass the original bill context (already filtered in BillEditPage)
    );

    if (_isDisposed) return; // Safety check

    setState(() {
      _isLoading = false; // Hide loading
      _typingAnimationController.stop(); // Stop typing animation
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        // Perform any cleanup or navigation logic here if needed
        return true;
      },
      child: Scaffold(
        // Modern AppBar with gradient
        appBar: AppBar(
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withOpacity(0.8),
                ],
              ),
            ),
          ),
          title: Row(
            children: [
              // Bot avatar in AppBar
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.smart_toy_outlined,
                  size: 20,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.chatbotPageTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Bill Bot Assistant',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        // Chat background with subtle pattern
        body: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.grey[50],
          ),
          child: SafeArea(
            child: Column(
              children: [
                // --- Chat Messages Area ---
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Show typing indicator when loading
                      if (index == _messages.length && _isLoading) {
                        return _buildTypingIndicator();
                      }

                      final message = _messages[index];
                      return _buildModernMessageBubble(message, index);
                    },
                  ),
                ),

                // --- Suggestions Area ---
                if (_suggestions.isNotEmpty && !_isLoading)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                          child: Text(
                            'Quick replies',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.7),
                            ),
                          ),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _suggestions.map((suggestion) {
                              return Container(
                                margin: const EdgeInsets.only(right: 8.0),
                                child: _buildSuggestionChip(suggestion, theme),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),

                // --- Modern Input Area ---
                _buildModernInputArea(l10n, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Modern message bubble with animation and avatar
  Widget _buildModernMessageBubble(ChatMessageEntity message, int index) {
    bool isUser = message.sender == ChatMessageSender.user;
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment:
                    isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Bot avatar (only for bot messages)
                  if (!isUser) ...[
                    Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.smart_toy_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],

                  // Message bubble
                  Flexible(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: isUser
                            ? LinearGradient(
                                colors: [
                                  theme.primaryColor,
                                  theme.primaryColor.withOpacity(0.8),
                                ],
                              )
                            : null,
                        color: isUser ? null : theme.colorScheme.surface,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: isUser
                              ? const Radius.circular(18)
                              : const Radius.circular(4),
                          bottomRight: isUser
                              ? const Radius.circular(4)
                              : const Radius.circular(18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.text,
                            style: TextStyle(
                              color: isUser
                                  ? Colors.white
                                  : theme.textTheme.bodyMedium?.color,
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(message.timestamp),
                            style: TextStyle(
                              color: isUser
                                  ? Colors.white.withOpacity(0.7)
                                  : theme.textTheme.bodySmall?.color
                                      ?.withOpacity(0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // User avatar (only for user messages)
                  if (isUser) ...[
                    Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.primaryColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.person_outline,
                        color: theme.primaryColor,
                        size: 18,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Modern suggestion chip
  Widget _buildSuggestionChip(String suggestion, ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onSuggestionTap(suggestion),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.primaryColor.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            suggestion,
            style: TextStyle(
              color: theme.primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // Modern input area
  Widget _buildModernInputArea(AppLocalizations l10n, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: theme.dividerColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: l10n.chatbotPageInputHint,
                  hintStyle: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 12.0,
                  ),
                  prefixIcon: Icon(
                    Icons.chat_bubble_outline,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                    size: 20,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: _isLoading ? null : (_) => _sendMessage(),
                enabled: !_isLoading,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          // Modern send button
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isLoading
                    ? [Colors.grey, Colors.grey]
                    : [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_isLoading ? Colors.grey : theme.primaryColor)
                      .withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading ? null : _sendMessage,
                borderRadius: BorderRadius.circular(24),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Typing indicator for when bot is responding
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Bot avatar
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: Colors.white,
              size: 18,
            ),
          ),
          // Typing animation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _typingAnimation,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTypingDot(0),
                    const SizedBox(width: 4),
                    _buildTypingDot(1),
                    const SizedBox(width: 4),
                    _buildTypingDot(2),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Individual typing dot with animation
  Widget _buildTypingDot(int index) {
    final delay = index * 0.2;
    final animationValue = (_typingAnimation.value + delay) % 1.0;
    final scale = (animationValue < 0.5)
        ? 0.4 + (animationValue * 1.2)
        : 1.0 - ((animationValue - 0.5) * 1.2);

    return Transform.scale(
      scale: scale.clamp(0.4, 1.0),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color:
              Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  // Helper to format timestamp
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 5) {
      return 'now';
    } else if (difference.inMinutes < 1) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    }

    // Check if the message is from today
    final isToday = now.year == dateTime.year &&
        now.month == dateTime.month &&
        now.day == dateTime.day;

    if (isToday) {
      // If today and more than 1 hour ago, show time (HH:mm)
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      // If not today, show date and time (DD/MM HH:mm)
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
