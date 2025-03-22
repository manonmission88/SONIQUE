//
//  ContentView.swift
//  Sonique
//
//  Created by Manish Niure on 3/22/25.
//

import SwiftUI

struct ContentView: View {
    @State private var isKidsMode: Bool = true
    @State private var showingDocumentPicker = false
    @State private var switcherOffset: CGFloat = 0
    
    // Refined color scheme
    let gradientTop = Color(hex: "4F46E5")    // Indigo
    let gradientMiddle = Color(hex: "3B82F6")  // Blue
    let gradientBottom = Color(hex: "60A5FA")  // Light Blue
    let accentColor = Color.white
    
    var body: some View {
        ZStack {
            // Rich gradient background
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: gradientTop, location: 0.0),
                    .init(color: gradientMiddle, location: 0.5),
                    .init(color: gradientBottom, location: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle pattern overlay
            ZStack {
                Circle()
                    .fill(.white.opacity(0.05))
                    .frame(width: 300, height: 300)
                    .blur(radius: 50)
                    .offset(x: -150, y: -100)
                
                Circle()
                    .fill(.white.opacity(0.05))
                    .frame(width: 300, height: 300)
                    .blur(radius: 50)
                    .offset(x: 150, y: 300)
            }
            .ignoresSafeArea()
            
            VStack(spacing: 25) {
                // Enhanced App Title with icon
                HStack(spacing: 15) {
                    Image(systemName: "soundwaves")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            .linearGradient(
                                colors: [.white, .white.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    Text("Sonique")
                        .font(.system(size: 50, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            .linearGradient(
                                colors: [.white, .white.opacity(0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .padding(.top, 40)
                .shadow(color: .black.opacity(0.2), radius: 2)
                
                // Enhanced Mode Switcher with better contrast
                ZStack {
                    // Background capsule - lighter for better contrast
                    RoundedRectangle(cornerRadius: 30)
                        .fill(.white.opacity(0.2))
                        .background(
                            .ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: 30)
                        )
                        .frame(width: 300, height: 70)
                        .shadow(color: .black.opacity(0.1), radius: 10)
                    
                    // Selection indicator - more visible
                    RoundedRectangle(cornerRadius: 25)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.4),
                                    .white.opacity(0.3)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 145, height: 60)
                        .shadow(color: .black.opacity(0.1), radius: 5)
                        .offset(x: switcherOffset)
                    
                    // Mode labels with enhanced visibility
                    HStack(spacing: 10) {
                        // Student Mode Button
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isKidsMode = true
                                switcherOffset = -75
                            }
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        }) {
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(isKidsMode ? .white.opacity(0.2) : .clear)
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 24))
                                        .symbolRenderingMode(.hierarchical)
                                        .foregroundStyle(isKidsMode ? .white : .white.opacity(0.7))
                                }
                                
                                Text("Student")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .frame(width: 145)
                            .foregroundColor(isKidsMode ? .white : .white.opacity(0.7))
                        }
                        
                        // Parent Mode Button
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isKidsMode = false
                                switcherOffset = 75
                            }
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        }) {
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(!isKidsMode ? .white.opacity(0.2) : .clear)
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: "person.2.circle.fill")
                                        .font(.system(size: 24))
                                        .symbolRenderingMode(.hierarchical)
                                        .foregroundStyle(!isKidsMode ? .white : .white.opacity(0.7))
                                }
                                
                                Text("Parent")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .frame(width: 145)
                            .foregroundColor(!isKidsMode ? .white : .white.opacity(0.7))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 35)
                        .fill(.white.opacity(0.1))
                        .shadow(color: .black.opacity(0.1), radius: 10)
                )
                .padding(.top, 20)
                
                Spacer()
                
                // Enhanced Main Action Buttons
                if isKidsMode {
                    // Student Mode: Enhanced Voice Input
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    }) {
                        ZStack {
                            // Keep existing glass effect background
                            Circle()
                                .fill(.white.opacity(0.15))
                                .background(
                                    .ultraThinMaterial,
                                    in: Circle()
                                )
                                .frame(width: 220, height: 220)
                            
                            // Animated ring
                            Circle()
                                .stroke(.white.opacity(0.3), lineWidth: 2)
                                .frame(width: 220, height: 220)
                            
                            VStack(spacing: 20) {
                                // New dynamic icon combination
                                ZStack {
                                    Image(systemName: "waveform.and.magnifyingglass")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 90, height: 90)
                                        .foregroundStyle(
                                            .linearGradient(
                                                colors: [.white, .white.opacity(0.8)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                }
                                
                                Text("Listen & Learn")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                            }
                        }
                    }
                } else {
                    // Parent Mode: Enhanced Upload
                    Button(action: {
                        showingDocumentPicker = true
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }) {
                        ZStack {
                            // Keep existing glass effect background
                            Circle()
                                .fill(.white.opacity(0.15))
                                .background(
                                    .ultraThinMaterial,
                                    in: Circle()
                                )
                                .frame(width: 220, height: 220)
                            
                            // Animated ring
                            Circle()
                                .stroke(.white.opacity(0.3), lineWidth: 2)
                                .frame(width: 220, height: 220)
                            
                            VStack(spacing: 20) {
                                // New dynamic icon combination
                                ZStack {
                                    Image(systemName: "doc.viewfinder")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 90, height: 90)
                                        .foregroundStyle(
                                            .linearGradient(
                                                colors: [.white, .white.opacity(0.8)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                }
                                
                                Text("Upload Content")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            switcherOffset = isKidsMode ? -75 : 75
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker(isPresented: $showingDocumentPicker) { url in
                print("Selected PDF: \(url)")
            }
        }
    }
}

// Custom Toggle Style
struct CustomToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        RoundedRectangle(cornerRadius: 40)
            .fill(configuration.isOn ? Color(hex: "4158D0") : Color(hex: "C850C0"))
            .frame(width: 75, height: 40)
            .overlay(
                Circle()
                    .fill(.white)
                    .shadow(radius: 1)
                    .frame(width: 32, height: 32)
                    .offset(x: configuration.isOn ? 18 : -18)
            )
            .onTapGesture {
                withAnimation(.spring()) {
                    configuration.isOn.toggle()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
    }
}

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// Add this DocumentPicker struct
struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onDocumentPicked: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf])
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.onDocumentPicked(url)
            parent.isPresented = false
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.isPresented = false
        }
    }
}
