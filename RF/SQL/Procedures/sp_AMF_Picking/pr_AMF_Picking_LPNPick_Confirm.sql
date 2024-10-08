/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/11/15  RIA     Added : pr_AMF_Picking_LPNPick_BuildResponse, pr_AMF_Picking_LPNPick_Confirm,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Picking_LPNPick_Confirm') is not null
  drop Procedure pr_AMF_Picking_LPNPick_Confirm;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Picking_LPNPick_Confirm:

  Processes the requests for Confirm LPN pick
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Picking_LPNPick_Confirm
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
  declare @vLPNId                    TRecordId,
          @vLPN                      TLPN,
          @vLPNPicked                TLPN,
          @vActivityLogId            TRecordId;
begin /* pr_AMF_Picking_LPNPick_Confirm */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /* Build V2 Procedure input */
  select @vxmlRFCProcInput = (select Record.Col.value('(SessionInfo/DeviceId)[1]',                 'TDeviceId'    ) as DeviceId,
                                     Record.Col.value('(SessionInfo/UserName)[1]',                 'TUserId'      ) as UserId,
                                     Record.Col.value('(SessionInfo/BusinessUnit)[1]',             'TBusinessUnit') as BusinessUnit,
                                     Record.Col.value('(Data/m_LPNPickInfo_BatchNo)[1]',           'TPickBatchNo' ) as PickBatchNo,
                                     Record.Col.value('(Data/m_LPNPickInfo_PickZone)[1]',          'TZoneId'      ) as PickZone,
                                     Record.Col.value('(Data/m_LPNPickInfo_PickTicket)[1]',        'TPickTicket'  ) as PickTicket,
                                     Record.Col.value('(Data/m_LPNPickInfo_PickToPallet)[1]',      'TPallet'      ) as PickingPallet,
                                     Record.Col.value('(Data/m_LPNPickInfo_OrderDetailId)[1]',     'TRecordId'    ) as OrderDetailId,
                                     Record.Col.value('(Data/m_LPNPickInfo_SKU)[1]',               'TSKU'         ) as FromSKU,
                                     Record.Col.value('(Data/m_LPNPickInfo_LPN)[1]',               'TLPN'         ) as FromLPN,
                                     Record.Col.value('(Data/m_LPNPickInfo_LPNId)[1]',             'TRecordId'    ) as FromLPNId,
                                     Record.Col.value('(Data/m_LPNPickInfo_LPNDetailId)[1]',       'TRecordId'    ) as FromLPNDetailId,
                                     Record.Col.value('(Data/m_LPNPickInfo_PickType)[1]',          'TTypeCode'    ) as PickType,
                                     Record.Col.value('(Data/m_LPNPickInfo_TaskId)[1]',            'TRecordId'    ) as TaskId,
                                     Record.Col.value('(Data/m_LPNPickInfo_TaskDetailId)[1]',      'TRecordId'    ) as TaskDetailId,
                                     Record.Col.value('(Data/m_LPNPickInfo_ConfirmScanOption)[1]', 'TControlValue') as ConfirmScanOption,
                                     Record.Col.value('(Data/PickedEntity)[1]',                    'TEntityKey'   ) as ScannedEntity,
                                     Record.Col.value('(Data/SKUPicked)[1]',                       'TLPN'         ) as SKUPicked,
                                     Record.Col.value('(Data/LPNPicked)[1]',                       'TLPN'         ) as LPNPicked,
                                     Record.Col.value('(Data/PickedUnits)[1]',                     'TInteger'     ) as UnitsPicked,
                                     Record.Col.value('(Data/PickedFromLocation)[1]',              'TLocation'    ) as PickedFromLocation,
                                     Record.Col.value('(Data/PickUoM)[1]',                         'TUoM'         ) as PickUoM,
                                     Record.Col.value('(Data/ShortPick)[1]',                       'TFlag'        ) as ShortPick,
                                     Record.Col.value('(Data/LocationEmpty)[1]',                   'TFlags'       ) as LocationEmpty,
                                     Record.Col.value('(Data/ConfirmLocationEmpty)[1]',            'TFlags'       ) as ConfirmLocationEmpty,
                                     Record.Col.value('(Data/DestZone)[1]',                        'TLookUpCode'  ) as DestZone,
                                     Record.Col.value('(Data/Operation)[1]',                       'TDescription' ) as Operation,
                                     Record.Col.value('(Data/m_Options_PickingMode)[1]',           'TDescription' ) as PickingType,
                                     Record.Col.value('(Data/m_LPNPickInfo_PickGroup)[1]',         'TPickGroup'   ) as PickGroup
                              from @vxmlInput.nodes('/Root') as Record(Col)
                              for xml raw('ConfirmBatchPick'), elements);

  exec pr_RFC_Picking_ConfirmBatchPick @vxmlRFCProcInput, @vxmlRFCProcOutput output;

  exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output,
                                 @ErrorXML output, @DataXML output;

  /* If there is error raised simply return */
  if (@vTransactionFailed > 0) return;

  /* Get the from Location and BusinessUnit */
  select @vBusinessUnit = Record.Col.value('(SessionInfo/BusinessUnit)[1]',  'TBusinessUnit'),
         @vLPNPicked    = Record.Col.value('(Data/PickedEntity)[1]',         'TEntityKey'   )
  from @vxmlInput.nodes('/Root')  as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Get the LPNId to use it for fetching success message */
  select @vLPNId = dbo.fn_LPNs_GetScannedLPN (@vLPNPicked, @vBusinessUnit, default);

  /* build confirmation message indicating the completion of pick */
  select top 1 @vSuccessMessage =  Comment
  from vwATEntity
  where (EntityId = @vLPNId) and
        (ActivityType in ('LPNPick'))
  order by AuditId desc;

  select @InfoXML = dbo.fn_AMF_BuildSuccessXML(@vSuccessMessage);

  /* Get the next pick if any or suggest a drop location if everything is picked */
  exec pr_Picking_LPNPick_SuggestNextPickOrDrop @vxmlInput, @vxmlRFCProcOutput, null, @DataXML output,
                                                @UIInfoXML output, @InfoXML output, @ErrorXML output;

end /* pr_AMF_Picking_LPNPick_Confirm */

Go

