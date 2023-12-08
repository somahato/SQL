DECLARE @ObjectLists TABLE (ManagedEntityRowId INT)
DECLARE @Error INT
Declare @DateFrom  DATETIME,
	@DateTo DATETIME,
	@ForecastDays INT,
	@ObjectList XML
DECLARE @dbEngineTypeGuid UNIQUEIDENTIFIER, @dbFileTypeGuid UNIQUEIDENTIFIER;
DECLARE @interval INT

Set @DateFrom = '2023-11-26 14:32:00'
Set @DateTo='2023-12-09 14:32:00'
Set @ForecastDays=1
Set @ObjectList=N'<Data><Objects><Object Use="Containment">244</Object></Objects></Data>'

	SELECT 
		@dbEngineTypeGuid = CASE WHEN met.ManagedEntityTypeSystemName = 'Microsoft.SQLServer.Windows.DBEngine' THEN met.ManagedEntityTypeGuid ELSE @dbEngineTypeGuid END
		,@dbFileTypeGuid = CASE WHEN met.ManagedEntityTypeSystemName = 'Microsoft.SQLServer.Windows.DBFile' THEN met.ManagedEntityTypeGuid ELSE @dbFileTypeGuid END
	FROM ManagedEntityType met
	WHERE met.ManagedEntityTypeSystemName IN ('Microsoft.SQLServer.Windows.DBEngine', 'Microsoft.SQLServer.Windows.DBFile')

DECLARE @begintime DATETIME = GETUTCDATE(),
			@endtime DATETIME = GETUTCDATE();


DECLARE @InstanceLists TABLE (ManagementGroupId INT NOT NULL
		,MachineId INT NOT NULL
		,InstanceId INT NOT NULL
		,ManagementGroupName NVARCHAR(256)
		,MachineName NVARCHAR(256)
		,InstanceName NVARCHAR(256))

DECLARE @DbFiles TABLE (MachineId INT
		,InstanceId INT
		,ManagedEntityTypeRowId INT
		,BaseManagedEntityTypeRowId INT
		,ManagedEntityRowId INT)

DECLARE @RawResults TABLE (MachineId INT
		,InstanceId INT
		,ManagedEntityRowId INT
		,FilePath NVARCHAR(MAX)
		,ValueTime DATETIME
		,FreeSpaceInFileMBAverage FLOAT
		,FreeSpaceInFilePercentAverage FLOAT
		,FreeSpacePlusAutoGrowthMBAverage FLOAT
		,FreeSpacePlusAutoGrowthPercentAverage FLOAT
		,FileSize FLOAT)

DECLARE @ReportResults Table (
		RecordType INT
		,RowNum BIGINT
		,MachineId INT NOT NULL
		,InstanceId INT NOT NULL
		,ManagedEntityRowId INT
		,FilePath NVARCHAR(MAX)
		,ValueTime DATETIME
		,FileSizeBegin FLOAT
		,FileSizeEnd FLOAT
		,FileSizeForecast FLOAT
		,FreePercentBeginning FLOAT
		,FreePercentEnd FLOAT
	)


