// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/spfk-audio

#import "sox.h"
#import "SoxWrapper.h"

@implementation SoxWrapper

char *_sox = "sox";

// MARK: - Convert (libsox API)

/// Unified conversion using the libsox API directly.
/// Parameters bits, sampleRate, and compression are optional (pass nil to skip).
/// - bits: Output bit depth (precision), e.g. @"16", @"24"
/// - sampleRate: Output sample rate, e.g. @"44100", @"48000"
/// - compression: Compression parameter (-C value), e.g. @"128.2" for MP3, @"6" for OGG quality
- (int)convertInput:(NSString *)input
             output:(NSString *)output
               bits:(nullable NSString *)bits
         sampleRate:(nullable NSString *)sampleRate
        compression:(nullable NSString *)compression
{
    if (sox_init() != SOX_SUCCESS) {
        return SOX_EOF;
    }

    sox_format_t *soxInput = NULL;
    sox_format_t *soxOutput = NULL;
    sox_effects_chain_t *chain = NULL;
    sox_effect_t *e = NULL;
    int result = SOX_EOF;
    sox_signalinfo_t out_signal;
    sox_signalinfo_t interm_signal;
    sox_encodinginfo_t out_encoding;
    sox_encodinginfo_t *encoding_ptr = NULL;
    const char *input_filetype = NULL;
    const char *output_filetype = NULL;

    // Determine if extensions require routing through libsndfile.
    // libsox's bundled binary lacks native FLAC/OGG format handlers, but the
    // sndfile pseudo-format handler delegates to libsndfile which supports them.
    NSString *inputExt = input.pathExtension.lowercaseString;
    if ([inputExt isEqualToString:@"flac"] ||
        [inputExt isEqualToString:@"ogg"] ||
        [inputExt isEqualToString:@"oga"] ||
        [inputExt isEqualToString:@"vorbis"]) {
        input_filetype = "sndfile";
    }

    NSString *outputExt = output.pathExtension.lowercaseString;
    if ([outputExt isEqualToString:@"flac"] ||
        [outputExt isEqualToString:@"ogg"] ||
        [outputExt isEqualToString:@"oga"] ||
        [outputExt isEqualToString:@"vorbis"]) {
        output_filetype = "sndfile";
    }

    // Open input file
    soxInput = sox_open_read(input.UTF8String, NULL, NULL, input_filetype);
    if (soxInput == NULL) {
        goto cleanup;
    }

    // Configure output signal from input (deep copy)
    out_signal = soxInput->signal;

    // Apply requested bit depth to signal precision
    if (bits != nil) {
        unsigned int bitDepth = (unsigned int)bits.intValue;
        if (bitDepth > 0) {
            out_signal.precision = bitDepth;
        }
    }

    // Apply requested sample rate
    if (sampleRate != nil) {
        double rate = sampleRate.doubleValue;
        if (rate > 0) {
            out_signal.rate = rate;
        }
    }

    // Open output file.
    // The signal precision drives bit depth for PCM/FLAC formats.
    // For sndfile-backed formats, skip the compression encoding parameter —
    // SoX-style compression values don't map to libsndfile's encoding system.
    // Sample rate conversion for these formats should be handled upstream.
    if (compression != nil && output_filetype == NULL) {
        memset(&out_encoding, 0, sizeof(out_encoding));
        out_encoding.encoding = SOX_ENCODING_UNKNOWN;
        out_encoding.compression = compression.doubleValue;
        encoding_ptr = &out_encoding;
    }

    soxOutput = sox_open_write(output.UTF8String,
                               &out_signal,
                               encoding_ptr,
                               output_filetype, NULL, NULL);

    if (soxOutput == NULL) {
        goto cleanup;
    }

    // Create effects chain
    chain = sox_create_effects_chain(&soxInput->encoding, &soxOutput->encoding);
    if (chain == NULL) {
        goto cleanup;
    }

    interm_signal = soxInput->signal; // working copy

    // Input effect (source)
    {
        char *args[10];
        e = sox_create_effect(sox_find_effect("input"));
        args[0] = (char *)soxInput;
        sox_effect_options(e, 1, args);
        sox_add_effect(chain, e, &interm_signal, &soxInput->signal);
        free(e);
        e = NULL;
    }

    // Rate effect (if sample rate conversion needed)
    if (sampleRate != nil) {
        double rate = sampleRate.doubleValue;
        if (rate > 0 && rate != soxInput->signal.rate) {
            char *args[10];
            e = sox_create_effect(sox_find_effect("rate"));
            sox_effect_options(e, 0, NULL);
            sox_add_effect(chain, e, &interm_signal, &soxOutput->signal);
            free(e);
            e = NULL;
        }
    }

    // Output effect (sink)
    {
        char *args[10];
        e = sox_create_effect(sox_find_effect("output"));
        args[0] = (char *)soxOutput;
        sox_effect_options(e, 1, args);
        sox_add_effect(chain, e, &interm_signal, &soxOutput->signal);
        free(e);
        e = NULL;
    }

    // Flow the effects chain
    result = sox_flow_effects(chain, NULL, NULL);
    // result checked by caller

cleanup:
    if (chain != NULL) {
        sox_delete_effects_chain(chain);
    }
    if (soxOutput != NULL) {
        sox_close(soxOutput);
    }
    if (soxInput != NULL) {
        sox_close(soxInput);
    }
    sox_quit();

    return result;
}

