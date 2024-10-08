/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/03/13  RIA     pr_RFC_QC_ValidateLPN: Used control variable to consider LPN statuses for QC (HPI-2512)
  2019/01/08  RIA     pr_RFC_QC_ValidateLPN: Initial Revision (HPI-2282)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_QC_ValidateLPN') is not null
  drop Procedure pr_RFC_QC_ValidateLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_QC_ValidateLPN:

    @xmlInput XML Structure:
    <ValidateLPNQC>
      <LPN></LPN>
      <BusinessUnit></BusinessUnit>
      <UserId></UserId>
      <DeviceId></DeviceId>
    </ValidateLPNQC>

    @xmlResult XML Structure:
    <QCInfo>
      <LPNINFO>
        <LPNId></LPNId>
        <LPN></LPN>
        <OrderId></OrderId>
        <PickTicket></PickTicket>
        <SalesOrder></SalesOrder>
        <Quantity></Quantity>
        <InnerPacks></InnerPacks>
        <ReservedQuantity> </ReservedQuantity>
        <Location></Location>
        <PickedUser></PickedUser>
        <PackedUser></PackedUser>
      </LPNINFO>
      <LPNDetailInfo>
        <LPNDetailId></LPNDetailId>
        <SKUId></SKUId>
        <SKU></SKU>
        <SKUDescription></SKUDescription>
        <Quantity></Quantity>
        <InnerPacks></InnerPacks>
        <OnhandStatus></OnhandStatus>
      </LPNDetailInfo>
      <NonScannableItems>                        -- This node will have atleast one item for UnKnown items
        <LPNDetailId></LPNDetailId>
        <SKUId></SKUId>
        <SKU></SKU>
        <Quantity></Quantity>
        <InnerPacks></InnerPacks>
        <OnhandStatus></OnhandStatus>
      </NonScannableItems>
      <Options>
        <QCMode>SE/SQ</QCMode>                   -- SE - Scan Each, SQ - Scan Qty
      </Options>
      <AdditionalChecks>
        <ChecksRequired>VCS,VW,LBA</ChecksRequired> -- VCS - Validate Carton size, VW - Validate Weight, VPL - Validate Packing List, LBA - Label Attached properly?
      </AdditionalChecks>
      <QCDetails>                                -- We will get data in this node in responce from RF after QC performed
        <SKU></SKU>
        <Quantity></Quantity>
        <InnerPacks></InnerPacks>
      </QCDetails>
    <QCInfo>
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_QC_ValidateLPN
  (@xmlInput       xml,
   @xmlResult      xml   output)
as
  /* Declare local variables */
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vRecordId              TRecordId,

          @vLPNId                 TRecordId,
          @vLPN                   TLPN,
          @vOrderId               TRecordId,
          @vPickedByUser          TUserId,
          @vPackedByUser          TUserId,
          @vLPNStatus             TStatus,
          @vOnhandStatus          TStatus,
          @vValidQCLPNStatuses    TControlValue,
          @vArchived              TFlag,

          @xmlRulesData           TXML,
          @vxmlLPNsInfo           xml,
          @vxmlLPNDetailsInfo     xml,
          @vxmlNonScannabeItems   xml,
          @vxmlOptions            xml,
          @vxmlAdditionalChecks   xml,
          @vxmlQCDetails          xml,

          @vQCMode                TControlValue,
          @vAdditionalChecks      TControlValue,

          @vLPNQuantity           TQuantity,
          @vDeviceId              TDeviceId,
          @vUserId                TUserId,
          @vBusinessUnit          TBusinessUnit,
          @vActivityLogId         TRecordId;

