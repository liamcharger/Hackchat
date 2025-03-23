//
//  CustomInstructionsView.swift
//  Hackchat
//
//  Created by Liam Willey on 3/21/25.
//

import SwiftUI

struct CustomInstructionsView: View {
    let chat: Chat
    
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject private var coreDataManager = CoreDataManager.shared
    
    @State private var instructions = ""
    
    private var instructionsHaveBeenEdited: Bool {
        let chatInstructions = (chat.customInstructions ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let instructions = instructions.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if chatInstructions == instructions {
            return false
        }
        return true
    }
    private var saveDisabled: Bool {
        !instructionsHaveBeenEdited || instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            NavigationBar("Custom Instructions") {
                Button {
                    // TODO: add confirmation when instructions have been edited
                    dismiss()
                } label: {
                    Text("Cancel")
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            Divider()
            Text("Customize how you want the model to respond, or to know about you.")
                .font(.system(size: 15))
                .padding(14)
                .foregroundStyle(.secondary)
            TextEditor(text: $instructions)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                }
                .padding(.horizontal)
            Button {
                chat.customInstructions = instructions
                coreDataManager.save()
                dismiss()
            } label: {
                Text("Save")
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .fontWeight(.semibold)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .padding()
            }
            .disabled(saveDisabled)
            .opacity(saveDisabled ? 0.5 : 1)
        }
        .onAppear {
            self.instructions = chat.customInstructions ?? ""
        }
    }
}

#Preview {
    CustomInstructionsView(chat: Chat(context: CoreDataManager.shared.persistentContainer.viewContext))
}
