

CREATE DATABASE BidNile;
GO

USE BidNile;
GO

CREATE SCHEMA Core;
GO

CREATE SCHEMA Operations;
GO

CREATE SCHEMA Catalog;
GO

CREATE SCHEMA Sales;
GO



create table Core.City
(
	Id int identity(1,1)
		constraint PK_City Primary Key,
	
	Name NVARCHAR(60) NOT NULL ,

	CountryCode CHAR(2) NOT NULL,
	

	Constraint UQ_CityName_countryCode 
		UNIQUE (Name,CountryCode),
	
	constraint  CK_City_CountryCode
		CHECK(CountryCode IN ( 'EG' , 'SA', 'AE')) 



);

CREATE TABLE Core.Member
(
	Id UNIQUEIDENTIFIER NOT NULL
		CONSTRAINT PK_Membe PRIMARY KEY
		CONSTRAINT DF_Member_MemberId DEFAULT NEWID(),
	
	FirstName NVARCHAR(100) NOT NULL,

	Email NVARCHAR(254) NOT NULL
		CONSTRAINT UQ_Member_Email UNIQUE ,

	Mobile VARCHAR(16) NOT NULL
		CONSTRAINT CK_Member_Mobile
		CHECK (
			LEN(Mobile) BETWEEN 3 AND 16
			AND Mobile LIKE '+[1-9]%'
			AND SUBSTRING(Mobile, 2, 15)
			NOT LIKE '%[^0-9]%' ),   
	
	IdentifyNumber NVARCHAR(20) NOT NULL
	CONSTRAINT UQ_Member_IdentifyNumber UNIQUE ,

	
    BirthDate DATE NOT NULL
	CONSTRAINT CK_Member_BirthDate_18
			CHECK (
				BirthDate <= DATEADD(YEAR, -18, CAST(GETDATE() AS DATE))
			),

	IsVerified BIT NOT NULL
	CONSTRAINT DF_Member_IsVerified DEFAULT 0,

	RegisterAt	DATETIME2 NOT NULL
	CONSTRAINT DF_Member_RegisterAt DEFAULT SYSDATETIME(),

	CityId INT NOT NULL,

    ReferredByMemberId UNIQUEIDENTIFIER NULL,

    CONSTRAINT CK_Member_BirthDate
        CHECK (BirthDate <= CAST(GETDATE() AS DATE)),

    CONSTRAINT CK_Member_Referral
        CHECK (
            ReferredByMemberId IS NULL
            OR ReferredByMemberId <> Id
        )


		


);


CREATE TABLE Core.Wallet
(
    WalletId INT IDENTITY(1,1)
        CONSTRAINT PK_Wallet PRIMARY KEY,

    MemberId UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT UQ_Wallet_MemberId UNIQUE,

    Balance DECIMAL(12,2) NOT NULL
        CONSTRAINT DF_Wallet_Balance DEFAULT 0,

    HeldAmount DECIMAL(12,2) NOT NULL
        CONSTRAINT DF_Wallet_HeldAmount DEFAULT 0,

    Currency CHAR(3) NOT NULL
        CONSTRAINT DF_Wallet_Currency DEFAULT 'EGP',

    LastUpdated DATETIME2(3) NOT NULL
        CONSTRAINT DF_Wallet_LastUpdated DEFAULT SYSDATETIME(),

    CONSTRAINT CK_Wallet_Balance
        CHECK (Balance >= 0),

    CONSTRAINT CK_Wallet_HeldAmount
        CHECK (HeldAmount >= 0 AND HeldAmount <= Balance)
);



CREATE TABLE Operations.Warehouse
(
    Id INT IDENTITY(1,1)
        CONSTRAINT PK_Warehouse PRIMARY KEY,

    Name NVARCHAR(80) NOT NULL
        CONSTRAINT UQ_Warehouse_Name UNIQUE,

    Capacity INT NOT NULL
        CONSTRAINT CK_Warehouse_Capacity
        CHECK (Capacity > 0),

    CityId INT NOT NULL,

    Latitude FLOAT NOT NULL
        CONSTRAINT CK_Warehouse_Latitude
        CHECK (Latitude BETWEEN -90 AND 90),

    Longitude FLOAT NOT NULL
        CONSTRAINT CK_Warehouse_Longitude
        CHECK (Longitude BETWEEN -180 AND 180),

    ManagerId INT NULL
        CONSTRAINT UQ_Warehouse_ManagerId UNIQUE,

    ManagerStartDate DATE NULL,

    CONSTRAINT CK_Warehouse_ManagerStartDate
        CHECK (
            (ManagerId IS NULL AND ManagerStartDate IS NULL)
            OR
            (ManagerId IS NOT NULL AND ManagerStartDate IS NOT NULL)
        )
);


