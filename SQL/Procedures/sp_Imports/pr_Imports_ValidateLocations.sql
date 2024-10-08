/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/11/15  MV      pr_Imports_ValidateLocations: Included validating Warehouse (CIMS-1683)
  2017/10/19  RA      pr_Imports_ValidateLocations: Changes added for validating the Import of Locations(CIMS-1649)
  2017/06/08  RV      pr_Imports_ValidateLocations: made changes to not delete location when location is not empty (CIMS-1339)
                      pr_Imports_ValidateLocations: correction to run time error in update statement for Delete action
  2017/05/12  OK      pr_Imports_Locations, pr_Imports_ValidateLocations: Added for Location imports
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ValidateLocations') is not null
  drop Procedure pr_Imports_ValidateLocations;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_ValidateLocations:
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ValidateLocations
  (@ttLocationImports  TLocationImportType  READONLY)
as
  declare @vReturnCode              TInteger,
          @ttLocationsValidation  TImportValidationType;
begin
  set @vReturnCode = 0;

  /* Get value from import table for validation */
  insert into @ttLocationsValidation (RecordId, RecordType, EntityId, EntityKey, EntityStatus, LocationId, Location, LocationType, StorageType, InputXML, Warehouse, BusinessUnit, RecordAction)
    select L.RecordId, L.RecordType, L.LocationId, L.Location, L.Status, L.LocationId, L.Location, L.LocationType, L.StorageType, convert(nvarchar(max), L.InputXML), L.Warehouse, L.BusinessUnit,
           dbo.fn_Imports_ResolveAction('LOC', L.RecordAction, L.LocationId, L.BusinessUnit, null /* UserId */)
    from @ttLocationImports L;

  /* Execute Validations */
  /* Validate EntityKey, BU, ignore Ownership & Warehouse */
  update @ttLocationsValidation
  set ResultXML = coalesce(LV.ResultXML, '') +
                  dbo.fn_Imports_ValidateInputData('Import_Location', LV.EntityKey, LV.EntityId,
                                                   LV.RecordAction, LV.BusinessUnit, '@@' /* Ownership */, LV.Warehouse /* Warehouse */)
  from @ttLocationsValidation LV join @ttLocationImports L on L.RecordId = LV.RecordId;

  /* If action itself was invalid, then report accordingly */
  update LV
  set LV.RecordAction = 'E' /* Error */,
      LV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_InvalidAction', LV.EntityKey)
  from @ttLocationsValidation LV
  where (LV.RecordAction = 'X' /* Invalid Action */);

  /* Cannot change LocationType/StorageType if Location is not empty */
  update LV
  set LV.RecordAction = 'E' /* Error */,
      LV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'LocImport_NoChangeOfLocationTypeAndStorageType', LV.EntityKey)
  from @ttLocationsValidation LV
  join Locations L on (L.Location = LV.Location)
  where ((LV.LocationType <> L.LocationType) or
        (LV.StorageType   <> L.StorageType)) and
        (L.Status         <> 'E' /* Empty */) and
        (LV.RecordAction  = 'U' /* Update */);

  /* Cannot delete the location if Location is not empty */
  update LV
  set LV.RecordAction = 'E' /* Error */,
      LV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'LocImport_CannotDeleteNonEmpty', LV.EntityKey)
  from @ttLocationsValidation LV
  join Locations L on (L.Location = LV.Location)
  where (coalesce(LV.EntityStatus, '') <> 'E' /* Empty */) and
        (LV.RecordAction    = 'D' /* Delete */);

  /* Validate the LocationType and StorageType validations */
  update LV
  set LV.RecordAction = 'E' /* Error */,
      LV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'LocImport_Invalid_StorageAndLocationType', LV.EntityKey)
  from @ttLocationsValidation LV
  join Locations L on (L.Location = LV.Location)
  where ((LV.LocationType <> L.LocationType) or
        (LV.StorageType   <> L.StorageType)) and
        (charindex(LV.StorageType, dbo.fn_Controls_GetAsString('Location_'+ LV.LocationType, 'ValidStorageType', 'AU', LV.BusinessUnit, null /* UserId */)) = 0) and
        (LV.RecordAction = 'U' /* Update */);

  /* Validate the LocationType and StorageType validations for Import*/
  update LV
  set LV.RecordAction = 'E' /* Error */,
      LV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'LocImport_Invalid_StorageAndLocationType', LV.EntityKey)
  from @ttLocationsValidation LV
  where (charindex(LV.StorageType, dbo.fn_Controls_GetAsString('Location_'+ LV.LocationType, 'ValidStorageType', 'AU', LV.BusinessUnit, null /* UserId */)) = 0) and
        (LV.RecordAction ='I' /* Insert */);

  /* Update RecordAction when there are errors */
  update @ttLocationsValidation
  set RecordAction = case when ResultXML is not null then 'E' else RecordAction end;

  /* Update Result XML with Errors Parent Node to complete the errors xml structure */
  update @ttLocationsValidation
  set ResultXML    = dbo.fn_XMLNode('Errors', ResultXML)
  where (RecordAction = 'E');

  select * from @ttLocationsValidation order by RecordId;

  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_ValidateLocations */

Go
