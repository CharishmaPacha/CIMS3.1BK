/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/09/11  TK      pr_Load_GenerateLoadForWavedOrders: Initial Revision (ACME-328)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Load_GenerateLoadForWavedOrders') is not null
  drop Procedure pr_Load_GenerateLoadForWavedOrders;
Go
/*------------------------------------------------------------------------------
  Proc pr_Load_GenerateLoadForWavedOrders: Generates Load for the Orders which are Waved
------------------------------------------------------------------------------*/
Create Procedure pr_Load_GenerateLoadForWavedOrders
  (@PickBatchId      TRecordId,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @ReturnCode    TInteger,
          @MessageName   TMessageName,

          @vOrdersToLoad TXML;

begin /* pr_Load_GenerateLoadForWavedOrders */
  SET NOCOUNT ON;

  set @MessageName = null;

  /* build XML with orders info to generate Load */
  select @vOrdersToLoad = '<Orders>' +
                           (select OrderId
                            from OrderHeaders
                            where (PickBatchId = @PickBatchId)
                            for xml raw('OrderHeader'), elements) +
                          '</Orders>'

  /* Generate Loads for the orders which are waved */
  exec pr_Load_Generate @vOrdersToLoad, @BusinessUnit, @UserId, null, null, null, null;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

end /* pr_Load_GenerateLoadForWavedOrders */

Go
