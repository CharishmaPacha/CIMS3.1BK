/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/15  TK      pr_RFC_CC_StartDirectedLocCC: Corrected permission name (HA-GoLive)
  2017/01/18  OK      pr_RFC_CC_StartDirectedLocCC: Restricted to allow Supervisor Count tasks if user doesn't have permissions (GNC-1408)
  2016/08/18  SV      pr_RFC_CC_StartDirectedLocCC, pr_RFC_CC_StartLocationCC: Changes to show the actual error message which occured in internal procedure call
                      pr_RFC_CC_ValidateEntity: Added validation when entering the SKU instead of Location (HPI-453)
  2012/07/24  PK      pr_RFC_CC_StartDirectedLocCC: Added a validation for not allowing other Warehouse
                       CC Batches other than user logged in WH.
  2012/07/16  AY      pr_RFC_CC_StartDirectedLocCC: Find Locations within User logged in WH.
  2012/01/09  YA      Added 'pr_RFC_CC_StartDirectedLocCC' for Directed CycleCount.
                        Modified 'pr_RFC_CC_CompleteLocationCC' to create Task and TaskDetails for Non-DirectedCC.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_CC_StartDirectedLocCC') is not null
  drop Procedure pr_RFC_CC_StartDirectedLocCC;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_CC_StartDirectedLocCC:

  This procedure is used to initiate Directed Cycle Counting. The user would give
  the Batch, PickZone or Location Type and it would fetch the first location to
  be cycle counted within the given criteria.

  TODO: Add Location Type as well in RF - options Picklanes, Reserve. We need
        to add Warehouse (user choice at time of signin) into the input XML as well.

     Xml structure which is returned from procedure to RF:
    * Reserve Locations *                                   * Picklane Locations *
  <CYCLECOUNTDETAILS>                                      <CYCLECOUNTDETAILS>
    <LOCATIONINFO>                                          <LOCATIONINFO>
      <LocationId></LocationId>                               <LocationId></LocationId>
      <Location></Location>                                   <Location></Location>
      <LocationType></LocationType>                           <LocationType></LocationType>
      <LocationStorageType></LocationStorageType>             <LocationStorageType></LocationStorageType>
      <LocationStatus></LocationStatus>                       <LocationStatus></LocationStatus>
      <NumPallets></NumPallets>                               <NumPallets></NumPallets>
      <NumLPNs></NumLPNs>                                     <NumLPNs></NumLPNs>
      <NumSKUs></NumSKUs>                                     <NumSKUs></NumSKUs>
      <NumUnits></NumUnits>                                   <NumUnits></NumUnits>
    </LOCATIONINFO>                                          </LOCATIONINFO>
    <LOCATIONDETAILS>                                        <LOCATIONDETAILS>
      <RESERVE>                                                <PICKLANE>
        <LPNId></LPNId>                                          <SKUId></SKUId>
        <LPN></LPN>                                              <SKU></SKU>
        <SKUId></SKUId>                                          <UOM></UOM>
        <SKU></SKU>                                              <Quantity></Quantity>
        <UOM></UOM>                                            </PICKLANE>
        <Quantity></Quantity>                                  <PICKLANE>
      </RESERVE>                                                  <SKUId></SKUId>
      <RESERVE>                                                   <SKU></SKU>
        <LPNId></LPNId>                                           <UOM></UOM>
        <LPN></LPN>                                               <Quantity></Quantity>
        <SKUId></SKUId>                                        </PICKLANE>
        <SKU></SKU>
        <UOM></UOM>
        <Quantity></Quantity>
      </RESERVE>
    </LOCATIONDETAILS>                                     </LOCATIONDETAILS>
    <OPTIONS>                                              <OPTIONS>
      <RESERVE>                                              <PICKLANE>
        <DefaultQuantity></DefaultQuantity>                    <DefaultQuantity></DefaultQuantity>
        <QuantityEnabled></QuantityEnabled>                    <QuantityEnabled></QuantityEnabled>
        <ScanSKU></ScanSKU>                                    <SKUPrompt></SKUPrompt>
      </RESERVE>                                             </PICKLANE>
    </OPTIONS>                                             </OPTIONS>
</CYCLECOUNTDETAILS>                                    </CYCLECOUNTDETAILS>

------------------------------------------------------------------------------*/
Create Procedure pr_RFC_CC_StartDirectedLocCC
  (@xmlDirectedLocCCInfo xml, -- Currently consists of BatchNo, PickZone
   @BusinessUnit         TBusinessUnit,
   @UserId               TUserId,
   @DeviceId             TDeviceId,
   @xmlResult            xml output)
as
  declare @ReturnCode        TInteger,
          @MessageName       TMessageName,
          @ConfirmMessage    TMessageName,

          @vBatchNo          TTaskBatchNo,
          @vPickZone         TZoneId,
          @vBatchPickZone    TZoneId,
          @vValidBatchNo     TTaskBatchNo,
          @vValidPickZone    TZoneId,
          @vTaskId           TRecordId,
          @vTaskSubType      TTypeCode,
          @vTaskDetailId     TRecordId,
          @vStatus           TStatus,
          @vLocation         TLocation,
          @vUserWarehouse    TWarehouse,
          @vBatchWarehouse   TWarehouse,
          @xmlResultvar      varchar(max);
