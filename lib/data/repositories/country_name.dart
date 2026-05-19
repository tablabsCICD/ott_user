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

  Future<List<String>> fetchDistrictsByState(String state) async {
    // Replace with actual API call
    return state == 'Maharashtra'
        ? ['Pune', 'Mumbai', 'Nagpur']
        : ['District 1', 'District 2'];
  }

  Future<List<String>> fetchTalukasByDistrict(String district) async {
    // Replace with actual API call
    return district == 'Pune' ? ['Haveli', 'Mulshi'] : ['Taluka 1', 'Taluka 2'];
  }
}
