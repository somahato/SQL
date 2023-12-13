USE [OperationsManager] 
GO 
SET ANSI_NULLS ON 
GO 
SET QUOTED_IDENTIFIER ON 
GO 
BEGIN
SET NOCOUNT ON
DECLARE @Err int 
DECLARE @Ret int 
DECLARE @DaysToKeep tinyint 
DECLARE @GroomingThresholdLocal datetime 
DECLARE @GroomingThresholdUTC datetime 
DECLARE @TimeGroomingRan datetime 
DECLARE @MaxTimeGroomed datetime 
DECLARE @RowCount int 
SET @TimeGroomingRan = getutcdate()
SELECT @GroomingThresholdLocal = dbo.fn_GroomingThreshold(DaysToKeep, getdate()) 
FROM dbo.PartitionAndGroomingSettings 
WHERE ObjectName = 'StateChangeEvent'
EXEC dbo.p_ConvertLocalTimeToUTC @GroomingThresholdLocal, @GroomingThresholdUTC OUT 
SET @Err = @@ERROR
IF (@Err <> 0) 
BEGIN 
GOTO Error_Exit 
END
SET @RowCount = 1 
-- This is to update the settings table 
-- with the max groomed data 
SELECT @MaxTimeGroomed = MAX(TimeGenerated) 
FROM dbo.StateChangeEvent 
WHERE TimeGenerated < @GroomingThresholdUTC
IF @MaxTimeGroomed IS NULL 
GOTO Success_Exit
-- Instead of the FK DELETE CASCADE handling the deletion of the rows from 
-- the MJS table, do it explicitly. Performance is much better this way. 
DELETE MJS 
FROM dbo.MonitoringJobStatus MJS 
JOIN dbo.StateChangeEvent SCE 
ON SCE.StateChangeEventId = MJS.StateChangeEventId 
JOIN dbo.State S WITH(NOLOCK) 
ON SCE.[StateId] = S.[StateId] 
WHERE SCE.TimeGenerated < @GroomingThresholdUTC 
AND S.[HealthState] in (0,1,2,3)
SELECT @Err = @@ERROR 
IF (@Err <> 0) 
BEGIN 
GOTO Error_Exit 
END
WHILE (@RowCount > 0) 
BEGIN 
-- Delete StateChangeEvents that are older than @GroomingThresholdUTC 
-- We are doing this in chunks in separate transactions on 
-- purpose: to avoid the transaction log to grow too large. 
DELETE TOP (10000) SCE 
FROM dbo.StateChangeEvent SCE 
JOIN dbo.State S WITH(NOLOCK) 
ON SCE.[StateId] = S.[StateId] 
WHERE TimeGenerated < @GroomingThresholdUTC 
AND S.[HealthState] in (0,1,2,3)
SELECT @Err = @@ERROR, @RowCount = @@ROWCOUNT
IF (@Err <> 0) 
BEGIN 
GOTO Error_Exit 
END 
END 
UPDATE dbo.PartitionAndGroomingSettings 
SET GroomingRunTime = @TimeGroomingRan, 
DataGroomedMaxTime = @MaxTimeGroomed 
WHERE ObjectName = 'StateChangeEvent'
SELECT @Err = @@ERROR, @RowCount = @@ROWCOUNT
IF (@Err <> 0) 
BEGIN 
GOTO Error_Exit 
END 
Success_Exit: 
Error_Exit: 
END
