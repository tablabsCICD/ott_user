import 'dart:convert';
import 'package:http/http.dart' as http;

class CountryService {
  static const String apiUrl = 'https://restcountries.com/v3.1/all';

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
    // Replace with actual API call
    return country == 'India'
        ? ['Maharashtra', 'Karnataka', 'Gujarat']
        : ['State 1', 'State 2'];
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
