import numpy as np
import math
import random
import pandas as pd
# import functions as fns - dunno how to handle custom fns in python

# functions -----------------------


def nGivenSupportingPop(pop, supPop):
    n = 0
    for i in range(1, pop):
        x = random.randint(1, supPop)
        n = n + (x == supPop)
    return n


# Set population parameters ----------------------------------

MeanTownPop = 300
SDTownPop = 120
MaxPop = 1000
MinPop = 50

# people within a building
MeanBuildingPop = 5
SDBuildingPop = 1
MinBuildingPop = 3
MaxBuildingPop = 9


Pop = math.floor(np.random.normal(MeanTownPop, SDTownPop, 1))

if Pop > MaxPop:
    Pop = MaxPop
elif Pop < MinPop:
    Pop = MinPop

BuildingPop = math.floor(np.random.normal(MeanBuildingPop, SDBuildingPop, 1))

if BuildingPop > MaxBuildingPop:
    BuildingPop = MaxBuildingPop
elif BuildingPop < MinBuildingPop:
    BuildingPop = MinBuildingPop

# layout buildings -----------------

# find the dimensions of grid that will lead to approximately the right number
# of buildings/person after running the building generating process:

idealBuildingN = Pop / BuildingPop
DimBuildings = math.floor(math.sqrt(idealBuildingN) * 1.61803) + 1
# sqrt number of ideal number buildings times golden ratio

# layout buildings as ones on an array of zeros, such that there aren't any innaccessible buildings
Layout = np.zeros((DimBuildings, DimBuildings), dtype=int)

for row in range(1, DimBuildings-1):
    for col in range(1, DimBuildings-1):
        # if no neighbours, building; if all neighbours,building; otherwise random
        Neighbours = Layout[row, col - 1] + Layout[row - 1, col - 1] + Layout[row - 1, col]
        if Neighbours == 3:
            Layout[row, col] = 0
        elif Neighbours == 0:
            Layout[row, col] = 1
        else:
            Layout[row, col] = random.randint(0, 1)

TotBuildings = np.sum(Layout)

BuildingLocations = (np.where(Layout == 1))

# print(BuildingLocations[1][1])
# BuildingLocations = Shuffle(find(Layout))

# create buildings
BuildingTypes = pd.read_csv("CSVs\BuildingTypes.csv")
BInd = 0
BuildingList = pd.DataFrame(index=range(TotBuildings), columns=['type', 'characteristic'])


# make a list of building types depending on the supporting population size, assign characteristics
for BType in range(0, (len(BuildingTypes) - 1)):
    nBType = nGivenSupportingPop(Pop, int(BuildingTypes.SupPopVal[BType]))
    BuildingList.type.iloc[BInd:(BInd + nBType)] = BuildingTypes.building[BType]
    characteristics = BuildingTypes.characteristics[1].split(';')
    BuildingList.characteristic.iloc[BInd:(
        BInd + nBType)] = characteristics[random.randint(0, len(characteristics))]
    BInd = nBType + BInd


houseCharacteristics = BuildingTypes.characteristics[len(BuildingTypes)].split(';')
print(houseCharacteristics)

for houseI in range(BInd, TotBuildings - 1):
    BuildingList.type.iloc[houseI] = "House"

print(BuildingList)
# print(nbuild)
