-- Alter Database Name
ALTER DATABASE [Housing Data Cleaning] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
ALTER DATABASE [Housing Data Cleaning] MODIFY NAME = HousingDataCleaning;
ALTER DATABASE HousingDataCleaning SET MULTI_USER WITH ROLLBACK IMMEDIATE;


-- Cleaning Data in SQL Queries -- 

SELECT * FROM HousingDataCleaning.dbo.NashvilleHousing

------------------

-- Standardize Date Format

SELECT SaleDate, CONVERT(Date,SaleDate)
FROM HousingDataCleaning.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing ALTER COLUMN SaleDate DATE

-----------------

---- Populate Property Address Data

SELECT * 
FROM HousingDataCleaning.dbo.NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID


-- WHERE ParcelID of table a has NULL Property address where b.PropertyAddress has a value

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM HousingDataCleaning.dbo.NashvilleHousing a
JOIN HousingDataCleaning.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL


-- Update Table a

UPDATE a  
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM HousingDataCleaning.dbo.NashvilleHousing a
JOIN HousingDataCleaning.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

------------------

---- Breaking out Address into Individual Columns (Address, City, State)

SELECT PropertyAddress
FROM HousingDataCleaning.dbo.NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID



-- Separate the Address with SUBSTRING ,
SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1 , LEN(PropertyAddress)) as Address
FROM HousingDataCleaning.dbo.NashvilleHousing


-- Add New Columns to Table
ALTER TABLE NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE NashvilleHousing
Add PropertySplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1 , LEN(PropertyAddress))



--- Alternative Method for Changing Address

SELECT OwnerAddress
FROM HousingDataCleaning.dbo.NashvilleHousing

SELECT
PARSENAME(REPLACE(OwnerAddress,',','.'),3)
,PARSENAME(REPLACE(OwnerAddress,',','.'),2)
,PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM HousingDataCleaning.dbo.NashvilleHousing


ALTER TABLE NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

ALTER TABLE NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

ALTER TABLE NashvilleHousing
Add OwnerSplitState Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)


SELECT * 
FROM HousingDataCleaning.dbo.NashvilleHousing


------------------

-- Change Y and N to Yes and No in "Sold as Vacant" Field

SELECT DISTINCT (SoldAsVacant), COUNT(SoldAsVacant)
FROM HousingDataCleaning.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant
,	CASE When SoldAsVacant = 'Y' THEN 'Yes'
		When SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END
FROM HousingDataCleaning.dbo.NashvilleHousing


UPDATE NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
		When SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END
FROM HousingDataCleaning.dbo.NashvilleHousing





------------------

-- Remove Duplicates


-- create a separate partition to check if the stated columns are exactly the same
-- duplicate row_num == 2


WITH RowNumCTE AS (
SELECT *, 
	ROW_NUMBER() OVER (
		PARTITION BY ParcelID,
					PropertyAddress,
					SalePrice,
					SaleDate,
					LegalReference
					ORDER BY UniqueID
					) row_num

FROM HousingDataCleaning.dbo.NashvilleHousing
--ORDER BY ParcelID
)

SELECT *
--DELETE
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress



------------------

-- Delete Unused Columns


SELECT *
FROM HousingDataCleaning.dbo.NashvilleHousing

ALTER TABLE HousingDataCleaning.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate
