/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/03  PK      pr_CycleCount_BuildDataForDirectedCC, pr_CycleCount_BuildInfo:
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_CycleCount_BuildDataForDirectedCC') is not null
  drop Procedure pr_CycleCount_BuildDataForDirectedCC;
Go
/*------------------------------------------------------------------------------
  Procedure pr_CycleCount_BuildDataForDirectedCC: The output fetched from V2 proc is passed to
    this proc as input and we are building the xml/data set in a format that helps
    to show the form for Suggested Location
------------------------------------------------------------------------------*/
Create Procedure pr_CycleCount_BuildDataForDirectedCC
  (@xmlInput            xml,
   @DirectedCCInfoXML   TXML    = null output)
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
          @vSuggestedLocation        TLocation,
          @vLocationBarcode          TBarcode,
          @vBatchNo                  TTaskBatchNo,
          @vPickZone                 TZone,
          @vTaskId                   TRecordId,
          @vTaskDetailId             TRecordId;
          /* Functional variables */
begin /* pr_CycleCount_BuildDataForDirectedCC */

  /*  Read values from inputxml as it is needed for dispalying data for Directed CC
      and also to build xml in the way to show suggested location form where user can scan location */
  select @vLocationId        = Record.Col.value('(LOCATIONINFO/LocationId)[1]',       'TRecordId'    ),
         @vSuggestedLocation = Record.Col.value('(LOCATIONINFO/Location)[1]',         'TLocation'    ),
         @vLocationBarcode   = Record.Col.value('(LOCATIONINFO/LocationBarcode)[1]',  'TBarcode'     ),
         @vBatchNo           = Record.Col.value('(LOCATIONINFO/BatchNo)[1]',          'TTaskBatchNo' ),
         @vPickZone          = Record.Col.value('(LOCATIONINFO/PickZone)[1]',         'TZone'        ),
         @vTaskId            = Record.Col.value('(LOCATIONINFO/TaskId)[1]',           'TRecordId'    ),
         @vTaskDetailId      = Record.Col.value('(LOCATIONINFO/TaskDetailId)[1]',     'TRecordId'    )
  from @xmlInput.nodes('/CYCLECOUNTDETAILS') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlInput = null));

  /* Build the DirectedCC Info XML */
  select @DirectedCCInfoXML = dbo.fn_XMLNode('PickZone',          @vPickZone) +
                              dbo.fn_XMLNode('BatchNo',           @vBatchNo) +
                              dbo.fn_XMLNode('SuggestedLocation', @vSuggestedLocation) +
                              dbo.fn_XMLNode('LocationBarcode',   @vLocationBarcode) +
                              dbo.fn_XMLNode('TaskId',            @vTaskId) +
                              dbo.fn_XMLNode('TaskDetailId',      @vTaskDetailId);

end /* pr_CycleCount_BuildDataForDirectedCC */

Go

