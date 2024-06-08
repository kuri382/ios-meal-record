import Foundation

struct GPT4oResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage
    let systemFingerprint: String?
    
    struct Choice: Codable {
        let index: Int
        let message: Message
        let logprobs: String?
        let finishReason: String
        
        enum CodingKeys: String, CodingKey {
            case index
            case message
            case logprobs
            case finishReason = "finish_reason"
        }
        
        struct Message: Codable {
            let role: String
            let content: String
        }
    }
    
    struct Usage: Codable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
}
