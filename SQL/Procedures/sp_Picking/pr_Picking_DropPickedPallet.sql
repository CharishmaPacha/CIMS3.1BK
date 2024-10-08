/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/06/29  PK      pr_Picking_DropPickedPallet: Removed the code and called set_pallet Location procedure in high level procedure.
  2011/08/29  PK      pr_Picking_DropPickedPallet: Added.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_DropPickedPallet') is not null
  drop Procedure pr_Picking_DropPickedPallet;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_DropPickedPallet:
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_DropPickedPallet
  (@DropPalletId    TRecordId,
   @DropLocationId  TRecordId,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId)
as
begin /* pr_Picking_DropPickedPallet */
  return;
end /* pr_Picking_DropPickedPallet */

Go

/*------------------------------------------------------------------------------
  Proc pr_Picking_DropPickedTote:
------------------------------------------------------------------------------*/
