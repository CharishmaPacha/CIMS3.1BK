/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_OrderDetails_Delete') is not null
  drop Procedure pr_Imports_OrderDetails_Delete;
Go
/*------------------------------------------------------------------------------
  Procedure pr_Imports_OrderDetails_Delete; Deletes the Order details in
    #OrderDetailsImport with RecordAction of 'D'

  #OrderDetailsImport: TOrderDetailsImportType
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_OrderDetails_Delete
  (@BusinessUnit TBusinessUnit,
   @UserId       TUserId)
as
begin /* pr_Imports_OrderDetails_Delete */

  /* Capture audit info */
  insert into #AuditInfo (EntityType, EntityId, EntityKey, ActivityType, Action,
                          Comment, BusinessUnit, UserId, UDF1, UDF2)
    select 'PickTicket', OrderId, PickTicket, 'AT_OrderLineDeleted' /* Audit Activity */, RecordAction,
           OrderDetailId, BusinessUnit, ModifiedBy, OrderDetailId, SKU
    from #OrderDetailsImport
    where (RecordAction = 'D');

  delete from OrderDetails
  where OrderDetailId in (select OrderDetailId from #OrderDetailsImport OD2 where (OD2.RecordAction = 'D'))

end /* pr_Imports_OrderHeaders_Delete */

Go
