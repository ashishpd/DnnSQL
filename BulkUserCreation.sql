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

/** BEGIN Configuration **/
DECLARE @UserToCopy NVARCHAR(100)
DECLARE @RoleMemberships NVARCHAR(1000)
DECLARE @StartingUserID INT
DECLARE @UsersToCreate INT

DECLARE @PortalID INT = 0

--Feel free to change user from 'admin' to 'something else'
SET @UserToCopy = 'testuser'

-- RoleMemberships to add to user. No need to add "Registered Users" as this will always be added. 
-- Can be left empty for no extra role memberships
SET @RoleMemberships = 'Testrole1,Testrole2'

-- bump it to number where you want to start username from 
SET @StartingUserID = 100000

-- set it number of users you want to create
SET @UsersToCreate = 350000
/** END Configuration **/


DECLARE @UserName NVARCHAR(100)
DECLARE @Password NVARCHAR(1000)
DECLARE @Email NVARCHAR(100)
DECLARE @PasswordSalt NVARCHAR(1000)
DECLARE @ApplicationId NVARCHAR(1000)
DECLARE @RoleID INT
DECLARE @AspUserID UNIQUEIDENTIFIER
DECLARE @CurrentDate AS DATETIME = GETUTCDATE()
DECLARE @FirstName NVARCHAR(100)
DECLARE @LastName NVARCHAR(100)
DECLARE @DisplayName NVARCHAR(100)
DECLARE @UserID INT
DECLARE @Counter INT
DECLARE @UserSuffix NVARCHAR(25)
DECLARE @UserIdCopy INT
DECLARE @ProfileProperty_FirstName INT
DECLARE @ProfileProperty_LastName INT
DECLARE @ProfileProperty_PreferredTimeZone INT
DECLARE @ProfileProperty_PreferredLocale INT
DECLARE @PreferredTimezone NVARCHAR(100)
DECLARE @PreferredLocale NVARCHAR(10)
DECLARE @RoleMembershipsCopy NVARCHAR(1000)
DECLARE @SingleRole NVARCHAR(100)
DECLARE @NewRoleID INT

SELECT  @ProfileProperty_FirstName = PropertyDefinitionId
FROM    dbo.dnn_ProfilePropertyDefinition
WHERE   PortalID = @PortalID
        AND PropertyName = 'FirstName'
SELECT  @ProfileProperty_LastName = PropertyDefinitionId
FROM    dbo.dnn_ProfilePropertyDefinition
WHERE   PortalID = @PortalID
        AND PropertyName = 'LastName'
SELECT  @ProfileProperty_PreferredTimeZone = PropertyDefinitionId
FROM    dbo.dnn_ProfilePropertyDefinition
WHERE   PortalID = @PortalID
        AND PropertyName = 'PreferredTimeZone'
SELECT  @ProfileProperty_PreferredLocale = PropertyDefinitionId
FROM    dbo.dnn_ProfilePropertyDefinition
WHERE   PortalID = @PortalID
        AND PropertyName = 'PreferredLocale'
		
SELECT  @Password = [Password] ,
        @PasswordSalt = PasswordSalt ,
        @ApplicationId = dbo.aspnet_Membership.ApplicationId
FROM    dbo.aspnet_Membership
        INNER JOIN dbo.aspnet_Users ON dbo.aspnet_Membership.UserId = dbo.aspnet_Users.UserId
WHERE   UserName = @UserToCopy

SELECT  @UserIdCopy = UserID
FROM    dbo.dnn_Users
WHERE   Username = @UserToCopy

SELECT  @PreferredTimezone = PropertyValue
FROM    dbo.dnn_UserProfile
WHERE   PropertyDefinitionID = @ProfileProperty_PreferredTimeZone
        AND UserID = @UserIdCopy
SELECT  @PreferredLocale = PropertyValue
FROM    dbo.dnn_UserProfile
WHERE   PropertyDefinitionID = @ProfileProperty_PreferredLocale
        AND UserID = @UserIdCopy

