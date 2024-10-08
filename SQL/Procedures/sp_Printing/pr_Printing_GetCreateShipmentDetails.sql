/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/03/16  RV      pr_Printing_GetCreateShipmentDetails: Made changes to create shipment based upon the IntegrationMethod and GenerationMethod (FBV3-921)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Printing_GetCreateShipmentDetails') is not null
  drop Procedure pr_Printing_GetCreateShipmentDetails;
Go

/*------------------------------------------------------------------------------
  Proc pr_Printing_GetCreateShipmentDetails: Evaluates the PrintList details in
    input XML and determines if the shipments have to be created, the interface
    to use. May actually create the shipments as well if it is determined to be
    Carrier API with CLR.

 Usage: Shipping Docs - After the user selects the records in the print list to
   print if any of those require the carrier shipments to be created, then this
   procedure is invoked with the user selected print list. If it turns out that
   the shipments are to be created with CIMSSI either DIRECTly or thru ADSI, UI
   the creates and finally does the printing as well by passing the print list
   to pr_Printing_ReprocessPrintListData

  Procedure captures the information of ShipLabels To Insert, invokes generic procedure,
  returns dataset with details of inputs to Create Shipment via CIMSSI or CIMSAPI from caller end
------------------------------------------------------------------------------*/
Create Procedure pr_Printing_GetCreateShipmentDetails
  (@InputXML         TXML)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,
          @vDebug                   TFlags,
          @vxmlRulesData            TXML,
          @vInputXML                XML,
          @vModule                  TName,
          @vOperation               TOperation,
          @vBusinessUnit            TBusinessUnit,
          @vUserId                  TUserId;

  declare @ttPrintList              TPrintList,
          @ttShipLabels             TShipLabels,
          @ttValidations            TValidations;
  declare @ttCreateShipmentDetails table
  (
    Carrier                TCarrier,
    LPNId                  TRecordId,
    LPN                    TLPN,
    OrderId                TRecordId,
    PickTicket             TPickTicket,
    ShipmentType           TFlags,
    LabelTypes             TDescription,
    IntegrationMethod      TName,
    GenerationMethod       TName,
    CarrierInterface       TCarrierInterface,
    APIWorkFlow            TName,
    CarrierInterfaceInput  TVarchar
    );
