#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# knight-rice installer
# ARCH LINUX | HYPRLAND
# ============================================================

[[ -n "${HOME:-}" ]] || {
    printf '[ERROR] HOME is not set.\n' >&2
    exit 1
}

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
WALLPAPER_DIR="$HOME/Pictures/wallpaper"
WALLPAPER_REPO="https://github.com/bat-fun/wallpaper.git"
BASHRC="$HOME/.bashrc"

SELECTED_EDITOR="kitty -e nvim"
SELECTED_BROWSER="brave"

CONFIG_PATHS=(
    dunst gtk-3.0 gtk-4.0 hypr kitty matugen nvim qt6ct rofi waybar wlogout starship.toml
)

PACKAGES=(
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    hyprland hyprlock hyprsunset hyprpolkitagent waybar rofi rofi-emoji rofi-calc kitty dunst awww
    zsh zsh-autosuggestions zsh-syntax-highlighting
    networkmanager network-manager-applet nm-connection-editor
    bluez bluez-utils blueman
    pipewire pipewire-pulse wireplumber pavucontrol
    wl-clipboard cliphist matugen starship
    grim slurp brightnessctl playerctl libnotify
    dolphin ark unzip 7zip ffmpegthumbs loupe mpv evince qt6ct python python-pillow
    noto-fonts noto-fonts-emoji
    ttf-jetbrains-mono-nerd ttf-font-awesome
    adwaita-icon-theme
)

AUR_PACKAGES=(wlogout bibata-cursor-theme-bin)

BACKUP_DIR=""
STAGE_DIR=""
BUILD_DIR=""
SELECTED_WALLPAPER=""
KEEP_STAGE=0
DEPLOYMENT_ACTIVE=0
INSTALL_CANCELLED=0
INSTALL_LOCK_FD=""

# Paths enrolled in the current deployment transaction. The original-state
# map is populated before any corresponding filesystem operation.
declare -a TRANSACTION_PATHS=()
declare -A ORIGINAL_PATH_EXISTS=()
declare -a MISSING_PACKAGES=()
declare -a MISSING_AUR=()

if [[ -t 1 ]]; then
    ACCENT='\033[1;38;5;146m'
    STEEL='\033[38;5;246m'
    BOLD='\033[1;38;5;255m'
    DIM='\033[38;5;242m'
    RED='\033[1;38;5;203m'
    GREEN='\033[1;38;5;114m'
    YELLOW='\033[1;38;5;221m'
    BLUE='\033[1;38;5;117m'
    RESET='\033[0m'
else
    ACCENT='' STEEL='' BOLD='' DIM='' RED='' GREEN='' YELLOW='' BLUE='' RESET=''
fi

banner() {
    clear 2>/dev/null || true
    printf '\n'
    printf '  %b╭────────────────────────────────────────────────────────────╮%b\n' "$DIM" "$RESET"
    printf '  %b│%b                                                            %b│%b\n' "$DIM" "$RESET" "$DIM" "$RESET"
    printf '  %b│%b  %b╦╔═╔╗╔╦╔═╗╦ ╦╔╦╗   ╦═╗╦╔═╗╔═╗%b                             %b│%b\n' "$DIM" "$RESET" "$ACCENT" "$RESET" "$DIM" "$RESET"
    printf '  %b│%b  %b╠╩╗║║║║║ ╦╠═╣ ║ ───╠╦╝║║  ║╣ %b   %bObsidian · Steel · Focus%b  %b│%b\n' "$DIM" "$RESET" "$ACCENT" "$RESET" "$STEEL" "$RESET" "$DIM" "$RESET"
    printf '  %b│%b  %b╩ ╩╝╚╝╩╚═╝╩ ╩ ╩    ╩╚═╩╚═╝╚═╝%b                             %b│%b\n' "$DIM" "$RESET" "$ACCENT" "$RESET" "$DIM" "$RESET"
    printf '  %b│%b                                                            %b│%b\n' "$DIM" "$RESET" "$DIM" "$RESET"
    printf '  %b│%b  %bArch Linux%b  %b·%b  %bHyprland%b  %b·%b  %bWaybar%b  %b·%b  %bMatugen%b           %b│%b\n' \
        "$DIM" "$RESET" "$BOLD" "$RESET" "$DIM" "$RESET" "$BOLD" "$RESET" "$DIM" "$RESET" "$BOLD" "$RESET" "$DIM" "$RESET" "$BOLD" "$RESET" "$DIM" "$RESET"
    printf '  %b╰────────────────────────────────────────────────────────────╯%b\n' "$DIM" "$RESET"
}

ui_card_top() {
    local title="$1"
    printf '\n  %b╭─ %b%s%b %b──────────────────────────────────────────╮%b\n' "$DIM" "$ACCENT" "$title" "$RESET" "$DIM" "$RESET"
}

