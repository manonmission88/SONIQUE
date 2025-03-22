//
//  ContentView.swift
//  Sonique
//
//  Created by Manish Niure on 3/22/25.
//

import SwiftUI
import Speech
import AVFoundation

class SpeechRecognizer: ObservableObject {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // Timer to detect 5 seconds of silence
    private var silenceTimer: Timer?
    
    @Published var recognizedText: String = "" {
        didSet {
            // Print updates for each change if needed:
            print("Recorded Text (update): \(recognizedText)")
        }
    }
    @Published var isRecognizing: Bool = false
    
    // Request speech recognition permission
    func requestPermission() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("Speech recognition authorized.")
                case .denied:
                    print("Speech recognition authorization denied.")
                case .restricted:
                    print("Speech recognition restricted on this device.")
                case .notDetermined:
                    print("Speech recognition not determined.")
                @unknown default:
                    print("Unknown speech recognition authorization status.")
                }
            }
        }
    }
    
    // Start listening and transcribing live audio
    func startListening() {
        // Ensure the recognizer is available
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            print("Speech recognizer is not available.")
            return
        }
        
        // Configure the audio session for recording
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio Session error: \(error.localizedDescription)")
            return
        }
        
        // Create the recognition request and setup the audio engine
        let request = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Remove any previous tap and install a new one
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isRecognizing = true
            }
        } catch {
            print("Audio Engine error: \(error.localizedDescription)")
            return
        }
        
        // Start the recognition task using the correct API method
        recognitionTask = recognizer.recognitionTask(with: request, resultHandler: { result, error in
            // Reset the silence timer each time new speech is detected
            self.resetSilenceTimer()
            
            if let result = result {
                DispatchQueue.main.async {
                    self.recognizedText = result.bestTranscription.formattedString
                }
            }
            
            if let error = error {
                print("Recognition error: \(error.localizedDescription)")
                self.stopListening()
            }
            
            if result?.isFinal == true {
                self.stopListening()
            }
        })
        
        // Start the silence timer (5 seconds of inactivity)
        self.startSilenceTimer()
    }
    
    // Stop listening, print final conversation, and reset everything
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        DispatchQueue.main.async {
            self.isRecognizing = false
            print("Final Conversation: \(self.recognizedText)")
        }
        self.invalidateSilenceTimer()
    }
    
    // Start a timer that stops listening after 5 seconds of silence
    private func startSilenceTimer() {
        self.invalidateSilenceTimer()  // Cancel any existing timer
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            print("Silence detected for 5 seconds. Stopping listening.")
            self.stopListening()
        }
    }
    
    // Reset the silence timer when new speech is detected
    private func resetSilenceTimer() {
        DispatchQueue.main.async {
            self.startSilenceTimer()
        }
    }
    
    // Invalidate the silence timer
    private func invalidateSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = nil
    }
}

struct ContentView: View {
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var showingDocumentPicker = false
    @State private var switcherOffset: CGFloat = 0
    
    // Refined color scheme
    let gradientTop = Color(hex: "4F46E5")    // Indigo
    let gradientMiddle = Color(hex: "3B82F6")  // Blue
    let gradientBottom = Color(hex: "60A5FA")  // Light Blue
    let accentColor = Color.white
    
    var body: some View {
        VStack(spacing: 40) {
            // Display the transcribed text in a scrollable view
            ScrollView {
                Text(speechRecognizer.recognizedText)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            
            // Microphone button to start/stop live transcription
            Button(action: {
                if speechRecognizer.isRecognizing {
                    speechRecognizer.stopListening()
                } else {
                    speechRecognizer.startListening()
                }
            }) {
                Image(systemName: speechRecognizer.isRecognizing ? "mic.fill" : "mic.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
                    .foregroundColor(.blue)
            }
            .accessibilityLabel("Voice Input Button")
            
            Spacer()
        }
        .padding()
        .onAppear {
            speechRecognizer.requestPermission()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

