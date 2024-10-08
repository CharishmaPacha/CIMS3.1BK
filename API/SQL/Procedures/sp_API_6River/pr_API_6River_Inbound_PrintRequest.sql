/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/01/29  RT      pr_API_6River_Inbound_PrintRequest: Changes to set Operation as 6rvr (CID-1662)
  2021/01/29  RV      pr_API_6River_Inbound_PrintRequest: Made changes to call CLR to print immediately (CID-1660)
  2020/11/19  NB      Added pr_API_6River_Inbound_PrintRequest(CID-1543)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_6River_Inbound_PrintRequest') is not null
  drop Procedure pr_API_6River_Inbound_PrintRequest;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_6River_Inbound_PrintRequest

  processed print requests from 6River
  reads the details from input received
  creates print request and print jobs for the requests
------------------------------------------------------------------------------*/
Create Procedure pr_API_6River_Inbound_PrintRequest
  (@TransactionRecordId   TRecordId)
as
  declare @vIntegrationName    TName,
          @vMessageType        TName,
          @vRequestInput       TVarchar,
          @vBusinessUnit       TBusinessUnit,
          @vLookupCategory     TCategory,
          @vResponse           TVarchar,
          @vMessage            TMessage,
          @vRecordId           TRecordId,
          @vEntityType         TEntity,
          @vEntityId           TRecordId,
          @vEntityKey          TEntityKey,
          @vLabelPrinterName   TName,
          @vLabelPrinterName2  TName,
          @vReportPrinterName  TName,
          @vOperation          TOperation,
          @vUserId             TUserId,
          @vDeviceId           TDeviceId,
          @vWarehouse          TWarehouse,
          @vPrintRequestXML    TXML,
          @vRequestMode        TCategory,
          @vPrintRequestId     TRecordId;

  declare @ttEntitiesToPrint  TEntitiesToPrint;
begin /* pr_API_6River_Inbound_PrintRequest */
begin try
  /* read the transaction details */
  select @vIntegrationName = IntegrationName,
         @vMessageType     = MessageType,
         @vRequestInput    = RawInput,
         @vBusinessUnit    = BusinessUnit
  from APIInboundTransactions
  where (RecordId = @TransactionRecordId);

  /* Create Entities to Print object if caller has not already created one */
  if (object_id('tempdb..#EntitiesToPrint') is null)
    select * into #EntitiesToPrint from @ttEntitiesToPrint;

  /* Read the details from Request Input */
  select row_number() over (order by (select 1)) RecordId, MessageType, Phase, DestinationLocation, UserId, DeviceId,
         ContainerId, GroupId, GroupType, Reprint, PickingStrategy, ConsolidationId
  into #PrintRequestsToProcess
  from OpenJson(@vRequestInput)
    with (MessageType          varchar(30) '$.messageType',
          Phase                varchar(20) '$.phase',
          DestinationLocation  varchar(20) '$.destinationLocation',
          UserId               varchar(20) '$.userID',
          DeviceId             varchar(20) '$.deviceID',
          containers           nvarchar(max) as JSON)
    cross apply OPENJSON(containers)
      with (ContainerId      varchar(30) '$.containerID',
            GroupId          varchar(20) '$.groupID',
            GroupType        varchar(20) '$.groupType',
            Reprint          bit         '$.reprint',
            PickingStrategy  varchar(20) '$.pickingStrategy',
            ConsolidationId  varchar(20) '$.consolidationID');

  /* Initialize */
  select @vEntityType  = 'LPN', -- Assumption as the input has ContainerId
         @vOperation   = '6RiverAPI',
         @vRequestMode = 'IMMEDIATE';

  insert into #EntitiesToPrint (EntityType, EntityId, EntityKey, Operation, LabelPrinterName, LabelPrinterName2, ReportPrinterName,
                                Warehouse, BusinessUnit, UserId, RecordId)
    select @vEntityType, L.LPNId, L.LPN, @vOperation, PR.DestinationLocation, null, PR.DestinationLocation,
           L.DestWarehouse, L.BusinessUnit, PR.UserId, PR.RecordId
    from #PrintRequestsToProcess PR join LPNs L on RR.ContainerId = L.LPN and L.BusinessUnit = @vBusinessUnit;

  /* Print using CLR or create print jobs based upon the request mode. Input is the #EntitiesToPrint that are loaded above */
  exec pr_Printing_EntityPrintRequest 'ShippingDocs', @vOperation, null /* Entity Type */, null /* EntityId */, null /* Entity Key */,
                                      @vBusinessUnit, @vUserId, null /* Device Id */, @vRequestMode,
                                      @vLabelPrinterName /* LabelPrinterName */, null /* LabelPrinterName2 */, @vReportPrinterName /* ReportPrinterName */,
                                      null /* Rules Data XML */;

  /* Respond to caller with success message */
  update APIInboundTransactions
  set ResponseCode      = '200', /* Processed Ok */
      Response          = 'Print Job Initiated',
      TransactionStatus = 'Processed'
  where (RecordId = @TransactionRecordId);

end try
begin catch
  /* Current Implementation of Message handlers adds some special characters to the message. These will interfere with forming
     a proper xml string. Hence, remove any special characters from the message before building the result xml with the error message */
  select @vMessage = replace(replace(replace(ERROR_MESSAGE(), '$', ''), '<', ''), '>', '');

  update APIInboundTransactions
  set ResponseCode      = '505', /* Internal Server Error */
      Response          = @vMessage,
      TransactionStatus = 'Fail'
  where (RecordId = @TransactionRecordId);

end catch

end /* pr_API_6River_Inbound_PrintRequest */

Go
