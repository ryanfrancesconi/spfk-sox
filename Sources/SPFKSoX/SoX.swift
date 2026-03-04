// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio

import AVFoundation
import Foundation
import SPFKBase
import SPFKSoXC

public typealias SplitStereoPair = (left: URL, right: URL)

public actor SoX {
    // sox isn't thread safe so access should be isolated to here
    private let sox = SoxWrapper()

    // singleton as sox code is full of static variables currently
    public static let shared = SoX()

    private init() {}

    // MARK: - Trim

    // Note: doesn't accept 32bit files

    /// Trim audio using a closed time range.
    /// - Parameters:
    ///   - fadeTime: Duration in seconds of the fade applied at trim boundaries to eliminate clicks.
    ///     Pass `0` to disable. Default is `0.01`.
    public func trim(
        input: URL,
        output: URL,
        timeChunk: ClosedRange<TimeInterval>,
        fadeTime: TimeInterval = 0.01
    ) throws {
        try trim(
            input: input,
            output: output,
            startTime: timeChunk.lowerBound,
            endTime: timeChunk.upperBound,
            fadeTime: fadeTime
        )
    }

    /// Trim audio from `startTime` to `endTime`.
    /// - Parameters:
    ///   - endTime: End time in seconds. `0` means trim to the end of file.
    ///   - fadeTime: Duration in seconds of the fade applied at trim boundaries to eliminate clicks.
    ///     Pass `0` to disable. Default is `0.01`.
    public func trim(
        input: URL,
        output: URL,
        startTime: TimeInterval,
        endTime: TimeInterval = 0,
        fadeTime: TimeInterval = 0.01
    ) throws {
        var endTimeStr: String = "0"

        if endTime > 0 {
            // sox syntax
            endTimeStr = "=" + String(endTime)
        }

        let fadeStr = String(fadeTime)

        let status = sox.trim(
            input.soxPath,
            output: output.soxPath,
            startTime: String(startTime),
            endTime: endTimeStr,
            fadeTime: fadeStr
        )

        guard SOX_SUCCESS.rawValue == status, output.exists else {
            throw NSError(description: "Failed to trim \(input.lastPathComponent)")
        }
    }

    // MARK: - PCM Conversion

    /// Convert audio to a PCM format (WAV, AIFF, CAF).
    @discardableResult
    public func convertPCM(input: URL, output: URL, bitDepth: UInt32?, sampleRate: Double?) throws -> Bool {
        guard input.exists else {
            throw NSError(description: "Input file does not exist: \(input.soxPath)")
        }

        let inputPath = input.soxPath
        let outputPath = output.soxPath

        let status: Int32 = if let bitDepth, let sampleRate {
            sox.convert(inputPath, output: outputPath, bits: String(bitDepth), sampleRate: String(sampleRate))

        } else if let bitDepth {
            sox.convert(inputPath, output: outputPath, bits: String(bitDepth))

        } else if let sampleRate {
            sox.convert(inputPath, output: outputPath, sampleRate: String(sampleRate))

        } else {
            sox.convert(inputPath, output: outputPath)
        }

        guard SOX_SUCCESS.rawValue == status else {
            throw NSError(description: "PCM conversion failed for \(input.lastPathComponent)")
        }

        return true
    }

    // MARK: - MP3 Conversion

    /**
     MP3 compressed audio; MP3 (MPEG Layer 3) is a part of the patent-encumbered MPEG standards for audio and video compression. It is a lossy compression format that achieves good compression rates with little quality loss.

     Because MP3 is patented, SoX cannot be distributed with MP3 support without incurring the patent holder's fees. Users who require SoX with MP3 support must currently compile and build SoX with the MP3 libraries (LAME & MAD) from source code, or, in some cases, obtain pre-built dynamically loadable libraries.

     When reading MP3 files, up to 28 bits of precision is stored although only 16 bits is reported to user. This is to allow default behavior of writing 16 bit output files. A user can specify a higher precision for the output file to prevent lossing this extra information. MP3 output files will use up to 24 bits of precision while encoding.

     MP3 compression parameters can be selected using SoX's −C option as follows (note that the current syntax is subject to change):

     The primary parameter to the LAME encoder is the bit rate. If the value of the −C value is a positive integer, it's taken as the bitrate in kbps (e.g. if you specify 128, it uses 128 kbps).

     The second most important parameter is probably "quality" (really performance), which allows balancing encoding speed vs. quality. In LAME, 0 specifies highest quality but is very slow, while 9 selects poor quality, but is fast. (5 is the default and 2 is recommended as a good trade-off for high quality encodes.)

     Because the −C value is a float, the fractional part is used to select quality. 128.2 selects 128 kbps encoding with a quality of 2. There is one problem with this approach. We need 128 to specify 128 kbps encoding with default quality, so 0 means use default. Instead of 0 you have to use .01 (or .99) to specify the highest quality (128.01 or 128.99).

     LAME uses bitrate to specify a constant bitrate, but higher quality can be achieved using Variable Bit Rate (VBR). VBR quality (really size) is selected using a number from 0 to 9. Use a value of 0 for high quality, larger files, and 9 for smaller files of lower quality. 4 is the default.

     In order to squeeze the selection of VBR into the the −C value float we use negative numbers to select VRR. -4.2 would select default VBR encoding (size) with high quality (speed). One special case is 0, which is a valid VBR encoding parameter but not a valid bitrate. Compression value of 0 is always treated as a high quality vbr, as a result both -0.2 and 0.2 are treated as highest quality VBR (size) and high quality (speed).

     - Parameters:
       - quality: LAME quality/speed trade-off (0 = best quality/slowest, 9 = worst/fastest).
         Default is `2` (recommended for high quality). Appended as the fractional part of the `-C` value.
     */
    @discardableResult
    public func convertMP3(
        input: URL,
        output: URL,
        bitRate: UInt32?,
        sampleRate: Double?,
        quality: Int = 2
    ) throws -> Bool {
        guard input.exists else {
            throw NSError(description: "Input file does not exist: \(input.soxPath)")
        }

        let inputPath = input.soxPath
        let outputPath = output.soxPath
        let qualitySuffix = ".\(quality)"

        let status: Int32 = if let bitRate, let sampleRate {
            sox.convert(inputPath, output: outputPath, bitRate: String(bitRate) + qualitySuffix, sampleRate: String(sampleRate))

        } else if let bitRate {
            sox.convert(inputPath, output: outputPath, bitRate: String(bitRate) + qualitySuffix)

        } else if let sampleRate {
            sox.convert(inputPath, output: outputPath, sampleRate: String(sampleRate))

        } else {
            sox.convert(inputPath, output: outputPath)
        }

        guard SOX_SUCCESS.rawValue == status else {
            throw NSError(description: "MP3 conversion failed for \(input.lastPathComponent)")
        }

        return true
    }

    // MARK: - Channel Operations

    /// Split stereo files to dual mono
    ///        sox infile.wav outfile.L.wav remix 1
    ///        sox infile.wav outfile.R.wav remix 2
    public func exportSplitStereo(
        input source: URL,
        destination: URL? = nil,
        newName: String? = nil,
        overwrite: Bool = true
    ) throws -> SplitStereoPair {
        // check source input

        let audioFile = try AVAudioFile(forReading: source)

        guard audioFile.length > 0 else {
            throw NSError(description: "duration is 0 for \(source.soxPath)")
        }

        var outputBin = source.deletingLastPathComponent()

        if let destination, destination.isDirectory {
            outputBin = destination
        }

        let baseName = newName ?? source.deletingPathExtension().lastPathComponent

        let left = baseName + ".L." + source.pathExtension
        let right = baseName + ".R." + source.pathExtension

        let url1 = outputBin.appendingPathComponent(left)
        let url2 = outputBin.appendingPathComponent(right)

        if overwrite || !url1.exists {
            guard SOX_SUCCESS.rawValue == sox.remix(source.soxPath, output: url1.soxPath, channel: "1") else {
                throw NSError(description: "Failed to export channel 1")
            }
        }

        if overwrite || !url2.exists {
            guard SOX_SUCCESS.rawValue == sox.remix(source.soxPath, output: url2.soxPath, channel: "2") else {
                throw NSError(description: "Failed to export channel 2")
            }
        }

        guard url1.exists, url2.exists else {
            throw NSError(description: "Failed to convert stereo pair, urls weren't written")
        }

        return SplitStereoPair(left: url1, right: url2)
    }

    /// Export all channels as mono files.
    /// For mono input, returns a single-element array with the remixed file.
    public func exportChannels(
        input source: URL,
        destination: URL? = nil,
        newName: String? = nil
    ) throws -> [URL] {
        var outputBin = source.deletingLastPathComponent()

        if let destination, destination.isDirectory {
            outputBin = destination
        }

        let baseName = newName ?? source.deletingPathExtension().lastPathComponent

        let channels = try AVAudioFile(forReading: source).fileFormat.channelCount

        guard channels > 0 else {
            throw NSError(description: "File has no audio channels: \(source.soxPath)")
        }

        var urls = [URL]()

        for i in 0 ..< channels {
            let channel = i + 1
            let filename = baseName + ".\(channel)." + source.pathExtension
            let url = outputBin.appendingPathComponent(filename)

            guard SOX_SUCCESS.rawValue == sox.remix(source.soxPath, output: url.soxPath, channel: String(describing: channel)) else {
                throw NSError(description: "Failed to export channels of \(source.soxPath)")
            }

            urls.append(url)
        }

        return urls
    }

    /// Mix a stereo file to mono
    public func stereoToMono(
        source: URL,
        destination: URL? = nil,
        newName: String? = nil,
        overwrite: Bool = true
    ) throws -> URL {
        var outputBin = source.deletingLastPathComponent()

        if let destination, destination.isDirectory {
            outputBin = destination
        }

        let baseName = newName ?? source.deletingPathExtension().lastPathComponent
        let left = baseName + ".Mono." + source.pathExtension

        let url1 = outputBin.appendingPathComponent(left)

        if !overwrite, url1.exists {
            return url1
        }

        guard SOX_SUCCESS.rawValue == sox.remix(source.soxPath, output: url1.soxPath, channel: "1"), url1.exists else {
            throw NSError(description: "Failed to convert to mono: \(source.soxPath)")
        }

        return url1
    }

    // MARK: - Multi-Channel

    /// Combine multiple mono files into a single multi-channel wave file.
    ///
    /// `sox -M chan1.wav chan2.wav chan3.wav chan4.wav chan5.wav multi.wav`
    @discardableResult
    public func createMultiChannelWave(
        input files: [URL],
        output: URL
    ) throws -> Bool {
        let inputs = files.filter(\.exists)

        guard inputs.isNotEmpty else {
            throw NSError(description: "No valid input files provided for multi-channel merge")
        }

        let paths = inputs.map(\.soxPath)

        let status = sox.createMultiChannelWave(paths, output: output.soxPath)

        guard SOX_SUCCESS.rawValue == status, output.exists else {
            throw NSError(description: "Failed to create multi-channel wave at \(output.soxPath)")
        }

        return true
    }
}

// MARK: - URL Extension

private extension URL {
    /// File-system path suitable for passing to SoX.
    /// Uses the non-deprecated `path(percentEncoded:)` on macOS 13+ and falls back to `.path` on macOS 12.
    var soxPath: String {
        if #available(macOS 13, iOS 16, *) {
            return path(percentEncoded: false)
        } else {
            return path
        }
    }
}
