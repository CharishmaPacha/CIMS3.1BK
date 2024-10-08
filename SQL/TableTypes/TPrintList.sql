/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  ********************************* IMPORTANT *********************************
  There is a Base version of this TableType exists. Taken here for additional fields.
  So, if there are any common fields to be added, MUST consider adding the same in Base version as well.
  *****************************************************************************

  2022/06/23  RV      TPrintList: Added Notifications (OBV3-529)
  2021/12/16  NB      TPrintList: Added PrintDataReadable(CIMSV3-1767)
  2021/12/14  AY      TPrintList: Added PrintDataBase64(CIMSV3-1767)
  2021/06/13  TK      TPrintList: SortSeqNo should be bigint (BK-348)
  2020/12/03  MS      TPrintList: Added NumDetails (CIMSV3-1250)
  2020/11/11  RV      TPrintList: Added PrintRequestId, PrintJobId and PrintDataFlag (HA-1660)
  2020/06/23  RV      TPrintList: Changed PrintData data type from TVarchar to TBinary (HA-894)
  2020/05/15  AY      TEntitiesToPrint: Added Document format for caller to be able to specific the format (HA-445)
                      TPrintList: Revised to include standard printer field names (HA-445/447)
  2020/04/10  NB      Added DocumentSubClass to TPrintList(CIMSV3-221)
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/*
  Print List is the list of documents (labels & reports) to be printed. This
  data set would contain all the information needed to print a label and/or a
  report. However, if there are any other operations to be done at the time of
  printing i.e. like Create Shipment etc, it would not include the data for that.

  We refer a label or a report to as a document and the fields are interpreted based
  upon whether we are printing a label or a report.

  DocumentClass    Label or Report
  DocumentSubClass Type of Label (BTW, ZPL) or Report (RDLC, PDF)

  DocumentType     Label  - SPL, CL etc.
                   Report - PL, PM, CI etc.
  DocumentSubType  Further detail about DocumentType i.e. What type of PL - ORD or LPN etc.
  DocumentFormat   Label  - LabelFormats.LabelFormatName
                   Report - RDLC Template name

  PrintData        Label  - Used only for ZPL and it is the ZPL Print stream
  PrintDataFlag    To indicate if PrintData is required or not and if required, if processed.

  PrintRequestId   To identify the related Print Request
  PrintJobId       To identify the related Print Job
*/
if type_id('dbo.TPrintList') is not null drop type TPrintList;
Create Type TPrintList as Table (
    EntityType               TEntity,
    EntityKey                TEntityKey,
    EntityId                 TRecordId,

    PrintRequestId           TRecordId,
    PrintJobId               TRecordId,

    DocumentClass            TTypeCode, /* Label or Report */
    DocumentSubClass         TTypeCode, /* Label Type or Report Type */

    DocumentType             TTypeCode, /* LabelType .. SPL, CL, SL, DocType .. PL, CI etc.,.  */
    DocumentSubType          TTypeCode, /* Further detail about DocumentType */

    PrintDataFlag            TFlags,    /* Required, Processed and Ignore: Not required to process */

    DocumentFormat           TName,     /* LabelFormat or RDLC Template or Static file name*/
    DocumentSchema           TName,     /* XSD File for RDLC Template or folder path for Static file */
    NumDetails               TCount,    /* NumDetails to print on the page */
    PrintData                TBinary,   /* ZPLData for ZPL Labels, ReportInput for RDLC */
    PrintDataBase64          TVarchar,
    PrintDataReadable        TVarchar,  /* Readable content, mostly used in Debugging */
    AdditionalContent        TName Default '',

    PrinterName              TName,
    PrinterConfigName        TName,
    PrinterConfigIP          TName,
    PrinterPort              TName,
    PrintProtocol            TName,      /* WIN or IP */
    PrintBatch               TInteger,   /* Group records that need to be printed together, DocumentSet for Reports */

    NumCopies                TInteger,
    SortOrder                TSortOrder, /* The order in which the documents are to be printed */
    InputRecordId            TRecordId,  /* Reference back to the EntitiesToPrint or any other inputs */

    Status                   TStatus Default 'N',
    Description              TDescription,
    Action                   TFlags  Default 'P', -- P-Print, S-Save

    CreateShipment           TFlags,     /* if this is Y, then CarrierInterface should be called to create shipment */

    FilePath                 TName,      /* DocumentFolder..Folder Path of the file */
    FileName                 TName,      /* DocumentFileName..Name of the PDF file to be saved to <DocumentFolder> folder */

    Notifications            TVarChar,

    /* Temporary fields for processing */
    SortSeqNo                bigint,   /* Used temporarily to build the Sort Order */
    ParentEntityKey          TEntityKey,

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,

    ParentRecordId           TRecordId,
    RecordId                 TRecordId Identity(2000, 1), /* DocumentSequence.. for reports which have to be printed together */
    Primary Key              (RecordId),
    Unique                   (EntityId, EntityKey, RecordId)
);

Grant References on Type:: TPrintList to public;

Go
