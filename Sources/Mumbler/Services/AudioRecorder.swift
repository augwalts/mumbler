import AVFoundation

enum AudioError: LocalizedError {
    case noInputChannels

    var errorDescription: String? {
        switch self {
        case .noInputChannels:
            return "No audio input channels available"
        }
    }
}

class AudioRecorder {
    private let audioEngine = AVAudioEngine()
    var bufferHandler: ((AVAudioPCMBuffer) -> Void)?

    var isRecording: Bool {
        audioEngine.isRunning
    }

    func startRecording() throws {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        guard recordingFormat.channelCount > 0 else {
            Log.error("Audio format has 0 channels — no input device available")
            throw AudioError.noInputChannels
        }

        Log.info("Audio format: \(recordingFormat.channelCount) ch, \(recordingFormat.sampleRate) Hz")

        // Remove any existing tap defensively before installing
        inputNode.removeTap(onBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.bufferHandler?(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        Log.info("Audio engine started")
    }

    func stopRecording() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        Log.info("Audio engine stopped")
    }
}