CREATE TABLE Operations.Employee
(
    EmpId INT IDENTITY(1,1)
        CONSTRAINT PK_Employee PRIMARY KEY,

    MemberId UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT UQ_Employee_MemberId UNIQUE,

    WarehouseId INT NOT NULL
);


CREATE TABLE Catalog.Category
(
    Id INT NOT NULL
        CONSTRAINT PK_Category PRIMARY KEY,

    CategoryCode INT NOT NULL
        CONSTRAINT UQ_Category_CategoryCode UNIQUE,

    NameEn VARCHAR(50) NOT NULL
        CONSTRAINT UQ_Category_NameEn UNIQUE,

    NameAr NVARCHAR(50) NULL,

    CommissionRate DECIMAL(4,2) NOT NULL
        CONSTRAINT CK_Category_CommissionRate
        CHECK (CommissionRate BETWEEN 0 AND 30),

    ParentCategoryId INT NULL
);


CREATE TABLE Catalog.Item
(
    Id INT IDENTITY(1,1)
        CONSTRAINT PK_Item PRIMARY KEY,

    Title NVARCHAR(150) NOT NULL,

    Description NVARCHAR(MAX) NULL,

    ConditionScore TINYINT NOT NULL
        CONSTRAINT CK_Item_ConditionScore
        CHECK (ConditionScore BETWEEN 1 AND 10),

    Specifications NVARCHAR(MAX) NOT NULL
        CONSTRAINT CK_Item_Specifications
        CHECK (ISJSON(Specifications) = 1),

    SellerId UNIQUEIDENTIFIER NOT NULL,

    CategoryId INT NOT NULL,

    WarehouseId INT NULL,

    InspectorMemberId UNIQUEIDENTIFIER NULL,

    ListedAt DATETIME2(3) NOT NULL
        CONSTRAINT DF_Item_ListedAt DEFAULT SYSDATETIME(),

    CONSTRAINT CK_Item_SellerInspector
        CHECK (
            InspectorMemberId IS NULL
            OR SellerId <> InspectorMemberId
        )
);
GO

CREATE TABLE Catalog.ItemPhoto
(
    ItemId INT NOT NULL,

    PhotoPosition TINYINT NOT NULL
        CONSTRAINT CK_ItemPhoto_PhotoPosition
        CHECK(PhotoPosition BETWEEN 1 AND 20),



     PhotoUrl VARCHAR(500) NOT NULL,

    IsMain BIT NOT NULL
        CONSTRAINT DF_ItemPhoto_IsMain DEFAULT 0,



     CONSTRAINT PK_ItemPhoto PRIMARY KEY(ItemId,PhotoPosition)
);



CREATE TABLE Sales.Auction
(
    Id INT IDENTITY(1,1)
        CONSTRAINT PK_Auction PRIMARY KEY,

    ItemId INT NOT NULL,

    StartingPrice DECIMAL(12,2) NOT NULL
        CONSTRAINT CK_Auction_StartingPrice
        CHECK (StartingPrice > 0),

    ReservePrice DECIMAL(12,2) NULL,

    BidIncrement DECIMAL(12,2) NOT NULL
        CONSTRAINT DF_Auction_BidIncrement DEFAULT 50.00
        CONSTRAINT CK_Auction_BidIncrement
        CHECK (BidIncrement > 0),

    StartAt DATETIMEOFFSET NOT NULL,

    EndAt DATETIMEOFFSET NOT NULL,

    Status VARCHAR(20) NOT NULL
        CONSTRAINT DF_Auction_Status DEFAULT 'Draft'
        CONSTRAINT CK_Auction_Status
        CHECK (Status IN (
            'Draft',
            'Live',
            'Ended',
            'Cancelled'
        )),

    CONSTRAINT CK_Auction_ReservePrice
        CHECK (
            ReservePrice IS NULL
            OR ReservePrice >= StartingPrice
        ),

    CONSTRAINT CK_Auction_DateRange
        CHECK (EndAt > StartAt)
);
GO


