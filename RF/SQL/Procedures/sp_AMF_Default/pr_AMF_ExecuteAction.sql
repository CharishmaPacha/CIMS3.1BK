/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/10/22  RIA     pr_AMF_ExecuteAction: Changes to send pickmode (BK-644)
  2021/05/28  TK      pr_AMF_ExecuteAction: Return success message on drop pallet (BK-324)
  2021/01/06  RIA     pr_AMF_ExecuteAction: Changes to update Devices table with new devicename for create in lpn if not present for particular device (HA-1839)
  2020/10/13  RIA     pr_AMF_ExecuteAction: Changes to update Devices table with new devicename for inquiry if not present for particular device (HA-1569)
  pr_AMF_ExecuteAction: call the new procedure to build the result messages (HA-1179)
  2020/09/04  SK      pr_AMF_ExecuteAction: Include Replenish Case/Unit picking (HA-1398)
  2020/09/02  TK      pr_AMF_ExecuteAction: Changes to pass TaskId to drop Pallet proc (HA-1175)
  2020/08/27  RV      pr_AMF_ExecuteAction: Created ResultMessages hash table to build xml with Info, Warnings and Errors (HA-1179)
  2020/06/09  RIA     pr_AMF_ExecuteAction: Consider PalletStatus while PausePicking (HA-873)
  2020/06/07  RIA     pr_AMF_ExecuteAction: Create DataTableSKUDetails if does not exist (HA-491)
  2020/06/07  RIA     pr_AMF_ExecuteAction: Changes to consider appropriate forms drop pallet/cart (HA-649)
  2020/05/15  TK      pr_AMF_ExecuteAction: Pass PickGroup to GetBatchPick (HA-543)
  2019/12/16  RIA     pr_AMF_ExecuteAction: Changes to call pr_AMF_Picking_UnitPick_BuildNextPickResponse (CID-1214)
  2019/11/08  RIA     pr_AMF_ExecuteAction: Changes to not send DataXML in 1st form (CIMSV3-624)
  2019/08/16  RIA     pr_AMF_ExecuteAction: Changes to remove m_ values from nodes (CID-947)
  2019/07/21  NB      pr_AMF_ExecuteAction: send LogInfo to caller in OutputXml(CID-835)
  2019/06/24  NB      pr_AMF_ExecuteAction: corrections to ignore FormSequence to find FormMethod when RFFormAction is given
  pr_AMF_ExecuteAction: Execute method based upon RFFormAction, Clean up
  2019/06/13  RIA     pr_AMF_ExecuteAction: Changes to show #Cartons / Totes in droppallet for pause pick (CID-562)
  2019/06/11  NB      pr_AMF_ExecuteAction: changes to validate Data and UIInfo returned by transaction procedure(CIMSV3-573)
  2019/06/10  NB      pr_AMF_ExecuteAction: changes to handle returning Outstanding Picks info for drop Cart during Batch Picking(CIMSV3-572)
  2019/06/08  RIA     pr_AMF_ExecuteAction: Changes for ConfirmPickTasks (CID-518)
  2019/05/23  SV      pr_AMF_ExecuteAction: Added CoO to the result set (CID-135)
  2019/05/22  VS      pr_AMF_ExecuteAction: Get the correct Message for Confirm Batch Pick (CID-262)
  2019/05/15  RIA     pr_AMF_ExecuteAction: Made changes to consider WorkFlowName in generic way (CIMSV3-464)
  2019/05/03  NB      pr_AMF_ExecuteAction: Added success message for ConfirmBatchPick and Minor corrections(CID-262)
  2019/04/19  OK      pr_AMF_ExecuteAction: Changes to send the DefaultToLPN value irrespective of AutoInitializeToLPN value (CID-308)
  2019/04/16  NB      pr_AMF_ExecuteAction: Added checks to validate Pallet drop on Pause Picking (CID-288),
  2019/04/08  NB      pr_AMF_ExecuteAction: Return success message on pick completion(CID-262)
  2019/03/13  NB      Modified pr_AMF_ExecuteAction to process Location Inquiry(CIMSV3-389)
  pr_AMF_ExecuteAction: modified to consider FormSequence to identify db procedure, for drop pallet
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_ExecuteAction') is not null
  drop Procedure pr_AMF_ExecuteAction;

Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_ExecuteAction:

  Processes the input request, retrieves details of transaction sent from caller,
  identifies RFC procedure to call. Builds the V2 input from AMF format and
  invokes the transaction procedure
  captures the response from transaction procedure, builds the the response in AMF format
  returns the same to caller

  InputXML format would be as follows

  <Root>
    <UIInfo>
      <WorkFlowName></WorkFlowName>
      <FormName></FormName>
    </UIInfo>
    <SessionInfo>
      <UserName></UserName>
      <DeviceId></DeviceId>
      <BusinessUnit></BusinessUnit>
    </SessionInfo>
    <Data>
      ...
      ...
      ...
    </Data>
  </Root>

  UIInfo..is the current form and work flow information. this will be used in identifying the processing details for the request and
          also useful in identying the next step in the work flow by evaluating the result of execution
  SessionInfo..is the device, user and businessunit of the caller. This will be useful for logging, audit trail etc.,.
  Data..This is the parent node for all the input information from the application. each node within the data element could be the user input in the form
        or the information passed back from ui for verification or validation

  OutputXML format would be as follows

  <Result>
    <UIInfo>
      <WorkFlowName></WorkFlowName>
      <FormName></FormName>
    </UIInfo>
    <Data>
      ...
      ...
      ...
    </Data>
    <Errors>
      <Messages>
        <Message>
          <DisplayText>...</DisplayText>
        </Message>
        <Message>
          <DisplayText>...</DisplayText>
        </Message>
        ...
        ...
      </Messages>
    </Errors>
    <Info>
      <Messages>
        <Message>
          <DisplayText>...</DisplayText>
        </Message>
        <Message>
          <DisplayText>...</DisplayText>
        </Message>
        ...
        ...
      </Messages>
    </Info>
     <Warnings>
      <Messages>
        <Message>
          <DisplayText>...</DisplayText>
        </Message>
        <Message>
          <DisplayText>...</DisplayText>
        </Message>
        ...
        ...
      </Messages>
    </Warnings>
  </Result>

  UIInfo..the next form to pull from database and display to the user
  Data..Transaction relevant data. This information is processed by application, and the form is filled with details of the child nodes of ths data, priori
        to displaying to the user
  Errors..Messages to displayed as errors to the user
  Info..Messages to be displayed as success messages to the user
  Warnings..Messages to be displayed as warnings to the user

