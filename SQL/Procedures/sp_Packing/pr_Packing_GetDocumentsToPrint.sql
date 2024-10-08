/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/04/10  DK      pr_Packing_GetDocumentsToPrint: New procedure to evaluate the PackingLists to be printed at Packing
                      pr_Packing_CloseLPN: Change to use pr_Packing_GetDocumentsToPrint. (CIMS-731)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Packing_GetDocumentsToPrint') is not null
  drop Procedure pr_Packing_GetDocumentsToPrint;
Go
/*------------------------------------------------------------------------------
  Proc pr_Packing_GetDocumentsToPrint: Evaluates the rules and gets the list
   of Packing Lists to print
------------------------------------------------------------------------------*/
Create Procedure pr_Packing_GetDocumentsToPrint
  (@xmlRulesData        TXML,
   @xmlReportsToPrint   TXML output,
   @xmlDocumentsToPrint TXML output)
as
  declare @vOrderId      TRecordId,
          @vOrderStatus  TStatus,
          @vBulkOrderId  TRecordId,
          @vPickBatchNo  TPickBatchNo,

          @vLPN          TLPN,
          @vPackageSeqNo TInteger,
          @vPrintOrdPackingList
                         TFlag,
          @vPackingListTypesToPrint TResult,
          @vReturnCode   TInteger,
          @vMessageName  TMessageName,
          @xmldata       xml,

          @vRulesResult  TResult;

  declare @vReportsxml        TXML,
          @vDocumentsxml      TXML;


begin
  /* Initialize */
  select @xmldata      = convert(xml, @xmlRulesData),
         @vReportsxml  = '';

  /* Get details from the xml */
  select @vOrderId      = Record.Col.value('OrderId[1]',      'TRecordId'),
         @vLPN          = Record.Col.value('LPN[1]',          'TLPN'),
         @vPackageSeqNo = Record.Col.value('PackageSeqNo[1]', 'TInteger'),
         @vOrderStatus  = Record.Col.value('OrderStatus[1]',  'TStatus'),
         @vPickBatchNo  = Record.Col.value('PickBatchNo[1]',  'TPickBatchNo'),
         @vBulkOrderId  = Record.Col.value('BulkOrderId[1]',  'TRecordId')
  from @xmlData.nodes('/RootNode') as Record(Col);

  /* Determine what Packing lists to print */
  exec pr_RuleSets_Evaluate 'PackingListType', @xmlRulesData, @vPackingListTypesToPrint output;

  /* Print the LPN Packing list if required. The rules determine this and is usually the case
     if LPN Packing list is required but not the only case on the Order */
  if (charindex('LPN', @vPackingListTypesToPrint) <> 0)
    begin
      select @vRulesResult = null,
             @xmlRulesData = dbo.fn_XMLStuffValue(@xmlRulesData, 'PackingListType', 'LPN');

      /* Get the packing list */
      exec pr_RuleSets_Evaluate 'PackingList', @xmlRulesData, @vRulesResult output;

      if (coalesce(@vRulesResult, '') <> '') /* LPN packing list */
        select @vReportsxml = @vReportsxml + '<Report>'                                             +
                                               '<ReportFormat>' + @vRulesResult + '</ReportFormat>' +
                                               '<ReportType>LPN</ReportType>'                       +
                                               '<Copies>1</Copies>'                                 +
                                             '</Report>';
    end /* LPN Packing List */

  /* Return Packing list required? */
  if (charindex('RET', @vPackingListTypesToPrint) <> 0)
    begin
      select @vRulesResult = null,
             @xmlRulesData = dbo.fn_XMLStuffValue(@xmlRulesData, 'PackingListType', 'RET');

      /* Get the return packing list */
      exec pr_RuleSets_Evaluate 'ReturnPackingList', @xmlRulesData, @vRulesResult output;

      if (coalesce(@vRulesResult, '') <> '') /* ReturnLPN packing list */
        select @vReportsxml = @vReportsxml + '<Report>'                                            +
                                              '<ReportFormat>' + @vRulesResult + '</ReportFormat>' +
                                              '<ReportType>ReturnLPN</ReportType>'                 +
                                              '<Copies>1</Copies>'                                 +
                                             '</Report>';
    end

  /* In the case of Bulk Pull Picking, the Packing List is already Printed. Therefore, the Order Packing List
     must be printed only when there is a difference between the printed Packing List and the contents packed for the order.
     This is mostly the case when the units packed are less the ordered units, and there are no more units remaining to be packed */
  -- select @vPrintOrdPackingList = 'N' /* No */;

  -- if (dbo.fn_OrderHeaders_IsBulkPullOrder(@vOrderId) > 0)
  --   begin
  --     /* Verify whether there are any more units to be packed for the Order.
  --        If there are more units required to be packed, and if all the picked units are packed
  --        then it means that the Order is packed short of some units. Reprint Order Packng list, in this case */
  --     if (exists (select OrderDetailId
  --                 from OrderDetails
  --                 where (OrderId = @vOrderId) and (UnitsToAllocate > 0))) and
  --        (not exists (select OPD.OrderDetailId
  --                     from vwOrderToPackDetails OPD
  --                     where ((OPD.OrderId = @vBulkOrderId) and
  --                           (OPD.SKUId in (select SKUId from OrderDetails where OrderId = @vOrderId)))))
  --       select @vPrintOrdPackingList = 'Y' /* Yes */;
  --   end
  -- else
  --   begin
  --     /* If the order is completely packed, then print the OrderPacking List also */
  --     if (@vOrderStatus in ('K' /* Packed */, 'S'/* Shipped */))
  --       select @vPrintOrdPackingList = 'Y' /* Yes */;
  --   end

  /* If Order requires packing list, then determine the format. Note that in some cases we may print
     both an LPN Pakcing list as well as an Order Packing list */
  if (charindex('ORD', @vPackingListTypesToPrint) <> 0)
    begin
      select @vRulesResult = null,
             @xmlRulesData = dbo.fn_XMLStuffValue(@xmlRulesData, 'PackingListType', 'ORD');

      /* Get the packing list */
      exec pr_RuleSets_Evaluate 'PackingList', @xmlRulesData, @vRulesResult output;

      select @vReportsxml = @vReportsxml + '<Report>'                                             +
                                             '<ReportFormat>' + @vRulesResult + '</ReportFormat>' +
                                             '<ReportType>ORD</ReportType>'                       +
                                             '<Copies>1</Copies>'                                 +
                                           '</Report>';

      /* Along with the Order packing list, see if there are any other documents to print */
      select @vRulesResult = null,
             @xmlRulesData = dbo.fn_XMLStuffValue(@xmlRulesData, 'DocumentType', 'ORD');

      /* Get the packing list */
      exec pr_RuleSets_Evaluate 'DocumentList', @xmlRulesData, @vRulesResult output;

      select @vDocumentsxml = @vDocumentsxml + '<Document>'                                           +
                                                 '<DocumentName>' + @vRulesResult + '</DocumentName>' +
                                                 '<Copies>1</Copies>'                                 +
                                               '</Document>';
    end

  select @xmlReportsToPrint   = @vReportsxml,
         @xmlDocumentsToPrint = @vDocumentsxml;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Packing_GetDocumentsToPrint */

Go
