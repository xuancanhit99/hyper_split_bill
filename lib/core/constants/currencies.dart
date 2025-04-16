// lib/core/constants/currencies.dart

/// A list of common ISO 4217 currency codes.
/// This list can be expanded as needed.
const List<String> cCommonCurrencies = [
  'USD', // United States Dollar
  'EUR', // Euro
  'JPY', // Japanese Yen
  'GBP', // British Pound Sterling
  'AUD', // Australian Dollar
  'CAD', // Canadian Dollar
  'CHF', // Swiss Franc
  'CNY', // Chinese Yuan
  'SEK', // Swedish Krona
  'NZD', // New Zealand Dollar
  'MXN', // Mexican Peso
  'SGD', // Singapore Dollar
  'HKD', // Hong Kong Dollar
  'NOK', // Norwegian Krone
  'KRW', // South Korean Won
  'TRY', // Turkish Lira
  'RUB', // Russian Ruble
  'INR', // Indian Rupee
  'BRL', // Brazilian Real
  'ZAR', // South African Rand
  'VND', // Vietnamese Dong
  'THB', // Thai Baht
  'IDR', // Indonesian Rupiah
  'MYR', // Malaysian Ringgit
  'PHP', // Philippine Peso
  // Add more currencies below as needed
  // 'AED', // United Arab Emirates Dirham
  // 'AFN', // Afghan Afghani
  // 'ALL', // Albanian Lek
  // 'AMD', // Armenian Dram
  // 'ANG', // Netherlands Antillean Guilder
  // 'AOA', // Angolan Kwanza
  // 'ARS', // Argentine Peso
  // 'AWG', // Aruban Florin
  // 'AZN', // Azerbaijani Manat
  // 'BAM', // Bosnia-Herzegovina Convertible Mark
  // 'BBD', // Barbadian Dollar
  // 'BDT', // Bangladeshi Taka
  // 'BGN', // Bulgarian Lev
  // 'BHD', // Bahraini Dinar
  // 'BIF', // Burundian Franc
  // 'BMD', // Bermudan Dollar
  // 'BND', // Brunei Dollar
  // 'BOB', // Bolivian Boliviano
  // 'BSD', // Bahamian Dollar
  // 'BTN', // Bhutanese Ngultrum
  // 'BWP', // Botswanan Pula
  // 'BYN', // Belarusian Ruble
  // 'BZD', // Belize Dollar
  // 'CDF', // Congolese Franc
  // 'CLP', // Chilean Peso
  // 'COP', // Colombian Peso
  // 'CRC', // Costa Rican Colón
  // 'CUP', // Cuban Peso
  // 'CVE', // Cape Verdean Escudo
  // 'CZK', // Czech Republic Koruna
  // 'DJF', // Djiboutian Franc
  // 'DKK', // Danish Krone
  // 'DOP', // Dominican Peso
  // 'DZD', // Algerian Dinar
  // 'EGP', // Egyptian Pound
  // 'ERN', // Eritrean Nakfa
  // 'ETB', // Ethiopian Birr
  // 'FJD', // Fijian Dollar
  // 'FKP', // Falkland Islands Pound
  // 'GEL', // Georgian Lari
  // 'GGP', // Guernsey Pound
  // 'GHS', // Ghanaian Cedi
  // 'GIP', // Gibraltar Pound
  // 'GMD', // Gambian Dalasi
  // 'GNF', // Guinean Franc
  // 'GTQ', // Guatemalan Quetzal
  // 'GYD', // Guyanaese Dollar
  // 'HNL', // Honduran Lempira
  // 'HRK', // Croatian Kuna (use EUR now)
  // 'HTG', // Haitian Gourde
  // 'HUF', // Hungarian Forint
  // 'ILS', // Israeli New Sheqel
  // 'IMP', // Manx pound
  // 'IQD', // Iraqi Dinar
  // 'IRR', // Iranian Rial
  // 'ISK', // Icelandic Króna
  // 'JEP', // Jersey Pound
  // 'JMD', // Jamaican Dollar
  // 'JOD', // Jordanian Dinar
  // 'KES', // Kenyan Shilling
  // 'KGS', // Kyrgystani Som
  // 'KHR', // Cambodian Riel
  // 'KID', // Kiribati Dollar
  // 'KMF', // Comorian Franc
  // 'KWD', // Kuwaiti Dinar
  // 'KYD', // Cayman Islands Dollar
  // 'KZT', // Kazakhstani Tenge
  // 'LAK', // Laotian Kip
  // 'LBP', // Lebanese Pound
  // 'LKR', // Sri Lankan Rupee
  // 'LRD', // Liberian Dollar
  // 'LSL', // Lesotho Loti
  // 'LYD', // Libyan Dinar
  // 'MAD', // Moroccan Dirham
  // 'MDL', // Moldovan Leu
  // 'MGA', // Malagasy Ariary
  // 'MKD', // Macedonian Denar
  // 'MMK', // Myanma Kyat
  // 'MNT', // Mongolian Tugrik
  // 'MOP', // Macanese Pataca
  // 'MRU', // Mauritanian Ouguiya
  // 'MUR', // Mauritian Rupee
  // 'MVR', // Maldivian Rufiyaa
  // 'MWK', // Malawian Kwacha
  // 'MZN', // Mozambican Metical
  // 'NAD', // Namibian Dollar
  // 'NGN', // Nigerian Naira
  // 'NIO', // Nicaraguan Córdoba
  // 'NPR', // Nepalese Rupee
  // 'OMR', // Omani Rial
  // 'PAB', // Panamanian Balboa
  // 'PEN', // Peruvian Nuevo Sol
  // 'PGK', // Papua New Guinean Kina
  // 'PKR', // Pakistani Rupee
  // 'PLN', // Polish Zloty
  // 'PYG', // Paraguayan Guarani
  // 'QAR', // Qatari Rial
  // 'RON', // Romanian Leu
  // 'RSD', // Serbian Dinar
  // 'RWF', // Rwandan Franc
  // 'SAR', // Saudi Riyal
  // 'SBD', // Solomon Islands Dollar
  // 'SCR', // Seychellois Rupee
  // 'SDG', // Sudanese Pound
  // 'SHP', // Saint Helena Pound
  // 'SLE', // Sierra Leonean Leone
  // 'SOS', // Somali Shilling
  // 'SRD', // Surinamese Dollar
  // 'SSP', // South Sudanese Pound
  // 'STN', // São Tomé and Príncipe Dobra
  // 'SYP', // Syrian Pound
  // 'SZL', // Swazi Lilangeni
  // 'TJS', // Tajikistani Somoni
  // 'TMT', // Turkmenistani Manat
  // 'TND', // Tunisian Dinar
  // 'TOP', // Tongan Paʻanga
  // 'TTD', // Trinidad and Tobago Dollar
  // 'TWD', // New Taiwan Dollar
  // 'TZS', // Tanzanian Shilling
  // 'UAH', // Ukrainian Hryvnia
  // 'UGX', // Ugandan Shilling
  // 'UYU', // Uruguayan Peso
  // 'UZS', // Uzbekistan Som
  // 'VES', // Venezuelan Bolívar Soberano
  // 'VUV', // Vanuatu Vatu
  // 'WST', // Samoan Tala
  // 'XAF', // CFA Franc BEAC
  // 'XCD', // East Caribbean Dollar
  // 'XDR', // Special Drawing Rights
  // 'XOF', // CFA Franc BCEAO
  // 'XPF', // CFP Franc
  // 'YER', // Yemeni Rial
  // 'ZMW', // Zambian Kwacha
  // 'ZWL', // Zimbabwean Dollar
];

/// A map associating common ISO 4217 currency codes with their names.
const Map<String, String> cCurrencyMap = {
  'USD': 'United States Dollar',
  'EUR': 'Euro',
  'JPY': 'Japanese Yen',
  'GBP': 'British Pound Sterling',
  'AUD': 'Australian Dollar',
  'CAD': 'Canadian Dollar',
  'CHF': 'Swiss Franc',
  'CNY': 'Chinese Yuan',
  'SEK': 'Swedish Krona',
  'NZD': 'New Zealand Dollar',
  'MXN': 'Mexican Peso',
  'SGD': 'Singapore Dollar',
  'HKD': 'Hong Kong Dollar',
  'NOK': 'Norwegian Krone',
  'KRW': 'South Korean Won',
  'TRY': 'Turkish Lira',
  'RUB': 'Russian Ruble',
  'INR': 'Indian Rupee',
  'BRL': 'Brazilian Real',
  'ZAR': 'South African Rand',
  'VND': 'Vietnamese Dong',
  'THB': 'Thai Baht',
  'IDR': 'Indonesian Rupiah',
  'MYR': 'Malaysian Ringgit',
  'PHP': 'Philippine Peso',
  // Add mappings for other currencies if their codes are in cCommonCurrencies
};