------------------------------------------------------------------------------*/
Create Procedure pr_AMF_ExecuteAction
  (@InputXML     TXML,
   @OutputXML    TXML output)
as
  declare @vInputXML             xml,
          @vUserId               TName,
          @vUserName             TName,
          @vBusinessUnit         TBusinessUnit,
          @vDeviceId             TDeviceId,
          @vDeviceName           TName,
          @vWarehouse            TWarehouse,
          @vCultureName          TName,
          @vFormName             TName,
          @vFormMethod           TName,
          @vWorkFlowName         TName,
          @vFormSequence         TSortSeq,
          @vrfcProcInputxml      xml,
          @vrfcProcOutputxml     xml,
          @sIsError              TFlag = 'N',
          @vErrorMessage         TMessage,
          @vErrorNumber          TMessage,
          @vSuccessMessage       TMessage,
          @vMessagesXML          TMessage,
          @vErrorXML             TXML,
          @vWarningsXML          TXML,
          @vInfoXML              TXML,
          @vDataXML              TXML,
          @vUIInfoXML            TXML,
          @vLogInfoXML           TXML,
          @vTransactionFailed    TBoolean,
          @vRFFormAction         TMessageName,
          @vSQL                  TNVarChar,
          @vSQLParams            TNVarChar,
          @vOutputXMLOUT         TXML,    /* output variable for dynamic sql call */
          @vActivityLogId        TRecordId,
          @vxmlDataXML           xml,
          @vxmlErrorXML          xml,
          @vxmlInfoXML           xml,
          @vxmlUIInfoXML         xml,
          /* Picking related variables */
          @vAutoInitializeToLPN  TFlags,
          @vPickToLPN            TLPN,
          @vNextPickFromLocation TLocation,
          @vNextPickFromLPN      TLPN,
          @vPalletToDrop         TPallet,
          @vPalletStatus         TStatus,
          @vCurrentPickingResponse TXML,
          @vxmlCurrrentPickResponse xml,
          @vxmlCurrrentPickList     xml,
          @vCurrrentPickList        TXML,
          @vPalletDetails           xml,
          @vPalletUnitsPicked       TInteger,
          /* Drop Pallet related variables */
          @vTaskId               TRecordid,
          @vTaskInfoxml          TXML,
          @vOutstandingPicksxml  xml,
          @vOutstandingPicks     TXML,
          @vTempxml              TXML,
          @vDropLocation         TLocation;
          /* Functional variables */
  declare @SKUDetails         TDataTableSKUDetails,
          @ttResultMessages   TResultMessagesTable;
