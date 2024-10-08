/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/02/06  RIA     pr_AMF_Inquiry_VAS: Changes to get UDF4 and UDF6 values (CID-1318)
  2019/06/22  RIA     pr_AMF_Inquiry_VAS: Changes to show additional information (CID-577)
  2019/06/18  RIA     pr_AMF_Inquiry_VAS: Changes to build values for table (CID-577)
  2019/05/24  RIA     pr_AMF_Inquiry_VAS: Changes to build xml with appropriate nodes to display the value (CID-382)
  2019/05/23  AY      pr_AMF_Inquiry_VAS: Change to use diff view to use for tees as well (CID-382)
  2019/05/19  RIA     pr_AMF_Inquiry_VAS: Changes to build xml that suits for VAS (CID-382)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Inquiry_VAS') is not null
  drop Procedure pr_AMF_Inquiry_VAS;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Inquiry_VAS:@vLPNInfo

  Processes the requests for VAS Instructions for VAS Inquiry work flow
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Inquiry_VAS
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
  declare @vInputXML                 xml,
          @LPN                       TLPN,
          @vLPNInfo                  TXML,
          @vLPNInfoXML               TXML,
          @vLPNDetailsXML            TXML,
          @vVASInfoxml               xml,
          @vxmlLPNDetails            xml,
          @vLPNId                    TRecordId,
          @vLPN                      TLPN,
          @vLPNOrderId               TRecordId,
          @vTrackingNo               TTrackingNo,
          @vUCCBarcode               TBarcode,
          @vLPNStatusDesc            TDescription,
          @vOH_UDF2                  TUDF,
          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId,
          @vReturnCode               TInteger,
          @vMessageName              TMessageName;
begin /* pr_AMF_Inquiry_VAS */

  select @vInputXML = convert(xml, @InputXML); /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vInputXML.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vInputXML.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /* Read inputs from InputXML */
  select @vUserId       = Record.Col.value('(SessionInfo/UserName)[1]',     'TUserId'      ),
         @vBusinessUnit = Record.Col.value('(SessionInfo/BusinessUnit)[1]', 'TBusinessUnit'),
         @vLPN          = Record.Col.value('(Data/LPN)[1]',                 'TLPN'         )
  from @vInputXML.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vInputXML = null));

  /* Insert exec fails when the lpn is invalid for vas Inquiry
     This is because of the rollback statement which gets executed for invalid lpns
     Therefore, validations for lpn from lpn inquiry procedure are performed here, to avoid db error and show proper error */
  select @vLPNId         = LPNId,
         @vLPN           = LPN,
         @vLPNStatusDesc = StatusDescription,
         @vLPNOrderId    = OrderId,
         @vTrackingNo    = TrackingNo,
         @vUCCBarcode    = UCCBarcode
  from  vwLPNs
  where (LPNId = dbo.fn_LPNs_GetScannedLPN (@vLPN, @vBusinessUnit, 'LTU'));

  select @vOH_UDF2 = UDF2
  from OrderHeaders
  where (OrderId = @vLPNOrderId);

  if (@vLPNId is null)
    set @vMessageName = 'LPNDoesNotExist';
  else
  if (@vLPNOrderId is null)
    select @vMessageName = 'AMF_VAS_LPNNotAssociatedWithAnyOrder'
  else
  if (coalesce(@vOH_UDF2, '') = '')
    select @vMessageName = 'AMF_VAS_OrderDoesNotRequireVAS'

  /* This will raise an exception, and the caller ExecuteAction procedure would
     capture and return error to UI */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Get LPN info to fill the form */
  exec pr_AMF_Info_GetLPNInfoXML @vLPNId, 'N' /* LPNDetails */, 'VASComplete', @vLPNInfoXML output;

  /* Create a temp table if not exists to insert values into it */
  if object_id('tempdb..#LPNDetails') is null
    create table #LPNDetails(SKUId          int,
                             SKU            varchar(50),
                             Description    varchar(120),
                             Quantity       int,
                             LPNDetailId    int,
                             OrderDetailId  int,
                             LPNId          int,
                             SortSeq        smallint)

  /* Fetch the SKU and LPN related information */
  insert into #LPNDetails (SKUId, SKU, Description, Quantity, LPNDetailId, OrderDetailId, LPNId, SortSeq)
    select S.SKUId, S.SKU, S.Description, LD.Quantity, LD.LPNDetailId, LD.OrderDetailId, LD.LPNId, 1 as SortSeq
    from LPNDetails LD join SKUs S on LD.SKUId = S.SKUId
    where (LPNId = @vLPNId);

  /* Get order details */
  select OD.*
  into #OrderDetails
  from LPNDetails LD join OrderDetails OD on LD.OrderDetailId = OD.OrderDetailId
  where (LD.LPNId = @vLPNId);

  /* Insert UDF4 value */
  insert into #LPNDetails (Description, SortSeq, LPNId, LPNDetailId)
    select OD.UDF4, 2, LD.LPNId, LD.LPNDetailId
    from #LPNDetails LD join #OrderDetails OD on LD.OrderDetailId = OD.OrderDetailId

  /* Insert UDF6 value */
  insert into #LPNDetails (Description, SortSeq, LPNId, LPNDetailId)
    select OD.UDF6, 3, LD.LPNId,LD.LPNDetailId
    from #LPNDetails LD join #OrderDetails OD on LD.OrderDetailId = OD.OrderDetailId and LD.SortSeq = 1

  /* Build LPNDetails xml */
  select @vxmlLPNDetails = (select *
                            from #LPNDetails
                            where (LPNId = @vLPNId)
                            order by LPNDetailId, SortSeq, SKU
                            for XML Raw('LPNDetail'), elements XSINIL, Root('LPNDETAILS'));

  select @DataXML = (select PickTicket, SalesOrder,
                            ShipFromName, ShipFromAddressLine1, ShipFromAddressLine2, ShipFromCityStateZip,
                            SoldToCustomerName, SoldToAddressLine1, SoldToAddressLine2, SoldToCityStateZip,
                            ShipToCustomerName, ShipToAddressLine1, ShipToAddressLine2, ShipToCityStateZip,
                            OH_UDF2, OH_UDF3, SoldToId, Comments
                     from vwPackingListHeaders
                     where (OrderId = @vLPNOrderId)
                     for Xml Raw(''), elements, Root('Data'));

  select @DataXml = dbo.fn_XmlAddNode(@DataXML, 'Data', @vLPNInfoXML + convert(varchar(max), @vxmlLPNDetails));

end /* pr_AMF_Inquiry_VAS */

Go

