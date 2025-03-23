//
//  ContentView.swift
//  Sonique
//
//  Created by Manish Niure on 3/22/25.
//

import SwiftUI
import Speech
import AVFoundation
import UniformTypeIdentifiers

class SpeechManager: ObservableObject {
    let synthesizer = AVSpeechSynthesizer()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var silenceTimer: Timer?
    
    @Published var recognizedText: String = ""
    @Published var isRecognizing: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var isKidMode: Bool = true
    
    init() {
        // Start in kid mode by default
        isKidMode = true
    }
    
    func requestPermission() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    // Welcome message and start listening
                    self.speakText("Welcome to Sonique! How can I help you?")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.startListening()
                    }
                case .denied:
                    self.showAlert = true
                    self.alertMessage = "Speech recognition permission denied. To enable it:\n1. Open Settings\n2. Scroll down to Sonique\n3. Tap on Sonique\n4. Enable Speech Recognition and Microphone permissions"
                case .restricted:
                    self.showAlert = true
                    self.alertMessage = "Speech recognition is restricted on this device. Please check your device settings or parental controls."
                case .notDetermined:
                    self.showAlert = true
                    self.alertMessage = "Speech recognition permission not determined. Please try again."
                @unknown default:
                    self.showAlert = true
                    self.alertMessage = "Unknown speech recognition authorization status. Please try again."
                }
            }
        }
    }
    
    private func startSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            self?.stopListening()
        }
    }
    
    func startListening() {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            showAlert = true
            alertMessage = "Speech recognizer is not available."
            return
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            showAlert = true
            alertMessage = "Audio Session error: \(error.localizedDescription)"
            return
        }
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputNode.outputFormat(forBus: 0)) { buffer, _ in
            request.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isRecognizing = true
                self.recognizedText = "Listening..."
                self.startSilenceTimer()
            }
        } catch {
            showAlert = true
            alertMessage = "Audio Engine error: \(error.localizedDescription)"
            return
        }
        
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                DispatchQueue.main.async {
                    self.recognizedText = result.bestTranscription.formattedString
                    // Reset silence timer when speech is detected
                    self.startSilenceTimer()
                }
            }
            
            if error != nil || result?.isFinal == true {
                self.stopListening()
            }
        }
    }
    
    func stopListening() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Error deactivating audio session: \(error.localizedDescription)")
        }
        
        DispatchQueue.main.async {
            self.isRecognizing = false
        }
    }
    
    func speakText(_ text: String) {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            showAlert = true
            alertMessage = "Audio Session error: \(error.localizedDescription)"
            return
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.2
        synthesizer.speak(utterance)
    }
    
    func toggleMode() {
        isKidMode.toggle()
        //speakText(message)
    }
}

class CustomFileManager: ObservableObject {
    @Published var selectedFile: URL?
    @Published var fileContent: String = ""
    @Published var isFileSelected: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var uploadedFiles: [(url: URL, date: Date)] = []
    
