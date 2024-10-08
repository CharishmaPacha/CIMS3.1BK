/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/23  AY      pr_Imports_CartonTypes: Changed UDFs to be with prefix CT_ (HA-796)
  2018/02/09  TD      pr_Imports_CartonTypes:Changes to update CartonTypeFilter (S2G-107)
  2015/09/09  YJ      pr_Imports_CartonTypes: Called function fn_Imports_ResolveAction to resolve Action (ACME-312)
  2015/06/30  OK      Added pr_Imports_CartonTypes, pr_Imports_ValidateCartonTypes.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_CartonTypes') is not null
  drop Procedure pr_Imports_CartonTypes;
Go
/*------------------------------------------------------------------------------
  Proc pr_Imports_CartonTypes:
------------------------------------------------------------------------------*/
Create Procedure pr_Imports_CartonTypes
  (@xmlData              Xml             = null,
   @Action               TFlag           = null,
   @CartonType           TCartonType     = null,
   @Description          TDescription    = null,
   @EmptyWeight          TWeight         = null,
   @InnerLength          TLength         = null,
   @InnerWidth           TLength         = null,
   @InnerHeight          TLength         = null,
   @InnerVolume          TLength         = null,
   @OuterLength          TLength         = null,
   @OuterWidth           TLength         = null,
   @OuterHeight          TLength         = null,
   @OuterVolume          TLength         = null,
   @CarrierPackagingType varchar(max)    = null,
   @SoldToId             TCustomerId     = null,
   @ShipToId             TShipToId       = null,
   @AvailableSpace       TInteger        = null,
   @MaxWeight            TWeight         = null,
   @Status               TStatus         = null,
   @SortSeq              TSortSeq        = null,
   @Visible              TBoolean        = null,
   @CT_UDF1              TUDF            = null,
   @CT_UDF2              TUDF            = null,
   @CT_UDF3              TUDF            = null,
   @CT_UDF4              TUDF            = null,
   @CT_UDF5              TUDF            = null,
   @BusinessUnit         TBusinessUnit   = null,
   @CreatedDate          TDateTime       = null,
   @ModifiedDate         TDateTime       = null,
   @CreatedBy            TUserId         = null,
   @ModifiedBy           TUserId         = null,
   @HostRecId            TRecordId       = null)

as
  declare @vReturnCode              TInteger,
          @vParentLogId             TRecordId,
          /* Table variables for CartonTypes, CartonType Validations and AuditTrail */
          @ttCartonTypesImports     TCartonTypesImportType,
          @ttCartonTypesValidation  TImportValidationType,
          @ttAuditInfo              TAuditTrailInfo;
