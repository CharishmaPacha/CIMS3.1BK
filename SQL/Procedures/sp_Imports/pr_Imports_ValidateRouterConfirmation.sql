/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/04/24  RV      pr_Imports_RouterConfirmations, pr_Imports_ValidateRouterConfirmation: Initial version
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ValidateRouterConfirmation') is not null
  drop Procedure pr_Imports_ValidateRouterConfirmation;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_ValidateRouterConfirmation:
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ValidateRouterConfirmation
  (@RouterConfirmationImport  TRouterConfirmationImportType READONLY)
as
  declare @vReturnCode   TInteger;

  declare @RouterConfirmationValidations TImportValidationType;
begin
  set @vReturnCode = 0;

  /* Insert key information in Router confimation validations table */
  insert into @RouterConfirmationValidations (RecordId, LPNId, EntityId, EntityKey, RecordType, EntityStatus, InputXML, BusinessUnit,
                                              RecordAction)
    select RCI.RecordId, RCI.LPNId, RCI.LPNId, RCI.LPN, RCI.RecordType, RCI.LPNStatus, convert(nvarchar(max), RCI.InputXML), RCI.BusinessUnit, coalesce(RCI.RecordAction, 'I' /* Insert */)
    from @RouterConfirmationImport RCI;

  /* Validate insert action records - verify whether LPN is exist or not to insert router confirmations */
  update RCV
  set RCV.RecordAction = 'E' /* Error */,
      RCV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'LPNDoesNotExist', RCV.EntityKey)
  from  @RouterConfirmationValidations RCV
  where (RCV.RecordAction = 'I' /* Insert */) and
        (RCV.LPNId is null);

  /* Validate Insert action records - verify the status of the LPN's router confirmation for insertion */
  update RCV
  set RCV.RecordAction = 'E' /* Error */,
      RCV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'LPNStatusInvalidForInsert', RCV.EntityKey)
  from  @RouterConfirmationValidations RCV
  where (RCV.RecordAction = 'I' /* Delete */) and
        (charindex(RCV.EntityStatus, 'NRVO' /* New, Received, Voided, Lost */) > 0);

  select * from @RouterConfirmationValidations order by RecordId;

  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_ValidateRouterConfirmation */

Go
