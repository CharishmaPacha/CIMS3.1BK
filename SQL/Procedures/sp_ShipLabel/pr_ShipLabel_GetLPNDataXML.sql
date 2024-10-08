/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/11/24  KN      pr_ShipLabel_GetLPNDataXML: Added  additional input parameters to fix label printing issue (Ship_4x7_1516).
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ShipLabel_GetLPNDataXML') is not null
  drop Procedure pr_ShipLabel_GetLPNDataXML;
Go
Create Procedure pr_ShipLabel_GetLPNDataXML
  (@LPNs             XML,
   @LPNId            TRecordId     = null,
   @Operation        TOperation    = null,
   @BusinessUnit     TBusinessUnit = null,
   @LabelFormatName  TName         = null)
as
  declare @ReturnCode           TInteger,
          @MessageName          TMessageName,
          @UserId               TUserId,
          @vLPN                 TLPN,
          @vRecordId            TRecordId;

  declare @ttLPNs     TEntityKeysTable;
  declare @ttLPNData  TLPNShipLabelData;

begin
SET NOCOUNT ON;
  select @ReturnCode   = 0,
         @Messagename  = null,
         @UserId       = System_User,
         @BusinessUnit = coalesce(@BusinessUnit, 'TD'),
         @vRecordId    = 0;

  insert into @ttLPNs (EntityKey)
    select Record.Col.value('(./text())[1]', 'varchar(50)')
    from @LPNs.nodes('/root/EntityKey') as Record(Col)

  while (exists (select * from @ttLPNs where RecordId > @vRecordId))
    begin
      select top 1
             @vLPN      = EntityKey,
             @vRecordId = RecordId
      from @ttLPNs
      where (RecordId > @vRecordId);

      insert into @ttLPNData
        exec pr_ShipLabel_GetLPNData @vLPN, @LPNId, @Operation, @BusinessUnit, @LabelFormatName;
    end

  /* Return the data */
  select * from @ttLPNData
  order by PickBatchNo, PickTicket, CurrentCarton;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_ShipLabel_GetLPNDataXML */

Go
