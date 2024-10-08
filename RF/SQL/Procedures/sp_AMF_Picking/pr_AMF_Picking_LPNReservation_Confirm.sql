/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/08/06  RIA     pr_AMF_Picking_LPNReservation_Confirm, pr_AMF_Picking_LPNReservation_GetAvailableLPNs,
  2020/06/25  RIA     pr_AMF_Picking_LPNReservation_Confirm, pr_AMF_Picking_LPNReservation_GetAvailableLPNs,
  pr_AMF_Picking_LPNReservation_Confirm: Code Revamp (HA-820)
  2020/06/15  RIA     pr_AMF_Picking_LPNReservation_Confirm: Changes to return pallet
  2020/05/27  RIA     Changes to pr_AMF_Picking_LPNReservation_Confirm, pr_AMF_Picking_LPNReservation_ValidateLPN (HA-521)
  2020/05/23  SK      pr_AMF_Picking_LPNReservation_Validate, pr_AMF_Picking_LPNReservation_Confirm:
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Picking_LPNReservation_Confirm') is not null
  drop Procedure pr_AMF_Picking_LPNReservation_Confirm;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Picking_LPNReservation_Confirm: Validates & Reserves the LPN scanned
    for PickTicket or Wave scanned returns the details that needs to be picked and available inventory
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Picking_LPNReservation_Confirm
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
          /* Standard variables */
  declare @vReturnCode               TInteger,
          @vMessageName              TMessageName,
          @vxmlInput                 xml,
          @vxmlRFCProcInput          xml,
          @vxmlRFCProcOutput         xml,
          @vrfcProcInputxml          TXML,
          @vrfcProcOutputxml         TXML,
          @vTransactionFailed        TBoolean,
          /* Input variables */
          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId,
          @vDeviceId                 TDeviceId,
          @vEntityToReserve          TEntity,
          @vWaveId                   TRecordId,
          @vWaveNo                   TWaveNo,
          @vOrderId                  TRecordId,
          @vPickTicket               TPickTicket,
          @vNewUnits                 TQuantity,
          @vNewUnits1                TQuantity,
          @vPallet                   TPallet,
          @vFilterValue              TEntity,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vxmlSKUDetails            xml,
          @vxmlInput1                xml,
          @vSKUInfoXML               TXML,
          @vSelectedQuantity         TQuantity;
begin /* pr_AMF_Picking_LPNReservation_Confirm */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /*  Read inputs from InputXML */
  select @vEntityToReserve = Record.Col.value('(Data/m_LPNReservationInfo_EntityToReserve)[1]', 'TEntity'  ),
         @vWaveId          = Record.Col.value('(Data/m_WaveInfo_WaveId)[1]',                    'TRecordId'),
         @vWaveNo          = nullif(Record.Col.value('(Data/m_WaveInfo_WaveNo)[1]',             'TWaveNo'), ''),
         @vOrderId         = Record.Col.value('(Data/m_OrderInfo_OrderId)[1]',                  'TRecordId'),
         @vPickTicket      = nullif(Record.Col.value('(Data/m_OrderInfo_PickTicket)[1]',        'TPickTicket'), ''),
         @vNewUnits        = nullif(Record.Col.value('(Data/NewUnits)[1]',                      'TQuantity'), ''),
         @vNewUnits1       = nullif(Record.Col.value('(Data/NewUnits1)[1]',                     'TQuantity'), ''),
         @vFilterValue     = Record.Col.value('(Data/FilterValue)[1]',                          'TEntity'  ),
         @vPallet          = Record.Col.value('(Data/m_LPNReservationInfo_Pallet)[1]',          'TPallet'  )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Set the qty */
  select @vSelectedQuantity = coalesce(@vNewUnits, @vNewUnits1);

  /* Build V2 Input Xml */
  select @vxmlRFCProcInput = (select Record.Col.value('(SessionInfo/BusinessUnit)[1]',   'TBusinessUnit') as BusinessUnit,
                                     Record.Col.value('(SessionInfo/UserName)[1]',       'TUserId'      ) as UserId,
                                     Record.Col.value('(SessionInfo/DeviceId)[1]',       'TDeviceId'    ) as DeviceId,
                                     Record.Col.value('(Data/m_WaveInfo_WaveId)[1]',     'TRecordId'    ) as WaveId,
                                     Record.Col.value('(Data/WaveNo)[1]',                'TWaveNo'      ) as PickBatchNo,
                                     Record.Col.value('(Data/m_OrderInfo_OrderId)[1]',   'TRecordId'    ) as OrderId,
                                     Record.Col.value('(Data/PickTicket)[1]',            'TPickTicket'  ) as PickTicket,
                                     Record.Col.value('(Data/Operation)[1]',             'TOperation'   ) as Operation,
                                     Record.Col.value('(Data/LPN)[1]',                   'TLPN'         ) as LPN,
                                     Record.Col.value('(Data/m_LPNReservationInfo_Pallet)[1]',
                                                                                         'TPallet'      ) as Pallet,
                                     Record.Col.value('(Data/m_LPNReservationInfo_EntityToReserve)[1]',
                                                                                         'TEntity'      ) as EntityToReserve,
                                     Record.Col.value('(Data/AllocateOption)[1]',        'TFlags'       ) as 'Option',
                                     @vSelectedQuantity as SelectedQuantity,
                                     Record.Col.value('(Data/Innerpacks)[1]',            'TInnerpacks'  ) as SelectedInnerPacks,
                                     Record.Col.value('(Data/UoM)[1]',                   'TUoM'         ) as SelectedUOM
                              from @vxmlInput.nodes('/Root') as Record(Col)
                              for xml raw('ConfirmLPNReservations'), elements);

  /* Confirm LPN Reservation for the Wave or PickTicket scanned */
  exec pr_Reservation_ConfirmFromLPN @vxmlRFCProcInput, @vxmlRFCProcOutput output;

  /* Evaluate XML Result */
  exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output,
                                 @ErrorXML output, @DataXML output, @InfoXML output;

  select @vxmlInput1 = (select @vEntityToReserve  as EntityToReserve,
                               @vWaveId           as WaveId,
                               @vWaveNo           as WaveNo,
                               @vOrderId          as OrderId,
                               @vPickTicket       as PickTicket
                        for XML RAW('LPNReservationInfo'), ELEMENTS);

  /* Build response in the required format to show in the screen */
  exec pr_AMF_Info_GetLPNReservationInfoXML @vxmlInput1, null /* SKUId */, @DataXML output;

  /* Send the Pallet back to screen that is already entered */
  select @DataXML = dbo.fn_XmlAddNode(@DataXML, 'Data', dbo.fn_XMLNode('LPNReservationInfo_Pallet', @vPallet) +
                                                        dbo.fn_XMLNode('LPNReservationInfo_FilterValue', @vFilterValue));

end /* pr_AMF_Picking_LPNReservation_Confirm */

Go

