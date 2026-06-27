#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -eq 0 ]; then
  SUDO=()
else
  SUDO=(sudo)
fi

SCRIPT_TMPDIR="$(mktemp -d)"
trap 'rm -rf "$SCRIPT_TMPDIR"' EXIT

COMMON_PACKAGES=(
  vim
  bash
  neovim
  tmux
  grep
  stow
  nmap
  traceroute
  dig
  pciutils
  fastfetch
  kubectl
  helm
  kustomize
  qemu
  qemu-kvm
  libvirt
  virt-install
  bridge-utils
  @development-tools
  @c-development
  @editors
  @container-management
  rustup
  llvm-devel
  go
  wget
  opentofu
  @gnome-desktop
  @office
  @fonts
  keepassxc
  openvpn
  easy-rsa
  thunderbird
  wireshark
  java-25-openjdk-devel
  inotify-tools
  colordiff
  newt
  xournalpp
  tcpreplay
  tcprewrite
  libpcap-devel
  mold
  cmake
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-44.noarch.rpm
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-44.noarch.rpm
)

SWAY_PACKAGES=(
  sway
  alacritty
  bash
  mako
  waybar
  keepassxc
  wofi
  grim
  slurp
  wl-clipboard
  zathura
  pavucontrol
  virt-manager
)

install_dnf_packages() {
  "${SUDO[@]}" dnf install -y "$@"
}

install_librewolf() {
  curl -fsSL https://repo.librewolf.net/librewolf.repo \
    | "${SUDO[@]}" tee /etc/yum.repos.d/librewolf.repo >/dev/null
  install_dnf_packages librewolf
}

install_fluxcd() {
  curl -fsSL https://fluxcd.io/install.sh | "${SUDO[@]}" bash
}

install_kubeconform() {
  local tmpdir
  tmpdir="$SCRIPT_TMPDIR/kubeconform"
  mkdir -p "$tmpdir"

  curl -fsSL https://github.com/yannh/kubeconform/releases/latest/download/kubeconform-linux-amd64.tar.gz \
    | tar -xz -C "$tmpdir" kubeconform
  "${SUDO[@]}" install -m 0755 "$tmpdir/kubeconform" /usr/local/bin/kubeconform
}

install_kind() {
  local asset tmpdir

  case "$(uname -s)-$(uname -m)" in
    Linux-x86_64) asset="kind-linux-amd64" ;;
    Linux-aarch64|Linux-arm64) asset="kind-linux-arm64" ;;
    *)
      echo "Unsupported platform for kind: $(uname -s)-$(uname -m)" >&2
      return 1
      ;;
  esac

  tmpdir="$SCRIPT_TMPDIR/kind"
  mkdir -p "$tmpdir"

  curl -fsSL -o "$tmpdir/kind" "https://kind.sigs.k8s.io/dl/v0.30.0/$asset"
  "${SUDO[@]}" install -m 0755 "$tmpdir/kind" /usr/local/bin/kind
}

install_ungoogled_chromium() {
  "${SUDO[@]}" dnf copr enable -y wojnilowicz/ungoogled-chromium
  install_dnf_packages ungoogled-chromium
}

install_docker() {
  "${SUDO[@]}" dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
  install_dnf_packages docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

install_dnf_packages "${COMMON_PACKAGES[@]}"
install_dnf_packages "${SWAY_PACKAGES[@]}"

install_librewolf
install_fluxcd
install_kubeconform
install_kind
install_ungoogled_chromium
install_docker
