/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/27  RKC     pr_Shipping_ShipManifest_GetDetails, pr_Shipping_GetBoLDataCustomerOrderDetails: Made changes to get the correct Weight (HA-2650)
  2021/03/28  TK      pr_Shipping_GetBoLDataCustomerOrderDetails: Changes to fn_GenerateSequence data set (HA-2471)
  2021/03/27  PHK     pr_Shipping_GetBoLData: Changes to get SCAC (HA-2469)
  2021/03/23  MS      pr_Shipping_GetBoLData, pr_Shipping_GetBoLData_V3: Made changes to get ActionId to evaluate printing ConsolidatedAddress for BoLs (HA-2386)
  2021/03/15  RV      pr_Shipping_GetBoLData: Made changes to return the flags for suplement pages (HA-1257)
  2021/03/11  PHK     pr_Shipping_GetBoLData: Changes to print ConsolidatedAddress (HA-2098)
  2021/03/01  AY      pr_Shipping_GetBoLData: Finalize changes for consolidator address (HA-2098)
  2021/02/23  AY      pr_Shipping_GetBoLData: Print ShipToName with Consolidator addres (HA-2054)
  2021/02/22  AY      pr_Shipping_GetBoLData: Fix issues with consolidator address (HA-2042)
  2020/02/01  RT      pr_Shipping_GetBoLData: Rules to get the BoL Reports (FB-2225)
                      pr_Shipping_GetBoLDataCarrierDetails and pr_Shipping_GetBoLDataCustomerOrderDetails: Included BOD reference feilds (FB-2225)
  2021/02/22  AY      pr_Shipping_GetBoLData: Fix issues with consolidator address (HA-2042)
  2020/12/10  PHK     pr_Shipping_GetBoLDataCustomerOrderDetails: Made changes to order details to fix the sort seq updating issue (HA-1731)
  2020/11/06  PHK     pr_Shipping_GetBoLData: Made changes to get the BoLType (HA-1558)
  2020/08/10  NB      pr_Shipping_GetBoLData_V3: added procedure for V3 Reports_GetData generic implementation(CIMSV3-1022)
  2020/07/07  RBV     pr_Shipping_GetBoLData; Changed the DataType TFlag to TControlCode (HA-1023)
  2020/06/30  RBV     pr_Shipping_GetBoLData; Added LoadNumber to Print on Master BOL Report (HA-896)
  2018/07/27  RT      pr_Shipping_GetBoLData: Added LoadType and LoadCarrier to the Rule data and changed the RuleSetType to VICSBoLFormat
                      pr_Shipping_GetBolDataCustomerOrderDetails: Made changes to print fixed records on first and Supplement page using controls , made a minor change in the records count
                      pr_Shipping_GetBolDataCarrierDetails: Made changes to print fixed records on first and Supplement page (S2GCA-112)
  2018/06/08  VM      pr_Shipping_GetBoLData: Return Reportsxml with report to print (S2G-931)
  2018/05/11  RT      pr_Shipping_GetBoLData: Made changes to get the Notes through the fn_Notes_GetBoLNotes function for Special Instructions(S2G-829)
  2016/07/25  KN      pr_Shipping_GetBoLData: Added BoLTypesToPrint for selecting Bol types to print (FB-726)
  2015/07/28  RV      pr_Shipping_GetBoLData: Separate the special instructions line1 and line2
  2015/07/24  RV      pr_Shipping_GetBolDataCustomerOrderDetails: Ceiling the Weight.
                      pr_Shipping_GetBolDataCarrierDetails: Ceiling the Weight.
                      pr_Shipping_GetBoLData: Add FOB to output XML (ACME-244).
  2013/04/02  PKS     pr_Shipping_GetBoLData: Renamed Address to AddressLine1 and AddressLine2, ShippedDate added to corresponding XMLs
  2013/03/28  AY      pr_Shipping_GetBoLData: Print consolidation address
  2013/01/30  YA      pr_Shipping_GetBoLData: Removed this check for displaying 'XXXX..' and print Bol number always for now.
                        Modified to display Client LoadId on the Master BoL.
                        Modified to display supplement page on master BoL.
  2013/01/25  TD      pr_Shipping_GetBoLData:Sending CID number in shiptoaddress.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_GetBoLData') is not null
  drop Procedure pr_Shipping_GetBoLData;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipping_GetBOLData: This proc will return the BoL info to be printed
    on the main page and supplement pages for all BoLs of the given Loads OR all
    given BoLs in the order they are presented here. For a particular Load, it
    would return the Master BoL data followed by the Underlying BoL data.

  Note: We have conditions for to Build Supplement pages based on the N,Y,L.
    N- No Supplement Page (<= 5 rows), Y-Normal - Common Supplement (< 15 Rows), L-Large - Single Supplement (>= 15 Rows.)

    Sample XML for Input Param xmlRequest:
     <PrintVICSBoL>
       <Loads>
         <LoadId>2</LoadId>
       </Loads>
       <BoLs>
         <BoLId>1</BoLId>
         <BoLNumber>21</BoLNumber>
       </BoLs>
       <BoLTypesToPrint>M</BoLTypesToPrint> M - returns Master bols only , U - Underlying bols only , MU Master bol and Underlying bols
     </PrintVICSBoL>
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_GetBoLData
  (@xmlRequest  TXML,
   @xmlResult   TXML   output)
