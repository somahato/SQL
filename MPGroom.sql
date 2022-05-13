PRINT '== Remove of [Image] '

PRINT '1. [Image]:'

DELETE i

FROM [Image] i

JOIN ManagementPack mp ON (i.ManagementPackRowId = mp.ManagementPackRowId)

WHERE NOT EXISTS (SELECT * FROM ManagementPackVersion WHERE ManagementPackRowId = mp.ManagementPackRowId)

PRINT '== Remove of [StringResource] '

PRINT '2. [StringResource]:'


DELETE sr

FROM StringResource sr

JOIN ManagementPack mp ON (sr.ManagementPackRowId = mp.ManagementPackRowId)

WHERE NOT EXISTS (SELECT * FROM ManagementPackVersion WHERE ManagementPackRowId = mp.ManagementPackRowId)

PRINT '== Remove of [ManagementPack] '

PRINT '3. [ManagementPack]:'

DELETE mp

FROM ManagementPack mp

WHERE NOT EXISTS (SELECT * FROM ManagementPackVersion WHERE ManagementPackRowId = mp.ManagementPackRowId)

　

PRINT '== Remove of [ManagementGroupManagementPackVersion] '

PRINT '4. [ManagementGroupManagementPackVersion]:'

DECLARE @ManagementPackVersionToDeleteRowId int

SET @ManagementPackVersionToDeleteRowId = '2405'

DELETE FROM ManagementGroupManagementPackVersion where ManagementPackVersionRowId = @ManagementPackVersionToDeleteRowId and DeletedDateTime is not null

PRINT '== Remove of [ManagementGroupManagementPackVersion] '

PRINT '5. [ManagementGroupManagementPackVersion]:'

DELETE FROM ManagementGroupManagementPackVersion

WHERE (ManagementPackVersionRowId = @ManagementPackVersionToDeleteRowId)

AND (DeletedDateTime = (SELECT TOP 1 DeletedDateTime

FROM ManagementGroupManagementPackVersion

WHERE (DeletedDateTime IS NOT NULL)

AND (ManagementPackVersionRowId = @ManagementPackVersionToDeleteRowId)

ORDER BY DeletedDateTime)

)

PRINT '== Remove of [ManagementPackChangeAudit] '

PRINT '6. [ManagementPackChangeAudit]:'


DELETE FROM ManagementPackChangeAudit

WHERE (ManagementPackAuditRowId IN

(SELECT ManagementPackAuditRowId

FROM ManagementPackChangeAudit

WHERE (ManagementPackVersionRowId = @ManagementPackVersionToDeleteRowId)

)

)


PRINT '== Remove of [MonitorServiceLevelObjectiveManagementPackVersion] '

PRINT '7. [MonitorServiceLevelObjectiveManagementPackVersion]:'

DELETE FROM MonitorServiceLevelObjectiveManagementPackVersion

WHERE (ServiceLevelObjectiveManagementPackVersionRowId IN

(SELECT ServiceLevelObjectiveManagementPackVersionRowId

FROM ServiceLevelObjectiveManagementPackVersion

WHERE (ManagementPackVersionRowId = @ManagementPackVersionToDeleteRowId)

)

)

PRINT '== Remove of [PerformanceServiceLevelObjectiveManagementPackVersion] '

PRINT '8. [PerformanceServiceLevelObjectiveManagementPackVersion]:'

DELETE FROM PerformanceServiceLevelObjectiveManagementPackVersion

WHERE (ServiceLevelObjectiveManagementPackVersionRowId IN

(SELECT ServiceLevelObjectiveManagementPackVersionRowId

FROM ServiceLevelObjectiveManagementPackVersion

WHERE (ManagementPackVersionRowId = @ManagementPackVersionToDeleteRowId)

)

)

PRINT '== Remove of [ServiceLevelObjectiveManagementPackVersion] '

PRINT '9. [ServiceLevelObjectiveManagementPackVersion]:'

DELETE FROM ServiceLevelObjectiveManagementPackVersion

WHERE (ManagementPackVersionRowId = @ManagementPackVersionToDeleteRowId)

