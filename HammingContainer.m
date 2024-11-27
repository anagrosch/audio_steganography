% Hamming error checking & correcting functions
% Add 4 parity bits to 8-bit characters (8,12)

classdef HammingContainer
    methods(Static)
        % Add Hamming error checking
        function updated = addParityBits(input)
            updated = char(zeros(size(input,1),12));

            for i=1:size(input,1)
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
            data = char(zeros(size(input,1),8));

            for i=1:size(input,1)
                % Check for errors
                p1 = mod(sum(input(i,[1, 3, 5, 7, 9, 11])), 2);
                p2 = mod(sum(input(i,[2, 3, 6, 7, 10, 11])), 2);
                p4 = mod(sum(input(i,[4, 5, 6, 7, 12])), 2);
                p8 = mod(sum(input(i,[8, 9, 10, 11, 12])), 2);
    
                % Determine incorrect bit
                error = p1 * 1 + p2 * 2 + p4 * 4 + p8 * 8;
    
                % Correct bit if necessary
                if error ~= 0
                    if error <= 12
                        input(i,error) = char('0'+mod(input(i,error) + 1, 2));
                    else
                        warning('Too many bits corrupted for Hamming correction.')
                    end
                end
                
                data(i,:) = input(i,[3, 5, 6, 7, 9, 10, 11, 12]);
            end
        end
    end
end