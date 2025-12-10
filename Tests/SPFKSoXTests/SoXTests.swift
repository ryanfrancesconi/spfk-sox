import AVFoundation
import Numerics
import SPFKAudioBase
import SPFKBase
@testable import SPFKSoX
import SPFKTesting
import Testing

@Suite(.tags(.file), .serialized)
class SoXTests: BinTestCase {
    @Test func convertMP3() async throws {
        let input = TestBundleResources.shared.tabla_wav
        let output = bin.appendingPathComponent("test.mp3")

        #expect(await SoX.shared.convertMP3(input: input, output: output, bitRate: 256, sampleRate: 48000))

        let avFile = try AVAudioFile(forReading: output)
        #expect(avFile.duration == 4.44)
    }

    @Test func convertPCM() async throws {
        let input = TestBundleResources.shared.tabla_wav

        let formats: [AudioFileType] = [.wav, .aiff]

        for format in formats {
            let output = bin.appendingPathComponent("test.\(format.pathExtension)")

            #expect(await SoX.shared.convertPCM(input: input, output: output, bitDepth: 24, sampleRate: 48000))

            let avFile = try AVAudioFile(forReading: output)

            #expect(avFile.duration.isApproximatelyEqual(to: 4.4, relativeTolerance: 0.1))
            #expect(avFile.fileFormat.sampleRate == 48000)
        }
    }

    @Test func createMultiChannelWave() async throws {
        let input = TestBundleResources.shared.tabla_wav

        let url1 = bin.appendingPathComponent("wave1.wav")
        try? url1.delete()

        try FileManager.default.copyItem(at: input, to: url1)

        let url2 = bin.appendingPathComponent("wave2.wav")
        try? url2.delete()

        try FileManager.default.copyItem(at: input, to: url2)

        let url3 = bin.appendingPathComponent("wave3.wav")
        try? url3.delete()

        try FileManager.default.copyItem(at: input, to: url3)

        let output = bin.appendingPathComponent("\(input.deletingPathExtension().lastPathComponent) 3 channels.wav")

        #expect(
            await SoX.shared.createMultiChannelWave(
                input: [url1, url2, url3],
                output: output
            )
        )

        let avFile = try AVAudioFile(forReading: output)
        #expect(avFile.duration == 4.39375)
        #expect(avFile.fileFormat.sampleRate == 48000)
    }

    @Test func exportStereoChannels() async throws {
        let input = TestBundleResources.shared.tabla_wav
        let channelPair = try await SoX.shared.exportSplitStereo(input: input, destination: bin, overwrite: true)

        #expect(channelPair.left.exists)
        #expect(channelPair.right.exists)
    }

    @Test func exportInvalidStereoChannels() async throws {
        let input = TestBundleResources.shared.no_data_chunk
        let bin = bin

        await #expect(throws: (any Error).self) {
            _ = try await SoX.shared.exportSplitStereo(input: input, destination: bin, overwrite: true)
        }
    }

    @Test func exportMultipleChannels() async throws {
        let input = TestBundleResources.shared.tabla_6_channel

        let urls = try await SoX.shared.exportChannels(input: input, destination: bin, newName: "TEST")
        let directoryContents = try #require(bin.directoryContents).filter { $0.lastPathComponent.contains("TEST") } // read actual files in bin

        #expect(urls.count == 6)
        #expect(directoryContents.count == 6)

        let expected = ["TEST.1.wav", "TEST.2.wav", "TEST.3.wav", "TEST.4.wav", "TEST.5.wav", "TEST.6.wav"]

        #expect(
            directoryContents.map(\.lastPathComponent) == expected
        )
    }

    @Test func trim() async throws {
        let input = TestBundleResources.shared.tabla_wav
        let output = bin.appendingPathComponent("trimmed.wav")

        #expect(
            await SoX.shared.trim(input: input, output: output, startTime: 1, endTime: 2)
        )

        let avFile = try AVAudioFile(forReading: output)
        #expect(avFile.duration == 1)
    }

    @Test func stereoToMono() async throws {
        let input = TestBundleResources.shared.tabla_wav

        let result = try await SoX.shared.stereoToMono(source: input, destination: bin)

        let avFile = try AVAudioFile(forReading: result)

        #expect(avFile.fileFormat.channelCount == 1)
    }

    @Test func concurrentInstances() async throws {
        deleteBinOnExit = false

        let input = TestBundleResources.shared.tabla_wav
        let output = bin.appendingPathComponent("trimmed.wav")

        let task1 = Task {
            await SoX.shared.trim(input: input, output: output, startTime: 1, endTime: 2)
        }

        let task2 = Task {
            await SoX.shared.trim(input: input, output: output, startTime: 1, endTime: 2)
        }

        let task3 = Task {
            await SoX.shared.trim(input: input, output: output, startTime: 1, endTime: 2)
        }

        let task4 = Task {
            await SoX.shared.trim(input: input, output: output, startTime: 1, endTime: 2)
        }

        try await wait(sec: 1)

        #expect(try await task1.value)
        #expect(try await task2.value)
        #expect(try await task3.value)
        #expect(try await task4.value)
    }
}
