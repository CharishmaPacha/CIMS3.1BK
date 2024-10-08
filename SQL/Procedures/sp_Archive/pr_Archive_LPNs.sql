/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/30  AY      pr_Archive_LPNs: Archive LPNDetails (HA-3124)
  2011/11/15  PKS     pr_Archive_LPNs, pr_Archive_Orders are added
------------------------------------------------------------------------------*/

Go

if object_id ('dbo.pr_Archive_LPNs') is not null
  drop Procedure pr_Archive_LPNs;
Go
/*------------------------------------------------------------------------------
  Proc pr_Archive_LPNs:
------------------------------------------------------------------------------*/
Create Procedure pr_Archive_LPNs
  (@UserId            TUserId,
   @BusinessUnit      TBusinessUnit)
as
  declare @vReturnCode    TInteger,
          @vMessageName   TMessageName,
          @vMessage       TDescription,
          @vArchiveDate   TDate;

  declare @ttLPNs         TEntityKeysTable;
begin
  select @vReturnCode   = 0,
         @vMessageName  = null,
         @vArchiveDate  = convert(date, getdate()-1);

  /* Update all LPNs' Archives to 'Y' when its status is
     shipped/consumed/voided/inactive
     and modified date is less than current date and archive status is 'N' */
  update LPNs
  set Archived = 'Y' /* Yes */
  output inserted.LPNId, inserted.LPN into @ttLPNs (EntityId, EntityKey)
  where ((Archived =  'N' /* No */) and
         (Status   in ('S' /* Shipped  */,
                       'C' /* Consumed */,
                       'V' /* Voided   */,
                       'I' /* Inactive */,
                       'O' /* Lost */)) and
         (ModifiedOn <= @vArchiveDate));

  /* Update LPNDetails */
  update LD
  set LD.Archived = 'Y'
  from LPNDetails LD join @ttLPNs TTL on LD.LPNId = TTL.EntityId;

  return(coalesce(@vReturnCode, 0));
end /* pr_Archive_LPNs */

Go
