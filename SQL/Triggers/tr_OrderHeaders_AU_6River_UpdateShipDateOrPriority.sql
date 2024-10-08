/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('tr_OrderHeaders_AU_6River_UpdateShipDateOrPriority') is not null
  drop Trigger tr_OrderHeaders_AU_6River_UpdateShipDateOrPriority;
Go
/*------------------------------------------------------------------------------
  tr_OrderHeaders_AU_6River_UpdateShipDateOrPriority: Whenever there is a change in Priority or DesiredShipDate on Order,
    this trigger generates API transaction for the PickTicket with Message Type as UpdatePriority & UpdateShipDate
------------------------------------------------------------------------------*/
Create Trigger tr_OrderHeaders_AU_6River_UpdateShipDateOrPriority on OrderHeaders After Update
as
begin
  /* If OrderHeaders table was modified, but Priority or DesiredShipDate was not part of the update statement, then exit */
  if not update(Priority) and not update(DesiredShipDate)
    return;

  /* Get all the Orders when there is a change in Priority or DesiredShipDate */
  select OH.OrderId, OH.PickTicket, INS.DesiredShipDate as NewDesiredShipDate, DEL.DesiredShipDate as OldDesiredShipDate,
         INS.Priority as NewPriority, DEL.Priority as OldPriority, W.PickMethod, OH.BusinessUnit
  into #OrdersModified
  from Inserted INS
    join Deleted      DEL on (INS.OrderId    = DEL.OrderId)
    join OrderHeaders OH  on (INS.OrderId    = OH.OrderId )
    join Waves        W   on (OH.PickBatchId = W.WaveId   )
  where (W.PickMethod = '6River') and
        ((DEL.DesiredShipDate <> INS.DesiredShipDate) or
         (DEL.Priority <> INS.Priority));

  /* If none of the Orders had changes, then exit */
  if not exists (select * from #OrdersModified) return;

  /* If there is any change in order priority or ship date then generate an API transaction for the order */
  insert into APIOutboundTransactions (IntegrationName, MessageType, EntityType, EntityId, EntityKey, BusinessUnit, CreatedBy)
    select 'CIMS' + PickMethod, 'UpdatePriority', 'PickTicket', OrderId, PickTicket, BusinessUnit, system_user
    from #OrdersModified
    where (NewPriority <> OldPriority)
    union
    select 'CIMS' + PickMethod, 'UpdateShipDate', 'PickTicket', OrderId, PickTicket, BusinessUnit, system_user
    from #OrdersModified
    where (NewDesiredShipDate <> OldDesiredShipDate);

end /* tr_OrderHeaders_AU_6River_UpdateShipDateOrPriority */

Go

alter table OrderHeaders Disable trigger tr_OrderHeaders_AU_6River_UpdateShipDateOrPriority;

Go

