% AUDIO STEGANOGRAPHY TOOL
% MATLAB Script hiding a text message in an audio file.
% Performs LSB Matching, Phase Coding, BBFEH Method(s)
% 

close all; clear all; clc;
lsb = LSBMatchingContainer;
pc = PhaseCodingContainer;
bbfeh = BBFEchoHidingContainer;
CLIPPING = false; %true=clip input, false=reselect input

warning('off','backtrace'); %turn off warning backtraces

% Print welcome page
disp("==============================");
fprintf("WELCOME TO AUDIO STEGANOGRAPHY\n");
fprintf("==============================\n")

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
    disp('User selected cancel.');
    return
end
audioInput.fullfile = fullfile(audioInput.path,audioInput.filename);
[~, audioInput.name, audioInput.ext] = fileparts(audioInput.fullfile);

% Read audio data
if strcmp(algorithm,'_lsb')
    x = lsb.readAudioData(audioInput);
    L = 0; %L unused -> set to 0
elseif strcmp(algorithm,'_pc')
    x = pc.readAudioData(audioInput);
    L = 8192; %segment length
elseif strcmp(algorithm,'_bbfeh')
    x = bbfeh.readAudioData(audioInput);
    L = 12*1024; %segment length (for 12-bit)
end

% Play input audio
fprintf("Playing '%s'...", audioInput.filename);
playClip(audioInput.fullfile);
fprintf("Done\n\n");

outPath = mkOutputDir(); %create directory for output files

% Encrypt audio file
if strcmp(choice,'E')
    % Set output filename
    output.filename = append(audioInput.name,algorithm,audioInput.ext);
    output.ext = audioInput.ext;
    output.fullfile = fullfile(outPath,output.filename);

    % Calculate max hidden characters based on audio file size
    max = getMaxLen(algorithm,L,x);
    
    % Get secret message
    h = getSecretMsg(max, CLIPPING);
    if h == -1
        return
    end
    
    % Encrypt hidden msg in audio input
    if strcmp(algorithm,'_lsb')
        lsb.lsbEncrypt(x,h,output);
    elseif strcmp(algorithm,'_pc')
        pc.phaseEncrypt(x,h,output,L);
    elseif strcmp(algorithm,'_bbfeh')
        bbfeh.bbfehEncrypt(x,h,output,L);
    end

    % Play output audio
    fprintf("Playing output '%s'...", output.filename);
    playClip(output.fullfile);
    fprintf("Done\n\n");

elseif strcmp(choice,'D') % Decrypt audio file
    if strcmp(algorithm,'_lsb')
        plaintext = lsb.lsbDecrypt(x,audioInput.ext);
    elseif strcmp(algorithm,'_pc')
        plaintext = pc.phaseDecrypt(x,L);
    elseif strcmp(algorithm,'_bbfeh')
        plaintext = bbfeh.bbfehDecrypt(x,L);
    end

    % Preview plaintext
    msgPreview(plaintext);
end

%% 
% Select steganography algorithm
function algorithm = stegSelection()
    validInputs = [1,2,3];
    disp('Select an algorithm to use.');
    disp('----------------------');
    fprintf("| %-19s|\n","1: LSB Matching");
    fprintf("| %-19s|\n","2: Phase Coding");
    fprintf("| %-19s|\n","3: BBF Echo Hiding");
    disp('----------------------');

    choice = input('Enter selection: ');
    while ~any(ismember(choice,validInputs))
        warning('Invalid selection.')
        choice = input('Enter selection (Ctrl+C to quit): ');
    end

    if choice == 1
        fprintf("LSB Selected\n\n");
        algorithm = '_lsb';
    elseif choice == 2
        fprintf("Phase Coding Selected\n\n")
        algorithm = '_pc';
    elseif choice == 3
        fprintf("BBF Echo Hiding Selected\n\n")
        algorithm = '_bbfeh';
    end
end

% Select encryption/decryption
function choice = funcSelection()
    validInputs = ['E','D'];
    disp('Would you like to encrypt or decrypt an audio file?');
    disp('-------------------------');
    fprintf("| %-22s|\n","E: encrypt audio file");
    fprintf("| %-22s|\n","D: decrypt audio file");
    disp('-------------------------');

    choice = upper(input('Enter selection: ',"s"));
    while ~any(ismember(choice,validInputs))
        warning('Invalid selection.');
        choice = upper(input('Enter selection (Ctrl+C to quit): ',"s"));
    end

    % Print running selection
    if strcmp(choice,'E')
        fprintf('\n----------------------------\n');
        disp('STARTING ENCRYPTION PROCESS');
        disp('----------------------------');
    
    elseif strcmp(choice,'D')
        fprintf('\n----------------------------\n');
        disp('STARTING DECRYPTION PROCESS');
        disp('----------------------------');
    end
end

% Retrieve hidden message
function h = getSecretMsg(maxLength, CLIPPING)
    % Get message file from user
    disp('Select hidden message file');
    [hiddenMsg.filename, hiddenMsg.path] = uigetfile({'*.txt',...
                                      'Audio Files (*.txt)'},...
                                      'Select hidden message file');
    if isequal(hiddenMsg.filename,0)
        disp('User selected cancel.');
        h = -1;
        return
    end

    % Read message data
    hiddenMsg.fullfile = fullfile(hiddenMsg.path,hiddenMsg.filename);
    [~,~, hiddenMsg.ext] = fileparts(hiddenMsg.fullfile);
    [h,~] = readBinData(hiddenMsg);
    
    % Check message is under max characters
    if (length(h) > maxLength) && (CLIPPING == true)
        h = h(1:maxLength);
        warning("Hidden message exceeded %d character limit. " + ...
            "Clipped message: '%s'", maxLength, char(h)');
    end

    while (length(h) > maxLength) && (CLIPPING == false)
        warning("Hidden message exceeded limit: (%d) characters", maxLength);

        % Get secret message from user
        [hiddenMsg.filename, hiddenMsg.path] = uigetfile({'*.txt',...
                                      'Audio Files (*.txt)'},...
                                      'Select hidden message file');
        if isequal(hiddenMsg.filename,0)
            disp('User selected cancel.');
            h = -1;
            return
        end

        % Read message data
        hiddenMsg.fullfile = fullfile(hiddenMsg.path,hiddenMsg.filename);
        [~,~, hiddenMsg.ext] = fileparts(hiddenMsg.fullfile);
        [h,~] = readBinData(hiddenMsg);
    end
end

% Determine max length for secret message
function max = getMaxLen(algorithm, L, input)
    if strcmp(algorithm,'_lsb')
        max = input.dsize/7 - 1; % save 1 character for end-of-text (0x3)
    elseif strcmp(algorithm,'_pc')
        S = input.dsize / L;
        max = floor((L/4*(S-1))/12);
        % max written to = L/4 = 2048 (only write in low-freq of segment)
        % max bits for msg = L/4 * (S - 1) (i.e. = 204800)
        % max char = floor(204800/12) = 17066

        % max 24-bits for msg length descriptor
        if max*12 > (2^24)-1
            max = ((2^24)-1)/12; %change max if video too large
        end
    elseif strcmp(algorithm,'_bbfeh')
        max = floor(input.dsize/L/12); %12-bit char
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
