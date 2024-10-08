/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/05  RIA     pr_AMF_Picking_LPNPick_PausePick: Changes to go back to first screen when Pallet is Empty (HA-649)
  pr_AMF_Picking_LPNPick_DropPallet, pr_AMF_Picking_LPNPick_PausePick,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Picking_LPNPick_PausePick') is not null
  drop Procedure pr_AMF_Picking_LPNPick_PausePick;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Picking_LPNPick_PausePick:

  Processes the requests for Pause pick LPN
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Picking_LPNPick_PausePick
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
          /* Standard variables */
  declare @vReturnCode               TInteger,
          @vMessage                  TMessage,
          @vMessageName              TMessageName,
          @vSuccessMessage           TMessage,
          @vxmlInput                 xml,
          @vxmlOutput                xml,
          @vxmlRFCProcInput          xml,
          @vxmlRFCProcOutput         xml,
          @vrfcProcInputxml          TXML,
          @vrfcProcOutputxml         TXML,
          @vTransactionFailed        TBoolean,
          /* Input variables */
          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId,
          @vDeviceId                 TDeviceId;
          /* Functional variables */
  declare @vErrorMessage             TMessage,
          @vErrorNumber              TMessage,
          @vPalletToDrop             TPallet,
          @vPalletStatus             TStatus,
          @vPalletUnitsPicked        TInteger,
          @vActivityLogId            TRecordId;
begin /* pr_AMF_Picking_LPNPick_PausePick */

  select @vxmlInput = convert(xml, @InputXML); /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /* Users can attempt to pause or stop picking from sub menu in the UI. Verify if such an action was performed and process */
  select @vxmlRFCProcInput = (select Record.Col.value('(SessionInfo/DeviceId)[1]',              'TDeviceId'    ) as DeviceId,
                                     Record.Col.value('(SessionInfo/UserName)[1]',              'TUserId'      ) as UserId,
                                     Record.Col.value('(SessionInfo/BusinessUnit)[1]',          'TBusinessUnit') as BusinessUnit,
                                     Record.Col.value('(Data/m_LPNPickInfo_BatchNo)[1]',        'TPickBatchNo' ) as PickBatchNo,
                                     Record.Col.value('(Data/m_LPNPickInfo_PickToPallet)[1]',   'TPallet'      ) as Pallet,
                                     Record.Col.value('(Data/m_LPNPickInfo_TaskId)[1]',         'TRecordId'    ) as TaskId,
                                     Record.Col.value('(Data/m_LPNPickInfo_TaskDetailId)[1]',   'TRecordId'    ) as TaskDetailId
                              from @vxmlInput.nodes('/Root') as Record(Col)
                              for xml raw('ConfirmBatchPause'), elements);

  exec pr_RFC_Picking_PauseBatch @vxmlRFCProcInput, @vxmlRFCProcOutput output;

  exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output,
                                 @ErrorXML output, @DataXML output;

  /* If there is error raised simply return */
  if (@vTransactionFailed > 0) return;

  select @vPalletUnitsPicked    = Record.Col.value('UnitsPicked[1]',  'TInteger'),
         @vPalletStatus         = Record.Col.value('PalletStatus[1]', 'TStatus'),
         @vErrorNumber          = Record.Col.value('ErrorNumber[1]',  'TMessage'),
         @vSuccessMessage       = Record.Col.value('ErrorMessage[1]', 'TMessage')
  from @vxmlRFCProcOutput.nodes('/BATCHPAUSEDETAILS/BATCHPAUSEINFO')  as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlRFCProcOutput = null));

  select @InfoXML = dbo.fn_AMF_BuildSuccessXML(@vSuccessMessage);

  /* If nothing was picked yet, then return to menu */
  /* We are getting UnitsPicked value from TaskDetails/vwOrderDetails, So considering PalletStatus as well */
  if ((@vPalletUnitsPicked = 0) or (@vPalletStatus = 'E' /* Empty */))
    begin
      /* Build the data xml */
      select @DataXML = (select 'Pause' Resolution
                         for Xml Raw(''), elements, Root('Data'));
    end
  else
    exec pr_Picking_LPNPick_SuggestNextPickOrDrop @vxmlInput, @vxmlRFCProcOutput, 'PAUSEPICKING', @DataXML output,
                                                  @UIInfoXML output, @InfoXML output, @ErrorXML output;

end /* pr_AMF_Picking_LPNPick_PausePick */

Go

