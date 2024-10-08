/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/08/03  MS      pr_Prod_MainProcess, pr_Prod_ProcessATRecord,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Prod_MainProcess') is not null
  drop Procedure pr_Prod_MainProcess;
Go
/*------------------------------------------------------------------------------
  Proc pr_Prod_MainProcess: This is the top most level procedure in the process of
    compiling the productivity information i.e processing the Audit Trial and
    building the Productivity and ProductivityDetail records.
------------------------------------------------------------------------------*/
Create Procedure pr_Prod_MainProcess
  (@Date           TDate   = null,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId = 'cimsadmin',
   @Debug          TFlags  = '') -- Use MLD to capture, log and display marker info
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vMessage           TMessage,
          @vRecordId          TRecordId,
          @vDebug             TFlags,

          @vATUserId          TUserId,
          @vATDate            TDate,
          @vCurrentDate       TDate;

  declare @ttMarkers          TMarkers;
  declare @ttUsers table (RecordId      TRecordId identity(1,1),
                          UserId        TUserId,
                          ActivityDate  TDate);
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0,
         @vCurrentDate = coalesce(@Date, cast(getdate() as Date));

  /* Create required hash tables if they do not exist */
  if (object_id('tempdb..#Markers') is null) select * into #Markers from @ttMarkers;

  /* Check if in debug mode */
  exec pr_Debug_GetOptions @@ProcId, null /* @Operation */, @BusinessUnit, @vDebug output;
  select @vDebug = coalesce(nullif(@Debug, ''), @vDebug);

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'MainProcess_Start', @@ProcId;

  /* Ignore productivity if UserId like CIMS */
  update AuditTrail
  set ProductivityFlag = 'I' /* Ignore */
  where (ProductivityFlag = 'N' /* Not Processed */) and
        (BusinessUnit = @BusinessUnit) and
        (UserId like 'cims%');

  /* Ignore AT if there are any transactions not worth evaluating */
  update AT
  set AT.ProductivityFlag = 'I' /* Ignore */
  from AuditTrail AT
    join ProdOperations PO on AT.ActivityType = PO.ActivityType
  where (AT.ProductivityFlag = 'N' /* Not Processed */) and
        (AT.BusinessUnit = @BusinessUnit) and
        (PO.Status <> 'A') /* Active */;

  /* Fetch Users list for the given date */
  insert into @ttUsers (UserId, ActivityDate)
    select distinct UserId, ActivityDate
    from AuditTrail
    where (ProductivityFlag = 'N' /* Not Processed */) and
          (ActivityDate = @vCurrentDate) and
          (coalesce(UserId, '') <> '') and
          (BusinessUnit = @BusinessUnit);

  /* Exit if there are no records to process */
  if (not exists (select * from @ttUsers))
    goto ExitHandler;

  /* Loop through each distinct UserId, ActivityDate */
  while (exists(select * from @ttUsers where RecordId > @vRecordId))
    begin
      select top 1 @vRecordId = RecordId,
                   @vATUserId = UserId,
                   @vATDate   = ActivityDate
      from @ttUsers
      where (RecordId > @vRecordId);

      select @vMessage = concat_ws('; ', 'User: ', @vATUserId, 'Date:', @vATDate);
      if (charindex('M', @vDebug) > 0) exec pr_Markers_Save @vMessage, @@ProcId;

      /* Process user productivity */
      exec pr_Prod_ProcessUserActivity @vATUserId, @vATDate, @BusinessUnit, @UserId, @Debug;

    end /* end loop */

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'MainProcess_End', @@ProcId;
  if (charindex('L', @vDebug) > 0) exec pr_Markers_Log default, 'ProductivityProcess', null, null, null, @@ProcId, null, @UserId, @BusinessUnit;
  if (charindex('D', @vDebug) > 0)
    select object_name(M1.ProcId), datediff(ms, M2.LogTime, M1.LogTime) Duration, M1.Marker, M1.LogTime, M1.RecordId
    from #Markers M1 left outer join #Markers M2 on M2.RecordId = M1.RecordId -1

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Prod_MainProcess */

Go