PRINT '== Remove of [ServiceLevelAgreementManagementPackVersion] '

PRINT '10. [ServiceLevelAgreementManagementPackVersion]:' 


DELETE FROM ServiceLevelAgreementManagementPackVersion

WHERE (ManagementPackVersionRowId = @ManagementPackVersionToDeleteRowId)

PRINT '== Remove of [ManagedEntityTypePropertyManagementPackVersion] '

PRINT '11. [ManagedEntityTypePropertyManagementPackVersion]:' 


DELETE FROM ManagedEntityTypePropertyManagementPackVersion

WHERE (ManagementPackVersionRowId = @ManagementPackVersionToDeleteRowId)

PRINT '== Remove of [RelationshipTypePropertyManagementPackVersion] '

PRINT '12. [RelationshipTypePropertyManagementPackVersion]:' 

DELETE FROM RelationshipTypePropertyManagementPackVersion

WHERE (ManagementPackVersionRowId = @ManagementPackVersionToDeleteRowId)

PRINT '== Remove of [ModuleTypeManagementPackVersion] '

PRINT '13. [ModuleTypeManagementPackVersion]:'

DELETE FROM [dbo].[ModuleTypeManagementPackVersion]

WHERE (ManagementPackVersionRowId = @ManagementPackVersionToDeleteRowId)

PRINT '== Remove of [Module] '

PRINT '14. [Module]:'

DELETE FROM Module

WHERE (ManagementPackVersionRowId = @ManagementPackVersionToDeleteRowId)

PRINT '== Remove of [MonitorManagementPackVersion] '

PRINT '15. [MonitorManagementPackVersion]:'

DELETE FROM MonitorManagementPackVersion

WHERE (ManagementPackVersionRowId = @ManagementPackVersionToDeleteRowId)

PRINT '== Remove of [DiscoveryManagementPackVersion] '

PRINT '16. [DiscoveryManagementPackVersion]:' 


DELETE FROM DiscoveryManagementPackVersion

WHERE (ManagementPackVersionRowId = @ManagementPackVersionToDeleteRowId)

PRINT '== Remove of [RecoveryManagementPackVersion] '

PRINT '17. [RecoveryManagementPackVersion]:' 

-- DELETE FROM recoveries before diagnostics

-- since recovery can reference diagnostic

DELETE FROM RecoveryManagementPackVersion

WHERE (ManagementPackVersionRowId = @ManagementPackVersionToDeleteRowId)

PRINT '== Remove of [DiagnosticManagementPackVersion] '

PRINT '18. [DiagnosticManagementPackVersion]:' 

DELETE FROM DiagnosticManagementPackVersion

WHERE (ManagementPackVersionRowId = @ManagementPackVersionToDeleteRowId)

PRINT '== Remove of [RuleManagementPackVersion] '

PRINT '19. [RuleManagementPackVersion]:' 


DELETE FROM RuleManagementPackVersion

WHERE (ManagementPackVersionRowId = @ManagementPackVersionToDeleteRowId)

PRINT '== Remove of [OverrideManagementPackVersion] '

PRINT '20. [OverrideManagementPackVersion]:' 

DELETE FROM OverrideManagementPackVersion

WHERE (ManagementPackVersionRowId = @ManagementPackVersionToDeleteRowId)

PRINT '== Remove of [ReportManagementPackVersion] '

PRINT '21. [ReportManagementPackVersion]:' 

DELETE FROM ReportManagementPackVersion

WHERE (ManagementPackVersionRowId = @ManagementPackVersionToDeleteRowId)

PRINT '== Remove of [ReportDisplayString] '

PRINT '22. [ReportDisplayString]:' 

DELETE FROM ReportDisplayString

WHERE (ManagementPackVersionRowId = @ManagementPackVersionToDeleteRowId)

PRINT '== Remove of [ImageReference] '

PRINT '23. [ImageReference]:' 

DELETE FROM ImageReference

WHERE (ManagementPackVersionRowId = @ManagementPackVersionToDeleteRowId)

