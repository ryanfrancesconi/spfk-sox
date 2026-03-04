# SPFK SoX

A Swift actor-based wrapper around [libSoX](https://sox.sourceforge.net/) (Sound eXchange) for macOS. Provides thread-safe audio format conversion, trimming, channel manipulation, and MP3 encoding through a clean async/await API.

## Features

- **Format Conversion** -- PCM (WAV, AIFF, CAF) with configurable bit depth and sample rate
- **MP3 Encoding** -- LAME-based encoding with bitrate and quality control
- **Trimming** -- Time-based audio trimming with automatic fade to eliminate clicks
- **Channel Operations** -- Split stereo to dual mono, extract individual channels, mix to mono
- **Multi-Channel Merge** -- Combine multiple mono files into a single multi-channel wave
- **Thread Safety** -- Swift actor isolation ensures serialized access to the non-thread-safe libSoX

## Requirements

- macOS 12.0+
- Swift 6.2+

## Usage

All operations go through the shared `SoX` actor instance:

```swift
import SPFKSoX

// Convert WAV to MP3 at 256 kbps
let success = await SoX.shared.convertMP3(
    input: inputURL,
    output: outputURL,
    bitRate: 256,
    sampleRate: 48000
)

// Convert to 24-bit 48kHz AIFF
await SoX.shared.convertPCM(
    input: inputURL,
    output: outputURL,
    bitDepth: 24,
    sampleRate: 48000
)

// Trim audio from 1s to 3s
await SoX.shared.trim(
    input: inputURL,
    output: outputURL,
    startTime: 1.0,
    endTime: 3.0
)

// Split stereo to dual mono
let pair = try await SoX.shared.exportSplitStereo(input: stereoURL, destination: outputDir)
// pair.left, pair.right

// Extract all channels as individual files
let channels = try await SoX.shared.exportChannels(input: multiChannelURL, destination: outputDir)

// Mix stereo to mono
let monoURL = try await SoX.shared.stereoToMono(source: stereoURL, destination: outputDir)

// Merge mono files into multi-channel wave
await SoX.shared.createMultiChannelWave(input: [ch1, ch2, ch3], output: outputURL)
```

## Architecture

```
SPFKSoX (Swift Actor)
  -- async/await, thread safety
SoxWrapper (Objective-C)
  -- argv construction, C bridging
libSoX + LAME + MAD + libsndfile (C)
  -- audio processing via prebuilt xcframeworks
```

## Bundled Libraries

| Library | Purpose |
|---------|---------|
| libsox | Core SoX audio processing engine |
| libsndfile | Audio file I/O (WAV, AIFF, FLAC, etc.) |
| libsamplerate | Sample rate conversion |
| libmp3lame | MP3 encoding (LAME) |
| libmad | MP3 decoding |
| libmpg123 | MP3 decoding (alternative) |

## Dependencies

- [spfk-audio-base](https://github.com/ryanfrancesconi/spfk-audio-base) -- Audio file type utilities
- [spfk-testing](https://github.com/ryanfrancesconi/spfk-testing) (test only) -- Test infrastructure
