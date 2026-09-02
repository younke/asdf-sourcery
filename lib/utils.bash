#!/usr/bin/env bash

set -euo pipefail

GH_REPO="https://github.com/krzysztofzablocki/Sourcery"
GH_API_REPO="https://api.github.com/repos/krzysztofzablocki/Sourcery"
TOOL_NAME="sourcery"
TOOL_TEST="sourcery --version"

fail() {
	# stderr, not stdout: these functions are called inside command
	# substitutions, which would otherwise capture the message instead of
	# showing it.
	echo -e "asdf-$TOOL_NAME: $*" >&2
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
	local kernel
	kernel="$(uname -s)"

	case "$kernel" in
	Darwin)
		echo "macos"
		;;
	Linux)
		echo "linux"
		;;
	*)
		fail "Unsupported OS: $kernel"
		;;
	esac
}

# Normalise uname -m to the spelling upstream uses in its Linux asset names,
# so the value that selects an asset is the same one that is validated here.
get_arch() {
	local machine
	machine="$(uname -m)"

	case "$machine" in
	x86_64 | amd64)
		echo "x86_64"
		;;
	*)
		fail "Unsupported Linux architecture: $machine. Upstream publishes x86_64 Linux binaries only."
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
	local arch release_json asset_url

	arch="$(get_arch)"

	# gh_api reports its own failure; exit rather than fall through to the
	# "no such asset" message below, which would misattribute the cause.
	release_json="$(gh_api "releases/tags/${version}")" || exit 1

	# Sorting keeps the choice independent of the order the API happens to
	# return assets in. Should upstream ever publish more than one Linux
	# archive, the lowest Ubuntu release sorts first, which is also the build
	# linked against the oldest glibc and so the most portable one.
	asset_url="$(printf '%s\n' "$release_json" |
		grep -o '"browser_download_url": *"[^"]*"' |
		sed 's/.*"browser_download_url": *"\([^"]*\)"/\1/' |
		grep -E '(linux|ubuntu)' |
		grep -F -- "$arch" |
		grep -E '\.tar\.xz$' |
		LC_ALL=C sort |
		head -n 1)" || true

	if [ -z "$asset_url" ]; then
		fail "Could not find a Linux $arch archive for $TOOL_NAME $version.\nUpstream ships Linux binaries for recent releases only."
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
		url="$(get_linux_asset_url "$version")" || exit 1
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

		# The Linux binary is dynamically linked against the Swift runtime,
		# which this plugin cannot install. Say so now rather than leave a
		# binary that fails on every later invocation. Only a warning: the
		# runtime may still be put on the library path afterwards.
		if ! "$install_path/$tool_cmd" --version >/dev/null 2>&1; then
			echo "asdf-$TOOL_NAME: warning: $tool_cmd was installed but does not run here." >&2
			echo "asdf-$TOOL_NAME: on Linux it needs a Swift 5.10 runtime on the library path." >&2
		fi

		echo "$TOOL_NAME $version installation was successful!"
	) || (
		rm -rf "$install_path"
		fail "An error occurred while installing $TOOL_NAME $version."
	)
}
