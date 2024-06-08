import Foundation

class GPT4Service {
    static let shared = GPT4Service()
    
    private init() {}
    
    func sendImageToGPT4(imageURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let openAIApiKey = Config.OpenAIApiKey
        request.setValue("Bearer \(openAIApiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let json: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "user",
                    "content":[
                        [
                            "type": "text",
                            "text": (
                                    "写真の内容を解析し、次のフォーマットで食事内容をJSON形式で返してください：\n"
                                    + "{\n"
                                    + "  \"meals\": [\n"
                                    + "    {\n"
                                    + "      \"name\": \"推定される食事名[String]\",\n"
                                    + "      \"nutrients\": \"推定される栄養素[カンマ区切りのString]\",\n"
                                    + "      \"weight\": \"推定される食事の重さ（単位はg, 数値のみ返すこと）[INT64]\",\n"
                                    + "      \"label\": \"staple or side[String]\"\n"
                                    + "      \"remaining\": \"100%の食事量を想定し、約何%残っていそうか。ほぼ空なら0でよい。範囲は0.0~1.0[Float]\"\n"
                                    + "    }\n"
                                    + "  ]\n"
                                    + "}\n"
                            )
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": imageURL.absoluteString
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 300
        ]
        
        let jsonData = try! JSONSerialization.data(withJSONObject: json)
        
        let task = URLSession.shared.uploadTask(with: request, from: jsonData) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            let responseString = String(data: data, encoding: .utf8) ?? "No response"
            completion(.success(responseString))
        }
        
        task.resume()
    }
}
