/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/09  RIA     pr_AMF_BuildLookUpList: Changes to consider LookUpCode instead of SortSeq (HA-GoLive)
  2021/01/06  RIA     pr_AMF_BuildLookUpList: Changes to fetch the list in order of LookUp codes (HA-1839)
  2020/07/29  RIA     pr_AMF_BuildLookUpList: Changes to default reason code value (HA-652)
  2020/01/07  RIA     pr_AMF_BuildLookUpList: Changes to accept default prompt (CIMSV3-655)
  2019/10/14  RIA     Included more nodes and minor corrections to pr_AMF_BuildLookUpList (CIMSV3-624)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_BuildLookUpList') is not null
  drop Procedure pr_AMF_BuildLookUpList;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_BuildLookUpList: Accepts LookUpCategory, RootNode, DefaultPrompt,
    BusinessUnit and returns the list of lookup codes/descriptions.

  output:

  <LookupCodes>
    <LookupCodeDetail>
      <LookUpDisplayDescription>411-A/R Adj-Reserve</LookUpDisplayDescription>
      <LookUpCode>411</LookUpCode>
    </LookupCodeDetail>
    <LookupCodeDetail>
      <LookUpDisplayDescription>504-Bundle Build</LookUpDisplayDescription>
      <LookUpCode>504</LookUpCode>
    </LookupCodeDetail>
    <LookupCodeDetail>
      <LookUpDisplayDescription>202-Cannot find Units</LookUpDisplayDescription>
      <LookUpCode>202</LookUpCode>
    </LookupCodeDetail>
           ....
           ....
    <LookupCodeDetail>
      <LookUpDisplayDescription>506-Concealed Damage</LookUpDisplayDescription>
      <LookUpCode>506</LookUpCode>
    </LookupCodeDetail>
  </LookupCodes>

------------------------------------------------------------------------------*/
Create Procedure pr_AMF_BuildLookUpList
  (@LookUpCategory      TCategory,
   @RootNode            TDescription,
   @DefaultPrompt       TDescription,
   @BusinessUnit        TBusinessUnit,
   @outputXML           TXML        = null output)
as
  declare @vxmlLookupCodes    xml,
          @vLookupCodesXML    TXML,
          @vFirstNode         TXML;
begin /* pr_AMF_BuildLookupCodes */
  /* The first node is to prompt user to select a reason and to validate if the
     user has selected a reason */
  select @vFirstNode = dbo.fn_XMLNode('LookupDetail',
                         dbo.fn_XMLNode('LookUpDisplayDescription',  coalesce(@DefaultPrompt, 'select a reason')) +
                         dbo.fn_XMLNode('LookUpCode',                '*'));

  /* Fetch the Lookup Description and codes for passed in LookUpCategory and BusinessUnit */
  select @vxmlLookupCodes = (select LookUpDisplayDescription, LookUpCode
                             from vwLookUps
                             where (LookUpCategory = @LookUpCategory) and
                                   (BusinessUnit   = @BusinessUnit) and
                                   (Status         = 'A')
                             order by LookUpCode
                             for XML Raw('LookupDetail'), elements);

  /* Convert to varchar */
  select @vLookupCodesXML = coalesce(convert(varchar(max), @vxmlLookupCodes), '');

  select @outputXML = dbo.fn_XMLNode(@RootNode, @vFirstNode + @vLookupCodesXML);
end /* pr_AMF_BuildLookUpList */

Go

