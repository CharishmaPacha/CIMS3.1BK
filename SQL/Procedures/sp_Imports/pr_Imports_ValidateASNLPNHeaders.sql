/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  to pr_Imports_ValidateASNLPNHeaders.Changed code to Open Xml concept and used UDT instead of hash tables. Added Audit Trail.
  pr_Imports_ValidateASNLPNHeaders, pr_Imports_ValidateASNLPNDetail : Made changes to read the table.(HPI-2360)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ValidateASNLPNHeaders') is not null
  drop Procedure pr_Imports_ValidateASNLPNHeaders;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_ValidateASNLPNHeaders: Validate the ASN LPN Header records
    and mark the RecordAction = E if there is an error
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ValidateASNLPNHeaders
  (@ttImportASNLPNHeaders  TASNLPNImportType  READONLY)
as
  declare @vReturnCode                  TInteger,
          @vValidateReceipts            TControlValue,
          @vBusinessUnit                TBusinessUnit,
          @ttASNLPNHeadersValidation    TImportValidationType;
begin
  set @vReturnCode = 0;

  /* Get value from import table for validation */
  insert into @ttASNLPNHeadersValidation (RecordId, RecordType, EntityId, EntityKey, EntityStatus, LPN,
                                          ReceiptId, ReceiptNumber, InputXML, Warehouse, BusinessUnit,
                                          RecordAction, HostRecId)
    select ALH.RecordId, ALH.RecordType, ALH.LPNId, ALH.LPN, ALH.Status, ALH.LPN,
           ALH.ReceiptId, ALH.ReceiptNumber, convert(nvarchar(max), ALH.InputXML), ALH.DestWarehouse, ALH.BusinessUnit,
           dbo.fn_Imports_ResolveAction('ASNLH', ALH.RecordAction, ALH.LPNId, ALH.BusinessUnit, null /* UserId */), ALH.HostRecId
    from @ttImportASNLPNHeaders ALH;

  /* If the user trying to insert an existing record into the db or
                 trying to update or delete the non existing record
    then we need to resolve what to do based upon control value */
  select @vValidateReceipts = dbo.fn_Controls_GetAsString('IMPORT_ASNLH', 'ValidateReceipt', 'N' /*  No */, @vBusinessUnit, '' /* UserId */);

  /* Validate if LPN Exists, BU, Owner and WH */
  with cteValidations(RecordId, ValidationMessage)
  as
  (
    select ALH.RecordId,
           dbo.fn_Imports_ValidateInputData('LPN', ALH.LPN, ALH.LPNId, ALH.RecordAction, ALH.BusinessUnit, ALH.Ownership, ALH.DestWarehouse)
    from @ttImportASNLPNHeaders ALH
      join @ttASNLPNHeadersValidation AHV on ALH.RecordId = AHV.RecordId
    union
    select ALH.RecordId, dbo.fn_Imports_ValidateEntityType(ALH.RecordType, 'LPN', ALH.LPNType, ALH.BusinessUnit)
    from @ttImportASNLPNHeaders ALH
      join @ttASNLPNHeadersValidation AHV on ALH.RecordId = AHV.RecordId
  )
  update @ttASNLPNHeadersValidation
  set RecordAction = 'E',
      ResultXML    = coalesce(ResultXML, '') + coalesce(V.ValidationMessage, '')
  from @ttASNLPNHeadersValidation AHV
  join cteValidations V on ((V.RecordId = AHV.RecordId) and
                            (V.ValidationMessage is not null));

  /* If action itself was invalid, then report accordingly */
  update ALHV
  set ALHV.RecordAction = 'E' /* Error */,
      ALHV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_InvalidAction', ALHV.EntityKey)
  from @ttASNLPNHeadersValidation ALHV
  where (ALHV.RecordAction = 'X' /* Invalid Action */);

  /* If Receipt was invalid, then report accordingly */
  if (@vValidateReceipts = 'Y')
    update ALHV
    set ALHV.RecordAction = 'E' /* Error */,
        ALHV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'ReceiptNumberIsInvalid', ALHV.EntityKey)
    from @ttASNLPNHeadersValidation ALHV
    where (ALHV.ReceiptNumber is not null) and
          (ALHV.ReceiptId is null);

  /* Validate SourceSystem system */
  --update ALHV
  --set ALHV.RecordAction = 'E' /* Error */,
  --    ALHV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_InvalidSourceSystem', ALHV.EntityKey)
  --from @ttASNLPNHeadersValidation ALHV
  --where (dbo.fn_IsValidLookUp('SourceSystem', ALHV.SourceSystem, ALHV.BusinessUnit, '') is not null);

  /* Do not allow updating any info on LPN unless it is in Transit, Received or Putaway */
  update ALHV
  set ALHV.RecordAction = 'E' /* Error */,
      ALHV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_ASNLPNStatusInvalidForUpdate', ALHV.EntityKey)
  from  @ttASNLPNHeadersValidation ALHV
  where (ALHV.RecordAction in ('U' /* Insert, Update */)) and
        (charindex(ALHV.EntityStatus, 'TRP' /* Intransit, Received, Putaway */) = 0);

  /* Validate SourceSystem with LPN record */
  -- Update ALHV
  -- set ALHV.RecordAction = 'E' /* Error */,
  --     ALHV.ResultXML    = dbo.fn_Imports_AppendError(ResultXML, 'Import_CannotChangeSourceSystem', ALHV.EntityKey)
  -- from @ttASNLPNHeadersValidation ALHV
  --   join LPNs L on L.LPNId = ALHV.EntityId and L.SourceSystem <> ALHV.SourceSystem
  -- where ALHV.RecordAction in ('U', 'D') /* Update, Delete */

  /* When using ASN import to import Picklane inventory, change action
     so that we can add the inventory to the Picklane */
  update ALHV
  set ALHV.RecordAction = 'L' /* Logical */
  from @ttASNLPNHeadersValidation ALHV
  where (ALHV.RecordAction = 'P' /* PickLane/Logical */) and (ALHV.RecordAction not in ('E'));

  select * from @ttASNLPNHeadersValidation order by RecordId;

  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_ValidateASNLPNHeaders */

Go
