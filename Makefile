SHELL := /bin/bash
.DEFAULT_GOAL := help

PYTHON ?= python3
BASH ?= bash

REPO ?= $(GITHUB_REPOSITORY)
LABELS_FILE ?= config/project/labels.json
MILESTONES_FILE ?= config/project/milestones.json
PROJECT_FILE ?= config/project/project-definition.json
BACKLOG_FILE ?= config/stories/backlog-manifest.json
PROJECT_NUMBER ?=
OWNER ?=
ISSUE_NUMBER ?=
ISSUE_STATE ?= open
TITLE ?=
BODY ?=
BODY_FILE ?=
LABELS ?=
ADD_LABELS ?=
REMOVE_LABELS ?=
DRY_RUN ?= true
LINK_SUBISSUES ?= false
CLEAR_NOT_PLANNED ?= false
ONLY_LINK_SUBISSUES ?= false
RUN_LABELS ?= true
RUN_MILESTONES ?= true
RUN_PROJECT ?= true
RUN_ISSUES ?= true

define require_repo
	@test -n "$(REPO)" || { echo "Missing REPO. Set REPO or GITHUB_REPOSITORY."; exit 1; }
endef

define require_issue_number
	@test -n "$(ISSUE_NUMBER)" || { echo "Missing ISSUE_NUMBER."; exit 1; }
endef

define require_project_number
	@test -n "$(PROJECT_NUMBER)" || { echo "Missing PROJECT_NUMBER."; exit 1; }
endef

define require_title
	@test -n "$(TITLE)" || { echo "Missing TITLE."; exit 1; }
endef

.PHONY: help setup labels_sync milestones_sync project_create project_sync issues_generate issue_milestones_sync bootstrap_local issue_create issue_update issue_delete

help:
	@printf '%s\n' \
		'Governance make targets:' \
		'  make labels_sync' \
		'  make milestones_sync' \
		'  make project_create' \
		'  make project_sync PROJECT_NUMBER=123' \
		'  make issues_generate' \
		'  make issue_milestones_sync' \
		'  make bootstrap_local' \
		'  make issue_create TITLE="..." BODY_FILE=... LABELS="status:backlog type:task"' \
		'  make issue_update ISSUE_NUMBER=123 TITLE="..." ADD_LABELS="priority:high"' \
		'  make issue_delete ISSUE_NUMBER=123' \
		'' \
		'Common variables:' \
		'  REPO, LABELS_FILE, MILESTONES_FILE, PROJECT_FILE, BACKLOG_FILE' \
		'  DRY_RUN=true|false, LINK_SUBISSUES=true|false' \
		'  RUN_LABELS=true|false, RUN_MILESTONES=true|false, RUN_PROJECT=true|false, RUN_ISSUES=true|false' \
		'  ADD_LABELS and REMOVE_LABELS accept space- or comma-separated lists'

labels_sync:
	$(call require_repo)
	@set -euo pipefail; \
	args=($(PYTHON) scripts/github/labels/sync.py --repo "$(REPO)" --file "$(LABELS_FILE)"); \
	if [[ "$(DRY_RUN)" == "true" ]]; then args+=(--dry-run); fi; \
	"$${args[@]}"

milestones_sync:
	$(call require_repo)
	@set -euo pipefail; \
	args=($(PYTHON) scripts/github/milestones/sync.py --repo "$(REPO)" --file "$(MILESTONES_FILE)"); \
	if [[ "$(DRY_RUN)" == "true" ]]; then args+=(--dry-run); fi; \
	"$${args[@]}"

project_create:
	$(call require_repo)
	@set -euo pipefail; \
	args=($(PYTHON) scripts/github/project/create.py "$(PROJECT_FILE)" --repo "$(REPO)"); \
	if [[ "$(DRY_RUN)" == "true" ]]; then args+=(--dry-run); fi; \
	"$${args[@]}"

