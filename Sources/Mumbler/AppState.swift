import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var isRecording = false
    @Published var currentTranscript = ""
    @Published var lastTranscript = ""
    @Published var statusMessage = "Ready"

    @AppStorage(Constants.holdToRecordKey) var holdToRecord = false
    @AppStorage(Constants.autoPasteKey) var autoPaste = true

    let audioRecorder = AudioRecorder()
    let speechTranscriber = SpeechTranscriber()
    let pasteService = PasteService()
    let hotkeyService = HotkeyService()

    private var indicatorPanel: RecordingIndicatorPanel?
    var isSetUp = false

    func setup() {
        guard !isSetUp else { return }
        isSetUp = true
        setupHotkey()
        setupTranscriberCallbacks()
        Task { await Permissions.requestAll() }
    }

    // MARK: - Hotkey Setup

    private func setupHotkey() {
        hotkeyService.onToggle = { [weak self] in
            Task { @MainActor in
                guard let self = self else { return }
                if self.holdToRecord {
                    // Hold mode: keyDown starts recording
                    if !self.isRecording {
                        self.startRecording()
                    }
                } else {
                    // Toggle mode: keyDown toggles
                    self.toggleRecording()
                }
            }
        }

        hotkeyService.onKeyUp = { [weak self] in
            Task { @MainActor in
                guard let self = self else { return }
                if self.holdToRecord && self.isRecording {
                    // Hold mode: keyUp stops recording
                    self.stopRecording()
                }
            }
        }

        hotkeyService.register()
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
                self.statusMessage = "Transcribed"

                if self.autoPaste && !text.isEmpty {
                    self.pasteService.pasteText(text)
                    self.statusMessage = "Pasted!"
                } else if !text.isEmpty {
                    self.pasteService.copyToClipboard(text)
                    self.statusMessage = "Copied to clipboard"
                }

                self.hideIndicator()

                // Reset status after a delay
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    self.statusMessage = "Ready"
                }
            }
        }

        speechTranscriber.onError = { [weak self] error in
            Task { @MainActor in
                guard let self = self else { return }
                self.statusMessage = "Error: \(error.localizedDescription)"
                self.isRecording = false
                self.hideIndicator()

                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    self.statusMessage = "Ready"
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

        // Check permissions first
        guard Permissions.microphoneStatus == .granted else {
            statusMessage = "Microphone access required"
            Task { await Permissions.requestMicrophone() }
            return
        }
        guard Permissions.speechStatus == .granted else {
            statusMessage = "Speech recognition access required"
            Task { await Permissions.requestSpeech() }
            return
        }

        currentTranscript = ""
        statusMessage = "Recording..."

        // Wire audio buffers to speech transcriber
        audioRecorder.bufferHandler = { [weak self] buffer in
            self?.speechTranscriber.appendBuffer(buffer)
        }

        // Start transcription first, then audio
        speechTranscriber.startTranscription()

        do {
            try audioRecorder.startRecording()
            isRecording = true
            showIndicator()
        } catch {
            statusMessage = "Failed to start recording: \(error.localizedDescription)"
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

    // MARK: - Indicator Panel

    private func showIndicator() {
        if indicatorPanel == nil {
            indicatorPanel = RecordingIndicatorPanel(appState: self)
        }
        indicatorPanel?.showIndicator()
    }

    private func hideIndicator() {
        indicatorPanel?.hideIndicator()
    }
}
