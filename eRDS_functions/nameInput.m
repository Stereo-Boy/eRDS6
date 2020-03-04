function nameId=nameInput(dataPath)
%safely ask for a name to save file;
%if file already exists, dont erases it but prompts for creating another one
nameId = input('Enter participant''s ID:  ', 's');
success=check_files(dataPath, nameId, 0, 0, 'verboseON');

if success==0
    choice = input('1: add numbers to the ID (new participant) or 2: exit?');
    if choice==1
     str=floor(now);
     nameId = [nameId '_' num2str(str)];
     disp(['New ID: ',nameId]);
     check_files(dataPath, nameId, 1, 1, 'verboseON');
    elseif choice==2
        error('Voluntary exit')
    else
        error('Input not understood')
    end
end