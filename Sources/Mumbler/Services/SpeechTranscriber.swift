import Speech
import AVFoundation

enum SpeechError: LocalizedError {
    case noRecognizer

    var errorDescription: String? {
        switch self {
        case .noRecognizer:
            return "Speech recognition is not available for this locale"
        }
    }
}

class SpeechTranscriber {
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let queue = DispatchQueue(label: "com.augustine.mumbler.speech-transcriber")
    private var generation: UInt64 = 0

    var onPartialResult: ((String) -> Void)?
    var onFinalResult: ((String) -> Void)?
    var onError: ((Error) -> Void)?

    var isAvailable: Bool { speechRecognizer != nil }

    init(locale: Locale = .current) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale) ?? SFSpeechRecognizer()
    }

    func startTranscription() {
        queue.sync {
            // Cancel and clean up any existing session
            recognitionTask?.cancel()
            recognitionRequest = nil
            recognitionTask = nil

            generation += 1
            let currentGeneration = generation

            guard let speechRecognizer = speechRecognizer else {
                Log.error("No speech recognizer available")
                onError?(SpeechError.noRecognizer)
                return
            }

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            request.addsPunctuation = true

            if speechRecognizer.supportsOnDeviceRecognition {
                request.requiresOnDeviceRecognition = true
                Log.info("Using on-device speech recognition")
            } else {
                Log.info("Using server-based speech recognition")
            }

            recognitionRequest = request

            recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self = self else { return }

                self.queue.async {
                    guard self.generation == currentGeneration else { return }

                    if let result = result {
                        let text = result.bestTranscription.formattedString
                        if result.isFinal {
                            Log.info("Final transcript: \(text.prefix(80))...")
                            self.onFinalResult?(text)
                            self.cleanupInternal()
                        } else {
                            self.onPartialResult?(text)
                        }
                    }

                    if let error = error {
                        let nsError = error as NSError
                        if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 216 {
                            Log.info("Recognition cancelled (expected)")
                            return
                        }
                        Log.error("Speech recognition error: \(error.localizedDescription)")
                        self.onError?(error)
                        self.cleanupInternal()
                    }
                }
            }

            Log.info("Transcription started (generation \(currentGeneration))")
        }
    }

    func appendBuffer(_ buffer: AVAudioPCMBuffer) {
        queue.async { [weak self] in
            self?.recognitionRequest?.append(buffer)
        }
    }

    func stopTranscription() {
        queue.async { [weak self] in
            self?.recognitionRequest?.endAudio()
            Log.info("Audio ended — waiting for final result")
        }
    }

    func cancel() {
        queue.sync {
            recognitionTask?.cancel()
            cleanupInternal()
            Log.info("Transcription cancelled")
        }
    }

    /// Must be called on `queue`.
    private func cleanupInternal() {
        recognitionRequest = nil
        recognitionTask = nil
    }
}
