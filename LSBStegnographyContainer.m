% Least Significant Bit (LSB) audio stenography functions
% Embed each bit of a secret message into the LSB of an audio file

classdef LSBStegnographyContainer
    methods(Static)
        % Perform LSB stenography on binary data
        function lsbEncrypt(input, msg, output)
            % Process hidden message
            msg(end + 1) = 3; % add end-of-text
            msgBin = char(join(string(dec2bin(msg)),'')); %combine binary into 1 char array

            disp('Encrypting audio file...');
            startPoint = 0; %embedding starting point
            if strcmp(output.ext,'.wav')
                startPoint = 46; %start after header of .wav
            end
        
            % Convert input data to binary strings
            ciphertext = string(dec2bin(input.data));
        
            for i = 1:length(msgBin)
                ciphertext{i+startPoint}(8) = msgBin(i); %change LSB of input to hidden msg bit
            end
            bin2File(bin2dec(ciphertext),output.fullfile);
        end

        % Decrypt hidden message with LSB stenography
        function msg = lsbDecrypt(input, ext)
            fprintf("Decrypting audio file...");
            startPoint = 0; %embedding starting point
            if strcmp(ext,'.wav')
                startPoint = 46; %start after header of .wav
            end
        
            msg = strings(input.dsize,1);
            inputBin = string(dec2bin(input.data));
            arrIdx = 1; EOT = '0000011';
        
            for i = (startPoint+1):length(inputBin)
                % Get LSB of each number
                msg{arrIdx}(end + 1) = inputBin{i}(end);
        
                % Check if end-of-text reached
                if mod(i-startPoint,7) == 0
                    if strcmp(msg{arrIdx},EOT)
                        break
                    end
                    arrIdx = arrIdx + 1;
                end
            end
            msg = msg(1:arrIdx-1); %remove end-of-text character
            fprintf("Done");
        
            % Convert msg to txt file
            msg = bin2dec(msg);
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