--Exec [Microsoft_SystemCenter_DataWarehouse_Report_Library_ReportObjectListParse]
--		@ObjectList = @ObjectList,
--		@StartDate = @DateFrom,
--		@EndDate = @DateTo;

	INSERT INTO @ObjectLists (ManagedEntityRowId)
	EXECUTE @Error = [Microsoft_SystemCenter_DataWarehouse_Report_Library_ReportObjectListParse]
		@ObjectList = @ObjectList,
		@StartDate = @DateFrom,
		@EndDate = @DateTo;

		--Select * from @ObjectLists

	;WITH entities AS(
	SELECT DISTINCT
		mg.ManagementGroupRowId AS ManagementGroupId
		,me.ManagedEntityTypeRowId AS ManagedEntityTypeRowId
		,me.ManagedEntityRowId AS ManagedEntityRowId
		,metmpv.BaseManagedEntityTypeRowId
	FROM ManagedEntityType met
		INNER JOIN ManagedEntityTypeManagementPackVersion metmpv ON met.ManagedEntityTypeRowId = metmpv.ManagedEntityTypeRowId
		INNER JOIN ManagementPackVersion mpv ON metmpv.ManagementPackVersionRowId = mpv.ManagementPackVersionRowId
		INNER JOIN ManagementGroupManagementPackVersion mgmpv ON mgmpv.ManagementPackVersionRowId = mpv.ManagementPackVersionRowId
		INNER JOIN ManagementGroup mg ON mg.ManagementGroupRowId = mgmpv.ManagementGroupRowId
		INNER JOIN ManagedEntity me ON me.ManagedEntityTypeRowId = met.ManagedEntityTypeRowId AND me.ManagementGroupRowId = mg.ManagementGroupRowId
		INNER JOIN ManagedEntityManagementGroup memg ON me.ManagedEntityRowId = memg.ManagedEntityRowId
		--where in scope
		INNER JOIN @ObjectLists as Ob ON me.ManagedEntityRowId = Ob.ManagedEntityRowId
	WHERE met.ManagedEntityTypeGuid = @dbEngineTypeGuid
		-- we need more checks here to get data for exact moment in time -- we need to test it carefully (re-discovery scenarios)
		AND (memg.ToDateTime IS NULL OR memg.ToDateTime > @DateFrom) AND memg.FromDateTime < @DateTo
		AND (mgmpv.DeletedDateTime IS NULL OR mgmpv.DeletedDateTime > @DateFrom) AND mgmpv.InstalledDateTime < @DateTo
	),
	propertiesRaw AS(
		SELECT
			me.ManagementGroupId
			,me.ManagedEntityRowId
			,me.BaseManagedEntityTypeRowId
			,CASE WHEN (metp.PropertySystemName = 'MachineName') THEN UPPER(ParamValues.x.value('.', 'nvarchar(max)')) ELSE NULL END AS MachineName
			,CASE WHEN (metp.PropertySystemName = 'InstanceName') THEN UPPER(ParamValues.x.value('.', 'nvarchar(max)')) ELSE NULL END AS InstanceName
		FROM entities me
			INNER JOIN ManagedEntityType met_base ON me.BaseManagedEntityTypeRowId = met_base.ManagedEntityTypeRowId
			INNER JOIN ManagedEntityTypeProperty metp ON met_base.ManagedEntityTypeRowId = metp.ManagedEntityTypeRowId
			INNER JOIN ManagedEntityProperty mep ON me.ManagedEntityRowId = mep.ManagedEntityRowId
			CROSS APPLY mep.PropertyXml.nodes('/Root/Property') AS ParamValues(x)
		WHERE
			-- we need more checks here to get data for exact moment in time
			(mep.ToDateTime IS NULL OR mep.ToDateTime > @DateFrom) AND mep.FromDateTime < @DateTo
			AND metp.PropertySystemName IN ('MachineName', 'InstanceName')
			AND x.value('@Guid', 'uniqueidentifier') = metp.PropertyGuid
	),
	propertiesGrouped AS (
		SELECT
			MAX(me.ManagementGroupId) AS ManagementGroupId
			,me.ManagedEntityRowId AS InstanceId
			,MAX(me.MachineName) AS  MachineName
			,MAX(me.InstanceName) AS InstanceName
		FROM propertiesRaw me
		GROUP BY me.ManagedEntityRowId
	),
	MachineIds AS(
		SELECT
			ManagementGroupId
			,MachineName
			,ROW_NUMBER() OVER (ORDER BY MachineName, ManagementGroupId) AS MachineId
		FROM propertiesGrouped
		GROUP BY MachineName, ManagementGroupId
	)
	INSERT INTO @InstanceLists(ManagementGroupId,MachineId,InstanceId,ManagementGroupName,MachineName,InstanceName)
	SELECT
		pg.ManagementGroupId
		,mi.MachineId
		,pg.InstanceId
		,mg.ManagementGroupDefaultName
		,pg.MachineName
		,pg.InstanceName
	FROM propertiesGrouped pg
		INNER JOIN MachineIds mi ON pg.MachineName = mi.MachineName AND pg.ManagementGroupId = mi.ManagementGroupId
		INNER JOIN ManagementGroup mg ON pg.ManagementGroupId = mg.ManagementGroupRowId;