PRINT '== Remove of [RelationshipTypeManagementPackVersion] '

PRINT '24. [RelationshipTypeManagementPackVersion]:' 

DELETE FROM RelationshipTypeManagementPackVersion

WHERE (ManagementPackVersionRowId = @ManagementPackVersionToDeleteRowId)

PRINT '== Remove of [ManagedEntityTypeManagementPackVersion] '

PRINT '25. [ManagedEntityTypeManagementPackVersion]:' 

DELETE FROM ManagedEntityTypeManagementPackVersion

WHERE (ManagementPackVersionRowId = @ManagementPackVersionToDeleteRowId)

PRINT '== Remove of [ScriptManagementPackVersion] '

PRINT '26. [ScriptManagementPackVersion]:' 


DELETE FROM ScriptManagementPackVersion

WHERE (ManagementPackVersionRowId = @ManagementPackVersionToDeleteRowId)

PRINT '== Remove of [DatasetTypeSchemaTypeManagementPackVersion] '

PRINT '27. [DatasetTypeSchemaTypeManagementPackVersion]:' 

DELETE FROM DatasetTypeSchemaTypeManagementPackVersion

WHERE (ManagementPackVersionRowId = @ManagementPackVersionToDeleteRowId)

PRINT '== Remove of [DatasetTypeManagementPackVersion] '

PRINT '28. [DatasetTypeManagementPackVersion]:' 

DELETE FROM DatasetTypeManagementPackVersion

WHERE (ManagementPackVersionRowId = @ManagementPackVersionToDeleteRowId)

PRINT '== Remove of [SchemaTypeManagementPackVersion] '

PRINT '29. [SchemaTypeManagementPackVersion]:' 

DELETE FROM SchemaTypeManagementPackVersion

WHERE (ManagementPackVersionRowId = @ManagementPackVersionToDeleteRowId)


-------------------------------------------------------------------------------------------------------------------------


-- groom instance space

-- EXEC InstanceGroom @ManagementPackVersionGroomingInd = 1

-------------------------------------------------------------------------------------------------------------------------

PRINT '== Remove of [ServiceLevelObjective] '

PRINT '30. [ServiceLevelObjective]:' 

DELETE o

FROM ServiceLevelObjective o

WHERE NOT EXISTS (SELECT *

FROM ServiceLevelObjectiveManagementPackVersion ompv

WHERE (ompv.ServiceLevelObjectiveRowId = o.ServiceLevelObjectiveRowId)

)

-- sla's

PRINT '== Remove of [ServiceLevelAgreement] '

PRINT '31. [ServiceLevelAgreement]:'

DELETE o

FROM ServiceLevelAgreement o

WHERE NOT EXISTS (SELECT *

FROM ServiceLevelAgreementManagementPackVersion ompv

WHERE (ompv.ServiceLevelAgreementRowId = o.ServiceLevelAgreementRowId)

)

PRINT '== Remove of [ModuleType] '

PRINT '32. [ModuleType]:' 

-- ModuleType 

DELETE o

FROM ModuleType o

WHERE NOT EXISTS (SELECT *

FROM ModuleTypeManagementPackVersion ompv

WHERE (ompv.ModuleTypeRowId = o.ModuleTypeRowId)

)

PRINT '== Remove of [Monitor] '

PRINT '33. [Monitor]:'

-- Monitor 

DELETE o

FROM Monitor o

WHERE NOT EXISTS (SELECT *

FROM MonitorManagementPackVersion ompv

WHERE (ompv.MonitorRowId = o.MonitorRowId)

)

PRINT '== Remove of [Discovery] '

PRINT '34. [Discovery]:' 


-- delete discoveries

DELETE o

FROM Discovery o

WHERE NOT EXISTS (SELECT *

FROM DiscoveryManagementPackVersion ompv

WHERE (ompv.DiscoveryRowId = o.DiscoveryRowId)

)

PRINT '== Remove of [Recovery] '

PRINT '35. [Recovery]:'

-- delete recoveries

DELETE o

FROM Recovery o

