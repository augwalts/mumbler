import AVFoundation

class AudioRecorder {
    private let audioEngine = AVAudioEngine()
    var bufferHandler: ((AVAudioPCMBuffer) -> Void)?

    var isRecording: Bool {
        audioEngine.isRunning
    }

    func startRecording() throws {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.bufferHandler?(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    func stopRecording() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
    }
}
