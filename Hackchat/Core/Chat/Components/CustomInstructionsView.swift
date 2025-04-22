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
    @State private var showDismissConfirmation = false
    @State private var selectedDetent = PresentationDetent.large
    
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
                    if instructionsHaveBeenEdited {
                        showDismissConfirmation = true
                    } else {
                        dismiss()
                    }
                } label: {
                    Text("Cancel")
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            Divider()
            Text("Customize how you want the model to respond, or what it should know about you.")
                .font(.system(size: 15))
                .padding(14)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
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
        .interactiveDismissDisabled()
        .presentationDragIndicator(.hidden)
        .presentationDetents([.large, .fraction(0.99)], selection: $selectedDetent)
        .onChange(of: selectedDetent) { oldValue, newValue in
            if newValue == .fraction(0.99) {
                // The user is trying to dismiss via swipe
                if instructionsHaveBeenEdited {
                    selectedDetent = oldValue
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        // Wait 0.1 seconds so the sheet can expand before we show the dialog
                        // Otherwise, the app will crash
                        showDismissConfirmation = true
                    }
                } else {
                    dismiss()
                }
            }
        }
        .confirmationDialog("Discard Changes", isPresented: $showDismissConfirmation, actions: {
            Button(role: .destructive) {
                dismiss()
            } label: {
                Text("Discard")
            }
        }, message: {
            Text("Are you sure you want to cancel? Any unsaved changes will be lost.")
        })
        .onAppear {
            self.instructions = chat.customInstructions ?? ""
        }
    }
}

#Preview {
    CustomInstructionsView(chat: Chat(context: CoreDataManager.shared.persistentContainer.viewContext))
}
