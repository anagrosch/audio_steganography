% Least Significant Bit (LSB) matching audio steganography functions
% Embed each bit of a secret message into the LSB of an audio file

classdef LSBMatchingContainer
    methods(Static)
        % Perform LSB steganography on binary data
        function lsbEncrypt(input, msg, output)
            % Process hidden message
            msg(end + 1) = 3; % add end-of-text
            msgBin = char(join(string(dec2bin(msg,7)),'')); %combine binary into 1 char array

            disp('Encrypting audio file...');
            startPoint = 0; %embedding starting point
            if strcmp(output.ext,'.wav')
                startPoint = 46; %start after header of .wav
            end
        
            % LSB matching
            ciphertext = input.data;
            for i = 1:length(msgBin)
                % Convert byte to binary
                bin = dec2bin(ciphertext(i+startPoint));

                % Change LSB to match msg
                if bin(end) ~= msgBin(i)
                    if ciphertext(i+startPoint) == 255 %prevent 255 -> 0
                        ciphertext(i+startPoint) = ciphertext(i+startPoint) - 1;
                    elseif ciphertext(i+startPoint) == 0 %prevent 0 -> 255
                        ciphertext(i+startPoint) = ciphertext(i+startPoint) + 1;
                    else %randomly select +/- 1
                        ciphertext(i+startPoint) = ciphertext(i+startPoint) + (2*randi(2)-3);
                    end
                end
            end
            bin2File(ciphertext,output.fullfile);
        end

        % Decrypt hidden message with LSB steganography
        function msg = lsbDecrypt(input, ext)
            fprintf("Decrypting audio file...");
            startPoint = 0; %embedding starting point
            if strcmp(ext,'.wav')
                startPoint = 46; %start after header of .wav
            end

            inputBin = dec2bin(input.data);
            msg = zeros(input.dsize,1);
            byte = char(zeros(1,7));

            for i = 1:input.dsize
                % Get LSB of each byte
                byte(mod(i-1,7)+1) = inputBin(i+startPoint, end);

                % Check if end-of-text reached
                if mod(i,7) == 0
                    if bin2dec(byte) == 3
                        break
                    end
                    msg(i/7,1) = bin2dec(byte);
                end
            end
            msg = msg(1:i/7-1); %remove empty elements
            fprintf("Done");
        
            % Convert msg to txt file
            bin2File(msg,fullfile('output','decrypted_lsb_msg.txt'));
        end

        % Get data from audio file
        function x = readAudioData(audioInput)
            [x.data, x.dsize] = readBinData(audioInput);
        end

        % Convert binary vector to readable file
        function bin2File(binData, filename)
            fid = fopen(filename,'wb');
            fwrite(fid,binData,'uint8');
            fclose(fid);
            fprintf("\nOutput file created: '%s'\n\n",filename);
        end
    end
end
