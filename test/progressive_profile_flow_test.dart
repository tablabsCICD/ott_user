import 'package:flutter_test/flutter_test.dart';
import 'package:ott/data/models/location.dart';
import 'package:ott/data/models/user.dart';
import 'package:ott/data/repositories/country_name.dart';
import 'package:ott/app/provider/userProvider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Progressive Profile Flow Stage Determination Tests', () {
    test('Stage 1 required when Email or DOB is missing', () {
      final user1 = User(id: 1, emailId: '', dob: '', firstName: '', lastName: '');
      final isStage1Incomplete1 = (user1.emailId == null || user1.emailId!.trim().isEmpty) ||
          (user1.dob == null || user1.dob!.trim().isEmpty);
      expect(isStage1Incomplete1, isTrue);

      final user2 = User(id: 1, emailId: 'test@filmytell.com', dob: '', firstName: '', lastName: '');
      final isStage1Incomplete2 = (user2.emailId == null || user2.emailId!.trim().isEmpty) ||
          (user2.dob == null || user2.dob!.trim().isEmpty);
      expect(isStage1Incomplete2, isTrue);

      final user3 = User(id: 1, emailId: 'test@filmytell.com', dob: '2000-01-01', firstName: '', lastName: '');
      final isStage1Incomplete3 = (user3.emailId == null || user3.emailId!.trim().isEmpty) ||
          (user3.dob == null || user3.dob!.trim().isEmpty);
      expect(isStage1Incomplete3, isFalse);
    });

    test('Stage 2 required when Stage 1 is completed but Name is missing', () {
      final user1 = User(id: 1, emailId: 'test@filmytell.com', dob: '2000-01-01', firstName: '', lastName: '');
      final isStage2Incomplete1 = (user1.firstName == null || user1.firstName!.trim().isEmpty) ||
          (user1.lastName == null || user1.lastName!.trim().isEmpty);
      expect(isStage2Incomplete1, isTrue);

      final user2 = User(id: 1, emailId: 'test@filmytell.com', dob: '2000-01-01', firstName: 'John', lastName: 'Doe');
      final isStage2Incomplete2 = (user2.firstName == null || user2.firstName!.trim().isEmpty) ||
          (user2.lastName == null || user2.lastName!.trim().isEmpty);
      expect(isStage2Incomplete2, isFalse);
    });

    test('Stage 3 Address required when Stage 1 & 2 completed but Address missing', () {
      final user1 = User(
        id: 1,
        emailId: 'test@filmytell.com',
        dob: '2000-01-01',
        firstName: 'John',
        lastName: 'Doe',
        location: null,
      );
      final loc1 = user1.location;
      final isAddressIncomplete1 = loc1 == null ||
          loc1.country == null || loc1.country!.trim().isEmpty ||
          loc1.state == null || loc1.state!.trim().isEmpty ||
          loc1.district == null || loc1.district!.trim().isEmpty;
      expect(isAddressIncomplete1, isTrue);

      final user2 = User(
        id: 1,
        emailId: 'test@filmytell.com',
        dob: '2000-01-01',
        firstName: 'John',
        lastName: 'Doe',
        location: Location(country: 'India', state: 'Maharashtra', district: 'Pune'),
      );
      final loc2 = user2.location;
      final isAddressIncomplete2 = loc2 == null ||
          loc2.country == null || loc2.country!.trim().isEmpty ||
          loc2.state == null || loc2.state!.trim().isEmpty ||
          loc2.district == null || loc2.district!.trim().isEmpty;
      expect(isAddressIncomplete2, isFalse);
    });
  });

  group('Hierarchical Location Service Filtering Tests', () {
    final countryService = CountryService();

    test('fetchDistrictsByState returns only districts for given state and does not mix', () async {
      final maharashtraDistricts = await countryService.fetchDistrictsByState('Maharashtra');
      expect(maharashtraDistricts.contains('Pune'), isTrue);
      expect(maharashtraDistricts.contains('Mumbai City'), isTrue);
      expect(maharashtraDistricts.contains('Nashik'), isTrue);
      expect(maharashtraDistricts.contains('Ahmedabad'), isFalse);
      expect(maharashtraDistricts.contains('Bengaluru Urban'), isFalse);

      final gujaratDistricts = await countryService.fetchDistrictsByState('Gujarat');
      expect(gujaratDistricts.contains('Ahmedabad'), isTrue);
      expect(gujaratDistricts.contains('Surat'), isTrue);
      expect(gujaratDistricts.contains('Pune'), isFalse);
    });

    test('fetchTalukasByDistrict returns only talukas for given district and does not mix', () async {
      final puneTalukas = await countryService.fetchTalukasByDistrict('Pune');
      expect(puneTalukas.contains('Haveli'), isTrue);
      expect(puneTalukas.contains('Mulshi'), isTrue);
      expect(puneTalukas.contains('Baramati'), isTrue);
      expect(puneTalukas.contains('Niphad'), isFalse);
      expect(puneTalukas.contains('Sinnar'), isFalse);

      final nashikTalukas = await countryService.fetchTalukasByDistrict('Nashik');
      expect(nashikTalukas.contains('Nashik'), isTrue);
      expect(nashikTalukas.contains('Niphad'), isTrue);
      expect(nashikTalukas.contains('Sinnar'), isTrue);
      expect(nashikTalukas.contains('Haveli'), isFalse);
      expect(nashikTalukas.contains('Mulshi'), isFalse);
    });
  });

  group('UserProvider Location Cascade Reset Tests', () {
    test('loadDistrictOptionsByState clears downstream selections and option lists', () async {
      final provider = UserProvider();
      provider.districtController.text = 'Pune';
      provider.cityController.text = 'Haveli';
      provider.pinCodeDateController.text = '411017';
      provider.talukaOptions = ['Haveli', 'Mulshi'];
      provider.pincodeOptions = ['411017'];

      await provider.loadDistrictOptionsByState('Gujarat');

      expect(provider.districtController.text, isEmpty);
      expect(provider.cityController.text, isEmpty);
      expect(provider.pinCodeDateController.text, isEmpty);
      expect(provider.talukaOptions, isEmpty);
      expect(provider.pincodeOptions, isEmpty);
      expect(provider.districtOptions.contains('Ahmedabad'), isTrue);
      expect(provider.districtOptions.contains('Pune'), isFalse);
    });

    test('loadTalukaOptionsByDistrict clears downstream selections and sets talukas', () async {
      final provider = UserProvider();
      provider.cityController.text = 'Haveli';
      provider.pinCodeDateController.text = '411017';
      provider.pincodeOptions = ['411017'];

      await provider.loadTalukaOptionsByDistrict('Nashik');

      expect(provider.cityController.text, isEmpty);
      expect(provider.pinCodeDateController.text, isEmpty);
      expect(provider.pincodeOptions, isEmpty);
      expect(provider.talukaOptions.contains('Niphad'), isTrue);
      expect(provider.talukaOptions.contains('Haveli'), isFalse);
    });
  });
}
