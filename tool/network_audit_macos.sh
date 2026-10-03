#!/usr/bin/env bash
# Checks that Docudis does not use the network. While it runs, tcpdump
# records every packet the Docudis process sends or receives (pktap tags each
# packet with its process), and afterwards the mDNSResponder log is searched
# for DNS lookups made on Docudis's behalf and the sandbox log for network
# access it was refused (an attempt the sandbox blocks sends no packet).
# It also fails if ONNX Runtime's telemetry wrote anything: its device ID and
# event queue under Application Support/Microsoft/DeveloperTools/.onnxruntime.
# Two workloads:
#
#   1. the release app, open for IDLE_SECONDS (use it by hand meanwhile if
#      you like: paste, open files, anonymize, restore);
#   2. integration_test/flow_test.dart, the whole flow with the real native
#      libraries and models. This is a debug build that talks to the flutter
#      tool over 127.0.0.1, so loopback packets are counted separately.
#
# It also lists the network functions each bundled native library imports.
#
#   tool/network_audit_macos.sh
#   IDLE_SECONDS=86400 tool/network_audit_macos.sh
#   APP=/Applications/Docudis.app FLOW=0 tool/network_audit_macos.sh
#
# APP skips the release build and audits that app instead; FLOW=0 skips the
# integration test. Needs sudo for tcpdump. Everything goes to
# build/network_audit/<time>/; exits 1 if any packet left the machine, any
# DNS lookup was made, the sandbox refused any network access or telemetry
# files were written.
set -euo pipefail
cd "$(dirname "$0")/.."

idle=${IDLE_SECONDS:-300}
out=build/network_audit/$(date +%Y%m%d-%H%M%S)
mkdir -p "$out"

if [ -z "${APP:-}" ]; then
  flutter build macos --release
  APP=build/macos/Build/Products/Release/Docudis.app
fi

{
  echo "commit: $(git rev-parse HEAD)$(git diff --quiet HEAD || echo ' (with local changes)')"
  echo "app: $APP"
  echo "macOS: $(sw_vers -productVersion) ($(uname -m))"
  echo "entitlements:"
  codesign -d --entitlements - --xml "$APP" 2> /dev/null | plutil -p - | grep '=>'
} > "$out/summary.txt"

echo "== Network functions imported by the bundled libraries" | tee "$out/imports.txt"
for lib in "$APP"/Contents/Frameworks/*.dylib \
  "$APP"/Contents/Frameworks/PDFium.framework/pdfium \
  "$APP"/Contents/Frameworks/FlutterMacOS.framework/FlutterMacOS; do
  syms=$(nm -u "$lib" | grep -E '^_(socket|connect|sendto|sendmsg|getaddrinfo|nw_.*|OBJC_CLASS_\$_NSURLSession.*)$' | tr '\n' ' ' || true)
  echo "$(basename "$lib"): ${syms:-none}" | tee -a "$out/imports.txt"
done

sudo -v
start=$(date '+%Y-%m-%d %H:%M:%S')
sudo tcpdump -i pktap,all -B 65536 -Q "proc =Docudis or eproc =Docudis" \
  -w "$out/docudis.pcapng" 2> "$out/tcpdump.log" &
tcpdump_pid=$!
sleep 2

echo "== Release app open for $idle s"
"$APP/Contents/MacOS/Docudis" > /dev/null 2>&1 &
app_pid=$!
sleep "$idle"
kill "$app_pid"
wait "$app_pid" || true

if [ "${FLOW:-1}" != 0 ]; then
  echo "== Integration test"
  if ! flutter test integration_test/flow_test.dart -d macos | tee "$out/flow_test.log"; then
    echo "integration test: FAILED, see flow_test.log" >> "$out/summary.txt"
  fi
fi

sleep 2
sudo kill -INT "$tcpdump_pid"
wait "$tcpdump_pid" || true

tcpdump -nn -k INP -r "$out/docudis.pcapng" > "$out/packets.txt" 2> /dev/null || true
/usr/bin/log show --start "$start" --info \
  --predicate 'process == "mDNSResponder" AND eventMessage CONTAINS "(Docudis)"' \
  | grep '(Docudis)' > "$out/dns.txt" || true
/usr/bin/log show --start "$start" \
  --predicate 'subsystem == "com.apple.sandbox.reporting" AND eventMessage CONTAINS "Sandbox: Docudis("' \
  | grep -E 'network|dnssd' > "$out/sandbox_denials.txt" || true

loopback=$(grep -c '(lo0' "$out/packets.txt" || true)
external=$(( $(wc -l < "$out/packets.txt") - loopback ))
dns=$(wc -l < "$out/dns.txt" | tr -d ' ')
denied=$(wc -l < "$out/sandbox_denials.txt" | tr -d ' ')
find "$HOME/Library/Containers/com.stonetech.docudis" \
  "$HOME/Library/Application Support/Microsoft/DeveloperTools" \
  -path '*/.onnxruntime/*' -newer "$out/imports.txt" > "$out/telemetry_files.txt" 2> /dev/null || true
telemetry=$(wc -l < "$out/telemetry_files.txt" | tr -d ' ')
dropped=$(sed -n 's/^\([0-9]*\) packets dropped by kernel$/\1/p' "$out/tcpdump.log")
{
  echo "packets to or from other machines: $external"
  echo "packets on loopback (127.0.0.1): $loopback"
  echo "DNS lookups: $dns"
  echo "network access refused by the sandbox: $denied"
  echo "ONNX Runtime telemetry files written: $telemetry"
  echo "packets tcpdump dropped (any process, uncounted): ${dropped:-unknown}"
} >> "$out/summary.txt"

echo "== Result ($out)"
cat "$out/summary.txt"
[ "$external" -eq 0 ] && [ "$dns" -eq 0 ] && [ "$denied" -eq 0 ] && [ "$telemetry" -eq 0 ]
