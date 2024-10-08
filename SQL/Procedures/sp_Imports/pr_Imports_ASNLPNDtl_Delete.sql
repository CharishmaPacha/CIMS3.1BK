/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/02/04  OK      Refactored the code into pr_Imports_ASNLPNDtl_Insert, pr_Imports_ASNLPNDtl_Update, pr_Imports_ASNLPNDtl_Delete
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ASNLPNDtl_Delete') is not null
  drop Procedure pr_Imports_ASNLPNDtl_Delete;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_ASNLPNDtl_Delete: Delete ASN LPN Detail record
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ASNLPNDtl_Delete
  (@ImportASNLPDetails  TASNLPNImportType READONLY)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId;
begin
  SET NOCOUNT ON;

  /* Delete all the details */
  Delete LD
  output 'LPN', Deleted.LPNId, null, 'AT_ASNLPNLineDeleted' /* Audit Activity */, 'D' /* Action - Update */,
         Deleted.BusinessUnit, Deleted.ModifiedBy
  into #ImportASNAuditInfo (EntityType, EntityId, EntityKey, ActivityType, Action, BusinessUnit, UserId)
  from LPNDetails LD
    join @ImportASNLPDetails ttASNLD on ttASNLD.LPNId = LD.LPNId and ttASNLD.LPNDetailId = LD.LPNDetailId
  where ttASNLD.RecordAction = 'D';

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_ASNLPNDtl_Delete */

Go
