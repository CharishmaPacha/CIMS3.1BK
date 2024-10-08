/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/21  RKC     pr_LPNs_TransferLPNs_PrepareforReceipt: Proc to handle Transfer LPNs (HA-1073)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_TransferLPNs_PrepareforReceipt') is not null
  drop Procedure pr_LPNs_TransferLPNs_PrepareforReceipt;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_TransferLPNs_PrepareforReceipt: When Transfer loads are shipped, the LPN would be
   in Shipped or Intransit status. There may be several updates to do to the
   LPNs shipped to prepare them for receiving at the destination Warehouse.
   This proc handles those scenarios
  a. If shipepd on a Transfer Load and the LPNs are in Transit, it would clear
     the LPNs off the Load so that they can be received now at the destination.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_TransferLPNs_PrepareforReceipt
  (@UserId            TUserId,
   @BusinessUnit      TBusinessUnit)
as
  declare @vReturnCode    TInteger,
          @vMessageName   TMessageName,
          @vMessage       TDescription,
          @vArchiveDate   TDate;
begin
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Clear the load information on the all Intransit LPN associated with a Transfer Load */
  update L
  set LoadId     = null,
      LoadNumber = null
  from LPNs L
   join Loads LD on (L.LoadId    = LD.LoadId) and
                    (LD.LoadType = 'Transfer')
  where (L.Status       = 'T' /* InTransit */) and
        (L.LoadId       > 0) and
        (LD.Status      = 'S' /* Shipped */) and
        (LD.BusinessUnit = @BusinessUnit)

  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_TransferLPNs_PrepareforReceipt */

Go
