/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/02  AY      Added ZPL Template (CIMSV3-1183)
  2020/10/12  MS      Added mapping NumCopies (CIMSV3-1131)
  2020/09/17  RV      Initial Revision (CIMSV3-1079)
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwLabelFormats') is not null
  drop View dbo.vwLabelFormats;
Go

Create View dbo.vwLabelFormats (
  RecordId,

  EntityType,

  LabelFormatName,
  LabelFormatDesc,
  LabelFileName,
  LabelSize,

  PrintDataStream,
  PrintOptions,
  NumCopies,
  PrinterMake,
  AdditionalContent,
  ZPLTemplate,
  ZPLFile,
  ZPLLink,

  LabelTemplateType,
  LabelSQLStatement,
  ZPLLabelSQLStatement,

  Status,
  SortSeq,
  Visible,

  LabelWidth,
  LabelHeight,

  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) As
select
  LF.RecordId,

  LF.EntityType,

  LF.LabelFormatName,
  LF.LabelFormatDesc,
  LF.LabelFileName,
  LF.LabelSize,

  LF.PrintDataStream,
  LF.PrintOptions,
  LF.NumCopies,
  LF.PrinterMake,
  LF.AdditionalContent,
  (select STRING_AGG(TemplateDetail, char(13)) from ContentTemplates where TemplateName = LabelFormatName), -- ZPLTemplate
  LF.LabelFormatName + '.zpl', -- ZPL File Name
  '?density=8&quality=grayscale&width=' + substring(LabelSize, 1, charindex('x', LabelSize)-1) +
  '&height=' + substring(LabelSize, charindex('x', LabelSize)+1, len(LabelSize)) +
  '&units=inches&index=0&zpl=' + (select dbo.fn_URLEncode(STRING_AGG(replace(TemplateDetail, '<%LabelHome%>', '0'), char(13))) from ContentTemplates where TemplateName = LabelFormatName),

  LF.LabelTemplateType,
  LF.LabelSQLStatement,
  LF.ZPLLabelSQLStatement,

  LF.Status,
  LF.SortSeq,
  LF.Visible,

  substring(LabelSize, 1, charindex('x', LabelSize)-1),              -- Label Width
  substring(LabelSize, charindex('x', LabelSize)+1, len(LabelSize)), -- Label Height

  LF.BusinessUnit,
  LF.CreatedDate,
  LF.ModifiedDate,
  LF.CreatedBy,
  LF.ModifiedBy
from
  LabelFormats LF
where LF.Visible = 'Y';

Go