as
  declare @ReturnCode                 TInteger,
          @MessageName                TMessageName,
          @vDebug                     TControlValue = 'N',

          /* entity variables */
          @vBoLId                     TBoLId,
          @vBoLNumber                 TBoLNumber,
          @vBoLType                   TTypeCode,
          @vVICSBoLNumber             TBoLNumber,
          @vBoLStatus                 TStatus,
          @vBoLCID                    TBoLCID,
          @vBoLTypesToPrint           TTypeCode,
          @vReport                    TResult,
          @xmlData                    TXML,

          @vLoadId                    TLoadId,
          @VLoadNumber                TLoadNumber,
          @vCurrLoadId                TLoadId,
          @vLoadStatus                TStatus,
          @vPrevLoadId                TLoadId,
          @vLoadType                  TTypeCode,
          @vLoadCarrier               TCarrier,
          @vLoadAccount               TAccount,
          @vWarehouse                 TWarehouse,
          @vBusinessUnit              TBusinessUnit,
          @vLoadConsolidatorAddress   TContactRefId,
          @vShipToName                TName,

          @vShipFromAddressId         TRecordId,
          @vShipToAddressId           TRecordId,
          @vShipToLocation            TShipToLocation,
          @vBillToAddressId           TRecordId,
          @vShipVia                   TShipVia,
          @vSCAC                      TSCAC,
          @vFreightTerms              TLookUpCode,

          @vProNumber                 TProNumber,
          @vSealNumber                TSealNumber,

          @IsMasterBoL                TFlag,
          @vSpecialInstructionsLine1  TVarchar,
          @vSpecialInstructionsLine2  TVarchar,
          @vVICSBoLNumbersList        varchar(Max),
          @vClientLoad                TLoadNumber,
          @vShippedDate               TDateTime,
          @vConsolidatorAddressId     TRecordId,
          /* Cursor Variables */
          @vCurrBoLId                 TBoLId,
          @vRecordId                  TRecordId,
          @vUseConsolidatorAddressForShipTo
                                      TControlValue,
          /* xml processing variables */
          @vShipFromxml               XML,
          @vShipToxml                 XML,
          @vConsolidatorAddressxml    XML,
          @vThirdPartyBillToxml       XML,
          @vCustomerOrderDetailsxml   XML,
          @vCustomerOrderTotalsxml    XML,
          @vCarrierDetailsxml         XML,
          @vCarrierTotalsxml          XML,
          @vSupplCustomerDetailsxml   XML,
          @vSupplCustomerTotalsxml    XML,
          @vSupplCarrierDetailsxml    XML,
          @vSupplCarrierTotalsxml     XML,
          @vAdditionalInstructions    XML,
          @Reportsxml                 XML,

          @vBoLData                   XML,
          @vResultXml                 XML,
          @vCurrentBoLXml             XML,
          @vRequestKeyData            XML,
          @IsSupplementForCustomers   TFlag,
          @IsSupplementForCarriers    TFlag,
          @vHasSuplementForCustomers  TFlag,
          @vHasSuplementForCarriers   TFlag,
          @vFOB                       TControlValue,
          @vAction                    TName;

  declare @CarrierDetails             TBoLCarrierDetails;
  declare @CustomerOrderDetails       TBoLCustomerOrderDetails;
  declare @ttMarkers                  TMarkers;

  declare @ttBoLs table (BoLId       TBoLId,
                         BolType     TTypeCode,
                         LoadId      TLoadId,
                         LoadStatus  TStatus,
                         RecordId    TInteger identity(1,1));

  declare @ttBoLsToProcess table (BoLId       TBoLId,
                                  LoadId      TLoadId,
                                  MasterBoL   TBoLNumber,
                                  BoLType     TFlag);

  declare @ttEntityData  table (EntityKey   varchar(50),
                                EntityType  varchar(50),
                                RecordId    Integer identity(1,1));
