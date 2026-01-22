/* Standardized Date Format*/
ALTER TABLE NashvilleHousing
ADD SaleDateConverted date

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(date, SaleDate)

/* Populate Property Address Data */
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress) as UpdateATable
FROM NashvilleHousing as a
JOIN NashvilleHousing as b
ON a.ParcelID = b.parcelID
AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is NULL

UPDATE a 
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing as a
JOIN NashvilleHousing as b
ON a.ParcelID = b.parcelID
AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is NULL

/*Breaking out Address into individual columns (Address, City, State)*/
--PropertyAddress
SELECT PropertyAddress, SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as PropertyStreetAddress,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) as PropertyCity 
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertyStreetAddress NVARCHAR(255)

UPDATE NashvilleHousing
SET PropertyStreetAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE NashvilleHousing
ADD PropertyCity NVARCHAR(255)

UPDATE NashvilleHousing
SET PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

--OwnerAddress
SELECT OwnerAddress, LTRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)) AS OwnerStreetAddress,
PARSENAME(REPLACE(OwnerAddress,',','.'), 2) as OwnerCity,
PARSENAME(REPLACE(OwnerAddress,',','.'), 1) as OwnerState
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerStreetAddress NVARCHAR(255),
	OwnerCity NVARCHAR(255),
	OwnerState NVARCHAR(255)

UPDATE NashvilleHousing
SET OwnerStreetAddress = LTRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)),
	OwnerCity = LTRIM(PARSENAME(REPLACE(OwnerAddress,',','.'), 2)),
	OwnerState = LTRIM(PARSENAME(REPLACE(OwnerAddress,',','.'), 1))


/*Standardize SoldAsVacant column values:
  'Y' → 'Yes'
  'N' → 'No'
*/
SELECT SoldAsVacant, COUNT(SoldAsVacant) as CountByValue
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY CountByValue

SELECT SoldAsVacant,
CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END AS SoldAsVacantStandardized
FROM NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END 

/*Detecting Duplicates with ROW_NUMBER()*/
  --Preview
SELECT *, ROW_NUMBER() OVER 
	(PARTITION BY ParcelID,
				  PropertyAddress,
				  SalePrice,
				  SaleDate,
				  LegalReference
	 ORDER BY UniqueID) AS RowNum
FROM NashvilleHousing

WITH CTE_RowNum as (
SELECT *, ROW_NUMBER() OVER (
	 PARTITION BY ParcelID,
				  PropertyAddress,
				  SalePrice,
				  SaleDate,
				  LegalReference
	 ORDER BY UniqueID) AS RowNum
FROM NashvilleHousing)

SELECT *
FROM CTE_RowNum
WHERE RowNum > 1

--If duplicates should be removed 
DELETE
FROM CTE_RowNum
WHERE RowNum > 1
