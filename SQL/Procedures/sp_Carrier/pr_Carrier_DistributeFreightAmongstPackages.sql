/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/09/16  RV/VS   Made changes to distribute the freight charges when generating all the packages at once (CIMSV3-3792)
  2022/12/26  VS      pr_Carrier_DistributeFreightAmongstPackages, pr_Carrier_Response_SaveShipmentData:
  2022/10/18  VS      pr_Carrier_DistributeFreightAmongstPackages/OnTrackingNoGenerate/ProcessStatus,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Carrier_DistributeFreightAmongstPackages') is not null
  drop Procedure pr_Carrier_DistributeFreightAmongstPackages;
Go
/*------------------------------------------------------------------------------
  Proc pr_Carrier_DistributeFreightAmongstPackages: In some cases the freight
    charges may be returned at the shipment level instead of the package level.
    We then need to distribute the freight charges of the shipment against the
    individual packages and this proc does that.
    For example for FedEx International Multi Packages each Order is a shipment
    and all the charges are distributed against all the packages in the shipment.
    Also, even in this example, additional packages (after reallocation) may be
    their own shipments with one package only with their own charge.
------------------------------------------------------------------------------*/
Create Procedure pr_Carrier_DistributeFreightAmongstPackages
  (@Carrier TCarrier)
as
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vShipmentListNetCharge      TMoney,
          @vShipmentAcctNetCharge      TMoney,
          @vTotalWeight                TWeight,
          @vTotalVolume                TVolume,
          @vShipmentPackagesCount      TCount,
          @vNumLPNs                    TCount,
          @vRemainderListNetCharge     TMoney,
          @vRemainderAcctNetCharge     TMoney;
begin /* pr_Carrier_DistributeFreightAmongstPackages */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode        = 0,
         @vMessageName       = null;

  /* FedEx International Mult Package Shipments AcctNet and ListNetCharges are getting Shipment Levels so we need to distribut to all Packges based on Weight */
  if (@Carrier = 'FEDEX')
    begin
      /* Get the Packages info */
      select @vShipmentPackagesCount = count(*),
             @vTotalWeight           = sum(PackageWeight),
             @vTotalVolume           = sum(PackageVolume)
      from #Packages;

      /* Retrieve the shipment level AcctNetCharges and ListNetCharges */
      select @vShipmentListNetCharge = NetCharge_Amount from #ShipmentRating where (RateType = 'PAYOR_LIST_SHIPMENT');
      select @vShipmentAcctNetCharge = NetCharge_Amount from #ShipmentRating where (RateType = 'PAYOR_ACCOUNT_SHIPMENT');

      /* Distribute the freight charges based on the weight of each package. If there is only one package,
         then the ShipmentCharge is attributed to the package */
      update P
      set ListNetCharge = case when @vShipmentPackagesCount = 1 then @vShipmentListNetCharge
                               else round((P.PackageWeight / @vTotalWeight) * @vShipmentListNetCharge, 2)
                          end,
          AcctNetCharge = case when @vShipmentPackagesCount = 1 then @vShipmentAcctNetCharge
                               else round((P.PackageWeight / @vTotalWeight) * @vShipmentAcctNetCharge, 2)
                          end
      from #Packages P;

      /* When there are multiple packages, the above code distributes it, but due to rounding,
         the total distributed charges may not exactly add up to the total shipment charges, so
         compute the residual charges and add to the first package */
      if (@vShipmentPackagesCount > 1)
        begin
          /* Get the remaining values to add it to any one of the charges of LPN of the shipment */
          select @vRemainderListNetCharge = @vShipmentListNetCharge - sum(ListNetCharge),
                @vRemainderAcctNetCharge = @vShipmentAcctNetCharge - sum(AcctNetCharge)
          from #Packages

          /* Add remaining values to the charges of first LPN of the shipment */
          update #Packages
          set ListNetCharge += @vRemainderListNetCharge,
              AcctNetCharge += @vRemainderAcctNetCharge
          from #Packages
          where (RecordId = 1);
        end

      /* Update the final package charges to Shiplabels table */
      update SL
      set SL.ListNetCharge = P.ListNetCharge,
          SL.AcctNetCharge = P.AcctNetCharge
      from #Packages P
        join ShipLabels SL on (SL.EntityId = P.EntityId)
      where (SL.Status = 'A') and (SL.ProcessStatus = 'LG');
    end

  --/* Other than FedEx Carrier for International MPS getting AcctNetCharges and ListNetCharges each package level only */
  --if (@Carrier <> 'FEDEX')
  --  begin
  --    /* Capturing Total ListNetCharges and Total AccNetCharges from response node since it is common for all packages
  --       fetch charges and update rows in shiplabel temp table */
  --    select @vTotalListNetCharge = ListNetCharge,
  --           @vTotalAcctNetCharge = AcctNetCharge
  --    from #Packages

  --    /* Get the total LPNs weight & volume to use further */
  --    select @vTotalWeight = sum(L.LPNWeight),
  --           @vTotalVolume = sum(L.LPNVolume)
  --    from #Packages ttSL
  --      join LPNs L on (L.LPNId = ttSL.EntityId);

  --    /* Get Number of LPNs from response -> No.of records are No.of LPNs */
  --    select @vNumLPNs = count(*) from #Packages;

  --    /* For MultiPackage Shipment, need to split the charges */
  --    if (@vNumLPNs > 1)
  --      begin
  --        /* Share total charges to each LPN by calculating LPN charges based on Order total weight and LPN weight */
  --        update ttSL
  --        set ttSL.ListNetCharge = round((L.LPNWeight / @vTotalWeight) * @vTotalListNetCharge, 2),
  --            ttSL.AcctNetCharge = round((L.LPNWeight / @vTotalWeight) * @vTotalAcctNetCharge, 2)
  --        from #Packages ttSL
  --          join LPNs L on (L.LPNId = ttSL.EntityId);

  --        /* Get the remaining values to add it to any one of the charges of LPN of the shipment */
  --        select @vRemainderListNetCharge = @vTotalListNetCharge - sum(ListNetCharge),
  --               @vRemainderAcctNetCharge = @vTotalAcctNetCharge - sum(AcctNetCharge)
  --        from #Packages

  --        /* Add remaining values to the charges of first LPN of the shipment */
  --        update #Packages
  --        set ListNetCharge += @vRemainderListNetCharge,
  --            AcctNetCharge += @vRemainderAcctNetCharge
  --        from #Packages
  --        where (RecordId = 1);
  --      end
  --    else
  --      /* If it is a single package (not a MultiPackage Shipment) - total charges apply to one LPN only */
  --      update #Packages
  --      set ListNetCharge = @vTotalListNetCharge,
  --          AcctNetCharge = @vTotalAcctNetCharge
  --  end

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Carrier_DistributeFreightAmongstPackages */

Go
