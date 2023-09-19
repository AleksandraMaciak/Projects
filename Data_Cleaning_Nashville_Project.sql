
-- SQL Data Cleaning

SELECT *
FROM NashvilleHousing.dbo.NashvilleHousing

-- Standardize Date Format

SELECT SaleDate,
CONVERT(Date,SaleDate)
FROM NashvilleHousing.dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)

-- Delete Unused Columns

SELECT *
FROM NashvilleHousing.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing.dbo.NashvilleHousing
DROP COLUMN Saledate

-- Populate Property Address Data 

SELECT *
FROM NashvilleHousing.dbo.NashvilleHousing
--Where PropertyAddress is null 
ORDER BY ParcelID

SELECT a.ParcelID,
	a.PropertyAddress, 
	b.ParcelID,
	b.PropertyAddress, 
	ISNULL (a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing.dbo.NashvilleHousing a
JOIN NashvilleHousing.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ]<> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL (a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing.dbo.NashvilleHousing a
JOIN NashvilleHousing.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ]<> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- Breaking out Address into Individual Columns (USING SUBSTRING)

SELECT *
FROM NashvilleHousing.dbo.NashvilleHousing

SELECT
SUBSTRING(PropertyAddress,1, CHARINDEX(',', PropertyAddress)-1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, len(PropertyAddress)) AS Address
FROM NashvilleHousing.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, len(PropertyAddress))

-- Breaking out Owner Address into Individual Columns (using PARSENAME)


SELECT OwnerAddress,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM NashvilleHousing.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT(SoldAsVacant), 
	COUNT(SoldAsVacant)
FROM NashvilleHousing.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'YES'
	 WHEN SoldAsVacant = 'N' THEN 'NO'
	 ELSE SoldAsVacant
	 END
FROM NashvilleHousing.dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'YES'
	 WHEN SoldAsVacant = 'N' THEN 'NO'
	 ELSE SoldAsVacant
	 END 

