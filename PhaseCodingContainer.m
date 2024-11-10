% Phase Coding audio steganography functions
% Alter audio's phase to embed each bit of a secret message
%
% Code based off @ktekeli phase_enc & phase_dec
% https://github.com/ktekeli/audio-steganography-algorithms/tree/master/04-Phase-Coding

classdef PhaseCodingContainer
    methods(Static)
        function phaseEncrypt(input, msg, output)
            % Process hidden message
            m = 7*length(msg);
            mBin = reshape(dec2bin(m,14),2,7);
            msg = [dec2bin(msg); mBin]; %add message length to message end
            msgBin = reshape(msg',1,7*length(msg)); %combine binary into 1 char array

            % Arrange audio signal into segments
            L = 8192; %segment length
            N = floor(input.dsize/L); %num of segments
            S = reshape(input.data(1:N*L,1),L,N); %segments => columns
            
            % Get phase for each segment
            X = fft(S);
            P = angle(X);

            % Calculate phase difference between segments
            deltaPhase = zeros(L,N);
            deltaPhase(:,2:N) = P(:,2:N) - P(:,1:N-1);

            % Convert msg data into phase shifts
            m = length(msgBin); %update msg length
            bPhase = zeros(1,m);
            for j=1:m
                if strcmp(msgBin(j),'0')
                    bPhase(j) = pi/2;
                else
                    bPhase(j) = -pi/2;
                end
            end

            % Embed data to mid frequency range w/symmetry
            outP(:,1) = P(:,1);
            outP(L/2-m+1:L/2,1) = bPhase;
            outP(L/2+2:L/2+m+1,1) = -flip(bPhase);

            % Alter phase shift with msg
            for k=2:N
                outP(:,k) = outP(:,k-1) + deltaPhase(:,k);
            end

            % Convert to time domain
            Y = real(ifft(abs(X) .* exp(1i*outP)));
            y = reshape(Y,N*L,1);
            y = [y;input.data(N*L+1:input.dsize,1)];

            audiowrite(output.fullfile,y,input.fs);
        end

        % Decrypt hidden message
        function msg = phaseDecrypt(input)
            % Arrange audio signal into segments
            L = 8192; %segment length

            % Get phase for first segment
            X = fft(input.data(1:L,1));
            P = angle(X);

            % Read message length
            msgLen = char(zeros(2,7));
            for i=1:2
                for j=1:7
                    % Get bit from each phase
                    idx = (i-1)*7+j;
                    if P(L/2-14+idx) > 0
                         msgLen(i,j) = '0';
                    else
                         msgLen(i,j) = '1';
                    end
                end
            end
            m = bin2dec(reshape(msgLen,1,14));

            % Decrypt msg bits from phase
            msg = char(zeros(1,m));
            for k=1:m
                % Get bit from each phase
                if P(L/2-m-14+k) > 0
                    msg(k) = '0';
                else
                    msg(k) = '1';
                end
            end
            msg = reshape(msg,7,m/7)';

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
