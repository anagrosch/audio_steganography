% Phase Coding audio steganography functions
% Alter audio's phase to embed each bit of a secret message
% Implements Hamming bit error checking from audiowrite & audioread
%
% Code based off @ktekeli phase_enc & phase_dec
% https://github.com/ktekeli/audio-steganography-algorithms/tree/master/04-Phase-Coding

classdef PhaseCodingContainer
    methods(Static)
        function phaseEncrypt(input, msg, output)
            % Process hidden message
            msg = PhaseCodingContainer.addParityBits(dec2bin(msg,8));
            m = 12*length(msg);

            % Get hidden message length
            msgBin = append(reshape(msg',1,[]),dec2bin(m,24)); %combine binary into 1 char array

            % Arrange audio signal into segments
            L = 8192; %segment length
            N = floor(input.dsize/L); %num of segments
            S = reshape(input.data(1:N*L,1),L,N); %segments => columns
            
            % Get phase for each segment
            X = fft(S);
            P = angle(X);

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

            audiowrite(output.fullfile,y,input.fs);
        end

        % Decrypt hidden message
        function msg = phaseDecrypt(input)
            % Arrange audio signal into segments
            L = 8192; %segment length
            N = floor(input.dsize/L); %num of segments
            S = reshape(input.data(1:N*L,1),L,N); %segments => columns

            % Get phase for first segment
            X = fft(S);
            P = angle(X);

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
            msg = PhaseCodingContainer.errorCheck(msg);

            % Convert msg to txt file
            msg = bin2dec(msg);
            bin2File(msg,fullfile('output','decrypted_pc_msg.txt'));
        end

        % Add Hamming error checking
        function updated = addParityBits(input)
            updated = char(zeros(length(input),12));

            for i=1:length(input)
                updated(i,[3, 5, 6, 7, 9, 10, 11, 12]) = input(i,:);
    
                % Calculate parity bits
                updated(i,1) = char('0'+mod(sum(updated(i,[3, 5, 7, 9, 11])), 2));
                updated(i,2) = char('0'+mod(sum(updated(i,[3, 6, 7, 10, 11])), 2));
                updated(i,4) = char('0'+mod(sum(updated(i,[5, 6, 7, 12])), 2));
                updated(i,8) = char('0'+mod(sum(updated(i,[9, 10, 11, 12])), 2));
            end
        end

        % Hamming error checking & correction
        function data = errorCheck(input)
            data = char(zeros(length(input),8));

            for i=1:length(input)
                % Check for errors
                p1 = mod(sum(input(i,[1, 3, 5, 7, 9, 11])), 2);
                p2 = mod(sum(input(i,[2, 3, 6, 7, 10, 11])), 2);
                p4 = mod(sum(input(i,[4, 5, 6, 7, 12])), 2);
                p8 = mod(sum(input(i,[8, 9, 10, 11, 12])), 2);
    
                % Determine incorrect bit
                error = p1 * 1 + p2 * 2 + p4 * 4 + p8 * 8;
    
                % Correct bit if necessary
                if error ~= 0
                    input(i,error) = char('0'+mod(input(i,error) + 1, 2));
                end
                
                data(i,:) = input(i,[3, 5, 6, 7, 9, 10, 11, 12]);
            end
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
