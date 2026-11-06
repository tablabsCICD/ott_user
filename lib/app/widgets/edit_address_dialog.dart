import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ott/app/core/utils/text_capitalization_formatter.dart';
import 'package:ott/app/provider/userProvider.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The existing "Edit address" form (manual entry, address search and
/// "use current location"), shared by Account Details and the third-launch
/// location step. Saves through [UserProvider.updateUserLocation].
/// Returns true when the address was saved.
Future<bool> showEditAddressDialog(BuildContext context) async {
  var saved = false;
  final formKey = GlobalKey<FormState>();
  final userProvider = context.read<UserProvider>();
  final location = userProvider.userObj.location;

  await userProvider.loadCountryOptions();
  if ((location?.country ?? "").trim().isNotEmpty) {
    await userProvider.loadStateOptionsByCountry(location!.country!);
  }

  userProvider.officeBuildingController.text =
      location?.officeBuilding ?? location?.area ?? "";
  userProvider.countryController.text = location?.country ?? "";
  userProvider.stateController.text = location?.state ?? "";
  userProvider.districtController.text = location?.district ?? "";
  userProvider.cityController.text = location?.city ?? location?.taluka ?? "";
  userProvider.pinCodeDateController.text = location?.pincode ?? "";

  if (!context.mounted) return false;
  await showDialog(
    context: context,
    builder: (dialogContext) {
      return Consumer<UserProvider>(
        builder: (context, provider, _) {
          final selectedThemeData = Theme.of(context);
          final lang = AppLocalizations.of(context)!;

          return AlertDialog(
            backgroundColor: selectedThemeData.scaffoldBackgroundColor,
            title: Text(lang.editAddress),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: provider.officeBuildingController,
                      maxLines: 2,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: [
                        CapitalizeWordsTextInputFormatter(),
                      ],
                      cursorColor: selectedThemeData.primaryColor,
                      onChanged: provider.searchAddressSuggestions,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: selectedThemeData.cardColor,
                        labelText: lang.profileAddress,
                        hintText: lang.profileSearchAddress,
                        labelStyle: TextStyle(
                          color: selectedThemeData.canvasColor,
                        ),
                        hintStyle: TextStyle(
                          color: selectedThemeData.canvasColor,
                          fontSize: 13,
                        ),
                        border: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: Colors.transparent),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: Colors.transparent),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: selectedThemeData.primaryColor,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        prefixIcon: Icon(
                          Icons.location_on_outlined,
                          color: selectedThemeData.canvasColor,
                        ),
                        suffixIcon: provider.isSearchingAddress
                            ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: selectedThemeData.primaryColor,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      style: TextStyle(color: selectedThemeData.canvasColor),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: provider.isFetchingCurrentLocation
                          ? null
                          : provider.useCurrentLocationFromGoogle,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: selectedThemeData.primaryColor,
                        side: BorderSide(
                          color: selectedThemeData.primaryColor,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: provider.isFetchingCurrentLocation
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: selectedThemeData.primaryColor,
                              ),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(
                        provider.isFetchingCurrentLocation
                            ? lang.profileFetchingLocation
                            : lang.profileUseCurrentLocation,
                      ),
                    ),
                    if (provider.addressSuggestions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 6, bottom: 8),
                        decoration: BoxDecoration(
                          color: selectedThemeData.cardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selectedThemeData.primaryColor
                                .withValues(alpha: 0.25),
                          ),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: provider.addressSuggestions.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color:
                                selectedThemeData.canvasColor.withValues(alpha: 0.08),
                          ),
                          itemBuilder: (context, index) {
                            final suggestion =
                                provider.addressSuggestions[index];
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                Icons.place_outlined,
                                color: selectedThemeData.primaryColor,
                              ),
                              title: Text(
                                suggestion['description'] ?? '',
                                style: TextStyle(
                                  color: selectedThemeData.canvasColor,
                                  fontSize: 13,
                                ),
                              ),
                              onTap: () {
                                provider.selectAddressSuggestion(suggestion);
                              },
                            );
                          },
                        ),
                      ),
                    _buildEditableLocationDropdown(
                      context: context,
                      selectedThemeData: selectedThemeData,
                      controller: provider.countryController,
                      label: lang.country,
                      hintText: lang.profileEnterCountry,
                      options: provider.countryOptions,
                      onChanged: (value) {
                        if (value.trim().isEmpty) {
                          provider.loadStateOptionsByCountry('');
                        }
                      },
                      onFieldSubmitted: provider.loadStateOptionsByCountry,
                      onOptionSelected: provider.loadStateOptionsByCountry,
                    ),
                    _buildEditableLocationDropdown(
                      context: context,
                      selectedThemeData: selectedThemeData,
                      controller: provider.stateController,
                      label: lang.state,
                      hintText: lang.profileEnterState,
                      options: provider.stateOptions,
                      onChanged: (value) {
                        if (value.trim().isEmpty) {
                          provider.loadDistrictOptionsByState('');
                        }
                      },
                      onFieldSubmitted: provider.loadDistrictOptionsByState,
                      onOptionSelected: provider.loadDistrictOptionsByState,
                    ),
                    _buildEditableLocationDropdown(
                      context: context,
                      selectedThemeData: selectedThemeData,
                      controller: provider.districtController,
                      label: lang.district,
                      hintText: lang.profileEnterDistrict,
                      options: provider.districtOptions,
                      onChanged: (value) {
                        if (value.trim().isEmpty) {
                          provider.loadTalukaOptionsByDistrict('');
                        }
                      },
                      onFieldSubmitted: provider.loadTalukaOptionsByDistrict,
                      onOptionSelected: provider.loadTalukaOptionsByDistrict,
                    ),
                    _buildEditableLocationDropdown(
                      context: context,
                      selectedThemeData: selectedThemeData,
                      controller: provider.cityController,
                      label: lang.profileCity,
                      hintText: lang.profileEnterCity,
                      options: provider.talukaOptions,
                    ),
                    _buildEditableLocationDropdown(
                      context: context,
                      selectedThemeData: selectedThemeData,
                      controller: provider.pinCodeDateController,
                      label: lang.profilePincode,
                      hintText: lang.profileEnterPincode,
                      options: provider.pincodeOptions,
                      keyboardType: TextInputType.number,
                      isRequired: false,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  lang.cancel,
                  style: TextStyle(color: selectedThemeData.canvasColor),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedThemeData.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final result = await provider.updateUserLocation();
                  if (!context.mounted) return;

                  if (result['success'] == true) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('isLoggedIn', true);
                    CustomToast.show(
                      context,
                      lang.profileAddressUpdated,
                      isSuccess: true,
                    );
                    saved = true;
                    Navigator.of(dialogContext).pop();
                  } else {
                    CustomToast.show(
                      context,
                      lang.homeFailureMessage('${result['message']}'),
                      isSuccess: false,
                    );
                  }
                },
                child: Text(lang.save),
              ),
            ],
          );
        },
      );
    },
  );
  return saved;
}

