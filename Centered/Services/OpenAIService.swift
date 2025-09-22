import Foundation

class OpenAIService: ObservableObject {
    private let apiKey: String
    private let apiURL = URL(string: "https://api.openai.com/v1/chat/completions")!
    
    init() {
        // Initialize with API key from Config.plist
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let key = config["OpenAIAPIKey"] as? String else {
            fatalError("OpenAI API key not found in Config.plist")
        }
        
        self.apiKey = key
    }
    
    /// Generates AI response using GPT-5 mini with reasoning and verbosity controls
    func generateAIResponse(for prompt: String) async throws -> String {
        print("🤖 Sending request to OpenAI API with prompt: \(prompt.prefix(100))...")
        
        // Create the request body for OpenAI Chat Completions API
        let requestBody: [String: Any] = [
            "model": "gpt-5-mini",
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_completion_tokens": 500,
            "reasoning_effort": "low",      // optional, if less "thinking" is okay
            "verbosity": "medium"           // controls how detailed/concise outputs are
        ]
        
        // Create URL request
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw OpenAIError.configurationError("Failed to serialize request body: \(error.localizedDescription)")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 OpenAI API HTTP Status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    
                    // Handle specific OpenAI error cases
                    if httpResponse.statusCode == 429 {
                        // Parse error details for quota issues
                        if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let error = errorData["error"] as? [String: Any],
                           let type = error["type"] as? String,
                           type == "insufficient_quota" {
                            throw OpenAIError.quotaExceeded
                        } else {
                            throw OpenAIError.rateLimited
                        }
                    } else if httpResponse.statusCode == 401 {
                        throw OpenAIError.invalidAPIKey
                    } else {
                        throw OpenAIError.apiError("HTTP \(httpResponse.statusCode): \(errorMessage)")
                    }
                }
            }
            
            // Parse JSON response
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw OpenAIError.invalidResponse("Invalid JSON response")
            }
            
            // Extract the AI response content
            guard let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                throw OpenAIError.invalidResponse("No content in response")
            }
            
            print("✅ OpenAI API response received: \(content.prefix(100))...")
            return content
            
        } catch let error as OpenAIError {
            throw error
        } catch {
            print("❌ OpenAI API network error: \(error.localizedDescription)")
            throw OpenAIError.apiError("Network error: \(error.localizedDescription)")
        }
    }
}

// MARK: - OpenAI Error Types
enum OpenAIError: Error, LocalizedError {
    case invalidResponse(String)
    case apiError(String)
    case configurationError(String)
    case quotaExceeded
    case rateLimited
    case invalidAPIKey
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse(let message):
            return "Invalid OpenAI response: \(message)"
        case .apiError(let message):
            return "OpenAI API error: \(message)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .quotaExceeded:
            return "OpenAI quota exceeded. Please check your billing and usage limits at https://platform.openai.com/usage"
        case .rateLimited:
            return "OpenAI rate limit exceeded. Please wait a moment and try again."
        case .invalidAPIKey:
            return "Invalid OpenAI API key. Please check your API key configuration."
        }
    }
}
