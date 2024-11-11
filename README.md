# Audio Steganography

Audio Steganography embeds information within an audio file in a way that is 
hardly noticable to humans for hiding a secret message.

## Algorithms

1. Least Significant Bit (LSB) Matching

    >The LSB algorithm focuses on minimizing the alterations made to the cover media to avoid detection.

    >The least significant bit of the audio file's first `m` bytes are modified to match the secret message, where `m` represents the length of the secret message in binary.

    >LSB matching randomly adds or subtracts 1 to each LSB that differs from the secret message.
    >This method creates a more secure alternative to standard LSB replacement.

    >Decryption simply requires reading the LSB of the first `m` bytes of the embedded audio file.

2. Phase Coding

    >Phase Coding hides information in the phase component of an audio signal.
    >Modifications using this method cannot be audibly perceived by humans, which addresses the noise added by LSB.

    >The cover audio file divided into segments is converted to the frequency domain by applying the Fast Fourier Transform (FFT).
    >The secret message is embedded into the each segment's phase components.
    >Applying the Inverse Fast Fourier Transform (IFFT) converts the data back to the time domain for outputting.

    >Decryption requires segmenting the embedded audio file and reading the phase shifts of each segment.

## Usage

### Input Files

This code supports `.wav` and/or `.mp3` files for the cover audio input, 
depending on the algorithm.

The secret message to be hidden is read in binary from a `.txt` file. The 
maximum characters permitted depends on the algorithm.

**LSB Matching**

$$max = size_{audio} / 7 - 1$$

**Phase Coding**

$$max = \lfloor (L / 4  * (S - 1)) / 12 \rfloor$$

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;where $S = size_{audio} / L$, or

$$max = (2^{24} - 1) / 12$$

### Input File Processing

The cover audio file data is retrieved as binary data. The formatting of the data depends on the algorithm implemented.

The secret message is converted to a binary string where the ascii code of each character is converted into a 7-bit binary string.

**LSB Matching**: An end-of-text descriptor (0x3) is appended to the end of the secret message for decryption.

**Phase Coding**: The length of the binary message as a 14-bit binary string is appended to the end of the secret message for decryption.

## References

- [LSB steganography in images and audio](https://daniellerch.me/stego/intro/lsb-en/)

- [An Improved Phase Coding Audio Steganography Algorithm](https://arxiv.org/html/2408.13277v1)

- [Audio Steganography using Phase Coding](https://medium.com/@achyuta.katta/audio-steganography-using-phase-encoding-d13f100380f2)

- [Hamming Code in Computer Network](https://www.geeksforgeeks.org/hamming-code-in-computer-network/)
