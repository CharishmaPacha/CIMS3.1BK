/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/10/26  MS      pr_ShipLabel_GetLabelsToVoid: Procedure to to fetch the "Voided(V)" status records from ShipLabels table (S2GCA-1003)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ShipLabel_GetLabelsToVoid') is not null
  drop Procedure pr_ShipLabel_GetLabelsToVoid;
Go
/*------------------------------------------------------------------------------
  Proc pr_ShipLabel_GetLabelsToVoid: Returns all the info to use in voiding
   the carrier label that was generated earlier

  return as :

  <VoidLabels>
    <InterfaceLogInfo>
      <InterfaceLogId>32683</InterfaceLogId>
    </InterfaceLogInfo>
    <LabelsToVoid xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <Label>
        <RecordId>4</RecordId>
        <CarrierInterface>ADSI</CarrierInterface>
        <CarrierSymbol>CONNECTSHIP_GLOBAL.TFORCE</CarrierSymbol>
        <MSN>11344</MSN>
      </Label>
      <Label>
        <RecordId>72</RecordId>
        <CarrierInterface>ADSI</CarrierInterface>
        <CarrierSymbol>CONNECTSHIP_GLOBAL.TFORCE</CarrierSymbol>
        <MSN>11344</MSN>
      </Label>
    </LabelsToVoid>
  </VoidLabels>
-----------------------------------------------------*/
Create Procedure pr_ShipLabel_GetLabelsToVoid
  (@CarrierInterface   TCarrierInterface,
   @BusinessUnit       TBusinessUnit,
   @ResultXML          xml output)
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,
          @vXmlMsgHeader        TVarChar,
          @vInterfacelogxml     Txml,
          @vInterfaceLogId      TRecordId,
          @vRecordsProcessed    TCount;

begin /* pr_ShipLabel_GetLabelsToVoid */
  select @vReturnCode  = 0,
         @vMessagename = null;

  /* Insert table structure into #LabelsToVoid */
  select RecordId, CarrierInterface, ServiceSymbol, MSN
  into #LabelsToVoid
  from ShipLabels
  where (RecordId = 0);

  /* enable identity insert to insert identity column recordid into tmp table */
  set Identity_Insert #LabelsToVoid ON;

  /* Need to update the records to process */
  update ShipLabels
  set Status = 'VI' /* Void in progress */
  output Inserted.RecordId, Inserted.CarrierInterface, Inserted.ServiceSymbol, Inserted.MSN
  into #LabelsToVoid (RecordId, CarrierInterface, ServiceSymbol, MSN)
  where (Carrierinterface = @CarrierInterface) and
        (Status           = 'V');

  select @vRecordsProcessed = @@rowcount;

  /* For void transactions we are appending EntityKey with RecordId and 'Void' string.
     Even we won't be having TrackingNo info to get the actual LPN for the Voided transactions.
     Hence used the substring to get the LPN info. */
  set @ResultXML =  (select RecordId,
                            CarrierInterface,
                            dbo.fn_SubstringUptoNthSeparator(ServiceSymbol, '.', 2) as CarrierSymbol,
                            MSN
                     from #LabelsToVoid
                     order by RecordId
                     for XML RAW('Label'), TYPE, ELEMENTS XSINIL, ROOT('LabelsToVoid'));

  /* If there are no records to void, exit */
  if (@ResultXML is null)
    goto ExitHandler;

  /* Create interface log */
  exec pr_InterfaceLog_AddUpdate @SourceSystem     = 'CIMS',
                                 @TargetSystem     = 'CIMS',
                                 @SourceReference  = null,
                                 @TransferType     = 'INT',
                                 @BusinessUnit     = @BusinessUnit,
                                 @xmlData          = @ResultXML,
                                 @xmlDocHandle     = null,
                                 @RecordsProcessed = @vRecordsProcessed,
                                 @LogId            = @vInterfaceLogId output,
                                 @RecordTypes      = 'VOIDCL';

  select @vInterfacelogxml = dbo.fn_XMLNode('InterfaceLogInfo',
                               dbo.fn_XMLNode('InterfaceLogId', @vInterfaceLogId));

  select @ResultXML = dbo.fn_XMLNode('VoidLabels', @vInterfacelogxml + convert(varchar(max), @ResultXML));

  /* Return xml */
  select @ResultXML as result

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_ShipLabel_GetLabelsToVoid */

Go