ui_card_row() {
    local label="$1"
    local value="$2"
    printf '  %b│%b  %b%-12s%b %b%s%b\n' "$DIM" "$RESET" "$STEEL" "$label" "$RESET" "$BOLD" "$value" "$RESET"
}

ui_card_bottom() {
    printf '  %b╰──────────────────────────────────────────────────────────╯%b\n' "$DIM" "$RESET"
}

log() {
    printf '\n  %b[%s]%b %b%s%b\n' "$ACCENT" "$1" "$RESET" "$STEEL" "$2" "$RESET"
}

success() {
    printf '    %b✓%b %s\n' "$GREEN" "$RESET" "$1"
}

warning() {
    printf '    %b!%b %s\n' "$YELLOW" "$RESET" "$1"
}

error() {
    printf '\n    %b✗ ERROR:%b %s\n' "$RED" "$RESET" "$*" >&2
}

die() {
    error "$@"
    exit 1
}

ask() {
    local prompt="$1"
    local default="${2:-no}"
    local answer
    local hint="y/N"

    [[ "$default" == yes ]] && hint="Y/n"

    while true; do
        printf '\n    %b▸%b %b%s%b %b[%s]%b ' "$ACCENT" "$RESET" "$BOLD" "$prompt" "$RESET" "$DIM" "$hint" "$RESET"
        if ! read -r answer; then
            return 1
        fi

        answer="${answer,,}"

        case "$answer" in
            "")
                [[ "$default" == yes ]] && return 0
                return 1
                ;;
            y|yes) return 0 ;;
            n|no) return 1 ;;
            *) printf '      %bPlease enter y or n.%b\n' "$DIM" "$RESET" ;;
        esac
    done
}

rollback_configs() {
    local index path destination previous had_original
    local rollback_failed=0

    (( DEPLOYMENT_ACTIVE )) || return 0

    warning "An unfinished configuration deployment was detected. Rolling back."

    for ((index=${#TRANSACTION_PATHS[@]} - 1; index>=0; index--)); do
        path="${TRANSACTION_PATHS[$index]}"
        destination="$CONFIG_DIR/$path"
        previous="$STAGE_DIR/rollback/$path"
        had_original="${ORIGINAL_PATH_EXISTS[$path]:-0}"

        if [[ "$had_original" == 1 ]]; then
            if [[ -e "$previous" || -L "$previous" ]]; then
                if [[ -e "$destination" || -L "$destination" ]]; then
                    if ! rm -rf -- "$destination"; then
                        KEEP_STAGE=1
                        rollback_failed=1
                        error "Could not remove partially installed path: $destination"
                        continue
                    fi
                fi

                if ! mkdir -p -- "$(dirname -- "$destination")"; then
                    KEEP_STAGE=1
                    rollback_failed=1
                    error "Could not recreate parent directory for: $destination"
                    continue
                fi

                if ! mv -- "$previous" "$destination"; then
                    KEEP_STAGE=1
                    rollback_failed=1
                    error "Could not restore original configuration: $destination"
                else
                    success "Restored $path"
                fi
            elif [[ ! -e "$destination" && ! -L "$destination" ]]; then
                # The original existed, but neither its rollback copy nor its
                # original destination remains. Preserve the staging area.
                KEEP_STAGE=1
                rollback_failed=1
                error "Original configuration could not be located: $destination"
            fi
            # If there is no rollback copy but destination exists, the move of
            # the original never happened; leave that original untouched.
        else
            if [[ -e "$destination" || -L "$destination" ]]; then
                if ! rm -rf -- "$destination"; then
                    KEEP_STAGE=1
                    rollback_failed=1
                    error "Could not remove newly installed path: $destination"
                fi
            fi
        fi
    done

    if (( rollback_failed )); then
        KEEP_STAGE=1
        warning "Rollback was incomplete. Recovery files will be preserved."
        DEPLOYMENT_ACTIVE=0
        return 1
    fi

    DEPLOYMENT_ACTIVE=0
    TRANSACTION_PATHS=()
    ORIGINAL_PATH_EXISTS=()
    success "Configuration rollback completed."
    return 0
}

cleanup() {
    local status=$?

    # Prevent recursive EXIT handling and defer further catchable signals
    # while recovery is running.
    trap - EXIT INT TERM HUP
    trap '' INT TERM HUP

    if (( DEPLOYMENT_ACTIVE )); then
        if ! rollback_configs; then
            status=1
        fi
    fi

    if [[ -n "$STAGE_DIR" && -d "$STAGE_DIR" ]]; then
        if (( KEEP_STAGE )); then
            warning "Recovery files preserved: $STAGE_DIR"
        elif ! rm -rf -- "$STAGE_DIR"; then
            warning "Could not remove staging directory: $STAGE_DIR"
            (( status != 0 )) || status=1
        fi
    fi

    if [[ -n "$BUILD_DIR" && -d "$BUILD_DIR" ]]; then
        if ! rm -rf -- "$BUILD_DIR"; then
            warning "Could not remove temporary build directory: $BUILD_DIR"
            (( status != 0 )) || status=1
        fi
    fi

    exit "$status"
}

handle_signal() {
    local signal="$1"
    local exit_code=1

    case "$signal" in
        INT)  exit_code=130 ;;
        TERM) exit_code=143 ;;
        HUP)  exit_code=129 ;;
    esac

    warning "Received SIG$signal. Exiting and attempting safe cleanup."
    exit "$exit_code"
}