// MARK: - Public Convert Methods (delegate to unified implementation)

- (int)convert:(NSString *)input
        output:(NSString *)output
          bits:(NSString *)bits
    sampleRate:(NSString *)sampleRate
{
    return [self convertInput:input output:output bits:bits sampleRate:sampleRate compression:nil];
}

- (int)convert:(NSString *)input
        output:(NSString *)output
          bits:(NSString *)bits
{
    return [self convertInput:input output:output bits:bits sampleRate:nil compression:nil];
}

- (int)convert:(NSString *)input
        output:(NSString *)output
    sampleRate:(NSString *)sampleRate
{
    return [self convertInput:input output:output bits:nil sampleRate:sampleRate compression:nil];
}

- (int)convert:(NSString *)input
        output:(NSString *)output
{
    return [self convertInput:input output:output bits:nil sampleRate:nil compression:nil];
}

- (int)convert:(NSString *)input
        output:(NSString *)output
       bitRate:(NSString *)bitRate
    sampleRate:(NSString *)sampleRate
{
    return [self convertInput:input output:output bits:nil sampleRate:sampleRate compression:bitRate];
}

- (int)convert:(NSString *)input
        output:(NSString *)output
       bitRate:(NSString *)bitRate
{
    return [self convertInput:input output:output bits:nil sampleRate:nil compression:bitRate];
}

// MARK: - Remix (libsox API)

- (int)remix:(NSString *)input
      output:(NSString *)output
     channel:(NSString *)channel
{
    if (sox_init() != SOX_SUCCESS) {
        return SOX_EOF;
    }

    sox_format_t *soxInput = NULL;
    sox_format_t *soxOutput = NULL;
    sox_effects_chain_t *chain = NULL;
    sox_effect_t *e = NULL;
    int result = SOX_EOF;

    soxInput = sox_open_read(input.UTF8String, NULL, NULL, NULL);
    if (soxInput == NULL) {
        goto cleanup;
    }

    sox_signalinfo_t out_signal = soxInput->signal;
    out_signal.channels = 1; // remix to mono

    soxOutput = sox_open_write(output.UTF8String,
                               &out_signal,
                               NULL, NULL, NULL, NULL);

    if (soxOutput == NULL) {
        goto cleanup;
    }

    chain = sox_create_effects_chain(&soxInput->encoding, &soxOutput->encoding);
    if (chain == NULL) {
        goto cleanup;
    }

    sox_signalinfo_t interm_signal = soxInput->signal;

    // Input effect
    {
        char *args[10];
        e = sox_create_effect(sox_find_effect("input"));
        args[0] = (char *)soxInput;
        sox_effect_options(e, 1, args);
        sox_add_effect(chain, e, &interm_signal, &soxInput->signal);
        free(e);
        e = NULL;
    }

    // Remix effect - extract specified channel
    {
        char *args[10];
        e = sox_create_effect(sox_find_effect("remix"));
        args[0] = (char *)channel.UTF8String;
        sox_effect_options(e, 1, args);
        sox_add_effect(chain, e, &interm_signal, &soxOutput->signal);
        free(e);
        e = NULL;
    }

    // Output effect
    {
        char *args[10];
        e = sox_create_effect(sox_find_effect("output"));
        args[0] = (char *)soxOutput;
        sox_effect_options(e, 1, args);
        sox_add_effect(chain, e, &interm_signal, &soxOutput->signal);
        free(e);
        e = NULL;
    }

    result = sox_flow_effects(chain, NULL, NULL);

cleanup:
    if (chain != NULL) {
        sox_delete_effects_chain(chain);
    }
    if (soxOutput != NULL) {
        sox_close(soxOutput);
    }
    if (soxInput != NULL) {
        sox_close(soxInput);
    }
    sox_quit();

    return result;
}

