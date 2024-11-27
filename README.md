# Audio Steganography

Audio Steganography embeds information within an audio file in a way that is 
hardly noticable to humans for hiding a secret message.

## Algorithms

1. Least Significant Bit (LSB) Matching

    >The LSB algorithm focuses on minimizing the alterations made to the
    >cover media to avoid detection.

    >The least significant bit of the audio file's first `m` bytes are
    >modified to match the secret message, where `m` represents the length
    >of the secret message in binary.

    >LSB matching randomly adds or subtracts 1 to each LSB that differs
    >from the secret message.
    >This method creates a more secure alternative to standard LSB replacement.

    >Decryption simply requires reading the LSB of the first `m` bytes of
    >the embedded audio file.

2. Phase Coding

    >Phase Coding hides information in the phase component of an audio signal.
    >Modifications using this method cannot be audibly perceived by humans,
    >which addresses the noise added by LSB.

    >The cover audio file divided into segments is converted to the
    >frequency domain by applying the Fast Fourier Transform (FFT).
    >The secret message is embedded into the each segment's phase components.
    >Applying the Inverse Fast Fourier Transform (IFFT) converts the data
    >back to the time domain for outputting.

    >Decryption requires segmenting the embedded audio file and reading
    >the phase shifts of each segment.

3. Bipolar Backward-Forward Echo Hiding

    >Echo hiding embeds information in a signal by adding unnoticable echos
    >corresponding to the bits of the message.
    >Symmetrical echo impulses of bipolar backward-forward echo hiding
    >increase its robustness compared to other echo hiding methods.
    
    >Delayed versions of the cover audio based on the 0-bit and 1-bit echo
    >kernels are added onto the cover audio with a mixer signal created from
    >the hidden message.

    >Decryption consists of segmenting the audio file and retrieving the
    delay points of each segment to determine the message bit value.

## Secret Message Input

This code only supports `.txt` files for the secret message input.
Each character is read as a binary string of its ascii code.

### LSB Matching

Each character requires 7 bits.
The maximum characters permitted is calculated by

$$max = \frac{size_{cover}}{7} - 1$$

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;where $size_{cover}$
represents the size of the cover audio file in bytes.

### Phase Coding

Each character requires 12 bits.
The maximum characters permitted is calculated by 

$$max_1 = \lfloor\frac{\frac{L}{4}  * (S - 1)}{12}\rfloor$$

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;where
$S = \frac{size_{cover}}{L}$ and $size_{cover}$ respresents size of the cover
audio sampled at 44.1 kHz.

If $max_1 > 2^{24} - 1$, then the max is calculated by

$$max_2 = \frac{2^{24} - 1}{12}$$

### Bipolar Backward-Forward Echo Hiding

Each character requires 12 bits.
The maximum characters permitted is calculated by

$$max = \frac{size_{cover}}{L/12}$$

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;where $size_{cover}$
represents the size of the cover audio sampled at 44.1 kHz.


## Cover Audio Input

This code supports `.wav` and/or `.mp3` files for the cover audio input, 
depending on the algorithm.
The formatting of the data depends on the algorithm implemented.

### LSB Matching

The cover audio file data is retrieved as binary data.
An end-of-text descriptor is embedded after the secret message.

### Phase Coding

The cover audio is retrieved as audio data with a sample rate of 44.1 kHz.
A 24-bit binary string describing the length of the binary message is embedded
in the first segment.
Each binary string of the secret message is converted into an 8-bit binary
string to implement 12-bit Hamming error correcting.

### Bipolar Backward-Forward Echo Hiding

The cover audio is retrieved as audio data with a sample of 44.1 kHz.
Each binary string of the secret message is converted into an 8-bit binary
string to implement 12-bit Hamming error correcting.

## References

- [LSB steganography in images and audio](https://daniellerch.me/stego/intro/lsb-en/)

- [An Improved Phase Coding Audio Steganography Algorithm](https://arxiv.org/html/2408.13277v1)

- [Audio Steganography using Phase Coding](https://medium.com/@achyuta.katta/audio-steganography-using-phase-encoding-d13f100380f2)

- [A Comparison of Echo Hiding Methods](http://www.epstem.net/en/download/article-file/381457)

- [Hamming Code in Computer Network](https://www.geeksforgeeks.org/hamming-code-in-computer-network/)
