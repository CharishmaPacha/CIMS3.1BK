/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person   Comments

  2021/07/02  AY       BoLs_Modify: Changed to use BoLFreightTerms_DD (HA-2849)
  2020/02/22  AY       BoLs_ModifyShipToAddress: Use Consolidator Address, not ShipTo (HA-2042)
  2020/12/04  PHK      BoLs_ModifyShipToAddress: Changed ControlName for ShipToAddressId (HA-1020)
  2020/07/03  HYP      Added form details for modify BoLShipToAddressId (HA-1020)
  2020/06/18  OK       Added form details for modify BoLCarrierDetails (HA-1005)
  2020/06/18  SJ       Added form details for modify BoLOrderDetails (HA-874)
  2020/06/18  KBB      Initial revision(HA-986)
------------------------------------------------------------------------------*/

Go

declare @FormName  TName;
/*------------------------------------------------------------------------------*/
/* BoL_Modify Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'BoLs_Modify';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'BoLId',                 'HiddenInput',           null,                    0,          null,         1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'BolNumber',             'ReadOnlyText',          null,                    0,          null,         2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ShipToLocation',        'Text',                  null,                    0,          null,         3,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'FoB',                   'FoB_DD',                null,                    0,          null,         4,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'BoLCID',                'Text',                  null,                    0,          null,         5,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'TrailerNumber',         'Text',                  null,                    0,          null,         6,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'SealNumber',            'Text',                  null,                    0,          null,         7,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ProNumber',             'Text',                  null,                    0,          null,         8,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ShipViaDescription',    'HiddenInput',           null,                    0,          null,         9,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'BoLInstructions',       'Text',                  null,                    0,          null,        10,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'FreightTerms',          'BoLFreightTerms_DD',    null,                    0,          null,        11,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
--union select 'ShipToAddressId',     'ShipToAddressId_DD',    null,                    0,          null,        12,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'BillToAddressId',       'BillToAddressId_DD',    null,                    0,          null,        13,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* BoL_Master Form Attributes. This is only applicable for MasterBoL and the reason
   to change the ShipTo on MasterBoL is the consolidator could vary */
/*------------------------------------------------------------------------------*/
select @FormName = 'BoLs_ModifyShipToAddress';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'BoLId',                 'HiddenInput',           null,                    0,          null,         1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'BolNumber',             'ReadOnlyText',          null,                    0,          null,         2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ShipToAddressId',       'ConsolidatorAddress_DD',null,                    0,          null,         1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* BoLOrderDetails_Modify Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'BoLOrderDetails_Modify';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'BoLOrderDetailId',     'HiddenInput',            null,                    0,          null,         1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'BoLNumber',            'ReadOnlyText',           null,                    0,          null,         1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'CustomerOrderNo',      'ReadOnlyText',           null,                    0,          null,         2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'NumPackages',          'Text',                   null,                    0,          null,         3,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'Weight',               'Text',                   null,                    0,          null,         4,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'Palletized',           'Text',                   null,                    0,          null,         5,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'ShipperInfo',          'Text',                   null,                    0,          null,         6,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

/*------------------------------------------------------------------------------*/
/* Modify BoLCarrierDetails Form Attributes */
/*------------------------------------------------------------------------------*/
select @FormName = 'BoLCarrierDetails_Modify';

/* Clear Table Entries */
delete from UIFormDetails where (FormName = @FormName);

insert into UIFormDetails
            (FieldName,               ControlName,             FieldCaption,            IsRequired, DefaultValue, SortSeq, DataTagType, DataTagName,        FormName,  BusinessUnit)
      select 'BoLCarrierDetailId',   'HiddenInput',            null,                    0,          null,         1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'BoLNumber',            'ReadOnlyText',           null,                    0,          null,         1,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'HandlingUnitQty',      'IntegerMin0',            null,                    0,          null,         2,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'HandlingUnitType',     'Text',                   null,                    0,          null,         3,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'PackageQty',           'IntegerMin0',            null,                    0,          null,         4,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'PackageType',          'Text',                   null,                    0,          null,         5,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'Weight',               'IntegerMin0',            null,                    0,          null,         6,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'CommDescription',      'Text',                   null,                    0,          null,         7,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'NMFCCode',             'Text',                   null,                    0,          null,         8,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits
union select 'NMFCClass',            'Text',                   null,                    0,          null,         9,       'Data',      null,               @FormName, BusinessUnit from vwBusinessUnits

Go