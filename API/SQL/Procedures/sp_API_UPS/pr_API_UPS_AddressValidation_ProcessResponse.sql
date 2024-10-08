/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/03/21  RV      pr_API_UPS_AddressValidation_ProcessResponse: Made changes to evaluate the address validation status based on rules (BK-997)
  2023/02/02  RV      pr_API_UPS_AddressValidation_ProcessResponse: Made changes to update the address based upon the control varaible (BK-997)
  2022/08/18  VS      pr_API_UPS_AddressValidation_ProcessResponse: Generate PTError Transaction if Order has invalid address (BK-885)
                      pr_API_UPS_AddressValidation_ProcessResponse: Made changes to revert back the order status
  2022/07/03  RV      pr_API_UPS_AddressValidation_ProcessResponse: Bug fixed to check the transaction count with
                      pr_API_UPS_AddressValidation_ProcessResponse: Procedure to process the Address response and save the validations (CID-1904)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_UPS_AddressValidation_ProcessResponse') is not null
  drop Procedure pr_API_UPS_AddressValidation_ProcessResponse;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_UPS_AddressValidation_ProcessResponse: Once UPS Address Validation API is invoked, we would get
    a Address response back from UPS which would be saved in the APIOutboundTransaction
    table and the RecordId passed to this procedure for processing the response.
    Process Address and save it in the Contacts table

  Note: we have response format in the below document
  D:/SVN/CIMS 3.0/branches/Dev3.0/Documents/Manuals/Developer Manuals/Address Validation RESTful API Developer Guide.pdf

  Address Classification Code:
  0 - UnClassified
  1 - Commercial
  2 - Residential
------------------------------------------------------------------------------*/
Create Procedure pr_API_UPS_AddressValidation_ProcessResponse
  (@TransactionRecordId   TRecordId)
as
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,
          @vMessage                     TMessage,
          @vTranCount                   TCount,
          /* Audit & Response */
          @vAuditActivity              TActivityType,
          @ttAuditTrailInfo            TAuditTrailInfo,
          @vAuditRecordId              TRecordId,

          @vContactId                   TRecordId,
          @vContactRefId                TContactRefId,
          @vAddressClassificationCode   TCount,
          @vAddressClassification       TVarchar,
          @vAddressValidationStatus     TStatus,

          @vAddressLine1                TAddressLine,
          @vAddressLine2                TAddressLine,
          @vCity                        TCity,
          @vState                       TState,
          @vZip                         TZip,

          @vRevertOrderToDownload       TControlValue,
          @vAllowToModify               TControlValue,

          @vRulesDataXML                TXML,

          @vRawResponse                 TVarchar,
          @vComments                    TVarchar,
          @vBusinessUnit                TBusinessUnit,
          @vUserId                      TUserId,
          @vModifiedDate                TDateTime;

  declare @ttValidations                TValidations;
  declare @ttContactModified table  (ContactId           TRecordId,
                                     ContactRefId        TContactRefId,
                                     OldAddressLine1     TAddressLine,
                                     NewAddressLine1     TAddressLine,
                                     OldAddressLine2     TAddressLine,
                                     NewAddressLine2     TAddressLine,
                                     OldCity             TCity,
                                     NewCity             TCity,
                                     OldState            TState,
                                     NewState            TState,
                                     OldZip              TZip,
                                     NewZip              TZip,
                                     OldResidential      TFlag,
                                     NewResidential      TFlag,
                                     Note                TVarchar  default '',
                                     RecordId            TRecordId Identity(1,1));

