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
    
    func loadFile(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            if let content = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.fileContent = content
                    self.selectedFile = url
                    self.isFileSelected = true
                }
            }
        } catch {
            showAlert = true
            alertMessage = "Error loading file: \(error.localizedDescription)"
        }
    }
}

struct ContentView: View {
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var fileManager = CustomFileManager()
    @State private var showingDocumentPicker = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Mode Toggle Button
            Button(action: {
                speechManager.toggleMode()
            }) {
                Text("Switch to \(speechManager.isKidMode ? "Parent" : "Kid") Mode")
                    .font(.system(size: 18))
                    .padding()
                    .background(speechManager.isKidMode ? Color.blue : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .accessibilityLabel("Mode toggle button")
            .accessibilityHint("Double tap to switch between kid and parent mode")
            .padding(.top)
            
            Text("Sonique")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.blue)
                .padding(.top, 20)
                .accessibilityAddTraits(.isHeader)
            
            // File Selection Button (Only in Parent Mode)
            if !speechManager.isKidMode {
                Button(action: {
                    showingDocumentPicker = true
                }) {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                        Text("Upload Content")
                    }
                    .font(.system(size: 18))
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .accessibilityLabel("Upload content button")
                .accessibilityHint("Double tap to choose a file to upload")
            }
            
            // Display Area
            ScrollView {
                VStack(spacing: 20) {
                    if !speechManager.isKidMode && fileManager.isFileSelected {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Uploaded Content:")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.gray)
                            
                            Text(fileManager.selectedFile?.lastPathComponent ?? "")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                            
                            if !fileManager.fileContent.isEmpty {
                                Text("Content Preview:")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.gray)
                                    .padding(.top, 10)
                                
                                Text(fileManager.fileContent)
                                    .font(.system(size: 16))
                                    .foregroundColor(.black)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Text(speechManager.recognizedText)
                        .font(.system(size: 24))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                }
                .padding(.horizontal)
            }
            .frame(maxHeight: .infinity)
            
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
        .background(speechManager.isKidMode ? Color.blue.opacity(0.1) : Color.green.opacity(0.1))
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
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

