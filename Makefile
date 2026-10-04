.PHONY: setup db-start db-stop db-reset db-push app-run app-run-staging app-test app-build-apk app-build-ios app-analyze app-clean codegen codegen-watch functions-serve functions-deploy check-release-env

APP := apps/keystona
DEFINES := dart-defines.json

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
	@echo "release env OK — SENTRY_DSN present, APP_ENV forced to production below"

# ─── Flutter App ─────────────────────────────
# Dev run. APP_ENV stays whatever dart-defines.json says (development), which
# keeps Sentry disabled so hot reloads don't spend quota or bury real issues.
app-run:
	cd $(APP) && flutter run --dart-define-from-file=$(DEFINES)

# Dev run WITH Sentry active, for testing instrumentation locally.
# The trailing --dart-define overrides the value in the file.
app-run-staging:
	cd $(APP) && flutter run --dart-define-from-file=$(DEFINES) --dart-define=APP_ENV=staging

app-test:
	cd $(APP) && flutter test

# Release builds force APP_ENV=production so SentryInit.isEnabled passes.
# Without this they inherit APP_ENV=development from the file and ship with
# crash reporting off — the bug this target previously had.
app-build-apk: check-release-env
	cd $(APP) && flutter build apk --release \
		--dart-define-from-file=$(DEFINES) \
		--dart-define=APP_ENV=production

app-build-ios: check-release-env
	cd $(APP) && flutter build ios --release \
		--dart-define-from-file=$(DEFINES) \
		--dart-define=APP_ENV=production

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
