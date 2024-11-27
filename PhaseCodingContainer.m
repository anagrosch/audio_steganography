% Phase Coding audio steganography functions
% Alter audio's phase to embed each bit of a secret message
% Implements Hamming bit error checking from audiowrite & audioread
%
% Code based off @ktekeli phase_enc & phase_dec
% https://github.com/ktekeli/audio-steganography-algorithms/tree/master/04-Phase-Coding

classdef PhaseCodingContainer
    methods(Static)
        function phaseEncrypt(input, msg, output, L)
            % Process hidden message
            msg = HammingContainer.addParityBits(dec2bin(msg,8));
            m = 12*length(msg);

            % Get hidden message length
            msgBin = append(reshape(msg',1,[]),dec2bin(m,24)); %combine binary into 1 char array

            % Arrange audio signal into segments
            N = floor(input.dsize/L); %num of segments
            S = reshape(input.data(1:N*L,1),L,N); %segments => columns
            
            % Get phase for each segment
            X = fft(S);
            P = angle(X);

            fprintf("Encrypting audio file...");
            % Convert msg data into phase shifts
            n = ceil(m/N); %msg bits per segment
            pad = ceil(m/N)*ceil(m/ceil(m/N))-m;
            bPhase = zeros(1,m+pad+24);
            
            for j=1:length(msgBin)
                if strcmp(msgBin(j),'0')
                    bPhase(j) = pi/2;
                else
                    bPhase(j) = -pi/2;
                end
            end

            % Embed msg length to first segment
            outP = P;
            outP(L/2-24+1:L/2,1) = bPhase(end-pad-23:end-pad);
            outP(L/2+2:L/2+24+1,1) = -flip(bPhase(end-pad-23:end-pad));

            % Embed data to mid frequency range w/symmetry
            for k=1:ceil(m/n)
                mStart = (k-1) * n + 1;
                mEnd = k * n;
                outP(L/2-n+1:L/2,k+1) = bPhase(mStart:mEnd);
                outP(L/2+2:L/2+n+1,k+1) = -flip(bPhase(mStart:mEnd));
            end

            % Convert to time domain
            Y = real(ifft(abs(X) .* exp(1i*outP)));
            y = reshape(Y,N*L,1);
            y = [y;input.data(N*L+1:input.dsize,1)];
            fprintf("Done\n\n");

            audiowrite(output.fullfile,y,input.fs);
        end

        % Decrypt hidden message
        function msg = phaseDecrypt(input, L)
            % Arrange audio signal into segments
            N = floor(input.dsize/L); %num of segments
            S = reshape(input.data(1:N*L,1),L,N); %segments => columns

            % Get phase for first segment
            X = fft(S);
            P = angle(X);

            fprintf("Decrypting audio file...");
            % Read message length
            msgLen = char(zeros(1,24));
            for j=1:24
                % Get bit from each phase
                if P(L/2-24+j,1) > 0
                     msgLen(j) = '0';
                else
                     msgLen(j) = '1';
                end
            end
            m = bin2dec(reshape(msgLen,1,24));

            n = ceil(m / N); %msg bits per segment
            P = P(L/2-n+1:L/2,2:ceil(m/n)+1); %remove unneeded phases

            % Decrypt msg bits from phase
            msg = char(zeros(1,m));
            for k=1:ceil(m/n)
                for l=1:n
                    % Get bit from each phase
                    if P(l,k) > 0
                        msg((k-1)*n+l) = '0';
                    else
                        msg((k-1)*n+l) = '1';
                    end
                end
            end
            msg = reshape(msg(1:m),12,[])';
            msg = HammingContainer.errorCheck(msg);
            fprintf("Done\n\n");

            % Convert msg to txt file
            msg = bin2dec(msg);
            bin2File(msg,fullfile('output','decrypted_pc_msg.txt'));
        end

        % Get data from audio file
        function x = readAudioData(audioInput)
            [x.data,x.fs] = audioread(audioInput.fullfile);
            x.dsize = length(x.data);
        end

        % Write output to file
        function data2File(filename, data, fs)
            audiowrite(filename,data,fs);
            fprintf("\nOutput file created: '%s'\n",filename);
        end
    end
end