    func loadFile(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            if let content = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.fileContent = content
                    self.selectedFile = url
                    self.isFileSelected = true
                    if !self.uploadedFiles.contains(where: { $0.url == url }) {
                        self.uploadedFiles.append((url: url, date: Date()))
                    }
                }
            }
        } catch {
            showAlert = true
            alertMessage = "Error loading file: \(error.localizedDescription)"
        }
    }
    
    func removeFile(_ url: URL) {
        uploadedFiles.removeAll { $0.url == url }
        if selectedFile == url {
            selectedFile = nil
            fileContent = ""
            isFileSelected = false
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ContentView: View {
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var fileManager = CustomFileManager()
    @State private var showingDocumentPicker = false
    @State private var isPressed = false
    @State private var selectedFileIndex: Int?
    @State private var showingAllFiles = false
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    speechManager.isKidMode ? Color.blue.opacity(0.15) : Color.green.opacity(0.15),
                    speechManager.isKidMode ? Color.blue.opacity(0.05) : Color.green.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated background circles
            Circle()
                .fill(speechManager.isKidMode ? Color.blue.opacity(0.1) : Color.green.opacity(0.1))
                .frame(width: 300, height: 300)
                .blur(radius: 50)
                .offset(x: -150, y: -200)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
            
            Circle()
                .fill(speechManager.isKidMode ? Color.blue.opacity(0.1) : Color.green.opacity(0.1))
                .frame(width: 300, height: 300)
                .blur(radius: 50)
                .offset(x: 150, y: 200)
                .scaleEffect(isAnimating ? 0.8 : 1.0)
            
            VStack(spacing: 25) {
                // Enhanced Title with animation at the top
                HStack(spacing: 15) {
                    Image(systemName: "ear.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.purple,
                                    Color.purple.opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(-15))
                    
                    Text("Sonique")
                        .font(.system(size: 70, weight: .heavy))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.purple,
                                    Color.purple.opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.purple.opacity(0.3), radius: 10)
                        .scaleEffect(isAnimating ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
                }
                .padding(.top, 40)
                .accessibilityAddTraits(.isHeader)
                
                // Accessibility-focused subtitle
                Text("Your Voice Tutor")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.top, -10)
                
                // Separate Mode Buttons with enhanced design
                HStack(spacing: 20) {
                    // Kid Mode Button
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            if !speechManager.isKidMode {
                                speechManager.toggleMode()
                            }
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 20, weight: .semibold))
                            
                            Text("Kid Mode")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            speechManager.isKidMode ? Color.purple : Color.purple.opacity(0.3),
                                            speechManager.isKidMode ? Color.purple.opacity(0.8) : Color.purple.opacity(0.2)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: speechManager.isKidMode ? Color.purple.opacity(0.3) : Color.clear, radius: 15)
                        )
                        .foregroundColor(speechManager.isKidMode ? .white : .gray)
                    }
                    .buttonStyle(PressableButtonStyle(isPressed: $isPressed))
                    .accessibilityLabel("Kid mode button")
                    .accessibilityHint("Double tap to switch to kid mode")
                    
                    // Parent Mode Button
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            if speechManager.isKidMode {
                                speechManager.toggleMode()
                            }
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 20, weight: .semibold))
                            
                            Text("Parent Mode")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            !speechManager.isKidMode ? Color.purple : Color.purple.opacity(0.3),
                                            !speechManager.isKidMode ? Color.purple.opacity(0.8) : Color.purple.opacity(0.2)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: !speechManager.isKidMode ? Color.purple.opacity(0.3) : Color.clear, radius: 15)
                        )
                        .foregroundColor(!speechManager.isKidMode ? .white : .gray)
                    }
                    .buttonStyle(PressableButtonStyle(isPressed: $isPressed))
                    .accessibilityLabel("Parent mode button")
                    .accessibilityHint("Double tap to switch to parent mode")
                }
                .padding(.top, 20)
                
                // File Selection Button with enhanced design
                if !speechManager.isKidMode {
                    Button(action: {
                        showingDocumentPicker = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 20, weight: .semibold))
                            Text("Upload New Content")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.orange, Color.orange.opacity(0.8)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.orange.opacity(0.3), radius: 15)
                        )
                        .foregroundColor(.white)
                    }
                    .accessibilityLabel("Upload new content button")
                    .accessibilityHint("Double tap to choose a new file to upload")
                }
                
                // Enhanced Display Area
                if !speechManager.isKidMode && fileManager.isFileSelected {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Uploaded Content")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.gray)
                        
                        ScrollView {
                            if !fileManager.fileContent.isEmpty {
                                Text(fileManager.fileContent)
                                    .font(.system(size: 16))
                                    .foregroundColor(.black)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(Color.white)
                                            .shadow(color: Color.black.opacity(0.05), radius: 10)
                                    )
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                    .padding(.horizontal)
                }
                
                // Enhanced Uploaded Files Bar
                if !speechManager.isKidMode {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("All Uploaded Files")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            HStack(spacing: 12) {
                                Text("\(fileManager.uploadedFiles.count) files")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                Button(action: {
                                    showingAllFiles = true
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "list.bullet")
                                        Text("View All")
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.blue.opacity(0.1))
                                    )
                                    .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        if !fileManager.uploadedFiles.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(fileManager.uploadedFiles, id: \.url) { file in
                                        FileCard(
                                            fileName: file.url.lastPathComponent,
                                            date: file.date,
                                            isSelected: fileManager.selectedFile == file.url,
                                            onTap: {
                                                fileManager.loadFile(from: file.url)
                                                selectedFileIndex = fileManager.uploadedFiles.firstIndex(where: { $0.url == file.url })
                                            },
                                            onDelete: {
                                                fileManager.removeFile(file.url)
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Enhanced Speech Recognition Display
                if speechManager.isKidMode {
                    Text(speechManager.recognizedText)
                        .font(.system(size: 24))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 10)
                        )
                        .padding(.horizontal)
                }
                
                // Enhanced Microphone Button
                if speechManager.isKidMode {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 10)
                            .frame(width: 130, height: 130)
                        
                        Button(action: {
                            if speechManager.isRecognizing {
                                speechManager.stopListening()
                            } else {
                                speechManager.startListening()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(speechManager.isRecognizing ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: speechManager.isRecognizing ? "mic.fill" : "mic.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 65, height: 65)
                                    .foregroundColor(speechManager.isRecognizing ? .red : .blue)
                                
                                if speechManager.isRecognizing {
                                    Circle()
                                        .stroke(Color.red, lineWidth: 3)
                                        .frame(width: 120, height: 120)
                                        .scaleEffect(1.2)
                                        .opacity(0.5)
                                        .animation(Animation.easeOut(duration: 1).repeatForever(autoreverses: true), value: speechManager.isRecognizing)
                                }
                            }
                        }
                        .accessibilityLabel(speechManager.isRecognizing ? "Stop listening" : "Start listening")
                        .accessibilityHint(speechManager.isRecognizing ? "Double tap to stop recording" : "Double tap to start recording")
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
            speechManager.requestPermission()
        }
        .alert("Error", isPresented: $speechManager.showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(speechManager.alertMessage)
        }
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: [.text, .plainText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let files):
                if let file = files.first {
                    fileManager.loadFile(from: file)
                }
            case .failure(let error):
                fileManager.showAlert = true
                fileManager.alertMessage = "Error selecting file: \(error.localizedDescription)"
            }
        }
        .alert("File Error", isPresented: $fileManager.showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(fileManager.alertMessage)
        }
        .sheet(isPresented: $showingAllFiles) {
            AllFilesView(fileManager: fileManager)
        }
    }
}

// Custom Button Style for Press Animation
struct PressableButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                isPressed = newValue
            }
    }
}

// Enhanced File Card View
struct FileCard: View {
    let fileName: String
    let date: Date
    let isSelected: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .gray)
                    
                    Text(fileName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(isSelected ? .white : .gray)
                        .lineLimit(1)
                    
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(isSelected ? .white : .gray)
                    }
                }
                
                Text(dateFormatter.string(from: date))
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .gray.opacity(0.8))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.15))
                    .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.black.opacity(0.05), radius: 5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Enhanced All Files View
struct AllFilesView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var fileManager: CustomFileManager
    @State private var selectedFile: URL?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(fileManager.uploadedFiles, id: \.url) { file in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "doc.text")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.blue)
                            
                            Text(file.url.lastPathComponent)
                                .font(.system(size: 17, weight: .medium))
                            
                            Spacer()
                            
                            Button(action: {
                                fileManager.removeFile(file.url)
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 16))
                                    .foregroundColor(.red)
                            }
                        }
                        
                        HStack {
                            Text(fileManager.formatDate(file.date))
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Button(action: {
                                selectedFile = file.url
                                fileManager.loadFile(from: file.url)
                            }) {
                                Text("View Content")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("All Uploaded Files")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

