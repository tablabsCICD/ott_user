import 'dart:convert';
import 'package:http/http.dart' as http;

class CountryService {
  static const String apiUrl = 'https://restcountries.com/v3.1/all';
  static const String countryStateApiUrl =
      'https://countriesnow.space/api/v0.1/countries/states';

  Future<List<String>> fetchCountryNames() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);

        // Extract only country names
        List<String> countryNames = data.map((country) {
          return country['name']['common'] as String;
        }).toList();

        // Sort alphabetically
        countryNames.sort();
        return countryNames;
      } else {
        throw Exception('Failed to fetch countries');
      }
    } catch (error) {
      throw Exception('Error fetching countries: $error');
    }
  }

  Future<List<String>> fetchStatesByCountry(String country) async {
    final countryName = country.trim();
    if (countryName.isEmpty) return [];

    try {
      final response = await http.post(
        Uri.parse(countryStateApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'country': countryName}),
      );

      if (response.statusCode != 200) return [];

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final isError = body['error'] == true;
      if (isError) return [];

      final data = body['data'] as Map<String, dynamic>?;
      final states = data?['states'] as List? ?? [];
      final stateNames = states
          .map((state) => (state as Map<String, dynamic>)['name']?.toString())
          .whereType<String>()
          .map((name) => name.trim())
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();

      stateNames.sort();
      return stateNames;
    } catch (_) {
      return [];
    }
  }

  static const Map<String, List<String>> _stateDistricts = {
    'Maharashtra': [
      'Ahmednagar',
      'Akola',
      'Amravati',
      'Aurangabad',
      'Beed',
      'Bhandara',
      'Buldhana',
      'Chandrapur',
      'Dhule',
      'Gadchiroli',
      'Gondia',
      'Hingoli',
      'Jalgaon',
      'Jalna',
      'Kolhapur',
      'Latur',
      'Mumbai City',
      'Mumbai Suburban',
      'Nagpur',
      'Nanded',
      'Nandurbar',
      'Nashik',
      'Osmanabad',
      'Palghar',
      'Parbhani',
      'Pune',
      'Raigad',
      'Ratnagiri',
      'Sangli',
      'Satara',
      'Sindhudurg',
      'Solapur',
      'Thane',
      'Wardha',
      'Washim',
      'Yavatmal',
    ],
    'Gujarat': [
      'Ahmedabad',
      'Amreli',
      'Anand',
      'Aravalli',
      'Banaskantha',
      'Bharuch',
      'Bhavnagar',
      'Botad',
      'Chhota Udaipur',
      'Dahod',
      'Dang',
      'Devbhoomi Dwarka',
      'Gandhinagar',
      'Gir Somnath',
      'Jamnagar',
      'Junagadh',
      'Kheda',
      'Kutch',
      'Mahisagar',
      'Mehsana',
      'Morbi',
      'Narmada',
      'Navsari',
      'Panchmahal',
      'Patan',
      'Porbandar',
      'Rajkot',
      'Sabarkantha',
      'Surat',
      'Surendranagar',
      'Tapi',
      'Vadodara',
      'Valsad',
    ],
    'Karnataka': [
      'Bagalkot',
      'Ballari',
      'Belagavi',
      'Bengaluru Rural',
      'Bengaluru Urban',
      'Bidar',
      'Chamarajanagar',
      'Chikkaballapur',
      'Chikkamagaluru',
      'Chitradurga',
      'Dakshina Kannada',
      'Davanagere',
      'Dharwad',
      'Gadag',
      'Hassan',
      'Haveri',
      'Kalaburagi',
      'Kodagu',
      'Kolar',
      'Koppal',
      'Mandya',
      'Mysuru',
      'Raichur',
      'Ramanagara',
      'Shivamogga',
      'Tumakuru',
      'Udupi',
      'Uttara Kannada',
      'Vijayapura',
      'Yadgir',
    ],
  };

  static const Map<String, List<String>> _districtTalukas = {
    'Pune': [
      'Ambegaon',
      'Baramati',
      'Bhor',
      'Daund',
      'Haveli',
      'Indapur',
      'Junnar',
      'Khed',
      'Maval',
      'Mulshi',
      'Pune City',
      'Purandar',
      'Shirur',
      'Velhe',
    ],
    'Nashik': [
      'Baglan',
      'Chandwad',
      'Deola',
      'Dindori',
      'Igatpuri',
      'Kalwan',
      'Malegaon',
      'Nandgaon',
      'Nashik',
      'Niphad',
      'Peint',
      'Sinnar',
      'Surgana',
      'Trimbakeshwar',
      'Yeola',
    ],
    'Nagpur': [
      'Bhiwapur',
      'Hingna',
      'Kalameshwar',
      'Kamptee',
      'Katol',
      'Kuhi',
      'Mouda',
      'Nagpur (Rural)',
      'Nagpur (Urban)',
      'Narkhed',
      'Parseoni',
      'Ramtek',
      'Savner',
      'Umred',
    ],
    'Ahmedabad': [
      'Ahmedabad City',
      'Bavla',
      'Daskroi',
      'Detroj-Rampura',
      'Dhandhuka',
      'Dholera',
      'Dholka',
      'Mandal',
      'Sanand',
      'Viramgam',
    ],
    'Bengaluru Urban': [
      'Anekal',
      'Bengaluru East',
      'Bengaluru North',
      'Bengaluru South',
      'Yelahanka',
    ],
  };

  Future<List<String>> fetchDistrictsByState(String state) async {
    final stateTrimmed = state.trim();
    if (stateTrimmed.isEmpty) return [];
    
    // Check predefined districts for state
    final districts = _stateDistricts[stateTrimmed];
    if (districts != null) {
      final list = List<String>.from(districts);
      list.sort();
      return list;
    }
    return [];
  }

  Future<List<String>> fetchTalukasByDistrict(String district) async {
    final districtTrimmed = district.trim();
    if (districtTrimmed.isEmpty) return [];

    final talukas = _districtTalukas[districtTrimmed];
    if (talukas != null) {
      final list = List<String>.from(talukas);
      list.sort();
      return list;
    }
    return [];
  }
}
