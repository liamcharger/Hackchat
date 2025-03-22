//
//  CustomInstructionsView.swift
//  Hackchat
//
//  Created by Liam Willey on 3/21/25.
//

import SwiftUI

struct CustomInstructionsView: View {
    let chat: Chat
    
    var body: some View {
        VStack {
            
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        }
    }
}

#Preview {
    CustomInstructionsView(chat: Chat(context: CoreDataManager.shared.persistentContainer.viewContext))
}
