/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/04/26  RV     Initial Version (CIMSV3-3532)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FedEx2_AddressValidation_ProcessResponse') is not null
  drop Procedure pr_API_FedEx2_AddressValidation_ProcessResponse;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_FedEx2_AddressValidation_ProcessResponse: Once FedEx Address Validation API is invoked, we would get
    a Address response back from FedEx which would be saved in the APIOutboundTransaction
    table and the RecordId passed to this procedure for processing the response.
    Process Address and save it in the Contacts table

  Note: we have response format in the below document
  Document Ref: https://developer.fedex.com/api/en-in/catalog/address-validation/v1/docs.html

  Address Classification: Unknown/Business/Residential/Mixed

  Sample Response:
  {
     "transactionId": "1c9b6e70-dbac-4ad8-bc68-ff4a7b0d5361",
     "customerTransactionId": "12512621",
     "output": {
       "resolvedAddresses": [
         {
            "clientReferenceId": "None",
            "streetLinesToken": [
              "7372 PARKRIDGE BLVD",
              "APT 286"
            ],
            "city": "IRVING",
            "stateOrProvinceCode": "TX",
            "postalCode": "75063-8365",
            "parsedPostalCode": {
              "base": "75063",
              "addOn": "8365",
              "deliveryPoint": "61"
            },
            "countryCode": "US",
            "classification": "UNKNOWN",
            "ruralRouteHighwayContract": false,
            "generalDelivery": false,
            "customerMessages": [],
            "normalizedStatusNameDPV": true,
            "standardizedStatusNameMatchSource": "Postal",
            "resolutionMethodName": "USPS_VALIDATE",
            "attributes": {
              "POBox": "false",
              "POBoxOnlyZIP": "false",
              "SplitZIP": "false",
              "SuiteRequiredButMissing": "false",
              "InvalidSuiteNumber": "false",
              "ResolutionInput": "RAW_ADDRESS",
              "DPV": "true",
              "ResolutionMethod": "USPS_VALIDATE",
              "DataVintage": "February 2023",
              "MatchSource": "Postal",
              "CountrySupported": "true",
              "ValidlyFormed": "true",
              "Matched": "true",
              "Resolved": "true",
              "Inserted": "false",
              "MultiUnitBase": "false",
              "ZIP11Match": "true",
              "ZIP4Match": "true",
              "UniqueZIP": "false",
              "StreetAddress": "true",
              "RRConversion": "false",
              "ValidMultiUnit": "true",
              "AddressType": "STANDARDIZED",
              "AddressPrecision": "MULTI_TENANT_UNIT",
              "MultipleMatches": "false"
            }
          }
       ]
     }
  }
------------------------------------------------------------------------------*/
Create Procedure pr_API_FedEx2_AddressValidation_ProcessResponse
  (@TransactionRecordId   TRecordId)
as
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,
          @vMessage                     TMessage,
          @vTranCount                   TCount,

          @vContactId                   TRecordId,
          @vContactRefId                TContactRefId,
          @vAddressClassificationCode   TCount,
          @vAddressClassification       TVarchar,
          @vAddressValidationStatus     TStatus,

          @vRevertOrderToDownload       TControlValue,
          @vExportOnAddressError        TControlValue,

          @vRawResponseJSON             TNVarchar,
          @vAVResponse                  TVarchar,
          @vAVDetails                   TVarchar,
          @vDocumentId                  TInteger,

          @vSeverity                    TDescription,
          @vNotifications               TVarchar,
          @vNotificationDetails         TVarchar,
          @vBusinessUnit                TBusinessUnit,
          @vUserId                      TUserId,
          @vModifiedDate                TDateTime;

  declare @ttValidations                TValidations,
          @ttNotifications              TCarrierResponseNotifications;

  declare @ttAddressValidationResponse table (
          TransactionId                     TName,
          ContactId                         TRecordId,
          ContactRefId                      TContactRefId,
          ClientReferenceId                 TContactRefId,
          AddressLine1                      TAddressLine,
          AddressLine2                      TAddressLine,
          AddressLine3                      TAddressLine,
          City                              TCity,
          State                             TState,
          Zip                               TZip,
          ZipBase                           TZip,
          ZipAddOn                          TZip,
          ZipDeliveryPoint                  TZip,
          Country                           TCountry,
          Classification                    TName,
          GeneralDelivery                   TFlags,
          NormalizedStatusNameDPV           TFlags,
          StandardizedStatusNameMatchSource TName,
          ResolutionMethodName              TFlags,

          POBox                             TFlags,
          POBoxOnlyZIP                      TFlags,
          SplitZIP                          TFlags,
          SuiteRequiredButMissing           TFlags,
          InvalidSuiteNumber                TFlags,
          ResolutionInput                   TName,
          DPV                               TFlags,
          DataVintage                       TName,
          MatchSource                       TName,
          CountrySupported                  TFlags,
          ValidlyFormed                     TFlags,
          Matched                           TFlags,
          Resolved                          TFlags,
          Inserted                          TFlags,
          MultiUnitBase                     TFlags,
          ZIP11Match                        TFlags,
          ZIP4Match                         TFlags,
          UniqueZIP                         TFlags,
          StreetAddress                     TFlags,
          RRConversion                      TFlags,
          AddressType                       TTypeCode,
          AddressPrecision                  TName,
          MultipleMatches                   TFlags,

          ValidationDetails                 TMessage);

