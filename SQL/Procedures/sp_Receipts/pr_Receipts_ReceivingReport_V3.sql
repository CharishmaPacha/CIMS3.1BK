/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/08/10  NB      pr_Receipts_ReceivingReport_V3: added procedure for V3 Reports_GetData generic implementation(CIMSV3-1022)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receipts_ReceivingReport_V3') is not null
  drop Procedure pr_Receipts_ReceivingReport_V3;
Go
/*------------------------------------------------------------------------------
Proc pr_Receipts_ReceivingReport_V3:

Wrapper procedure called from V3 SQL to invoke pr_Receipts_ReceivingReport procedure
and return the xml
------------------------------------------------------------------------------*/
Create Procedure pr_Receipts_ReceivingReport_V3
  (@xmlInput          xml,
   @BusinessUnit      TBusinessUnit,
   @UserId            TUserId,
   @xmlReceiptSummary xml output)
as
  declare @vEntityId  TRecordId;
begin /* pr_Receipts_ReceivingReport_V3 */
  select @vEntityId = Record.Col.value('EntityId[1]', 'TRecordId')
  from @xmlInput.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @xmlInput = null ));

  exec pr_Receipts_ReceivingReport @vEntityId, @BusinessUnit, @UserId, @xmlReceiptSummary  output;
end /* pr_Receipts_ReceivingReport_V3 */

Go
