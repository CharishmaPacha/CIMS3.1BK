/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Picking_LPNPick_GetPick') is not null
  drop Procedure pr_AMF_Picking_LPNPick_GetPick;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Picking_LPNPick_GetPick: Given the users criteria, determine
   the LPN Pick Task to execute and present the same to the user
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Picking_LPNPick_GetPick
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
          @vDeviceId                 TDeviceId,
          @vPalletId                 TRecordId,
          @vPallet                   TPallet,
          @vLocation                 TLocation;
          /* Functional variables */
  declare @vDataXML                  TXML,
          @vErrorMessage             TMessage,
          @vErrorNumber              TMessage,
          @vLPN                      TLPN,
          @vLPNId                    TRecordId,
          @vRFFormAction             TMessageName,
          @vTaskId                   TRecordId,
          @vActivityLogId            TRecordId;
begin /* pr_AMF_Picking_LPNPick_GetPick */

  select @vxmlInput = convert(xml, @InputXML); /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /* Build V2 Input Xml for GetBatchPick procedure */
  select @vxmlRFCProcInput = (select Record.Col.value('(SessionInfo/DeviceId)[1]',       'TDeviceId'    ) as DeviceId,
                                     Record.Col.value('(SessionInfo/UserName)[1]',       'TUserId'      ) as UserId,
                                     Record.Col.value('(SessionInfo/BusinessUnit)[1]',   'TBusinessUnit') as BusinessUnit,
                                     Record.Col.value('(Data/WaveNo)[1]',                'TPickBatchNo' ) as PickBatchNo,
                                     Record.Col.value('(Data/TaskId)[1]',                'TRecordId'    ) as TaskId,
                                     Record.Col.value('(Data/PickZone)[1]',              'TZoneId'      ) as PickZone,
                                     Record.Col.value('(Data/DestZone)[1]',              'TZoneId'      ) as DestZone,
                                     Record.Col.value('(Data/PickTicket)[1]',            'TPickTicket'  ) as PickTicket,
                                     Record.Col.value('(Data/PickingPallet)[1]',         'TPallet'      ) as Pallet,
                                     Record.Col.value('(Data/PickGroup)[1]',             'TPickGroup'   ) as PickGroup,
                                     Record.Col.value('(Data/Operation)[1]',             'TDescription' ) as Operation
                              from @vxmlInput.nodes('/Root') as Record(Col)
                              for xml raw('GetBatchPick'), elements);

  exec pr_RFC_Picking_GetBatchPick @vxmlRFCProcInput, @vxmlRFCProcOutput output;

  /* If there is nothing to pick, an error woud have been raisee, if we are here, then it is succesful */
  exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output,
                                 @ErrorXML output, @DataXML output;

  /* Convert V2 Response of next Pick to AMF Format */
  exec pr_Picking_LPNPick_BuildNextPickResponse @vxmlRFCProcOutput, @DataXML output;

end /* pr_AMF_Picking_LPNPick_GetPick */

Go

