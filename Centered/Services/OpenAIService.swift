import Foundation

class OpenAIService: ObservableObject {
    private let apiKey: String
    private let chatCompletionsURL = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let responsesURL = URL(string: "https://api.openai.com/v1/responses")!
    
    init() {
        // Initialize with API key from Config.plist
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let key = config["OpenAIAPIKey"] as? String else {
            fatalError("OpenAI API key not found in Config.plist")
        }
        
        self.apiKey = key
    }
    
    /// Generates AI response using specified GPT model with reasoning and verbosity controls
    /// - Parameters:
    ///   - prompt: The prompt to send to the AI
    ///   - model: The model to use ("gpt-5" uses new /v1/responses endpoint, others use /v1/chat/completions)
    ///   - analysisType: The type of analysis ("weekly" or "monthly") to determine system message
    func generateAIResponse(for prompt: String, model: String = "gpt-5", analysisType: String = "weekly") async throws -> String {
        print("🤖 Sending request to OpenAI API with model: \(model), analysisType: \(analysisType), prompt: \(prompt.prefix(100))...")
        
        // Determine system message based on analysis type
        let systemMessage: String
        if analysisType == "monthly" {
            systemMessage = """
You are an AI Behavioral Therapist/Scientist. 

Your job is to analyze the user's journal input and produce:

1) top four moods (one word each) + count in format: mood(#), mood(#), ...

2) a summary + actionable steps + a goal for the next week

3) a mental health "centered score" from 60–100

The tone must be encouraging, supportive, and concise.

Do NOT exceed ~200 words in paragraph 2.
"""
        } else {
            // Weekly analysis
            systemMessage = """
You are an AI Behavioral Therapist/Scientist. 

Your job is to analyze the user's journal input and produce:

1) top three moods (one word each) + count in format: mood(#), mood(#), ...

2) a summary + actionable steps + a goal for the next week

3) a mental health "centered score" from 60–100

The tone must be encouraging, supportive, and concise.

Do NOT exceed ~200 words in paragraph 2.
"""
        }
        
        // GPT-5 uses different endpoint and structure
        let isGPT5 = model == "gpt-5"
        
        // Create the request body - different structure for GPT-5 vs other models
        let requestBody: [String: Any]
        let apiURL: URL
        
        if isGPT5 {
            // GPT-5 uses /v1/responses endpoint with new structure
            apiURL = responsesURL
            var body: [String: Any] = [
                "model": model,
                "input": [
                    [
                        "role": "system",
                        "content": systemMessage
                    ],
                    [
                        "role": "user",
                        "content": prompt
                    ]
                ],
                "max_output_tokens": 300
            ]
            body["reasoning"] = ["effort": "medium"]
            requestBody = body
        } else {
            // Other models use /v1/chat/completions endpoint with legacy structure
            apiURL = chatCompletionsURL
            requestBody = [
                "model": model,
                "messages": [
                    [
                        "role": "system",
                        "content": systemMessage
                    ],
                    [
                        "role": "user",
                        "content": prompt
                    ]
                ],
                "max_completion_tokens": 300
            ]
        }
        
        // Create URL request
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            // Log the raw JSON being sent
            if let jsonData = request.httpBody,
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📤 RAW JSON SENT TO OPENAI:")
                print("═══════════════════════════════════════════════════")
                print(jsonString)
                print("═══════════════════════════════════════════════════")
            }
        } catch {
            throw OpenAIError.configurationError("Failed to serialize request body: \(error.localizedDescription)")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Log the raw JSON being received
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 RAW JSON RECEIVED FROM OPENAI:")
                print("═══════════════════════════════════════════════════")
                print(responseString)
                print("═══════════════════════════════════════════════════")
            }
            
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
            
            // Extract the AI response content - different parsing for GPT-5 vs other models
            if isGPT5 {
                // GPT-5 /v1/responses endpoint structure
                // Response format: { "output": [{ "role": "assistant", "content": "..." }] }
                if let output = json["output"] as? [[String: Any]],
                   let firstOutput = output.first {
                    // Try string content
                    if let content = firstOutput["content"] as? String, !content.isEmpty {
                        print("✅ OpenAI API response received (GPT-5 string format): \(content.prefix(100))...")
                        return content
                    }
                    
                    // Try array-of-blocks content
                    if let contentBlocks = firstOutput["content"] as? [[String: Any]] {
                        let assembled = contentBlocks.compactMap { block -> String? in
                            if block["type"] as? String == "text" {
                                return block["text"] as? String
                            }
                            return nil
                        }.joined()
                        
                        if !assembled.isEmpty {
                            print("✅ OpenAI API response received (GPT-5 block format): \(assembled.prefix(100))...")
                            return assembled
                        }
                    }
                }
            } else {
                // Legacy /v1/chat/completions endpoint structure
                guard let choices = json["choices"] as? [[String: Any]],
                      let firstChoice = choices.first else {
                    throw OpenAIError.invalidResponse("No choices in response")
                }
                
                // First: try GPT-4 style (string content)
                if let message = firstChoice["message"] as? [String: Any] {
                    // Try string content (GPT-4 style)
                    if let content = message["content"] as? String, !content.isEmpty {
                        print("✅ OpenAI API response received (string format): \(content.prefix(100))...")
                        return content
                    }
                    
                    // Try array-of-blocks content (GPT-5 format)
                    if let contentBlocks = message["content"] as? [[String: Any]] {
                        let assembled = contentBlocks.compactMap { block -> String? in
                            if block["type"] as? String == "text" {
                                return block["text"] as? String
                            }
                            return nil
                        }.joined()
                        
                        if !assembled.isEmpty {
                            print("✅ OpenAI API response received (block format): \(assembled.prefix(100))...")
                            return assembled
                        }
                    }
                }
                
                // Second: try GPT-5 delta streaming structure
                if let delta = firstChoice["delta"] as? [String: Any] {
                    // Try string content in delta
                    if let deltaContent = delta["content"] as? String, !deltaContent.isEmpty {
                        print("✅ OpenAI API response received (delta format): \(deltaContent.prefix(100))...")
                        return deltaContent
                    }
                    
                    // Try array-of-blocks in delta
                    if let deltaBlocks = delta["content"] as? [[String: Any]] {
                        let assembled = deltaBlocks.compactMap { block -> String? in
                            if block["type"] as? String == "text" {
                                return block["text"] as? String
                            }
                            return nil
                        }.joined()
                        
                        if !assembled.isEmpty {
                            print("✅ OpenAI API response received (delta block format): \(assembled.prefix(100))...")
                            return assembled
                        }
                    }
                }
            }
            
            // If we get here, no content was found in any recognized format
            print("❌ No content found in response. Full response: \(json)")
            throw OpenAIError.invalidResponse("No content in any recognized format")
            
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