begin /* pr_API_FedEx2_AddressValidation_ProcessResponse */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vUserId      = system_user,
         @vTranCount   = @@trancount;

  if (@vTranCount = 0) begin transaction;

  /* #Notifications hold the carrier response Notifications */
  if (object_id('tempdb..#Notifications') is null) select * into #Notifications from @ttNotifications;
  if (object_id('tempdb..#AddressValidationResponse') is null) select * into #AddressValidationResponse from @ttAddressValidationResponse;
  if (object_id('tempdb..#Validations') is null) select * into #Validations from @ttValidations;

  /* Get Transaction Info */
  select @vContactId       = EntityId,
         @vContactRefId    = EntityKey,
         @vRawResponseJSON = RawResponse,
         @vBusinessUnit    = BusinessUnit,
         @vModifiedDate    = ModifiedDate,
         @vUserId          = Modifiedby
  from APIOutboundTransactions
  where (RecordId = @TransactionRecordId);

  select @vRevertOrderToDownload = dbo.fn_Controls_GetAsBoolean('AddressValidation', 'RevertOrderToDownload', 'No', @vBusinessUnit, @vUserId),
         @vExportOnAddressError  = dbo.fn_Controls_GetAsBoolean('AddressValidation', 'ExportOnAddressError',  'No', @vBusinessUnit, @vUserId);

  /*-------------------- Notifications --------------------*/
  /* Get all the notifications into a hash table */
  exec pr_API_FedEx2_Response_GetNotifications @vRawResponseJSON, @vBusinessUnit, @vUserId, @vSeverity out, @vNotifications out, @vNotificationDetails output;

  /*-------------------- Load Response --------------------*/
  insert into #AddressValidationResponse
              (TransactionId, ClientReferenceId, ContactId, ContactRefId, AddressLine1, AddressLine2, AddressLine3, City, State, Zip, ZipBase,
               ZipAddOn, ZipDeliveryPoint, Country, Classification, GeneralDelivery, NormalizedStatusNameDPV, StandardizedStatusNameMatchSource,
               ResolutionMethodName, POBox, POBoxOnlyZIP, SplitZIP, SuiteRequiredButMissing, InvalidSuiteNumber, ResolutionInput,
               DPV, DataVintage, MatchSource, CountrySupported, ValidlyFormed, Matched, Resolved, Inserted, MultiUnitBase, ZIP11Match, ZIP4Match,
               UniqueZIP, StreetAddress, RRConversion, AddressType, AddressPrecision, MultipleMatches)
    select TransactionId, ClientReferenceId, @vContactId, @vContactRefId, AddressLine1, AddressLine2, AddressLine3, City, State, Zip, ZipBase,
           ZipAddOn, ZipDeliveryPoint, Country, Classification, GeneralDelivery, NormalizedStatusNameDPV, StandardizedStatusNameMatchSource,
           ResolutionMethodName, POBox, POBoxOnlyZIP, SplitZIP, SuiteRequiredButMissing, InvalidSuiteNumber, ResolutionInput,
           DPV, DataVintage, MatchSource, CountrySupported, ValidlyFormed, Matched, Resolved, Inserted, MultiUnitBase, ZIP11Match, ZIP4Match,
           UniqueZIP, StreetAddress, RRConversion, AddressType, AddressPrecision, MultipleMatches
  from OPENJSON(@vRawResponseJSON, '$')
  with
  (
    TransactionId            TName          '$.transactionId',
    ResolvedAddressesJSON    TNVarchar      '$.output.resolvedAddresses' as json
  )
  as AddressValidation
  CROSS APPLY OPENJSON(AddressValidation.ResolvedAddressesJSON)
  with
  (
    ClientReferenceId                 TRecordId      '$.customerTransactionId',
    AddressLine1                      TAddressLine   '$.streetLinesToken[0]',
    AddressLine2                      TAddressLine   '$.streetLinesToken[1]',
    AddressLine3                      TAddressLine   '$.streetLinesToken[2]',
    City                              TCity          '$.city',
    State                             TState         '$.stateOrProvinceCode',
    Zip                               TZip           '$.postalCode',
    ZipBase                           TZip           '$.parsedPostalCode.base',
    ZipAddOn                          TZip           '$.parsedPostalCode.addOn',
    ZipDeliveryPoint                  TZip           '$.parsedPostalCode.deliveryPoint',
    Country                           TCountry       '$.countryCode',
    Classification                    TName          '$.classification',
    GeneralDelivery                   TFlags         '$.generalDelivery',
    NormalizedStatusNameDPV           TFlags         '$.normalizedStatusNameDPV',
    StandardizedStatusNameMatchSource TName          '$.standardizedStatusNameMatchSource',
    ResolutionMethodName              TFlags         '$.resolutionMethodName',
    AttributesJSON                    TNVarchar      '$.attributes' as json
  )
  as AddressValidationAttributes
  CROSS APPLY OPENJSON(AttributesJSON)
  with
  (
    POBox                             TFlags         '$.POBox',
    POBoxOnlyZIP                      TFlags         '$.POBoxOnlyZIP',
    SplitZIP                          TFlags         '$.SplitZIP',
    SuiteRequiredButMissing           TFlags         '$.SuiteRequiredButMissing',
    InvalidSuiteNumber                TFlags         '$.InvalidSuiteNumber',
    ResolutionInput                   TName          '$.ResolutionInput',
    DPV                               TFlags         '$.DPV',
    DataVintage                       TName          '$.DataVintage',
    MatchSource                       TName          '$.MatchSource',
    CountrySupported                  TFlags         '$.CountrySupported',
    ValidlyFormed                     TFlags         '$.ValidlyFormed',
    Matched                           TFlags         '$.Matched',
    Resolved                          TFlags         '$.Resolved',
    Inserted                          TFlags         '$.Inserted',
    MultiUnitBase                     TFlags         '$.MultiUnitBase',
    ZIP11Match                        TFlags         '$.ZIP11Match',
    ZIP4Match                         TFlags         '$.ZIP4Match',
    UniqueZIP                         TFlags         '$.UniqueZIP',
    StreetAddress                     TFlags         '$.StreetAddress',
    RRConversion                      TFlags         '$.RRConversion',
    AddressType                       TTypeCode      '$.AddressType',
    AddressPrecision                  TName          '$.AddressPrecision',
    MultipleMatches                   TFlags         '$.MultipleMatches'
  );

  /* Address Attibutes may give additional info on why the address is incorrect. Capture that
     info so that user can easily see it without having to review the AVResponse JSON

     If the address returned includes the following values for the below attributes, then the address is valid:
     Address State is Standardized
     Attributes of Resolved address are True
     Delivery Point Valid (DPV) is True
     Interpolated Address is False -  NOT IMPLEMENTED YET
  */
  update #AddressValidationResponse
  set ValidationDetails = concat_ws(',', iif(Resolved             = 'false', 'UnableToResolve',        null),
                                         iif(DPV                  = 'false', 'NotAValidDeliveryPoint', null),
                                         iif(InvalidSuiteNumber   = 'true',  'InvalidSuiteNumber',     null),
                                         iif(MultipleMatches      = 'true',  'MultipleMatches',        null),
                                         iif(POBoxOnlyZIP         = 'true',  'POBoxOnlyZIP',           null),
                                         iif(CountrySupported     = 'false', 'CountryNoSupported',     null),
                                         iif(StreetAddress        = 'false', 'NotAStreetAddress',      null)
                                   );

  /* Update the Contacts with validated info
     AddressType Valid Values:
     RAW          - address country not supported.
     NORMALIZED   - address country supported, but unable to match the address against reference data
     STANDARDIZED - address service was able to successfully match the address against reference data */
  if (coalesce(@vSeverity, '') not in ('Error', 'Failure', 'Fault'))
    begin
      update C
      set AddressLine1              = iif((AV.AddressType = 'STANDARDIZED') and (C.AddressLine1 <> AV.AddressLine1), AV.AddressLine1, C.AddressLine1),
          State                     = iif((AV.AddressType = 'STANDARDIZED') and (C.State <> AV.State),               AV.State,        C.State),
          City                      = iif((AV.AddressType = 'STANDARDIZED') and (C.City <> AV.City),                 AV.City,         C.City),
          Zip                       = iif((AV.AddressType = 'STANDARDIZED') and (C.Zip <> AV.Zip),                   AV.Zip,          C.Zip),
          Country                   = iif((AV.AddressType = 'STANDARDIZED') and (C.Country <> AV.Country),           AV.Country,      C.Country),
          AddrClassification        = AV.Classification,
          Residential               = iif(AV.Classification = 'Residential', 'Y', Residential),
          @vAddressValidationStatus =
          AVStatus                  = case when (AV.AddressType = 'STANDARDIZED') then 'Valid'
                                           when (AV.AddressType = 'RAW')          then 'Invalid'
                                           when (AV.AddressType = 'NORMALIZED')   then 'Invalid'
                                           else 'Invalid'
                                      end,
          AVResponse                = @vRawResponseJSON,
          AVDetails                 = concat_ws('-', AV.AddressType, ValidationDetails),
          ModifiedDate              = @vModifiedDate
      from Contacts C, #AddressValidationResponse AV
      where (C.ContactId = @vContactId);
    end
  else
    begin
      update C
      set AddrClassification        = AV.classification,
          @vAddressValidationStatus =
          AVStatus                  = 'Failed',
          AVResponse                = @vRawResponseJSON,
          AVDetails                 = AV.ValidationDetails,
          ModifiedDate              = @vModifiedDate
      from Contacts C, #AddressValidationResponse AV
      where (C.ContactId = @vContactId)
    end

  update APIOutboundTransactions
  set TransactionStatus = iif(@vSeverity in ('Success', 'Error'), 'Success', 'Failed')
  where (RecordId = @TransactionRecordId);

  /* Log in AT and/or Notifications */
  exec pr_API_FedEx2_LogResponse default, 'AT_FedEx2_AddressValidation', @vSeverity, @vBusinessUnit, @vUserId,
                                 'Contact', @vContactId, @vContactRefId;

  /* When an address is invalid, then flag all the respective Orders shipping to that address as well */
  insert into #Validations (EntityType, EntityId, EntityKey, MessageName, Value1, Value2, Value3)
    select distinct 'Order', OH.OrderId, OH.PickTicket, 'Order_AddressValidation_Invalid', OH.PickTicket, C.ContactRefId,
           substring(C.AVDetails, 1, 120 /* TDescription */)
    from OrderHeaders OH
      join Contacts C on (OH.ShipToId = C.ContactRefId) and (C.ContactType = 'S') and (C.AVStatus in ('Invalid', 'Ambiguous'))
    where (OH.Archived = 'N') and
          (OH.ShipToId = @vContactRefId) and
          (OH.BusinessUnit = @vBusinessUnit) and
          (OH.Status not in ('S' /* Shipped */, 'X' /* Canceled */)) and
          (OH.ShipVia like 'Fed%');

  /* Save Validations to Notifications */
  exec pr_Notifications_SaveValidations 'Order', null /* OrderId */, null /* PickTicket */, 'NO', 'AddressValidation', @vBusinessUnit, @vUserId;

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
  if ((@vExportOnAddressError = 'Y') and (@vAddressValidationStatus in ('Invalid')))
    begin
      /* Build temp table to be similar to table Exports */
      create table #ExportRecords (ExpRecordId int identity(1, 1) not null);
      exec pr_PrepareHashTable 'Exports', '#ExportRecords';

      /* Generate the Error Transactions for OrderHeaders.
         Value3: Mapped with Validation Details */
      insert into #ExportRecords (TransType, TransEntity, TransQty, OrderId, Comments, ShipVia, CreatedBy)
        select 'PTError', 'OH', OH.NumUnits, OH.OrderId, V.Value3, OH.ShipVia, @vUserId
        from #Validations V
          join OrderHeaders OH on (V.EntityId = OH.OrderId);

      /* Insert Records into Exports table */
      exec pr_Exports_InsertRecords 'PTError', null, @vBusinessUnit;
    end

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_FedEx2_AddressValidation_ProcessResponse */

Go
