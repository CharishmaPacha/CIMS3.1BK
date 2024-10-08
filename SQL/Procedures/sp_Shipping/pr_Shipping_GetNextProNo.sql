/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/05/01  AY      pr_Shipping_GetNextProNo: Generate next Pro No (S2G-115)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_GetNextProNo') is not null
  drop Procedure pr_Shipping_GetNextProNo;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipping_GetNextProNo:
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_GetNextProNo
  (@ShipVia          TShipVia,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @ProNo            TProNumber output)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,
          @vCheckDigit        TInteger,
          @vProNo             TProNumber,
          @xmlData            TXML,

          @vControlCategory   TCategory,
          @vAutoGenerateProNo TControlValue;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  select @vControlCategory = 'ProNumber_' + @ShipVia;

  select @vAutoGenerateProNo = dbo.fn_Controls_GetAsString(@vControlCategory, 'AutoGenerate', '1' /* No */,  @BusinessUnit, @UserId);

  /* Get the generic for the ones which is not defined */
  if (@vAutoGenerateProNo = '1')
    begin
      select @vControlCategory = 'ProNumber_Generic';
      select @vAutoGenerateProNo = 'Y';
    end

  if (@vAutoGenerateProNo = 'N' /* No */)
    goto ErrorHandler;

  exec pr_Controls_GetNextSeqNoStr @vControlCategory, 1 /* Count */, @UserId, @BusinessUnit,
                                   @vProNo output;

  /* There are multiple logics to generate the check digits, primarily based
     upon the Carrier. We would use it as rule driven */
  select @xmlData = '<RootNode>' +
                       dbo.fn_XMLNode('ShipVia',      @ShipVia) +
                       dbo.fn_XMLNode('ProNo',        @vProNo) +
                       dbo.fn_XMLNode('BusinessUnit', @BusinessUnit) +
                    '</RootNode>'

  /* Get the ProNumber CheckDigit */
  exec pr_RuleSets_Evaluate 'ProNumberCheckDigit', @xmlData, @vCheckDigit output;

  /* Update ProNumber by adding CheckDigit and return to the caller */
  select @ProNo = @vProNo + coalesce(cast(@vCheckDigit as varchar(max)), '');

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Shipping_GetNextProNo */

Go

--
