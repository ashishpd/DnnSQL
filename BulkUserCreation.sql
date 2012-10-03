--Script created by Ash Prasad
--Script can be used to create users in bulk in DotNetNuke
--No license - free to use as you feel :)
--PLEASE DO NOT USE THIS IN PRODUCTION. ONLY MEANT TO BE USED IN TEST ENVIRONMENT

--How it works. Very simple. Reads settings for 'admin' account and simply copies that over to new user
-- Very simple to change though, just change UserToCopy value to something else
--What's going to be the password for new users. Same as that of 'admin'. 
--Replace dnn_ with empty, space or something else if you don't use standard database prefix of 'dnn_' 

--User name will be user1, user2, user3, etc,
--Email will be user1@email.com, user2@email.com
--FirstName will be First1, First2, First3, etc.
--LastName will be Last1, Last2, Last3, etc.
--DisplayName will be First1 Last1, First2, Last2, etc.		

--Tweak with @StartingUserID (default 10) and or @UsersToCreate (default 1000) to change starting userid 
--  and total users to create

DECLARE @UserName nvarchar(100)
DECLARE @Password nvarchar(1000)
DECLARE @Email nvarchar(100)
DECLARE @PasswordSalt nvarchar(1000)
DECLARE @ApplicationId nvarchar(1000)
DECLARE @PortalID INT = 0
DECLARE @RoleID INT
DECLARE @AspUserID UNIQUEIDENTIFIER
DECLARE @CurrentDate AS DATETIME = GETUTCDATE()
DECLARE @FirstName nvarchar(100)
DECLARE @LastName nvarchar(100)
DECLARE @DisplayName nvarchar(100)
DECLARE @UserID INT
DECLARE @Counter INT
DECLARE @StartingUserID INT
DECLARE @UsersToCreate INT
DECLARE @UserSuffix nvarchar(25)
DECLARE @UserToCopy nvarchar(100)

--Feel free to change user from 'admin' to 'something else'
SET @UserToCopy = 'admin'

SELECT  @Password = [Password], @PasswordSalt = PasswordSalt,  @ApplicationId = dbo.aspnet_Membership.ApplicationId FROM dbo.aspnet_Membership
INNER JOIN dbo.aspnet_Users ON dbo.aspnet_Membership.UserId = dbo.aspnet_Users.UserId
WHERE UserName = @UserToCopy

IF @ApplicationId is NULL
	BEGIN
		RAISERROR ('User does not exist', 16, 1);
		return
	END

SELECT  @RoleID = [RoleID] FROM dbo.dnn_Roles WHERE RoleName = 'Registered Users'

SET @StartingUserID = 10 -- bump it to number where you want to start username from 
Set @UsersToCreate = 1000 -- set it number of users you want to create


