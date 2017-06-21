-- lock table

CREATE TABLE [Web].[LockInfo]
(
  [LockInfoId] [int] IDENTITY(1,1) NOT NULL, 
  [LockName] [nvarchar](256) NULL, 
  [DurationInSeconds] [int] NULL, 
  [CreatedOn] [datetime] NOT NULL, 
  CONSTRAINT [PK_LockInfoId] PRIMARY KEY CLUSTERED 
  ( 
    [LockInfoId] ASC
  )
  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, 
  IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) 
  ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [Web].[LockInfo] ADD  DEFAULT ((60)) FOR [DurationInSeconds]

-- stored procedure

CREATE Procedure [Web].[usp_Lock] 
  (@Lock BIT, @LockName NVARCHAR(256), @LockDuration INT = NULL) 
  AS 
    BEGIN SET TRANSACTION ISOLATION LEVEL SERIALIZABLE 
    BEGIN TRY 
      BEGIN TRANSACTION 

      DECLARE @Success AS BIT 
      SET @Success = 0

      IF(@Lock IS NULL OR @LockName IS NULL) 
      BEGIN  
        SELECT @Success AS Success; 
        ROLLBACK TRANSACTION
        RETURN; 
      END 

      IF(@Lock = 1) -- LOCK
      BEGIN 
        DELETE FROM [Web].[LockInfo] 
        WHERE @LockName = [LockName] AND 
        DATEADD(SECOND, [DurationInSeconds], [CreatedOn]) < GETUTCDATE();

        IF NOT EXISTS (
                       SELECT * FROM [Web].[LockInfo] 
                       WHERE @LockName = [LockName]) 
        BEGIN 
          IF(@LockDuration IS NULL) 
            INSERT INTO [Web].[LockInfo]  
            ([LockName], [CreatedOn]) 
            VALUES(@LockName, GETUTCDATE()) 
          ELSE 
            INSERT INTO [Web].[LockInfo]  
            ([LockName], [DurationInSeconds], [CreatedOn]) 
            VALUES(@LockName, @LockDuration, GETUTCDATE())
          
          SET @Success = 1 
        END 
      END 
      
      ELSE -- UNLOCK
      BEGIN 
        DELETE FROM [Web].[LockInfo] 
        WHERE @LockName = [LockName] 
        SET @Success = 1 
      END 
      
      COMMIT TRANSACTION 
    END TRY
  
    BEGIN CATCH 
      SET @Success = 0 
      IF(@@TRANCOUNT > 0) 
        ROLLBACK TRANSACTION
    END CATCH;
 
    SELECT @Success AS Success; 
  END