trap cleanup EXIT
trap 'handle_signal INT' INT
trap 'handle_signal TERM' TERM
trap 'handle_signal HUP' HUP

validate_environment() {
    log "01 // SYSTEM CHECK" "Checking the environment."

    [[ "$EUID" -ne 0 ]] || die "Run as your normal user."
    [[ -t 0 ]] || die "Run from an interactive terminal."

    [[ "$CONFIG_DIR" == /* ]] || die "XDG_CONFIG_HOME must be an absolute path."
    [[ "$DATA_DIR" == /* ]] || die "XDG_DATA_HOME must be an absolute path."

    command -v pacman >/dev/null 2>&1 ||
        die "Arch Linux is required."

    command -v git >/dev/null 2>&1 ||
        die "Install Git first: sudo pacman -S git"

    command -v flock >/dev/null 2>&1 ||
        die "flock is required (provided by util-linux)."

    for path in "${CONFIG_PATHS[@]}"; do
        [[ -e "$ROOT_DIR/$path" || -L "$ROOT_DIR/$path" ]] ||
            die "Missing repository configuration: $path"
    done

    mkdir -p -- "$CONFIG_DIR" "$DATA_DIR" "$HOME/Pictures" ||
        die "Could not create required user directories."

    # Keep the lock file in the user's data directory. Do not delete it after
    # unlocking: removing a lock file can create races between concurrent runs.
    exec {INSTALL_LOCK_FD}>"$DATA_DIR/.knight-rice-installer.lock" ||
        die "Could not open installer lock file."

    flock -n "$INSTALL_LOCK_FD" ||
        die "Another instance of this installer is already running."

    success "Environment validated."
}

check_official_packages() {
    log "02 // ARSENAL" "Checking official packages."

    MISSING_PACKAGES=()

    for package in "${PACKAGES[@]}"; do
        if pacman -Q "$package" >/dev/null 2>&1; then
            success "$package"
        else
            warning "Missing: $package"
            MISSING_PACKAGES+=("$package")
        fi
    done

    ((${#MISSING_PACKAGES[@]})) || {
        success "All official packages installed."
        return 0
    }

    printf '\n  Missing packages:\n'
    printf '    %s\n' "${MISSING_PACKAGES[@]}"

    ask "Install missing official packages?" yes || {
        warning "Skipping official packages."
        return 0
    }

    command -v sudo >/dev/null 2>&1 ||
        die "sudo is required to install official packages."

    sudo pacman -S --needed "${MISSING_PACKAGES[@]}"
}

get_aur_helper() {
    if command -v paru >/dev/null 2>&1; then
        printf 'paru'
    elif command -v yay >/dev/null 2>&1; then
        printf 'yay'
    fi
}

install_yay() {
    log "03 // AUR" "Preparing yay."

    command -v sudo >/dev/null 2>&1 ||
        die "sudo is required to install yay."

    sudo pacman -S --needed base-devel git

    BUILD_DIR="$(mktemp -d -- "${TMPDIR:-/tmp}/knight-rice-yay.XXXXXXXX")" ||
        die "Could not create yay build directory."

    git clone --depth 1 \
        https://aur.archlinux.org/yay.git "$BUILD_DIR/yay" ||
        die "Could not clone the yay AUR repository."

    warning "Review the PKGBUILD in $BUILD_DIR/yay before continuing."
    ask "Build and install yay from this PKGBUILD?" yes ||
        die "yay installation cancelled."

    (
        cd "$BUILD_DIR/yay" || exit 1
        makepkg -si
    )

    if rm -rf -- "$BUILD_DIR"; then
        BUILD_DIR=""
    else
        warning "Could not remove yay build directory: $BUILD_DIR"
    fi

    command -v yay >/dev/null 2>&1 ||
        die "yay installation could not be verified."
}

check_aur_packages() {
    local helper

    log "03 // AUR" "Checking extra applications."

    MISSING_AUR=()

    for package in "${AUR_PACKAGES[@]}"; do
        if pacman -Q "$package" >/dev/null 2>&1; then
            success "$package"
        else
            warning "Missing: $package"
            MISSING_AUR+=("$package")
        fi
    done

    ((${#MISSING_AUR[@]})) || return 0

    ask "Install missing AUR applications?" yes || {
        warning "Skipping AUR applications."
        return 0
    }

    helper="$(get_aur_helper || true)"

    if [[ -z "$helper" ]]; then
        ask "Build yay because no AUR helper exists?" yes || {
            warning "Skipping AUR applications."
            return 0
        }
        install_yay
        helper="yay"
    fi

    "$helper" -S --needed "${MISSING_AUR[@]}"
}

validate_configs() {
    local path source

    for path in "${CONFIG_PATHS[@]}"; do
        source="$ROOT_DIR/$path"

        [[ -e "$source" || -L "$source" ]] ||
            die "Missing source: $path"

        # This installer copies real files/directories into CONFIG_DIR; it
        # never creates repo-to-~/.config symlinks. Reject symlinks anywhere
        # in the source tree too, because cp -a would otherwise preserve them.
        [[ ! -L "$source" ]] ||
            die "Source configuration must not be a symlink: $path"

        if find "$source" -type l -print -quit | grep -q .; then
            die "Symbolic links are not allowed inside configuration source: $path"
        fi

        if [[ "$path" == starship.toml ]]; then
            [[ -f "$source" ]] ||
                die "Expected a regular file: $path"
        else
            [[ -d "$source" ]] ||
                die "Expected a directory: $path"
        fi
    done
}

install_configs() {
    local path destination source previous backup_path
    local -a existing=()

    log "04 // DEPLOYMENT" "Preparing configurations."

    validate_configs

    printf '\n  Paths to replace:\n'
    for path in "${CONFIG_PATHS[@]}"; do
        printf '    %s\n' "$CONFIG_DIR/$path"
    done

    if ! ask "Continue with installation?" no; then
        warning "Configuration installation cancelled."
        INSTALL_CANCELLED=1
        return 0
    fi

    for path in "${CONFIG_PATHS[@]}"; do
        destination="$CONFIG_DIR/$path"
        if [[ -e "$destination" || -L "$destination" ]]; then
            existing+=("$path")
        fi
    done

    STAGE_DIR="$(mktemp -d -- "$CONFIG_DIR/.knight-rice-install.XXXXXXXX")" ||
        die "Could not create configuration staging directory."

    mkdir -p -- "$STAGE_DIR/payload" "$STAGE_DIR/rollback" ||
        die "Could not create staging subdirectories."

    for path in "${CONFIG_PATHS[@]}"; do
        cp -a -- "$ROOT_DIR/$path" "$STAGE_DIR/payload/$path" ||
            die "Could not stage $path."
    done

    if ((${#existing[@]})); then
        printf '\n  Existing configurations detected:\n'
        printf '    %s\n' "${existing[@]}"
        warning "Disabling backups means there will be no permanent copy after a successful deployment."

        if ask "Back up existing configurations?" yes; then
            mkdir -p -- "$DATA_DIR/dotfile-backups" ||
                die "Could not create permanent backup directory."

            BACKUP_DIR="$(mktemp -d -- "$DATA_DIR/dotfile-backups/knight-rice-XXXXXXXX")" ||
                die "Could not create permanent backup location."

            chmod 700 -- "$BACKUP_DIR" ||
                die "Could not secure permanent backup directory."

            for path in "${existing[@]}"; do
                destination="$CONFIG_DIR/$path"
                backup_path="$BACKUP_DIR/$path"

                mkdir -p -- "$(dirname -- "$backup_path")" ||
                    die "Could not create backup path for $path."

                cp -a -- "$destination" "$backup_path" ||
                    die "Backup failed for $path."

                success "Backed up $path"
            done

            success "Backup: $BACKUP_DIR"
        else
            warning "Permanent backup skipped."
        fi
    fi

    # Start the transaction before the first destructive move. Record whether
    # each destination existed before enrolling it, so recovery can distinguish
    # an untouched original from a newly installed path.
    DEPLOYMENT_ACTIVE=1
    TRANSACTION_PATHS=()
    ORIGINAL_PATH_EXISTS=()

    for path in "${CONFIG_PATHS[@]}"; do
        destination="$CONFIG_DIR/$path"
        source="$STAGE_DIR/payload/$path"
        previous="$STAGE_DIR/rollback/$path"

        if [[ -e "$destination" || -L "$destination" ]]; then
            ORIGINAL_PATH_EXISTS["$path"]=1
        else
            ORIGINAL_PATH_EXISTS["$path"]=0
        fi
        TRANSACTION_PATHS+=("$path")

        if [[ "${ORIGINAL_PATH_EXISTS[$path]}" == 1 ]]; then
            mv -- "$destination" "$previous" ||
                die "Could not move existing configuration into rollback storage: $path"
        fi

        mv -- "$source" "$destination" ||
            die "Could not install configuration: $path"

        success "Installed $path"
    done

    # Commit: after this point, failures in optional wallpaper/service setup do
    # not revert a completed configuration deployment.
    DEPLOYMENT_ACTIVE=0
    TRANSACTION_PATHS=()
    ORIGINAL_PATH_EXISTS=()
    chmod +x "$CONFIG_DIR/hypr/scripts/"* 2>/dev/null || true
    success "Configuration deployment completed."
}

configure_starship_bashrc() {
    log "04 // SHELL" "Configuring Starship for Bash."

    if [[ -e "$BASHRC" && ! -f "$BASHRC" ]]; then
        warning "$BASHRC exists but is not a regular file; skipping Starship setup."
        return 0
    fi

    if [[ -f "$BASHRC" ]] && grep -Fq -- 'starship init bash' "$BASHRC"; then
        success "Starship initialization already exists in ~/.bashrc."
        return 0
    fi

    if ! {
        printf '\n# >>> knight-rice starship init >>>\n'
        printf 'if command -v starship >/dev/null 2>&1; then\n'
        printf '    eval "$(starship init bash)"\n'
        printf 'fi\n'
        printf '# <<< knight-rice starship init <<<\n'
    } >> "$BASHRC"; then
        warning "Could not update ~/.bashrc; add Starship initialization manually."
        return 0
    fi

    success "Starship initialization added to ~/.bashrc."
}

has_wallpapers() {
    [[ -d "$WALLPAPER_DIR" ]] || return 1

    find "$WALLPAPER_DIR" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' \
        -o -iname '*.png' -o -iname '*.webp' \
        -o -iname '*.gif' \) -print -quit | grep -q .
}

fetch_wallpapers() {
    local tmp_repo count=0

    log "05 // WALLPAPERS" "Checking wallpaper collection."

    mkdir -p -- "$WALLPAPER_DIR" || {
        warning "Could not create wallpaper directory."
        return 0
    }

    if has_wallpapers; then
        success "Existing wallpapers detected."
        return 0
    fi

    if command -v git >/dev/null 2>&1; then
        log "05 // WALLPAPERS" "Cloning $WALLPAPER_REPO into $WALLPAPER_DIR."
        tmp_repo="$(mktemp -d)" || {
            warning "Could not create temporary directory for wallpapers."
            return 0
        }

        if git clone --depth 1 "$WALLPAPER_REPO" "$tmp_repo"; then
            while IFS= read -r -d '' image; do
                cp -n -- "$image" "$WALLPAPER_DIR/" && count=$((count + 1))
            done < <(
                find "$tmp_repo" -type f \
                    \( -iname '*.jpg' -o -iname '*.jpeg' \
                    -o -iname '*.png' -o -iname '*.webp' \
                    -o -iname '*.gif' \) -print0
            )
            rm -rf -- "$tmp_repo"
            if (( count > 0 )); then
                success "Installed $count wallpapers from $WALLPAPER_REPO."
                return 0
            fi
        else
            rm -rf -- "$tmp_repo"
            warning "Could not clone $WALLPAPER_REPO (offline or unreachable)."
        fi
    else
        warning "git unavailable; skipping wallpaper repository clone."
    fi

    warning "No wallpapers found. Generating minimal fallback wallpaper."

    if command -v python3 >/dev/null 2>&1 && python3 -c "import PIL" >/dev/null 2>&1; then
        python3 - "$WALLPAPER_DIR/obsidian-minimal.png" <<'PYEOF'
import sys
from PIL import Image

w, h = 1920, 1080
img = Image.new("RGB", (w, h))
pixels = img.load()
for y in range(h):
    t = y / (h - 1)
    r = int(14 + 12 * t)
    g = int(14 + 12 * t)
    b = int(13 + 13 * t)
    for x in range(w):
        pixels[x, y] = (r, g, b)
img.save(sys.argv[1])
PYEOF
        success "Created fallback wallpaper: $WALLPAPER_DIR/obsidian-minimal.png"
    else
        warning "Pillow unavailable; place wallpapers in $WALLPAPER_DIR manually."
    fi
}

choose_wallpaper() {
    local -a wallpapers=()
    local choice index=1 wallpaper

    SELECTED_WALLPAPER=""

    mapfile -d '' -t wallpapers < <(
        find "$WALLPAPER_DIR" -maxdepth 1 -type f \
            \( -iname '*.jpg' -o -iname '*.jpeg' \
            -o -iname '*.png' -o -iname '*.webp' \
            -o -iname '*.gif' \) -print0 | sort -z
    )

    ((${#wallpapers[@]})) || {
        warning "No wallpapers available."
        return 0
    }

    printf '\n  AVAILABLE WALLPAPERS\n'

    for wallpaper in "${wallpapers[@]}"; do
        printf '    %d) %s\n' "$index" "$(basename -- "$wallpaper")"
        index=$((index + 1))
    done

    printf '    0) Skip\n'

    read -r -p '  Select wallpaper [1]: ' choice || return 0
    choice="${choice:-1}"

    [[ "$choice" =~ ^[0-9]+$ ]] || {
        warning "Invalid selection."
        return 0
    }

    (( choice == 0 )) && return 0

    if (( choice > ${#wallpapers[@]} )); then
        warning "Selection outside the list."
        return 0
    fi

    SELECTED_WALLPAPER="${wallpapers[$((choice - 1))]}"
    success "Selected $(basename -- "$SELECTED_WALLPAPER")"
}


generate_colors() {
    [[ -n "$SELECTED_WALLPAPER" ]] || return 0

    local color_data
    local source_color
    local scheme_type

    log "06 // SHADOWS" "Extracting dominant wallpaper color."

    if ! color_data="$(
        "$ROOT_DIR/hypr/scripts/dominant-color" "$SELECTED_WALLPAPER" )"; then
        warning "Could not extract dominant color."
        return 0
    fi

    read -r source_color scheme_type <<< "$color_data"

    log "06 // SHADOWS" "Generating Matugen palette."

    if matugen \
        --mode dark \
        --type "$scheme_type" \
        color hex "$source_color"; then

        success "Colors generated from $source_color ($scheme_type)."
    else
        warning "Matugen failed."
    fi
}


start_services() {
    local unit

    log "07 // SYSTEM SERVICES" "Checking background services."

    if ! command -v systemctl >/dev/null 2>&1; then
        warning "systemctl unavailable."
        return 0
    fi

    if ask "Enable and start NetworkManager and Bluetooth?" yes; then
        if ! command -v sudo >/dev/null 2>&1; then
            warning "sudo is unavailable; skipping system services."
        else
            for unit in NetworkManager.service bluetooth.service; do
                if systemctl list-unit-files "$unit" --no-legend --no-pager |
                    grep -F -- "$unit" >/dev/null; then
                    if sudo systemctl enable --now "$unit"; then
                        success "$unit enabled and started."
                    else
                        warning "Could not start $unit."
                    fi
                else
                    warning "$unit is not installed."
                fi
            done
        fi
    fi

    if systemctl --user show-environment >/dev/null 2>&1; then
        if systemctl --user enable --now \
            pipewire.socket pipewire-pulse.socket wireplumber.service; then
            success "PipeWire and WirePlumber started."
        else
            warning "Audio services could not all be started."
        fi
    else
        warning "User systemd session unavailable."
    fi
}

start_awww() {
    log "08 // WALLPAPER ENGINE" "Starting AWWW."

    if ! command -v awww >/dev/null 2>&1 ||
       ! command -v awww-daemon >/dev/null 2>&1; then
        warning "AWWW unavailable."
        return 0
    fi

    if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
        warning "No active Wayland session."
        return 0
    fi

    if ! awww query >/dev/null 2>&1; then
        nohup awww-daemon >/dev/null 2>&1 &

        local attempt
        for attempt in {1..10}; do
            sleep 1
            awww query >/dev/null 2>&1 && break
        done
    fi

    if ! awww query >/dev/null 2>&1; then
        warning "AWWW daemon failed to start."
        return 0
    fi

    success "AWWW daemon running."

    if [[ -n "$SELECTED_WALLPAPER" ]]; then
        if awww img "$SELECTED_WALLPAPER"; then
            success "Wallpaper applied."
        else
            warning "Could not apply wallpaper."
        fi
    fi
}

finish() {
    ui_card_top "KNIGHT-RICE READY"
    ui_card_row "Configs" "$CONFIG_DIR"
    ui_card_row "Wallpapers" "$WALLPAPER_DIR"
    ui_card_row "Editor" "$SELECTED_EDITOR"
    [[ -n "$SELECTED_BROWSER" ]] && ui_card_row "Browser" "$SELECTED_BROWSER"
    [[ -z "$BACKUP_DIR" ]] || ui_card_row "Backup" "$BACKUP_DIR"
    ui_card_bottom

    printf '\n  %bQUICK START%b\n' "$BOLD" "$RESET"
    printf '    %b%-18s%b %s\n' "$ACCENT" "SUPER + Return" "$RESET" "Terminal (Kitty)"
    printf '    %b%-18s%b %s\n' "$ACCENT" "SUPER + A" "$RESET" "App Launcher (Rofi)"
    printf '    %b%-18s%b %s\n' "$ACCENT" "SUPER + W / R" "$RESET" "Wallpaper Gallery / Random"
    printf '    %b%-18s%b %s\n' "$ACCENT" "SUPER + K" "$RESET" "Keybind Cheatsheet"
    printf '    %b%-18s%b %s\n' "$ACCENT" "SUPER + G" "$RESET" "Google / YouTube Search"
    printf '    %b%-18s%b %s\n' "$ACCENT" "SUPER + ALT + R" "$RESET" "Warm Reading Mode"
    printf '    %b%-18s%b %s\n' "$ACCENT" "SUPER + ALT + N" "$RESET" "Do Not Disturb"
    printf '    %b%-18s%b %s\n' "$ACCENT" "SUPER + V" "$RESET" "Clipboard History"
    printf '    %b%-18s%b %s\n' "$ACCENT" "Waybar 󰒓" "$RESET" "GNOME-style Quick Settings"
    printf '\n  %bLog out and back into Hyprland if needed. Enjoy the focus.%b\n\n' "$STEEL" "$RESET"
}

show_plan() {
    log "02 // INSTALL PLAN" "Review your configuration before making changes."
    ui_card_top "DEPLOYMENT SUMMARY"
    ui_card_row "Editor" "$SELECTED_EDITOR"
    ui_card_row "Browser" "${SELECTED_BROWSER:-keep existing}"
    ui_card_row "Config" "$CONFIG_DIR"
    ui_card_row "Wallpapers" "$WALLPAPER_DIR"
    ui_card_row "Safety" "Automatic backup + atomic rollback"
    ui_card_bottom

    ask "Proceed with installation?" yes || {
        warning "Installation cancelled cleanly. No system changes were made."
        exit 0
    }
}

select_preferences() {
    local editor_choice browser_choice

    log "01 // PREFERENCES" "Choose your primary editor and browser."

    printf '\n  %bEDITOR%b\n' "$BOLD" "$RESET"
    printf '    %b1)%b Neovim %b(terminal-native, recommended)%b\n' "$ACCENT" "$RESET" "$DIM" "$RESET"
    printf '    %b2)%b VS Code %b(Code - OSS)%b\n' "$ACCENT" "$RESET" "$DIM" "$RESET"
    printf '    %b3)%b Both %b(Neovim primary)%b\n' "$ACCENT" "$RESET" "$DIM" "$RESET"
    printf '    %b4)%b Both %b(VS Code primary)%b\n' "$ACCENT" "$RESET" "$DIM" "$RESET"
    printf '    %b▸%b Select editor %b[1]%b: ' "$ACCENT" "$RESET" "$DIM" "$RESET"
    read -r editor_choice || editor_choice=1
    editor_choice="${editor_choice:-1}"

    case "$editor_choice" in
        2)
            PACKAGES+=(code)
            SELECTED_EDITOR="code"
            ;;
        3)
            PACKAGES+=(neovim code)
            SELECTED_EDITOR="kitty -e nvim"
            ;;
        4)
            PACKAGES+=(neovim code)
            SELECTED_EDITOR="code"
            ;;
        *)
            PACKAGES+=(neovim)
            SELECTED_EDITOR="kitty -e nvim"
            ;;
    esac
    success "Editor set to: $SELECTED_EDITOR"

    printf '\n  %bBROWSER%b\n' "$BOLD" "$RESET"
    printf '    %b1)%b Brave %b(AUR: brave-bin, recommended)%b\n' "$ACCENT" "$RESET" "$DIM" "$RESET"
    printf '    %b2)%b Firefox\n' "$ACCENT" "$RESET"
    printf '    %b3)%b Chromium\n' "$ACCENT" "$RESET"
    printf '    %b4)%b Zen Browser %b(AUR: zen-browser-bin)%b\n' "$ACCENT" "$RESET" "$DIM" "$RESET"
    printf '    %b5)%b Skip browser install\n' "$ACCENT" "$RESET"
    printf '    %b▸%b Select browser %b[1]%b: ' "$ACCENT" "$RESET" "$DIM" "$RESET"
    read -r browser_choice || browser_choice=1
    browser_choice="${browser_choice:-1}"

    case "$browser_choice" in
        2)
            PACKAGES+=(firefox)
            SELECTED_BROWSER="firefox"
            ;;
        3)
            PACKAGES+=(chromium)
            SELECTED_BROWSER="chromium"
            ;;
        4)
            AUR_PACKAGES+=(zen-browser-bin)
            SELECTED_BROWSER="zen-browser"
            ;;
        5)
            SELECTED_BROWSER=""
            warning "Browser installation skipped."
            ;;
        *)
            AUR_PACKAGES+=(brave-bin)
            SELECTED_BROWSER="brave"
            ;;
    esac
    [[ -n "$SELECTED_BROWSER" ]] && success "Browser set to: $SELECTED_BROWSER"
}

configure_zsh() {
    local zsh_source="$ROOT_DIR/zsh/.zshrc"
    local zsh_target="$HOME/.zshrc"

    log "04 // SHELL" "Configuring Zsh."
    [[ -f "$zsh_source" ]] || {
        warning "Missing $zsh_source; skipping Zsh config."
        return 0
    }

    if [[ -f "$zsh_target" && ! -L "$zsh_target" ]]; then
        if ! cmp -s "$zsh_source" "$zsh_target"; then
            cp -a -- "$zsh_target" "${zsh_target}.bak.$(date +%Y%m%d%H%M%S)" &&
                success "Backed up existing ~/.zshrc"
        fi
    fi

    cp -f -- "$zsh_source" "$zsh_target" && success "Installed ~/.zshrc"

    if [[ "$SELECTED_EDITOR" == "code" ]]; then
        sed -i -E 's|^export EDITOR=.*|export EDITOR="code --wait"|; s|^export VISUAL=.*|export VISUAL="code --wait"|' "$zsh_target"
    fi

    if command -v zsh >/dev/null 2>&1; then
        local zsh_bin
        zsh_bin="$(command -v zsh)"
        if [[ "${SHELL:-}" != "$zsh_bin" ]]; then
            if ask "Set Zsh as your default login shell?" yes; then
                chsh -s "$zsh_bin" && success "Default shell set to $zsh_bin" ||
                    warning "Could not change login shell; run: chsh -s $zsh_bin"
            fi
        else
            success "Zsh is already your default shell."
        fi
    fi
}

configure_sddm() {
    local theme_src="$ROOT_DIR/sddm/knight-sddm"
    local theme_dst="/usr/share/sddm/themes/knight-sddm"
    local sddm_cache="/var/tmp/knight-sddm"

    [[ -d "$theme_src" ]] || return 0

    log "07 // LOGIN SCREEN" "Optional minimal SDDM login theme."
    ask "Install and enable the knight-sddm login theme?" yes || {
        warning "Skipping SDDM setup."
        return 0
    }

    command -v sudo >/dev/null 2>&1 || {
        warning "sudo unavailable; skipping SDDM setup."
        return 0
    }

    sudo pacman -S --needed sddm qt6-5compat || {
        warning "Could not install sddm/qt6-5compat; skipping SDDM setup."
        return 0
    }

    sudo mkdir -p /usr/share/sddm/themes /etc/sddm.conf.d "$sddm_cache"
    sudo rm -rf -- "$theme_dst"
    sudo cp -a -- "$theme_src" "$theme_dst"
    printf '[Theme]\nCurrent=knight-sddm\n' | sudo tee /etc/sddm.conf.d/10-knight.conf >/dev/null

    sudo chown "$USER" "$sddm_cache"
    chmod 755 "$sddm_cache"
    if [[ -n "${SELECTED_WALLPAPER:-}" && -f "$SELECTED_WALLPAPER" ]]; then
        cp -f -- "$SELECTED_WALLPAPER" "$sddm_cache/wallpaper"
        chmod 644 "$sddm_cache/wallpaper"
    fi

    if command -v systemctl >/dev/null 2>&1; then
        if ! systemctl is-enabled sddm.service >/dev/null 2>&1; then
            sudo systemctl enable sddm.service || warning "Could not enable sddm.service automatically."
        fi
    fi

    success "SDDM theme configured (knight-sddm)."
}

configure_dark_mode() {
    if command -v gsettings >/dev/null 2>&1; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true
        success "Dark mode preference enabled (prefer-dark)."
    fi
}

configure_programs() {
    local programs_file="$CONFIG_DIR/hypr/module/programs.lua"
    [[ -f "$programs_file" ]] || return 0

    if [[ -n "$SELECTED_EDITOR" ]]; then
        sed -i -E "s|^([[:space:]]*code[[:space:]]*=[[:space:]]*\")[^\"]*(\".*)|\1${SELECTED_EDITOR}\2|" "$programs_file"
    fi

    if [[ -n "$SELECTED_BROWSER" ]]; then
        sed -i -E "s|^([[:space:]]*browser[[:space:]]*=[[:space:]]*\")[^\"]*(\".*)|\1${SELECTED_BROWSER}\2|" "$programs_file"
    fi

    success "Updated $programs_file"
}

main() {
    banner

    validate_environment
    select_preferences
    show_plan
    check_official_packages
    check_aur_packages

    install_configs
    if (( INSTALL_CANCELLED )); then
        warning "Installation cancelled before configuration deployment."
        return 0
    fi

    configure_programs
    configure_dark_mode
    configure_zsh
    configure_starship_bashrc
    fetch_wallpapers
    choose_wallpaper
    generate_colors
    configure_sddm

    start_services
    start_awww

    finish
}

main "$@"
