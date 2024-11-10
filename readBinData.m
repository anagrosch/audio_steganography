
% Read input audio file as binary data
function [data, dataLen] = readBinData(file)
    fprintf("Processing '%s' file...", file.filename);
    fid = fopen(file.fullfile,'rb');
    [data,dataLen] = fread(fid,'*uint8');
    fclose(fid);
    fprintf("Done\n");
end
