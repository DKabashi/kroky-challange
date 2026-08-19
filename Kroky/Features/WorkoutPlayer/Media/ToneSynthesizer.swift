import Foundation

/// A single sine note with a duration, used to build a cue.
struct Tone {
    let frequency: Double
    let duration: Double
}

/// Renders sequences of sine `Tone`s into in-memory 16-bit PCM WAV data.
///
/// Synthesising the cues avoids bundling (and licensing) audio assets, keeps
/// the app binary small, and produces click-free tones by shaping every note
/// with a short attack/release envelope. This type is pure — given the same
/// input it always returns the same bytes — which keeps it trivial to reason
/// about and test.
enum ToneSynthesizer {
    static let sampleRate = 44_100.0

    private static let channelCount = 1
    private static let bitsPerSample = 16
    private static let attack = 0.006
    private static let maxRelease = 0.09

    /// Builds a mono WAV file for `tones` played back to back.
    /// - Parameter peakAmplitude: the loudest sample level, in `0...1`.
    static func wavData(for tones: [Tone], peakAmplitude: Double = 0.6) -> Data {
        let samples = renderSamples(for: tones, peakAmplitude: peakAmplitude)

        var data = Data(capacity: 44 + samples.count * 2)
        appendHeader(to: &data, sampleCount: samples.count)
        for sample in samples {
            withUnsafeBytes(of: sample.littleEndian) { data.append(contentsOf: $0) }
        }
        return data
    }

    private static func renderSamples(for tones: [Tone], peakAmplitude: Double) -> [Int16] {
        var samples: [Int16] = []
        samples.reserveCapacity(tones.reduce(0) { $0 + Int($1.duration * sampleRate) })

        for tone in tones {
            let frameCount = Int(tone.duration * sampleRate)
            guard frameCount > 0 else { continue }

            let attackFrames = max(1, Int(attack * sampleRate))
            let releaseFrames = max(1, Int(min(maxRelease, tone.duration / 2) * sampleRate))
            let angularStep = 2 * Double.pi * tone.frequency / sampleRate

            for frame in 0..<frameCount {
                let envelope = amplitudeEnvelope(
                    frame: frame,
                    frameCount: frameCount,
                    attackFrames: attackFrames,
                    releaseFrames: releaseFrames
                )
                let value = sin(Double(frame) * angularStep) * envelope * peakAmplitude
                samples.append(Int16((value * Double(Int16.max)).rounded()))
            }
        }
        return samples
    }

    /// A linear attack/release ramp that fades the tone in and out so it starts
    /// and stops without an audible click.
    private static func amplitudeEnvelope(
        frame: Int,
        frameCount: Int,
        attackFrames: Int,
        releaseFrames: Int
    ) -> Double {
        if frame < attackFrames {
            return Double(frame) / Double(attackFrames)
        }
        let releaseStart = frameCount - releaseFrames
        if frame >= releaseStart {
            return Double(frameCount - frame) / Double(releaseFrames)
        }
        return 1
    }

    private static func appendHeader(to data: inout Data, sampleCount: Int) {
        let dataSize = sampleCount * bitsPerSample / 8
        let byteRate = Int(sampleRate) * channelCount * bitsPerSample / 8
        let blockAlign = channelCount * bitsPerSample / 8

        data.append(contentsOf: Array("RIFF".utf8))
        append(UInt32(36 + dataSize), to: &data)
        data.append(contentsOf: Array("WAVE".utf8))

        data.append(contentsOf: Array("fmt ".utf8))
        append(UInt32(16), to: &data)                       // fmt chunk size
        append(UInt16(1), to: &data)                        // PCM format
        append(UInt16(channelCount), to: &data)
        append(UInt32(sampleRate), to: &data)
        append(UInt32(byteRate), to: &data)
        append(UInt16(blockAlign), to: &data)
        append(UInt16(bitsPerSample), to: &data)

        data.append(contentsOf: Array("data".utf8))
        append(UInt32(dataSize), to: &data)
    }

    private static func append(_ value: UInt32, to data: inout Data) {
        withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
    }

    private static func append(_ value: UInt16, to data: inout Data) {
        withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
    }
}
