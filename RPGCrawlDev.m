%create an option to generate a town or skip to interface
if input('generateTown')
    townName = input('townName');
    %% set population parameters
    MeanTownPop = 300;
    SDTownPop = 120;
    MaxPop = 1000;
    MinPop = 50;

    MeanBuildingPop = 5;
    SDBuildingPop = 1;
    MinBuildingPop = 3;
    MaxBuildingPop = 9;

    Pop = normInBounds(MeanTownPop, SDTownPop,  MinPop, MaxPop); 
    BuildingPop = normInBounds(MeanBuildingPop, SDBuildingPop, MinBuildingPop, MaxBuildingPop);
    % find the dimensions of grid that will lead to approximately the right number of buildings/person after running the building generating process.

    %% create a layout of buildings based on DimBuildings
    DimBuildings = floor(sqrt(Pop / BuildingPop) * 1.61803); % sqrt number of ideal buildings times golden ratio
    TotBuildings = 0;
    Layout = zeros(DimBuildings); 
    for row = 2:DimBuildings
        for col = 2:DimBuildings
            % if no neighbours, building; if all neighbours,building; otherwise random
            Neighbours = Layout(row, col - 1) + Layout(row - 1,col - 1) + Layout(row - 1,col);
            if Neighbours == 3
                Layout(row,col) = 0;
            elseif Neighbours == 0
                Layout(row,col) = 1;
            else
                Layout(row,col) = randi([0 1]);
            end
        end
    end
    BuildingLocations = Shuffle(find(Layout));
    TotBuildings = sum(Layout, 'all');
    %% create buildings
    BuildingTypes = readtable("CSVs\BuildingTypes.csv");
    BuildingProperties = {'type', 'character'};
    BuildingList = cell2table(cell(TotBuildings, length(BuildingProperties)),'VariableNames',BuildingProperties); 
    BuildingList = addvars(BuildingList, BuildingLocations);
    BInd = 1; 
    for BType = 1:(height(BuildingTypes) - 1)
        nBType = nGivenPPerPop(Pop, BuildingTypes.SupPopVal(BType));
        BuildingList.type(BInd:(BInd + nBType - 1)) = BuildingTypes.building(BType); 
        BInd = nBType + BInd;
    end
    BuildingList.type(BInd:end) = {'House'}; 

    for BInd = 1:height(BuildingList)
        characteristics = BuildingTypes.characteristics(ismember(BuildingTypes.building, BuildingList.type(BInd)));
        characteristics = split(characteristics{1}, "; ");
        BuildingList.character(BInd) = characteristics(randi([1 length(characteristics)]));
    end

    %% create people
    personTypes = readtable("CSVs\personTypes.csv");
    personProperties = {'name', 'job', 'intentions', 'temperament', 'race', 'age', 'gender', 'height'};
    PersonList = cell2table(cell(Pop, length(personProperties)),'VariableNames',personProperties); 
    for property = 3:length(personProperties)
       for person = 1:height(PersonList)
           PersonList(person, property) = assignByProp(personTypes, personProperties(property));
       end
    end
    %make sure we don't have any problematic intentions
    PersonList.age(ismember(PersonList.age,'child') & ismember(PersonList.intentions,'seduce')) = {'adult'}; 

    PersonNames = readtable("CSVs\names.csv");
    location = nan([height(PersonList) 1]);
    for person = 1:height(PersonList)
      name = cell([1 2]);  
      name(1)  = rndFromNamedCol(PersonNames, strcat(PersonList.race(person), '1')); 
      name(2) = rndFromNamedCol(PersonNames, strcat(PersonList.race(person), '2'));
      PersonList.name(person) = {append(name{1}, ' ', name{2})};
      BldSelect = randi([1 height(BuildingList)]);
      location(person) = BuildingList.BuildingLocations(BldSelect);
      %PersonList.building(person) = BuildingList.type(BldSelect);
    end
    PersonList = addvars(PersonList, location);

    PInd = 1; 
    JobList = cell([Pop 1]);
    roles = personTypes(ismember(personTypes.characteristic, 'role'), :);

    for PType = 1:height(roles)
        nJob = nGivenPPerPop(Pop, roles.value(PType));
        PersonList.job(PInd:(PInd + nJob - 1)) = roles.name(PType); 
        PInd = nJob + PInd;
    end

    %make role a selectable list of options like building characteristics
    for person = PInd:Pop
        buildingJobList = BuildingTypes.worker(ismember(BuildingTypes.building, BuildingList.type(BuildingList.BuildingLocations == PersonList.location(person))));
        buildingJobList = split(buildingJobList{1}, "; ");
        PersonList.job(person) = buildingJobList(randi([1 length(buildingJobList)]));
    end
    PersonList.age(ismember(PersonList.job,'Sex worker') & ismember(PersonList.age,'child')) = {'adult'}; 

    currentLocation = randi([1 DimBuildings^2]);
    %% save vars
    data.PersonList = PersonList;
    data.BuildingList = BuildingList;
    data.Layout = Layout;
    data.CurrentLocation = currentLocation;
    savstr = strcat('Towns\', townName, '.mat');    
    save(savstr, 'data');
end    

%% load vars
townName = input('load');
loadstr = strcat('Towns\', townName, '.mat');    
load(loadstr);

BuildingTypes = readtable("CSVs\BuildingTypes.csv");

PersonList = data.PersonList ;
Pop = height(PersonList);
disp(PersonList)

BuildingList = data.BuildingList ;
TotBuildings = height(BuildingList);
disp(BuildingList)

Layout = data.Layout;
currentLocation = data.CurrentLocation;

while 1
    disp('map')
    thisLayout = Layout;
    thisLayout(currentLocation) = 2;
    thisLayout = [1:size(thisLayout,2); thisLayout];
    thisLayout = [(0:size(thisLayout,1) - 1)', thisLayout];
    disp(thisLayout);
    disp('location')
    if Layout(currentLocation)
        thisBuilding = BuildingList(BuildingList.BuildingLocations == currentLocation, :);
        disp(thisBuilding)
    else
        disp('road')
    end
    disp('surrounds') 
    [row, col] = ind2sub(size(Layout), currentLocation);
    neighbourArray = [row - 1, col - 1; row - 1, col; row - 1, col + 1; 
                      row, col - 1; row, col + 1;
                      row + 1, col - 1; row + 1, col; row + 1, col + 1;];
    neighbourArray(logical(sum(neighbourArray == 0 | neighbourArray > size(Layout, 1), 2)), :) = [];
    neighbourVec = sub2ind(size(Layout), neighbourArray(:, 1), neighbourArray(:, 2));
    buildings = BuildingList(ismember(BuildingList.BuildingLocations, neighbourVec), :);
    [bRow, bCol] = ind2sub(size(Layout), buildings.BuildingLocations);
    buildings = addvars(buildings, bRow, bCol);
    disp(buildings)
    disp('people')
    if Layout(currentLocation)
        %people in the building
        %workers
        workerInd = Shuffle(find(PersonList.location == currentLocation));
        nworker = normInBounds(Pop/TotBuildings, 3, 0, length(workerInd));
        %patrons
        buildingIdx = ismember(BuildingTypes.building, thisBuilding.type);
        nPatron = normInBounds(BuildingTypes.patrons(buildingIdx), BuildingTypes.patronsVar(buildingIdx), 0, 15);
        
        peopleInd = unique([workerInd(1:nworker)' randi([1 height(PersonList)], 1, nPatron)]);
        people = PersonList(peopleInd, :);
    else
        %people in the road
        nPeople = normInBounds(2, 2, 0, 15);
        people = PersonList(randi([1 Pop], 1, nPeople), :);
    end
    [bRow, bCol] = ind2sub(size(Layout), people.location);
    people = addvars(people, bRow, bCol);
    disp(people)
    %add to party, change intention
    row = input('row');
    col = input('col');
    currentLocation = sub2ind(size(Layout), row, col);
end

%% functions
function selection = rndFromNamedCol(table, column)
  Set = table2cell(table(:,ismember(table.Properties.VariableNames, column)));
  selector = randi([1 sum(~cellfun(@isempty, Set))]);
  selection = split(Set(selector));
  selection = selection(1);
  selection = split(selection, '/');
  selection = selection(1);
end

function selection = assignByProp(table, characteristic)
    set = table(ismember(table.characteristic, characteristic), :);
    if isnan(set.value(1))
        selector = randi([1 height(set)]);
        selection = set.name(selector);
        return
    else
        selector = randi([1 sum(set.value)]);
        for i = 1:height(set)
           if selector <= sum(set.value(1:i))
               selection = set.name(i);
               return 
           end
        end
    end
end

function val = normInBounds(mean, sd, min, max)
    val = floor(normrnd(mean, sd));
    if val < min
        val = min;
    elseif val > max 
        val = max;
    end
end


function n = nGivenPPerPop(pop, prob)
    n = 0;
    for i = 1:pop
        x = randi([1 prob]);
        n = n + (x == prob);
    end
end
