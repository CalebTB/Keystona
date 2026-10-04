.PHONY: setup db-start db-stop db-reset db-push app-run app-run-staging app-test app-build-apk app-build-ios app-build-ipa app-analyze app-clean codegen codegen-watch functions-serve functions-deploy check-release-env check-symbol-env symbols-upload clean-ios-stale warn-ios-debug-artifacts check-ipa-produced

APP := apps/keystona
DEFINES := dart-defines.json

# Sentry release identity — one string, two consumers.
#
# Left to their own defaults these disagree: the Flutter SDK reports
# "<bundleId>@<version>" at runtime, while sentry_dart_plugin creates
# "<pubspecName>@<version>" at upload time. The result is debug files attached
# to a release no event ever reports, so symbolication, release health and
# regression detection all silently point at the wrong thing.
#
# So compute it here and feed the SAME value to the app (--dart-define) and to
# the plugin (SENTRY_RELEASE env, which takes precedence over its pubspec
# default). Keep BUNDLE_ID in sync with android applicationId and iOS
# PRODUCT_BUNDLE_IDENTIFIER — both are com.keystona.keystona today.
BUNDLE_ID := com.keystona.keystona
APP_VERSION := $(shell sed -n 's/^version:[[:space:]]*//p' $(APP)/pubspec.yaml)
SENTRY_RELEASE := $(BUNDLE_ID)@$(APP_VERSION)
export SENTRY_RELEASE

# ─── Setup ───────────────────────────────────
setup:
	cd $(APP) && flutter pub get
	supabase start
	supabase db reset

# ─── Supabase ────────────────────────────────
db-start:
	supabase start

db-stop:
	supabase stop

db-reset:
	supabase db reset

db-push:
	supabase db push

# ─── Release preflight ───────────────────────
# dart-defines.json is gitignored, so a fresh clone or a CI runner has no copy
# of it. Without this check `flutter build` still succeeds: every
# String.fromEnvironment just resolves to its default or an empty string, and
# the app ships with crash reporting silently switched off. Fail loudly here
# instead of discovering it from an empty Sentry dashboard after release.
check-release-env:
	@test -f $(APP)/$(DEFINES) || { \
		echo "ERROR: $(APP)/$(DEFINES) is missing."; \
		echo "       It is gitignored. Copy dart-defines.example.json and fill it in."; \
		exit 1; }
	@python3 -c "import json,sys; \
d=json.load(open('$(APP)/$(DEFINES)')); \
dsn=d.get('SENTRY_DSN',''); \
missing=[k for k in ('SUPABASE_URL','SUPABASE_ANON_KEY','SENTRY_DSN') if not d.get(k)]; \
sys.exit('ERROR: $(DEFINES) missing values for: '+', '.join(missing)) if missing else None; \
sys.exit('ERROR: SENTRY_DSN looks like a placeholder (%s).\n       Get the real DSN from Sentry > Settings > Client Keys.' % dsn) if '/123' in dsn or 'ingest' not in dsn else None" \
		|| exit 1
	@test -n "$(APP_VERSION)" || { \
		echo "ERROR: could not read 'version:' from $(APP)/pubspec.yaml."; \
		echo "       SENTRY_RELEASE would become '$(BUNDLE_ID)@' and artifacts"; \
		echo "       would attach to a release no event reports."; \
		exit 1; }
	@echo "release env OK — SENTRY_DSN present, APP_ENV forced to production below"
	@echo "release id: $(SENTRY_RELEASE)"

# iOS debug builds leave Runner.debug.dylib and __preview.dylib inside
# build/ios/iphoneos/Runner.app, and sentry_dart_plugin scans that path
# UNCONDITIONALLY (see flutter_debug_files.dart). So a stale debug build gets
# published as if it were the shipping binary: the upload succeeds, the
# ignore_missing guard never fires because files *are* present, and iOS crashes
# silently fail to symbolicate.
#
# That is not hypothetical — the first "successful" upload sent a four-month-old
# debug build whose App.framework was a 35KB JIT stub instead of AOT code.
#
# Release targets wipe the directory first so the only thing there is the build
# that just ran.
clean-ios-stale:
	@rm -rf $(APP)/build/ios/iphoneos $(APP)/build/ios/Release-iphoneos

# Warns instead of failing, because symbols-upload also runs after Android-only
# builds where a leftover iOS debug directory has no bearing on what shipped.
#
# Scoped deliberately to build/ios/iphoneos. Debug-iphoneos and the simulator
# directories also contain Runner.debug.dylib, but the plugin never scans them
# (its iOS roots are iphoneos/Runner.app, Release-*-iphoneos, archive, and
# framework/Release*), so matching those would warn about files that can never
# be uploaded — and a guard that cries wolf is worse than no guard.
warn-ios-debug-artifacts:
	@if [ -f $(APP)/build/ios/iphoneos/Runner.app/Runner.debug.dylib ]; then \
		echo ""; \
		echo "WARNING: a DEBUG iOS build exists under $(APP)/build/ios."; \
		echo "         sentry_dart_plugin will upload it alongside real symbols."; \
		echo "         Harmless for an Android release, but do NOT read this run"; \
		echo "         as iOS coverage. Ship iOS via 'make app-build-ipa'."; \
		echo ""; \
	fi

