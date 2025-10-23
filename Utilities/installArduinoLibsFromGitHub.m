%% installArduinoLibsFromGitHub.m
% ==================================================================================================
% Downloads a Zip of an Arduino Library from a Github repository and extracts it to the Arduino-CLI 
% user Libraries folder within the Matlab Support Packages for Arduino Hardware. Works in 2024a<
% By: Eric Prandovszky
% prandov@yorku.ca
% September 20, 2024
% ==================================================================================================
disp('Running: InstallArduinoLibsFromGitHub.m')
 
    % Enter the library repository URL
        repositoryURL = 'https://github.com/m5stack/M5Unit-Synth'; % M5Unit-Synth Library - REQUIRED
    % Call the function to install the library
        gitDownloadAndExtract(repositoryURL);

%% gitDownloadAndExtract(repositoryURL[Main Repo Page or .Zip], CustomlibraryFolderName[Optional: if the MATLAB add-on needs a specific folder name]) 
function gitDownloadAndExtract(repositoryURL, CustomlibraryFolderName)
        % repositoryURL character array of the git URL. 
        % CustomlibraryFolderName (Optional). This may be necessisary if your MATLAB custom arduino addon expects a different folder name

    % Check if matlab 2024a or newer is running
        if isMATLABReleaseOlderThan("R2024a")
        %currentVersion = ver('MATLAB');
        %if str2double(currentVersion.Version) <= 24 
        %if matlabRelease.Date <= datetime(2024, 5, 1)
            error('This code works on version r2024a or newer.');
        else
            % disp('MATLAB version OK! (r2024a or newer)');
        end
    % Check if Arduino support packages are installed
        if ~any(strcmp(matlab.addons.installedAddons().Identifier, 'ML_ARDUINO'))
            error('MATLAB Support Package for Arduino Hardware not Detected, please install it first.')
        end
    % Check if the URL matches a basic pattern
        if isempty(regexp(repositoryURL, '^(http|https)://github.com/[^\s/$.?#].[^\s]*$', 'once'))
            error('Not a valid github URL.')
        end
    % Extract the repository name
        urlparts = split(repositoryURL, '/'); % Split the URL by '/'
        repoName = urlparts{5}; % 5th part should be the repo name
    %Check for a custom library folder name
        if nargin < 2
            libraryFolderName = repoName;
        else    
            libraryFolderName = CustomlibraryFolderName;
        end   
        fprintf(' -Attempting to install the %s library in the folder %s.\n', repoName, libraryFolderName);
    % Set Destination Folder
        %addinLibrariesFolder = pwd; %PWD for testing
        addinLibrariesFolder = fullfile(arduinoio.CLIRoot, 'user','libraries');
        libraryFolderFullPath = fullfile(addinLibrariesFolder,libraryFolderName);
    % Check if the 'Library' folder exists
        if isfolder(fullfile(addinLibrariesFolder, libraryFolderName))
            cd(addinLibrariesFolder);
            fprintf(' --%s folder found, library might already be installed.\n',libraryFolderName);
            %%error('you may have already installed the requested library')
            return
        end
    % Check if this is an Arduino Library
        repoURL = strjoin(urlparts(1:5), '/');
        libPropsJson = '/blob/master/library.json';
        libPropsProp = '/blob/master/library.properties';
        try LibJson = webread([repoURL,libPropsJson]);catch;LibJson = 'none';end 
        try LibProp = webread([repoURL,libPropsProp]);catch;LibProp = 'none';end
        % Try to determine if the requested url is an arduino library by searching for 'arduino' in the library properties page
        keyword = 'arduino';
        if contains(LibJson, keyword, 'IgnoreCase', true) || contains(LibProp,keyword, 'IgnoreCase', true)
            disp(' --Arduino related git repository found');
        else
            % Warn the user, but continue anyway
            disp(' --! Did not find any reference to arduino in the library properties.');
            disp(' --* Double check library compatibility');
        end
    % Download the library repository
        % Check if the URL is a zip file just download that
        if endsWith(repositoryURL, '.zip')    
            archiveName = [libraryFolderName,'-',urlparts{end}];
            archiveNameFullPath = fullfile(addinLibrariesFolder, archiveName);
            if isfile(archiveNameFullPath)
                cd(addinLibrariesFolder);
                error(['A Folder named "', archiveName, '" exists in the selected folder.']);
            else
                websave(archiveNameFullPath, repositoryURL);
            end
        % If its the main repository url, use the git API to download
        else
            if endsWith(repositoryURL, '/') % Remove the end / to not cause an error
                repositoryURL = extractBefore(repositoryURL, length(repositoryURL)); 
            end
            archiveName = [repoName,'-master.zip'];
            archiveNameFullPath = fullfile(addinLibrariesFolder, archiveName);
            if isfile(archiveNameFullPath)
                cd(addinLibrariesFolder);
                error(['A Folder named "', archiveName, '" exists in the selected folder.']);
            else
                % Use the git API to download the library
                fprintf(' --Downloading %s Library\n',repoName);
                apiURL = ['https://api.github.com/repos/', repositoryURL(20:end), '/zipball'];
                options = weboptions('HeaderFields', {'Accept' 'application/vnd.github.v3+json'});
                response = webread(apiURL, options);
            end
            fid = fopen(archiveNameFullPath, 'w');
            fwrite(fid, response);
            fclose(fid);
        end
    % Extract the .zip
        fprintf(' --Extracting the %s Library.\n',repoName);
        extractFolder = fullfile(addinLibrariesFolder,'temp');
        unzip(archiveNameFullPath,extractFolder);
        % Github will name the folder 'owner-repository-releasecode' so Rename the extracted folder to match the repository name
        folderPattern = ['*',repoName,'*'];
        contents = dir(fullfile(extractFolder, folderPattern));
        folderNames = {contents([contents.isdir]).name};
        %Check for multiple folders in the temp directory (there should only be the one extracted archive folder)
        if size(folderNames, 1) == 0 && size(folderNames, 2) == 0
            fprintf(' Could not find the %s folder extract directory.\n %s',folderPattern)
        elseif size(folderNames, 1) == 1 && size(folderNames, 2) > 1
            fprintf('Error: Multiple folders with "%s" in the name exist in the extract directory.\n',folderPattern)
            disp('This function cant tell which folder to work with.')
            error('Check the # of folders in temp folder, or check the # of folders in the .zip archive.')
        else
    % Move the folder and Change a folder name useing movefile
        movefile(fullfile(extractFolder,folderNames{1}), libraryFolderFullPath);
        end    
    % Delete the .zip
        delete(archiveNameFullPath)
    % Remove the temp folder % because Arduino cli threw an error in osx sonoma(however it may have been a rosetta2 issue)
        rmdir(extractFolder) 
     %Move to the arduino libraries folder
        % cd(addinLibrariesFolder)
        disp(' --Done!')
end