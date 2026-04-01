import SwiftUI

@MainActor
class AppState: ObservableObject {
    @Published var isRecording = false
    @Published var currentTranscript = ""
    @Published var lastTranscript = ""
    @Published var statusMessage = "Ready"

    @AppStorage(Constants.autoPasteKey) var autoPaste = true

    let audioRecorder = AudioRecorder()
    let speechTranscriber = SpeechTranscriber()
    let pasteService = PasteService()

    var floatingPanel: MumblerPanel?

    init() {
        // Deferred to next run loop so NSApp is fully initialized
        DispatchQueue.main.async {
            Task { @MainActor in
                self.setupTranscriberCallbacks()
                self.floatingPanel = MumblerPanel(appState: self)
                self.floatingPanel?.show()
                await Permissions.requestAll()
            }
        }
    }

    // MARK: - Transcriber Callbacks

    private func setupTranscriberCallbacks() {
        speechTranscriber.onPartialResult = { [weak self] text in
            Task { @MainActor in
                self?.currentTranscript = text
            }
        }

        speechTranscriber.onFinalResult = { [weak self] text in
            Task { @MainActor in
                guard let self = self else { return }
                self.lastTranscript = text
                self.currentTranscript = ""

                if self.autoPaste && !text.isEmpty {
                    self.pasteService.pasteText(text)
                    self.statusMessage = "Pasted!"
                } else if !text.isEmpty {
                    self.pasteService.copyToClipboard(text)
                    self.statusMessage = "Copied"
                }

                // Reset status after a delay
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    await MainActor.run { self.statusMessage = "Ready" }
                }
            }
        }

        speechTranscriber.onError = { [weak self] error in
            Task { @MainActor in
                guard let self = self else { return }
                self.statusMessage = "Error"
                self.isRecording = false

                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    await MainActor.run { self.statusMessage = "Ready" }
                }
            }
        }
    }

    // MARK: - Recording Control

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    func startRecording() {
        guard !isRecording else { return }

        guard Permissions.microphoneStatus == .granted else {
            statusMessage = "Need mic access"
            Task { await Permissions.requestMicrophone() }
            return
        }
        guard Permissions.speechStatus == .granted else {
            statusMessage = "Need speech access"
            Task { await Permissions.requestSpeech() }
            return
        }

        currentTranscript = ""
        statusMessage = "Recording..."

        audioRecorder.bufferHandler = { [weak self] buffer in
            self?.speechTranscriber.appendBuffer(buffer)
        }

        speechTranscriber.startTranscription()

        do {
            try audioRecorder.startRecording()
            isRecording = true
        } catch {
            statusMessage = "Mic error"
            speechTranscriber.cancel()
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        statusMessage = "Transcribing..."
        audioRecorder.stopRecording()
        speechTranscriber.stopTranscription()
    }
}
