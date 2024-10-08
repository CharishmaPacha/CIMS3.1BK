/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/04  RIA     pr_AMF_Inquiry_Pallet: Changes to build SKU information (OB2-1783)
  2020/11/04  MS      pr_AMF_Inquiry_LPN, pr_AMF_Inquiry_Pallet: Made changes to show values in UDF on RF Screen (JL-289)
  2020/05/14  AY      pr_AMF_Inquiry_Pallet: Added WH/Qty for Pallet Inquiry (HA-433)
  2020/02/20  RIA     pr_AMF_Inquiry_Pallet: Changes to get LPNsInTransit and LPNsReceived (JL-115)
  2019/07/10  RIA     pr_AMF_Inquiry_Pallet: Changes to show the required info (CID-GoLive)
  AY      pr_AMF_Inquiry_Pallet: Changes to show info more relevant to Picking carts
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Inquiry_Pallet') is not null
  drop Procedure pr_AMF_Inquiry_Pallet;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Inquiry_Pallet:@vPalletInfo

  Processes the requests for Pallet Inquiry for Pallet Inquiry work flow
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Inquiry_Pallet
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
          /* Standard variables */
  declare @vReturnCode               TInteger,
          @vMessageName              TMessageName,
          @vMessage                  TMessage,
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
          @vRFFormAction             TMessageName,
          @Pallet                    TPallet,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vRecordId                 TRecordId,
          @vPalletId                 TRecordId,
          @vPallet                   TPallet,
          @vPalletTaskId             TRecordId,
          @vPalletTaskCount          TCount,
          @vPalletTaskList           TVarchar,
          @vTaskAssignedTo           TUserId,
          @vTaskAssignedToName       TName,
          @vWaveNo                   TWaveNo,
          @vWaveType                 TDescription,
          @vTotalUnitsToPick         TCount,
          @vTotalUnitsPicked         TCount,
          @vNumCartonsOrTotes        TCount,
          @vNumPositions             TCount,
          @vLPNsInTransit            TCount,
          @vLPNsReceived             TCount,
          @vUnitsInTransit           TCount,
          @vUnitsReceived            TCount,
          @vReceiptId                TRecordId,
          @vReceiptTypeDesc          TDescription,
          @vxmlPalletDetails         xml,
          @vPalletInfoXML            TXML;
