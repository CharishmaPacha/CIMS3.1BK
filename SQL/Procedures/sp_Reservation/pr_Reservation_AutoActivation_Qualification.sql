/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/12/05  SK      pr_Reservation_AutoActivation_Qualification: Additional qualification (FBV3-593)
                      pr_Reservation_AutoActivation & pr_Reservation_AutoActivation_Qualification:
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Reservation_AutoActivation_Qualification') is not null
  drop Procedure pr_Reservation_AutoActivation_Qualification;
Go
/*------------------------------------------------------------------------------
  Proc pr_Reservation_AutoActivation_Qualification:

  The caller of this procedure has populated a list of waves for auto activation
  This procedure will determine if the wave could be processed further. There are
  two criteria
  a. ByWave: Wave is eligible when the From and To Details match for the entire wave.
             If not, the wave is not considered for activation.
  b. ByWaveSKU: If there are some SKUs on the Wave for which the From and To details
                match, then we qualify those SKUs

  #Waves (TWaveInfo)            - stores all wave & wave details
  #ToLPNDetails (TLPNDetails)   - All To LPNs related to the wave sent in
  #FromLPNDetails (TLPNDetails) - All FromLPNs related to the wave sent in
------------------------------------------------------------------------------*/
Create Procedure pr_Reservation_AutoActivation_Qualification
  (@WaveId           TRecordId  = null,
   @Warehouse        TWarehouse = null,
   @RulesXML         TXML       = null,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @Qualified        TFlag output)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,

          @vWaveType          TTypeCode,
          @vQualifyCriteria   TString;
begin /* pr_Reservation_AutoActivation_Qualification */
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vRecordId    = 0,
         @vMessageName = null,
         @Qualified    = 'Y' /* Default - Yes */;

  /* If either of them does not exist then disqualify and return */
  if not exists (select * from #FromLPNDetails) or
     not exists (select * from #ToLPNDetails)
    begin
      select @Qualified  = 'N' /* No */;

      goto ExitHandler;
    end

  /* Fetch wave info */
  select @vWaveType        = WaveType,
         @vQualifyCriteria = UDF1
  from #Waves
  where (WaveId = @WaveId);

  /* Sum by KeyValue quantity for To and From LPNs */
  select KeyValue, sum(Quantity) as Quantity
  into #ToLPNDetailsSummary
  from #ToLPNDetails
  group by KeyValue;

  select KeyValue, sum(Quantity) as Quantity
  into #FromLPNDetailsSummary
  from #FromLPNDetails
  group by KeyValue;

  /* The entire wave's sku list should have quantity reserved and ship cartons generated */
  if (@vQualifyCriteria = 'ByWave')
    begin
      /* Update output param as N to exclude this wave from processing if there is any mismatch */
      select @Qualified = 'N' /* No */
      from #ToLPNDetailsSummary TLD
        full outer join #FromLPNDetailsSummary FLD on (TLD.KeyValue = FLD.KeyValue) and (TLD.Quantity = FLD.Quantity)
      where (TLD.KeyValue is null or FLD.KeyValue is null);
    end
  else
  if (@vQualifyCriteria = 'ByWaveSKU')
    begin
      ---Make a SKU exception list and delete those SKUs from #FromLPNdetails & #ToLPNDetails
      print 'TODO';
    end

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Reservation_AutoActivation_Qualification */

Go
