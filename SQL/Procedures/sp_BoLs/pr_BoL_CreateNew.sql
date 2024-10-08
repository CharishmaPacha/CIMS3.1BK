/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/08/02  RKC     pr_BoL_CreateNew: If ship-to-address is same for all the orders in the load then we need to print ship-to-address on master BoL (CID-880)
  2018/05/04  YJ      pr_BoL_CreateNew: Changes to update FreightTerms from OrderHeaders (S2G-806)
  2018/05/01  AY      pr_BoL_CreateNew: Generate Pro No (S2G-115)
  2014/03/05  PKS     pr_BoL_CreateNew: New Customer code J060C considered while validating Account.
  2013/12/03  PKS     pr_BoL_CreateNew: All Target.Com orders are ThirdParty billing only. Also, there should be default address for ShipTo and BillTo
  2013/06/11  PKS     pr_BoL_CreateNew: ShipToAddressId and BillToAddressId are updated in MasterBol.
  2013/03/28  AY      pr_BoL_CreateNew: Save Account to BoL.UDF2
  2013/01/25  TD      pr_BoL_CreateNew: Default freight set to COD.(COLLECT)
                      pr_BoL_CreateNew: Added BoLType
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_BoL_CreateNew') is not null
  drop Procedure pr_BoL_CreateNew;
Go
/*------------------------------------------------------------------------------
  Proc pr_BoL_CreateNew:
       Procedure creates a New BoL Record in BoLs Table, with the given Input
         values for  BusinessUnit.
------------------------------------------------------------------------------*/
Create Procedure pr_BoL_CreateNew
  (@LoadId            TLoadId,
   @BoLType           TTypeCode      = 'U',
   @BusinessUnit      TBusinessUnit,
   @TrailerNumber     TTrailerNumber = null,
   @SealNumber        TSealNumber    = null,
   @ProNumber         TProNumber     = null,
   @ShipVia           TShipVia       = null,
   @ShipFromAddressId TRecordId,
   @ShipToAddressId   TRecordId,
   @BillToAddressId   TRecordId      = null,
   @MasterBoL         TBoLNumber     = null,
   @FreightTerms      TLookUpCode    = null,
   -----------------------------------------
   @BoLId             TBoLId       output,
   @BoLNumber         TBoLNumber   output,
   @VICSBoLNumber     TBoLNumber   output)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,
          @vBoLNumber              TBoLNumber,
          @vBoLId                  TBoLId,
          @vShipToStore            TShipToStore,
          @vAccount                TDescription,
          @vShipToAddressId        TRecordId,
          @vBillToAddressId        TRecordId,
          @vGeneratedProNo         TProNumber,
          @vUserId                 TUserId,
          @vCount                  TCount,
          @vConsolidatorAddressId  TContactRefId;

  declare @ttAddressIds            TEntityKeysTable;

begin /* pr_BoL_CreateNew */
  select @vReturnCode  = 0,
         @vUserId      = 'CIMS';

  select @vBoLNumber = BoLNumber,
         @vBoLId     = BoLId
  from BoLs
  where (BoLId        = @BoLId) and
        (BusinessUnit = @BusinessUnit);

  /* A BoL already exists with the BoLId value */
  if (@vBoLId is not null)
    goto ExitHandler;

  /* Get ShipToStore and save in BoL.UDF1 */
  select @vShipToStore = Reference2,
         @vAccount     = Reference1
  from vwShipToAddress
  where (ContactId = @ShipToAddressId);

  select @vShipToAddressId = @ShipToAddressId,
         @vBillToAddressId = @BillToAddressId;

  /* If Master BoL, then set ShipTo Account be consolidation address of the account */
  if (@BoLType = 'M')
    begin
      -- select @vAccount  = Min(OH.Account)
      -- from OrderHeaders     OH
      --   join OrderShipments OS on (OS.OrderId   = OH.OrderId)
      --   join Shipments      S  on (S.ShipmentId = OS.ShipmentId)
      --   join Loads          L  on (L.LoadId     = S.LoadId)
      -- where (L.LoadId = @LoadId)
      --
      -- /* Getting ShipToAddress record Id */
      -- select @vShipToAddressId = ContactId
      -- from vwShipToAddress
      -- where (ShipToId = 'C-' + @vAccount);
      --
      -- /* Getting BillToAddressId record Id */
      -- select @vBillToAddressId = ContactId
      -- from vwBillToAddress
      -- where (BillToId = 'T-' + @vAccount);

      /* Consider addresses on underlying BoLs and find a unique ShipTo address */
      if (@vShipToAddressId is null)
        begin
          /* Get the ShipToAddress of all underlying BoLs */
          insert into @ttAddressIds (EntityId, EntityKey)
            select ShipToAddressId, BoLNumber
            from BoLs
            where (LoadId = @LoadId);

          /* Check if all addresses are same, if so, we set to the address id so the address prints on Master BoL */
          select @vShipToAddressId = dbo.fn_Contacts_GetUniqueAddressId (@ttAddressIds, 'S');
        end

      /* Consider addresses on existing BoL and find a unique ShipTo address */
      if (@vBillToAddressId is null)
        begin
          delete from @ttAddressIds;

          /* Get the ShipToAddress of all underlying BoLs */
          insert into @ttAddressIds (EntityId, EntityKey)
            select BillToAddressId, BoLNumber
            from BoLs
            where (LoadId = @LoadId);

          /* Check if all addresses are same, if so, we set to the address id so the address prints on Master BoL */
          select @vBillToAddressId = dbo.fn_Contacts_GetUniqueAddressId (@ttAddressIds, 'B');
        end
    end
  else
    begin
      /* For Underlying BoL, if there is no Pro number given, generate one if needed */
      if (@ProNumber is null)
        exec pr_Shipping_GetNextProNo @ShipVia, @BusinessUnit, @vUserId, @vGeneratedProNo output;
    end

  /* Generate a VICSBoLNumber */
  exec pr_BoL_GetVICSBoLNo  @BusinessUnit, @VICSBoLNumber output, @BoLNumber output;

  /* Insert data into BoL for the newly generated BoL */
  insert into BoLs(BoLNumber,
                   VICSBoLNumber,
                   BoLType,
                   LoadId,
                   TrailerNumber,
                   SealNumber,
                   ProNumber,
                   ShipVia,
                   ShipFromAddressId,
                   ShipToAddressId,
                   BillToAddressId,
                   FreightTerms,
                   UDF1,
                   UDF2,
                   UDF3,
                   UDF4,
                   UDF5,
                   BusinessUnit)
            select @BoLNumber,
                   @VICSBoLNumber,
                   @BoLType,
                   @LoadId,
                   @TrailerNumber,
                   @SealNumber,
                   coalesce(@ProNumber, @vGeneratedProNo),
                   @ShipVia,
                   @ShipFromAddressId,
                   @vShipToAddressId,
                   @vBillToAddressId,
                   @FreightTerms, --@'COD',/* COLLECT */ /* @FreightTerms  Hardcoding to COD as this is not currently imported on Orders */
                   @vShipToStore,
                   null,
                   null,
                   null,
                   null,
                   @BusinessUnit;

  /* Save id of the record just created */
  set @BoLId = Scope_Identity();

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_BoL_CreateNew */

Go