--PRINT '== Checking of @InstanceLists '

		--Select * from @InstanceLists
	
	INSERT INTO @DbFiles
	SELECT DISTINCT
		il.MachineId
		,il.InstanceId
		,me.ManagedEntityTypeRowId AS ManagedEntityTypeRowId
		,metmpv2.BaseManagedEntityTypeRowId AS BaseManagedEntityTypeRowId
		,me.ManagedEntityRowId AS ManagedEntityRowId
	FROM ManagedEntityType met
		INNER JOIN ManagedEntityTypeManagementPackVersion metmpv ON met.ManagedEntityTypeRowId = metmpv.ManagedEntityTypeRowId
		INNER JOIN ManagementPackVersion mpv ON metmpv.ManagementPackVersionRowId = mpv.ManagementPackVersionRowId
		INNER JOIN ManagementGroupManagementPackVersion mgmpv ON mgmpv.ManagementPackVersionRowId = mpv.ManagementPackVersionRowId
		INNER JOIN ManagedEntityTypeManagementPackVersion metmpv2 ON metmpv.BaseManagedEntityTypeRowId = metmpv2.ManagedEntityTypeRowId
		INNER JOIN ManagementGroup mg ON mg.ManagementGroupRowId = mgmpv.ManagementGroupRowId
		INNER JOIN ManagedEntity me ON me.ManagedEntityTypeRowId = met.ManagedEntityTypeRowId
		INNER JOIN ManagedEntityManagementGroup memg ON me.ManagedEntityRowId = memg.ManagedEntityRowId
		INNER JOIN @InstanceLists il ON me.TopLevelHostManagedEntityRowId = il.InstanceId
	WHERE met.ManagedEntityTypeGuid = @dbFileTypeGuid
		-- we need more checks here to get data for exact moment in time -- we need to test it carefully (re-discovery scenarios)
		AND (memg.ToDateTime IS NULL OR memg.ToDateTime > @DateFrom) AND memg.FromDateTime < @DateTo
		AND (mgmpv.DeletedDateTime IS NULL OR mgmpv.DeletedDateTime > @DateFrom) AND mgmpv.InstalledDateTime < @DateTo;

	;WITH files AS (
		SELECT
			me.MachineId
			,me.InstanceId
			,me.ManagedEntityTypeRowId
			,me.ManagedEntityRowId
			,CASE WHEN (metp.PropertySystemName = 'FilePath') THEN ParamValues.x.value('.', 'nvarchar(max)') ELSE NULL END AS FilePath
		FROM @DbFiles me
			INNER JOIN ManagedEntityType met_base ON me.BaseManagedEntityTypeRowId = met_base.ManagedEntityTypeRowId
			INNER JOIN ManagedEntityTypeProperty metp ON met_base.ManagedEntityTypeRowId = metp.ManagedEntityTypeRowId
			INNER JOIN ManagedEntityProperty mep ON me.ManagedEntityRowId = mep.ManagedEntityRowId
			CROSS APPLY mep.PropertyXml.nodes('/Root/Property') AS ParamValues(x)
		WHERE 
			-- we need more checks here to get data for exact moment in time
			(mep.ToDateTime IS NULL OR mep.ToDateTime > @DateFrom) AND mep.FromDateTime < @DateTo
			AND metp.PropertySystemName = 'FilePath'
			AND x.value('@Guid', 'uniqueidentifier') = metp.PropertyGuid
	),
	group_files AS (
		SELECT DISTINCT
			MachineId
			,InstanceId
			,ManagedEntityRowId
			,FilePath
		FROM files
	),
	rules as (
		SELECT 
			[RuleRowId]
			,[RuleSystemName]
		FROM [dbo].[Rule]
		WHERE RuleSystemName IN (
			'Microsoft.SQLServer.Windows.CollectionRule.DBFile.FileAllocatedSpaceLeftMB',
			'Microsoft.SQLServer.Windows.CollectionRule.DBFile.FileAllocatedSpaceLeftPercent',
			'Microsoft.SQLServer.Windows.CollectionRule.DBFile.SpaceFreeMegabytes',
			'Microsoft.SQLServer.Windows.CollectionRule.DBFile.SpaceFreePercent')
	),
	instances AS (
		SELECT 
			rules.RuleSystemName
			,rules.RuleRowId
			,pri.PerformanceRuleInstanceRowId
		FROM [dbo].[PerformanceRuleInstance] pri
			JOIN rules ON pri.RuleRowId = rules.RuleRowId
	),
	ruleData AS (
		SELECT 
			me.MachineId
			,me.InstanceId
			,me.ManagedEntityRowId
			,me.FilePath	
			,pd.[DateTime] AS ValueTime
			,CASE WHEN i.RuleSystemName = 'Microsoft.SQLServer.Windows.CollectionRule.DBFile.FileAllocatedSpaceLeftMB' THEN pd.AverageValue ELSE NULL END AS FreeSpaceInFileMBAverage
			,CASE WHEN i.RuleSystemName = 'Microsoft.SQLServer.Windows.CollectionRule.DBFile.FileAllocatedSpaceLeftPercent' THEN pd.AverageValue ELSE NULL END AS FreeSpaceInFilePercentAverage
			,CASE WHEN i.RuleSystemName = 'Microsoft.SQLServer.Windows.CollectionRule.DBFile.SpaceFreeMegabytes' THEN pd.AverageValue ELSE NULL END AS FreeSpacePlusAutoGrowthMBAverage
			,CASE WHEN i.RuleSystemName = 'Microsoft.SQLServer.Windows.CollectionRule.DBFile.SpaceFreePercent' THEN pd.AverageValue ELSE NULL END AS FreeSpacePlusAutoGrowthPercentAverage
		FROM group_files me
			INNER JOIN [Perf].[vPerfHourly] pd ON pd.ManagedEntityRowId = me.ManagedEntityRowId
			INNER JOIN instances i ON pd.PerformanceRuleInstanceRowId = i.PerformanceRuleInstanceRowId
		WHERE pd.[DateTime] BETWEEN @DateFrom AND @DateTo
	),
	groupedData AS (
		SELECT
			rd.MachineId
			,rd.InstanceId
			,rd.ManagedEntityRowId
			,MAX(rd.FilePath) AS FilePath
			,rd.ValueTime
			,MAX(FreeSpaceInFileMBAverage) AS FreeSpaceInFileMBAverage
			,MAX(FreeSpaceInFilePercentAverage) AS FreeSpaceInFilePercentAverage
			,MAX(FreeSpacePlusAutoGrowthMBAverage) AS FreeSpacePlusAutoGrowthMBAverage
			,MAX(FreeSpacePlusAutoGrowthPercentAverage) AS FreeSpacePlusAutoGrowthPercentAverage
		FROM ruleData rd
		GROUP BY rd.MachineId, rd.InstanceId, rd.ManagedEntityRowId, rd.ValueTime
	)
	INSERT INTO @RawResults
	SELECT 
		r.MachineId
		,r.InstanceId
		,r.ManagedEntityRowId
		,r.FilePath
		,r.ValueTime
		,r.FreeSpaceInFileMBAverage
		,r.FreeSpaceInFilePercentAverage
		,r.FreeSpacePlusAutoGrowthMBAverage
		,r.FreeSpacePlusAutoGrowthPercentAverage
		,CASE 
			WHEN r.FreeSpaceInFilePercentAverage = 0 THEN 0 
			ELSE r.FreeSpaceInFileMBAverage / r.FreeSpaceInFilePercentAverage * 100 
		END AS FileSize 
	FROM groupedData r;