begin
begin try
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Get the XML User inputs in to the local variables */
  select @vLPN          = Record.Col.value('LPN[1]'            , 'TLPN'),
         @vBusinessUnit = Record.Col.value('BusinessUnit[1]'   , 'TBusinessUnit'),
         @vUserId       = Record.Col.value('UserId[1]'         , 'TUserId'),
         @vDeviceId     = Record.Col.value('DeviceId[1]'       , 'TDeviceId')
  from @xmlInput.nodes('/ValidateLPNQC') as Record(Col);

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @vBusinessUnit, @vUserId, @vDeviceId,
                      null, @vLPN, 'LPN',
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Get the LPN Info */
  select @vLPNId          = LPNId,
         @vLPN            = LPN,
         @vOrderId        = OrderId,
         @vLPNStatus      = Status,
         @vOnhandStatus   = OnhandStatus,
         @vArchived       = Archived
  from vwLPNs
  where (LPNId = dbo.fn_LPNs_GetScannedLPN(@vLPN, @vBusinessUnit, default));

  /* Get LPN status for QC */
  select @vValidQCLPNStatuses  = dbo.fn_Controls_GetAsString('LPN_QC', 'ValidQCLPNStatuses', 'KD' /* Picked/Packed */,  @vBusinessUnit, @vUserId);

  /* Validations */
  if (@vLPNId is null)
    set @vMessageName = 'LPNDoesNotExist';
  else
  if (charindex(@vLPNStatus, @vValidQCLPNStatuses) = 0)
    set @vMessageName = 'InvalidLPNStatus';
  else
  if (@vArchived = 'Y')
    set @vMessageName = 'LPNIsArchived';

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    goto ErrorHandler;

  select top 1
         @vPickedByUser = PickedBy,
         @vPackedByUser = PackedBy
  from LPNDetails
  where (LPNId = @vLPNId);

  /* Build the xml for LPN Info */
  set @vxmlLPNsInfo = (select LPNId,
                              LPN,
                              OrderId,
                              PickTicket,
                              SalesOrder,
                              Quantity,
                              0 as ReservedQuantity,
                              Location,
                              @vPickedByUser as PickedUser,
                              @vPackedByUser as PackedUser
                       from vwLPNs
                       where (LPNId = @vLPNId)
                       for XML raw('LPNInfo'), elements);

  /* Build the xml for LPN Details info */
  set @vxmlLPNDetailsInfo = (select LPNDetailId,
                                    SKUId,
                                    SKU,
                                    SKUDescription,
                                    InnerPacks,
                                    Quantity,
                                    OnhandStatus
                             from vwLPNDetails
                             where (LPNId = @vLPNId)
                             for XML raw('LPNDetail'), type, elements xsinil, root('LPNDetailInfo'));

  /* Build the xml for Not Scannable Items info */
  set @vxmlNonScannabeItems = (select LD.LPNDetailId,
                                      OD.SKUId,
                                      S.SKU,
                                      LD.InnerPacks,
                                      LD.Quantity,
                                      LD.OnhandStatus
                               from OrderDetails OD
                                    join SKUs S on OD.SKUId = S.SKUId
                                    join LPNDetails LD on OD.OrderId       = LD.OrderId       and
                                                          OD.OrderDetailId = LD.OrderDetailId and
                                                          LD.LPNId         = @vLPNId
                               where (OD.OrderId = @vOrderId) and
                                     (S.IsScannable = 'N')
                               for XML raw('NonScannableItem'), type, elements xsinil, root('NonScannableItems'));

  exec pr_RuleSets_Evaluate 'QC_GetQCMode', @xmlRulesData, @vQCMode output;

  /* Build the xml for LPN Details info */
  set @vxmlOptions = (select @vQCMode as QCMode
                      for XML raw('Options'), elements);

  exec pr_RuleSets_Evaluate 'QC_AdditionalChecks', @xmlRulesData, @vAdditionalChecks output;

  /* Build the xml for LPN Details info */
  set @vxmlAdditionalChecks = (select @vAdditionalChecks as ChecksRequired
                      for XML raw('AdditionalChecks'), elements);

  /* Build XML, The return dataset is used for RF to show Pallet info, Pallet Details in seperate nodes */
  set @xmlResult = dbo.fn_XMLNode('QCInfo',
                                    coalesce(convert(varchar(max), @vxmlLPNsInfo), '') +           /* <LPNsInfo>             */
                                    coalesce(convert(varchar(max), @vxmlLPNDetailsInfo), '') +     /* <LPNDetailsInfo>       */
                                    coalesce(convert(varchar(max), @vxmlNonScannabeItems), '') +   /* <NotScannabeItemsInfo> */
                                    coalesce(convert(varchar(max), @vxmlOptions), '') +            /* <Options>              */
                                    coalesce(convert(varchar(max), @vxmlAdditionalChecks), '') +   /* <AdditionalChecks>     */
                                    coalesce(convert(varchar(max), @vxmlQCDetails), ''));          /* <QCDetails>            */

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Log the result */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vLPNId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vLPNId, @ActivityLogId = @vActivityLogId output;
end catch;
  return(coalesce(@vReturnCode, 0));
end /* pr_RFC_QC_ValidateLPN */

Go
