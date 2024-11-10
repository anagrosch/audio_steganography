
% Convert binary vector to readable file
function bin2File(binData, filename)
    fid = fopen(filename,'wb');
    fwrite(fid,binData,'uint8');
    fclose(fid);
    fprintf("\nOutput file created: '%s'\n",filename);
end