--Select * from @RawResults

	SELECT 
		@begintime = MIN(r.ValueTime)
		,@endtime = MAX(r.ValueTime) 
	FROM @RawResults r;

	--DECLARE @interval INT;
	SET @interval = DATEDIFF(DAY, @begintime, @endtime);
	SET @interval = CASE WHEN @interval = 0 OR @interval IS NULL THEN 1 ELSE @interval END;

	;WITH filteredData AS (
		SELECT
			r.MachineId
			,r.InstanceId
			,SUM (CASE WHEN r.ValueTime = @begintime THEN r.FileSize ELSE NULL END) as FileSizeBegin
			,SUM (CASE WHEN r.ValueTime = @endtime THEN r.FileSize ELSE NULL END) as FileSizeEnd
			,AVG (CASE WHEN r.ValueTime = @begintime THEN r.FreeSpacePlusAutoGrowthPercentAverage ELSE NULL END) as FreePercentBeginning
			,AVG (CASE WHEN r.ValueTime = @endtime THEN r.FreeSpacePlusAutoGrowthPercentAverage ELSE NULL END) as FreePercentEnd
		FROM @RawResults r
		WHERE r.ValueTime IN (@begintime, @endtime)
		GROUP BY r.MachineId, r.InstanceId
	)
	INSERT INTO @ReportResults
	SELECT 
		1 AS RecordType
		,ROW_NUMBER() OVER (ORDER BY r.MachineId, r.InstanceId) AS RowNum
		,r.MachineId
		,r.InstanceId
		,NULL AS ManagedEntityRowId
		,NULL AS FilePath
		,NULL AS ValueTime
		,r.FileSizeBegin
		,r.FileSizeEnd
		,@ForecastDays * (r.FileSizeEnd - r.FileSizeBegin) / @interval + r.FileSizeEnd AS FileSizeForecast
		,r.FreePercentBeginning
		,r.FreePercentEnd
	FROM filteredData r
	ORDER BY r.MachineId, r.InstanceId;

	INSERT INTO @ReportResults
	SELECT 
		2 AS RecordType
		,ROW_NUMBER() OVER (ORDER BY r.MachineId, r.InstanceId, r.ValueTime) AS RowNum
		,r.MachineId
		,r.InstanceId
		,NULL AS ManagedEntityRowId
		,NULL AS FilePath
		,r.ValueTime
		,NULL AS FileSizeBegin
		,SUM (r.FileSize) AS FileSizeEnd
		,NULL AS FileSizeForecast
		,NULL AS FreePercentBeginning
		,NULL AS FreePercentEnd 
	FROM @RawResults r
	GROUP BY r.MachineId, r.InstanceId, r.ValueTime
	ORDER BY r.MachineId, r.InstanceId, r.ValueTime;

	;WITH rawData AS (
		SELECT
			r.MachineId
			,r.InstanceId
			,r.FilePath
			,r.FileSize
			,r.ManagedEntityRowId
			,ROW_NUMBER() OVER (PARTITION BY r.MachineId, r.InstanceId ORDER BY r.FileSize DESC) AS RowNum
		FROM @RawResults r
		WHERE r.ValueTime = @endtime
	)
	INSERT INTO @ReportResults
	SELECT 
		3 AS RecordType
		,ROW_NUMBER() OVER (ORDER BY r.MachineId, r.InstanceId, r.FileSize DESC) AS RowNum
		,r.MachineId
		,r.InstanceId
		,NULL AS ManagedEntityRowId
		,r.FilePath
		,NULL AS ValueTime
		,NULL AS FileSizeBegin
		,r.FileSize AS FileSizeEnd
		,NULL AS FileSizeForecast
		,NULL AS FreePercentBeginning
		,NULL AS FreePercentEnd 
	FROM rawData r
	WHERE r.RowNum <= 5
	ORDER BY r.MachineId, r.InstanceId, r.FileSize DESC;

	;WITH rawData AS (
		SELECT
			rBegin.MachineId
			,rBegin.InstanceId
			,rBegin.FilePath
			,rBegin.FileSize AS FileSizeBegin
			,rEnd.FileSize AS FileSizeEnd
			,ROUND(rEnd.FileSize - rBegin.FileSize, 7) AS Growth
			,ROW_NUMBER() OVER (PARTITION BY rBegin.MachineId, rBegin.InstanceId ORDER BY rEnd.FileSize - rBegin.FileSize DESC) AS RowNum
		FROM @RawResults rBegin
			INNER JOIN @RawResults rEnd on rBegin.InstanceId = rEnd.InstanceId and rBegin.ManagedEntityRowId = rEnd.ManagedEntityRowId
		WHERE rBegin.ValueTime = @begintime and rEnd.ValueTime = @endtime
	)
	INSERT INTO @ReportResults
	SELECT
		4 AS RecordType
		,ROW_NUMBER() OVER (ORDER BY r.MachineId, r.InstanceId, r.Growth DESC) AS RowNum
		,r.MachineId
		,r.InstanceId
		,NULL AS ManagedEntityRowId
		,r.FilePath
		,NULL AS ValueTime
		,r.FileSizeBegin AS FileSizeBegin
		,r.FileSizeEnd AS FileSizeEnd
		,NULL AS FileSizeForecast
		,NULL AS FreePercentBeginning
		,NULL AS FreePercentEnd 
	FROM rawData r
	WHERE r.RowNum <= 5
	ORDER BY r.MachineId, r.InstanceId, r.Growth DESC;

	INSERT INTO @ReportResults
	SELECT 
		5 as RecordType
		,ROW_NUMBER() OVER (ORDER BY rBegin.MachineId, rBegin.InstanceId, rBegin.FilePath, rBegin.ManagedEntityRowId) as RowNum
		,rBegin.MachineId
		,rBegin.InstanceId
		,rBegin.ManagedEntityRowId as ManagedEntityRowId
		,rBegin.FilePath
		,NULL as ValueTime
		,rBegin.FileSize as FileSizeBegin
		,rEnd.FileSize as FileSizeEnd
		,ROUND(@ForecastDays*(rEnd.FileSize - rBegin.FileSize)/@interval + rEnd.FileSize, 7) as FileSizeForecast
		,rBegin.FreeSpacePlusAutoGrowthPercentAverage as FreePercentBeginning
		,rEnd.FreeSpacePlusAutoGrowthPercentAverage as FreePercentEnd 
	FROM @RawResults rBegin
		INNER JOIN @RawResults rEnd ON rBegin.InstanceId = rEnd.InstanceId AND rBegin.ManagedEntityRowId = rEnd.ManagedEntityRowId
	WHERE rBegin.ValueTime = @begintime AND rEnd.ValueTime = @endtime
	ORDER BY  rBegin.MachineId, rBegin.InstanceId, rBegin.FilePath, rBegin.ManagedEntityRowId;

	SELECT
		r.RecordType
		,r.RowNum
		,il.ManagementGroupId
		,r.MachineId
		,r.InstanceId
		,il.ManagementGroupName
		,il.MachineName
		,il.InstanceName
		,r.ManagedEntityRowId
		,r.FilePath
		,r.ValueTime
		,r.FileSizeBegin
		,r.FileSizeEnd
		,r.FileSizeForecast
		,r.FreePercentBeginning
		,FreePercentEnd
	FROM @ReportResults r
		INNER JOIN @InstanceLists il ON r.InstanceId = il.InstanceId
	ORDER BY il.ManagementGroupName, il.MachineName, il.InstanceName, r.RecordType, r.RowNum;
