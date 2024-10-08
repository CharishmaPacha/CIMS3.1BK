/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/06  TK      pr_Allocation_AllocateWave: Create pick tasks based upon Pick Method
                      pr_Allocation_GenerateAPITransaction: Initial Revision (CID-1489)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_GenerateAPITransaction') is not null
  drop Procedure pr_Allocation_GenerateAPITransaction;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_GenerateAPITransaction generates API outbound transaction for Wave Entity
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_GenerateAPITransaction
  (@WaveId             TRecordId,
   @Operation          TOperation = null,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @Debug              TFlags = null)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,
          @vOperation              TOperation,

          @vWaveId                 TRecordId,
          @vWaveNo                 TWaveNo,
          @vWavePickMethod         TPickMethod;
begin /* pr_Allocation_GenerateAPITransaction */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Get Wave Info */
  select @vWaveId         = RecordId,
         @vWaveNo         = BatchNo,
         @vWavePickMethod = PickMethod
  from Waves
  where (RecordId = @WaveId);

  /* If Pick Method is 'CIMSRF' then not need to insert into APIOutboundTransactions  */
  if (@vWavePickMethod = 'CIMSRF') return;

  /* Generate outbound pickWave tansaction */
  insert into APIOutboundTransactions (IntegrationName, MessageType, EntityType, EntityId, EntityKey, BusinessUnit, CreatedBy)
    select 'CIMS' + @vWavePickMethod, 'PickWave', 'Wave', @vWaveId, @vWaveNo, @BusinessUnit, @UserId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_GenerateAPITransaction */

Go