CREATE TABLE Sales.Bid
(
    Id BIGINT IDENTITY(1,1)
        CONSTRAINT PK_Bid PRIMARY KEY,

    AuctionId INT NOT NULL,

    MemberId UNIQUEIDENTIFIER NOT NULL,

    Amount DECIMAL(12,2) NOT NULL
        CONSTRAINT CK_Bid_Amount
        CHECK (Amount > 0),

    PlacedAt DATETIME2(3) NOT NULL
        CONSTRAINT DF_Bid_PlacedAt DEFAULT SYSDATETIME(),

    IpAddress VARCHAR(45) NOT NULL,

    CONSTRAINT UQ_Bid_AuctionId_Amount
        UNIQUE (AuctionId, Amount)
);
GO



CREATE TABLE Sales.AuctionFollow
(
    Id INT IDENTITY(1,1)
        CONSTRAINT PK_AuctionFollow PRIMARY KEY,

    MemberId UNIQUEIDENTIFIER NOT NULL,

    AuctionId INT NOT NULL,

    FollowedAt DATETIME2(3) NOT NULL
        CONSTRAINT DF_AuctionFollow_FollowedAt
        DEFAULT SYSDATETIME(),

    CONSTRAINT UQ_AuctionFollow_Member_Auction
        UNIQUE (MemberId, AuctionId)
);
GO

-- 3.1 Core Foreign Keys

ALTER TABLE Core.Member 
    ADD CONSTRAINT FK_Member_City
    foreign key(CityId)
    references Core.City(Id)


ALTER TABLE Core.Member 
    ADD CONSTRAINT FK_Member_Referrer
    Foreign key(ReferredByMemberId)
    references Core.Member(Id)


ALTER TABLE Core.Wallet
    ADD CONSTRAINT FK_Wallet_Member
    foreign key(MemberId)
    references Core.Member(Id)



-- 3.1 Operations Foreign Keys

ALTER TABLE Operations.Warehouse
ADD CONSTRAINT FK_Warehouse_City
FOREIGN KEY (CityId)
REFERENCES Core.City(Id);
GO

ALTER TABLE Operations.Employee
ADD CONSTRAINT FK_Employee_Member
FOREIGN KEY (MemberId)
REFERENCES Core.Member(Id);
GO

ALTER TABLE Operations.Employee
ADD CONSTRAINT FK_Employee_Warehouse
FOREIGN KEY (WarehouseId)
REFERENCES Operations.Warehouse(Id);
GO

ALTER TABLE Operations.Warehouse
ADD CONSTRAINT FK_Warehouse_Employee
FOREIGN KEY (ManagerId)
REFERENCES Operations.Employee(EmpId);
GO





-- 3.1 Catalog Foreign Keys

ALTER TABLE Catalog.Category
ADD CONSTRAINT FK_Category_Parent
FOREIGN KEY (ParentCategoryId)
REFERENCES Catalog.Category(Id);
GO

ALTER TABLE Catalog.Item
ADD CONSTRAINT FK_Item_Member
FOREIGN KEY (SellerId)
REFERENCES Core.Member(Id);
GO

ALTER TABLE Catalog.Item
ADD CONSTRAINT FK_Item_Category
FOREIGN KEY (CategoryId)
REFERENCES Catalog.Category(Id);
GO

ALTER TABLE Catalog.Item
ADD CONSTRAINT FK_Item_Warehouse
FOREIGN KEY (WarehouseId)
REFERENCES Operations.Warehouse(Id);
GO

ALTER TABLE Catalog.Item
ADD CONSTRAINT FK_Item_Inspector
FOREIGN KEY (InspectorMemberId)
REFERENCES Operations.Employee(MemberId);
GO

ALTER TABLE Catalog.ItemPhoto
ADD CONSTRAINT FK_ItemPhoto_Item
FOREIGN KEY (ItemId)
REFERENCES Catalog.Item(Id)
ON DELETE CASCADE;
GO



-- 3.1 Sales Foreign Keys

ALTER TABLE Sales.Auction
ADD CONSTRAINT FK_Auction_Item
FOREIGN KEY (ItemId)
REFERENCES Catalog.Item(Id);
GO

ALTER TABLE Sales.Bid
ADD CONSTRAINT FK_Bid_Auction
FOREIGN KEY (AuctionId)
REFERENCES Sales.Auction(Id);
GO

