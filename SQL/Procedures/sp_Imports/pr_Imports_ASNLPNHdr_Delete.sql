/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/15  MS      pr_Imports_ASNLPNHeaders, pr_Imports_ASNLPNHdr_Delete, pr_Imports_ASNLPNDetails, pr_Imports_CIMSDE_ImportData
                      pr_Imports_ASNLPNHdr_Insert, pr_Imports_ASNLPNHdr_Update, pr_Imports_ASNLPNHdr_Delete (HPI-2363)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_ASNLPNHdr_Delete') is not null
  drop Procedure pr_Imports_ASNLPNHdr_Delete;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_ASNLPNHdr_Delete:
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_ASNLPNHdr_Delete
  (@ImportASNLPNHeaders  TASNLPNImportType READONLY)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId;
begin
  SET NOCOUNT ON;

  -- /* Capture audit info before */
  -- insert into #ImportASNAuditInfo
  -- select 'ASNLPNH', ALH.LPNId, ALH.LPN, null /* EntityDetails */, 'AT_ASNLPNHeaderDeleted' /* Audit Activity */, ALH.RecordAction /* Action */,
  --        null /* Comment */, ALH.BusinessUnit, ALH.ModifiedBy, null /* UDF1 */, null /* UDF2 */, null /* UDF3 */, null /* UDF4 */, null /* UDF5 */, null /* Audit Id */
  -- from @ImportASNLPNHeaders ALH
  --   join LPNs L on (L.LPNId = ALH.LPNId)
  -- where ALH.RecordAction = 'D';

  /* Delete the LPN Headers, capture the audit trail */
  delete L
  output 'LPN', Deleted.LPNId, Deleted.LPN, 'AT_ASNLPNHeaderDeleted' /* Audit Activity */, 'D',
         Deleted.BusinessUnit, ttASNLH.ModifiedBy
  into #ImportASNAuditInfo (EntityType, EntityId, EntityKey, ActivityType, Action, BusinessUnit, UserId)
  from LPNs L
    join @ImportASNLPNHeaders ttASNLH on ttASNLH.LPNId = L.LPNId
  where ttASNLH.RecordAction = 'D';

  /* Delete the details for the LPNs */
  Delete LD
  from LPNDetails LD
    join @ImportASNLPNHeaders ttASNLH on ttASNLH.LPNId = LD.LPNId
  where ttASNLH.RecordAction = 'D';

  /* Delete Received counts of LPNs */
  Delete LD
  from ReceivedCounts LD
    join @ImportASNLPNHeaders ttASNLH on ttASNLH.LPNId = LD.LPNId
  where ttASNLH.RecordAction = 'D';

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Imports_ASNLPNHdr_Delete */

Go
