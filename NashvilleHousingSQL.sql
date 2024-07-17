/* 

Cleaning Data in SQL

*/

Select *
From PortfolioProject.dbo.NashvilleHousing

--------------------Format Date (Remove time value from SaleDate)--------------------

Select SaleDate, CONVERT(Date,SaleDate)
From PortfolioProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing --Add table
Add SaleDateConverted Date;

Update NashvilleHousing --Add results
SET SaleDateConverted = CONVERT(Date,SaleDate)

Select SaleDateConverted, CONVERT(Date,SaleDate)
From PortfolioProject.dbo.NashvilleHousing

--------------------Populate Property Address Data (Clean null values)--------------------

Select *
From PortfolioProject.dbo.NashvilleHousing
Where PropertyAddress is null --Find Null Values
ORDER BY ParcelID

--Self join to compare UniqueID, ParcelID, and Property Address (Compare 2 identical ParcelID's with a different UniqueID to populate missing PropertyAddress)
Select A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress, ISNULL(A.PropertyAddress, B.PropertyAddress) --When A.PropertyAddress ISNULL populate with B.PropertyAddress
From PortfolioProject.dbo.NashvilleHousing A
JOIN PortfolioProject.dbo.NashvilleHousing B
	on A.ParcelID = B.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
Where A.PropertyAddress is null
--RUN THIS BLOCK AGAIN AFTER UPDATING TO VERIFY NULL VALUES HAVE BEEN REMOVED

Update A --NashvilleHousing Alias
SET PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress)
From PortfolioProject.dbo.NashvilleHousing A
JOIN PortfolioProject.dbo.NashvilleHousing B
	on A.ParcelID = B.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
Where A.PropertyAddress is null

--------------------Separate PropertyAddress into Individual Columns (Street Address, City)--------------------

Select PropertyAddress
From PortfolioProject.dbo.NashvilleHousing

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address --Look at PropertyAddress, Look for Commas, within PropertyAddress column, use -1 to remove the comma
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as Address --Start at the comma, +1 to remove comma, Length of Property Address is where to finish
From PortfolioProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

Update NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE NashvilleHousing
Add PropertySplitCity Nvarchar(255);

Update NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

Select *
From PortfolioProject.dbo.NashvilleHousing --Will see 2 new columns added to the end of dataset

--------------------Separate OwnerAddress into Individual Columns (Street Address, City, State)--------------------

Select OwnerAddress
From PortfolioProject.dbo.NashvilleHousing 

Select
PARSENAME(REPLACE(OwnerAddress,',','.'), 3) --PARSENAME looks for periods. Replace the commas with periods then PARSENAME will separate
, PARSENAME(REPLACE(OwnerAddress,',','.'), 2)
, PARSENAME(REPLACE(OwnerAddress,',','.'), 1)
From PortfolioProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'), 3)

ALTER TABLE NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'), 2)

ALTER TABLE NashvilleHousing
Add OwnerSplitState Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'), 1)

--------------------Update SoldAsVacant Y and N to Yes and No--------------------

Select Distinct(SoldAsVacant), Count(SoldAsVacant) --Show the amount of Yes, No, Y, N
From PortfolioProject.dbo.NashvilleHousing
Group by SoldAsVacant
ORDER BY 2 --RUN THIS BLOCK AGAIN AFTER UPDATING TO VERIFY Y AND N ARE UPDATED


Select SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
From PortfolioProject.dbo.NashvilleHousing

Update NashvilleHousing 
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END

--------------------Remove Duplicates--------------------

With RowNumCTE AS( --Use CTE to identify duplicates and then remove them
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress, 
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From PortfolioProject.dbo.NashvilleHousing
)
DELETE --Delete duplicate data, 
From RowNumCTE
Where row_num > 1

--------------------Remove Unused Columns--------------------

Select *
From PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate