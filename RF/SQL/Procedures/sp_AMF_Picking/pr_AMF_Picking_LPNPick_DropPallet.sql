/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/08  PK      pr_AMF_Picking_LPNPick_DropPallet: Passing TaskId to drop pallet (HA-1175).
  pr_AMF_Picking_LPNPick_DropPallet, pr_AMF_Picking_LPNPick_PausePick,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Picking_LPNPick_DropPallet') is not null
  drop Procedure pr_AMF_Picking_LPNPick_DropPallet;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Picking_LPNPick_DropPallet:

  Processes the requests for pr_AMF_Picking_LPNPick_DropPallet
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Picking_LPNPick_DropPallet
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
          @vPalletToDrop             TPallet,
          @vDropLocation             TLocation;
          /* Functional variables */
  declare @vDataXML                  TXML,
          @vOutstandingPicksXML      TXML,
          @vxmlData                  xml,
          @vErrorMessage             TMessage,
          @vErrorNumber              TMessage,
          @vLPNId                    TRecordId,
          @vLPN                      TLPN,
          @vRFFormAction             TMessageName,
          @vTaskId                   TRecordId,
          @vActivityLogId            TRecordId;
begin /* pr_AMF_Picking_LPNPick_DropPallet */

  select @vxmlInput = convert(xml, @InputXML); /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  select @vDeviceId     = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ),
         @vUserId       = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
         @vBusinessUnit = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'),
         @vPalletToDrop = Record.Col.value('(Data/Pallet)[1]',                     'TPallet'      ),
         @vDropLocation = Record.Col.value('(Data/DroppedLocation)[1]',            'TLocation'    ),
         @vTaskId       = Record.Col.value('(Data/m_TaskInfo_TaskId)[1]',          'TRecordId'    )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  exec pr_RFC_Picking_DropPickedPallet @vDeviceId, @vUserId, @vBusinessUnit, @vPalletToDrop, @vDropLocation, @vTaskId,
                                       @vxmlRFCProcOutput output;

  exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output,
                                 @ErrorXML output, @DataXML output;

  if (@vTransactionFailed > 0) return;

  /* read the success message */
  select @vSuccessMessage = Record.Col.value('(ErrorMessage)[1]',   'TMessage')
  from @vxmlRFCProcOutput.nodes('/DROPPEDPALLETDETAILS/DROPPEDPALLETINFO') as Record(Col);

  select @InfoXML = dbo.fn_AMF_BuildSuccessXML(@vSuccessMessage);

  /* Build the data xml */
  select @DataXML = (select 'Done' Resolution
                     for Xml Raw(''), elements, Root('Data'));
end /* pr_AMF_Picking_LPNPick_DropPallet */

Go

