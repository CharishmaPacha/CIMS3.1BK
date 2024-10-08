/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/05  MS      ContentTemplates: UniqueKey constraint changed (HA-579)
  2020/05/29  VM      ContentTemplates: New fields - LinType, LineCondition (HA-575)
  2019/08/05  AY      ContentTemplates: Added AdditionalData
  2016/08/19  DK      Added new table ContentTemplates (HPI-457)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Table: ContentTemplates - The table holds templates for content of emails etc.
   TemplateName    - Unique identifier of each template
   TemplateType    - HTML, TEXT, ZPL
   LineType        - HDR (Header), DTL (Detail), FTR (Footer)
   TemplateDetail  - Actual content
   LineCondition   - Condition to make the line part of the complete template or not
   AdditionalData  - To complete templates for Content Labels we need additional data
                     to position each section correctly. This field holds that in XML format
------------------------------------------------------------------------------*/
Create Table ContentTemplates (
    RecordId                 TRecordId      identity (1,1) not null,

    TemplateName             TName,
    TemplateType             TTypeCode,
    LineType                 TTypeCode,
    TemplateDetail           TVarChar,
    LineCondition            TQuery,

    Category                 TCategory,
    SubCategory              TCategory,

    Status                   TStatus        not null default 'A' /* Active */,
    SortSeq                  TSortSeq       not null default 0,

    AdditionalData           xml,

    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkTemplates_RecordId  PRIMARY KEY (RecordId),
    constraint ukTemplates_Name      UNIQUE (TemplateName, SortSeq, BusinessUnit)
);

Go