Widget _buildEditableLocationDropdown({
  required BuildContext context,
  required ThemeData selectedThemeData,
  required TextEditingController controller,
  required String label,
  required String hintText,
  required List<String> options,
  TextInputType keyboardType = TextInputType.text,
  bool isRequired = true,
  ValueChanged<String>? onChanged,
  ValueChanged<String>? onFieldSubmitted,
  ValueChanged<String>? onOptionSelected,
}) {
  final cleanOptions =
      options.where((option) => option.trim().isNotEmpty).toSet().toList();

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: selectedThemeData.canvasColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: keyboardType == TextInputType.number
              ? TextCapitalization.none
              : TextCapitalization.words,
          inputFormatters: keyboardType == TextInputType.number
              ? [FilteringTextInputFormatter.digitsOnly]
              : [CapitalizeWordsTextInputFormatter()],
          cursorColor: selectedThemeData.primaryColor,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          validator: isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context)!
                        .profileFieldRequired(hintText);
                  }
                  return null;
                }
              : null,
          style: TextStyle(
            color: selectedThemeData.canvasColor,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: selectedThemeData.cardColor,
            hintText: hintText,
            hintStyle: TextStyle(
              color: selectedThemeData.canvasColor,
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.transparent),
              borderRadius: BorderRadius.circular(6),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.transparent),
              borderRadius: BorderRadius.circular(6),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: selectedThemeData.primaryColor),
              borderRadius: BorderRadius.circular(6),
            ),
            suffixIcon: PopupMenuButton<String>(
              icon: Icon(
                Icons.arrow_drop_down,
                color: selectedThemeData.primaryColor,
              ),
              color: selectedThemeData.cardColor,
              enabled: cleanOptions.isNotEmpty,
              onSelected: (value) {
                controller.text = value;
                if (onOptionSelected != null) {
                  onOptionSelected(value);
                }
              },
              itemBuilder: (context) {
                if (cleanOptions.isEmpty) {
                  return [
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Text(
                        AppLocalizations.of(context)!.profileNoOptionsAvailable,
                        style: TextStyle(
                          color: selectedThemeData.canvasColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ];
                }

                return cleanOptions
                    .map(
                      (option) => PopupMenuItem<String>(
                        value: option,
                        child: Text(
                          option,
                          style: TextStyle(
                            color: selectedThemeData.canvasColor,
                          ),
                        ),
                      ),
                    )
                    .toList();
              },
            ),
          ),
        ),
      ],
    ),
  );
}
