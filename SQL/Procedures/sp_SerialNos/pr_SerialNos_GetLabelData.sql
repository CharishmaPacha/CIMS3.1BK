/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/04/02  RV      pr_SerialNos_Capture: Initial Revision
                      pr_SerialNos_GetLabelData: Initial Revision (S2GCA-507)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_SerialNos_GetLabelData') is not null
  drop Procedure pr_SerialNos_GetLabelData;
Go
/*------------------------------------------------------------------------------
  Proc pr_SerialNos_GetLabelData: Returns the data set to be used to print serial numbers Label.
    SerialNosPerLabel parameter should sends from the label that the bartender can print per label
  This procedure is called from Bartender labels.
------------------------------------------------------------------------------*/
Create Procedure pr_SerialNos_GetLabelData
  (@LPN               TLPN          = null,
   @PrintBatch        TBatch        = null,
   @SerialNosPerLabel TCount        = 3,
   @BusinessUnit      TBusinessUnit = null,
   @UserId            TUserId       = null)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vUserId            TUserId,

          @vRecordId          TRecordId,
          @vLPNId             TRecordId,
          @vSerialNoCount     TCount,
          @vCurrentSerialNo   TSerialNo,
          @vCurrentLabelCount TCount;

  declare @ttSerialNumbers       TEntityKeysTable;
  declare @ttSerialNumbersToPrint table (RecordId  TRecordId identity(1, 1),
                                         SerialNo1 TSerialNo,
                                         SerialNo2 TSerialNo,
                                         SerialNo3 TSerialNo,
                                         SerialNo4 TSerialNo,
                                         UDF1      TUDF,
                                         UDF2      TUDF,
                                         UDF3      TUDF,
                                         UDF4      TUDF,
                                         UDF5      TUDF);
begin
  set NOCOUNT ON;
  select @vReturnCode        = 0,
         @vMessagename       = null,
         @vUserId            = System_User,
         @vRecordId          = 0,
         @vSerialNoCount     = 0,
         @vCurrentLabelCount = 1;

  /* Get the LPNId */
  select @vLPNId = LPNId
  from LPNs
  where (LPN = @LPN) and (BusinessUnit = @BusinessUnit);

  /* Get the all the serial numbers for that particular batch */
  insert into @ttSerialNumbers (EntityId, EntityKey)
    select RecordId, SerialNo
    from SerialNos
    where (LPNId = @vLPNId) and (PrintBatch = @PrintBatch);

  /* Return if there are no lablels to print */
  if (@@rowcount = 0)
    return;

  /* Loop through all the serial numbers and return data set based upon the number of serial numbers per label */
  while exists (select * from @ttSerialNumbers where RecordId > @vRecordId)
    begin
      select top 1 @vCurrentSerialNo = EntityKey,
                   @vRecordId        = RecordId,
                   @vSerialNoCount  += 1
      from @ttSerialNumbers
      where (RecordId > @vRecordId)
      order by RecordId;

    /* If it is first serial number then need to insert the serial number as first serial number */
    if (@vSerialNoCount = 1)
      insert into @ttSerialNumbersToPrint (SerialNo1)
        select @vCurrentSerialNo
    else
      /* From second to 3/4 serial numbers update on the CurrentLabel */
      update @ttSerialNumbersToPrint
      set SerialNo2 = case when (@vSerialNoCount = 2) then @vCurrentSerialNo else SerialNo2 end,
          SerialNo3 = case when (@vSerialNoCount = 3) then @vCurrentSerialNo else SerialNo3 end,
          SerialNo4 = case when (@vSerialNoCount = 4) then @vCurrentSerialNo else SerialNo4 end
      where (RecordId = @vCurrentLabelCount);

    /* Based upon the SerialNos per label reset the serail number count */
    if (@vSerialNoCount % @SerialNosPerLabel = 0)
      begin
        select @vCurrentLabelCount += 1,
               @vSerialNoCount      = 0;
      end
    end /* End of while */

  /* Return data set */
  select SerialNo1, SerialNo2, SerialNo3, SerialNo4
  from @ttSerialNumbersToPrint;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_SerialNos_GetLabelData */

Go
