/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/02/05  PK      Added pr_Exports_OpenOrders, pr_Exports_OpenReceipts,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_OpenReceipts') is not null
  drop Procedure pr_Exports_OpenReceipts;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_OpenReceipts:

  This procedure will return the Open Receipts
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_OpenReceipts
  (@TransType     TTypeCode      = null,
   @ReceiptNumber TReceiptNumber = null,
   @BusinessUnit  TBusinessUnit  = null,
   @UserId        TUserId        = null,
   @XmlData       XML            = null,
   @ResultXml     XML   output)
as
  declare @ReturnCode       TInteger,
          @MessageName      TMessageName,
          @Message          TDescription,

          @vRecordType      TTypeCode;

begin
  set NOCOUNT ON;

  select @ReturnCode    = 0,
         @MessageName   = null,
         @vRecordType   = 'OR' /* Open Receipts */;

  /* Fetch the parameter values from the xmlData */
  if (@XmlData is not null)
    select @TransType     = Record.Col.value('TransType[1]',     'TTypeCode'),
           @ReceiptNumber = Record.Col.value('ReceiptNumber[1]', 'TReceiptNumber'),
           @BusinessUnit  = Record.Col.value('BusinessUnit[1]',  'TBusinessUnit'),
           @UserId        = Record.Col.value('UserId[1]',        'TUserId')
    from @xmlData.nodes('//msg/msgBody/Record') as Record(Col);

  /* Make null if empty strings are passed */
  select @TransType     = nullif(@TransType,     ''),
         @ReceiptNumber = nullif(@ReceiptNumber, ''),
         @BusinessUnit  = nullif(@BusinessUnit,  ''),
         @UserId        = nullif(@UserId,        '');

  /* Get the Shipped Load Info into XML */
  select @ResultXml = (select distinct @vRecordType as RecordType, ReceiptNumber, ReceiptTypeDesc as ReceiptType,
                              VendorId, Vessel, Warehouse, Ownership, ContainerNo, RH_UDF1, RH_UDF2,
                              RH_UDF3, RH_UDF4, RH_UDF5, HostReceiptLine, CustPO, SKU, SKU1, SKU2,
                              SKU3, SKU4, SKU5, CoO, UnitCost, QtyOrdered, QtyIntransit, QtyReceived,
                              QtyToReceive as QtyOpen, RD_UDF1, RD_UDF2, RD_UDF3, RD_UDF4, RD_UDF5,
                              RD_UDF6, RD_UDF7, RD_UDF8, RD_UDF9, RD_UDF10, vwORE_UDF1, vwORE_UDF2,vwORE_UDF3,
                              vwORE_UDF4, vwORE_UDF5,vwORE_UDF6, vwORE_UDF7, vwORE_UDF8, vwORE_UDF9, vwORE_UDF10
                      from vwOpenReceipts
                      where (ReceiptNumber = coalesce(@ReceiptNumber, ReceiptNumber)) and
                            (BusinessUnit  = @BusinessUnit)
                      FOR XML PATH('ReceiptInfo'), ROOT('ExportOpenReceipts'));

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Exports_OpenReceipts */

Go
