/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/09/13  VS      pr_Shipment_Recalculate: Passed EntityStatus Parameter (BK-910)
  2021/03/17  MS      pr_Shipment_Recalculate: Enhanced proc to defer the counts (HA-1935)
  2020/01/21  TK      pr_Shipment_Recalculate: Initial Revision (S2GCA-970)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipment_Recalculate') is not null
  drop Procedure pr_Shipment_Recalculate;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipment_Recalculate: Loops thru each Shipment from the temp table and recounts it
------------------------------------------------------------------------------*/
Create Procedure pr_Shipment_Recalculate
  (@ShipmentsToReCalculate    TEntityKeysTable readonly,
   @Flags                     TFlags = 'CS',
   @BusinessUnit              TBusinessUnit,
   @UserId                    TUserId)
as
  declare @vReturnCode         TInteger,
          @vMessageName        TMessageName,

          @vRecordId           TRecordId,
          @vShipmentId         TRecordId;

  declare @ttRecountKeysTable  TRecountKeysTable;
begin  /* pr_Shipment_Recalculate */
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* defer re-count for later */
  if (charindex('$', @Flags) > 0)
    begin
      /* Input to this procedure is EntityKeysTable but caller is expecting RecountKeysTable, so copy the data */
      insert into @ttRecountKeysTable (EntityId, EntityKey) select EntityId, EntityKey from @ShipmentsToReCalculate;

      /* invoke RequestRecalcCounts to defer Shipment count updates */
      exec pr_Entities_RequestRecalcCounts 'Shipment', null /* EntityId */, null /* Entity key */,  @Flags, @@ProcId,
                                            null /* Operation */, @BusinessUnit, null /* EntityStatus */, @ttRecountKeysTable;

      return (0);
    end

  /* Loop thru each Load and recount it */
  while exists(select * from @ShipmentsToReCalculate where RecordId > @vRecordId)
    begin
      select top 1 @vRecordId   = RecordId,
                   @vShipmentId = EntityId
      from @ShipmentsToReCalculate
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Invoke Proc to recount Shipment */
      exec pr_Shipment_Recount @vShipmentId;
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Shipment_Recalculate */

Go
