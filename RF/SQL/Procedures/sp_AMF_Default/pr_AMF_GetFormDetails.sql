/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/01  RIA     pr_AMF_SubstituteDBDataLookUps: Added and made changes to pr_AMF_GetFormDetails (HA-2517)
  2021/03/03  RIA     pr_AMF_SubstituteDBDataSet: Added and made changes to pr_AMF_GetFormDetails (HA-2113)
  2019/04/01  NB      Modified pr_AMF_GetFormDetails to consider AlternateCategory forms when there
  2019/01/31  NB      pr_AMF_GetFormDetails modified to read DeviceCategory specific form html(CIMSV3-331)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_GetFormDetails') is not null
  drop Procedure pr_AMF_GetFormDetails;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_GetFormDetails:

  Processes the input request, retrieves the Html for the request Form, replaces
  the Caption Place Holders in the HTML with their respective Field Captions, considering
  the culturename defined for the User
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_GetFormDetails
  (@InputXML     TXML)
as
  declare @vInputXML           xml,
          @vFormId             TRecordId,
          @vFormName           TName,
          @vFormHtml           TVarchar,
          @vFormDisplayCaption TName,
          @vUserName           TName,
          @vBusinessUnit       TBusinessUnit,
          @vDeviceId           TDeviceId,
          @vCultureName        TName,
          @vDeviceCategory     TName,
          @vAlternateCategory  TName;

begin
    /* Extracting data elements from XML. */
  set @vInputXML = convert(xml, @InputXML);

  select @vFormName = Record.Col.value('FormName[1]', 'TName')
  from @vInputXML.nodes('/Root/Data') as Record(Col)
  OPTION (OPTIMIZE FOR (@vInputXML = null));

  select @vUserName       = Record.Col.value('UserName[1]',      'TUserId'),
         @vDeviceId       = Record.Col.value('DeviceId[1]',      'TDeviceId'),
         @vBusinessUnit   = Record.Col.value('BusinessUnit[1]',  'TBusinessUnit'),
         @vDeviceCategory = Record.Col.value('DeviceCategory[1]','TName')
  from @vInputXML.nodes('/Root/SessionInfo') as Record(Col)
  OPTION (OPTIMIZE FOR (@vInputXML = null));

  /* Capture Device specific information from devices table and search for relevant form
     There could be device specific forms */
  select Top 1
         @vFormId             = RecordId,
         @vFormDisplayCaption = DisplayCaption,
         @vFormHtml           = RawHtml
  from AMF_Forms
  where (FormName       = @vFormName    ) and
        (Status         = 'A' /* Active */) and
        (DeviceCategory = @vDeviceCategory) and
        (BusinessUnit   = @vBusinessUnit)
  order by Version Desc;

  /* If form HTML is null, then verify whether the DeviceCategory is defined with Alternate */
  if (@vFormHtml is null)
    begin
      select Top 1
             @vFormId             = RecordId,
             @vFormDisplayCaption = DisplayCaption,
             @vFormHtml           = RawHtml
      from AMF_Forms
      where (FormName       = @vFormName    ) and
            (Status         = 'A' /* Active */) and
            (DeviceCategory = (select AlternateCategory from AMF_DeviceCategories where (CategoryName = @vDeviceCategory))) and
            (BusinessUnit   = @vBusinessUnit)
      order by Version Desc;
    end

  /* If there is no device category specific form, then read the Standard version */
  if (@vFormHtml is null)
    begin
      select Top 1
             @vFormId             = RecordId,
             @vFormDisplayCaption = DisplayCaption,
             @vFormHtml           = RawHtml
      from AMF_Forms
      where (FormName       = @vFormName    ) and
            (Status         = 'A' /* Active */) and
            (DeviceCategory = 'STD') and
            (BusinessUnit   = @vBusinessUnit)
      order by Version Desc;

    end

  select @vCultureName = CultureName
  from Users
  where (UserName = @vUserName) and (BusinessUnit = @vBusinessUnit);

  select @vCultureName = coalesce(@vCultureName, 'en-US' /* english US */);
  select @vFormHtml = dbo.fn_AMF_SubstituteCaptions(@vFormHtml, @vCultureName, @vBusinessUnit);

  /* Substitute and data sets in the form */
  if (charindex('DBDATASET', @vFormHtml) > 0)
    exec pr_AMF_SubstituteDBDataSet @vFormHtml, @vInputXML, @vFormHtml output;

  /* Substitute and data sets in the form */
  if (charindex('DBDATALOOKUPS', @vFormHtml) > 0)
    exec pr_AMF_SubstituteDBDataLookUps @vFormHtml, @vInputXML, @vFormHtml output;

  select @vFormId FormId, coalesce(@vFormDisplayCaption, @vFormName) FormTitle, @vFormHtml RawHtml;
end /* pr_AMF_GetFormDetails */

Go