begin /* pr_API_UPS_AddressValidation_ProcessResponse */
begin try
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode     = 0,
         @vMessageName    = null,
         @vTranCount      = @@trancount,
         @vAuditActivity  = 'AT_ContactModify';

  if (@vTranCount = 0) begin transaction;

  /* Temporary table to store Validations */
  if (object_id('tempdb..#Validations') is null)      select * into #Validations  from @ttValidations;
  if (object_id('tempdb..#ContactModified') is null) select * into #ContactModified from @ttContactModified;

  /* Get Response Info */
  select @vContactId    = EntityId,
         @vContactRefId = EntityKey,
         @vRawResponse  = RawResponse,
         @vBusinessUnit = BusinessUnit,
         @vModifiedDate = ModifiedDate,
         @vUserId       = Modifiedby
  from APIOutboundTransactions
  where (RecordId   = @TransactionRecordId) and
        (EntityType = 'Contact');

  select @vRevertOrderToDownload = dbo.fn_Controls_GetAsBoolean('UPS_ShipToAddressValidation', 'RevertOrderToDownload', 'Y' /* Yes */, @vBusinessUnit, @vUserId),
         @vAllowToModify         = dbo.fn_Controls_GetAsBoolean('UPS_ShipToAddressValidation', 'AllowToModify',         'N' /* No */, @vBusinessUnit, @vUserId);

  select @vAddressClassificationCode = json_value(@vRawResponse, '$.XAVResponse.AddressClassification.Code'),
         @vAddressClassification     = json_value(@vRawResponse, '$.XAVResponse.AddressClassification.Description'),
         @vAddressValidationStatus   = case when @vRawResponse like '%ValidAddressIndicator%'     then 'Valid'
                                            when @vRawResponse like '%AmbiguousAddressIndicator%' then 'Ambiguous'
                                            when @vRawResponse like '%NoCandidatesIndicator%'     then 'Invalid'
                                            when @vRawResponse like '%Error%'                     then 'Invalid'
                                       end;

  if (@vAddressValidationStatus = 'Valid')
    select @vAddressLine1 = iif(json_value(@vRawResponse, '$.XAVResponse.Candidate.AddressKeyFormat.AddressLine') is null,
                                  json_value(@vRawResponse, '$.XAVResponse.Candidate.AddressKeyFormat.AddressLine[0]'),
                                  json_value(@vRawResponse, '$.XAVResponse.Candidate.AddressKeyFormat.AddressLine')),
           @vAddressLine2 = json_value(@vRawResponse, '$.XAVResponse.Candidate.AddressKeyFormat.AddressLine[1]'),
           @vCity         = json_value(@vRawResponse, '$.XAVResponse.Candidate.AddressKeyFormat.PoliticalDivision2'),
           @vState        = json_value(@vRawResponse, '$.XAVResponse.Candidate.AddressKeyFormat.PoliticalDivision1'),
           @vZip          = json_value(@vRawResponse, '$.XAVResponse.Candidate.AddressKeyFormat.PostcodePrimaryLow');

  /* Build the xml for Rules */
  select @vRulesDataXML = dbo.fn_XMLNode('RootNode',
                            dbo.fn_XMLNode('Carrier',                 'UPS') +
                            dbo.fn_XMLNode('ContactId',               @vContactId) +
                            dbo.fn_XMLNode('AddressValidationStatus', @vAddressValidationStatus) +
                            dbo.fn_XMLNode('AllowToModifyAddress',    @vAllowToModify) +
                            dbo.fn_XMLNode('ValidatedAddressLine1',   @vAddressLine1) +
                            dbo.fn_XMLNode('ValidatedAddressLine2',   @vAddressLine2) +
                            dbo.fn_XMLNode('ValidatedCity',           @vCity) +
                            dbo.fn_XMLNode('ValidatedState',          @vState) +
                            dbo.fn_XMLNode('ValidatedZip',            @vZip) +
                            dbo.fn_XMLNode('BusinessUnit',            @vBusinessUnit) +
                            dbo.fn_XMLNode('UserId',                  @vUserId));

  /* Determine the Address validation status */
  exec pr_RuleSets_Evaluate 'Carrier_AddressValidation', @vRulesDataXML, @vAddressValidationStatus output;

  /* Clear the addresses when AllowToModify control value is N or address is not valid */
  if (@vAllowToModify = 'N' /* No */) or (@vAddressValidationStatus <> 'Valid')
    select @vAddressLine1 = null,
           @vAddressLine2 = null,
           @vCity         = null,
           @vState        = null,
           @vZip          = null;

  /* Get the Error Message from RawResponse and send to Host */
  select @vComments = string_agg([Message], ', ')
  from openjson(@vRawResponse, '$.response.errors')
  with ([Message] TNvarchar '$.message');

  /* Apart from errors, add additional info based upon indicators */
  select @vComments = concat_ws(', ', @vComments,
                        iif (@vRawResponse like '%AmbiguousAddressIndicator%', 'Ambiguous Address', ''),
                        iif (@vRawResponse like '%NoCandidatesIndicator%',     'No Candidates', ''));

  /* Update the Candidate response from API on UDF1 */
  update APIOutboundTransactions
  set UDF1 = json_query(RawResponse, '$.XAVResponse.Candidate')
  where (RecordId   = @TransactionRecordId);

  /* Update the Contacts with validated info */
  update Contacts
  set AddressLine1       = coalesce(@vAddressLine1, AddressLine1),
      AddressLine2       = coalesce(@vAddressLine2, AddressLine2),
      City               = coalesce(@vCity,         City),
      State              = coalesce(@vState,        State),
      Zip                = coalesce(@vZip,          Zip),
      Residential        = case when @vAddressClassificationCode = 2 then 'Y' /* Yes */ else 'N' /* No */ end,
      AddrClassification = @vAddressClassification,
      AVStatus           = @vAddressValidationStatus,
      AVDetails          = @vComments,
      AVResponse         = json_query(@vRawResponse, '$.XAVResponse.Candidate'),
      ModifiedDate       = @vModifiedDate
  output inserted.ContactId, inserted.ContactRefId, deleted.AddressLine1, inserted.AddressLine1, deleted.AddressLine2, inserted.AddressLine2,
         deleted.City, inserted.City, deleted.State, inserted.State, deleted.Zip, inserted.Zip, deleted.Residential, inserted.Residential
  into #ContactModified(ContactId, ContactRefId, OldAddressLine1, NewAddressLine1, OldAddressLine2, NewAddressLine2,
                        OldCity, NewCity, OldState, NewState, OldZip, NewZip, OldResidential, NewResidential)
  where (ContactId = @vContactId);

  /* When an address is invalid, then flag all the respective Orders shipping to that address as well */
  insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2, Value3)
    select distinct 'Order', OH.OrderId, OH.PickTicket, 'Order_AddressValidation_Invalid', OH.PickTicket, OH.ShipToId,
           substring(@vComments, 1, 120 /* TDescription */)
    from OrderHeaders OH
      join Contacts C on (OH.ShipToId = C.ContactRefId) and (C.ContactType = 'S') and (C.AVStatus in ('Invalid', 'Ambiguous'))
    where (OH.Archived = 'N') and
          (OH.ShipToId = @vContactRefId) and
          (OH.BusinessUnit = @vBusinessUnit) and
          (OH.Status not in ('S' /* Shipped */, 'X' /* Canceled */))
          /* Note: As of now using UPS address validation for all other small package carriers. If implemented any carrier
                   specific validations need to uncomment the following statement */
          --(OH.ShipVia like 'UPS%');

  /* Notifications would have reasons for dis-qualification, so set HasNotes, Status and PreProcessFlag and
     revert the order status to downloaded based upon the control value */
  update OH
  set OH.Status       = iif((@vRevertOrderToDownload = 'Y') and (OH.Status = 'N' /* New */), 'O' /* Downloaded */, OH.Status),
      OH.HasNotes     = 'Y' /* Yes */,
      OH.ModifiedDate = @vModifiedDate,
      OH.ModifiedBy   = @vUserId
  from OrderHeaders OH join #Validations V on (OH.OrderId = V.EntityId);

  if (@vTranCount = 0) commit transaction;

  /*--------------------- Exports ------------------*/
  /* If Address was invalid, then notify the host of all Orders that have an issue */
  if (@vAddressValidationStatus in ('Invalid', 'Ambiguous'))
    begin
      /* Build temp table to be similar to table Exports */
      create table #ExportRecords (ExpRecordId int identity(1, 1) not null);
      exec pr_PrepareHashTable 'Exports', '#ExportRecords';

      /* Generate the Error Transactions for OrderHeaders */
      insert into #ExportRecords (TransType, TransEntity, TransQty, OrderId, Comments, ShipVia, CreatedBy)
        select 'PTError', 'OH', OH.NumUnits, OH.OrderId, @vComments, OH.ShipVia, @vUserId
        from #Validations V
          join OrderHeaders OH on (V.EntityId = OH.OrderId);

      /* Insert Records into Exports table */
      exec pr_Exports_InsertRecords 'PTError', null, @vBusinessUnit;
    end

  /* Build the note with the change in values for each field */
  update #ContactModified set Note = coalesce(Note, '');
  update #ContactModified set Note = concat_ws(', ',
                                                 dbo.fn_ChangeInValue('AddressLine1', OldAddressLine1, NewAddressLine1, default, @vBusinessUnit, @vUserId),
                                                 dbo.fn_ChangeInValue('AddressLine2', OldAddressLine2, NewAddressLine2, default, @vBusinessUnit, @vUserId),
                                                 dbo.fn_ChangeInValue('City',         OldCity,         NewCity,         default, @vBusinessUnit, @vUserId),
                                                 dbo.fn_ChangeInValue('State',        OldState,        NewState,        default, @vBusinessUnit, @vUserId),
                                                 dbo.fn_ChangeInValue('Zip',          OldZip,          NewZip,          default, @vBusinessUnit, @vUserId),
                                                 dbo.fn_ChangeInValue('Residential',  OldResidential,  NewResidential,  default, @vBusinessUnit, @vUserId));

  /* Insert Audit Trail */
  insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
    select 'Contact', ContactId, ContactRefId, @vAuditActivity, @vBusinessUnit, @vUserId,
           dbo.fn_Messages_Build(@vAuditActivity, Note, null, null, null, null) /* Comment */
    from #ContactModified;

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

end try
begin catch
  if (@@trancount > 0) rollback transaction

  exec @vReturnCode = pr_ReRaiseError;
end catch

ErrorHandler:
  /* Save Validations to Notifications */
  exec pr_Notifications_SaveValidations 'Order', null /* OrderId */, null /* PickTicket */, 'NO', 'AddressValidation', @vBusinessUnit, @vUserId;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_UPS_AddressValidation_ProcessResponse */

Go
