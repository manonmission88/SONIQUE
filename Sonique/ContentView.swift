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
                    self.alertMessage = "Speech recognition permission denied. Please enable it in Settings."
                case .restricted:
                    self.showAlert = true
                    self.alertMessage = "Speech recognition is restricted on this device."
                case .notDetermined:
                    print("Speech recognition not determined.")
                @unknown default:
                    self.showAlert = true
                    self.alertMessage = "Unknown speech recognition authorization status."
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
        let message = "Switched to \(isKidMode ? "Kid" : "Parent") Mode"
//        speakText(message)
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
    
    var body: some View {
        VStack(spacing: 20) {
            // Simplified Mode Toggle Button
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    speechManager.toggleMode()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: speechManager.isKidMode ? "person.fill" : "person.2.fill")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text(speechManager.isKidMode ? "Kid Mode" : "Parent Mode")
                        .font(.system(size: 17, weight: .bold))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(speechManager.isKidMode ? Color.blue : Color.green)
                        .shadow(color: speechManager.isKidMode ? Color.blue.opacity(0.3) : Color.green.opacity(0.3), radius: 10)
                )
                .foregroundColor(.white)
            }
            .buttonStyle(PressableButtonStyle(isPressed: $isPressed))
            .accessibilityLabel("Mode toggle button")
            .accessibilityHint("Double tap to switch between kid and parent mode")
            .padding(.top, 20)
            
            Text("Sonique")
                .font(.system(size: 45, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            speechManager.isKidMode ? Color.blue : Color.green,
                            speechManager.isKidMode ? Color.blue.opacity(0.7) : Color.green.opacity(0.7)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.top, 10)
                .accessibilityAddTraits(.isHeader)
            
            // File Selection Button (Only in Parent Mode)
            if !speechManager.isKidMode {
                Button(action: {
                    showingDocumentPicker = true
                }) {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                        Text("Upload New Content")
                    }
                    .font(.system(size: 18))
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.orange, Color.orange.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: Color.orange.opacity(0.3), radius: 10)
                }
                .accessibilityLabel("Upload new content button")
                .accessibilityHint("Double tap to choose a new file to upload")
            }
            
            // Display Area (Uploaded Content)
            if !speechManager.isKidMode && fileManager.isFileSelected {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Uploaded Content:")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.gray)
                    
                    ScrollView {
                        if !fileManager.fileContent.isEmpty {
                            Text(fileManager.fileContent)
                                .font(.system(size: 16))
                                .foregroundColor(.black)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                    .frame(maxHeight: 200)
                }
                .padding(.horizontal)
            }
            
            // Uploaded Files Bar (Only in Parent Mode)
            if !speechManager.isKidMode {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("All Uploaded Files")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Text("\(fileManager.uploadedFiles.count) files")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            
                            Button(action: {
                                showingAllFiles = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "list.bullet")
                                    Text("View All")
                                }
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
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
            Spacer()
            
            // Speech Recognition Display (Only in Kid Mode)
            if speechManager.isKidMode {
                Text(speechManager.recognizedText)
                    .font(.system(size: 24))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(15)
                    .padding(.horizontal)
            }
            
            // Microphone Button with Overlay (Only in Kid Mode)
            if speechManager.isKidMode {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .shadow(color: .gray, radius: 5)
                        .frame(width: 120, height: 120)
                    
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
                                .frame(width: 110, height: 110)
                            
                            Image(systemName: speechManager.isRecognizing ? "mic.fill" : "mic.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .foregroundColor(speechManager.isRecognizing ? .red : .blue)
                            
                            if speechManager.isRecognizing {
                                Circle()
                                    .stroke(Color.red, lineWidth: 3)
                                    .frame(width: 110, height: 110)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    speechManager.isKidMode ? Color.blue.opacity(0.1) : Color.green.opacity(0.1),
                    speechManager.isKidMode ? Color.blue.opacity(0.05) : Color.green.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
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
        .onAppear {
            speechManager.requestPermission()
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
            .onChange(of: configuration.isPressed) { newValue in
                isPressed = newValue
            }
    }
}

// File Card View for the horizontal scroll
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
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .foregroundColor(isSelected ? .white : .gray)
                    
                    Text(fileName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isSelected ? .white : .gray)
                        .lineLimit(1)
                    
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(isSelected ? .white : .gray)
                    }
                }
                
                Text(dateFormatter.string(from: date))
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .gray.opacity(0.8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// New view for displaying all files
struct AllFilesView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var fileManager: CustomFileManager
    @State private var selectedFile: URL?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(fileManager.uploadedFiles, id: \.url) { file in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                            
                            Text(file.url.lastPathComponent)
                                .font(.system(size: 16, weight: .medium))
                            
                            Spacer()
                            
                            Button(action: {
                                fileManager.removeFile(file.url)
                            }) {
                                Image(systemName: "trash")
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
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("All Uploaded Files")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
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