Set @Counter = 0
WHILE @Counter < @UsersToCreate
BEGIN
	SET @Counter = @Counter + 1
	SET @AspUserID = NEWID()
	SET @UserSuffix = CONVERT(NVARCHAR(25), @StartingUserID + @Counter)
	SET @UserName = 'user' + @UserSuffix
	SET @Email = 'user' + @UserSuffix + '@email.com'
	SET @FirstName = 'First' + @UserSuffix
	SET @LastName = 'Last' + @UserSuffix
	SET @DisplayName = @FirstName + ' ' + @LastName		

	INSERT INTO dbo.aspnet_Users 
			( ApplicationId ,
			  UserId ,
			  UserName ,
			  LoweredUserName ,
			  MobileAlias ,
			  IsAnonymous ,
			  LastActivityDate
			)
	VALUES  ( @ApplicationId , -- ApplicationId - uniqueidentifier
			  @AspUserID , -- UserId - uniqueidentifier
			  @UserName , -- UserName - nvarchar(256)
			  @UserName , -- LoweredUserName - nvarchar(256)
			  NULL , -- MobileAlias - nvarchar(16)
			  0 , -- IsAnonymous - bit
			  @CurrentDate  -- LastActivityDate - datetime
			)

	INSERT INTO dbo.aspnet_Membership
			( ApplicationId ,
			  UserId ,
			  Password ,
			  PasswordFormat ,
			  PasswordSalt ,
			  MobilePIN ,
			  Email ,
			  LoweredEmail ,
			  PasswordQuestion ,
			  PasswordAnswer ,
			  IsApproved ,
			  IsLockedOut ,
			  CreateDate ,
			  LastLoginDate ,
			  LastPasswordChangedDate ,
			  LastLockoutDate ,
			  FailedPasswordAttemptCount ,
			  FailedPasswordAttemptWindowStart ,
			  FailedPasswordAnswerAttemptCount ,
			  FailedPasswordAnswerAttemptWindowStart ,
			  Comment
			)
	VALUES  ( @ApplicationId , -- ApplicationId - uniqueidentifier
			  @AspUserID , -- UserId - uniqueidentifier
			  @Password , -- Password - nvarchar(128)
			  2 , -- PasswordFormat - int
			  @PasswordSalt , -- PasswordSalt - nvarchar(128)
			  NULL , -- MobilePIN - nvarchar(16)
			  @Email , -- Email - nvarchar(256)
			  @Email , -- LoweredEmail - nvarchar(256)
			  NULL , -- PasswordQuestion - nvarchar(256)
			  NULL , -- PasswordAnswer - nvarchar(128)
			  1 , -- IsApproved - bit
			  0 , -- IsLockedOut - bit
			  @CurrentDate , -- CreateDate - datetime
			  @CurrentDate , -- LastLoginDate - datetime
			  @CurrentDate , -- LastPasswordChangedDate - datetime
			  '1754-01-01 00:00:00.000' , -- LastLockoutDate - datetime
			  0 , -- FailedPasswordAttemptCount - int
			  '1754-01-01 00:00:00.000' , -- FailedPasswordAttemptWindowStart - datetime
			  0 , -- FailedPasswordAnswerAttemptCount - int
			  '1754-01-01 00:00:00.000' , -- FailedPasswordAnswerAttemptWindowStart - datetime
			  NULL  -- Comment - ntext
			)

	INSERT INTO dbo.dnn_Users
			( Username ,
			  FirstName ,
			  LastName ,
			  IsSuperUser ,
			  AffiliateId ,
			  Email ,
			  DisplayName ,
			  UpdatePassword ,
			  LastIPAddress ,
			  IsDeleted ,
			  CreatedByUserID ,
			  CreatedOnDate ,
			  LastModifiedByUserID ,
			  LastModifiedOnDate
			)
	VALUES  ( @UserName , -- Username - nvarchar(100)
			  @FirstName , -- FirstName - nvarchar(50)
			  @LastName , -- LastName - nvarchar(50)
			  0 , -- IsSuperUser - bit
			  NULL , -- AffiliateId - int
			  @Email , -- Email - nvarchar(256)
			  @DisplayName , -- DisplayName - nvarchar(128)
			  0 , -- UpdatePassword - bit
			  N'' , -- LastIPAddress - nvarchar(50)
			  0 , -- IsDeleted - bit
			  0 , -- CreatedByUserID - int
			  @CurrentDate , -- CreatedOnDate - datetime
			  0 , -- LastModifiedByUserID - int
			  @CurrentDate  -- LastModifiedOnDate - datetime
			)

	SET @UserID = SCOPE_IDENTITY()

	INSERT INTO dbo.dnn_UserRoles
			( UserID ,
			  RoleID ,
			  ExpiryDate ,
			  IsTrialUsed ,
			  EffectiveDate ,
			  CreatedByUserID ,
			  CreatedOnDate ,
			  LastModifiedByUserID ,
			  LastModifiedOnDate
			)
	VALUES  ( @UserID , -- UserID - int
			  @RoleID , -- RoleID - int
			  NULL , -- ExpiryDate - datetime
			  1 , -- IsTrialUsed - bit
			  NULL , -- EffectiveDate - datetime
			  0 , -- CreatedByUserID - int
			  @CurrentDate , -- CreatedOnDate - datetime
			  0 , -- LastModifiedByUserID - int
			  @CurrentDate  -- LastModifiedOnDate - datetime
			)

	INSERT INTO dbo.dnn_UserPortals
			( UserId ,
			  PortalId ,
			  CreatedDate ,
			  Authorised ,
			  IsDeleted ,
			  RefreshRoles
			)
	VALUES  ( @UserID , -- UserId - int
			  @PortalID , -- PortalId - int
			  @CurrentDate , -- CreatedDate - datetime
			  1 , -- Authorised - bit
			  0 , -- IsDeleted - bit
			  0  -- RefreshRoles - bit
			)
			
		--Create FirstName UserProfile Property
		INSERT INTO dbo.dnn_UserProfile
				( UserID ,
				  PropertyDefinitionID ,
				  PropertyValue ,
				  PropertyText ,
				  Visibility ,
				  LastUpdatedDate ,
				  ExtendedVisibility
				)
		VALUES  ( @UserID , -- UserID - int
				  2 , -- PropertyDefinitionID - int
				  @FirstName , -- PropertyValue - nvarchar(3750)
				  NULL , -- PropertyText - nvarchar(max)
				  0 , -- Visibility - int
				  @CurrentDate , -- LastUpdatedDate - datetime
				  ''  -- ExtendedVisibility - varchar(400)
				)	
				
		--Create LastName UserProfile Property
		INSERT INTO dbo.dnn_UserProfile
				( UserID ,
				  PropertyDefinitionID ,
				  PropertyValue ,
				  PropertyText ,
				  Visibility ,
				  LastUpdatedDate ,
				  ExtendedVisibility
				)
		VALUES  ( @UserID , -- UserID - int
				  4 , -- PropertyDefinitionID - int
				  @LastName , -- PropertyValue - nvarchar(3750)
				  NULL , -- PropertyText - nvarchar(max)
				  0 , -- Visibility - int
				  @CurrentDate , -- LastUpdatedDate - datetime
				  ''  -- ExtendedVisibility - varchar(400)
				)						
END

--Following SQLs can be used to verify new user records
/*
SELECT * FROM dbo.aspnet_Users
SELECT * FROM dbo.aspnet_Membership
SELECT * FROM dbo.dnn_users
SELECT * FROM dbo.dnn_UserRoles
SELECT * FROM dbo.dnn_UserPortals
*/