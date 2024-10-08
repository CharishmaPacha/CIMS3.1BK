/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/03/18  MS      pr_Router_ExportInstructions, pr_Router_ExportInstructions_FW,
  2018/06/09  YJ      pr_Router_ExportInstructions_FW: Changes to get UCCBarcode from RouterInstruction
  2018/02/14  DK      Added pr_Router_ExportInstructions_FW (S2G-232)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Router_ExportInstructions_FW') is not null
  drop Procedure pr_Router_ExportInstructions_FW;
Go
/*------------------------------------------------------------------------------
  Proc pr_Router_ExportInstructions_FW: Get all the router instructions to be
    exported (Export Status of N) and builds xml of the data to be exported
------------------------------------------------------------------------------*/
Create Procedure pr_Router_ExportInstructions_FW
  (@xmlData           xml,
   @XmlResult         xml = null output)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,
          @vNextProcessBatch       TBatch,

          @ttRecsToExport          TEntityKeysTable,
          @xmlExportsMsgHeader     TVarchar,
          @xmlDCMSRouteInstruction xml,

          @vBusinessUnit           TBusinessUnit,
          @vUserId                 TUserId;

  declare @ttDCMSRouteInstruction table (ContainerId        char(20),
                                         CartonNumber       char(20),
                                         EstimatedWeight    char(6),
                                         DivertDestination  char(10));
begin
  set @vReturnCode = 0;

  select @vBusinessUnit = Record.Col.value('BusinessUnit[1]', 'TBusinessUnit')
  from @xmlData.nodes('/Root') as Record(Col);

  /* Get all the records of RouterInstruction which are not exported. */
  insert into @ttRecsToExport (EntityId)
    select RecordId
    from RouterInstruction
    where (ExportStatus = 'N' /* No */) and
          (BusinessUnit = @vBusinessUnit);

  if (@@rowcount = 0) return;

  /* Insert the details to format as fixed width */
  insert into @ttDCMSRouteInstruction(ContainerId, CartonNumber, EstimatedWeight, DivertDestination)
    select RI.LPN, RI.UCCBarcode, cast((RI.EstimatedWeight * 100) as int), RI.Destination
    from RouterInstruction RI join @ttRecsToExport RE on (RI.RecordId = RE.EntityId);

  /* Get the next batch no */
  exec pr_Controls_GetNextSeqNo 'ExportRouterBatch', 1, @vUserId, @vBusinessUnit,
                                @vNextProcessBatch output;

  /* Update with Batch No and mark the details as processed */
  update RI
  set ExportStatus   = 'Y' /* Yes */,
      ExportBatch    = @vNextProcessBatch,
      ExportDateTime = current_timestamp
  from RouterInstruction RI join @ttRecsToExport RE on (RI.RecordId = RE.EntityId);

  set @xmlDCMSRouteInstruction = (select *
                                 from @ttDCMSRouteInstruction
                                 for XML RAW('Record'), TYPE, ELEMENTS XSINIL, ROOT('msgBody'));

  /* Build MsgHeader node for exports */
  select @xmlExportsMsgHeader = dbo.fn_XMLNode('msgHeader', dbo.fn_XMLNode('BatchNo', @vNextProcessBatch));

  select @xmlResult = '<msg>' +  @xmlExportsMsgHeader + convert(varchar(max), @xmlDCMSRouteInstruction)  + '</msg>';

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Router_ExportInstructions_FW */

Go
