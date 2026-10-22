import SwiftUI
import AVFoundation

/// Optional offline soundscape. No audio data, tracking or cloud service.
enum SoundscapePreset: String, CaseIterable, Identifiable {
    case singingBowl = "Поющая чаша"
    case warmDrone = "Мягкий фон"
    case quiet = "Без музыки"
    var id: String { rawValue }
}

/// Generates a gentle synthetic tone, not a recording of an authentic Tibetan bowl.
@MainActor
@Observable
final class SoundscapePlayer {
    var preset: SoundscapePreset = .quiet
    var volume: Float = 0.15
    private var engine: AVAudioEngine?
    private var node: AVAudioSourceNode?

    func play(_ selection: SoundscapePreset) {
        stop()
        preset = selection
        guard selection != .quiet else { return }
        let audioEngine = AVAudioEngine()
        let format = audioEngine.outputNode.inputFormat(forBus: 0)
        let sampleRate = format.sampleRate
        let channels = Int(format.channelCount)
        guard sampleRate > 0, channels > 0 else { return }
        let frequency = selection == .singingBowl ? 220.0 : 146.83
        let level = Double(min(0.25, max(0.0, volume)))
        var phase = 0.0
        let source = AVAudioSourceNode { _, _, frameCount, audioBufferList in
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                let value = Float(sin(phase) * level)
                phase += 2 * Double.pi * frequency / sampleRate
                if phase >= 2 * Double.pi { phase -= 2 * Double.pi }
                for buffer in buffers {
                    guard let data = buffer.mData?.assumingMemoryBound(to: Float.self) else { continue }
                    data[frame] = value
                }
            }
            return noErr
        }
        audioEngine.attach(source)
        audioEngine.connect(source, to: audioEngine.mainMixerNode, format: format)
        do {
            try audioEngine.start()
            engine = audioEngine
            node = source
        } catch {
            audioEngine.stop()
            preset = .quiet
        }
    }

    func stop() {
        engine?.stop()
        engine = nil
        node = nil
        preset = .quiet
    }
}

struct SoundscapeSettingsView: View {
    @State private var player = SoundscapePlayer()
    var body: some View {
        Form {
            Section("Аудиосопровождение") {
                Picker("Звук", selection: $player.preset) {
                    ForEach(SoundscapePreset.allCases) { Text($0.rawValue).tag($0) }
                }
                .onChange(of: player.preset) { _, chosen in
                    player.play(chosen)
                }
                HStack {
                    Text("Громкость")
                    Slider(value: $player.volume, in: 0...0.25)
                }
                Button("Остановить звук") { player.stop() }
            }
            Section {
                Text("Это простой синтезированный звуковой фон, а не запись тибетских чаш. Используй комфортную громкость и при дискомфорте отключи звук. Специальные лечебные свойства не заявляются.")
                    .font(.footnote)
            }
        }
        .navigationTitle("Звуковая среда")
        .onDisappear { player.stop() }
    }
}