begin
begin try
  begin transaction;
  SET NOCOUNT ON;

  /* Initialize local variables and retreive BatchNo and Pickzone from i/p xml */
  select @vBatchNo  = Record.Col.value('BatchNo[1]' , 'TTaskBatchNo'),
         @vPickZone = Record.Col.value('PickZone[1]', 'TZoneId')
  from @xmlDirectedLocCCInfo.nodes('DIRECTEDLOCCC') as Record(Col)

  /* Clear Empty Strings */
  select @vBatchNo       = nullif(@vBatchNo,  ''),
         @vPickzone      = nullif(@vPickzone, ''),
         @vUserWarehouse = dbo.fn_Users_LoggedInWarehouse(@DeviceId, @UserId, @BusinessUnit);

  /* Validate Batch No */
  if (@vBatchNo is not null)
    begin
      select @vValidBatchNo   = BatchNo,
             @vBatchPickZone  = PickZone,
             @vStatus         = Status,
             @vTaskSubType    = TaskSubType,
             @vBatchWarehouse = Warehouse
      from Tasks
      where (BatchNo      = @vBatchNo) and
            (BusinessUnit = @BusinessUnit);

      if (@vValidBatchNo is null)
        set @MessageName = 'CC_InvalidBatch';
      else
      if (@vBatchWarehouse is not null) and (@vBatchWarehouse <> @vUserWarehouse)
        set @MessageName = 'SelectedBatchFromWrongWarehouse';
      else
      if (dbo.fn_Permissions_IsAllowed(@UserId, 'CycleCount.Pri.AllowCycleCount_L2') <> '1') and (@vTaskSubType = 'L2')
        set @MessageName = 'CC_UserDoNotHavePermissions_L2CC';
      else
      if (@vStatus = 'C' /* Completed */)
        set @MessageName = 'CC_BatchCompleted';
      else
      if (@vStatus not in ('N'/* Ready to Start */,'I'/* InProgress */))
        set @MessageName = 'CC_InvalidBatchStatus';

      if (@MessageName is not null)
        goto ErrorHandler;
    end

  /* Validate Pick Zone */
  if (@vPickZone is not null)
    begin
      select @vValidPickZone = LookUpCode
      from LookUps
      where LookUpCode = @vPickZone;

      if (@vValidPickZone is null)
        begin
          set @MessageName = 'InvalidPickZone'
          goto ErrorHandler;
        end
    end

  /* If both Batch No and PickZone are given, ensure they match */
  if (@vBatchPickZone is not null) and
     (@vValidPickZone is not null) and
     (@vValidPickZone <> @vBatchPickZone)
    begin
      set @MessageName = 'PickingZoneMismatch';
      goto ErrorHandler;
    end

  /* Call the subprocedure(pr_CC_FindNextLocationFromBatch) to find the next location
     on that particular batch
  select @vValidBatchNo  = coalesce(@vValidBatchNo,  @vBatchNo),
         @vValidPickZone = coalesce(@vValidPickZone, @vBatchPickZone, @vPickZone);

   I do not understand the purpose of the above and hence commented it. Some comments
   should have been written to help others understand this logic. AY
  */

  /* If user has not requested a specific batch, then find the next CycleCount
     batch to be issued */
  if (@vValidBatchNo is null)
    exec pr_CycleCount_GetNextBatch @vValidBatchNo output,
                                    @vTaskId, @vUserWarehouse, null, @UserId;

  if (@vValidBatchNo is null)
    begin
      set @MessageName = 'NoBatchesToCycleCount';
      goto ErrorHandler;
    end

  /* Get the next location from the selected Batch */
  exec pr_CycleCount_GetNextLocFromBatch @vValidBatchNo,
                                         @UserId,
                                         @vLocation     output,
                                         @vTaskDetailId output;

  /* Will return a confirmation message incase no Locations found on that particular batch to be cyclecounted */
  if (@vLocation is null)
    begin
      set @MessageName = 'NoLocationsToCycleCount';
      goto ErrorHandler;
    end

  /* Call pr_RFC_CC_StartLocationCC with returned Location
   - which Returns all the details of the Location fetched as @xmlResult  o/p
   - return xml */
  exec @ReturnCode = pr_RFC_CC_StartLocationCC @vLocation,
                                               @vTaskDetailId,
                                               @BusinessUnit,
                                               @UserId,
                                               @DeviceId,
                                               @xmlResult  output;

  if (@ReturnCode > 0)
    goto ErrorHandler;

  set @xmlResultvar = convert(varchar(max), @xmlResult)
  exec pr_Device_Update @DeviceId, @UserId, 'StartDirectedLocCC', @xmlResultvar, @@ProcId;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  /* We need to display the error message which internally occured first.
     This condition will not override the actual message occured during the internal call of other procedure */
  if (@xmlResult is null)
    exec @ReturnCode = pr_BuildRFErrorXML @xmlResult output;
end catch;

  return(coalesce(@ReturnCode, 0));
end /* pr_RFC_CC_StartDirectedLocCC */

Go
