//
//  ContentView.swift
//  Sonique
//
//  Created by Manish Niure on 3/22/25.
//

import SwiftUI

struct ContentView: View {
    @State private var isKidsMode: Bool = true
    
    var body: some View {
        VStack {
            // Toggle button at the top for Kids/Parents mode
            Button(action: {
                isKidsMode.toggle()
            }) {
                Text(isKidsMode ? "Kids Mode" : "Parents Mode")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isKidsMode ? Color.blue : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .accessibilityLabel("Toggle mode: \(isKidsMode ? "Kids" : "Parents")")
            .padding(.horizontal)
            .padding(.top)
            
            Spacer()  // Push content down
            
            // Big voice input icon button in the middle
            Button(action: {
                // Add your voice input action here
            }) {
                Image(systemName: "mic.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
                    .foregroundColor(.blue)
            }
            .accessibilityLabel("Voice Input Button")
            
            Spacer()  // Push content up
        }
        .padding()
        .background(
            Image("sonique") // Replace with your image name or use the generated image asset
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
