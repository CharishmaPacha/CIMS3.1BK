/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Router_DCMS_ExportInstructions') is not null
  drop Procedure pr_Router_DCMS_ExportInstructions;
Go
/*------------------------------------------------------------------------------
  pr_Router_DCMS_ExportInstructions: Procedure to export the Route instructions
    from CIMS to SDI's DCMS
------------------------------------------------------------------------------*/
Create Procedure pr_Router_DCMS_ExportInstructions
as
  declare @vReturnCode     TInteger,
          @vMessageName    TMessageName,

          @ttRecsToExport  TEntityKeysTable;
begin /* pr_Router_DCMS_ExportInstructions */
  set @vReturnCode = 0;

  /* Get all the records of RouterInstruction to DCMSRouteInstruction
     which are not exported. */
  insert into @ttRecsToExport (EntityId)
    select RecordId
    from RouterInstruction
    where (ExportStatus = 'N' /* No */);

  /* Export them to DCMS */
  insert into DCMS_RouteInstruction(CartonLPN, PrimaryDestination, WorkId1, DCMSReady, DCMSReadyTime)
    select RI.LPN, RI.Destination, coalesce(RI.WorkId, ''), 1, current_timestamp
    from RouterInstruction RI join @ttRecsToExport RE on (RI.RecordId = RE.EntityId);

  /* Mark all the LPNs just exported to DCMS as processed */
  update RI
  set ExportStatus   = 'Y' /* Yes */,
      ExportDateTime = current_timestamp
  from RouterInstruction RI join @ttRecsToExport RE on (RI.RecordId = RE.EntityId);

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Router_DCMS_ExportInstructions */

Go
