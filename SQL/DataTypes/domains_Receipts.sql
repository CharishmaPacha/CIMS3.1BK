/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/20  AY      Changed varchar range for TReceiptType (OB2-1777)
  2020/03/16  AY      Added TReceiptDetails
  2014/01/27  TD      Added TReceiverNumber.
  2013/04/11  AY      Added TInvoiceNo, TContainer
  2013/02/08  PK      Added TVessel, TContainerSize.
  2011/01/14  VK      Added TVendorSKU.
  2010/11/23  VM      Added TPackingSlip.
  2010/09/20  PK      Initial revision.
------------------------------------------------------------------------------*/

Go

/* Common */
Create Type TPackingSlip               from varchar(50);        grant references on Type:: TPackingSlip               to public;
Create Type TReceiptNumber             from varchar(50);        grant references on Type:: TReceiptNumber             to public;
Create Type TReceiverNumber            from varchar(50);        grant references on Type:: TReceiverNumber            to public;

/* ReceiptHdrs */
Create Type TReceiptType               from varchar(10);        grant references on Type:: TReceiptType               to public;
Create Type TVessel                    from varchar(50);        grant references on Type:: TVessel                    to public;
Create Type TContainerSize             from varchar(50);        grant references on Type:: TContainerSize             to public;
Create Type TInvoiceNo                 from varchar(50);        grant references on Type:: TInvoiceNo                 to public;
Create Type TContainer                 from varchar(50);        grant references on Type:: TContainer                 to public;

/* ReceiptDetails */
Create Type TVendorSKU                 from varchar(50);        grant references on Type:: TVendorSKU                 to public;

Go