begin /* pr_AMF_Inquiry_Pallet */

  select @vxmlInput = convert(xml, @InputXML); /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /*  Read inputs from InputXML */
  select @vUserId       = Record.Col.value('(SessionInfo/UserName)[1]',     'TUserId'      ),
         @vBusinessUnit = Record.Col.value('(SessionInfo/BusinessUnit)[1]', 'TBusinessUnit'),
         @Pallet        = Record.Col.value('(Data/Pallet)[1]',              'TPallet'      )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Insert exec fails when the Pallet is invalid for pallet Inquiry
     This is because of the rollback statement which gets executed for invalid locations
     Therefore, validations for pallet from pallet inquiry procedure are performed here, to avoid db error and show proper error */
  select @vPalletId          = PalletId,
         @vPallet            = Pallet,
         @vPalletTaskId      = TaskId,
         @vWaveNo            = PickBatchNo,
         @vReceiptId         = ReceiptId
  from  vwPallets
  where (PalletId = dbo.fn_Pallets_GetPalletId (@Pallet, @vBusinessUnit));

  if (@vPalletId is null)
    set @vMessageName = 'PalletDoesNotExist';

  /* This will raise an exception, and the caller ExecuteAction procedure would
     capture and return error to UI */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* If Pallet does not have TaskId, then get it from Tasks */
  if (@vPalletTaskId is null)
    select @vPalletTaskId    = min(TaskId),
           @vPalletTaskCount = count(*)
    from Tasks
    where (PalletId = @vPalletId) and
          (Status not in ('C', 'X'));

  if (@vPalletTaskId is not null)
    select @vWaveNo           = WaveNo,
           @vWaveType         = WaveTypeDesc,
           @vTaskAssignedTo   = AssignedTo,
           @vTotalUnitsToPick = TotalUnitsRemaining,
           @vTotalUnitsPicked = TotalUnitsCompleted
    from vwTasks
    where (TaskId = @vPalletTaskId);

  select @vNumCartonsOrTotes = sum(case when LPNType <> 'A' then 1 else 0 end),
         @vNumPositions      = sum(case when LPNType =  'A' then 1 else 0 end),
         @vLPNsInTransit     = sum(case when Status  =  'T' then 1 else 0 end),
         @vLPNsReceived      = sum(case when Status <>  'T' then 1 else 0 end),
         @vUnitsInTransit    = sum(case when Status  =  'T' then Quantity else 0 end),
         @vUnitsReceived     = sum(case when Status <>  'T' then Quantity else 0 end)
  from LPNs
  where (PalletId = @vPalletId);

  /* Get Receipts Info */
  if (@vReceiptId is not null)
    select @vReceiptTypeDesc = ReceiptTypeDesc
    from vwReceiptHeaders
    where (ReceiptId = @vReceiptId);

  /* Get the Pallet/Cart LPNs, but don't need to show empty positions */
  select LPN, StatusDescription, replace(right(AlternateLPN, 3), '-', '') as Position,
         PickTicket, SKU, SKU1, SKU2, SKU3, SKU4, SKU5, SKUDescription, Quantity,
         (Quantity - ReservedQty) UnitsToPick, ReservedQty UnitsPicked, 0 PrintLabel, SKUId
  into #LPNDetails
  from vwLPNs
  where (PalletId = @vPalletId) and
        ((LPNType  <> 'A'     ) or (Quantity > 0));

  update LD
  set SKU            = coalesce(S.DisplaySKU, S.SKU),
      SKUDescription = coalesce(S.DisplaySKUDesc, S.Description)
  from #LPNDetails LD join SKUs S on LD.SKUId = S.SKUId;

  /* Process output into XML */
  select @vxmlPalletDetails = (select * from #LPNDetails
                               for Xml Raw('PalletDetail'), elements XSINIL, Root('PALLETDETAILS'));

  select @vPalletInfoXML = (select Pallet, PalletType, StatusDesc as Status, NumLPNs, Quantity, Location, @vPalletTaskId TaskId,
                                   @vWaveNo WaveNo, @vWaveType WaveType, @vTaskAssignedTo TaskAssignedTo,
                                   @vTaskAssignedToName TaskAssignedToName,
                                   P.SKU, SKUDescription, P.SKU1, P.SKU2, P.SKU3, P.SKU4,
                                   coalesce(S.DisplaySKU, P.SKU) DisplaySKU, coalesce(S.DisplaySKUDesc, P.SKUDescription) DisplaySKUDesc,
                                   @vNumCartonsOrTotes NumCartonsOrTotes, @vNumPositions Positions,
                                   @vTotalUnitsToPick TotalUnitsToPick, @vTotalUnitsPicked TotalUnitsPicked,
                                   @vLPNsInTransit LPNsInTransit, @vLPNsReceived LPNsReceived,
                                   @vUnitsInTransit UnitsInTransit, @vUnitsReceived UnitsReceived,
                                   ReceiptNumber, @vReceiptTypeDesc ReceiptType, ReceiverNumber, Warehouse, DestLocation,
                                   PAL_UDF1, PAL_UDF2, PAL_UDF3, PAL_UDF4, PAL_UDF5
                            from vwPallets P
                              left join SKUs S on P.SKUId = S.SKUId
                            where (PalletId = @vPalletId)
                            for Xml path(''));

  select @DataXml = dbo.fn_XmlNode('Data', @vPalletInfoXML +
                                           coalesce(convert(varchar(max), @vxmlPalletDetails), ''));

end /* pr_AMF_Inquiry_Pallet */

Go

