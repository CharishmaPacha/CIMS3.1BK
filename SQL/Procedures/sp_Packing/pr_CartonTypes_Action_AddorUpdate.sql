/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/08  RBV     Added pr_CartonTypes_Action_AddorUpdate (HA-1110)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_CartonTypes_Action_AddorUpdate') is not null
  drop Procedure pr_CartonTypes_Action_AddorUpdate;
Go
/*------------------------------------------------------------------------------
  Proc pr_CartonTypes_Action_AddorUpdate: This procedure is used for
                               1)Create new cartonType
                               2)update details on the existing cartonType
------------------------------------------------------------------------------*/
Create Procedure pr_CartonTypes_Action_AddorUpdate
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML           = null output)
as
  /* Declare local variables */
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vMessage                    TDescription,
          @vRecordId                   TRecordId,
          /* Audit & Response */
          @vRecordsUpdated             TCount,
          @vTotalRecords               TCount,
          /* Input variables */
          @vEntity                     TEntity,
          @vAction                     TAction,
          @vCartonType                 TCartonType,
          @vDescription                TDescription,
          @vEmptyWeight                TWeight,
          @vInnerLength                TLength,
          @vInnerWidth                 TLength,
          @vInnerHeight                TLength,
          @vOuterLength                TLength,
          @vOuterWidth                 TLength,
          @vOuterHeight                TLength,
          @vAvailableSpace             TInteger,
          @vMaxWeight                  TInteger,
          @vMaxUnits                   TInteger,
          @vStatus                     TStatus,
          @vSortSeq                    TSortSeq,
          /* Other variables */
          @vExistingCartonType         TCartonType;

begin /* pr_CartonTypes_AddorUpdate */
  SET NOCOUNT ON;

  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vRecordId      = 0,
         @vTotalRecords  = count(*) from #ttSelectedEntities;

  /* Extracting data elements from XML */
  select @vEntity               = Record.Col.value('Entity[1]',                      'TEntity'),
         @vAction               = Record.Col.value('Action[1]',                      'TAction'),
         @vRecordId             = Record.Col.value('(SelectedRecords/RecordDetails/EntityId) [1]',
                                                                                     'TRecordId'),
         @vCartonType           = Record.Col.value('(Data/CartonType)[1]',           'TCartonType'),
         @vDescription          = Record.Col.value('(Data/Description)[1]',          'TDescription'),
         @vEmptyWeight          = Record.Col.value('(Data/EmptyWeight)[1]',          'TWeight'),

         @vInnerLength          = Record.Col.value('(Data/InnerLength)[1]',          'TLength'),
         @vInnerWidth           = Record.Col.value('(Data/InnerWidth)[1]',           'TLength'),
         @vInnerHeight          = Record.Col.value('(Data/InnerHeight)[1]',          'TLength'),

         @vOuterLength          = Record.Col.value('(Data/OuterLength)[1]',          'TLength'),
         @vOuterWidth           = Record.Col.value('(Data/OuterWidth)[1]',           'TLength'),
         @vOuterHeight          = Record.Col.value('(Data/OuterHeight)[1]',          'TLength'),

         @vAvailableSpace       = Record.Col.value('(Data/AvailableSpace)[1]',       'TInteger'),
         @vMaxWeight            = Record.Col.value('(Data/MaxWeight)[1]',            'TInteger'),
         @vMaxUnits             = Record.Col.value('(Data/MaxUnits)[1]',             'TInteger'),

         @vStatus               = Record.Col.value('(Data/Status)[1]',               'TStatus'),
         @vSortSeq              = Record.Col.value('(Data/SortSeq)[1]',              'TSortSeq')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  select @vExistingCartonType = CartonType
  from CartonTypes
  where (CartonType = @vCartonType) and (BusinessUnit = @BusinessUnit);

  if (@vAction = 'CartonTypes_Add') and (coalesce(@vCartonType, '') = '')
    set @vMessageName = 'CartonTypeIsRequired';
  else
  if (@vAction = 'CartonTypes_Add') and (@vExistingCartonType is not null)
    set @vMessageName = 'CartonTypeAlreadyExists'
  else
  if (rtrim(coalesce(@vDescription, '')) = '')
    set @vMessageName = 'CartonDescriptionIsRequired';
  else
  if (@vAction = 'CartonType_Edit') and (coalesce(@vRecordId, 0) = 0)
    set @vMessageName = 'InvalidRecordId';

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  if (@vAction = 'CartonTypes_Add')
    begin
      /* #ttSelectedEntities is not populated with entries during addition of a new carton type
         Right now we will be adding 1 record at a time */
      select @vTotalRecords = 1;

      /* Insert the record into CartonTypes Table */
      insert into CartonTypes
              (CartonType, Description, EmptyWeight, InnerLength, InnerWidth, InnerHeight,
               OuterLength, OuterWidth, OuterHeight, AvailableSpace, MaxWeight, MaxUnits,
               CarrierPackagingType, Status, SortSeq, BusinessUnit)
        select @vCartonType, @vDescription, @vEmptyWeight, @vInnerLength, @vInnerWidth, @vInnerHeight,
               @vOuterLength, @vOuterWidth, @vOuterHeight, @vAvailableSpace, @vMaxWeight, @vMaxUnits,
               '' /* CarrierPackagingType */, @vStatus, @vSortSeq, @BusinessUnit;
    end
  else
    begin
      /* Update carton type */
      update CartonTypes
      set Description    = coalesce(@vDescription,    Description),
          EmptyWeight    = coalesce(@vEmptyWeight,    EmptyWeight),
          InnerLength    = coalesce(@vInnerLength,    InnerLength),
          InnerWidth     = coalesce(@vInnerWidth,     InnerWidth),
          InnerHeight    = coalesce(@vInnerHeight,    InnerHeight),
          OuterLength    = coalesce(@vOuterLength,    OuterLength),
          OuterWidth     = coalesce(@vOuterWidth,     OuterWidth),
          OuterHeight    = coalesce(@vOuterHeight,    OuterHeight),
          AvailableSpace = coalesce(@vAvailableSpace, AvailableSpace),
          MaxWeight      = coalesce(@vMaxWeight,      MaxWeight),
          MaxUnits       = coalesce(@vMaxUnits,       MaxUnits),
          Status         = coalesce(@vStatus,         Status),
          SortSeq        = coalesce(@vSortSeq,        SortSeq)
      where (RecordId = @vRecordId);
    end

  /* Get record count */
  select @vRecordsUpdated = @@rowcount;

  /* Build response */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_CartonTypes_Action_AddorUpdate */

Go
