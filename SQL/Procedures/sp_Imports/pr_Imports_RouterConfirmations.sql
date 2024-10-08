/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/19  MS      pr_Imports_RouterConfirmations: Modified UDF names (JL-314)
  2018/04/24  RV      pr_Imports_RouterConfirmations, pr_Imports_ValidateRouterConfirmation: Initial version
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_RouterConfirmations') is not null
  drop Procedure pr_Imports_RouterConfirmations;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_RouterConfirmations:
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_RouterConfirmations
  (@xmlData              Xml             = null,
   @documentHandle       TInteger        = null,
   @InterfaceLogId       TRecordId       = null,
   @Action               TFlag           = null,
   @LPN                  TLPN            = null,
   @ActualWeight         TInteger        = null,
   @Destination          TLocation       = null,
   @DivertDate           TDate           = null,
   @DivertTime           TTime           = null,
   @UDF1                 TUDF            = null,
   @UDF2                 TUDF            = null,
   @UDF3                 TUDF            = null,
   @UDF4                 TUDF            = null,
   @UDF5                 TUDF            = null,
   @BusinessUnit         TBusinessUnit   = null,
   @UserId               TUserId         = null)
as
  declare @vReturnCode                    TInteger,

          @ttRouterConfirmationValidation TImportValidationType,
          @ttRouterConfirmation           TRouterConfirmationImportType;
begin
  SET NOCOUNT ON;

  if (@xmldata is not null) and (@InterfaceLogId is null)
    begin
      select @InterfaceLogId = Record.Col.value('ParentLogId[1]',  'TRecordId')
      from @xmlData.nodes('//msg/msgHeader') as Record(Col);
    end

  /* Populate the temp table */
  if (@documentHandle is not null)
    begin
      insert into @ttRouterConfirmation (
        InputXML,
        RecordType,
        RecordAction,
        LPN,
        ActualWeight,
        Destination,
        DivertDate,
        DivertTime,
        DivertDateTime,
        UDF1,
        UDF2,
        UDF3,
        UDF4,
        UDF5,
        BusinessUnit)
      select
        *
      from OPENXML(@documentHandle, '//msg/msgBody/Record', 2)
      with (InputXML              nvarchar(max)  '@mp:xmltext', -- Directive to return the xmltext of the record node
            RecordType        TRecordType,
            Action            TFlag      'Action',
            LPN               TLPN,
            ActualWeight      TInteger,
            Destination       TLocation,
            DivertDate        TDate,
            DivertTime        TTime,
            DivertDateTime    TXML,
            UDF1              TUDF,
            UDF2              TUDF,
            UDF3              TUDF,
            UDF4              TUDF,
            UDF5              TUDF,
            BusinessUnit      TBusinessUnit);
    end
  else
    begin
      insert into @ttRouterConfirmation (
        RecordAction, LPN, ActualWeight, Destination, DivertDate, DivertTime,
        UDF1, UDF2, UDF3, UDF4, UDF5, BusinessUnit)
      select
        @Action, @LPN, @ActualWeight, @Destination, @DivertDate, @DivertTime,
        @UDF1, @UDF2, @UDF3, @UDF4, @UDF5, @BusinessUnit;
    end

  if (exists (select * from @ttRouterConfirmation))
    update ttRC
    set LPNId        = L.LPNId,
        LPNStatus    = L.Status
    from @ttRouterConfirmation ttRC
      join LPNs L on (L.TrackingNo = ttRC.LPN);

  /* pr_Imports_ValidateRouterConfirmation procedure  will return the result set of validation,
     captured in RoutingConfirmation Table */
  insert @ttRouterConfirmationValidation
    exec pr_Imports_ValidateRouterConfirmation @ttRouterConfirmation

  /* Set Record Action for Routing Confirmations after validation */
  update @ttRouterConfirmation
  set RecordAction = RCV.RecordAction
  from @ttRouterConfirmation RC
    join @ttRouterConfirmationValidation RCV on (RCV.RecordId = RC.RecordId);

  /* Insert update or Delete based on Action */
  if (exists(select * from @ttRouterConfirmation where (coalesce(RecordAction, 'I') = 'I' /* Insert */)))
    insert into RouterConfirmation (
      LPNId,
      LPN,
      ActualWeight,
      Destination,
      DivertDate,
      DivertTime,
      RC_UDF1,
      RC_UDF2,
      RC_UDF3,
      RC_UDF4,
      RC_UDF5,
      BusinessUnit,
      CreatedDate,
      CreatedBy)
    select
      LPNId,
      LPN,
      ActualWeight/100, /* send weight with multiples of hundred, So we have divided by 100 */
      Destination,
      convert(DATE, stuff(stuff(stuff(DivertDateTime,13,0,':'),11,0,':'),9,0,' ')), /* Get the date from DiverDateTime: DDMMYYhhmmss */
      convert(TIME, stuff(stuff(stuff(DivertDateTime,13,0,':'),11,0,':'),9,0,' ')), /* Get the time from DiverDateTime: DDMMYYhhmmss */
      UDF1,
      UDF2,
      UDF3,
      UDF4,
      UDF5,
      BusinessUnit,
      current_timestamp,
      coalesce(@UserId, System_User)
    from @ttRouterConfirmation
    where ( RecordAction = 'I' /* Insert */);

  /* Update Interface Log with the inserted/Updated/deleted details */
  exec pr_InterfaceLog_AddDetails @InterfaceLogId, 'Import', null, @ttRouterConfirmationValidation;

end /* pr_Imports_RouterConfirmations */

Go