WHERE NOT EXISTS (SELECT *

FROM RecoveryManagementPackVersion ompv

WHERE (ompv.RecoveryRowId = o.RecoveryRowId)

)

PRINT '== Remove of [Diagnostic] '

PRINT '36. [Diagnostic]:'

-- delete diagnostics

DELETE o

FROM Diagnostic o

WHERE NOT EXISTS (SELECT *

FROM DiagnosticManagementPackVersion ompv

WHERE (ompv.DiagnosticRowId = o.DiagnosticRowId)

)

PRINT '== Remove of [[Rule]] '

PRINT '37. [[Rule]]:'

-- delete rules

DELETE o

FROM [Rule] o

WHERE NOT EXISTS (SELECT *

FROM RuleManagementPackVersion ompv

WHERE (ompv.RuleRowId = o.RuleRowId)

)

PRINT '== Remove of [[Override]] '

PRINT '38. [[Override]]:'

-- SELECT * verrides

DELETE o

FROM [Override] o

WHERE NOT EXISTS (SELECT *

FROM OverrideManagementPackVersion ompv

WHERE (ompv.OverrideRowId = o.OverrideRowId)

)

PRINT '== Remove of [ReportDisplayString] '

PRINT '39. [ReportDisplayString]:'

-- delete reports

DELETE rds

FROM ReportDisplayString rds

WHERE NOT EXISTS (SELECT *

FROM ReportManagementPackVersion rmpv

WHERE (rds.ReportRowId = rmpv.ReportRowId)

)

PRINT '== Remove of [[Report]] '

PRINT '40. [[Report]]:'

DELETE o

FROM [Report] o

WHERE NOT EXISTS (SELECT *

FROM ReportManagementPackVersion ompv

WHERE (ompv.ReportRowId = o.ReportRowId)

)

PRINT '== Remove of [Script] '

PRINT '41. [Script]:'


-- delete scripts

DELETE o

FROM Script o

WHERE NOT EXISTS (SELECT *

FROM ScriptManagementPackVersion ompv

WHERE (ompv.ScriptRowId = o.ScriptRowId)

)

PRINT '== Remove of [SchemaType] '

PRINT '42. [SchemaType]:'

-- delete schema types

DELETE o

FROM SchemaType o

WHERE NOT EXISTS (SELECT *

FROM SchemaTypeManagementPackVersion ompv

WHERE (ompv.SchemaTypeRowId = o.SchemaTypeRowId)

)

PRINT '== Remove of [DatasetType] '

PRINT '43. [DatasetType]:'

-- delete dataset types

DELETE o

FROM DatasetType o

WHERE NOT EXISTS (SELECT *

FROM DatasetTypeManagementPackVersion ompv

WHERE (ompv.DatasetTypeRowId = o.DatasetTypeRowId)

)

PRINT '== Remove of [RelationshipTypeProperty] '

PRINT '44. [RelationshipTypeProperty]:'

-- delete Rel type properties

DELETE o

FROM RelationshipTypeProperty o

WHERE NOT EXISTS (SELECT *

FROM RelationshipTypePropertyManagementPackVersion ompv

WHERE (ompv.RelationshipTypePropertyRowId = o.RelationshipTypePropertyRowId)

)

PRINT '== Remove of [RelationshipType] '

PRINT '45. [RelationshipType]:'

-- delete Rel types

DELETE o

FROM RelationshipType o

WHERE NOT EXISTS (SELECT *

FROM RelationshipTypeManagementPackVersion ompv

WHERE (ompv.RelationshipTypeRowId = o.RelationshipTypeRowId)

)

PRINT '== Remove of [ManagedEntityTypeProperty] '

PRINT '46. [ManagedEntityTypeProperty]:'

-- delete ME type properties

DELETE o

FROM ManagedEntityTypeProperty o

WHERE NOT EXISTS (SELECT *

FROM ManagedEntityTypePropertyManagementPackVersion ompv

WHERE (ompv.ManagedEntityTypePropertyRowId = o.ManagedEntityTypePropertyRowId)

)

PRINT '== Remove of [ManagedEntityTypeImage] '

