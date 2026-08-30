#!/usr/bin/env bash

set -euo pipefail

shellcheck --shell=bash --external-sources \
	bin/* --source-path=lib/ \
	lib/* \
	scripts/*

shfmt --language-dialect bash --diff \
	./**/*
