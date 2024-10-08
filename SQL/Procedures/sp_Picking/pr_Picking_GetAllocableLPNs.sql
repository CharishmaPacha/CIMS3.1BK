/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_GetAllocableLPNs') is not null
  drop Procedure pr_Picking_GetAllocableLPNs;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_GetAllocableLPNs:
    Procedure returns the allocable LPNs for a given SKU.

  ToDo: This procedure will have to be rewritten for Locator System. The
  procedure below is to get the allocable inventory from AX.
------------------------------------------------------------------------------*/
Create Procedure pr_Picking_GetAllocableLPNs
  (@SKUId  TRecordId,
   @SKU    TSKU)
as
  declare @BatchNo       integer,
          @AXCompanyCode varchar(max);
begin
  return 0;
end /* pr_Picking_GetAllocableLPNs */

Go
