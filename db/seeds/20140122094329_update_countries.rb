#add country

["Afghanistan", "Albania", "Algeria", "Andorra", "Angola",
  "Antigua & Deps", "Argentina", "Armenia", "Australia",
  "Austria", "Azerbaijan", "Bahamas", "Bahrain", "Bangladesh",
  "Barbados", "Belarus", "Belgium", "Belize", "Benin", "Bhutan",
  "Bolivia", "Bosnia Herzegovina", "Botswana", "Brazil", "Brunei",
  "Bulgaria", "Burkina", "Burma", "Burundi", "Caicos", "Cambodia",
  "Cameroon", "Canada", "Cape Verde", "Central African Rep", "Chad",
  "Chile", "China", "Colombia", "Comoros", "Congo", "Congo {Democratic Rep}",
  "Cook Islands", "Costa Rica", "Croatia", "Cuba", "Cyprus", "Czech Republic",
  "Côte d'Ivoire", "Democratic People's Republic of Korea",
  "Democratic Republic of the Congo", "Denmark", "Djibouti",
  "Dominica", "Dominican Republic", "East Timor", "Ecuador", "Egypt",
  "El Salvador", "Equatorial Guinea", "Eritrea", "Estonia", "Ethiopia",
  "Federation of Saint Kitts and Nevis", "Fiji", "Finland", "France",
  "Gabon", "Gambia", "Georgia", "Germany", "Ghana", "Greece", "Grenada",
  "Guatemala", "Guinea", "Guinea-Bissau", "Guyana", "Haiti", "Honduras",
  "Hungary", "Iceland", "India", "Indonesia", "Iran", "Iraq", "Ireland {Republic}",
  "Israel", "Italy", "Ivory Coast", "Jamaica", "Japan", "Jordan", "Kazakhstan",
  "Kenya", "Kiribati", "Korea North", "Korea South", "Kosovo", "Kuwait", "Kyrgyzstan",
  "Laos", "Latvia", "Lebanon", "Lesotho", "Liberia", "Libya", "Liechtenstein",
  "Lithuania", "Luxembourg", "Macedonia", "Madagascar", "Malawi", "Malaysia",
  "Maldives", "Mali", "Malta", "Marshall Islands", "Mauritania", "Mauritius", "Mexico",
  "Micronesia", "Moldova", "Monaco", "Mongolia", "Montenegro", "Morocco", "Mozambique",
  "Myanmar, {Burma}", "Nagorno-Karabakh", "Namibia", "Nauru", "Nepal", "Netherlands",
  "New Zealand", "Nicaragua", "Niger", "Nigeria", "Norway", "Oman", "Pakistan", "Palau",
  "Palestine", "Panama", "Papua New Guinea", "Paraguay", "Peru", "Philippines", "Poland",
  "Portugal", "Qatar", "Republic of Korea", "Republic of the Congo", "Romania",
  "Russian Federation", "Rwanda", "Sahrawi Arab Democratic Republic", "Saint Lucia",
  "Saint Vincent & the Grenadines", "Samoa", "San Marino", "Sao Tome & Principe",
  "Saudi Arabia", "Senegal", "Serbia", "Seychelles", "Sierra Leone", "Singapore",
  "Slovakia", "Slovenia", "Solomon Islands", "Somalia", "South Africa", "Spain",
  "Sri Lanka", "St Kitts & Nevis", "St Lucia", "Sudan", "Sudan, South", "Suriname",
  "Swaziland", "Sweden", "Switzerland", "Syria", "Taiwan", "Tajikistan", "Tanzania",
  "Thailand", "Timor-Leste", "Togo", "Tonga", "Transnistria", "Trinidad & Tobago",
  "Tunisia", "Turkey", "Turkmenistan", "Turks", "Tuvalu", "Uganda", "Ukraine",
  "United Arab Emirates", "United Kingdom", "United States", "Uruguay", "Uzbekistan",
  "Vanuatu", "Vatican City", "Venezuela", "Vietnam", "Yemen", "Zambia", "Zimbabwe"].each do |param|
  Country.find_or_create_by_name(param)
