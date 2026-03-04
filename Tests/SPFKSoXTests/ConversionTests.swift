import AVFoundation
import SPFKBase
@testable import SPFKSoX
import SPFKTesting
import Testing

@Suite(.tags(.file), .serialized)
class ConversionTests: BinTestCase {
    // MARK: - convertPCM parameter combinations

    @Test func convertPCMBitDepthOnly() async throws {
        let input = TestBundleResources.shared.tabla_wav
        let output = bin.appendingPathComponent("bitDepthOnly.wav")

        try await SoX.shared.convertPCM(input: input, output: output, bitDepth: 16, sampleRate: nil)

        let avFile = try AVAudioFile(forReading: output)
        #expect(avFile.fileFormat.settings[AVLinearPCMBitDepthKey] as? Int == 16)
    }

    @Test func convertPCMSampleRateOnly() async throws {
        let input = TestBundleResources.shared.tabla_wav
        let output = bin.appendingPathComponent("sampleRateOnly.wav")

        try await SoX.shared.convertPCM(input: input, output: output, bitDepth: nil, sampleRate: 44100)

        let avFile = try AVAudioFile(forReading: output)
        #expect(avFile.fileFormat.sampleRate == 44100)
    }

    @Test func convertPCMNoOptions() async throws {
        let input = TestBundleResources.shared.tabla_wav
        let output = bin.appendingPathComponent("noOptions.aiff")

        try await SoX.shared.convertPCM(input: input, output: output, bitDepth: nil, sampleRate: nil)
        #expect(output.exists)
    }

    @Test func convertPCMInvalidInput() async throws {
        let input = URL(fileURLWithPath: "/nonexistent/file.wav")
        let output = bin.appendingPathComponent("shouldNotExist.wav")

        await #expect(throws: (any Error).self) {
            try await SoX.shared.convertPCM(input: input, output: output, bitDepth: 24, sampleRate: 48000)
        }
    }

    // MARK: - convertMP3 parameter combinations

    @Test func convertMP3BitRateOnly() async throws {
        let input = TestBundleResources.shared.tabla_wav
        let output = bin.appendingPathComponent("bitRateOnly.mp3")

        try await SoX.shared.convertMP3(input: input, output: output, bitRate: 128, sampleRate: nil)
        #expect(output.exists)
    }

    @Test func convertMP3SampleRateOnly() async throws {
        let input = TestBundleResources.shared.tabla_wav
        let output = bin.appendingPathComponent("sampleRateOnly.mp3")

        try await SoX.shared.convertMP3(input: input, output: output, bitRate: nil, sampleRate: 44100)
        #expect(output.exists)
    }

    @Test func convertMP3NoOptions() async throws {
        let input = TestBundleResources.shared.tabla_wav
        let output = bin.appendingPathComponent("noOptions.mp3")

        try await SoX.shared.convertMP3(input: input, output: output, bitRate: nil, sampleRate: nil)
        #expect(output.exists)
    }

    @Test func convertMP3InvalidInput() async throws {
        let input = URL(fileURLWithPath: "/nonexistent/file.wav")
        let output = bin.appendingPathComponent("shouldNotExist.mp3")

        await #expect(throws: (any Error).self) {
            try await SoX.shared.convertMP3(input: input, output: output, bitRate: 256, sampleRate: 48000)
        }
    }
}
