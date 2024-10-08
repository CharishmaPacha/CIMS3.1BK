                                                    /*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/01  RT      Initial Revison (HA-77)
------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
 Inv Allocation Model
 -----------------------------------------------------------------------------*/
declare @InvAllocationModel TLookUpsTable, @LookUpCategory TCategory = 'InvAllocationModel';

insert into @InvAllocationModel
       (LookUpCode,  LookUpDescription,         Status)
values ('SR',        'System Reservation',      'A'),
       ('MR',        'Manual Reservation',      'A')

exec pr_LookUps_Setup @LookUpCategory, @InvAllocationModel;

Go
