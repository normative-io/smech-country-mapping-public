#!/usr/bin/env bash
# Copyright 2022 Meta Mind AB
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


cd "$(dirname "$0")/.."

mkdir -p output

> output/iso-countries.json sqlite3 data/mapping.db < scripts/generate-iso-country-table-json.sql

> output/countries.ts cat << EOL
/**
  Generated by:
  https://github.com/normative-io/smech-country-mapping/blob/develop/scripts/generate-client-mapping.sh

  Country data table used to map SMECH country names to ISO alpha-2 codes and for the list of countries
  in the country selector.
**/

export interface IsoCountryInfo {
  iso_name: string;
  iso_alpha2: string;
};

EOL

{
  echo 'export const ISO_COUNTRIES: IsoCountryInfo[] = ('
  sqlite3 data/mapping.db < scripts/generate-iso-country-table-json.sql
  echo ');'
} >> output/countries.ts

{
  echo ''
  echo 'export const SMECH_COUNTRY_NAME_TO_ALPHA2: { [key: string]: string } = ('
  sqlite3 data/mapping.db <<EOQ
select
  json_group_object(smech_name, alpha2)
  as json_result
from allcountries
where smech_name is not null;
EOQ
  echo ');'
  echo ''
} >> output/countries.ts

npx prettier --print-width 120 --single-quote --quote-props consistent -w \
  output/countries.ts output/iso-countries.json
