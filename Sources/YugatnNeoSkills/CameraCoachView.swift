import SwiftUI
import AVFoundation
import Vision

/// На устройстве: никакая фотография или видеозапись не сохраняется.
@MainActor
@Observable
final class PoseCoach: NSObject {
    var status = "Камера выключена"
    var isRunning = false
    var jointsVisible = 0
    var voiceEnabled = true
    let session = AVCaptureSession()

    private let captureQueue = DispatchQueue(label: "neo.skills.capture")
    private let outputQueue = DispatchQueue(label: "neo.skills.pose", qos: .userInitiated)
    private let videoOutput = AVCaptureVideoDataOutput()
    private let speech = AVSpeechSynthesizer()
    private var lastSpeech = Date.distantPast
    private var lastFrame = Date.distantPast
    private let request = VNDetectHumanBodyPoseRequest()

    func start() async {
        guard !isRunning else { return }
        guard await AVCaptureDevice.requestAccess(for: .video) else {
            status = "Доступ к камере не предоставлен"; return
        }
        status = "Настройка камеры…"
        let configured: Bool = await withCheckedContinuation { continuation in
            captureQueue.async {
                self.session.beginConfiguration()
                self.session.sessionPreset = .medium
                defer { self.session.commitConfiguration() }
                guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                      let input = try? AVCaptureDeviceInput(device: device),
                      self.session.canAddInput(input),
                      self.session.canAddOutput(self.videoOutput) else {
                    continuation.resume(returning: false); return
                }
                self.session.addInput(input)
                self.videoOutput.alwaysDiscardsLateVideoFrames = true
                self.videoOutput.setSampleBufferDelegate(self, queue: self.outputQueue)
                self.session.addOutput(self.videoOutput)
                continuation.resume(returning: true)
            }
        }
        guard configured else { status = "Камера недоступна"; return }
        captureQueue.async { self.session.startRunning() }
        isRunning = true
        status = "Помести всё тело в кадр"
    }

    func stop() {
        guard isRunning else { return }
        captureQueue.async { self.session.stopRunning() }
        speech.stopSpeaking(at: .immediate)
        isRunning = false
        status = "Камера выключена"
        jointsVisible = 0
    }

    private func report(_ visible: Int) {
        jointsVisible = visible
        let phrase = visible < 6 ? "Отойди немного, чтобы всё тело было видно" :
            "Положение тела распознано. Продолжай в комфортном темпе"
        status = phrase
        if voiceEnabled && Date().timeIntervalSince(lastSpeech) > 12 {
            lastSpeech = Date()
            speech.speak(AVSpeechUtterance(string: phrase))
        }
    }
}

extension PoseCoach: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput,
                                   didOutput sampleBuffer: CMSampleBuffer,
                                   from connection: AVCaptureConnection) {
        // Важный принцип: не собирать очередь, анализировать максимум ~5 кадров/с.
        // Все пороговые значения относятся только к видимости, НЕ к правильности техники.
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let poseRequest = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored)
        do {
            try handler.perform([poseRequest])
            let observation = poseRequest.results?.first
            let points = try observation?.recognizedPoints(.all) ?? [:]
            let count = points.values.filter { $0.confidence > 0.45 }.count
            Task { @MainActor in self.report(count) }
        } catch {
            Task { @MainActor in self.status = "Не удалось распознать позу" }
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.layer.videoGravity = .resizeAspectFill
        view.layer.session = session
        return view
    }
    func updateUIView(_ uiView: PreviewView, context: Context) {}
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var layer: AVCaptureVideoPreviewLayer { super.layer as! AVCaptureVideoPreviewLayer }
}

struct CameraCoachView: View {
    @State private var coach = PoseCoach()
    var body: some View {
        VStack(spacing: 12) {
            if coach.isRunning {
                CameraPreview(session: coach.session)
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ContentUnavailableView("Камера выключена", systemImage: "camera",
                    description: Text("Анализ происходит на iPhone. Кадры не сохраняются и не отправляются в сеть."))
            }
            Text(coach.status).multilineTextAlignment(.center)
            Toggle("Голосовые подсказки", isOn: $coach.voiceEnabled)
            Button(coach.isRunning ? "Остановить камеру" : "Включить камеру") {
                if coach.isRunning { coach.stop() }
                else { Task { await coach.start() } }
            }
            .buttonStyle(.borderedProminent)
            Text("Пилотный режим проверяет только видимость тела, а не правильность упражнений. Не используй подсказки вместо тренера.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("ИИ-наблюдение · прототип")
        .onDisappear { coach.stop() }
    }
}