// MARK: - Multi-Channel Wave (sox_main - multi-input merge)

/// Multi-input merge requires sox_main since the libsox effects chain API
/// is designed for single-input processing. The -M (merge) flag in sox_main
/// handles interleaving multiple input files into a single multi-channel output.
- (int)createMultiChannelWave:(NSArray *)inputs
                       output:(NSString *)output {
    int count = 2;

    // sox -M chan1.wav chan2.wav chan3.wav chan4.wav chan5.wav multi.wav
    char *argv[2 + inputs.count + 1];

    argv[0] = _sox;
    argv[1] = (char *)"-M";

    for (id object in inputs) {
        NSString *value = (NSString *)object;
        argv[count++] = (char *)value.UTF8String;
    }

    argv[count++] = (char *)output.UTF8String;

    return sox_main(count, argv);
}

// MARK: - Trim (libsox API)

- (int)  trim:(NSString *)input
       output:(NSString *)output
    startTime:(NSString *)startTime
      endTime:(NSString *)endTime
     fadeTime:(NSString *)fadeTime {
    if (sox_init() != SOX_SUCCESS) {
        return SOX_EOF;
    }

    sox_format_t *soxInput = NULL;
    sox_format_t *soxOutput = NULL;
    sox_effects_chain_t *chain = NULL;
    sox_effect_t *e = NULL;
    int result = SOX_EOF;

    char *args[10];

    soxInput = sox_open_read(input.UTF8String, NULL, NULL, NULL);

    if (soxInput == NULL) {
        goto cleanup;
    }

    sox_signalinfo_t interm_signal = soxInput->signal; /* NB: deep copy */
    sox_signalinfo_t out_signal = soxInput->signal;

    soxOutput = sox_open_write(output.UTF8String,
                               &out_signal,
                               NULL, NULL, NULL, NULL);

    if (soxOutput == NULL) {
        goto cleanup;
    }

    chain = sox_create_effects_chain(&soxInput->encoding, &soxOutput->encoding);

    // Input effect
    e = sox_create_effect(sox_find_effect("input"));
    args[0] = (char *)soxInput;
    sox_effect_options(e, 1, args);
    sox_add_effect(chain, e, &interm_signal, &soxInput->signal);
    free(e);

    // Trim effect
    e = sox_create_effect(sox_find_effect("trim"));

    int argc = 1;
    args[0] = (char *)startTime.UTF8String;

    if (![endTime isEqualToString:@"0"]) {
        args[1] = (char *)endTime.UTF8String;
        argc = 2;
    }

    sox_effect_options(e, argc, args);
    sox_add_effect(chain, e, &interm_signal, &out_signal);
    free(e);

    // Fade effect (skip if fadeTime is "0")
    if (![fadeTime isEqualToString:@"0"] && ![fadeTime isEqualToString:@"0.0"]) {
        args[0] = "h";
        args[1] = (char *)fadeTime.UTF8String;
        args[2] = "0";
        args[3] = (char *)fadeTime.UTF8String;
        e = sox_create_effect(sox_find_effect("fade"));
        sox_effect_options(e, 4, args);
        sox_add_effect(chain, e, &interm_signal, &out_signal);
        free(e);
    }

    // Output effect
    e = sox_create_effect(sox_find_effect("output"));
    args[0] = (char *)soxOutput;
    sox_effect_options(e, 1, args);
    sox_add_effect(chain, e, &interm_signal, &out_signal);
    free(e);

    result = sox_flow_effects(chain, NULL, NULL);

cleanup:
    if (chain != NULL) {
        sox_delete_effects_chain(chain);
    }
    if (soxOutput != NULL) {
        sox_close(soxOutput);
    }
    if (soxInput != NULL) {
        sox_close(soxInput);
    }
    sox_quit();

    return result;
}

@end
