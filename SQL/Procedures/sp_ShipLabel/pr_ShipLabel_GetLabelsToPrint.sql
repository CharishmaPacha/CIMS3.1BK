/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/14  VM      pr_ShipLabel_GetLabelsToPrintForEntity, pr_ShipLabel_GetLabelsToPrintProcess - renamed to obsolete (HA-2510)
  2019/05/02  YJ      pr_ShipLabel_GetLabelsToPrintProcess: Migrated from Prod (S2GCA-98)
  pr_ShipLabel_GetLabelsToPrintProcess:  changes to get pallet tag records for pallet and load.
  pr_ShipLabel_GetLabelsToPrintForEntity: changes when the Entity is Load and validated the input
  pr_ShipLabel_GetLabelFormat, pr_ShipLabel_GetLabelsToPrint,
  pr_ShipLabel_GetLabelsToPrintProcess: Changed CarrierInterface domain name (S2GCA-434)
  2018/09/14  RV      pr_ShipLabel_GetLabelsToPrint:
  pr_ShipLabel_GetLabelsToPrintProcess: Made changes to get the shipment type (S2GCA-249)
  2018/06/04  YJ      pr_ShipLabel_GetLabelsToPrintProcess: Changed Amazon SoldTo '165099': Migrated from staging (S2G-727)
  2018/06/01  RV      pr_ShipLabel_GetLabelsToPrintProcess: Made changes to print all the pallet ship labels against the PickTicket
  2018/05/10  RV      pr_ShipLabel_GetLabelFormat, pr_ShipLabel_GetLabelsToPrintProcess: Added Pallet Ship Label type to print
  2018/04/27  RV      pr_ShipLabel_GetLabelsToPrintProcess: Made changes to return ZPL to print from Shipping Docs page
  2018/04/26  RV      pr_ShipLabel_GetLabelsToPrintProcess: Made changes to print the pallet ship label (S2G-686)
  OK      pr_ShipLabel_GetLabelsToPrintForEntity: Enhanced to explod the LPNs/Pallets based on the Rules (S2G-706)
  2017/07/12  VM      pr_ShipLabel_GetLabelsToPrintProcess: Send order OrderCategory1 to process CreateShipment Rules (SRI-798)
  2017/04/10  TK      pr_ShipLabel_GetLabelsToPrintForEntity:
  2016/11/28  KN      pr_ShipLabel_GetLabelsToPrintProcess : Reverted unnecessary changes done for (HPI-740)
  2016/11/17  KN      pr_ShipLabel_GetLabelsToPrintProcess : Changed order of nodes for printing SL-1 , CL-2 (FB-810).
  2016/10/18  KN      pr_ShipLabel_GetLabelsToPrintProcess: Additionally passing Shipvia to evalutate rules (HPI-882)
  2016/09/22  KN      pr_ShipLabel_GetLabelsToPrintProcess : Added  condition to consider LPN also (HPI-740)
  2016/08/19  RV      pr_ShipLabel_GetLabelsToPrintForEntity: Made changes to calculate the weight (HPI-483)
  2016/08/11  RV      pr_ShipLabel_GetLabelsToPrintProcess: Made changes to handle the multi packages while printing
  pr_ShipLabel_GetLabelsToPrintForEntity: Do not prompt for weight if we have estimated weight
  2016/07/27  AY      pr_ShipLabel_GetLabelsToPrintForEntity: Corrections to earlier validations (NBD-474)
  2016/05/12  RV      pr_ShipLabel_GetLabelsToPrintForEntity: Don't allow to print the ship labels and update
  2016/05/05  AY      pr_ShipLabel_GetLabelsToPrintProcess: Print appropriate packing lists when user enters
  2016/05/04  TD      pr_ShipLabel_GetLabelsToPrintProcess:Changes to sendentikey value if the labeltype is
  2016/05/04  RV      pr_ShipLabel_GetLabelsToPrintProcess: Clean up the temp table to avoid the Unique violations (NBD-385)
  2016/05/03  RV      pr_ShipLabel_GetLabelsToPrintProcess: Label display format changed as LPN information is first (NBD-385)
  2016/03/16  DK      pr_ShipLabel_GetLabelsToPrintProcess: Enhanced to generate UCCBarcode (NBD-282).
  2016/03/08  TK      pr_ShipLabel_GetLabelFormat & pr_ShipLabel_GetLabelsToPrintProcess:
  pr_ShipLabel_GetLabelsToPrintProcess: Consider DocumentType & EntityType which will be helpful to evaluate rules
  2016/01/08  KN      pr_ShipLabel_GetLabelsToPrintProcess: Added condition for return label (FB-509)
  2015/12/05  RV      pr_ShipLabel_GetLabelsToPrintForEntity: Added procedure (NBD-53)
  2015/11/15  AY      pr_ShipLabel_GetLabelsToPrintProcess: Allow re-printing with UCCBarcode
  2015/10/16  AY      pr_ShipLabel_GetLabelsToPrintProcess: Show proper message with ShipVia Description (ACME-340)
  2015/09/14  AY      pr_ShipLabel_GetLabelsToPrintProcess: Enhancement to reprint labels or not.
  2015/09/06  AY      pr_ShipLabel_GetLabelsToPrintProcess: Consider SortOrder of BPL as default (CIMS-617)
  2015/04/02  RV      pr_ShipLabel_GetLabelsToPrintProcess,pr_ShipLabel_GetLabelsToPrint: Resquence LPNs for the order before print
  2015/02/04  PKS     pr_ShipLabel_GetLabelsToPrint: using of funciton fn_XMLNode is discarded because it does not support to build XML with mutiple nodes.
  pr_ShipLabel_GetLabelsToPrint, pr_ShipLabel_GetLabelsToPrintProcess :
  2012/11/28  AA      pr_ShipLabel_GetLabelsToPrintProcess: Added parameter LPN Status
  2012/11/10  AA      pr_ShipLabel_GetLabelsToPrintProcess: new procedure to return labels
  2012/08/30  AY/AA   pr_ShipLabel_GetLabelsToPrint: Introduced.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ShipLabel_GetLabelsToPrint') is not null
  drop Procedure pr_ShipLabel_GetLabelsToPrint;
