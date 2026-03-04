import AVFoundation
import Numerics
import SPFKBase
@testable import SPFKSoX
import SPFKTesting
import Testing

@Suite(.tags(.file), .serialized)
class TrimTests: BinTestCase {
    @Test func trimWithClosedRange() async throws {
        let input = TestBundleResources.shared.tabla_wav
        let output = bin.appendingPathComponent("rangeTrimmed.wav")

        try await SoX.shared.trim(input: input, output: output, timeChunk: 1.0 ... 3.0)

        let avFile = try AVAudioFile(forReading: output)
        #expect(avFile.duration.isApproximatelyEqual(to: 2.0, relativeTolerance: 0.05))
    }

    @Test func trimStartOnly() async throws {
        let input = TestBundleResources.shared.tabla_wav
        let output = bin.appendingPathComponent("startOnly.wav")

        // endTime defaults to 0, meaning trim from startTime to end of file
        try await SoX.shared.trim(input: input, output: output, startTime: 2.0)

        let avFile = try AVAudioFile(forReading: output)
        // Original is ~4.39s, trimming from 2s should give ~2.39s
        #expect(avFile.duration.isApproximatelyEqual(to: 2.39, relativeTolerance: 0.05))
    }

    @Test func trimInvalidInput() async throws {
        let input = URL(fileURLWithPath: "/nonexistent/file.wav")
        let output = bin.appendingPathComponent("shouldNotExist.wav")

        await #expect(throws: (any Error).self) {
            try await SoX.shared.trim(input: input, output: output, startTime: 0, endTime: 1)
        }
    }
}
