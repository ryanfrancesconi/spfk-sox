import AVFoundation
import SPFKBase
@testable import SPFKSoX
import SPFKTesting
import Testing

@Suite(.tags(.file), .serialized)
class ChannelTests: BinTestCase {
    // MARK: - exportSplitStereo

    @Test func exportSplitStereoWithCustomName() async throws {
        let input = TestBundleResources.shared.tabla_wav
        let pair = try await SoX.shared.exportSplitStereo(
            input: input,
            destination: bin,
            newName: "CustomName",
            overwrite: true
        )

        #expect(pair.left.lastPathComponent == "CustomName.L.wav")
        #expect(pair.right.lastPathComponent == "CustomName.R.wav")
        #expect(pair.left.exists)
        #expect(pair.right.exists)
    }

    @Test func exportSplitStereoOverwriteFalse() async throws {
        let input = TestBundleResources.shared.tabla_wav

        // First export
        let pair1 = try await SoX.shared.exportSplitStereo(
            input: input,
            destination: bin,
            newName: "NoOverwrite",
            overwrite: true
        )

        #expect(pair1.left.exists)
        #expect(pair1.right.exists)

        // Second export with overwrite: false — files already exist, should skip
        let pair2 = try await SoX.shared.exportSplitStereo(
            input: input,
            destination: bin,
            newName: "NoOverwrite",
            overwrite: false
        )

        #expect(pair2.left.exists)
        #expect(pair2.right.exists)
    }

    // MARK: - exportChannels

    @Test func exportChannelsMonoInput() async throws {
        let input = TestBundleResources.shared.tabla_wav

        // First create a mono file
        let monoURL = try await SoX.shared.stereoToMono(source: input, destination: bin, newName: "mono_source")

        // Export channels of a mono file — should produce 1 file
        let urls = try await SoX.shared.exportChannels(input: monoURL, destination: bin, newName: "MonoCh")

        #expect(urls.count == 1)
        #expect(urls.first?.lastPathComponent == "MonoCh.1.wav")
    }

    // MARK: - stereoToMono

    @Test func stereoToMonoWithCustomName() async throws {
        let input = TestBundleResources.shared.tabla_wav

        let result = try await SoX.shared.stereoToMono(
            source: input,
            destination: bin,
            newName: "MyMono"
        )

        #expect(result.lastPathComponent == "MyMono.Mono.wav")
        #expect(result.exists)

        let avFile = try AVAudioFile(forReading: result)
        #expect(avFile.fileFormat.channelCount == 1)
    }

    @Test func stereoToMonoDefaultDestination() async throws {
        // Copy to bin first so output goes to a known writable location
        let input = TestBundleResources.shared.tabla_wav
        let localCopy = bin.appendingPathComponent("stereo_input.wav")
        try FileManager.default.copyItem(at: input, to: localCopy)

        let result = try await SoX.shared.stereoToMono(source: localCopy)

        #expect(result.lastPathComponent == "stereo_input.Mono.wav")
        #expect(result.exists)
    }
}
