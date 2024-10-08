/*------------------------------------------------------------------------------
  (c) Foxfire Technologies (India) Ltd. Hyderabad, India

  Revision History:

  Date        Person  Comments

  2010/12/08  PK      Initial revision.
------------------------------------------------------------------------------*/
Go

delete from InterfaceTypes;

Go
/*------------------------------------------------------------------------------
 InterfaceTypes
------------------------------------------------------------------------------*/
insert into InterfaceTypes  (TransferType,    RecordType,     Description,            ProcedureName,             SortSeq, Status, BusinessUnit)
                     select 'I'/* Import */, 'SKU',           'SKU Import',           'pr_Imports_SKUs',         1,       'A',    BusinessUnit from vwBusinessUnits
Go