Go
/*------------------------------------------------------------------------------
  Proc pr_ShipLabel_GetLabelsToPrint: Returns all the info associated with the
    label formats to be printed for an LPN.
------------------------------------------------------------------------------*/
Create Procedure pr_ShipLabel_GetLabelsToPrint
  (@LPN           TLPN      = null,
   @LPNId         TRecordId = null,
   @UserId        TUserId,
   @BusinessUnit  TBusinessUnit)
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,
          @vMessage             TDescription,

          @vLPNId               TRecordId,
          @vOrderId             TRecordId,
          @vOrderType           TTypeCode,
          @vOrderTypeDesc       TDescription,
          @vCarrier             TCarrier,
          @vCarrierInterface    TCarrierInterface,

          @xmlData              TXML,
          @vXMLData             XML,
          @Result               TResult,
          @vShiplabelFormat     TName;

begin /* pr_ShipLabel_GetLabelsToPrint */
  select @vReturnCode   = 0,
         @vMessagename  = null;

  /* If we do not have LPNId, fetch it */
  if (@LPNId is null)
    select @LPNId = LPNId
    from LPNs
    where (LPN = @LPN) and
          (BusinessUnit = @BusinessUnit);

  /* Get LPN Info */
  select @vLPNId   = LPNId,
         @vOrderId = OrderId
  from LPNs
  where (LPNId = @LPNId) and
        (BusinessUnit = @BusinessUnit);

  /* Get Order Info */
  select @vOrderType       = OrderType,
         @vOrderTypeDesc   = OrderTypeDescription,
         @vCarrier         = Carrier
  from vwOrderHeaders
  where (OrderId = @vOrderId);

  /* Validations */

  if (@vLPNId is null)
    set @vMessageName = 'LPNIsInvalid'
  else
  if (@vOrderId is null)
    set @vMessageName = 'ShipLabel_LPNNotOnAnyOrder'
  else
  if (@vOrderType in ('B', 'R' /* Bulk/Replenish */))
    set @vMessageName = 'ShipLabel_InvalidOrderType'

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Re order the Package Sequence Number */
  exec pr_LPNs_PackageNoResequence @vOrderId, @LPNId;

  /* Use rules to identify the Ship label format
     To do so - we need to generate an xml and call appropriate proc by passing xml */
  select @vXMLData = (select @vOrderId     as OrderId,
                             'SL'          as LabelType,
                             @vCarrier     as Carrier,
                             ''            as CarrierInterface,
                             @BusinessUnit as BusinessUnit
                      for XML raw('RootNode'), elements);

  select @xmlData = convert(varchar(Max), @vXMLData);

  /* Determine which integration we are going to use ie. Direct with UPS/FedEx or ADSI */
  exec pr_RuleSets_Evaluate 'CarrierInterface', @xmlData, @vCarrierInterface output;

  /* Stuff latest values of Carrier Interface */
  select @xmlData = dbo.fn_XMLStuffValue(@xmlData, 'CarrierInterface', @vCarrierInterface);

  /* Get the ship label */
  exec pr_RuleSets_Evaluate 'ShiplabelFormat', @xmlData, @vShipLabelFormat output;

  /* Uniqueness on the table is EntityType, LabelFormatName and BusinessUnit, so
     we need all these params to actually return the right data - AY */
  select RecordId,
         EntityType,
         LabelFormatName
         LabelFormatDesc,
         LabelFileName,
         PrintOptions,
         PrinterMake,
         Status,
         SortSeq,
         BusinessUnit,
         CreatedDate,
         ModifiedDate,
         CreatedBy,
         ModifiedBy
  from LabelFormats
  where (EntityType      = 'Ship') and
        (LabelFormatName = @vShipLabelFormat) and
        (BusinessUnit    = @BusinessUnit);

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName, @vOrderTypeDesc;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_ShipLabel_GetLabelsToPrint */

Go