begin
  SET NOCOUNT ON;

  if (@xmldata is not null)
    select @vParentLogId = Record.Col.value('ParentLogId[1]','TRecordId')
    from @xmlData.nodes('//msg/msgHeader') as Record(Col);

  /* Populate the CartonTypes table type */
  if (@xmlData is not null)
    begin
      insert into @ttCartonTypesImports (
        InputXML,
        RecordAction,
        CartonType,
        Description,
        EmptyWeight,
        InnerLength,
        InnerWidth,
        InnerHeight,
        InnerVolume,
        OuterLength,
        OuterWidth,
        OuterHeight,
        OuterVolume,
        CarrierPackagingType,
        SoldToId,
        ShipToId,
        AvailableSpace,
        MaxWeight,
        Status,
        SortSeq,
        Visible,
        CT_UDF1,
        CT_UDF2,
        CT_UDF3,
        CT_UDF4,
        CT_UDF5,
        BusinessUnit,
        CreatedDate,
        ModifiedDate,
        CreatedBy,
        ModifiedBy,
        HostRecId)
      select
        convert(nvarchar(max), Record.Col.query('.')),
        Record.Col.value('Action[1]',               'TFlag'),
        Record.Col.value('CartonType[1]',           'TCartonType'),
        Record.Col.value('Description[1]',          'TDescription'),
        Record.Col.value('EmptyWeight[1]',          'TWeight'),
        Record.Col.value('InnerLength[1]',          'TLength'),
        Record.Col.value('InnerWidth[1]',           'TLength'),
        Record.Col.value('InnerHeight[1]',          'TLength'),
        Record.Col.value('InnerVolume[1]',          'TSKU'),
        Record.Col.value('OuterLength[1]',          'TLength'),
        Record.Col.value('OuterWidth[1]',           'TLength'),
        Record.Col.value('OuterHeight[1]',          'TLength'),
        Record.Col.value('OuterVolume[1]',          'varchar(max)'),
        Record.Col.value('CarrierPackagingType[1]', 'TSKU'),
        Record.Col.value('SoldToId[1]',             'TCustomerId'),
        Record.Col.value('ShipToId[1]',             'TShipToId'),
        Record.Col.value('AvailableSpace[1]',       'TInteger'),
        Record.Col.value('MaxWeight[1]',            'TWeight'),
        Record.Col.value('Status[1]',               'TStatus'),
        coalesce(Record.Col.value('SortSeq[1]',     'TSortSeq'), 0),
        coalesce(Record.Col.value('Visible[1]',     'TBoolean'), 0),
        Record.Col.value('UDF1[1]',                 'TUDF'),
        Record.Col.value('UDF2[1]',                 'TUDF'),
        Record.Col.value('UDF3[1]',                 'TUDF'),
        Record.Col.value('UDF4[1]',                 'TUDF'),
        Record.Col.value('UDF5[1]',                 'TUDF'),
        Record.Col.value('BusinessUnit[1]',         'TBusinessUnit'),
        nullif(Record.Col.value('CreatedDate[1]',   'TDateTime'), ''),
        nullif(Record.Col.value('ModifiedDate[1]',  'TDateTime'), ''),
        Record.Col.value('CreatedBy[1]',            'TUserId'),
        Record.Col.value('ModifiedBy[1]',           'TUserId'),
        Record.Col.value('HostRecId[1]',            'TRecordId')
      from @xmlData.nodes('//msg/msgBody/Record') as Record(Col)
      OPTION ( OPTIMIZE FOR ( @xmlData = null ) )
    end
  else
    begin
      insert into @ttCartonTypesImports (
        RecordAction, CartonType, Description,
        EmptyWeight, InnerLength, InnerWidth,
        InnerHeight, OuterLength,
        OuterWidth, OuterHeight,
        CarrierPackagingType, SoldToId, ShipToId,
        AvailableSpace, MaxWeight, Status, SortSeq,
        Visible, CT_UDF1, CT_UDF2, CT_UDF3, CT_UDF4, CT_UDF5, BusinessUnit,
        CreatedDate, ModifiedDate, CreatedBy, ModifiedBy, HostRecId)
      select
        @Action, @CartonType, @Description,
        @EmptyWeight, @InnerLength, @InnerWidth,
        @InnerHeight, @OuterLength,
        @OuterWidth, @OuterHeight,
        @CarrierPackagingType, @SoldToId, @ShipToId,
        @AvailableSpace, @MaxWeight, @Status, @SortSeq,
        @Visible, @CT_UDF1, @CT_UDF2, @CT_UDF3, @CT_UDF4, @CT_UDF5, @BusinessUnit,
        @CreatedDate, @ModifiedDate, @CreatedBy, @ModifiedBy, @HostRecId;
    end

  /* Update with RecordId of CartonTypes */
  update TCT
  set TCT.CartonTypeId = CT.RecordId
  from @ttCartonTypesImports TCT
  join CartonTypes CT on CT.CartonType = TCT.CartonType;

  /* Validating the CartonTypes */
  insert @ttCartonTypesValidation
    exec pr_Imports_ValidateCartonTypes @ttCartonTypesImports;

  /* Set RecordAction for Carton Type Records  */
  update @ttCartonTypesImports
  set RecordAction = CTV.RecordAction
  from @ttCartonTypesImports CTI
    join @ttCartonTypesValidation CTV on (CTI.RecordId = CTV.RecordId);

  /* Insert update or Delete based on Action */
  if (exists(select * from @ttCartonTypesImports where (RecordAction = 'I' /* Insert */)))
    insert into CartonTypes (
      CartonType,
      Description,
      EmptyWeight,
      InnerLength,
      InnerWidth,
      InnerHeight,
      OuterLength,
      OuterWidth,
      OuterHeight,
      CarrierPackagingType,
      SoldToId,
      ShipToId,
      AvailableSpace,
      MaxWeight,
      Status,
      SortSeq,
      Visible,
      CT_UDF1,
      CT_UDF2,
      CT_UDF3,
      CT_UDF4,
      CT_UDF5,
      BusinessUnit,
      CreatedDate,
      ModifiedDate,
      CreatedBy,
      ModifiedBy)
    select
      CartonType,
      Description,
      EmptyWeight,
      InnerLength,
      InnerWidth,
      InnerHeight,
      OuterLength,
      OuterWidth,
      OuterHeight,
      CarrierPackagingType,
      SoldToId,
      ShipToId,
      AvailableSpace,
      MaxWeight,
      coalesce(nullif(ltrim(rtrim(Status)), ''), 'A' /* Active */),
      coalesce(SortSeq, 0),
      coalesce(Visible, 0),
      CT_UDF1,
      CT_UDF2,
      CT_UDF3,
      CT_UDF4,
      CT_UDF5,
      BusinessUnit,
      CreatedDate,
      ModifiedDate,
      coalesce(CreatedDate, current_timestamp),
      coalesce(CreatedBy, System_User)
    from @ttCartonTypesImports
    where ( RecordAction = 'I' /* Insert */)
    order by HostRecId;

  if (exists(select * from @ttCartonTypesImports where (RecordAction = 'U' /* Update */)))
    update C1
    set
      C1.Description             = C2.Description,
      C1.EmptyWeight             = C2.EmptyWeight,
      C1.InnerLength             = C2.InnerLength,
      C1.InnerWidth              = C2.InnerWidth,
      C1.InnerHeight             = C2.InnerHeight,
      C1.OuterLength             = C2.OuterLength,
      C1.OuterWidth              = C2.OuterWidth,
      C1.OuterHeight             = C2.OuterHeight,
      C1.CarrierPackagingType    = C2.CarrierPackagingType,
      C1.SoldToId                = C2.SoldToId,
      C1.ShipToId                = C2.ShipToId,
      C1.AvailableSpace          = C2.AvailableSpace,
      C1.MaxWeight               = C2.MaxWeight,
      C1.Status                  = coalesce(nullif(ltrim(rtrim(C2.Status)), ''), 'A' /* Active */),
      C1.SortSeq                 = C2.SortSeq,
      C1.Visible                 = C2.Visible,
      C1.CT_UDF1                 = C2.CT_UDF1,
      C1.CT_UDF2                 = C2.CT_UDF2,
      C1.CT_UDF3                 = C2.CT_UDF3,
      C1.CT_UDF4                 = C2.CT_UDF4,
      C1.CT_UDF5                 = C2.CT_UDF5,
      C1.BusinessUnit            = C2.BusinessUnit,
      C1.ModifiedDate            = coalesce(C2.ModifiedDate, current_timestamp),
      C1.ModifiedBy              = coalesce(C2.ModifiedBy, System_User)
   /* output to audit info */
    output 'CT', Inserted.CartonType, 'CartonTypeModified', C2.RecordAction,
           Inserted.BusinessUnit, Inserted.ModifiedBy
    into @ttAuditInfo (EntityType, EntityKey, ActivityType, Action, BusinessUnit, UserId)
    from CartonTypes C1
      join @ttCartonTypesImports C2 on (C1.CartonType    = C2.CartonType)
    where (C2.RecordAction = 'U' /* Update */);

  /* process deletes by just marking them as inactive */
  if (exists(select * from @ttCartonTypesImports where (RecordAction = 'D' /* Delete */)))
    begin
      /* Capture audit info */
      insert into @ttAuditInfo (EntityType, EntityKey, ActivityType, Action, BusinessUnit, UserId)
        select 'CT', CartonType, 'CartonTypeDeleted', RecordAction, BusinessUnit, ModifiedBy
        from @ttCartonTypesImports
        where (RecordAction = 'D');

      update C1
      set C1.Status = 'I' /* Inactive */
      from CartonTypes C1
        join @ttCartonTypesImports C2 on (C1.CartonType = C2.CartonType)
      where (C2.RecordAction = 'D');
    end

  /* Verify if Audit Trail should be updated */
  if (exists(select * from @ttAuditInfo))
    begin
      /* Update comment. The comment will be used later to handle updating audit id values */
      update @ttAuditInfo
      set Comment = dbo.fn_Messages_BuildDescription(ActivityType, 'CT', EntityKey /* Carton Type */, null, null, null, null, null, null, null, null, null, null);

      exec pr_AuditTrail_InsertRecords @ttAuditInfo;
    end

  /* Update Interface Log with the inserted/Updated/deleted details */
  exec pr_InterfaceLog_AddDetails @vParentLogId, 'Import', null, @ttCartonTypesValidation;

end /* pr_Imports_CartonTypes */

Go
