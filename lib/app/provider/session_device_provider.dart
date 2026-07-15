import 'package:ott/app/core/network/anti_piracy_api_client.dart';
import 'package:ott/app/core/repositories/secure_playback_repository.dart';
import 'package:ott/data/models/anti_piracy_models.dart';
import 'baseProvider.dart';

class SessionDeviceProvider extends BaseProvider {
  SessionDeviceProvider({SecurePlaybackRepository? repository})
      : _repository = repository ?? SecurePlaybackRepository.instance;

  final SecurePlaybackRepository _repository;
  bool isLoading = false;
  String? errorMessage;
  List<DeviceBinding> devices = [];

  Future<void> fetchDevices() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      devices = await _repository.getRegisteredDevices();
    } on SecurePlaybackException catch (error) {
      errorMessage = error.userMessage;
    } catch (_) {
      errorMessage = 'Unable to load registered devices.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> removeDevice(String deviceId) async {
    try {
      await _repository.removeDevice(deviceId);
      await fetchDevices();
      return true;
    } on SecurePlaybackException catch (error) {
      errorMessage = error.userMessage;
    } catch (_) {
      errorMessage = 'Unable to remove this device.';
    }
    notifyListeners();
    return false;
  }
}
