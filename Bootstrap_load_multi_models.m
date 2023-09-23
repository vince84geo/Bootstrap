%
%         SCRIPT FOR LOADING MULTIPLE BOOTSTRAPED *.OUT Model FILES
%           Into an Multi-Dimensional Array of [Nz:Nx:# of files]
%                      
%          Get Log, Mean and Std Dev from Multi-Dimensional Array
%
%          Out put descriptive statistics into *.OUT model format
%
%                       last updated 18/06/2019
%                      b k at adelaide edu au
%
clear

% list all *.out files in working dir
file_List = struct2cell(dir('*.out'))';

% Get model mesh dimensions from first file
filename = file_List{1,1};
fileID = fopen(filename,'r');

% Collect info on mesh from header (Row 1)
formatSpec = '%16f %16f %16f';
endRow = 1;
dataArray = textscan(fileID, formatSpec,endRow, 'Delimiter', '', 'WhiteSpace', '');

Nx = dataArray{1,1};
Ny = dataArray{1,2};
Nz = dataArray{1,3};

% Preallocate model mesh to speed up operation 
Model_Array = zeros(Nz,Nx,numel(file_List(:,1)));

% Load Nx Data
formatSpec = '%f';
endRow = Nx;
dataArray = textscan(fileID, formatSpec,endRow, 'Delimiter', '', 'WhiteSpace', '');
Nx_data = double(dataArray{1,1});

% Load Ny Data
formatSpec = '%d';
endRow = Ny;
dataArray = textscan(fileID, formatSpec,endRow, 'Delimiter', '', 'WhiteSpace', '');
Ny_data = double(dataArray{1,1});

% Load Nz Data
formatSpec = '%d';
endRow = Nz;
[dataArray,position] = textscan(fileID, formatSpec,endRow, 'Delimiter', '', 'WhiteSpace', '');
Nz_data = double(dataArray{1,1});
fclose(fileID);

% loop through each *.out model file in list
for i = 1:numel(file_List(:,1))
    % select *.out to load
    filename = file_List{i,1};
    
    fileID = fopen(filename,'r');
    formatSpec = '%16f';
    endRow = 3 + Nx + Nz + Ny; % Skip 
    % Skip first parts of out file
    skip = textscan(fileID, formatSpec,endRow, 'Delimiter', '', 'WhiteSpace', '');
    
    % Loop through each Nz row and save values to model mesh
    for j = 1:Nz
        
        endRow = 1; % Read the Nx row number
        dataArray = textscan(fileID, formatSpec,endRow, 'Delimiter', '', 'WhiteSpace', '');
        Nz_Number = double(dataArray{1,1});
        
        endRow = Nx; % Read all values in Nx row
        dataArray = textscan(fileID, formatSpec,endRow, 'Delimiter', '', 'WhiteSpace', '');
        
        % Store all values into model array according to Nx row value
        Model_Array(j,:,i) = double(dataArray{1,1})';
    end   
    fclose(fileID);
end

% Descriptive Statistics from multidimensional array data
Model_Mean = zeros(Nz,Nx);
Model_Std = zeros(Nz,Nx);
Model_Std_l = zeros(Nz,Nx);
Model_Mean_l = zeros(Nz,Nx);

Model_log = log(Model_Array);
for i = 1:Nx
   for j = 1:Nz
       Model_Std_l(j,i) = std(Model_log(j,i,:));
       Model_Mean_l(j,i) = mean(Model_log(j,i,:));
       Model_Std(j,i) = std(Model_Array(j,i,:));
       Model_Mean(j,i) = mean(Model_Array(j,i,:));
   end
end
Model_Std_l = exp(Model_Std_l);
Model_Mean_l = exp(Model_Mean_l);

% Create sting list to export models
Model_Export_List = ["Bootstrap_Mean.out","Bootstrap_Log_Mean.out","Bootstrap_Std.out","Bootstrap_Log_Std.out"]';

% Loop through the model list and export them
for j = 1:numel(Model_Export_List)
    % export the mean format in *.out format
    fileID = fopen(char(Model_Export_List(j,:)),'w');
    
    fprintf(fileID,'%16d%16d%16d\n',Nx,Ny,Nz); % Print header file
    fprintf(fileID,'%16f%16f%16f%16f%16f%16f%16f%16f\n',Nx_data); % Print header file
    fprintf(fileID,'\n');
    fprintf(fileID,'%16f\n',Ny_data);
    fprintf(fileID,'%16f%16f%16f%16f%16f%16f%16f%16f\n',Nz_data);
    for i = 1:Nz
        fprintf(fileID,'\n');
        fprintf(fileID,'%16d\n',i);
        fprintf(fileID,'%16e%16e%16e%16e%16e%16e%16e%16e\n',Model_Mean(i,:)); % Print header file
    end
    fprintf(fileID,'\n%s','Created by GeotoolsTM');
    fprintf(fileID,'\n%s','Curnamona  (site name)');
    fprintf(fileID,'\n%s','               1               1  (i j block numbers)');
    fprintf(fileID,'\n%s','      348.964086     6549.462297  (real world coordinates)');
    fprintf(fileID,'\n%s','       12.299865  (rotation)');
    fprintf(fileID,'\n%s','           0.150  (top elevation)');
    fprintf(fileID,'\n');
    
    fclose(fileID);      
end