# Symbol upload needs a token the app itself never sees. Missing it makes
# sentry_dart_plugin fail rather than silently ship unsymbolicated builds.
check-symbol-env:
	@test -n "$$SENTRY_AUTH_TOKEN" || { \
		echo "ERROR: SENTRY_AUTH_TOKEN is not set."; \
		echo "       Create one at Sentry > Settings > Auth Tokens with project:releases scope,"; \
		echo "       then: export SENTRY_AUTH_TOKEN=... (or set it in CI secrets)."; \
		echo "       It is build-time only and must never be embedded in the app."; \
		exit 1; }

# ─── Flutter App ─────────────────────────────
# Dev run. Passes APP_ENV=development explicitly — it is no longer in
# dart-defines.json, because a default of 'development' living in a file is
# exactly what let release builds ship with Sentry switched off. Debug builds
# are held back by kReleaseMode regardless; this is belt and braces.
app-run:
	cd $(APP) && flutter run --dart-define-from-file=$(DEFINES) \
		--dart-define=APP_ENV=development

# Dev run WITH Sentry active, for testing instrumentation locally.
# The trailing --dart-define overrides the value in the file.
app-run-staging:
	cd $(APP) && flutter run --dart-define-from-file=$(DEFINES) \
		--dart-define=APP_ENV=staging \
		--dart-define=SENTRY_RELEASE=$(SENTRY_RELEASE)

app-test:
	cd $(APP) && flutter test

# Release builds force APP_ENV=production so SentryInit.isEnabled passes.
# Without this they inherit APP_ENV=development from the file and ship with
# crash reporting off — the bug this target previously had.
app-build-apk: check-release-env check-symbol-env
	cd $(APP) && flutter build apk --release \
		--dart-define-from-file=$(DEFINES) \
		--dart-define=APP_ENV=production \
		--dart-define=SENTRY_RELEASE=$(SENTRY_RELEASE)
	$(MAKE) symbols-upload

app-build-ios: check-release-env check-symbol-env clean-ios-stale
	cd $(APP) && flutter build ios --release \
		--dart-define-from-file=$(DEFINES) \
		--dart-define=APP_ENV=production \
		--dart-define=SENTRY_RELEASE=$(SENTRY_RELEASE)
	$(MAKE) symbols-upload

# THE iOS shipping path — use this, not an Xcode archive.
#
# Archiving by hand in Xcode does not pass --dart-define, so SENTRY_DSN resolves
# empty and the App Store build ships with Sentry entirely absent, silently.
# This target bakes the defines in AND produces build/ios/archive/Runner.xcarchive,
# whose dSYMs directory the plugin scans (flutter_debug_files.dart yields
# '$$buildDir/ios/archive'), so the symbols uploaded are the ones in the binary
# you actually submit.
app-build-ipa: check-release-env check-symbol-env clean-ios-stale
	cd $(APP) && flutter build ipa --release \
		--dart-define-from-file=$(DEFINES) \
		--dart-define=APP_ENV=production \
		--dart-define=SENTRY_RELEASE=$(SENTRY_RELEASE)
	$(MAKE) symbols-upload
	$(MAKE) check-ipa-produced

# `flutter build ipa` prints "Encountered error while creating the IPA" and then
# EXITS 0 when exportArchive fails — missing iOS Distribution certificate, an
# unaccepted Program License Agreement, no matching provisioning profile. make
# therefore reports success with nothing shippable: the exact silent-failure
# shape this target exists to prevent. Assert the artifact rather than trusting
# the exit code.
#
# Deliberately runs AFTER symbols-upload: the archive did compile, so its dSYMs
# are valid for that build and worth keeping even when the export step fails.
check-ipa-produced:
	@ls $(APP)/build/ios/ipa/*.ipa >/dev/null 2>&1 || { \
		echo ""; \
		echo "ERROR: the archive compiled and its dSYMs uploaded, but no .ipa"; \
		echo "       was exported — there is nothing to submit."; \
		echo "       Both usual causes are fixed at developer.apple.com:"; \
		echo "         - no 'iOS Distribution' signing certificate exists"; \
		echo "         - the Program License Agreement needs accepting"; \
		echo ""; \
		exit 1; }

# Uploads whatever debug files the preceding build produced. Must run AFTER the
# build and from the SAME build that ships — a local upload paired with a
# CI-built binary leaves artifacts that do not match the running code.
symbols-upload: check-symbol-env warn-ios-debug-artifacts
	cd $(APP) && dart run sentry_dart_plugin

app-analyze:
	cd $(APP) && flutter analyze

app-clean:
	cd $(APP) && flutter clean && flutter pub get

# ─── Code Generation ─────────────────────────
codegen:
	cd $(APP) && dart run build_runner build --delete-conflicting-outputs

codegen-watch:
	cd $(APP) && dart run build_runner watch --delete-conflicting-outputs

# ─── Edge Functions ──────────────────────────
functions-serve:
	supabase functions serve --no-verify-jwt

functions-deploy:
	supabase functions deploy
