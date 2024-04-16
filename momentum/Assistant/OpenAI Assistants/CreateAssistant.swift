import Foundation
import SwiftOpenAI

func openAICreateAssistant(actions: [Action], service: OpenAIService) async -> String? {
    let actionsAsOpenAITools: [AssistantObject.Tool] = actions.map { action in
        .init(type: .function, function: actionToOpenAIFunction(action))
    }
    
    let uuid = UUID()
    let parameters = AssistantParameters(
        action: .create(model: Model.gpt4TurboPreview.value),
        name: "mv-\(uuid)-assistant",
        description: "Personal Momentum Assistant for user \(uuid)",
        instructions: "You are Momentum Assistant, a concise, capable, and proactive AI integrated into the Momentum calendar and to-do list app. Leverage read/write access to the user's calendar and to-dos to efficiently fulfill requests. Always clarify ambiguities before proceeding. Keep responses extremely brief to respect the user's time. Respond in plain text. Do NOT respond in Markdown form, and try your best to not use any special characters.",
        tools: actionsAsOpenAITools + [
            .init(type: .codeInterpreter),
        ],
        fileIDS: nil,
        metadata: nil
    )
    
    if let assistant = try? await service.createAssistant(parameters: parameters) {
        print("Success \(assistant)")
        return assistant.id
    } else {
        return nil
    }
}
