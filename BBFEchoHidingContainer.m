% Bipolar Backward-Forward Echo Hiding (BBFEH) audio steganography func

classdef BBFEchoHidingContainer
    methods(Static)
        % Perform BBFEH on cover audio
        function bbfehEncrypt(input, msg, output, L)
            % Add EOT if needed
            N = 12*floor(input.dsize/L/12); %mod(N,12)=0
            if length(msg)*12 < N
                msg(end + 1) = 3; % add end-of-text
            end

            % Process hidden message
            msgBin = HammingContainer.addParityBits(dec2bin(msg,8));
            msgBin = reshape(msgBin', 1, 12*length(msg));

            % Pad with 0 if needed
            if length(msg)*12 < N
                msgBin(end+1:N) = '0';
            end
            msgBin = msgBin - '0'; %convert string to array

            fprintf("Embedding audio file...");
            % Create echo kernels (i)
            [h0,h1] = BBFEchoHidingContainer.mkEchoKernels();

            % Delayed versions of audio file (ii)
            k0 = filter(h0,1,input.data);
            k1 = filter(h1,1,input.data);
            
            % Create mixer signal w/Hann smoothing (iii)
            J = floor((L/12)/4); %mod(J,4)=0
            tmp = reshape(ones(L,1)*msgBin,N*L,1);
            H = conv(tmp, hann(J));                     %Hann smoothing
            norm  = H(J/2+1:end-J/2+1) / max(abs(H));   %Normalization
            mix = norm*ones(1,input.channels);

            % Embed echos into cover audio (iv)
            x = input.data(1:N*L,:)...
                + k1(1:N*L,:).*mix...
                + k0(1:N*L,:).*(1-mix);
            x = [x; input.data(N*L+1:input.dsize, :)];
            fprintf("Done\n\n");

            audiowrite(output.fullfile,x,input.fs);
            fprintf("Output file created: '%s'\n",output.fullfile);
        end

        % Decrypt hidden message with BBFEH
        function msg = bbfehDecrypt(input, L)
            d0 = 50; d1 = 75;
            n = -d1:d1;

            % Arrange audio signal into segments
            N = 12*floor(input.dsize/L/12); %num of segments
            S = reshape(input.data(1:N*L,1),L,N); %segments => columns

            fprintf("Extracting message from audio file...");
            msg = char(zeros(1,N));

            for i=1:N
                c = ifft(log(abs(fft(S(:,i))))); %nth real cepstrum

                % Get bit
                if c(n==d0) >= c(n==d1)
                    msg(i) = '0';
                else
                    msg(i) = '1';
                end
            end
            msg = reshape(msg(1:N),12,[])';
            msg = HammingContainer.errorCheck(msg);

            % Remove EOT & zero padding if needed
            msg = bin2dec(msg);
            if ismember(3,msg) %check if EOT exists
                msg = msg(1:find(msg==3)-1);
            end
            fprintf("Done\n\n");

            % Convert msg to txt file
            bin2File(msg,fullfile('output','decrypted_bbfeh_msg.txt'));
        end

        % Create the echo kernels
        function [h0, h1] = mkEchoKernels()
            d0 = 50; d1 = 75;
            n = 0:d1; a = 0.5;
            
            % Create 0-bit echo kernel
            h0 = zeros(1,d1+1);
            h0(n==d0) = a/4;
            h0(n==d1) = -a/4;
            h0 = [flip(h0(2:d1+1)),h0];

            % Create 1-bit echo kernel
            h1 = h0*(-1);
        end

        % Get data from audio file
        function x = readAudioData(audioInput)
            [x.data,x.fs] = audioread(audioInput.fullfile);
            [x.dsize, x.channels] = size(x.data);
        end
    end
end
