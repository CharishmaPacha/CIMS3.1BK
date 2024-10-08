/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/12/11  PK      pr_Imports_ReceiptDetails: Enhancements to gather SKU info by using RD UDF's.
                      pr_Imports_ValidateReceiptDetail: Validate Receipt and SKU by gathering from RD UDF's.
                      pr_Imports_LogError: If there are no records then insert the message name in the temp table.
                      pr_Imports_LogError, pr_Imports_ValidateLookUp, pr_Imports_ValidateInputdata:
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Imports_LogError') is not null
  drop Procedure pr_Imports_LogError;
Go
Create Procedure pr_Imports_LogError
  (@MessageName  TMessageName,
   @Value1       TDescription = null,
   @Value2       TDescription = null,
   @Value3       TDescription = null,
   @Value4       TDescription = null,
   @Value5       TDescription = null)
as
  declare @MessageDesc TMessageName;
begin
  /* Log the description of the error */
  insert into #Errors (Error)
    select dbo.fn_Messages_Build(@MessageName, @Value1, @Value2, @Value3, @Value4, @Value5);
end /* pr_Imports_LogError */

Go
