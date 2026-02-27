.PHONY: setup db-start db-stop db-reset app-run app-test app-build-apk app-build-ios app-analyze app-clean codegen codegen-watch functions-serve functions-deploy

# ─── Setup ───────────────────────────────────
setup:
	cd apps/keystona && flutter pub get
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

# ─── Flutter App ─────────────────────────────
app-run:
	cd apps/keystona && flutter run --dart-define-from-file=dart-defines.json

app-test:
	cd apps/keystona && flutter test

app-build-apk:
	cd apps/keystona && flutter build apk --release --dart-define-from-file=dart-defines.json

app-build-ios:
	cd apps/keystona && flutter build ios --release --dart-define-from-file=dart-defines.json

app-analyze:
	cd apps/keystona && flutter analyze

app-clean:
	cd apps/keystona && flutter clean && flutter pub get

# ─── Code Generation ─────────────────────────
codegen:
	cd apps/keystona && dart run build_runner build --delete-conflicting-outputs

codegen-watch:
	cd apps/keystona && dart run build_runner watch --delete-conflicting-outputs

# ─── Edge Functions ──────────────────────────
functions-serve:
	supabase functions serve --no-verify-jwt

functions-deploy:
	supabase functions deploy
