import 'dart:convert'; // Import for jsonDecode
import 'package:fpdart/fpdart.dart';
import 'package:hyper_split_bill/core/error/failures.dart';
import 'package:hyper_split_bill/features/bill_splitting/data/datasources/chat_data_source.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/chat_message_entity.dart'; // Import message entity
import 'package:injectable/injectable.dart';
import 'package:hyper_split_bill/core/prompts/chat_prompts.dart'; // Import chat prompts
import 'package:hyper_split_bill/core/providers/locale_provider.dart'; // Import LocaleProvider

// Define a simple structure for the chat response
class ChatResponse {
  final String botMessage;
  final List<String> suggestions;

  ChatResponse({required this.botMessage, this.suggestions = const []});
}

@lazySingleton
class SendChatMessageUseCase {
  final ChatDataSource chatDataSource;
  final LocaleProvider localeProvider; // Add LocaleProvider dependency

  SendChatMessageUseCase(
      this.chatDataSource, this.localeProvider); // Inject LocaleProvider

  // Takes the new message, the history, and the initial bill context.
  // Returns the bot's response or a Failure.
  Future<Either<Failure, ChatResponse>> call({
    required String newMessage,
    required List<ChatMessageEntity> history,
    required String billContextJson, // The initial bill JSON
  }) async {
    try {
      // Construct the full message history/context to send to the API
      // You might want to format this differently depending on the API requirements
      final historyString = history
          .map((msg) =>
              "${msg.sender == ChatMessageSender.user ? 'User' : 'Bot'}: ${msg.text}")
          .join('\n');

      // Combine initial context, history, and new message
      // Adjust the prompt structure as needed for your specific Chat API
      // Get current locale code
      final currentLanguageCode = localeProvider.locale.languageCode;

      // Combine initial context, history, and new message
      // Adjust the prompt structure as needed for your specific Chat API
      final fullPrompt = chatPrompt
          .replaceFirst(languageCodePlaceholder,
              currentLanguageCode) // Replace language placeholder
          .replaceFirst(billContextPlaceholder, billContextJson)
          .replaceFirst(historyStringPlaceholder, historyString)
          .replaceFirst(newMessagePlaceholder, newMessage);

      print("--- Sending Prompt to Chat API ---");
      print(fullPrompt);
      print("---------------------------------");

      final responseString = await chatDataSource.sendMessage(
        message: fullPrompt,
        // Optionally specify model if needed by datasource
      );

      print("--- Received Response from Chat API ---");
      print(responseString);
      print("------------------------------------");

      // Attempt to parse the response JSON
      try {
        // Clean potential markdown fences (though prompt requests not to use them)
        String cleanedResponse = responseString.trim();
        final RegExp jsonBlockRegex =
            RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```', multiLine: true);
        final match = jsonBlockRegex.firstMatch(cleanedResponse);
        if (match != null && match.groupCount >= 1) {
          cleanedResponse = match.group(1)!.trim();
          print("Extracted JSON from markdown block in chat response.");
        }

        final decodedJson = jsonDecode(cleanedResponse) as Map<String, dynamic>;

        if (decodedJson.containsKey('response') &&
            decodedJson.containsKey('suggestions')) {
          final botMessage = decodedJson['response'] as String;
          final suggestions = (decodedJson['suggestions'] as List<dynamic>?)
                  ?.map((s) => s.toString())
                  ?.toList() ??
              [];
          return Right(
              ChatResponse(botMessage: botMessage, suggestions: suggestions));
        } else {
          print(
              "Error: Chat API response JSON missing required keys ('response', 'suggestions').");
          // Fallback: return the raw string as the message if parsing fails structurally
          return Right(ChatResponse(botMessage: responseString));
        }
      } catch (e) {
        print(
            "Error parsing Chat API response JSON: $e. Returning raw response.");
        // Fallback: return the raw string as the message if parsing fails
        return Right(ChatResponse(botMessage: responseString));
      }
    } catch (e) {
      print("Error calling ChatDataSource: $e");
      // Convert generic exception to a Failure type if needed
      return Left(ServerFailure(
          'Failed to get response from Chatbot: ${e.runtimeType}'));
    }
  }
}
