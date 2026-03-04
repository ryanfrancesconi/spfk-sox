import AVFoundation
import SPFKBase
@testable import SPFKSoX
import SPFKTesting
import Testing

@Suite(.tags(.file), .serialized)
class MultiChannelTests: BinTestCase {
    @Test func createMultiChannelWaveEmptyInput() async throws {
        let output = bin.appendingPathComponent("empty.wav")

        await #expect(throws: (any Error).self) {
            try await SoX.shared.createMultiChannelWave(input: [], output: output)
        }
        #expect(!output.exists)
    }

    @Test func createMultiChannelWaveNonexistentFiles() async throws {
        let output = bin.appendingPathComponent("nonexistent.wav")

        let files = [
            URL(fileURLWithPath: "/nonexistent/a.wav"),
            URL(fileURLWithPath: "/nonexistent/b.wav"),
        ]

        await #expect(throws: (any Error).self) {
            try await SoX.shared.createMultiChannelWave(input: files, output: output)
        }
    }
}
