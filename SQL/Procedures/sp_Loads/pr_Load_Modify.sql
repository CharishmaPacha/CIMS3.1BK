/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/21  SK/AY   pr_Load_Modify, pr_Load_GenerateBoLs: Option for user to choose group by for the report (HA-2676)
  2021/02/04  RT      pr_Load_GenerateBoLs and pr_Load_Modify: Changes to use BoLLPNs to compute the BoLOrderDEtails and BoLCarrierDetails (FB-2225)
  2018/05/22  PK      pr_Load_MarkAsShipped, pr_Load_Modify: Migrated the changes from HPI production to S2G (S2G-878)
  2016/06/17  PSK     pr_Load_Modify: Changes to show error message on GenerateBols Action(CIMS-976).
              AY      pr_Load_Modify: Bug fixes and changes to handle error messages
  2014/03/03  NY      pr_Load_Update, pr_Load_Modify: Changed fn_Messages_Build to use fn_Messages_BuildActionResponse to display messages.
  2012/11/30  PKS     pr_Load_Modify: made this procedure as generic for all Load Modify operations.
  2012/11/29  PKS     Procedure pr_Load_markLoadsAsShipped was renamed to pr_Load_Modify and
  2012/11/19  PKS     Rename procedure pr_Load_Modify to pr_Load_Update (As well in revision history to avoid confusion).
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Load_Modify') is not null
  drop procedure pr_Load_Modify;
Go
/*------------------------------------------------------------------------------
   Proc pr_Load_Modify:
   LoadsXML XML structure

   <ModifyLoads>
     <LoadIds>
       <LoadId>123</LoadId>
       <LoadId>456</LoadId>
       <LoadId>789</LoadId>
     </LoadIds>
   </ModifyLoads>
------------------------------------------------------------------------------*/
Create Procedure pr_Load_Modify
  (@LoadContents XML,
   @BusinessUnit TBusinessUnit,
   @UserId       TUserId,
   @Message      TMessage output)
as
  declare @ReturnCode         TInteger,
          @MessageName        TMessageName,
          @vEntity            TEntity  = 'Load',
          /* Loads Related*/
          @vLoadId            TRecordId,
          @vLoadNumber        TLoadNumber,
          @vLoadsCount        TCount,
          @vLoadsModified     TCount,
          @vCount             TCount,
          @xmlData            xml,
          @vAction            TAction,
          @vRegenerate        TFlag,
          @vBOD_GroupCriteria TLookUpCode,
          @vRecordId          TRecordId,
          @vErrorMsg          TMessage,
          @ValidatedMessage   TXML;

  declare @ttLoadsToModify TEntityKeysTable;
  declare @ttActualErrorMessages table
          (MessageName TMessage);
  declare @ttConsolidatedErrorMessages table
          (ErrorMessage TMessage);
begin /* pr_Load_Modify */
begin try
  begin transaction
  SET NOCOUNT ON;

  select @vCount         = 0,
         @vLoadsCount    = 0,
         @vLoadsModified = 0,
         @ReturnCode     = 0,
         @MessageName    = null,
         @vRecordId      = 0;

  /* Validate Business Unit */
  select @MessageName = dbo.fn_IsValidBusinessUnit(@BusinessUnit, @UserId);

  set @xmlData = convert(xml, @LoadContents);

  /* Return if there is no xmlData sent */
  if (@xmlData is null)
    begin
      set @MessageName = 'InvalidData';
      goto ErrorHandler;
    end

  select @vAction = Record.Col.value('Action[1]','TAction')
  from @xmlData.nodes('/ModifyLoads') as Record(Col);

  /* Get the all loads from the xml */
  insert into @ttLoadsToModify (EntityId)
    select Record.Col.value('.', 'TRecordId') LoadId
    from @xmlData.nodes('/ModifyLoads/LoadIds/LoadId') as Record(Col);

  select @vLoadsCount = @@rowcount,
         @vCount      = @@rowcount;

  if (@vAction = 'MarkAsShipped')
    begin
      /* Iterating to mark all loads as shipped */
      while exists(select * from @ttLoadsToModify where RecordId > @vRecordId)
        begin
          select Top 1 @vLoadId     = LTM.EntityId,
                       @vRecordId   = LTM.RecordId,
                       @vLoadNumber = L.LoadNumber
          from @ttLoadsToModify LTM left outer join Loads L on LTM.EntityId = L.LoadId
          where (RecordId > @vRecordId)
          order by RecordId;

          begin try
            exec @ReturnCode = pr_Load_MarkAsShipped @vLoadId, @BusinessUnit, @UserId, @ValidatedMessage output;

            if (@ValidatedMessage is not null)
              begin
                select @vErrorMsg = dbo.fn_AppendCSV(@vErrorMsg, null, @vLoadNumber + ': ' + @ValidatedMessage)
                select @ValidatedMessage = null;
              end
            else
              select @vLoadsModified = @vLoadsModified + 1;

          end try
          begin catch
            select @vErrorMsg = dbo.fn_AppendCSV(@vErrorMsg, null, @vLoadNumber + ': ' + ERROR_MESSAGE());

            insert into @ttActualErrorMessages
              select ERROR_MESSAGE()
          end catch;
        end;

        insert into @ttConsolidatedErrorMessages
          select convert(varchar(10),count(MessageName))+' of '+convert(varchar(10),@vCount)+' '+replace(replace(MessageName,'<$',''),'$>','') as ErrMessages from @ttActualErrorMessages group by MessageName

        select @vErrorMsg = coalesce(@vErrorMsg + ', <br/>', '') + ErrorMessage from @ttConsolidatedErrorMessages
    end;
  else
  if (@vAction = 'GenerateBoLs')
    begin
      select @vRegenerate        = Record.Col.value('Regenerate[1]',         'TFlag'),
             @vBOD_GroupCriteria = Record.Col.value('BOD_GroupCriteria[1]',  'TLookUpCode')
      from @xmlData.nodes('/ModifyLoads/Data') as Record(Col);

      /* Iterating to mark all loads to generate BoL Info  */
      while exists(select * from @ttLoadsToModify where RecordId > @vRecordId)
        begin
          select Top 1 @vLoadId   = EntityId,
                       @vRecordId = RecordId
          from @ttLoadsToModify
          where (RecordId > @vRecordId)
          order by RecordId;

          begin try
            exec @ReturnCode = pr_Load_GenerateBoLs @vLoadId, @vRegenerate, @UserId, @vBOD_GroupCriteria;
            select @vLoadsModified = @vLoadsModified + 1;
          end try
          begin catch
            /* Append new error to the message if it is not already in the message */
            if ((@vErrorMsg is null) or (charindex (ERROR_MESSAGE(), @vErrorMsg) = 0))
              select @vErrorMsg = dbo.fn_AppendCSV(@vErrorMsg, null, ERROR_MESSAGE());
          end catch;
        end;
    end;

  /* Framing result message. Skip the success message if no Loads were modified. */
  if (coalesce(@Message, '') = '') and (@vLoadsModified > 0)
    exec @Message = dbo.fn_Messages_BuildActionResponse @vEntity, @vAction, @vLoadsModified, @vLoadsCount;

  select @Message = dbo.fn_AppendCSV(@Message, null, @vErrorMsg);

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  commit transaction;
end try
begin catch
  /* Handling transactions in case it is rolled back from sub procedures */
  if (@@trancount > 0) rollback transaction;

  exec @ReturnCode = pr_ReRaiseError;
end catch
  return(coalesce(@ReturnCode, 0));
end /* pr_Load_Modify */

Go