PRINT '47. [ManagedEntityTypeImage]:'

-- delete ME type images

DELETE o

FROM ManagedEntityTypeImage o

WHERE NOT EXISTS (SELECT *

FROM ManagedEntityTypeManagementPackVersion ompv

WHERE (ompv.ManagedEntityTypeRowId = o.ManagedEntityTypeRowId)

)

PRINT '== Remove of [ManagedEntityType] '

PRINT '48. [ManagedEntityType]:'

-- delete ME types

DELETE o

FROM ManagedEntityType o

WHERE NOT EXISTS (SELECT *

FROM ManagedEntityTypeManagementPackVersion ompv

WHERE (ompv.ManagedEntityTypeRowId = o.ManagedEntityTypeRowId)

)

PRINT '== Remove of [WorkflowCategory] '

PRINT '49. [WorkflowCategory]:'

-- delete workflow category

DELETE FROM WorkflowCategory

WHERE WorkflowCategoryRowId NOT IN (

SELECT WorkflowCategoryRowId FROM DiagnosticManagementPackVersion

UNION ALL

SELECT WorkflowCategoryRowId FROM DiscoveryManagementPackVersion

UNION ALL

SELECT WorkflowCategoryRowId FROM MonitorManagementPackVersion

UNION ALL

SELECT WorkflowCategoryRowId FROM RecoveryManagementPackVersion

UNION ALL

SELECT WorkflowCategoryRowId FROM OverrideManagementPackVersion

UNION ALL

SELECT WorkflowCategoryRowId FROM RuleManagementPackVersion

)

PRINT '== Remove of [DisplayString] '

PRINT '50. [DisplayString]:'

-- delete display strings

DELETE FROM DisplayString

WHERE ElementGuid NOT IN (

SELECT SchemaTypeGuid FROM SchemaType

UNION ALL

SELECT DatasetTypeGuid FROM DatasetType

UNION ALL

SELECT DiagnosticGuid FROM Diagnostic

UNION ALL

SELECT DiscoveryGuid FROM Discovery

UNION ALL

SELECT StringResourceGuid FROM StringResource

UNION ALL

SELECT ImageGuid FROM [Image]

UNION ALL

SELECT ManagedEntityTypeGuid FROM ManagedEntityType

UNION ALL

SELECT PropertyGuid FROM ManagedEntityTypeProperty

UNION ALL

SELECT ManagementPackVersionIndependentGuid FROM ManagementPack

UNION ALL

SELECT MonitorGuid FROM Monitor

UNION ALL

SELECT OverrideGuid FROM Override

UNION ALL

SELECT RecoveryGuid FROM Recovery

UNION ALL

SELECT RelationshipTypeGuid FROM RelationshipType

UNION ALL

SELECT PropertyGuid FROM RelationshipTypeProperty

UNION ALL

SELECT ReportGuid FROM Report

UNION ALL

SELECT RuleGuid FROM [Rule]

UNION ALL

SELECT ScriptGuid FROM Script

UNION ALL

SELECT ReportDisplayStringGuid FROM ReportDisplayString

UNION ALL

SELECT ServiceLevelAgreementGuid FROM ServiceLevelAgreement

UNION ALL

SELECT ServiceLevelObjectiveGuid FROM ServiceLevelObjective

)

PRINT '== Remove of [ManagementPackVersionReference] '

PRINT '51. [ManagementPackVersionReference]:'

-- delete MP version references

DELETE FROM ManagementPackVersionReference

WHERE ReferencingManagementPackVersionRowId = @ManagementPackVersionToDeleteRowId

PRINT '== Remove of [ManagementPackVersion] '

PRINT '52. [ManagementPackVersion]:'

-- delete MP version

DELETE FROM ManagementPackVersion

WHERE ManagementPackVersionRowId = @ManagementPackVersionToDeleteRowId

----------------------------------------------------------------------------------------------------------------------------------------------

-- rebuild ME type images

--EXEC ManagedEntityTypeImageRebuild


-- since we modified data in config tables

-- update stats on all of them

--EXEC DomainTableStatisticsUpdate 
