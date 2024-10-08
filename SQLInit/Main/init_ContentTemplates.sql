/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/08/29  PK      Updated the content to display hardcoded value for packagetype,
                        displaying the weight description.(HPI-457).
  2016/08/19  DK      Initial revision(HPI-457)
------------------------------------------------------------------------------*/
Go
delete from ContentTemplates;

  declare  @vTemplateDetail  varchar(max);

select @vTemplateDetail = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title></title>
</head>
<body>
    <div>
        <table cellpadding="0" cellspacing="0">
            <tr>
                <td style="width: 800px; border: 1px #DCDCDC solid">
                    <div>
                        <img alt="CIMS" src="https://cloudimsystems.com/dev/wp-content/uploads/2018/07/cims-logo-color.jpg" />
                        <br />
                        <br />
                        <br />
                        <div width="600px" align="left">
                            <table width="600px">
                                <tr>
                                    <td width="300px">
                                        <table>
                                            <tr>
                                                <td>
                                                    <label>
                                                        Ship Date:
                                                    </label>
                                                </td>
                                                <td>
                                                    <label>
                                                        ~SHIPDATE~
                                                    </label>
                                                </td>
                                            </tr>
                                        </table>
                                    </td>
                                    <td width="300px">
                                    </td>
                                </tr>
                                <tr>
                                    <td>
                                        <hr width="120px" align="left" />
                                    </td>
                                    <td>
                                        <hr width="120px" align="left" />
                                    </td>
                                </tr>
                                <tr>
                                    <td>
                                        <b>From</b>
                                    </td>
                                    <td>
                                        <b>To</b>
                                    </td>
                                </tr>
                                <tr>
                                    <td valign="top">
                                        <label>
                                            ~SHIPFROMADDRESSDISPLAY~</label>
                                    </td>
                                    <td valign="top">
                                        <label>
                                            ~SHIPTOADDRESSDISPLAY~</label>
                                    </td>
                                </tr>
                                <tr>
                                <td>&nbsp;</td>
                                </tr>
                                <tr>
                                    <td width="200px">
                                        <label>
                                            Tracking Number(s):</label>
                                    </td>
                                    <td width="200px">
                                        <label>
                                            ~TRACKINGNO~</label>
                                    </td>
                                </tr>
                                <tr>
                                <td>&nbsp;</td>
                                </tr>
                            </table>
                            <table width="600Px">
                                <thead>
                                    <tr>
                                        <th align="left" colspan="2">
                                            Shipment Facts
                                        </th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr>
                                        <td>
                                            <label>
                                                Purchase order number:</label>
                                        </td>
                                        <td>
                                            <label>
                                                ~CUSTPO~</label>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td>
                                            <label>
                                                Reference:</label>
                                        </td>
                                        <td>
                                            <label>
                                                ~SALESORDER~</label>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td>
                                            <label>
                                                Service type:</label>
                                        </td>
                                        <td>
                                            <label>
                                                ~SHIPVIADESCRIPTION~</label>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td>
                                            <label>
                                                Packaging type:</label>
                                        </td>
                                        <td>
                                            <label>
                                                Package</label>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td>
                                            <label>
                                                Number of pieces:</label>
                                        </td>
                                        <td>
                                            <label>
                                                ~NUMUNITS~</label>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td>
                                            <label>
                                                Weight:</label>
                                        </td>
                                        <td>
                                            <label>
                                                ~TotalWeightDesc~</label>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </td>
            </tr>
        </table>
        <br />
    </div>
</body>
</html>';

insert into ContentTemplates
            (TemplateName,       TemplateType, TemplateDetail,   Category, SubCategory, BusinessUnit)
      select 'ShipConfirmation', 'HTML',       @vTemplateDetail, 'Orders', 'ShipConfirmation', BusinessUnit from vwBusinessUnits;

Go
