/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/10  MS      pr_Shipping_GetPackingListData_New, pr_Shipping_PLGetShipLabelsXML: Changes to generate labels based on EntityType (S2GCA-1178)
  2018/05/01  RV/RT   pr_Shipping_GetPackingListData: Refactor the code to get the ship label xml and comments xml by
                        adding procedures pr_Shipping_PLGetCommentsXML and pr_Shipping_PLGetShipLabelsXML (HPI-1498)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_PLGetShipLabelsXML') is not null
  drop Procedure pr_Shipping_PLGetShipLabelsXML;
Go
/*------------------------------------------------------------------------------
  pr_Shipping_PLGetShipLabelsXML:

  Returns ship label and return ship label XMLs as an output with respect to the OrderId and LPN
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_PLGetShipLabelsXML
  (@OrderId            TRecordId,
   @LPN                TLPN,
   @BusinessUnit       TBusinessUnit,
   @ShipLabelXML       TXML output,
   @ReturnShipLabelXML TXML output)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,
          @vMessage                 TDescription,

          @vReturnLabelRequired     TControlValue;
begin
  SET NOCOUNT ON;

  select @vReturnLabelRequired = dbo.fn_Controls_GetAsString('ShipLabels', 'IsReturnLabelRequired', 'N' /* No */, @BusinessUnit, 'CIMSAgent');

  /* Explicitly mentioned the columns of ShipLabels in below queries because ZPL has some special characters and
      we are unable handle while converting to xml */

 if (coalesce (@LPN, '') <> '')
    begin
      /* Include ship label type of 'S' */
      set @ShipLabelxml = (select RecordId, EntityType, EntityKey, LabelType, TrackingNo, Label, ShipVia,
                                  case /* Check whether the Ship Label is already generated or not */
                                    when ((Label is null and ZPLLabel is null) or (coalesce(TrackingNo, '') = ''))
                                      then 'N' /* No */
                                      else 'Y' /* Yes */
                                   end as IsShipLabelGenerated,
                                   Status, BusinessUnit, CreatedDate, ModifiedDate, CreatedBy, ModifiedBy, Notifications
                           from ShipLabels
                           where EntityKey = @LPN and LabelType = 'S' /* Label */ and Status = 'A' and BusinessUnit = @BusinessUnit
                           for xml raw('SHIPLABEL'), elements, binary base64)

      /* Include ship label type of 'RL' */
      set @ReturnShipLabelxml = (select RecordId, EntityType, EntityKey, LabelType, TrackingNo, Label, ShipVia,
                                        case /* Check whether the Ship Label is already generated or not */
                                          when ((Label is null and ZPLLabel is null) or (coalesce(TrackingNo, '') = ''))
                                            then 'N' /* No */
                                            else 'Y' /* Yes */
                                        end as IsShipLabelGenerated,
                                        Status, BusinessUnit, CreatedDate, ModifiedDate, CreatedBy, ModifiedBy, Notifications
                                 from ShipLabels
                                 where EntityKey = @LPN and LabelType = 'RL' /* Return label */ and Status = 'A' and BusinessUnit = @BusinessUnit
                                 for xml raw('ReturnSHIPLABEL'), elements, binary base64)
    end
  else
  if (coalesce (@OrderId, 0) <> 0)
    begin
      /* Include ship label type of 'S' */
      set @ShipLabelxml = (select top 1 RecordId, EntityType, EntityKey, LabelType, TrackingNo, Label, ShipVia,
                                        case /* Check whether the Ship Label is already generated or not */
                                          when ((Label is null and ZPLLabel is null) or (coalesce(TrackingNo, '') = ''))
                                            then 'N' /* No */
                                            else 'Y' /* Yes */
                                        end as IsShipLabelGenerated,
                                        Status, BusinessUnit, CreatedDate, ModifiedDate, CreatedBy, ModifiedBy, Notifications
                           from ShipLabels
                           where OrderId = @OrderId and LabelType = 'S' /* Label */ and Status = 'A'
                           for xml raw('SHIPLABEL'), elements, binary base64)

      /* Include ship label type of 'RL' */
      set @ReturnShipLabelxml = (select top 1 RecordId, EntityType, EntityKey, LabelType, TrackingNo, Label, ShipVia,
                                              case /* Check whether the return label is already generated or not */
                                                when (((Label is null and ZPLLabel is null) or (coalesce(TrackingNo, '') = '')) and @vReturnLabelRequired = 'Y' /* Yes */)
                                                  then 'N' /* No */
                                                  else 'Y' /* Yes */
                                              end as IsReturnLabelGenerated,
                                              Status, BusinessUnit, CreatedDate, ModifiedDate, CreatedBy, ModifiedBy, Notifications
                                 from ShipLabels
                                 where OrderId = @OrderId and LabelType = 'RL' /* Return label */ and Status = 'A'
                                 for xml raw('ReturnSHIPLABEL'), elements, binary base64)
    end

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  return(coalesce(@vReturnCode, 0));
end /* pr_Shipping_PLGetShipLabelsXML */

Go
