import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/pages/profile%20page/component/EditProfilePage.dart';
import 'package:ott/app/provider/userProvider.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountDetailsPage extends StatefulWidget {
  const AccountDetailsPage({super.key});

  @override
  State<AccountDetailsPage> createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends State<AccountDetailsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<UserProvider>();
      await provider.hydrateFromCache();
      final id = provider.userObj.id ?? 0;
      if (id > 0) {
        await provider.getUserById(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Account Details",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            final user = userProvider.userObj;
            final location = user.location;

            String v(String? value) =>
                (value == null || value.trim().isEmpty) ? "Not added" : value;

            return Stack(
              children: [
                SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _profileHeader(user, theme),
                      const SizedBox(height: 16),
                      _card(
                        theme: theme,
                        children: [
                          _inputTile(
                              theme, "Mobile Number", v(user.mobileNumber),
                              trailing: "EDIT"),
                          const SizedBox(height: 12),
                          _inputTile(theme, "Email Address", v(user.emailId),
                              trailing: "ADD"),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _sectionTitle(theme, "Personal Details"),
                      const SizedBox(height: 10),
                      _card(
                        theme: theme,
                        children: [
                          _inputTile(theme, "First Name", v(user.firstName)),
                          const SizedBox(height: 12),
                          _inputTile(theme, "Last Name", v(user.lastName)),
                          const SizedBox(height: 12),
                          _inputTile(theme, "Birthday", v(user.dob)),
                          /* const SizedBox(height: 12),
                          _chipSelector(theme, "Identity", ["Female", "Male"],
                              selected: _genderLabel(user.gender)), */
                        ],
                      ),
                      const SizedBox(height: 18),
                      _sectionTitle(theme, "Address"),
                      const SizedBox(height: 10),
                      _card(
                        theme: theme,
                        children: [
                          /*   _chipSelector(
                              theme, "Save as", ["Home", "Work", "Other"],
                              selected: "Home"),
                          const SizedBox(height: 12), */
                          _inputTile(theme, "Address Line",
                              v(location?.officeBuilding)),
                          const SizedBox(height: 12),
                          _inputTile(
                            theme,
                            "City",
                            v(location?.city ?? location?.taluka),
                          ),
                          const SizedBox(height: 12),
                          _inputTile(theme, "District", v(location?.district)),
                          const SizedBox(height: 12),
                          _inputTile(theme, "State", v(location?.state)),
                          const SizedBox(height: 12),
                          _inputTile(theme, "Country", v(location?.country)),
                          const SizedBox(height: 12),
                          _inputTile(theme, "Pincode", v(location?.pincode)),
                          const SizedBox(height: 12),
                          _editButtons(theme),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _profileHeader(dynamic user, ThemeData theme) {
    final photo = (user.profilePhoto ?? '').toString().trim();
    final imageUri = Uri.tryParse(photo);
    final hasValidNetworkPhoto = photo.isNotEmpty &&
        imageUri != null &&
        (imageUri.isScheme('http') || imageUri.isScheme('https'));
    final ImageProvider imageProvider = hasValidNetworkPhoto
        ? NetworkImage(photo)
        : AssetImage(ImageConstant.profile);

    return Center(
      child: Hero(
        tag: "profile",
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: theme.cardColor,
              backgroundImage: imageProvider,
            ),
            (user.verified ?? false)
                ? Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.scaffoldBackgroundColor,
                      ),
                      child: Icon(
                        Icons.verified,
                        color: Colors.blue,
                        size: 18,
                      ),
                    ),
                  )
                : SizedBox(),
          ],
        ),
      ),
    );
  }

  Widget _card({required ThemeData theme, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _editButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            theme,
            icon: Icons.person_outline,
            label: "Edit Profile",
            onPressed: _openEditProfile,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionButton(
            theme,
            icon: Icons.location_on_outlined,
            label: "Edit Address",
            onPressed: _showEditAddressDialog,
          ),
        ),
      ],
    );
  }

  Widget _actionButton(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _openEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfilePage()),
    );

    if (!mounted) return;
    final provider = context.read<UserProvider>();
    final id = provider.userObj.id ?? 0;
    if (id > 0) {
      await provider.getUserById(id);
    }
  }

  Future<void> _showEditAddressDialog() async {
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

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Consumer<UserProvider>(
          builder: (context, provider, _) {
            final selectedThemeData = Theme.of(context);

            return AlertDialog(
              backgroundColor: selectedThemeData.scaffoldBackgroundColor,
              title: const Text("Edit Address"),
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
                        cursorColor: selectedThemeData.primaryColor,
                        onChanged: provider.searchAddressSuggestions,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: selectedThemeData.cardColor,
                          labelText: 'Address',
                          hintText: 'Search your address',
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
                              ? 'Fetching location...'
                              : 'Use current location',
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
                                  .withOpacity(0.25),
                            ),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: provider.addressSuggestions.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: selectedThemeData.canvasColor
                                  .withOpacity(0.08),
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
                        label: 'Country',
                        hintText: 'Enter country',
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
                        label: 'State',
                        hintText: 'Enter state',
                        options: provider.stateOptions,
                      ),
                      _buildEditableLocationDropdown(
                        context: context,
                        selectedThemeData: selectedThemeData,
                        controller: provider.districtController,
                        label: 'District',
                        hintText: 'Enter district',
                        options: provider.districtOptions,
                      ),
                      _buildEditableLocationDropdown(
                        context: context,
                        selectedThemeData: selectedThemeData,
                        controller: provider.cityController,
                        label: 'City',
                        hintText: 'Enter city',
                        options: provider.talukaOptions,
                      ),
                      _buildEditableLocationDropdown(
                        context: context,
                        selectedThemeData: selectedThemeData,
                        controller: provider.pinCodeDateController,
                        label: 'Pincode',
                        hintText: 'Enter pincode',
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
                    "Cancel",
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
                    if (!mounted) return;

                    if (result['success'] == true) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('isLoggedIn', true);
                      CustomToast.show(
                        context,
                        "Address updated successfully!",
                        isSuccess: true,
                      );
                      Navigator.of(dialogContext).pop();
                    } else {
                      CustomToast.show(
                        context,
                        'Failure: ${result['message']}',
                        isSuccess: false,
                      );
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
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
            cursorColor: selectedThemeData.primaryColor,
            onChanged: onChanged,
            onFieldSubmitted: onFieldSubmitted,
            validator: isRequired
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '$hintText is required';
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
                          'No options available',
                          style: TextStyle(
                            color:
                                selectedThemeData.canvasColor.withOpacity(0.7),
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

  static Widget _sectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 15,
        color: theme.canvasColor,
      ),
    );
  }

  Widget _inputTile(ThemeData theme, String label, String value,
      {String? trailing}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 12, color: theme.canvasColor.withOpacity(0.7)),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(fontSize: 14, color: theme.canvasColor),
                ),
              ),
              /* if (trailing != null)
                Text(
                  trailing,
                  style: TextStyle(
                      color: theme.primaryColor, fontWeight: FontWeight.w600),
                ) */
            ],
          ),
        )
      ],
    );
  }

  Widget _chipSelector(ThemeData theme, String title, List<String> options,
      {required String selected}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 12, color: theme.canvasColor.withOpacity(0.7))),
        const SizedBox(height: 8),
        Row(
          children: options.map((e) {
            final isSelected = e == selected;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isSelected
                          ? theme.primaryColor
                          : theme.dividerColor.withOpacity(0.5)),
                  color: isSelected
                      ? theme.primaryColor.withOpacity(0.08)
                      : theme.cardColor,
                ),
                child: Text(
                  e,
                  style: TextStyle(
                    color: isSelected ? theme.primaryColor : theme.canvasColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        )
      ],
    );
  }

  Widget _bottomButton(ThemeData theme) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(14),
        color: theme.scaffoldBackgroundColor,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {},
          child: const Text(
            "Save Changes",
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  String _genderLabel(String? gender) {
    final g = (gender ?? '').trim().toLowerCase();
    if (g == 'female' || g == 'woman') return 'Woman';
    if (g == 'male' || g == 'man') return 'Man';
    return '';
  }
}
