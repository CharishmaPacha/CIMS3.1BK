/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/06/02  RV     Appended 2 to the Address Validation method as we have integration names appended with 2 (CIMSV3-3532)
  2022/11/25  RKC    tr_OrderHeaders_AU_UpdateContactDetails: Added "SV.IsSmallpackageCarrier= Y" condition and get the AVMethod from controls (OBV3-1517)
  2022/11/15  RKC    tr_OrderHeaders_AU_UpdateContactDetails: Included the FedEx Carrier (OBV3-1443)
  2022/07/29  RV     tr_OrderHeaders_AU_UpdateContactDetails: Made changes to defaul AV method to UPS (BK-882)
  2022/02/25  RT     tr_OrderHeaders_AU_UpdateContactDetails: Trigger to validate the Address when there is ShipVia update (CID-1904)
------------------------------------------------------------------------------*/

Go

if object_id('tr_OrderHeaders_AU_UpdateContactDetails') is not null
  drop Trigger tr_OrderHeaders_AU_UpdateContactDetails;
Go
/*------------------------------------------------------------------------------
  tr_OrderHeaders_AU_UpdateContactDetails: Validate the address of an Order
  when there is change in ShipVia when PreProcessing or ModifyShipDetails
------------------------------------------------------------------------------*/
Create Trigger tr_OrderHeaders_AU_UpdateContactDetails on OrderHeaders After update
as
  declare @vDefaultAVMethod   TControlValue,
          @vBusinessUnit      TBusinessUnit;
begin
  /* If OrderHeaders table was modified, but ShipVia was not part of the update statement, then exit */
  if not update(ShipVia) return;

  /* Get BusinessUnit */
  select top 1 @vBusinessUnit = BusinessUnit from Inserted

  /* Get Default Address validation method from controls */
  select @vDefaultAVMethod = dbo.fn_Controls_GetAsString('AddressValidation', 'AVMethod', '%Carrier%' /* FedEx, UPS, %Carrier% */, @vBusinessUnit, '' /* UserId */);

  /* Reset the Contacts for address validation.
     We have integration names for UPS and FedEx with '2' appended, for example: CIMSUPS2 and CIMSFEDEX2.
     Therefore, we need to append '2' to the carrier names */
  update C
  set C.AVMethod = iif(@vDefaultAVMethod = '%Carrier%', SV.Carrier + '2', @vDefaultAVMethod), /* As of now all SPL orders validate with FEDEX carrier until implement the other carriers services */
      C.AVStatus = 'ToBeVerified'
  from Contacts C
    join Inserted     INS on (INS.ShipToId             = C.ContactRefId  ) and
                             (INS.BusinessUnit         = C.BusinessUnit  )
    join ShipVias     SV  on (SV.ShipVia               = INS.ShipVia     ) and
                             (SV.IsSmallPackageCarrier = 'Y'             ) and
                             (SV.BusinessUnit          = INS.BusinessUnit)
  where (C.ContactType = 'S') and (C.AVStatus not in ('Valid'));

end /* tr_OrderHeaders_AU_UpdateContactDetails */

Go

/* By default we will use address validation, so leave the trigger enabled */
--alter table OrderHeaders enable trigger tr_OrderHeaders_AU_UpdateContactDetails;

Go
