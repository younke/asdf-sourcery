#!/usr/bin/env bash

set -euo pipefail

GH_REPO="https://github.com/krzysztofzablocki/Sourcery"
GH_API_REPO="https://api.github.com/repos/krzysztofzablocki/Sourcery"
TOOL_NAME="sourcery"
TOOL_TEST="sourcery --version"

fail() {
	echo -e "asdf-$TOOL_NAME: $*"
	exit 1
}

curl_opts=(-fsSL)

# asdf sets GITHUB_API_TOKEN when a plugin runs, mise and GitHub Actions set
# GITHUB_TOKEN. Either one lifts the anonymous GitHub API rate limit.
gh_token="${GITHUB_API_TOKEN:-${GITHUB_TOKEN:-}}"

if [ -n "$gh_token" ]; then
	curl_opts=("${curl_opts[@]}" -H "Authorization: token $gh_token")
fi

# Detect the platform to install for.
# Returns: "macos" | "linux", or fails on unsupported platforms.
get_platform() {
	local kernel machine
	kernel="$(uname -s)"
	machine="$(uname -m)"

	case "$kernel" in
	Darwin)
		echo "macos"
		;;
	Linux)
		case "$machine" in
		x86_64 | amd64)
			echo "linux"
			;;
		*)
			fail "Unsupported Linux architecture: $machine. Upstream publishes x86_64 Linux binaries only."
			;;
		esac
		;;
	*)
		fail "Unsupported OS: $kernel"
		;;
	esac
}

sort_versions() {
	sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
		LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

list_github_tags() {
	git ls-remote --tags --refs "$GH_REPO" |
		grep -o 'refs/tags/.*' | cut -d/ -f3- |
		sed 's/^v//'
}

list_all_versions() {
	list_github_tags
}

ignore_invalid_versions() {
	# drop first 5 versions after sorting
	# 0.1.0 0.1.1 0.2.0 0.2.1 0.2.2
	# version 0.3.0 is downloadable
	cut -d ' ' -f 6-
}

# Query the GitHub API, failing loudly when the request does not succeed so
# that rate limits and network errors do not surface as "version not found".
gh_api() {
	local path="$1"
	local response

	if ! response="$(curl "${curl_opts[@]}" "$GH_API_REPO/$path")"; then
		fail "Could not query the GitHub API at $GH_API_REPO/$path.\nSet GITHUB_API_TOKEN if you are being rate limited."
	fi

	printf '%s' "$response"
}

# Find the Linux archive attached to a release. Upstream builds it on Ubuntu,
# so the file name carries the Ubuntu release it was built on, for example
# sourcery-2.3.0-ubuntu-22.04.5-lts-jammy-x86_64.tar.xz.
get_linux_asset_url() {
	local version="$1"
	local machine release_json asset_url

	machine="$(uname -m)"
	release_json="$(gh_api "releases/tags/${version}")"

	asset_url="$(printf '%s\n' "$release_json" |
		grep -o '"browser_download_url": *"[^"]*"' |
		sed 's/.*"browser_download_url": *"\([^"]*\)"/\1/' |
		grep -E '(linux|ubuntu)' |
		grep -F -- "$machine" |
		grep -E '\.tar\.xz$' |
		head -n 1)" || true

	if [ -z "$asset_url" ]; then
		fail "Could not find a Linux $machine archive for $TOOL_NAME $version.\nUpstream ships Linux binaries for recent releases only."
	fi

	printf '%s\n' "$asset_url"
}

download_release() {
	local version filename url platform
	version="$1"
	filename="$2"
	platform="$(get_platform)"

	case "$platform" in
	macos)
		url="$GH_REPO/releases/download/${version}/${TOOL_NAME}-${version}.zip"
		;;
	linux)
		url="$(get_linux_asset_url "$version")"
		;;
	*)
		fail "Unsupported platform: $platform"
		;;
	esac

	echo "* Downloading $TOOL_NAME release $version..."
	# Release assets redirect to a host that rejects requests carrying an
	# Authorization header, so they are fetched without one.
	curl -fsSL -o "$filename" "$url" || fail "Could not download $url"
}

install_version() {
	local install_type="$1"
	local version="$2"
	local install_path="${3%/bin}/bin"

	if [ "$install_type" != "version" ]; then
		fail "asdf-$TOOL_NAME supports release installs only"
	fi

	(
		mkdir -p "$install_path"

		# Handle different archive structures per platform
		local platform
		platform="$(get_platform)"

		case "$platform" in
		macos)
			# macOS archive has bin/sourcery
			cp -r "${ASDF_DOWNLOAD_PATH}/bin/${TOOL_NAME}" "$install_path"
			;;
		linux)
			# Ubuntu archive has sourcery at root
			cp -r "${ASDF_DOWNLOAD_PATH}/${TOOL_NAME}" "$install_path"
			;;
		*)
			fail "Unsupported platform: $platform"
			;;
		esac

		local tool_cmd
		tool_cmd="$(echo "$TOOL_TEST" | cut -d' ' -f1)"
		test -x "$install_path/$tool_cmd" || fail "Expected $install_path/$tool_cmd to be executable."

		echo "$TOOL_NAME $version installation was successful!"
	) || (
		rm -rf "$install_path"
		fail "An error occurred while installing $TOOL_NAME $version."
	)
}