begin /* pr_AMF_ExecuteAction */
begin try
  select @vInputXML = convert(xml, @InputXML);

  /* read session information */
  select @vUserName     = Record.Col.value('UserName[1]',    'TUserId'),
         @vDeviceId     = Record.Col.value('DeviceId[1]',    'TDeviceId'),
         @vBusinessUnit = Record.Col.value('BusinessUnit[1]','TBusinessUnit')
  from @vInputXML.nodes('/Root/SessionInfo') as Record(Col)
  OPTION (OPTIMIZE FOR (@vInputXML = null));

  /* read ui information */
  select @vWorkFlowName = Record.Col.value('WorkFlowName[1]', 'TName'),
         @vFormName     = Record.Col.value('FormName[1]',     'TName'),
         @vFormSequence = Record.Col.value('FormSequence[1]', 'TSortSeq')
  from @vInputXML.nodes('/Root/UIInfo') as Record(Col)
  OPTION (OPTIMIZE FOR (@vInputXML = null));

  select @vRFFormAction = Record.Col.value('RFFormAction[1]', 'TMessageName')
  from @vInputXML.nodes('/Root/Data') as Record(Col)
  OPTION (OPTIMIZE FOR (@vInputXML = null));

  /* Read data xml node from Input */
  select @vDataXML   = convert(varchar(max), @vInputXML.query('Root/Data')),
         @vUIInfoXML = convert(varchar(max), @vInputXML.query('Root/UIInfo'));

  if (@vWorkFlowName like 'Inquiry%')
    begin
      /* Get the user logged in WH */
      select @vWarehouse = Warehouse
      from Devices
      where DeviceId = @vDeviceId + '@' + @vUserName;

      select @vUserId = @vUserName + '@' + 'Inquiry';
      /* Add or Update Device */
      exec pr_Device_AddOrUpdate @vDeviceId, 'RF', @vUserId, @vWarehouse, null /* Printer */,
                                 @vBusinessUnit, 'Inquiry';

      select @vDeviceName = @vDeviceId + '@' + @vUserId;
    end
  else
  if (@vWorkFlowName = 'Inventory_CreateInvLPN')
    begin
      /* Get the user logged in WH */
      select @vWarehouse = Warehouse
      from Devices
      where DeviceId = @vDeviceId + '@' + @vUserName;

      select @vUserId = @vUserName + '@' + 'Inventory';
      /* Add or Update Device */
      exec pr_Device_AddOrUpdate @vDeviceId, 'RF', @vUserId, @vWarehouse, null /* Printer */,
                                 @vBusinessUnit, 'Inventory';

      select @vDeviceName = @vDeviceId + '@' + @vUserId;
    end
  else
  if (@vWorkFlowName = 'Misc_ConfigurePrinter')
    begin
      /* Get the user logged in WH */
      select @vWarehouse = Warehouse
      from Devices
      where DeviceId = @vDeviceId + '@' + @vUserName;

      select @vUserId = @vUserName + '@' + 'ConfigurePrinter';
      /* Add or Update Device */
      exec pr_Device_AddOrUpdate @vDeviceId, 'RF', @vUserId, @vWarehouse, null /* Printer */,
                                 @vBusinessUnit, 'ConfigurePrinter';

      select @vDeviceName = @vDeviceId + '@' + @vUserId;
    end
  else
    select @vDeviceName = @vDeviceId + '@' + @vUserName;

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @Inputxml, @@ProcId, @vBusinessUnit, @vUserName, @vDeviceName,
                      null, null, null, @vWorkFlowName /* Operation */, null /* Message */,
                      @vFormName, @vFormSequence, @vRFFormAction, -- Value 1, 2 & 3
                      @ActivityLogId = @vActivityLogId output;

  select @vLogInfoXML = dbo.fn_XMLNode('LogInfo', @vWorkFlowName + '-' + @vFormName + '#' + dbo.fn_Str(@vActivityLogId));

  /* Create hash table if it does not exist, which is used in many places */
  if object_id('tempdb..#DataTableSKUDetails') is null
    select * into #DataTableSKUDetails from @SKUDetails;

  /* Create hash table to insert messages to show in RF */
  if object_id('tempdb..#ResultMessages') is null
    select * into #ResultMessages from @ttResultMessages;

  /* Verify work flow and form name, and call relevant transaction procedure */
  if (@vWorkFlowName in ('BatchPicking', 'ReplenishBatchPicking'))
    begin
      select @vRFFormAction     = Record.Col.value('RFFormAction[1]', 'TMessageName')
      from @vInputXML.nodes('/Root/Data') as Record(Col)
      OPTION (OPTIMIZE FOR (@vInputXML = null));

      /* Users can attempt to pause or stop picking from sub menu in the UI. Verify if such an action was performed and process */
      if (coalesce(@vRFFormAction, '') = 'PAUSEPICKING')
        begin
          select @vrfcProcInputxml = (select Record.Col.value('(SessionInfo/DeviceId)[1]',              'TDeviceId'    ) as DeviceId,
                                             Record.Col.value('(SessionInfo/UserName)[1]',              'TUserId'      ) as UserId,
                                             Record.Col.value('(SessionInfo/BusinessUnit)[1]',          'TBusinessUnit') as BusinessUnit,
                                             Record.Col.value('(Data/m_BATCHPICKINFOBatchNo)[1]',       'TPickBatchNo' ) as PickBatchNo,
                                             Record.Col.value('(Data/m_BATCHPICKINFOPickToPallet)[1]',  'TPallet'      ) as Pallet,
                                             Record.Col.value('(Data/m_BATCHPICKINFOTaskId)[1]',        'TRecordId'    ) as TaskId,
                                             Record.Col.value('(Data/m_BATCHPICKINFOTaskDetailId)[1]',  'TRecordId'    ) as TaskDetailId
                                      from @vInputXML.nodes('/Root') as Record(Col)
                                      for xml raw('ConfirmBatchPause'), elements);

          exec pr_RFC_Picking_PauseBatch @vrfcProcInputxml, @vrfcProcOutputxml output;
          select @vTransactionFailed = dbo.fn_AMF_TransactionFailed(@vrfcProcOutputxml);
          if (@vTransactionFailed <= 0)
            begin
              /* Validate if the Pallet should be dropped */
              select @vPalletUnitsPicked    = Record.Col.value('UnitsPicked[1]',  'TInteger'),
                     @vPalletStatus         = Record.Col.value('PalletStatus[1]', 'TStatus'),
                     @vErrorNumber          = Record.Col.value('ErrorNumber[1]',  'TMessage'),
                     @vErrorMessage         = Record.Col.value('ErrorMessage[1]', 'TMessage')
              from @vrfcProcOutputxml.nodes('/BATCHPAUSEDETAILS/BATCHPAUSEINFO')  as Record(Col)
              OPTION (OPTIMIZE FOR (@vrfcProcOutputxml = null));

              select @vPalletToDrop = null;
              /* when there are units picked, then drop cart must be suggested */
              if (coalesce(@vPalletUnitsPicked, 0) > 0) and (@vPalletStatus <> 'E' /* Empty */) and
                  ((coalesce(@vErrorNumber, '') = '0') and (coalesce(@vErrorMessage, '') <> ''))
                begin
                  select @vInfoXML = dbo.fn_AMF_BuildSuccessXML(@vErrorMessage);

                  select @vErrorNumber = null, @vErrorMessage = null; -- reset vars as their purpose for this validation is over
                  select @vrfcProcInputxml = (select Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ) as DeviceId,
                                                     Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ) as UserId,
                                                     Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit') as BusinessUnit,
                                                     Record.Col.value('(Data/m_BATCHPICKINFOPickToPallet)[1]', 'TPallet'      ) as Pallet,
                                                     --Record.Col.value('(Data/Operation)[1]',                  'TDescription' ) as Operation,
                                                     'DropPallet' as Operation,
                                                     Record.Col.value('(Data/m_BATCHPICKINFOTaskId)[1]',        'TRecordId'    ) as TaskId
                                              from @vInputXML.nodes('/Root') as Record(Col)
                                              for xml raw('DropPalletInfo'), elements);

                   /* Build the xml in the format expected by the ValidatePallet procedure */
                   select @vrfcProcInputxml = convert(xml, dbo.fn_XMLNode('ValidateDropPallet', convert(varchar(max), @vrfcProcInputxml)));

                   exec pr_RFC_Picking_ValidatePallet @vrfcProcInputxml, @vrfcProcOutputxml  output;
                   select @vTransactionFailed = dbo.fn_AMF_TransactionFailed(@vrfcProcOutputxml);
                   if (@vTransactionFailed <= 0)
                     begin
                       /* Read PalletId from response, to ascertain response returned has drop pallet detail */
                       select @vPalletToDrop = Record.Col.value('(Pallet)[1]',  'TPallet'),
                              @vTaskId       = Record.Col.value('(TaskId)[1]',  'TRecordId')
                       from @vrfcProcOutputxml.nodes('/ValidateDropPallet/DropPalletResponse') as Record(Col)
                       OPTION (OPTIMIZE FOR (@vrfcProcOutputxml = null));
                     end
                end
            end
        end
      else /* if (coalesce(@vRFFormAction, '') = 'PAUSEPICKING') */
      if (coalesce(@vRFFormAction, '') = 'SKIPCURRENTPICK')
        begin
          select @vrfcProcInputxml = (select Record.Col.value('(SessionInfo/DeviceId)[1]',              'TDeviceId'    ) as DeviceId,
                                             Record.Col.value('(SessionInfo/UserName)[1]',              'TUserId'      ) as UserId,
                                             Record.Col.value('(SessionInfo/BusinessUnit)[1]',          'TBusinessUnit') as BusinessUnit,
                                             Record.Col.value('(Data/m_BATCHPICKINFOBatchNo)[1]',       'TPickBatchNo' ) as PickBatchNo,
                                             Record.Col.value('(Data/m_BATCHPICKINFOPickZone)[1]',      'TZoneId'      ) as PickZone,
                                             Record.Col.value('(Data/m_BATCHPICKINFOPickTicket)[1]',    'TPickTicket'  ) as PickTicket,
                                             Record.Col.value('(Data/m_BATCHPICKINFOPickToPallet)[1]',  'TPallet'      ) as PickingPallet,
                                             Record.Col.value('(Data/m_BATCHPICKINFOOrderDetailId)[1]', 'TRecordId'    ) as OrderDetailId,
                                             Record.Col.value('(Data/m_BATCHPICKINFOSKU)[1]',           'TSKU'         ) as FromSKU,
                                             Record.Col.value('(Data/m_BATCHPICKINFOLPN)[1]',           'TLPN'         ) as FromLPN,
                                             Record.Col.value('(Data/m_BATCHPICKINFOLPNId)[1]',         'TRecordId'    ) as FromLPNId,
                                             Record.Col.value('(Data/m_BATCHPICKINFOLPNDetailId)[1]',   'TRecordId'    ) as FromLPNDetailId,
                                             Record.Col.value('(Data/m_BATCHPICKINFOPickType)[1]',      'TTypeCode'    ) as PickType,
                                             Record.Col.value('(Data/m_BATCHPICKINFOTaskId)[1]',        'TRecordId'    ) as TaskId,
                                             Record.Col.value('(Data/m_BATCHPICKINFOTaskDetailId)[1]',  'TRecordId'    ) as TaskDetailId,
                                             Record.Col.value('(Data/PickedTo)[1]',                     'TLPN'         ) as ToLPN,
                                             Record.Col.value('(Data/SKUPicked)[1]',                    'TLPN'         ) as SKUPicked,
                                             Record.Col.value('(Data/LPNPicked)[1]',                    'TLPN'         ) as LPNPicked,
                                             Record.Col.value('(Data/PickedUnits)[1]',                  'TInteger'     ) as UnitsPicked,
                                             Record.Col.value('(Data/PickedFromLocation)[1]',           'TLocation'    ) as PickedFromLocation,
                                             Record.Col.value('(Data/PickUoM)[1]',                      'TUoM'         ) as PickUoM,
                                             Record.Col.value('(Data/ShortPick)[1]',                    'TFlag'        ) as ShortPick,
                                             Record.Col.value('(Data/LocationEmpty)[1]',                'TFlags'       ) as LocationEmpty,
                                             Record.Col.value('(Data/ConfirmLocationEmpty)[1]',         'TFlags'       ) as ConfirmLocationEmpty,
                                             Record.Col.value('(Data/DestZone)[1]',                     'TLookUpCode'  ) as DestZone,
                                             Record.Col.value('(Data/Operation)[1]',                    'TDescription' ) as Operation,
                                             Record.Col.value('(Data/SelectedPickMode)[1]',             'TDescription' ) as PickMode,
                                             Record.Col.value('(Data/m_OPTIONSPickingMode)[1]',         'TDescription' ) as PickingType,
                                             Record.Col.value('(Data/m_BATCHPICKINFOPickGroup)[1]',     'TPickGroup'   ) as PickGroup
                                      from @vInputXML.nodes('/Root') as Record(Col)
                                      for xml raw('ConfirmBatchPick'), elements);

          exec pr_RFC_Picking_SkipBatchPick @vrfcProcInputxml, @vrfcProcOutputxml output;
          select @vTransactionFailed = dbo.fn_AMF_TransactionFailed(@vrfcProcOutputxml);

           /* TODO TODO DUPLICATE CODE.. This below if condition is a duplicate of code after call to pr_RFC_Picking_ConfirmUnitPick
              TODO TODO This should be optimized into one code instead of two */
           if (@vTransactionFailed <= 0)
             begin
               /* Verify whether the task pick is completed, and there are no more picks left */
               select @vNextPickFromLocation  = Record.Col.value('Location[1]',    'TLocation'),
                      @vNextPickFromLPN       = Record.Col.value('LPN[1]',         'TLPN'),
                      @vErrorNumber           = Record.Col.value('ErrorNumber[1]', 'TMessage'),
                      @vErrorMessage          = Record.Col.value('ErrorMessage[1]', 'TMessage')
               from @vrfcProcOutputxml.nodes('/BATCHPICKDETAILS/BATCHPICKINFO')  as Record(Col)
               OPTION (OPTIMIZE FOR (@vrfcProcOutputxml = null));

               /* when there is no next pick location and pick from LPN, and the response has ErrorNumber as 0 with Error Message, then
                  it means that ConfirmBatchPick has returned all picks completed message
                  TODO TODO TODO..pr_RFC_Picking_ConfirmBatchPick must be enhanced to return a code or message indicating type of response */
               if ((coalesce(@vNextPickFromLocation, '') = '') and (coalesce(@vNextPickFromLPN, '') = '')  and
                   (coalesce(@vErrorNumber, '') = '0') and  (coalesce(@vErrorMessage, '') <> ''))
                 begin
                   select @vErrorNumber = null, @vErrorMessage = null; -- reset vars as their purpose for this validation is over
                   select @vrfcProcInputxml = (select Record.Col.value('(SessionInfo/DeviceId)[1]',             'TDeviceId'    ) as DeviceId,
                                                      Record.Col.value('(SessionInfo/UserName)[1]',             'TUserId'      ) as UserId,
                                                      Record.Col.value('(SessionInfo/BusinessUnit)[1]',         'TBusinessUnit') as BusinessUnit,
                                                      Record.Col.value('(Data/m_BATCHPICKINFOPickToPallet)[1]',  'TPallet'      ) as Pallet,
                                                      --Record.Col.value('(Data/Operation)[1]',                  'TDescription' ) as Operation,
                                                      'DropPallet' as Operation,
                                                      Record.Col.value('(Data/m_BATCHPICKINFOTaskId)[1]',        'TRecordId'    ) as TaskId
                                               from @vInputXML.nodes('/Root') as Record(Col)
                                               for xml raw('DropPalletInfo'), elements);

                    /* Build the xml in the format expected by the ValidatePallet procedure */
                    select @vrfcProcInputxml = convert(xml, dbo.fn_XMLNode('ValidateDropPallet', convert(varchar(max), @vrfcProcInputxml)));

                    exec pr_RFC_Picking_ValidatePallet @vrfcProcInputxml, @vrfcProcOutputxml  output;
                    select @vTransactionFailed = dbo.fn_AMF_TransactionFailed(@vrfcProcOutputxml);
                    if (@vTransactionFailed <= 0)
                      begin
                        /* Read PalletId from response, to ascertain response returned has drop pallet detail */
                        select @vPalletToDrop = Record.Col.value('(Pallet)[1]',  'TPallet'),
                               @vTaskId       = Record.Col.value('(TaskId)[1]',  'TRecordId')
                        from @vrfcProcOutputxml.nodes('/ValidateDropPallet/DropPalletResponse') as Record(Col)
                        OPTION (OPTIMIZE FOR (@vrfcProcOutputxml = null));
                      end
                 end
             end
        end
      else /* if (coalesce(@vRFFormAction, '') = 'SKIPCURRENTPICK') */
      if (@vFormName in ('BatchPicking_GetPickTask', 'Replenishment_GetPickTask'))
        begin
          /* Build V2 Input Xml for GetBatchPick procedure */
          select @vrfcProcInputxml = (select Record.Col.value('(SessionInfo/DeviceId)[1]',       'TDeviceId'    ) as DeviceId,
                                             Record.Col.value('(SessionInfo/UserName)[1]',       'TUserId'      ) as UserId,
                                             Record.Col.value('(SessionInfo/BusinessUnit)[1]',   'TBusinessUnit') as BusinessUnit,
                                             Record.Col.value('(Data/WaveNo)[1]',                'TPickBatchNo' ) as PickBatchNo,
                                             Record.Col.value('(Data/TaskId)[1]',                'TRecordId'    ) as TaskId,
                                             Record.Col.value('(Data/PickZone)[1]',              'TZoneId'      ) as PickZone,
                                             Record.Col.value('(Data/DestZone)[1]',              'TZoneId'      ) as DestZone,
                                             Record.Col.value('(Data/PickTicket)[1]',            'TPickTicket'  ) as PickTicket,
                                             Record.Col.value('(Data/PickingPallet)[1]',         'TPallet'      ) as Pallet,
                                             Record.Col.value('(Data/PickGroup)[1]',             'TPickGroup'   ) as PickGroup,
                                             Record.Col.value('(Data/PickType)[1]',              'TTypeCode'    ) as PickType,
                                             Record.Col.value('(Data/Operation)[1]',             'TDescription' ) as Operation
                                      from @vInputXML.nodes('/Root') as Record(Col)
                                      for xml raw('GetBatchPick'), elements);

          exec pr_RFC_Picking_GetBatchPick @vrfcProcInputxml, @vrfcProcOutputxml output;
          select @vTransactionFailed = dbo.fn_AMF_TransactionFailed(@vrfcProcOutputxml);

        end /* if (@vFormName = 'BatchPicking_GetPickTask' ) */
      else
      if (@vFormName in ('BatchPicking_ConfirmUnitPick', 'BatchPicking_ConfirmLPNPick', 'Replenishment_ConfirmUnitPick'))
        begin
          /* Build V2 Procedure input */
          select @vrfcProcInputxml = (select Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ) as DeviceId,
                                             Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ) as UserId,
                                             Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit') as BusinessUnit,
                                             Record.Col.value('(Data/m_BATCHPICKINFOBatchNo)[1]',       'TPickBatchNo' ) as PickBatchNo,
                                             Record.Col.value('(Data/m_BATCHPICKINFOPickZone)[1]',      'TZoneId'      ) as PickZone,
                                             Record.Col.value('(Data/m_BATCHPICKINFOPickTicket)[1]',    'TPickTicket'  ) as PickTicket,
                                             Record.Col.value('(Data/m_BATCHPICKINFOPickToPallet)[1]',  'TPallet'      ) as PickingPallet,
                                             Record.Col.value('(Data/m_BATCHPICKINFOOrderDetailId)[1]', 'TRecordId'    ) as OrderDetailId,
                                             Record.Col.value('(Data/m_BATCHPICKINFOSKU)[1]',           'TSKU'         ) as FromSKU,
                                             Record.Col.value('(Data/m_BATCHPICKINFOLPN)[1]',           'TLPN'         ) as FromLPN,
                                             Record.Col.value('(Data/m_BATCHPICKINFOLPNId)[1]',         'TRecordId'    ) as FromLPNId,
                                             Record.Col.value('(Data/m_BATCHPICKINFOLPNDetailId)[1]',   'TRecordId'    ) as FromLPNDetailId,
                                             Record.Col.value('(Data/m_BATCHPICKINFOPickType)[1]',      'TTypeCode'    ) as PickType,
                                             Record.Col.value('(Data/m_BATCHPICKINFOTaskId)[1]',        'TRecordId'    ) as TaskId,
                                             Record.Col.value('(Data/m_BATCHPICKINFOTaskDetailId)[1]',  'TRecordId'    ) as TaskDetailId,
                                             Record.Col.value('(Data/m_BATCHPICKINFOConfirmScanOption)[1]', 'TControlValue') as ConfirmScanOption,
                                             Record.Col.value('(Data/PickedTo)[1]',                   'TLPN'         ) as ToLPN,
                                             Record.Col.value('(Data/CoO)[1]',                        'TCoO'         ) as CoO,
                                             Record.Col.value('(Data/PickedEntity)[1]',               'TEntityKey'   ) as ScannedEntity,
                                             Record.Col.value('(Data/SKUPicked)[1]',                  'TLPN'         ) as SKUPicked,
                                             Record.Col.value('(Data/LPNPicked)[1]',                  'TLPN'         ) as LPNPicked,
                                             Record.Col.value('(Data/PickedUnits)[1]',                'TInteger'     ) as UnitsPicked,
                                             Record.Col.value('(Data/PickedFromLocation)[1]',         'TLocation'    ) as PickedFromLocation,
                                             Record.Col.value('(Data/PickUoM)[1]',                    'TUoM'         ) as PickUoM,
                                             Record.Col.value('(Data/ShortPick)[1]',                  'TFlag'        ) as ShortPick,
                                             Record.Col.value('(Data/LocationEmpty)[1]',              'TFlags'       ) as LocationEmpty,
                                             Record.Col.value('(Data/ConfirmLocationEmpty)[1]',       'TFlags'       ) as ConfirmLocationEmpty,
                                             Record.Col.value('(Data/DestZone)[1]',                   'TLookUpCode'  ) as DestZone,
                                             Record.Col.value('(Data/Operation)[1]',                  'TDescription' ) as Operation,
                                             Record.Col.value('(Data/SelectedPickMode)[1]',           'TDescription' ) as PickMode,
                                             Record.Col.value('(Data/m_OPTIONSPickingMode)[1]',         'TDescription' ) as PickingType,
                                             Record.Col.value('(Data/m_BATCHPICKINFOPickGroup)[1]',     'TPickGroup'   ) as PickGroup
                                      from @vInputXML.nodes('/Root') as Record(Col)
                                      for xml raw('ConfirmBatchPick'), elements);

          exec pr_RFC_Picking_ConfirmBatchPick @vrfcProcInputxml, @vrfcProcOutputxml output;

          select @vTransactionFailed = dbo.fn_AMF_TransactionFailed(@vrfcProcOutputxml);

          if (@vTransactionFailed <= 0)
            begin
              /* Verify whether the task pick is completed, and there are no more picks left */
              select @vNextPickFromLocation  = Record.Col.value('Location[1]',     'TLocation'),
                     @vNextPickFromLPN       = Record.Col.value('LPN[1]',          'TLPN'),
                     @vErrorNumber           = Record.Col.value('ErrorNumber[1]',  'TMessage'),
                     @vErrorMessage          = Record.Col.value('ErrorMessage[1]', 'TMessage')
              from @vrfcProcOutputxml.nodes('/BATCHPICKDETAILS/BATCHPICKINFO')  as Record(Col)
              OPTION (OPTIMIZE FOR (@vrfcProcOutputxml = null));

              /* when there is no next pick location and pick from LPN, and the response has ErrorNumber as 0 with Error Message, then
                 it means that ConfirmBatchPick has returned all picks completed message
                 TODO TODO TODO..pr_RFC_Picking_ConfirmBatchPick must be enhanced to return a code or message indicating type of response */
              if ((coalesce(@vNextPickFromLocation, '') = '') and (coalesce(@vNextPickFromLPN, '') = '')  and
                  (coalesce(@vErrorNumber, '') = '0') and  (coalesce(@vErrorMessage, '') <> ''))
                   begin
                     select @vInfoXML = dbo.fn_AMF_BuildSuccessXML(@vErrorMessage);

                     select @vErrorNumber = null, @vErrorMessage = null; -- reset vars as their purpose for this validation is over
                     select @vrfcProcInputxml = (select Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ) as DeviceId,
                                                        Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ) as UserId,
                                                        Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit') as BusinessUnit,
                                                        Record.Col.value('(Data/m_BATCHPICKINFOPickToPallet)[1]',  'TPallet'      ) as Pallet,
                                                        --Record.Col.value('(Data/Operation)[1]',                  'TDescription' ) as Operation,
                                                        'DropPallet' as Operation,
                                                        Record.Col.value('(Data/m_BATCHPICKINFOTaskId)[1]',        'TRecordId'    ) as TaskId
                                                 from @vInputXML.nodes('/Root') as Record(Col)
                                                 for xml raw('DropPalletInfo'), elements);
                      /* Build the xml in the format expected by the ValidatePallet procedure */
                      select @vrfcProcInputxml = convert(xml, dbo.fn_XMLNode('ValidateDropPallet', convert(varchar(max), @vrfcProcInputxml)));

                      exec pr_RFC_Picking_ValidatePallet @vrfcProcInputxml, @vrfcProcOutputxml  output;

                      /* Read PalletId from response, to ascertain response returned has drop pallet detail */
                      select @vPalletToDrop = Record.Col.value('(Pallet)[1]',  'TPallet'),
                             @vTaskId       = Record.Col.value('(TaskId)[1]',  'TRecordId')
                      from @vrfcProcOutputxml.nodes('/ValidateDropPallet/DropPalletResponse') as Record(Col)
                      OPTION (OPTIMIZE FOR (@vrfcProcOutputxml = null));
                   end
                 else
                   begin
                     /* build confirmation message indicating the completion of pick */
                     select @vSuccessMessage =  dbo.fn_Messages_Build('BatchPicking_UnitsPickSuccessful',
                                                                       Record.Col.value('(Data/PickedUnits)[1]',                 'TInteger'    ),
                                                                       Record.Col.value('(Data/m_BATCHPICKINFOPickUoM)[1]',      'TUoM'        ),
                                                                       Record.Col.value('(Data/m_BATCHPICKINFOPickToPallet)[1]', 'TPallet'     ),
                                                                       Record.Col.value('(Data/m_BATCHPICKINFOTaskId)[1]',       'TRecordId'   ),
                                                                       Record.Col.value('(Data/m_BATCHPICKINFOBatchNo)[1]',      'TPickBatchNo'))
                     from @vInputXML.nodes('/Root') as Record(Col)
                     OPTION (OPTIMIZE FOR (@vInputXML = null));

                     select @vInfoXML = dbo.fn_AMF_BuildSuccessXML(@vSuccessMessage);
                   end
           end
        end /* if (@vFormName = 'BatchPicking_ConfirmUnitPick') */
      else
      if (@vFormName in ('DropPickingCart_Confirm', 'DropPickingPallet_Confirm'))
        begin
          select @vDeviceId     = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ),
                 @vUserName     = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
                 @vBusinessUnit = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'),
                 @vPalletToDrop = Record.Col.value('(Data/Pallet)[1]',                     'TPallet'      ),
                 @vDropLocation = Record.Col.value('(Data/DroppedLocation)[1]',            'TLocation'    ),
                 @vTaskId       = Record.Col.value('(Data/m_TaskInfo_TaskId)[1]',          'TRecordId'    )
          from @vInputXML.nodes('/Root') as Record(Col)
          OPTION (OPTIMIZE FOR (@vInputXML = null));

          exec pr_RFC_Picking_DropPickedPallet @vDeviceId, @vUserName, @vBusinessUnit, @vPalletToDrop, @vDropLocation, @vTaskId,
                                               @vrfcProcOutputxml output;

          select @vTransactionFailed = dbo.fn_AMF_TransactionFailed(@vrfcProcOutputxml);

          /* Get the success message */
          select @vSuccessMessage = Record.Col.value('(ErrorMessage)[1]',   'TMessage')
          from @vrfcProcOutputxml.nodes('/DROPPEDPALLETDETAILS/DROPPEDPALLETINFO') as Record(Col);

          select @vInfoXML = dbo.fn_AMF_BuildSuccessXML(@vSuccessMessage);
        end /* (@vFormName = 'DropPickingPallet_DropPallet') */

      /* Transform output to AMF Format, if successful transaction */
      if (@vTransactionFailed <= 0)
        begin
          if ((coalesce(@vRFFormAction, '') = 'PAUSEPICKING') and (@vPalletToDrop is null))
            begin
              select @vSuccessMessage =  Record.Col.value('(ErrorMessage)[1]', 'TMessage'    )
              from @vrfcProcOutputxml.nodes('/BATCHPAUSEDETAILS/BATCHPAUSEINFO') as Record(Col)
              OPTION (OPTIMIZE FOR (@vrfcProcOutputxml = null));

              select @vInfoXML = dbo.fn_AMF_BuildSuccessXML(@vSuccessMessage);

              select @vDataXML = '';
              with ResponseDetails as
              (
                select dbo.fn_XMLNode('BATCHPAUSEINFO' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) ResponseDetail
                from @vrfcProcOutputxml.nodes('/BATCHPAUSEDETAILS/BATCHPAUSEINFO/*') as t(c)
              )
              select @vDataXML = @vDataXML + ResponseDetail from ResponseDetails;

              select @vDataXML = dbo.fn_XMLNode('Data', @vDataXML);
            end
          else
          if ((@vFormName in ('BatchPicking_ConfirmUnitPick', 'BatchPicking_ConfirmLPNPick', 'Replenishment_ConfirmUnitPick')) and
              (@vPalletToDrop is not null)) /* If the Pallet has to be dropped */
            begin
              /* Get Task info to fill the form */
              exec pr_AMF_Info_GetTaskInfoXML @vTaskId, 'PalletToDrop', @vTaskInfoXML output;

              /* Get PalletDetails as XML from vwPallets for the Input Pallet */
              with PalletCounts
              as
              (
                select Min(SKU) PalletSKU, Min(SKUDescription) PalletSKUDescription, count(distinct SKUId) SKUCount, count(distinct LPNId) LPNCount,
                sum(Quantity) TotalQty, count(distinct OrderId) OrderCount
                from vwLPNDetails where PalletId in (select PalletId from Pallets where Pallet = @vPalletToDrop)
                )
              select @vPalletDetails = (
                                        select case when SKUCount > 1 then 'Multiple' else PalletSKU end as SKU,
                                        case when SKUCount > 1 then 'Multiple' else PalletSKUDescription end as SKUDescription,
                                        *
                                        from PalletCounts for xml raw('PalletDetails'), Elements);

              select @vDataXML = '';
              with ResponseDetails as
              (
                select dbo.fn_XMLNode('DROPPALLETRESPONSE' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) ResponseDetail
                from @vrfcProcOutputxml.nodes('/ValidateDropPallet/DropPalletResponse/*') as t(c)
                union
                select dbo.fn_XMLNode('PALLETDETAILS' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) ResponseDetail
                from @vPalletDetails.nodes('/PalletDetails/*') as t(c)
                -- union
                -- select dbo.fn_XMLNode('TASKINFO' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) ResponseDetail
                -- from @vTaskInfoxml.nodes('/TASKINFO/*') as t(c)
              )
              select @vDataXML = @vDataXML + ResponseDetail from ResponseDetails;

              exec pr_AMF_Info_GetOutstandingPicks @vTaskId, @vOutstandingPicks output, @vOutstandingPicksxml output;

              select @vDataXML = dbo.fn_XmlNode('Data', @vDataXML + coalesce(@vTaskInfoXML, '') + coalesce(@vOutstandingPicks, ''));
            end
          else
          if (@vFormName in ('DropPickingCart_Confirm', 'DropPickingPallet_Confirm'))
            begin
              select @vDataXML = '';
              with ResponseDetails as
              (
                select dbo.fn_XMLNode('DROPPEDPALLETINFO' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) ResponseDetail
                from @vrfcProcOutputxml.nodes('/DROPPEDPALLETDETAILS/DROPPEDPALLETINFO/*') as t(c)
              )
              select @vDataXML = @vDataXML + ResponseDetail from ResponseDetails;

              select @vDataXML = dbo.fn_XMLNode('Data', @vDataXML);

            end
          else
          if (@vFormName in ('BatchPicking_GetPickTask',  'BatchPicking_ConfirmUnitPick', 'BatchPicking_ConfirmLPNPick',
                             'Replenishment_GetPickTask', 'Replenishment_ConfirmUnitPick' ))
            begin /* Process V2 Response to AMF Format */

              /* Call the pr_AMF_Picking_UnitPick_BuildNextPickResponse to build response */
              exec pr_AMF_Picking_UnitPick_BuildNextPickResponse @vrfcProcOutputxml, @vDataXML output;

            end /* Process V2 Response to AMF Format */

      end

      if (@vTransactionFailed > 0)
        begin
          /* On Error.. return the data from input as is to caller */
          select @vErrorXML = dbo.fn_AMF_BuildErrorXML(@vrfcProcOutputxml);
        end
      else
        begin
          exec pr_AMF_GetNextWorkFlowSequence @vDataXML, @vUIInfoXML output;
        end

    end /* if (@vWorkFlowName = 'BatchPicking') */
  else
  if (exists (select * from AMF_WorkFlowDetails where (WorkFlowName = @vWorkFlowName)))
    begin
      /* Fetch method name for the current form from the work flow details */
      select @vFormMethod = null;

      /* If there is an RF FormAction, then the work flow method changes accordingly */
      if (@vRFFormAction <> '')
        select Top 1
               @vFormMethod = FormMethod
        from AMF_WorkFlowDetails
        where (WorkFlowName = @vWorkFlowName) and
              (FormName     = @vFormName) and
              -- FormSequence must be ignored when FormAction is given
              (FormMethod   is not null) and
              (FormCondition like '%RFFormAction%' +@vRFFormAction +'%');

      /* If isn't a form action, then execute the method of the form */
      if (@vFormMethod is null)
        select Top 1
               @vFormMethod = FormMethod
        from AMF_WorkFlowDetails
        where ((WorkFlowName = @vWorkFlowName) and (FormName = @vFormName) and (FormSequence = coalesce(nullif(@vFormSequence, 0), FormSequence)) and (FormMethod is not null));

      /* Execute form method */
      if (@vFormMethod is not null)
        begin
          select @vSQL       = N'exec ' + @vFormMethod + ' @InputXML, @DataXML output, @UIInfoXML output, @InfoXML output, @ErrorXML output',
                 @vSQLParams = N'@InputXML TXML, @DataXML TXML output, @UIInfoXML TXML output, @InfoXML TXML output, @ErrorXML TXML output';

          exec sp_executesql @vSQL, @vSQLParams, @InputXML = @InputXML, @DataXML = @vDataXML output, @UIInfoXML = @vUIInfoXML output, @InfoXML = @vInfoXML output,  @ErrorXML = @vErrorXML output;

          /* Verify the outputs */
          if (@vDataXML is null) or (@vUIInfoXML is null)
            begin
              /* send back error message if processing was incorrect in the work flow method */
              select @vErrorXML = null;
              if (@vDataXML is null) select @vErrorXML = dbo.fn_AMF_GetMessageXML(@vFormMethod +  ' returned no output for Data');
              if (@vUIInfoXML is null) select @vErrorXML =  coalesce(@vErrorXML, '') + dbo.fn_AMF_GetMessageXML(@vFormMethod +  ' returned no output for UIInfo');
              select @vErrorXML =  dbo.fn_XMLNode('Errors', dbo.fn_XMLNode('Messages', @vErrorXML));

              /* Treat this as an Error in the processing and return the user to same screen as earlier */
              /* Read data xml node from Input */
              select @vDataXML   = convert(varchar(max), @vInputXML.query('Root/Data')),
                     @vUIInfoXML = convert(varchar(max), @vInputXML.query('Root/UIInfo'));
            end
          else
            begin
              /* Verify whether the Data and UIInfo nodes are proper Xml with parent node named correctly defined */
              select @vxmlDataXML = convert(xml, @vDataXML),
                     @vxmlInfoXML = convert(xml, @vUIInfoXML);

               if  ((@vxmlDataXML.exist('Data') = 0) or (@vxmlInfoXML.exist('UIInfo') = 0))
                 begin
                    select @vErrorXML = null;
                    if (@vxmlDataXML.exist('Data') = 0) select @vErrorXML = dbo.fn_AMF_GetMessageXML(@vFormMethod +  ' returned invalid output for Data');
                    if (@vxmlInfoXML.exist('UIInfo') = 0) select @vErrorXML =  coalesce(@vErrorXML, '') + dbo.fn_AMF_GetMessageXML(@vFormMethod +  ' returned invalid output for UIInfo');
                    select @vErrorXML =  dbo.fn_XMLNode('Errors', dbo.fn_XMLNode('Messages', @vErrorXML));

                    /* Treat this as an Error in the processing and return the user to same screen as earlier */
                    /* Read data xml node from Input */
                    select @vDataXML   = convert(varchar(max), @vInputXML.query('Root/Data')),
                           @vUIInfoXML = convert(varchar(max), @vInputXML.query('Root/UIInfo'));
                 end
            end

          /* If the transaction was successful, compute the next step in the work flow */
          if (@vErrorXML is null)
            begin
              exec pr_AMF_GetNextWorkFlowSequence @vDataXML, @vUIInfoXML output;
            end
        end
      else
        begin
          /* send back error message if Form Method is not defined in the work flow */
          select @vErrorXML = '<Errors><Messages>' + dbo.fn_AMF_GetMessageXML('Method Name undefined in Work Flow details!!!') + '</Messages></Errors>';
        end

      /* Clean up RFFormAction from Data XML as it need not be sent to caller.
         It is only needed for the current context of execution */
      if (charindex('RFFormAction', @vDataXML) > 0)
        select @vDataXML = dbo.fn_XMLDeleteNode (@vDataXML, 'RFFormAction');
    end
  else
    begin
      select @vErrorXML = '<Errors><Messages>' + dbo.fn_AMF_GetMessageXML('Work Flow Processing Undefined!!!') + '</Messages></Errors>';
    end

  /* If there is no error in processing, save the DataXML for reused on further exceptions
     If there is error, then send the previous DataXML itself */
  if (@vErrorXML is null)
    update Devices
    set DataXML = @vDataXML
    where (DeviceId = @vDeviceName);
  else
  if (@vFormSequence <> 0)
    select @vDataXML = DataXML
    from Devices
    where (DeviceId = @vDeviceName);

  /* Build Result with Info, Warnings and Errors */
  exec pr_AMF_BuildMessagesXML @vInfoXML, @vWarningsXML, @vErrorXML, @vMessagesXML output;

    /* Build the output xml */
  select @OutputXML = dbo.fn_XMLNode('Result', coalesce(@vUIInfoXML,   '') +
                                               coalesce(@vDataXML,     '') +
                                               coalesce(@vMessagesXML, '') +
                                               coalesce(@vLogInfoXML,  ''));

  exec pr_RFLog_End @OutputXML, @@ProcId, @Value1 = @vFormMethod, @ActivityLogId = @vActivityLogId;

end try
begin catch
  /* Capture Exception details and send in AMF Format */
  select @vErrorMessage = ERROR_MESSAGE();
  select @vErrorMessage =  replace(replace(replace(@vErrorMessage, '<', ''), '>', ''), '$', '');
  select @vErrorXML =  '<Errors><Messages>' +
                          dbo.fn_XMLNode('Message', dbo.fn_XMLNode('DisplayText', @vErrorMessage)) +
                       '</Messages></Errors>';

  /* In case of exception, resend the same DataXML as before when form sequence is not 0 */
  if (@vFormSequence <> 0)
    select @vDataXML = DataXML
    from Devices
    where (DeviceId = @vDeviceName);

   select @OutputXML = dbo.fn_XMLNode('Result', coalesce(@vUIInfoXML, '') +
                                                coalesce(@vDataXML,   '') +
                                                coalesce(@vErrorXML,  '') +
                                                coalesce(@vLogInfoXML,''));

   exec pr_RFLog_End @OutputXML, @@ProcId, @Value1 = @vFormMethod, @ActivityLogId = @vActivityLogId;

end catch
end /* pr_AMF_ExecuteAction */

Go

