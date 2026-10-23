# Common commands. Everything runs in the dev container via tool/dev.
# `make` or `make help` lists the targets.

DEV := tool/dev
# Google Maven answers 404 from Iran; override with `make MAVEN_MIRROR= build`.
export MAVEN_MIRROR ?= https://maven.myket.ir
FLAVOR ?= apk
# Phone serial for `make install` (see `make devices`); empty means the only device.
SERIAL ?=
APK := app/build/app/outputs/flutter-apk/app-$(FLAVOR)-debug.apk
# A single test file or directory, e.g. `make test-app T=test/ui/session_flow_test.dart`.
T ?=

.DEFAULT_GOAL := help
.PHONY: help get analyze test test-core test-server test-server-fast test-app goldens \
        gen gen-l10n check up down build build-all install run devices server-image clean

help: ## List the targets
	@grep -E '^[a-z0-9-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

get: ## Fetch Dart and Flutter packages
	$(DEV) flutter pub get

analyze: ## Analyze core, server and app (as CI does)
	$(DEV) sh -c 'dart analyze packages/core server && cd app && flutter analyze'

test: test-core test-server test-app ## Run every test suite (server needs `make up`)

test-core: ## Core unit tests (T=file to run one)
	$(DEV) sh -c 'cd packages/core && dart test $(T)'

test-server: ## Server tests, including Postgres (needs `make up`)
	$(DEV) sh -c 'cd server && dart test $(T)'

test-server-fast: ## Server tests without Postgres
	$(DEV) sh -c 'cd server && dart test -x postgres $(T)'

test-app: ## App unit, widget and golden tests (T=file to run one)
	$(DEV) sh -c 'cd app && flutter test $(T)'

goldens: ## Re-render golden screenshots (T=file to limit)
	$(DEV) sh -c 'cd app && flutter test --update-goldens $(T)'

gen: ## Regenerate drift code (app_database.g.dart)
	$(DEV) sh -c 'cd app && dart run build_runner build --delete-conflicting-outputs'

gen-l10n: ## Regenerate app_localizations*.dart from the .arb files
	$(DEV) sh -c 'cd app && flutter gen-l10n'

check: get analyze up test build-all ## Everything CI checks

up: ## Start Postgres, the server and ntfy
	docker compose up -d --wait

down: ## Stop the compose services
	docker compose down

server-image: ## Build the server image
	docker compose build server

build: ## Debug APK for FLAVOR (apk|play|bazaar)
	$(DEV) sh -c 'cd app && flutter build apk --debug --flavor $(FLAVOR)'

build-all: ## Debug APKs for every flavour
	$(DEV) sh -c 'cd app && for f in apk play bazaar; do flutter build apk --debug --flavor $$f || exit 1; done'

# Replaces in place so the app keeps its data; never `flutter install`, which uninstalls first.
install: build ## Build, then install on the phone keeping its data
	$(DEV) adb $(if $(SERIAL),-s $(SERIAL)) install -r $(APK)

run: ## Run on the phone with hot reload
	$(DEV) sh -c 'cd app && flutter run --flavor $(FLAVOR)'

devices: ## List connected phones
	$(DEV) adb devices -l

clean: ## Remove build outputs
	$(DEV) sh -c 'cd app && flutter clean'
