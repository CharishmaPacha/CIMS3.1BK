/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/23  RIA     pr_AMF_DataTableSKUDetails_BuildLPN: Included onhandstatus unavailable as well for new temp LPNs (HA-2902)
  2021/06/23  RIA     Added: pr_AMF_DataTableSKUDetails_Build, pr_AMF_DataTableSKUDetails_BuildLocation, pr_AMF_DataTableSKUDetails_BuildLPN (HA-2878)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_DataTableSKUDetails_Build') is not null
  drop Procedure pr_AMF_DataTableSKUDetails_Build;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_DataTableSKUDetails_Build: In this procedure we will get number
    of records(used in top clause) from controls based on operation. We will be calling
    either BuildLocation or BuildLPN procs based on the values passed to this procedure.

  We can send the detail level/ we will be enhancing this to fetch the DetailLevel also
    from the controls.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_DataTableSKUDetails_Build
  (@LocationId          TRecordId,
   @LPNId               TRecordId,
   @DetailLevel         TFlags     = null,
   @Operation           TOperation,
   @SKUFilter           TSKU,
   @BusinessUnit        TBusinessUnit,
   @DetailsXML          TXML       = null output,
   @xmLDetails          xml        = null output  -- true xml data type
   )
as
  /* Standard variables */
  declare @vReturnCode               TInteger,
          @vMessageName              TDescription,
          @vMessage                  TMessage,
          @vxmlInput                 xml,
          /* Input variables */
          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId,
          @vDeviceId                 TDeviceId,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vLPNDetailsXML            TXML,
          @vLocationDetailsXML       TXML,
          @vLPNId                    TRecordId,
          @vLPN                      TLPN,
          @vLPNStatus                TStatus,
          @vLPNType                  TTypeCode,
          @vLPNDetailId              TRecordId,
          @vSKUId                    TRecordId,
          @vRowsToSelect             TInteger;
begin /* pr_AMF_DataTableSKUDetails_Build */

  /* get the value of max records to show in the datatable for the specific operation */
  select @vRowsToSelect = dbo.fn_Controls_GetAsInteger(@Operation, 'RFNumLinesToDisplay', 100, @BusinessUnit, null /* UserId */);

  /* get the detail level for specific operation, if not particularly requested by caller */
  if (@DetailLevel is null)
    select @DetailLevel = dbo.fn_Controls_GetAsString(@Operation, 'DetailLevel', 'None', @BusinessUnit, null /* UserId */);

  if (@LocationId is not null)
    exec pr_AMF_DataTableSKUDetails_BuildLocation @LocationId, @DetailLevel, @Operation, @vRowsToSelect, @SKUFilter, @BusinessUnit, @vLocationDetailsXML output;

  if (@LPNId is not null)
    exec pr_AMF_DataTableSKUDetails_BuildLPN @LPNId, @DetailLevel, @Operation, @vRowsToSelect, @SKUFilter, @BusinessUnit, @vLPNDetailsXML output;

  select @DetailsXML = coalesce(@vLocationDetailsXML, @vLPNDetailsXML, '');
  select @xmlDetails = convert(xml, @DetailsXML);
end /* pr_AMF_DataTableSKUDetails_Build */

Go

