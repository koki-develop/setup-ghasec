#!/usr/bin/env bash
set -euo pipefail

# --- Version Resolution ---

version="${INPUT_VERSION}"

curl_args=(-L)
if [ -n "${GITHUB_TOKEN:-}" ]; then
  curl_args+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

if [ "${version}" = "latest" ]; then
  version=$(curl -sf "${curl_args[@]}" "https://api.github.com/repos/koki-develop/ghasec/releases/latest" | jq -r '.tag_name') || {
    echo "::error::Failed to fetch latest release from GitHub API"
    exit 1
  }
  if [ -z "${version}" ] || [ "${version}" = "null" ]; then
    echo "::error::Failed to parse latest version from GitHub API response"
    exit 1
  fi
fi

# Strip v prefix if present (from user input like "v0.1.0" or API response like "v0.1.0")
version="${version#v}"

echo "Installing ghasec v${version}..."

# --- Platform Detection ---

case "${RUNNER_OS}" in
  Linux)   os="Linux" ;;
  macOS)   os="Darwin" ;;
  Windows) os="Windows" ;;
  *)
    echo "::error::Unsupported OS: ${RUNNER_OS}"
    exit 1
    ;;
esac

case "${RUNNER_ARCH}" in
  X64)   arch="x86_64" ;;
  X86)   arch="i386" ;;
  ARM64) arch="arm64" ;;
  *)
    echo "::error::Unsupported architecture: ${RUNNER_ARCH}"
    exit 1
    ;;
esac

if [ "${os}" = "Windows" ]; then
  ext="zip"
else
  ext="tar.gz"
fi

archive_name="ghasec_${os}_${arch}.${ext}"

# --- Download ---

base_url="https://github.com/koki-develop/ghasec/releases/download/v${version}"
install_dir="${RUNNER_TEMP}/ghasec"
mkdir -p "${install_dir}"

echo "Downloading ${archive_name}..."
http_code=$(curl -s "${curl_args[@]}" -w "%{http_code}" -o "${install_dir}/${archive_name}" "${base_url}/${archive_name}")
if [ "${http_code}" -ne 200 ]; then
  if [ "${http_code}" -eq 404 ]; then
    echo "::error::ghasec v${version} is not available for ${RUNNER_OS}/${RUNNER_ARCH}"
  else
    echo "::error::Failed to download ${base_url}/${archive_name} (HTTP ${http_code})"
  fi
  exit 1
fi

checksums_name="ghasec_${version}_checksums.txt"
echo "Downloading ${checksums_name}..."
curl -sf "${curl_args[@]}" -o "${install_dir}/checksums.txt" "${base_url}/${checksums_name}" || {
  echo "::error::Failed to download ${base_url}/${checksums_name}"
  exit 1
}

# --- Checksum Verification ---

expected_hash=$(awk -v name="${archive_name}" '$2 == name { print $1 }' "${install_dir}/checksums.txt")
if [ -z "${expected_hash}" ]; then
  echo "::error::Checksum for ${archive_name} not found in checksums.txt"
  exit 1
fi

if command -v sha256sum &> /dev/null; then
  actual_hash=$(sha256sum "${install_dir}/${archive_name}" | awk '{gsub(/^\\/, "", $1); print $1}')
elif command -v shasum &> /dev/null; then
  actual_hash=$(shasum -a 256 "${install_dir}/${archive_name}" | awk '{gsub(/^\\/, "", $1); print $1}')
else
  echo "::error::Neither sha256sum nor shasum is available"
  exit 1
fi

if [ "${actual_hash}" != "${expected_hash}" ]; then
  echo "::error::Checksum verification failed for ${archive_name}"
  echo "::error::Expected: ${expected_hash}"
  echo "::error::Actual:   ${actual_hash}"
  exit 1
fi

echo "Checksum verified."

# --- Extract and Add to PATH ---

echo "Extracting ${archive_name}..."
if [ "${ext}" = "zip" ]; then
  unzip -q "${install_dir}/${archive_name}" -d "${install_dir}" || {
    echo "::error::Failed to extract ${archive_name}"
    exit 1
  }
else
  tar xzf "${install_dir}/${archive_name}" -C "${install_dir}" || {
    echo "::error::Failed to extract ${archive_name}"
    exit 1
  }
fi

echo "${install_dir}" >> "${GITHUB_PATH}"

echo "ghasec v${version} installed successfully."
