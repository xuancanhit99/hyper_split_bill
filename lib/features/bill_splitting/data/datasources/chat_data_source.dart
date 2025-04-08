// Defines the contract for interacting with a chat API (like Gemini or Grok).
abstract class ChatDataSource {
  // Sends a message and optional history to the chat API.
  // Returns the model's response text.
  Future<String> sendMessage({
    required String message,
    List<Map<String, String>>?
        history, // e.g., [{"role": "user", "content": "..."}, {"role": "assistant", "content": "..."}]
    String? modelName, // Optional: Specify model
  });
}
