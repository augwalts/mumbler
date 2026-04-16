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

    private var statusResetTask: Task<Void, Never>?
    private var transcriptionTimeoutTask: Task<Void, Never>?
    /// Accumulated transcript across auto-restarts (Speech framework ~1min limit)
    private var accumulatedTranscript = ""

    init() {
        setupTranscriberCallbacks()
        Task {
            _ = await Permissions.requestAll()
        }
    }

    // MARK: - Transcriber Callbacks

    private func setupTranscriberCallbacks() {
        speechTranscriber.onPartialResult = { [weak self] text in
            Task { @MainActor in
                guard let self = self else { return }
                if self.accumulatedTranscript.isEmpty {
                    self.currentTranscript = text
                } else {
                    self.currentTranscript = self.accumulatedTranscript + " " + text
                }
            }
        }

        speechTranscriber.onFinalResult = { [weak self] text in
            Task { @MainActor in
                guard let self = self else { return }
                self.transcriptionTimeoutTask?.cancel()
                self.transcriptionTimeoutTask = nil

                if self.isRecording {
                    // Speech framework hit its ~1min limit while still recording.
                    // Accumulate transcript and restart transcription session.
                    if !text.isEmpty {
                        self.accumulatedTranscript += (self.accumulatedTranscript.isEmpty ? "" : " ") + text
                    }
                    self.currentTranscript = ""
                    Log.info("Auto-restarting transcription (accumulated \(self.accumulatedTranscript.count) chars)")
                    self.speechTranscriber.startTranscription()
                    return
                }

                // Normal stop — user pressed stop
                let fullTranscript: String
                if !self.accumulatedTranscript.isEmpty {
                    fullTranscript = self.accumulatedTranscript + (text.isEmpty ? "" : " " + text)
                } else {
                    fullTranscript = text
                }
                self.accumulatedTranscript = ""

                self.lastTranscript = fullTranscript
                self.currentTranscript = ""
                Log.info("Final result received (\(fullTranscript.count) chars)")

                if self.autoPaste && !fullTranscript.isEmpty {
                    self.pasteService.pasteText(fullTranscript)
                    self.statusMessage = "Pasted!"
                } else if !fullTranscript.isEmpty {
                    self.pasteService.copyToClipboard(fullTranscript)
                    self.statusMessage = "Copied"
                }

                self.scheduleStatusReset(after: 2_000_000_000)
            }
        }

        speechTranscriber.onError = { [weak self] error in
            Task { @MainActor in
                guard let self = self else { return }
                self.transcriptionTimeoutTask?.cancel()
                self.transcriptionTimeoutTask = nil

                if self.isRecording {
                    self.audioRecorder.stopRecording()
                }
                self.isRecording = false
                self.statusMessage = "Error: \(error.localizedDescription)"
                Log.error("Transcription error: \(error.localizedDescription)")
                self.scheduleStatusReset(after: 3_000_000_000)
            }
        }
    }

    private func scheduleStatusReset(after nanoseconds: UInt64) {
        statusResetTask?.cancel()
        statusResetTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: nanoseconds)
            guard !Task.isCancelled, let self = self else { return }
            self.statusMessage = "Ready"
        }
    }

    // MARK: - Recording Control

    func toggleRecording() {
        isRecording ? stopRecording() : startRecording()
    }

    func startRecording() {
        guard !isRecording else { return }

        statusResetTask?.cancel()

        guard Permissions.microphoneStatus == .granted else {
            statusMessage = "Need mic access"
            Log.info("Requesting mic permission")
            Task { _ = await Permissions.requestMicrophone() }
            return
        }
        guard Permissions.speechStatus == .granted else {
            statusMessage = "Need speech access"
            Log.info("Requesting speech permission")
            Task { _ = await Permissions.requestSpeech() }
            return
        }
        guard speechTranscriber.isAvailable else {
            statusMessage = "Speech recognition unavailable"
            Log.error("No speech recognizer for current locale")
            return
        }

        currentTranscript = ""
        accumulatedTranscript = ""
        statusMessage = "Recording..."
        Log.info("Recording started")

        audioRecorder.bufferHandler = { [weak self] buffer in
            self?.speechTranscriber.appendBuffer(buffer)
        }

        speechTranscriber.startTranscription()

        do {
            try audioRecorder.startRecording()
            isRecording = true
        } catch {
            statusMessage = "Mic error: \(error.localizedDescription)"
            Log.error("Mic error: \(error.localizedDescription)")
            speechTranscriber.cancel()
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        statusMessage = "Transcribing..."
        Log.info("Recording stopped — waiting for transcription")
        audioRecorder.stopRecording()
        speechTranscriber.stopTranscription()

        // Timeout: if no final result arrives within 5s, reset
        transcriptionTimeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled, let self = self else { return }
            Log.info("Transcription timeout — no final result after 5s")
            self.speechTranscriber.cancel()
            self.currentTranscript = ""
            self.statusMessage = "Ready"
        }
    }
}
