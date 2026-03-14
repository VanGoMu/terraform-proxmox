#!/usr/bin/env bash
# =============================================================================
# create_template.sh — Crea el template Debian 13 (Trixie) cloud-init en Proxmox
#
# PREREQUISITO: Ejecutar en el nodo Proxmox (como root) ANTES de terraform apply.
# El VMID generado debe coincidir con template_vm_id en terraform.tfvars.
#
# Uso:
#   bash create_template.sh [-i VMID] [-s STORAGE] [-b BRIDGE] [-n NOMBRE] [-h]
#
# Ejemplo:
#   bash create_template.sh -i 9000 -s local-lvm -b vmbr0
# =============================================================================

set -euo pipefail

TEMPLATE_VMID=9000
TEMPLATE_NAME="debian-13-cloud-template"
STORAGE="local-lvm"
BRIDGE="vmbr0"

IMAGE_URL="https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
IMAGE_FILE="debian-13-genericcloud-amd64.qcow2"
WORK_DIR="/var/lib/vz/template/iso"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

while getopts "i:n:s:b:h" opt; do
  case $opt in
    i) TEMPLATE_VMID="$OPTARG" ;;
    n) TEMPLATE_NAME="$OPTARG" ;;
    s) STORAGE="$OPTARG" ;;
    b) BRIDGE="$OPTARG" ;;
    h) grep '^#' "$0" | grep -v '^#!/' | sed 's/^# \{0,2\}//'; exit 0 ;;
    *) exit 1 ;;
  esac
done

[[ $EUID -ne 0 ]] && error "Este script debe ejecutarse como root en el nodo Proxmox."
command -v qm &>/dev/null    || error "'qm' no encontrado. ¿Estás en el nodo Proxmox?"
command -v wget &>/dev/null  || apt-get install -y -q wget

echo ""
info "=== Configuración del template ==="
info "  VMID    : $TEMPLATE_VMID"
info "  Nombre  : $TEMPLATE_NAME"
info "  Storage : $STORAGE"
info "  Bridge  : $BRIDGE"
info "  Imagen  : $IMAGE_FILE"
echo ""

if qm status "$TEMPLATE_VMID" &>/dev/null; then
  warn "Ya existe una VM/template con VMID $TEMPLATE_VMID."
  read -rp "¿Eliminarla y recrear? [s/N] " confirm
  [[ "$confirm" =~ ^[sS]$ ]] || error "Abortado por el usuario."
  info "Eliminando VM $TEMPLATE_VMID..."
  qm destroy "$TEMPLATE_VMID" --purge
fi

mkdir -p "$WORK_DIR"
if [[ -f "$WORK_DIR/$IMAGE_FILE" ]]; then
  info "Imagen ya descargada: $WORK_DIR/$IMAGE_FILE"
else
  info "Descargando imagen Debian 13 cloud..."
  wget -q --show-progress -O "$WORK_DIR/$IMAGE_FILE" "$IMAGE_URL"
fi

if command -v virt-customize &>/dev/null; then
  info "Personalizando imagen con qemu-guest-agent y cloud-init..."
  virt-customize \
    -a "$WORK_DIR/$IMAGE_FILE" \
    --install "qemu-guest-agent,cloud-init,cloud-utils,curl,wget" \
    --run-command "systemctl enable qemu-guest-agent" \
    --run-command "systemctl enable cloud-init" \
    --truncate /etc/machine-id \
    --quiet
else
  warn "libguestfs-tools no instalado — saltando personalización de imagen."
  warn "Instalarlo con: apt-get install -y libguestfs-tools"
fi

info "Creando VM $TEMPLATE_VMID ($TEMPLATE_NAME)..."
qm create "$TEMPLATE_VMID" \
  --name "$TEMPLATE_NAME" \
  --memory 2048 \
  --cores 2 \
  --net0 virtio,bridge="$BRIDGE" \
  --ostype l26 \
  --agent enabled=1 \
  --scsihw virtio-scsi-pci \
  --serial0 socket \
  --vga serial0 \
  --tablet 0

info "Importando disco al storage '$STORAGE'..."
qm importdisk "$TEMPLATE_VMID" "$WORK_DIR/$IMAGE_FILE" "$STORAGE"

info "Configurando scsi0, cloud-init y boot..."
qm set "$TEMPLATE_VMID" --scsi0 "${STORAGE}:vm-${TEMPLATE_VMID}-disk-0,discard=on"
qm set "$TEMPLATE_VMID" --ide2 "${STORAGE}:cloudinit"
qm set "$TEMPLATE_VMID" --boot order=scsi0 --bootdisk scsi0

info "Convirtiendo VM a template..."
qm template "$TEMPLATE_VMID"

echo ""
info "=== Template creado exitosamente ==="
info "Configurar en terraform.tfvars:"
info "  template_vm_id = $TEMPLATE_VMID"
info "  template_name  = \"$TEMPLATE_NAME\""
info "  vm_storage     = \"$STORAGE\""
echo ""
