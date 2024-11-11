% AUDIO STEGANOGRAPHY TOOL
% MATLAB Script hiding a text message in an audio file.
% Performs LSB or Phase Coding Method
% 

close all; clear all; clc;
lsb = LSBMatchingContainer;
pc = PhaseCodingContainer;

% Print welcome page
disp("============================");
fprintf("WELCOME TO AUDIO STEGANOGRAPHY\n");
fprintf("============================\n")

% Get steganography algorithm
algorithm = stegSelection();

% Get user function choice
choice = funcSelection();

% Get audio input
disp('Select a cover audio file.');

validFiles = '*.wav';
if strcmp(algorithm,'_lsb')
    validFiles = '*.wav;*.mp3';
end
audioFiles = append('Audio Files (',validFiles,')');
[audioInput.filename, audioInput.path] = uigetfile({validFiles,...
                                                    audioFiles},...
                                                    'Select audio file');
if isequal(audioInput.filename,0)
    disp('User selected cancel');
    return
end
audioInput.fullfile = fullfile(audioInput.path,audioInput.filename);
[~, audioInput.name, audioInput.ext] = fileparts(audioInput.fullfile);

% Read audio data
if strcmp(algorithm,'_lsb')
    x = lsb.readAudioData(audioInput);
elseif strcmp(algorithm,'_pc')
    x = pc.readAudioData(audioInput);
end

% Play input audio
fprintf("Playing '%s'...\n\n", audioInput.filename);
%playClip(audioInput.fullfile);

outPath = mkOutputDir(); %create directory for output files

% Encrypt audio file
if strcmp(choice,'E')
    % Set output filename
    output.filename = append(audioInput.name,algorithm,audioInput.ext);
    output.ext = audioInput.ext;
    output.fullfile = fullfile(outPath,output.filename);

    % Calculate max hidden characters based on audio file size
    max = getMaxLen(algorithm,x);
    
    % Get secret message
    h = getSecretMsg(max);
    
    % Encrypt hidden msg in audio input
    if strcmp(algorithm,'_lsb')
        lsb.lsbEncrypt(x,h,output);
    elseif strcmp(algorithm,'_pc')
        pc.phaseEncrypt(x,h,output);
    end

    % Play output audio
    fprintf("Playing output '%s'...\n\n", output.filename);
    playClip(output.fullfile);

elseif strcmp(choice,'D') % Decrypt audio file
    if strcmp(algorithm,'_lsb')
        plaintext = lsb.lsbDecrypt(x, audioInput.ext);
    elseif strcmp(algorithm,'_pc')
        plaintext = pc.phaseDecrypt(x);
    end

    % Preview plaintext
    msgPreview(plaintext);
end

%% 
% Select steganography algorithm
function algorithm = stegSelection()
    validInputs = [1,2];
    disp('Select an algorithm to use.');
    disp('1: LSB Matching');
    disp('2: Phase Coding');
    choice = input('Enter selection: ');
    while ~any(ismember(choice,validInputs))
        choice = input('Invalid selection. Try again (Ctrl+C to quit): ');
    end

    if choice == 1
        disp('------------');
        disp('LSB Selected');
        disp('------------');
        algorithm = '_lsb';
    elseif choice == 2
        disp('---------------------')
        disp('Phase Coding Selected')
        disp('---------------------')
        algorithm = '_pc';
    end
end

% Select encryption/decryption
function choice = funcSelection()
    validInputs = ['E','D'];
    disp('Would you like to encrypt or decrypt an audio file?');
    disp('E: encrypt audio file');
    disp('D: decrypt audio file')
    choice = upper(input('Enter selection: ',"s"));
    while ~any(ismember(choice,validInputs))
        choice = upper(input('Invalid selection. Try again (Ctrl+C to quit): ',"s"));
    end

    % Print running selection
    if strcmp(choice,'E')
        disp('------------------------------');
        disp('STARTING ENCRYPTION PROCESS');
        disp('------------------------------');
    
    elseif strcmp(choice,'D')
        disp('------------------------------');
        disp('STARTING DECRYPTION PROCESS');
        disp('------------------------------');
    end
end

% Retrieve hidden message
function h = getSecretMsg(maxLength)
    % Get message file from user
    disp('Select hidden message file');
    [hiddenMsg.filename, hiddenMsg.path] = uigetfile({'*.txt',...
                                      'Audio Files (*.txt)'},...
                                      'Select hidden message file');
    if isequal(hiddenMsg.filename,0)
        disp('User selected cancel');
        return
    end

    % Read message data
    hiddenMsg.fullfile = fullfile(hiddenMsg.path,hiddenMsg.filename);
    [~,~, hiddenMsg.ext] = fileparts(hiddenMsg.fullfile);
    [h,~] = readBinData(hiddenMsg);
    
    % Check message is under max characters
    while length(h) > maxLength
        fprintf("Hidden message exceeded limit: (%d) characters",maxLength);

        % Get secret message from user
        [hiddenMsg.filename, hiddenMsg.path] = uigetfile({'*.txt',...
                                      'Audio Files (*.txt)'},...
                                      'Select hidden message file');
        if isequal(hiddenMsg.filename,0)
            disp('User selected cancel');
            return
        end

        % Read message data
        hiddenMsg.fullfile = fullfile(hiddenMsg.path,hiddenMsg.filename);
        [~,~, hiddenMsg.ext] = fileparts(hiddenMsg.fullfile);
        [h,~] = readBinData(hiddenMsg);
    end
end

% Determine max length for secret message
function max = getMaxLen(algorithm, input)
    if strcmp(algorithm,'_lsb')
        max = input.dsize/7 - 1; % save 1 character for end-of-text (0x3)
    elseif strcmp(algorithm,'_pc')
        L = 8192;
        S = input.dsize / L;
        max = floor((L/4*(S-1))/12);
        % max written to = L/4 = 2048 (only write in low-freq of segment)
        % max bits for msg = L/4 * (S - 1) (i.e. = 204800)
        % max char = floor(204800/12) = 17066

        % max 24-bits for msg length descriptor
        if max*12 > (2^24)-1
            max = ((2^24)-1)/12; %change max if video too large
        end
    end
end

% Print first two lines of decrypted message
function msgPreview(msg)
    % Convert decimal array to sentences
    text = splitlines(char(msg).');
    fprintf("\nExtracted message:\n");
    fprintf("------------------\n");

    % Display only first two lines if applicable
    l = length(text);
    if l <= 0
        disp('ERROR: no message extracted.');
        return
    elseif l > 2
        text = [text(1:2);'...(more lines)'];
    end
    disp(strjoin(text,'\n'));
    disp('------------------');
end

% Play audio file
function playClip(filename)
    [y, fs] = audioread(filename);
    duration = length(y) / fs;
    sound(y, fs)
    pause(duration);
end

% Create output directory
function path = mkOutputDir()
    if ~isfolder('output')
        mkdir('output')
    end
    path = what('output').path;
end
