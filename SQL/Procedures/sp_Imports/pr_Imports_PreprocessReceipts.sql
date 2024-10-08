/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_PreprocessReceipts') is not null
  drop Procedure pr_Imports_PreprocessReceipts;
Go
Create Procedure pr_Imports_PreprocessReceipts
as
  declare @vReceiptId  TRecordId,
          @vRecordId   TRecordId;

  declare @ttReceipts  TEntityKeysTable;
begin /* pr_Imports_PreprocessReceipts */
  SET NOCOUNT ON;

  select @vRecordId = 0;

  /* Identify the orders to be preprocessed */
  insert into @ttReceipts(EntityId)
    select ReceiptId
    from ReceiptHeaders
    where (PreprocessFlag = 'N' /* No */)
    order by ReceiptId;

  while (exists(select * from @ttReceipts where RecordId > @vRecordId))
    begin
      select Top 1
             @vRecordId = RecordId,
             @vReceiptId = EntityId
      from @ttReceipts
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Call pr_ReceiptHeaders_Preprocess procedure  */
      exec pr_ReceiptHeaders_Preprocess @vReceiptId, 'Import_ROD';
    end /* while (@vReceiptRecordId is not null) */

end /* pr_Imports_PreprocessReceipts */

Go
