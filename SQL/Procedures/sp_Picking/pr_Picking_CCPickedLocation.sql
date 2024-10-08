/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2014/07/24  TD      Added new procedured pr_Picking_CCPickedLocation.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Picking_CCPickedLocation') is not null
  drop Procedure pr_Picking_CCPickedLocation;
Go
/*------------------------------------------------------------------------------
  Proc pr_Picking_CCPickedLocation:
  <CONFIRMCYCLECOUNTDETAILS xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <Location></Location>
    <SubTaskType></SubTaskType>
    <BatchNo></BatchNo>
   <CCLOCDETAILS>
      <LOCATIONCONTENTS>
        <Pallet></Pallet>
        <LPN></LPN>
        <SKU></SKU>
        <NumLPNs></NumLPNs>
        <Quantity></Quantity>
      </LOCATIONCONTENTS>
   </CCLOCDETAILS>
  </CONFIRMCYCLECOUNTDETAILS>

  This procedure will mark the location as cycle counted or will create a
    task for this based on the operation.

------------------------------------------------------------------------------*/
Create Procedure pr_Picking_CCPickedLocation
  (@LocationId       TRecordId,
   @Operation        TDescription,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @DeviceId         TDeviceId)
as
  declare @vReturnCode          TInteger,
          @vLocation            TLocation,
          @CCMessage            TMessageName,
          @vSubTaskType         TTypeCode,
          @vBatchNo             TPickBatchNo,
          @vCCDetails           xml,
          @vxmlLocationContents xml,
          @xmlResult            xml;

begin /* pr_Picking_CCPickedLocation */

  select @vLocation = Location
  from Locations
  where (LocationId = @LocationId);

  if (@Operation = 'ConfirmEmpty')
    begin
      select @vxmlLocationContents = (select 0    as Pallet,
                                             0    as LPN,
                                             0    as SKU,
                                             0    as NumLPNs,
                                             0    as Quantity
      FOR XML RAW('LOCATIONCONTENTS'), TYPE, ELEMENTS XSINIL, ROOT('CCLOCDETAILS'));

      select @vCCDetails = (select @vLocation as Location,
                                   'PE'       as SubTaskType, --Picking CC Task
                                   ''         as BatchNo,   +
                                   @vxmlLocationContents
                            FOR XML RAW('CONFIRMCYCLECOUNTDETAILS'), TYPE, ELEMENTS);

      exec pr_RFC_CC_CompleteLocationCC @vCCDetails, @BusinessUnit, @UserId,
                                        @DeviceId, @xmlResult output;
    end
  else
  if (@Operation = 'ConfirmNonEmpty')
    begin
      exec pr_Locations_CreateCycleCountTask @LocationId,
                                             'Auditing',
                                             @UserId,
                                             @BusinessUnit,
                                             @CCMessage output;
    end
end /* pr_Picking_CCPickedLocation */

Go
