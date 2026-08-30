#!/usr/bin/env bash
#
# Cloud Agent environment bootstrap for Apache NuttX.
#
# Installs the host toolchain and build tools required to configure and build
# NuttX, clones the companion nuttx-apps repository as a sibling directory
# (aligned to the checked-out NuttX revision), and builds the sim:nsh
# configuration so the simulator is ready to run.
#
# The script is idempotent: it can be re-run safely against a partially
# prepared workspace.

set -euo pipefail

NUTTX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPS_PARENT="$(dirname "$NUTTX_DIR")"
APPS_DIR="$(realpath -m "$APPS_PARENT/apps")"
APPS_REMOTE="https://github.com/apache/nuttx-apps.git"

echo "==> NuttX directory: $NUTTX_DIR"
echo "==> Apps directory:  $APPS_DIR"

###############################################################################
# 1. System packages
###############################################################################
# genromfs and xxd generate the NSH ROMFS "/etc" image; bison/flex/gperf and
# libncurses back the kconfig-frontends configuration tools.
echo "==> Installing system packages"
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
  bison \
  build-essential \
  cmake \
  flex \
  gawk \
  genromfs \
  gperf \
  git \
  libncurses-dev \
  libtool \
  ninja-build \
  pkg-config \
  xxd

###############################################################################
# 2. Host compiler
###############################################################################
# The sim:nsh configuration selects the GCC toolchain (CONFIG_SIM_TOOLCHAIN_GCC)
# and the build invokes the generic "cc". On images where "cc" defaults to
# clang, point it at gcc so the intended toolchain is used.
if update-alternatives --query cc >/dev/null 2>&1; then
  if command -v gcc >/dev/null 2>&1; then
    sudo update-alternatives --set cc "$(command -v gcc)" || true
  fi
fi

###############################################################################
# 3. kconfig-frontends
###############################################################################
# Not packaged for recent Ubuntu releases, so build it from the NuttX tools
# bundle (same source and revision used by the project's CI image).
if ! command -v kconfig-conf >/dev/null 2>&1; then
  echo "==> Building kconfig-frontends from source"
  KCONFIG_REV="9ad3e1ee75c7d39bfee8019ce44f4fd035d89584"
  TMP_TOOLS="$(mktemp -d)"
  curl -s -L "https://github.com/patacongo/tools/archive/${KCONFIG_REV}.tar.gz" \
    | tar -C "$TMP_TOOLS" --strip-components=1 -xz
  (
    cd "$TMP_TOOLS/kconfig-frontends"
    ./configure \
      --enable-mconf --disable-gconf --disable-qconf \
      --enable-static --prefix=/usr/local
    make
    sudo make install
  )
  sudo ldconfig
  rm -rf "$TMP_TOOLS"
else
  echo "==> kconfig-frontends already installed"
fi

###############################################################################
# 4. Companion apps repository
###############################################################################
# NuttX expects the applications in a sibling "apps" directory. The apps and
# NuttX trees must stay API compatible, so pin apps to the revision that
# matches this NuttX snapshot. NuttX and nuttx-apps track together on master;
# this is the nuttx-apps commit contemporary with the NuttX source here
# (nuttx-apps master as of 2026-08-19). Bump APPS_REV when advancing NuttX.
APPS_REV="${NUTTX_APPS_REV:-191e244082c50730063d53ab8ff53cf3802a08ab}"

if [ ! -d "$APPS_DIR/.git" ]; then
  echo "==> Cloning nuttx-apps into $APPS_DIR"
  if [ ! -w "$APPS_PARENT" ]; then
    sudo mkdir -p "$APPS_DIR"
    sudo chown "$(id -u):$(id -g)" "$APPS_DIR"
  fi
  git clone "$APPS_REMOTE" "$APPS_DIR"
fi

echo "==> Checking out apps revision $APPS_REV"
git -C "$APPS_DIR" fetch --quiet origin
git -C "$APPS_DIR" checkout -q "$APPS_REV"

###############################################################################
# 5. Configure and build the simulator
###############################################################################
cd "$NUTTX_DIR"
if [ ! -f .config ]; then
  echo "==> Configuring sim:nsh"
  ./tools/configure.sh sim:nsh
fi

echo "==> Building"
make -j"$(nproc)"

echo "==> Done. Run the simulator with: ./nuttx"