end

countries_diff={"Ascension Island"=>nil, "Senegal (Sénégal)"=>"Senegal", "Vatican City (Città del Vaticano)"=>"Vatican City", "Guinea-Bissau (Guiné Bissau)"=>"Guinea-Bissau",
  "Qatar (‫قطر‬‎)"=>"Qatar", "Ukraine (Україна)"=>"Ukraine", "Uganda"=>"Uganda", "Eritrea"=>"Eritrea", "Norway (Norge)"=>"Norway", "Russia (Россия)"=>"Russian Federation",
  "São Tomé and Príncipe (São Tomé e Príncipe)"=>"Sao Tome & Principe", "South Africa"=>"South Africa", "Fiji"=>"Fiji", "Belarus (Беларусь)"=>"Belarus",
  "Saint Kitts and Nevis"=>"Federation of Saint Kitts and Nevis", "Guernsey"=>nil, "Puerto Rico"=>nil, "Mexico (México)"=>"Mexico", "South Korea (대한민국)"=>"Korea South",
  "Burkina Faso"=>"Burkina", "Seychelles"=>"Seychelles", "Belgium (België)"=>"Belgium", "Wallis and Futuna"=>nil, "Syria (‫سوريا‬‎)"=>"Syria",
  "Congo [Republic] (Congo-Brazzaville)"=>"Republic of the Congo", "Solomon Islands"=>"Solomon Islands", "Saint Barthélemy (Saint-Barthélémy)"=>nil, "Chile"=>"Chile",
  "Malaysia"=>"Malaysia", "United States"=>"United States", "Saint Pierre and Miquelon (Saint-Pierre-et-Miquelon)"=>nil, "Barbados"=>"Barbados",
  "Cape Verde (Kabu Verdi)"=>"Cape Verde", "Morocco (‫المغرب‬‎)"=>"Morocco", "Gibraltar"=>nil, "Georgia (საქართველო)"=>"Georgia", "New Zealand"=>"New Zealand",
  "Svalbard and Jan Mayen (Svalbard og Jan Mayen)"=>nil, "Slovenia (Slovenija)"=>"Slovenia", "Lebanon (‫لبنان‬‎)"=>"Lebanon", "Yemen (‫اليمن‬‎)"=>"Yemen", "Australia"=>"Australia",
  "Åland Islands (Åland)"=>nil, "Dominican Republic (República Dominicana)"=>"Dominican Republic", "Germany (Deutschland)"=>"Germany", "Martinique"=>nil,
  "British Indian Ocean Territory"=>nil, "Japan (日本)"=>"Japan", "Tanzania"=>"Tanzania", "Romania (România)"=>"Romania",
  "Equatorial Guinea (Guinea Ecuatorial)"=>"Equatorial Guinea", "Central African Republic (République centrafricaine)"=>"Central African Rep",
  "Azerbaijan (Azərbaycan)"=>"Azerbaijan", "Luxembourg"=>"Luxembourg", "Belize"=>"Belize", "Antarctica"=>nil, "Côte d’Ivoire"=>"Côte d'Ivoire", "Libya (‫ليبيا‬‎)"=>"Libya",
  "United Kingdom"=>"United Kingdom", "Mongolia (Монгол)"=>"Mongolia", "Switzerland (Schweiz)"=>"Switzerland", "Nauru"=>"Nauru", "Haiti"=>"Haiti", "Taiwan (台灣)"=>"Taiwan",
  "Saint Lucia"=>"Saint Lucia", "Zimbabwe"=>"Zimbabwe", "United Arab Emirates (‫الإمارات العربية المتحدة‬‎)"=>"United Arab Emirates", "Timor-Leste"=>"Timor-Leste", "Vanuatu"=>"Vanuatu",
  "Greece (Ελλάδα)"=>"Greece", "Palau"=>"Palau", "San Marino"=>"San Marino", "Poland (Polska)"=>"Poland", "Mayotte"=>nil, "Angola"=>"Angola", "Estonia (Eesti)"=>"Estonia",
  "Togo"=>"Togo", "Bangladesh (বাংলাদেশ)"=>"Bangladesh", "El Salvador"=>"El Salvador", "Sweden (Sverige)"=>"Sweden", "Uruguay"=>"Uruguay", "Cayman Islands"=>nil,
  "Spain (España)"=>"Spain", "Ceuta and Melilla (Ceuta y Melilla)"=>nil, "Honduras"=>"Honduras", "Saint Martin (Saint-Martin [partie française])"=>nil, "Laos (ສ.ປ.ປ ລາວ)"=>"Laos",
  "Bosnia and Herzegovina (Босна и Херцеговина)"=>"Bosnia Herzegovina", "Cyprus (Κύπρος)"=>"Cyprus", "Jamaica"=>"Jamaica", "Macedonia [FYROM] (Македонија)"=>"Macedonia",
  "Uzbekistan (Ўзбекистон)"=>"Uzbekistan", "Albania (Shqipëria)"=>"Albania", "Niue"=>nil, "Botswana"=>"Botswana", "Singapore"=>"Singapore", "Gambia"=>"Gambia",
  "Kiribati"=>"Kiribati", "Swaziland"=>"Swaziland", "North Korea (조선 민주주의 인민 공화국)"=>"Democratic People's Republic of Korea",
  "Congo [DRC] (Jamhuri ya Kidemokrasia ya Kongo)"=>"Democratic Republic of the Congo", "American Samoa"=>nil, "U.S. Virgin Islands"=>nil,
  "Paraguay"=>"Paraguay", "Isle of Man"=>nil, "Benin (Bénin)"=>"Benin", "Trinidad and Tobago"=>"Trinidad & Tobago", "Bahamas"=>"Bahamas", "Thailand (ไทย)"=>"Thailand",
  "Papua New Guinea"=>"Papua New Guinea", "Netherlands (Nederland)"=>nil, "Caribbean Netherlands"=>"Netherlands", "Malawi"=>"Malawi", "Heard Island and McDonald Islands"=>nil,
  "Macau (澳門)"=>nil, "Micronesia"=>"Micronesia", "Maldives"=>"Maldives", "U.S. Outlying Islands"=>nil, "Iceland (Ísland)"=>"Iceland", "Monaco"=>"Monaco", "Bermuda"=>nil,
  "Tonga"=>"Tonga", "Kyrgyzstan"=>"Kyrgyzstan", "Vietnam (Việt Nam)"=>"Vietnam", "Guadeloupe"=>nil, "Italy (Italia)"=>"Italy", "Liechtenstein"=>"Liechtenstein",
  "British Virgin Islands"=>nil, "Guinea (Guinée)"=>"Guinea", "Faroe Islands (Føroyar)"=>nil, "Diego Garcia"=>nil, "Costa Rica"=>"Costa Rica", "Bhutan (འབྲུག)"=>"Bhutan",
  "China (中国)"=>"China", "Greenland (Kalaallit Nunaat)"=>nil, "Cambodia (កម្ពុជា)"=>"Cambodia", "Denmark (Danmark)"=>"Denmark", "Guatemala"=>"Guatemala", "India (भारत)"=>"India",
  "Tristan da Cunha"=>nil, "New Caledonia (Nouvelle-Calédonie)"=>nil, "Sierra Leone"=>"Sierra Leone", "Portugal"=>"Portugal", "Tuvalu"=>"Tuvalu", "Nicaragua"=>"Nicaragua",
  "France"=>"France", "Djibouti"=>"Djibouti", "Turks and Caicos Islands"=>"Caicos", "Saudi Arabia (‫المملكة العربية السعودية‬‎)"=>"Saudi Arabia", "Bolivia"=>"Bolivia",
  "Venezuela"=>"Venezuela", "Bahrain (‫البحرين‬‎)"=>"Bahrain", "French Polynesia (Polynésie française)"=>nil, "Czech Republic (Česká republika)"=>"Czech Republic",
  "French Southern Territories (Terres australes françaises)"=>nil, "Argentina"=>"Argentina", "Antigua and Barbuda"=>"Antigua & Deps", "Kazakhstan (Казахстан)"=>"Kazakhstan",
  "Saint Vincent and the Grenadines"=>"Saint Vincent & the Grenadines", "Cuba"=>"Cuba", "Kuwait (‫الكويت‬‎)"=>"Kuwait", "Ethiopia"=>"Ethiopia", "Mauritania (‫موريتانيا‬‎)"=>"Mauritania",
  "Montenegro (Crna Gora)"=>"Montenegro", "Suriname"=>"Suriname", "Algeria (‫الجزائر‬‎)"=>"Algeria", "Mauritius (Moris)"=>"Mauritius", "Afghanistan (‫افغانستان‬‎)"=>"Afghanistan",
  "Brazil (Brasil)"=>"Brazil", "Latvia (Latvija)"=>"Latvia", "Canary Islands (Islas Canarias)"=>nil, "Clipperton Island (Île Clipperton)"=>nil, "Armenia (Հայաստան)"=>"Armenia",
  "Palestine (‫فلسطين‬‎)"=>"Palestine", "Tokelau"=>nil, "Lesotho"=>"Lesotho", "Burundi (Uburundi)"=>"Burundi", "Pakistan (‫پاکستان‬‎)"=>"Pakistan", "Serbia (Србија)"=>"Serbia",
  "Ecuador"=>"Ecuador", "Réunion"=>nil, "Iran (‫ایران‬‎)"=>"Iran", "Malta"=>"Malta", "South Georgia and the South Sandwich Islands"=>nil, "Norfolk Island"=>nil,
  "Tunisia (‫تونس‬‎)"=>"Tunisia", "Anguilla"=>nil, "Lithuania (Lietuva)"=>"Lithuania", "Nigeria"=>"Nigeria", "Guam"=>nil, "Andorra"=>"Andorra", "Egypt (‫مصر‬‎)"=>"Egypt",
  "Guyana"=>"Guyana", "Jersey"=>nil, "Ghana (Gaana)"=>"Ghana", "Marshall Islands"=>"Marshall Islands", "Mali"=>"Mali", "Peru (Perú)"=>"Peru", "Sint Maarten"=>nil,
  "Western Sahara (‫الصحراء الغربية‬‎)"=>"Sahrawi Arab Democratic Republic", "Indonesia"=>"Indonesia", "Liberia"=>"Liberia", "Jordan (‫الأردن‬‎)"=>"Jordan",
  "Austria (Österreich)"=>"Austria", "Comoros (‫جزر القمر‬‎)"=>"Comoros", "Falkland Islands [Islas Malvinas]"=>nil, "Pitcairn Islands"=>nil, "Saint Helena"=>nil,
  "Aruba"=>nil, "Canada"=>"Canada", "Turkey (Türkiye)"=>"Turkey", "Grenada"=>"Grenada", "Croatia (Hrvatska)"=>"Croatia", "Kenya"=>"Kenya", "Israel (‫ישראל‬‎)"=>"Israel",
  "Hungary (Magyarország)"=>"Hungary", "Namibia"=>"Namibia", "Sudan (‫السودان‬‎)"=>"Sudan", "French Guiana (Guyane française)"=>nil, "Cocos [Keeling] Islands"=>nil,
  "Montserrat"=>nil, "Northern Mariana Islands"=>nil, "Bulgaria (България)"=>"Bulgaria", "Brunei"=>"Brunei", "Ireland"=>"Ireland {Republic}", "Chad (Tchad)"=>"Chad",
  "Rwanda"=>"Rwanda", "Moldova (Republica Moldova)"=>"Moldova", "South Sudan (‫جنوب السودان‬‎)"=>"Sudan, South", "Bouvet Island"=>nil, "Myanmar [Burma] (မြန်မာ)"=>"Burma",
  "Niger (Nijar)"=>"Niger", "Cameroon (Cameroun)"=>"Cameroon", "Sri Lanka (ශ්‍රී ලංකාව)"=>"Sri Lanka", "Turkmenistan"=>"Turkmenistan", "Cook Islands"=>"Cook Islands",
  "Colombia"=>"Colombia", "Mozambique (Moçambique)"=>"Mozambique", "Iraq (‫العراق‬‎)"=>"Iraq", "Somalia (Soomaaliya)"=>"Somalia", "Christmas Island"=>nil,
  "Hong Kong (香港)"=>nil, "Kosovo (Косово)"=>"Kosovo", "Zambia"=>"Zambia", "Panama (Panamá)"=>"Panama", "Dominica"=>"Dominica", "Curaçao"=>nil, "Oman (‫عُمان‬‎)"=>"Oman",
  "Slovakia (Slovensko)"=>"Slovakia", "Tajikistan"=>"Tajikistan", "Gabon"=>"Gabon", "Finland (Suomi)"=>"Finland", "Samoa"=>"Samoa", "Nepal (नेपाल)"=>"Nepal",
  "Philippines"=>"Philippines", "Madagascar (Madagasikara)"=>"Madagascar"}