begin
  select @vInputXML = convert(xml, @InputXML);

  /* Read inputs for generic procedure */
  select @vModule       = Record.Col.value('(Data/Module)[1]',             'TDescription'),
         @vOperation    = Record.Col.value('(Data/Operation)[1]',          'TOperation'),
         @vBusinessUnit = Record.Col.value('(SessionInfo/BusinessUnit)[1]','TBusinessUnit'),
         @vUserId       = Record.Col.value('(SessionInfo/UserId)[1]',      'TUserId')
  from @vInputXML.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vInputXML = null));

  /* Build rules data xml */
  select @vxmlRulesData = dbo.fn_XMLNode('RootNode',
                           dbo.fn_XMLNode('Module',                @vModule) +
                           dbo.fn_XMLNode('Operation',             @vOperation) +
                           dbo.fn_XMLNode('MessageNamePrefix',     'ShipLabel') +
                           dbo.fn_XMLNode('BusinessUnit',          @vBusinessUnit) +
                           dbo.fn_XMLNode('UserId',                @vUserId));

  /* Create hash tables */
  select * into #PrintList from @ttPrintList;
  select * into #ShipLabelsToInsert from @ttShipLabels;
  if (object_id('tempdb..#Validations') is null) select * into #Validations from @ttValidations;

  /* Transfer details of PrintList from InputXML to #PrintList */
  insert into #PrintList(EntityType, EntityKey, EntityId, PrintRequestId, PrintJobId, DocumentClass,
                         DocumentSubClass, DocumentType, DocumentSubType, PrintDataFlag, DocumentFormat, DocumentSchema,
                         PrintData, AdditionalContent, PrinterName, PrinterConfigName, PrinterConfigIP, PrinterPort,
                         PrintProtocol, PrintBatch, NumCopies, SortOrder, InputRecordId, Status,
                         Description, Action, CreateShipment, FilePath, FileName, SortSeqNo,
                         ParentEntityKey, UDF1, UDF2, UDF3, UDF4, UDF5, ParentRecordId)
    select Record.Col.value('EntityType[1]',  'TEntity'), Record.Col.value('EntityKey[1]', 'TEntityKey'),
           Record.Col.value('EntityId[1]', 'TRecordId'), Record.Col.value('PrintRequestId[1]', 'TRecordId'),
           Record.Col.value('PrintJobId[1]', 'TRecordId'), Record.Col.value('DocumentClass[1]', 'TTypeCode'),
           Record.Col.value('DocumentSubClass[1]', 'TTypeCode'), Record.Col.value('DocumentType[1]', 'TTypeCode'),
           Record.Col.value('DocumentSubType[1]', 'TTypeCode'), Record.Col.value('PrintDataFlag[1]', 'TFlags'),
           Record.Col.value('DocumentFormat[1]', 'TName'), Record.Col.value('DocumentSchema[1]', 'TName'),
           Record.Col.value('PrintData[1]', 'TBinary'), Record.Col.value('AdditionalContent[1]', 'TName'),
           Record.Col.value('PrinterName[1]', 'TName'), Record.Col.value('PrinterConfigName[1]', 'TName'),
           Record.Col.value('PrinterConfigIP[1]', 'TName'), Record.Col.value('PrinterPort[1]', 'TName'),
           Record.Col.value('PrintProtocol[1]', 'TName'), Record.Col.value('PrintBatch[1]', 'TInteger'),
           Record.Col.value('NumCopies[1]', 'TInteger'), Record.Col.value('SortOrder[1]', 'TSortOrder'),
           Record.Col.value('InputRecordId[1]', 'TRecordId'), Record.Col.value('Status[1]', 'TStatus'),
           Record.Col.value('Description[1]', 'TDescription'), Record.Col.value('Action[1]', 'TFlags'),
           Record.Col.value('CreateShipment[1]', 'TFlags'), Record.Col.value('FilePath[1]', 'TName'),
           Record.Col.value('FileName[1]', 'TName'), Record.Col.value('SortSeqNo[1]', 'TSortSeq'),
           Record.Col.value('ParentEntityKey[1]', 'TEntityKey'), Record.Col.value('UDF1[1]', 'TUDF'),
           Record.Col.value('UDF2[1]', 'TUDF'), Record.Col.value('UDF3[1]', 'TUDF'),
           Record.Col.value('UDF2[1]', 'TUDF'), Record.Col.value('UDF5[1]', 'TUDF'),
           Record.Col.value('ParentRecordId[1]', 'TRecordId')
      from @vInputXML.nodes('/Root/Data/PrintList/PrintListRecord') as Record(Col)
      OPTION ( OPTIMIZE FOR ( @vInputXML = null ) );

  /* Consider all ShipLabel records with CreateShipment Y as potential inserts into ShipLabels table */
  insert into #ShipLabelsToInsert (EntityId, EntityType, EntityKey, CartonType, SKUId, PackageLength, PackageWidth, PackageHeight,
                                   PackageWeight, PackageVolume, OrderId, PickTicket, TotalPackages, TaskId, WaveId, WaveNo, WaveType, LabelType,
                                   RequestedShipVia, ShipVia, Carrier, IsSmallPackageCarrier, BusinessUnit, CreatedBy, InsertRequired)
    select distinct L.LPNId, 'L' /* LPN */, L.LPN, L.CartonType, L.SKUId, 0.0, 0.0, 0.0,
                    0.0, 0.0, OH.OrderId, OH.PickTicket, OH.LPNsAssigned, L.TaskId, OH.PickBatchId, OH.PickBatchNo, W.WaveType, 'S' /* Ship Label */,
                    OH.ShipVia, OH.ShipVia, S.Carrier, S.IsSmallPackageCarrier, @vBusinessUnit, @vUserId, 'Evaluate'
    from #PrintList PL
      join LPNs L          on (L.LPNId = PL.EntityId) and (PL.EntityType = 'LPN') and
                              (PL.DocumentClass = 'Label') and (PL.DocumentType in ('SPL')) and
                              (L.LPNType = 'S'/* ShipCarton */)
      join OrderHeaders OH on (L.OrderId = OH.OrderId)
      join Waves        W  on (OH.PickBatchId = W.WaveId)
      join ShipVias     S  on (OH.ShipVia = S.ShipVia) and (S.IsSmallPackageCarrier = 'Y')
    where (PL.CreateShipment = 'Y');

  if (object_id('tempdb..#OrdersToValidate') is null)
    select distinct OH.* into #OrdersToValidate
    from #ShipLabelsToInsert SL
      join vwOrderHeaders OH on (SL.OrderId = OH.OrderId);

  /* Rule to evaluate the ship label data */
  exec pr_RuleSets_ExecuteAllRules 'Carrier_Validations', @vxmlRulesData, @vBusinessUnit;

  /* Procedure identifies whether or not to create the Shipment and if so, which Interface
     to be used to create the shipment and updates the table with the details */
  exec pr_Carrier_CreateShipment @vModule, @vOperation, @vBusinessUnit, @vUserId;

  /* The record with ProcessStatus = N i.e. Not yet processed are the ones to be processed by UI */

  /* Insert the unprocessed records for multiple shipment type shipments */
  insert into @ttCreateShipmentDetails(Carrier, OrderId, PickTicket, ShipmentType, LabelTypes, IntegrationMethod, GenerationMethod, CarrierInterface, APIWorkFlow)
    select distinct Carrier, OrderId, PickTicket, ShipmentType, LabelsRequired, IntegrationMethod, GenerationMethod, CarrierInterface, APIWorkFlow
    from #ShipLabelsToInsert
    where (ShipmentType = 'M') and (ProcessStatus in ('N', 'Initial')) and (IntegrationMethod = 'CIMSSI') and (GenerationMethod = 'UI');

  /* Insert the unprocessed records for single shipment type shipments */
  insert into @ttCreateShipmentDetails(Carrier, LPNId, LPN, OrderId, PickTicket, ShipmentType, LabelTypes, IntegrationMethod, GenerationMethod, CarrierInterface, APIWorkFlow)
    select distinct Carrier, EntityId, EntityKey, OrderId, PickTicket, ShipmentType, LabelsRequired, IntegrationMethod, GenerationMethod, CarrierInterface, APIWorkFlow
    from #ShipLabelsToInsert
    where (ShipmentType in ('Y', 'S')) and (ProcessStatus in ('N', 'Initial')) and (IntegrationMethod = 'CIMSSI') and (GenerationMethod = 'UI');

  /* Build the inputs for respective CarrierInterface CIMSSI */
  update CSD
  set CarrierInterfaceInput = dbo.fn_XMLNode('CreateShipmentInput',
                                       dbo.fn_XMLNode('Carrier',           Carrier) +
                                       dbo.fn_XMLNode('CarrierInterface',  CarrierInterface) +
                                       dbo.fn_XMLNode('LPNId',             LPNId) +
                                       dbo.fn_XMLNode('LPN',               LPN) +
                                       dbo.fn_XMLNode('OrderId',           OrderId) +
                                       dbo.fn_XMLNode('PickTicket',        PickTicket) +
                                       dbo.fn_XMLNode('ShipmentType',      ShipmentType) +
                                       dbo.fn_XMLNode('LabelTypes',        LabelTypes))
  from @ttCreateShipmentDetails CSD
  where (IntegrationMethod = 'CIMSSI') and (GenerationMethod = 'UI');

  /* Build the inputs for respective CIMSAPI */
  /*
  update CSD
  set CarrierInterfaceInput = APIRecordId
  where (CarrierInterface = 'CIMSAPI');
  */

  /* Return the details to the caller */
  select * from @ttCreateShipmentDetails;

end /* pr_Printing_GetCreateShipmentDetails */

Go
