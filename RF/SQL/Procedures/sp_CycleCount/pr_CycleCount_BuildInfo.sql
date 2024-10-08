/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/03  PK      pr_CycleCount_BuildDataForDirectedCC, pr_CycleCount_BuildInfo:
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_CycleCount_BuildInfo') is not null
  drop Procedure pr_CycleCount_BuildInfo;
Go
/*------------------------------------------------------------------------------
  Procedure pr_CycleCount_BuildInfo: The output fetched from V2 proc is passed to
    this proc as input and we are building the xml/data set in a format that suits
    the current V3 implementation of CC
------------------------------------------------------------------------------*/
Create Procedure pr_CycleCount_BuildInfo
  (@xmlInput            xml,
   @Operation           TOperation = null,
   @LocationInfoXML     TXML       = null output,
   @LocationDetailsXML  TXML       = null output,
   @AdditionalInfoXML   TXML       = null output)
as
  /* Standard variables */
  declare @vReturnCode               TInteger,
          @vMessageName              TMessageName,
          @vxmlInput                 xml,
          @vxmlOutput                xml,
          @vxmlRFCProcInput          xml,
          @vxmlRFCProcOutput         xml,
          @vrfcProcInputxml          TXML,
          @vrfcProcOutputxml         TXML,
          @vTransactionFailed        TBoolean,
          /* Input variables */
          @vLocationId               TRecordId,
          @vLocation                 TLocation,
          @vLocationType             TLocationType,
          @vLocationBarcode          TBarcode,
          @vBatchNo                  TTaskBatchNo,
          @vTaskId                   TRecordId,
          @vTaskDetailId             TRecordId,
          @vScanEntity               TControlValue,
          @vForceUserInput           TControlValue,
          @vRequestedCCLevel         TTypeCode,
          @vDefaultQty               TControlValue,
          @vInputQtyPrompt           TControlValue;
/* Functional variables */
  declare @vTaskSubType              TFlag,
          @vTempXML                  TXML;
begin /* pr_CycleCount_BuildInfo */

  /*  Read values from inputxml as it is needed for dispalying data for Directed CC
      and also to build xml in the way js is expecting */
  select @vLocationId        = Record.Col.value('(LOCATIONINFO/LocationId)[1]',       'TRecordId'    ),
         @vLocation          = Record.Col.value('(LOCATIONINFO/Location)[1]',         'TLocation'    ),
         @vLocationType      = Record.Col.value('(LOCATIONINFO/LocationType)[1]',     'TLocationType'),
         @vLocationBarcode   = Record.Col.value('(LOCATIONINFO/LocationBarcode)[1]',  'TBarcode'     ),
         @vRequestedCCLevel  = Record.Col.value('(LOCATIONINFO/RequestedCCLevel)[1]', 'TTypeCode'    ),
         @vBatchNo           = Record.Col.value('(LOCATIONINFO/BatchNo)[1]',          'TTaskBatchNo' ),
         @vTaskId            = Record.Col.value('(LOCATIONINFO/TaskId)[1]',           'TRecordId'    ),
         @vTaskDetailId      = Record.Col.value('(LOCATIONINFO/TaskDetailId)[1]',     'TRecordId'    ),
         @vDefaultQty        = Record.Col.value('(OPTIONS/RESERVE/DefaultQuantity)[1]',       'TControlValue'),
         @vInputQtyPrompt    = Record.Col.value('(OPTIONS/RESERVE/InputQtyPrompt)[1]',        'TControlValue')
  from @xmlInput.nodes('/CYCLECOUNTDETAILS') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlInput = null));

  /* Call the AMF_LocationInfo proc which returns the LocationInfo to be shown in screen */
  exec pr_AMF_Info_GetLocationInfoXML @vLocationId, null /* No details */, @Operation, @LocationInfoXML output;

  /* Extract Location - LPN Details
     Format will be:
     <LOCLNS>
      <LOCLPN>
        <LPN></LPN>
        ....
      </LOCLPN>
      <LOCLPN>
      ...
      </LOCLPN>
     </LOCLPNS>

     This will be sent as array of json object to RF forms */
  if (@vLocationType in ('B', 'R' /* Bulk, Reserve */))
    begin
      select @vTempXML = (select c.query('.')
                          from @xmlInput.nodes('/CYCLECOUNTDETAILS/LOCATIONDETAILS/RESERVE') as t(c)
                          for xml path('LOCLPN'), root('LOCLPNS'));

      if (@vTempXML is not null)
        select @LocationDetailsXML = replace(replace(cast(@vTempXML as varchar(max)), '<RESERVE>', ''), '</RESERVE>', '');
      else
        select @LocationDetailsXML = dbo.fn_XMLNode('LOCLPNS', '');
    end /* End if logic */
  else
  if (@vLocationType in ('K' /* Picklane */))
    begin
      select @vTempXML = (select c.query('.')
                          from @xmlInput.nodes('/CYCLECOUNTDETAILS/LOCATIONDETAILS/PICKLANE') as t(c)
                          for xml path('LOCSKU'), root('LOCSKUs'));

      if (@vTempXML is not null)
        select @LocationDetailsXML = replace(replace(cast(@vTempXML as varchar(max)),'<PICKLANE>', ''), '</PICKLANE>', '');
      else
        select @LocationDetailsXML = dbo.fn_XMLNode('LOCSKUs', '');
    end /* End if logic */

  /* Build the Additional Info XML */
  select @AdditionalInfoXML = dbo.fn_XMLNode('TaskId',                        @vTaskId) +
                              dbo.fn_XMLNode('TaskDetailId',                  @vTaskDetailId) +
                              dbo.fn_XMLNode('BatchNo',                       @vBatchNo) +
                              dbo.fn_XMLNode('LocationBarcode',               @vLocationBarcode) +
                              dbo.fn_XMLNode('LocationInfo_RequestedCCLevel', @vRequestedCCLevel) +
                              dbo.fn_XMLNode('DefaultQuantity',               @vDefaultQty) +
                              dbo.fn_XMLNode('InputQtyPrompt',                @vInputQtyPrompt);

end /* pr_CycleCount_BuildInfo */

Go