IF @ApplicationId IS NULL 
    BEGIN
        RAISERROR ('User does not exist', 16, 1);
        RETURN
    END

SELECT  @RoleID = [RoleID]
FROM    dbo.dnn_Roles
WHERE   RoleName = 'Registered Users'
	    AND PortalID = @PortalID

SET @Counter = 0
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

        INSERT  INTO dbo.aspnet_Users
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

        INSERT  INTO dbo.aspnet_Membership
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

        INSERT  INTO dbo.dnn_Users
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

        INSERT  INTO dbo.dnn_UserRoles
                ( UserID ,
                  RoleID ,
                  ExpiryDate ,
                  IsTrialUsed ,
                  EffectiveDate ,
                  CreatedByUserID ,
                  CreatedOnDate ,
                  LastModifiedByUserID ,
                  LastModifiedOnDate,
				  Status,
				  IsOwner
			    )
        VALUES  ( @UserID , -- UserID - int
                  @RoleID , -- RoleID - int
                  NULL , -- ExpiryDate - datetime
                  1 , -- IsTrialUsed - bit
                  NULL , -- EffectiveDate - datetime
                  0 , -- CreatedByUserID - int
                  @CurrentDate , -- CreatedOnDate - datetime
                  0 , -- LastModifiedByUserID - int
                  @CurrentDate,  -- LastModifiedOnDate - datetime
				  1,
				  0
			    )

        INSERT  INTO dbo.dnn_UserPortals
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
        INSERT  INTO dbo.dnn_UserProfile
                ( UserID ,
                  PropertyDefinitionID ,
                  PropertyValue ,
                  PropertyText ,
                  Visibility ,
                  LastUpdatedDate ,
                  ExtendedVisibility
				)
        VALUES  ( @UserID , -- UserID - int
                  @ProfileProperty_FirstName , -- PropertyDefinitionID - int
                  @FirstName , -- PropertyValue - nvarchar(3750)
                  NULL , -- PropertyText - nvarchar(max)
                  0 , -- Visibility - int
                  @CurrentDate , -- LastUpdatedDate - datetime
                  ''  -- ExtendedVisibility - varchar(400)
				)	

		--Create LastName UserProfile Property
        INSERT  INTO dbo.dnn_UserProfile
                ( UserID ,
                  PropertyDefinitionID ,
                  PropertyValue ,
                  PropertyText ,
                  Visibility ,
                  LastUpdatedDate ,
                  ExtendedVisibility
				)
        VALUES  ( @UserID , -- UserID - int
                  @ProfileProperty_LastName , -- PropertyDefinitionID - int
                  @LastName , -- PropertyValue - nvarchar(3750)
                  NULL , -- PropertyText - nvarchar(max)
                  0 , -- Visibility - int
                  @CurrentDate , -- LastUpdatedDate - datetime
                  ''  -- ExtendedVisibility - varchar(400)
				)	
		
		--Create PreferredTimeZone UserProfile Property
        INSERT  INTO dbo.dnn_UserProfile
                ( UserID ,
                  PropertyDefinitionID ,
                  PropertyValue ,
                  PropertyText ,
                  Visibility ,
                  LastUpdatedDate ,
                  ExtendedVisibility
				)
        VALUES  ( @UserID , -- UserID - int
                  @ProfileProperty_PreferredTimeZone , -- PropertyDefinitionID - int
                  @PreferredTimezone , -- PropertyValue - nvarchar(3750)
                  NULL , -- PropertyText - nvarchar(max)
                  0 , -- Visibility - int
                  @CurrentDate , -- LastUpdatedDate - datetime
                  ''  -- ExtendedVisibility - varchar(400)
				)	
		
		--Create LastName UserProfile Property
        INSERT  INTO dbo.dnn_UserProfile
                ( UserID ,
                  PropertyDefinitionID ,
                  PropertyValue ,
                  PropertyText ,
                  Visibility ,
                  LastUpdatedDate ,
                  ExtendedVisibility
				)
        VALUES  ( @UserID , -- UserID - int
                  @ProfileProperty_PreferredLocale , -- PropertyDefinitionID - int
                  @PreferredLocale , -- PropertyValue - nvarchar(3750)
                  NULL , -- PropertyText - nvarchar(max)
                  0 , -- Visibility - int
                  @CurrentDate , -- LastUpdatedDate - datetime
                  ''  -- ExtendedVisibility - varchar(400)
				)	
	
	-- create and add to roles
        SET @RoleMembershipsCopy = @RoleMemberships
        WHILE LEN(@RoleMembershipsCopy) > 0 
            BEGIN
  
				-- parse roles create          
                IF PATINDEX('%,%', @RoleMembershipsCopy) > 0 
                    BEGIN
                        SET @SingleRole = SUBSTRING(@RoleMembershipsCopy, 0,
                                                    PATINDEX('%,%',
                                                             @RoleMembershipsCopy))
                        --SELECT  @SingleRole

                        SET @RoleMembershipsCopy = SUBSTRING(@RoleMembershipsCopy,
                                                             LEN(@SingleRole
                                                              + ',') + 1,
                                                             LEN(@RoleMembershipsCopy))
                    END
                ELSE 
                    BEGIN
                        SET @SingleRole = @RoleMembershipsCopy
                        SET @RoleMembershipsCopy = NULL
                        --SELECT  @SingleRole
                    END
                SET @SingleRole = LTRIM(RTRIM(@SingleRole))

				-- create roles if necessary
                IF NOT EXISTS ( SELECT  *
                                FROM    dbo.dnn_Roles
                                WHERE   ( PortalID = @PortalID )
                                        AND ( RoleName = @SingleRole ) ) 
                    BEGIN
                        INSERT  INTO [dbo].[dnn_Roles]
                                ( [PortalID] ,
                                  [RoleName] ,
                                  [IsPublic] ,
                                  [AutoAssignment] ,
                                  [CreatedByUserID] ,
                                  [CreatedOnDate] ,
                                  [LastModifiedByUserID] ,
                                  [LastModifiedOnDate] ,
                                  [Status] ,
                                  [SecurityMode] ,
                                  [IsSystemRole]
                                )
                        VALUES  ( @PortalID ,
                                  @SingleRole ,
                                  0 ,
                                  0 ,
                                  -1 ,
                                  @CurrentDate ,
                                  -1 ,
                                  @CurrentDate ,
                                  1 ,
                                  0 ,
                                  0 
                                )
                        SELECT  @NewRoleID = SCOPE_IDENTITY()
                    END
                ELSE 
                    BEGIN
                        SELECT  @NewRoleID = RoleID
                        FROM    dnn_Roles
                        WHERE   ( PortalID = @PortalID )
                                AND ( RoleName = @SingleRole ) 
                    END 

                INSERT  INTO dbo.dnn_UserRoles
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
                          @NewRoleID , -- RoleID - int
                          NULL , -- ExpiryDate - datetime
                          1 , -- IsTrialUsed - bit
                          NULL , -- EffectiveDate - datetime
                          0 , -- CreatedByUserID - int
                          @CurrentDate , -- CreatedOnDate - datetime
                          0 , -- LastModifiedByUserID - int
                          @CurrentDate  -- LastModifiedOnDate - datetime
			            )
				
				        
            END --WHILE LEN(@RoleMembershipsCopy) > 0 
	
									
    END

--Following SQLs can be used to verify new user records
/*
SELECT * FROM dbo.aspnet_Users
SELECT * FROM dbo.aspnet_Membership
SELECT * FROM dbo.dnn_users
SELECT * FROM dbo.dnn_UserRoles
SELECT * FROM dbo.dnn_UserPortals
*/
