/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/15  MS      Corrections as per New Format (CIMSV3-1210)
  2014/04/16  TK      Changes made to control data using procedure
  2010/09/20  PK      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* States */
/*------------------------------------------------------------------------------*/
declare @States TLookUpsTable, @LookUpCategory TCategory = 'State';

insert into @States
       (LookUpCode,  LookUpDescription,                   Status)
values ('AL',        'Alabama',                           'A'),
       ('AK',        'Alaska ',                           'A'),
       ('AZ',        'Arizona',                           'A'),
       ('AR',        'Arkansas',                          'A'),
       ('CA',        'California',                        'A'),
       ('CO',        'Colorado',                          'A'),
       ('CT',        'Connecticut',                       'A'),
       ('DE',        'Delaware',                          'A'),
       ('DC',        'District of Columbia',              'A'),
       ('FL',        'Florida',                           'A'),
       ('GA',        'Georgia',                           'A'),
       ('HI',        'Hawaii',                            'A'),
       ('ID',        'Idaho',                             'A'),
       ('IL',        'Illinois',                          'A'),
       ('IN',        'Indiana',                           'A'),
       ('IA',        'Iowa',                              'A'),
       ('KS',        'Kansas',                            'A'),
       ('KY',        'Kentucky',                          'A'),
       ('LA',        'Louisiana',                         'A'),
       ('ME',        'Maine',                             'A'),
       ('MD',        'Maryland',                          'A'),
       ('MA',        'Massachusetts',                     'A'),
       ('MI',        'Michigan',                          'A'),
       ('MN',        'Minnesota',                         'A'),
       ('MS',        'Mississippi',                       'A'),
       ('MO',        'Missouri',                          'A'),
       ('MT',        'Montana',                           'A'),
       ('NE',        'Nebraska',                          'A'),
       ('NV',        'Nevada',                            'A'),
       ('NH',        'New Hampshire',                     'A'),
       ('NJ',        'New Jersey',                        'A'),
       ('NM',        'New Mexico',                        'A'),
       ('NY',        'New York',                          'A'),
       ('NC',        'North Carolina',                    'A'),
       ('ND',        'North Dakota',                      'A'),
       ('OH',        'Ohio',                              'A'),
       ('OK',        'Oklahoma',                          'A'),
       ('OR',        'Oregon',                            'A'),
       ('PA',        'Pennsylvania',                      'A'),
       ('RI',        'Rhode Island',                      'A'),
       ('SC',        'South Carolina',                    'A'),
       ('SD',        'South Dakota',                      'A'),
       ('TN',        'Tennessee',                         'A'),
       ('TX',        'Texas',                             'A'),
       ('UT',        'Utah',                              'A'),
       ('VT',        'Vermont',                           'A'),
       ('VA',        'Virgina',                           'A'),
       ('WA',        'Washington',                        'A'),
       ('WV',        'West Virginia',                     'A'),
       ('WI',        'Wisconsin',                         'A'),
       ('WY',        'Wyoming',                           'A'),
       ('AA',        'Armed Forces Americas',             'A'),
       ('AE',        'Armed Forces Europe',               'A'),
       ('AP',        'Armed Forces Pacific',              'A'),
       ('AS',        'American Samoa',                    'A'),
       ('FM',        'Federated States of Micronesia',    'A'),
       ('GU',        'Guam',                              'A'),
       ('MH',        'Marshall Islands',                  'A'),
       ('MP',        'Northern Mariana Islands',          'A'),
       ('PW',        'Palau',                             'A'),
       ('PR',        'Puerto Rico',                       'A'),
       ('VI',        'Virgin Islands',                    'A'),
/* Canada */
       ('AB',        'Alberta',                           'A'),
       ('BC',        'British Columbia',                  'A'),
       ('MB',        'Manitoba',                          'A'),
       ('NB',        'New Brunswick',                     'A'),
       ('NF',        'Newfoundland',                      'A'),
       ('NT',        'Northwest Territory',               'A'),
       ('NS',        'Nova Scotia',                       'A'),
       ('NU',        'Nunavut',                           'A'),
       ('PE',        'Prince Edward Island',              'A'),
       ('ON',        'Ontario',                           'A'),
       ('QC',        'Quebec',                            'A'),
       ('SK',        'Saskatchewan',                      'A'),
       ('YT',        'Yukon',                             'A')

exec pr_LookUps_Setup @LookUpCategory, @States, @LookUpCategoryDesc = 'State';

Go