project_sync:
	$(call require_repo)
	$(call require_project_number)
	@set -euo pipefail; \
	args=($(PYTHON) scripts/github/project/sync.py "$(PROJECT_FILE)" --repo "$(REPO)" --project-number "$(PROJECT_NUMBER)" --issue-state "$(ISSUE_STATE)"); \
	if [[ -n "$(OWNER)" ]]; then args+=(--owner "$(OWNER)"); fi; \
	if [[ "$(LINK_SUBISSUES)" == "true" ]]; then args+=(--link-subissues); fi; \
	if [[ "$(ONLY_LINK_SUBISSUES)" == "true" ]]; then args+=(--only-link-subissues); fi; \
	if [[ "$(DRY_RUN)" == "true" ]]; then args+=(--dry-run); fi; \
	"$${args[@]}"

issues_generate:
	$(call require_repo)
	@set -euo pipefail; \
	args=($(PYTHON) scripts/github/issues/generate.py "$(BACKLOG_FILE)" --repo "$(REPO)"); \
	if [[ "$(DRY_RUN)" == "true" ]]; then args+=(--dry-run); fi; \
	if [[ "$(DRY_RUN)" == "false" && "$(LINK_SUBISSUES)" == "true" ]]; then args+=(--link-subissues); fi; \
	"$${args[@]}"

issue_milestones_sync:
	$(call require_repo)
	@set -euo pipefail; \
	args=($(PYTHON) scripts/github/issue_milestones/sync.py --repo "$(REPO)"); \
	if [[ "$(CLEAR_NOT_PLANNED)" == "true" ]]; then args+=(--clear-not-planned); fi; \
	if [[ "$(DRY_RUN)" == "true" ]]; then args+=(--dry-run); fi; \
	"$${args[@]}"

bootstrap_local:
	$(call require_repo)
	@set -euo pipefail; \
	args=($(BASH) scripts/github/bootstrap/local.sh --repo "$(REPO)"); \
	if [[ "$(DRY_RUN)" == "true" ]]; then args+=(--dry-run); else args+=(--no-dry-run); fi; \
	if [[ "$(RUN_LABELS)" == "false" ]]; then args+=(--skip-labels); fi; \
	if [[ "$(RUN_MILESTONES)" == "false" ]]; then args+=(--skip-milestones); fi; \
	if [[ "$(RUN_PROJECT)" == "false" ]]; then args+=(--skip-project); fi; \
	if [[ "$(RUN_ISSUES)" == "false" ]]; then args+=(--skip-issues); fi; \
	if [[ "$(LINK_SUBISSUES)" == "true" ]]; then args+=(--link-subissues); fi; \
	"$${args[@]}"

issue_create:
	$(call require_repo)
	$(call require_title)
	@set -euo pipefail; \
	cmd=(gh issue create --repo "$(REPO)" --title "$(TITLE)"); \
	if [[ -n "$(BODY_FILE)" ]]; then \
		cmd+=(--body-file "$(BODY_FILE)"); \
	else \
		cmd+=(--body "$(BODY)"); \
	fi; \
	add_labels() { \
		local raw="$${1:-}"; \
		raw="$${raw//,/ }"; \
		for item in $$raw; do \
			[[ -n "$$item" ]] && cmd+=(--label "$$item"); \
		done; \
	}; \
	add_labels "$(LABELS)"; \
	"$${cmd[@]}"

issue_update:
	$(call require_repo)
	$(call require_issue_number)
	@set -euo pipefail; \
	cmd=(gh issue edit "$(ISSUE_NUMBER)" --repo "$(REPO)"); \
	if [[ -n "$(TITLE)" ]]; then \
		cmd+=(--title "$(TITLE)"); \
	fi; \
	if [[ -n "$(BODY_FILE)" ]]; then \
		cmd+=(--body-file "$(BODY_FILE)"); \
	elif [[ -n "$(BODY)" ]]; then \
		cmd+=(--body "$(BODY)"); \
	fi; \
	add_labels() { \
		local flag="$${1:-}"; \
		local raw="$${2:-}"; \
		raw="$${raw//,/ }"; \
		for item in $$raw; do \
			[[ -n "$$item" ]] && cmd+=("$$flag" "$$item"); \
		done; \
	}; \
	add_labels --add-label "$(ADD_LABELS)"; \
	add_labels --remove-label "$(REMOVE_LABELS)"; \
	"$${cmd[@]}"

issue_delete:
	$(call require_repo)
	$(call require_issue_number)
	@gh issue delete "$(ISSUE_NUMBER)" --repo "$(REPO)" --yes