countries_diff.each do |new,old|
  next if old == new
  unless old
    Country.find_or_create_by_name(new)
  else
    country = Country.find_by_name(old)
    country.update_attribute(:name,new) if country
  end
end

columns_to_be_updated = {"guardians"=>["country_id"], "archived_guardians"=>["country_id"], "archived_employees"=>["nationality_id", "home_country_id", "office_country_id"],
  "archived_students"=>["nationality_id", "country_id"], "students"=>["nationality_id", "country_id"], "applicant_guardians"=>["country_id"],
  "employees"=>["nationality_id", "home_country_id", "office_country_id"], "applicants"=>["nationality_id", "country_id"]}

{"Congo [Republic] (Congo-Brazzaville)"=>"Congo", "Congo [DRC] (Jamhuri ya Kidemokrasia ya Kongo)"=>"Congo {Democratic Rep}", "Timor-Leste"=>"East Timor",
  "Côte d’Ivoire"=>"Ivory Coast", "North Korea (조선 민주주의 인민 공화국)"=>"Korea North", "Myanmar [Burma] (မြန်မာ)"=>"Myanmar, {Burma}", "Nagorno-Karabakh"=>nil,
  "South Korea (대한민국)"=>"Republic of Korea", "Saint Kitts and Nevis"=>"St Kitts & Nevis", "Saint Lucia"=>"St Lucia", "Transnistria"=> nil, "Turks and Caicos Islands"=>"Turks"
}.each do |replaced,deletable|

  replaced_country = Country.find_by_name(replaced)
  deletable_country = Country.find_by_name(deletable)

  if replaced_country && deletable_country
    columns_to_be_updated.each do |table,columns|
      columns.each do |column|
        sqlquery = "UPDATE `#{table}` SET `#{column}` = #{replaced_country.id} WHERE `#{column}` = #{deletable_country.id} ;"
        ActiveRecord::Base.connection.execute(sqlquery)
      end if ActiveRecord::Base.connection.tables.include? table
    end

    sqlquery = "UPDATE `configurations` SET `config_value` = #{replaced_country.id} WHERE `config_value` = '#{deletable_country.id}' and `config_key` = 'DefaultCountry' ;"
    ActiveRecord::Base.connection.execute(sqlquery)

  end

  deletable_country.delete if deletable_country

end

old_ivory = Country.find(:first,:conditions=>"name like '%ivoire%' and name not like 'Côte%'")
new_ivory = Country.find(:first,:conditions=>"name like 'Côte%'")

if new_ivory && old_ivory
  columns_to_be_updated.each do |table,columns|
    columns.each do |column|
      sqlquery = "UPDATE `#{table}` SET `#{column}` = #{new_ivory.id} WHERE `#{column}` = #{old_ivory.id} ;"
      ActiveRecord::Base.connection.execute(sqlquery)
    end if ActiveRecord::Base.connection.tables.include? table
  end

  sqlquery = "UPDATE `configurations` SET `config_value` = #{new_ivory.id} WHERE `config_value` = '#{old_ivory.id}' and `config_key` = 'DefaultCountry' ;"
  ActiveRecord::Base.connection.execute(sqlquery)

end

old_ivory.delete if old_ivory
