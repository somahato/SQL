Declare @Start DateTime
Declare @EndTime DateTime
Declare @Object uniqueidentifier

Set @Start = GETUTCDATE()
Set @EndTime = DATEADD(HH,1,GETUTCDATE())
Set @Object = (Select BaseManagedEntityId From BaseManagedEntity Where FullName like 'Microsoft.Windows.Computer:ServerNamewithFQDN')
exec dbo.p_MaintenanceModeStart @BaseManagedEntityId=@Object,@StartTime=@Start,@ScheduledEndTime=@EndTime,@ReasonCode=1,@Comments=N'Using SQL script',@User=N'LAB\sourav',@Recursive=1