begin
  select @ReturnCode = 0,
         @vRecordId  = 0;

  if (@xmlRequest is null)
    begin
      set @MessageName = 'InvalidInputData';
      goto ErrorHandler;
    end

  /* Create required hash tables if they does not exist */
  if (object_id('tempdb..#Markers') is null) select * into #Markers from @ttMarkers;

  /* Check if in debug mode */
  exec pr_Debug_GetOptions @@ProcId, null /* @Operation */, @vBusinessUnit, @vDebug output;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'pr_Shipping_GetBoLData_Start', @@ProcId;

  /* Read the given Loads or BoLs into a temp table for processing distinguishing
     between the two using EntityType */
  select @vRequestKeyData  = convert(xml, @xmlRequest);

  /* Get BolType Flag & Options */
  select @vBoLTypesToPrint = Record.Col.value('BoLTypesToPrint[1]',  'TTypeCode'),
         @vAction          = Record.Col.value('(Options/Action)[1]', 'TName')
  from @vRequestKeyData.nodes('/PrintVICSBoL') as Record(Col);

  /* Get the user selected Loads from the input */
  insert into @ttEntityData (EntityKey, EntityType)
    select Record.Col.value('.', 'TRecordId'), 'Load'
    from @vRequestKeyData.nodes('/PrintVICSBoL/Loads/LoadId') as Record(Col);

  /* Get the user selected BoLs */
  insert into @ttEntityData (EntityKey, EntityType)
    select Record.Col.value('.', 'TRecordId'), 'BoL'
    from @vRequestKeyData.nodes('/PrintVICSBoL/BoLs/BoLId') as Record(Col);

  /* If there are no entities selected for printing BoLs, exit */
  if ((select count(*) from @ttEntityData) <= 0)
    begin
      set @MessageName = 'NoValidInputDataInRequest';
      goto ErrorHandler;
    end;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'GetLoadBols_Start', @@ProcId;

  /* Get all the BoLs for the corresponding Loads send in input */
  insert into @ttBoLs (BoLId, BoLType, LoadId)
    select B.BoLId, B.BoLType, B.LoadId
    from BoLs B join @ttEntityData ED on (B.LoadId = ED.EntityKey)
    where (ED.EntityType = 'Load')
    order by B.LoadId, B.BoLType, B.BoLId;

  /* Add all the specific BoLs sent in the input */
  insert into @ttBoLs (BoLId, BoLType, LoadId)
    select B.BoLId, B.BoLType, B.LoadId
    from BoLs B join @ttEntityData ED on (B.BoLId = ED.EntityKey)
    where (ED.EntityType = 'BoL')
    order by B.LoadId, B.BoLType, B.BoLId;

  /* Eliminate the cancelled Loads */
  delete TB from @ttBols TB join Loads L on TB.LoadId = L.LoadId and (L.Status = 'X' /* Canceled */);

  /* If specific BoL Type is requested, then eliminate the other type */
  if (@vBoLTypesToPrint is not null)
    delete TB from @ttBoLs TB where (charindex(TB.BolType, @vBoLTypesToPrint) = 0);

  /* Iterate thru each BoL */
  while (exists (select * from @ttBoLs where RecordId > @vRecordId))
    begin
      /* Get the next BoL to process */
      select top 1 @vRecordId  = RecordId,
                   @vCurrBoLId = BoLId,
                   @vLoadId    = LoadId
      from @ttBoLs
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Get BoL Details */
      select @vBoLType                  = BoLType,
             @vFreightTerms             = FreightTerms,
             @vShipFromAddressId        = ShipFromAddressId,
             @vShipToAddressId          = ShipToAddressId,
             @vShipToLocation           = ShipToLocation,
             @vBillToAddressId          = BillToAddressId,
             @vProNumber                = nullif(ProNumber, ''),
             @vSealNumber               = nullif(SealNumber, ''),
             @vVICSBoLNumber            = VICSBoLNumber,
             @vBoLNumber                = BoLNumber,
             @vSpecialInstructionsLine1 = case
                                            when (BoLType = 'M' /* Master */) then
                                              'Underlying Bill of Lading Numbers:'
                                            when ((BoLType = 'U' /* Underlying */) and (MasterBoL is not null)) then
                                              'Master BoL :' + MasterBoL
                                            else
                                              ''
                                          end,
            @vSpecialInstructionsLine2  = coalesce(nullif(BoLInstructions, ''), dbo.fn_Notes_GetBoLNotes(BoLNumber, BusinessUnit)),
            @IsMasterBoL                = case when BoLType = 'M' then 'Y' else 'N' end,
            @vVICSBoLNumbersList        = MasterBoL,
            @vFOB                       = coalesce (FOB, '')
      from BoLs
      where (BoLId = @vCurrBoLId);

      /* Get Load info */
      select @vClientLoad              = ClientLoad,
             @vBoLCID                  = BoLCID,
             @vLoadNumber              = LoadNumber,
             @vShipVia                 = ShipVia,
             @vLoadType                = LoadType,
             @vShippedDate             = ShippedDate,
             @vWarehouse               = FromWarehouse,
             @vBusinessUnit            = BusinessUnit,
             @vLoadAccount             = Account,
             @vLoadConsolidatorAddress = ConsolidatorAddressId
      from Loads
      where (LoadId = @vLoadId);

      /* Get the Carrier for the Load */
      select @vLoadCarrier = Carrier,
             @vSCAC        = SCAC
      from ShipVias
      where (ShipVia = @vShipVia) and (BusinessUnit = @vBusinessUnit);

      /* If the Load has a consolidator, then get the id */
      if (@vLoadConsolidatorAddress is not null)
        select @vConsolidatorAddressId = ContactId
        from Contacts
        where (ContactType = 'FC') and
              (ContactRefId = @vLoadConsolidatorAddress) and
              (BusinessUnit = @vBusinessUnit);

      /* Get BoL data here */
      set @vBoLData = (select @vBoLNumber                               as BoLNumber,
                              @vBoLType                                 as BoLType,
                              @vVICSBoLNumber                           as VICSBoLNumber,
                              @vBoLCID                                  as BoLCID,
                              @vClientLoad                              as ClientLoad,
                              @vLoadNumber                              as LoadNumber,
                              coalesce(L.ShipViaDescription, L.ShipVia) as CarrierName,
                              L.TrailerNumber                           as TrailerNumber,
                              coalesce(@vSealNumber, L.SealNumber)      as SealNumbers,
                              coalesce(@vProNumber, L.ProNumber)        as PRONumber,
                              L.ShipVia +
                              coalesce(coalesce(@vProNumber, L.PRONumber), '')
                                                                        as PRONumberBarcode,
                              '(9012K) '+
                              L.ShipVia +
                              coalesce(coalesce(@vProNumber, L.PRONumber), '')
                                                                        as PRONumberBarcodeText,
                              @vSCAC                                    as SCAC,
                              coalesce(@vShippedDate, current_timestamp)
                                                                        as ShippedDate,
                              @vFreightTerms                            as FreightTerms,
                              @vSpecialInstructionsLine1                as SpecialInstructions,
                              '$0.00'                                   as CODAmount,
                              ''                                        as FeeTerms,    -- It depends on the COD amount..
                              ''                                        as CustomerCheckAcceptance,
                              ''                                        as TrailerLoaded,
                              ''                                        as FreightCounted,
                              @IsMasterBoL                              as HasMasterBoL
                       from vwLoads L
                       where (L.LoadId = @vLoadId)
                       for xml raw('BoLData'), elements);

      /* For Master BoL, generate list of Underlying BoLs */
      /* If we have more than 6 bols for a load then we need show in report supplement */
      if (@vBoLType = 'M'/* Master */)
        begin
          if ((select count(*) from BoLs  where ((LoadId = @vLoadId) and (BoLType = 'U' /* Underlying */) )) <= 6)
            begin
              select @vVICSBoLNumbersList = coalesce(@vVICSBoLNumbersList + ', ', '') + VICSBoLNumber
              from BoLs
              where ((LoadId = @vLoadId) and (BoLType = 'U' /* Underlying */));
            end

          select @vSpecialInstructionsLine2 = @vVICSBoLNumbersList;
        end

      /* To obtain the ConsolidatorAddress for the Underlying BoL's & to print the Name as ShipToName only */
      if ((@vBoLType = 'U' /* Underlying BoL */) and (@vAction = 'Loads_Rpt_BoL_Account'))
        begin
          select @vShipToName = Name from Contacts where (ContactId = @vShipToAddressId);
          select @vShipToAddressId = @vConsolidatorAddressId;
        end

      /* Build xml here for additional instructions */
      set @vAdditionalInstructions = (select @vSpecialInstructionsLine1  as Line1,
                                             @vSpecialInstructionsLine2  as Line2,
                                             @vBoLNumber                 as BoLNumber
                                      for xml raw('AdditionalInstructions'), elements);

      /* There may be multiple formats of BoL Reports to be printed, primarily based
         upon the Carrier. use rules to determine the format to print */
      select @xmlData = dbo.fn_XMLNode('RootNode',
                          dbo.fn_XMLNode('LoadId',               @vLoadId) +
                          dbo.fn_XMLNode('LoadType',             @vLoadType) +
                          dbo.fn_XMLNode('Carrier',              @vLoadCarrier) +
                          dbo.fn_XMLNode('ShipVia',              @vShipVia) +
                          dbo.fn_XMLNode('Account',              @vLoadAccount) +
                          dbo.fn_XMLNode('ConsolidatorAddress',  @vLoadConsolidatorAddress) +
                          dbo.fn_XMLNode('Warehouse',            @vWarehouse) +
                          dbo.fn_XMLNode('BusinessUnit',         @vBusinessUnit));

      /* Build xml here for Report to print by using rules */
      exec pr_RuleSets_Evaluate 'VICSBoLFormat', @xmlData, @vReport output;

      select @Reportsxml = (select @vReport as Report
                            for xml raw('REPORTS'), elements);

      /* Ship From Address */
      set @vShipFromxml = (select Name                 as Name,
                                  AddressLine1         as AddressLine1,
                                  AddressLine2         as AddressLine2,
                                  CityStateZip         as CityStateZip,
                                  ''                   as SIDNumber,
                                  coalesce (@vFOB, '') as FOB,
                                  @vBoLNumber          as BoLNumber
                           from vwShipFromAddress
                           where (ContactId = @vShipFromAddressId)
                           for xml raw('ShipFromAddress'), elements);

      /* If the Load has a consolidator, then optionally, use the Consolidator address for Ship To addresss */
      if (@vUseConsolidatorAddressForShipTo = 'Y')
        begin
          /* Even if we use the consolidator address, the ShipToName still is the original ShipTo name */
          select @vShipToName = Name from Contacts where (ContactId = @vShipToAddressId);
          select @vShipToAddressId = @vConsolidatorAddressId;
        end

      /* Ship To Address */
      set @vShipToxml = (select coalesce (@vShipToName, Name) as Name,
                                AddressLine1                  as AddressLine1,
                                AddressLine2                  as AddressLine2,
                                CityStateZip                  as CityStateZip,
                                @vClientLoad                  as CIDNumber,
                                coalesce (@vFOB, '')          as FOB,
                                @vShipToLocation              as LocationNumber, /* Ship To Store Code */
                                @vBoLNumber                   as BoLNumber
                         from Contacts
                         where (ContactId = @vShipToAddressId)
                         for xml raw('ShipToAddress'), elements);

      /* Consolidator Address */
      set @vConsolidatorAddressxml = (select Name                   as Name,
                                             AddressLine1           as AddressLine1,
                                             AddressLine2           as AddressLine2,
                                             CityStateZip           as CityStateZip,
                                             @vClientLoad           as CIDNumber,
                                             coalesce (@vFOB, '')   as FOB,
                                             @vShipToLocation       as LocationNumber, /* Ship To Store Code */
                                             @vBoLNumber            as BoLNumber
                                      from Contacts
                                      where (ContactId = @vConsolidatorAddressId)
                                      for xml raw('ConsolidatorAddress'), elements);

      /* ThirdParty To BillTo */
      set @vThirdPartyBillToxml = (select Name         as Name,
                                          AddressLine1 as AddressLine1,
                                          AddressLine2 as AddressLine2,
                                          CityStateZip as CityStateZip,
                                          @vBoLNumber  as BoLNumber
                                   from vwBillToAddress
                                   where (ContactId = @vBillToAddressId)
                                   for xml raw('ThirdPartyBillToAddress'), elements);

      if (@vThirdPartyBillToxml is null)
        begin
          set @vThirdPartyBillToxml = (select ''          as Name,
                                              ''          as AddressLine1,
                                              ''          as AddressLine2,
                                              ''          as CityStateZip,
                                              @vBoLNumber as BoLNumber
                                       for xml raw('ThirdPartyBillToAddress'), elements );
        end

      if (@vShipToxml is null)
        begin
          set @vShipToxml = (select ''                   as Name,
                                    ''                   as AddressLine1,
                                    ''                   as AddressLine2,
                                    ''                   as CityStateZip,
                                    @vClientLoad         as CIDNumber,
                                    coalesce (@vFOB, '') as FOB,
                                    ''                   as LocationNumber, /* Ship To Store Code */
                                    @vBoLNumber          as BoLNumber
                             for xml raw('ShipToAddress'), elements );
        end

      if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'GetBoLDataCustomerOrderDetails_Start', @@ProcId;

      /* Get Customer details here */
      exec pr_Shipping_GetBoLDataCustomerOrderDetails @vCurrBoLId, @vReport, @IsSupplementForCustomers output,
                                                      @vCustomerOrderDetailsxml output, @vCustomerOrderTotalsxml output,
                                                      @vSupplCustomerDetailsxml output, @vSupplCustomerTotalsxml output;

      if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'GetBoLDataCarrierDetails_Start', @@ProcId;

      /* Get Carrier Details here */
      exec pr_Shipping_GetBoLDataCarrierDetails @vCurrBoLId, @vReport, @IsSupplementForCarriers output,
                                                @vCarrierDetailsxml output, @vCarrierTotalsxml output,
                                                @vSupplCarrierDetailsxml output, @vSupplCarrierTotalsxml output;

      /* If there is a supplement for Customer Orders but not Carrier Details,
         then generate a blank supplement for Carrier Details for proper pagination
         and vice-versa */

      /* Common Supplement - Supplement Page with both Customer Order Details and Carrier Details
         Single Supplement - Supplement Page with only Customer Order Details or Carrier Details
      */

      /* If Customer Details are to be printed on the Common Supplement and  Carrier Details are such that
         they do not need a supplement, then ensure that Carrier Details for Common Supplement
         are returned with a blank records dataset to fill in the Carrer Details area of Common Supplement */
      if ((@IsSupplementForCustomers = 'Y' /* Yes */) and (@IsSupplementForCarriers = 'N' /* No */ ))
        begin
          exec pr_BoL_GetCarrierDetailsAsXML @CarrierDetails, @vBoLNumber,
                                             'Y' /* Supplement */, null /* Rows */,
                                             @vSupplCarrierDetailsxml output;
           /* We need to build a supplement xml for the Carriers detail totals..if the Customers alone
            has supplement page */
          select @vSupplCarrierTotalsxml = replace(convert(varchar(max), @vCarrierTotalsxml),
                                                   'CarrierDetailTotals', 'SupplementCarrierDetailTotals');

          if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'GetCarrierDetailsAsXML_End', @@ProcId;
        end
      else
      /* This is the vice versa of the above condition
         If Carrier Details are to be printed on the Common Supplement and  Customer Order Details are such that
         they do not need a supplement, then ensure that Customer Order Details for Common Supplement
         are returned with a blank records dataset to fill in the Customer Order Details area of Common Supplement */
      if ((@IsSupplementForCustomers = 'N' /* No */) and (@IsSupplementForCarriers = 'Y' /* Yes */ ))
        begin
          exec pr_BoL_GetCustomerOrderDetailsAsXML @CustomerOrderDetails, @vBoLNumber,
                                                   'Y' /* Norml */, null /* Rows */,
                                                   @vSupplCustomerDetailsxml output;

         /* We need to build a supplement xml for the customer orderdetail totals..if the carriers alone
            has supplement page */
          select @vSupplCustomerTotalsxml = replace(convert(varchar(max), @vCustomerOrderTotalsxml),
                                                    'CustomerOrderTotals', 'SupplementCustomerOrderTotals');

          if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'GetCustomerOrderDetailsAsXML_End', @@ProcId;
        end
      else
      /* If Customer Details are to be printed on the Single Supplement and  Carrier Details are smaller in
         count which can be printed on Common Supplement, then transform Carrier Details for such that blank records
         are added to the dataset to fill in the Carrer Details area of Single Supplement

         The idea is, if Customer Details is getting printed to a Single Supplement, then print the Carrier Details
         to Single Supplement as well */
      if ((@IsSupplementForCustomers = 'L' /* Large */) and (@IsSupplementForCarriers = 'Y' /* Normal */ ))
        begin
          exec pr_BoL_GetCarrierDetailsAsXML @CarrierDetails, @vBoLNumber,
                                             'L' /* Supplement */, null /* Rows */,
                                             @vSupplCarrierDetailsxml output;

          if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'GetCarrierDetailsAsXML_Start', @@ProcId;
        end
      else
      /* This is the vice versa of the above condition
         In this case, we have the Carrier Details to be printed on a Single Supplement and Custoemr Order Details are smaller in
         count which can be printed on Common Supplement. Customer Order Details are to be transformed such that blank records
         are added to the dataset to fill in the Customer Order Details area of Single Supplement

         The idea is, if Carrier Details is getting printed to a Single Supplement, then print the Customer Order Details
         to Single Supplement as well */
      if ((@IsSupplementForCustomers = 'Y' /* Normal */) and (@IsSupplementForCarriers = 'L' /* Large */ ))
        begin
          exec pr_BoL_GetCustomerOrderDetailsAsXML @CustomerOrderDetails, @vBoLNumber,
                                                   'L' /* Large */, null /* Rows */,
                                                   @vSupplCustomerDetailsxml output;
        end

      /* Set flags for Suplemnt page for customers required or not based upon the suplement customers xml available */
      if (@vSupplCustomerDetailsxml is null)
        select @vHasSuplementForCustomers = 'N';
      else
        select @vHasSuplementForCustomers = 'Y';

      /* Set flags for Suplemnt page for carriers required or not based upon the suplement carriers xml available */
      if (@vSupplCarrierDetailsxml is null)
        select @vHasSuplementForCarriers = 'N';
      else
        select @vHasSuplementForCarriers = 'Y';

      /* Add the flags to show/hide the suplement pages for customer order and carrier details */
      set @vBoLData.modify('insert <HasSuplementForCustomers>{sql:variable("@vHasSuplementForCustomers")}</HasSuplementForCustomers> into (//BoLData)[1]');
      set @vBoLData.modify('insert <HasSuplementForCarriers>{sql:variable("@vHasSuplementForCarriers")}</HasSuplementForCarriers> into (//BoLData)[1]');

        /* The other conditions where one of the Customer Order Details or Carrier Details has a Single Supplement and the other
           set of Details does not need a Supplement, needs no additional processing. In this scenario, the Non-Supplement Details will
           get printed on the Main Page, and a Single Supplement will get printed for the other details with more than 14 Records */

      /* Build result xml here..*/
      set @vCurrentBoLXml = (select coalesce(@vBoLData, ''),
                                     coalesce(@vShipFromxml,  ''),
                                     coalesce(@vShipToxml,  ''),
                                     coalesce(@vConsolidatorAddressxml,  ''),
                                     coalesce(@vThirdPartyBillToxml,  ''),
                                     coalesce(@vCustomerOrderDetailsxml,  ''),
                                     coalesce(@vCustomerOrderTotalsxml,  ''),
                                     coalesce(@vCarrierDetailsxml,  ''),
                                     coalesce(@vCarrierTotalsxml,  ''),
                                     coalesce(@vSupplCustomerDetailsxml,  ''),
                                     coalesce(@vSupplCustomerTotalsxml,  ''),
                                     coalesce(@vSupplCarrierDetailsxml,  ''),
                                     coalesce(@vSupplCarrierTotalsxml,  ''),
                                     coalesce(@vAdditionalInstructions, ''),
                                     coalesce(@Reportsxml,              '')
                              for xml raw('BoLReportData'), elements );

      /* Cordinate  multiple xmls */
      set @vResultXml =  cast(coalesce(@vResultXml, '') as varchar(max)) +
                         cast (coalesce(@vCurrentBoLXml, '') as  varchar(max));

    end /* next bol */

  /* Build the result xml here with main root */
  set @xmlResult= (select @vResultXml
                   for xml raw('BoLReports'), elements);

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'pr_Shipping_GetBoLData_End', @@ProcId;
  if (charindex('L', @vDebug) > 0) exec pr_Markers_Log @ttMarkers, 'GetBolData', null, null, 'GetBolData', @@ProcId, 'Markers_GetBolData';

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Shipping_GetBoLData */

Go