ALTER TABLE Sales.Bid
ADD CONSTRAINT FK_Bid_Member
FOREIGN KEY (MemberId)
REFERENCES Core.Member(Id);
GO

ALTER TABLE Sales.AuctionFollow
ADD CONSTRAINT FK_AuctionFollow_Member
FOREIGN KEY (MemberId)
REFERENCES Core.Member(Id);
GO

ALTER TABLE Sales.AuctionFollow
ADD CONSTRAINT FK_AuctionFollow_Auction
FOREIGN KEY (AuctionId)
REFERENCES Sales.Auction(Id);
GO

-- task 3.2

ALTER TABLE  Core.Member
    ADD  AppLanguage CHAR(2) NOT NULL
    CONSTRAINT DF_Member_AppLanguage DEFAULT 'ar'
    CONSTRAINT CK_Member_AppLanguage
    CHECK (AppLanguage IN ('ar', 'en'));

--task 3.3

ALTER TABLE [Catalog].[Item]
    ADD IsFeatured BIT NOT NULL
    CONSTRAINT DF_Item_IsFeatured DEFAULT 0

--TASK 3.4
EXEC sp_rename
'[Sales].[Bid].[IpAddress]',
'DeviceIp',
'COLUMN';


ALTER TABLE Operations.Warehouse
DROP CONSTRAINT CK_Warehouse_Capacity;
GO

EXEC sp_rename
'[Operations].[Warehouse].[Capacity]',
'MaxItems',
'COLUMN'

 GO  
 
ALTER TABLE Operations.Warehouse
WITH CHECK ADD CONSTRAINT CK_Warehouse_MaxItems
CHECK (MaxItems > 0);
GO



-- 3.5 Increase Member FullName length

ALTER TABLE Core.Member
ALTER COLUMN FullName NVARCHAR(150) NOT NULL;
GO

--3.6 Task
ALTER TABLE [Operations].[Warehouse]
DROP CONSTRAINT [CK_Warehouse_MaxItems]
GO

ALTER TABLE [Operations].[Warehouse]
  ALTER COLUMN [MaxItems] SMALLINT NOT NULL

  ALTER TABLE [Operations].[Warehouse]
    ADD CONSTRAINT [CK_Warehouse_MaxItems] 
    CHECK (MaxItems > 0 AND MaxItems <= 30000);
    GO

--3.7
ALTER TABLE [Catalog].[Category]
    DROP CONSTRAINT [CK_Category_CommissionRate]
GO
ALTER TABLE [Catalog].[Category]
    ADD CONSTRAINT [CK_Category_CommissionRate]
    CHECK (CommissionRate BETWEEN 0 AND 25)

--3.8
ALTER TABLE Sales.Auction
DROP CONSTRAINT CK_Auction_Status;

ALTER TABLE Sales.Auction
DROP CONSTRAINT DF_Auction_Status;

ALTER TABLE Sales.Auction
WITH CHECK ADD CONSTRAINT CK_Auction_Status
CHECK (
    Status IN (
        'Draft',
        'Live',
        'Ended',
        'Cancelled',
        'PendingReview'
    )
);


ALTER TABLE Sales.Auction
ADD CONSTRAINT DF_Auction_Status
DEFAULT 'PendingReview' FOR Status;


--3.9
ALTER TABLE [Sales].[Auction]
 ADD BuyNowPrice DECIMAL(12,2) NULL

 GO
 ALTER TABLE [Sales].[Auction]
ADD CONSTRAINT CK_BuyNowPrice_Auction 
 CHECK(BuyNowPrice>StartingPrice)


--WITH CHECK validates existing rows
-- NOCHECK is unnecessary because existing rows have NULL BuyNowPrice

--3.10
ALTER TABLE [Core].[Member]
ADD CONSTRAINT UQ_Mobile_Member
UNIQUE(Mobile)


--3.11
ALTER TABLE [Core].[Member]
    ADD VerifiedAt DateTime2(2) NULL
    

ALTER TABLE Core.Member
DROP CONSTRAINT DF_Member_IsVerified;
GO

ALTER TABLE Core.Member
DROP COLUMN IsVerified;
GO



--3.12
CREATE SCHEMA Marketing 
Go

ALTER SCHEMA Marketing
    TRANSFER [Sales].[AuctionFollow]

