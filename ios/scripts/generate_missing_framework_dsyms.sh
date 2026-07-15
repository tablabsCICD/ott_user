#!/bin/sh

set -eu

# Vendored frameworks are already compiled, so changing Xcode's debug-information
# setting cannot create their dSYMs. During an archive, copy a vendor-provided
# dSYM when available; otherwise create a UUID-matching symbol wrapper from the
# embedded Mach-O binary so App Store Connect can process the archive.
if [ "${ACTION:-}" != "install" ] || [ "${PLATFORM_NAME:-}" != "iphoneos" ]; then
  exit 0
fi

frameworks_dir="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
destination_dir="${DWARF_DSYM_FOLDER_PATH}"

if [ ! -d "$frameworks_dir" ] || [ -z "$destination_dir" ]; then
  exit 0
fi

mkdir -p "$destination_dir"

dsym_matches_binary() {
  binary_path="$1"
  dsym_path="$2"

  [ -d "$dsym_path" ] || return 1

  binary_uuids="$(xcrun dwarfdump --uuid "$binary_path" 2>/dev/null | awk '{print $2}')"
  dsym_uuids="$(xcrun dwarfdump --uuid "$dsym_path" 2>/dev/null | awk '{print $2}')"

  [ -n "$binary_uuids" ] || return 1

  for uuid in $binary_uuids; do
    case " $dsym_uuids " in
      *" $uuid "*) ;;
      *) return 1 ;;
    esac
  done
}

# These are binary XCFrameworks supplied by media_kit_libs_ios_video and
# razorpay-pod. Frameworks compiled from source already receive dSYMs from
# Xcode and must not be duplicated here.
vendored_frameworks="
Ass
Avcodec
Avfilter
Avformat
Avutil
Dav1d
Freetype
Fribidi
Harfbuzz
Mbedcrypto
Mbedtls
Mbedx509
Mpv
Png16
Razorpay
RazorpayCore
RazorpayStandard
Swresample
Swscale
Uchardet
Xml2
"

for framework_name in $vendored_frameworks; do
  framework_path="$frameworks_dir/$framework_name.framework"
  [ -d "$framework_path" ] || continue

  executable_name="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$framework_path/Info.plist" 2>/dev/null || true)"
  [ -n "$executable_name" ] || executable_name="$framework_name"

  binary_path="$framework_path/$executable_name"
  output_path="$destination_dir/$framework_name.framework.dSYM"

  [ -f "$binary_path" ] || continue

  if dsym_matches_binary "$binary_path" "$output_path"; then
    continue
  fi

  vendor_dsym=""
  if [ -d "${PODS_ROOT:-}" ]; then
    vendor_dsym="$(find "$PODS_ROOT" -type d -path "*/ios-arm64/dSYMs/$framework_name.framework.dSYM" -print -quit 2>/dev/null || true)"
  fi

  rm -rf "$output_path"

  if [ -n "$vendor_dsym" ] && dsym_matches_binary "$binary_path" "$vendor_dsym"; then
    ditto "$vendor_dsym" "$output_path"
    echo "Copied vendor dSYM for $framework_name.framework"
  else
    dsymutil_log="${TEMP_DIR:-/tmp}/$framework_name-dsymutil.log"
    if ! xcrun dsymutil "$binary_path" -o "$output_path" 2>"$dsymutil_log"; then
      cat "$dsymutil_log" >&2
      exit 1
    fi
    echo "Generated UUID-matching dSYM for $framework_name.framework"
  fi

  if ! dsym_matches_binary "$binary_path" "$output_path"; then
    echo "error: dSYM UUID does not match $framework_name.framework" >&2
    exit 1
  fi
done
