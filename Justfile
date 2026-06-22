just := just_executable()

# List all worktrees and flag any whose branch is fully merged into main
worktree-status:
    #!/usr/bin/env bash
    set -euo pipefail
    git fetch projectbluefin main --quiet 2>/dev/null || git fetch origin main --quiet 2>/dev/null || true
    echo "Worktree status:"
    while IFS= read -r line; do
        wt=$(echo "$line" | awk '{print $1}')
        ref=$(git -C "$wt" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "detached")
        ahead=$(git rev-list --count "projectbluefin/main..${ref}" 2>/dev/null || echo "?")
        behind=$(git rev-list --count "${ref}..projectbluefin/main" 2>/dev/null || echo "?")
        if [[ "$ahead" == "0" ]]; then
            echo "  STALE  $wt  ($ref)  — 0 unique commits, fully in main"
        else
            echo "  active $wt  ($ref)  ahead=$ahead behind=$behind"
        fi
    done < <(git worktree list | tail -n +2 | awk '{print $1}')

# Remove worktrees whose branch is fully merged into main. Pass FORCE=1 to also remove active worktrees.
worktree-clean FORCE="0":
    #!/usr/bin/env bash
    set -euo pipefail
    git fetch projectbluefin main --quiet 2>/dev/null || git fetch origin main --quiet 2>/dev/null || true
    removed=0
    while IFS= read -r wt; do
        ref=$(git -C "$wt" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "detached")
        ahead=$(git rev-list --count "projectbluefin/main..${ref}" 2>/dev/null || echo "1")
        if [[ "$ahead" == "0" ]] || [[ "{{ FORCE }}" == "1" ]]; then
            echo "Removing stale worktree: $wt ($ref)"
            git worktree remove "$wt" --force
            git branch -D "$ref" 2>/dev/null || true
            removed=$((removed + 1))
        fi
    done < <(git worktree list | tail -n +2 | awk '{print $1}')
    git worktree prune
    echo "Removed $removed stale worktree(s)."

# Rebase current branch onto main, run all gates, then open a PR.
# Usage: just pr "pr title" or just pr (prompts for title)
pr TITLE="":
    #!/usr/bin/env bash
    set -euo pipefail
    REMOTE=$(git remote | grep -E "projectbluefin|origin" | head -1)
    git fetch "$REMOTE" main --quiet
    BRANCH=$(git rev-parse --abbrev-ref HEAD)
    if [[ "$BRANCH" == "main" ]]; then
        echo "ERROR: on main — create a feature branch first" >&2; exit 1
    fi
    echo "Rebasing $BRANCH onto $REMOTE/main..."
    git rebase "$REMOTE/main"
    UNIQUE=$(git log HEAD "^$REMOTE/main" --oneline | wc -l)
    if [[ "$UNIQUE" -eq 0 ]]; then
        echo "ERROR: no unique commits on $BRANCH — nothing to PR" >&2; exit 1
    fi
    echo "$UNIQUE commit(s) unique to $BRANCH:"
    git log HEAD "^$REMOTE/main" --oneline
    echo ""
    echo "Running gates..."
    {{ just }} check
    pre-commit run --all-files
    echo ""
    if [[ -z "{{ TITLE }}" ]]; then
        gh pr create --fill
    else
        gh pr create --title "{{ TITLE }}" --fill-verbose
    fi

# Run unit tests (pytest for hooks.py, bats for shell scripts)
# test_libvirt_helper.bats is excluded — requires a running libvirtd session
test:
    python3 -m pytest tests/test_hooks.py -v --cov=tests --cov-report=term-missing
    bats tests/test_libsetup.bats
    bats tests/test_setup_scripts.bats
    bats tests/test_privileged_setup.bats
    bats tests/test_bling.bats
    bats tests/test_bling_sh.bats
    bats tests/test_luks_tpm2.bats
    bats tests/test_rechunker_group_fix.bats
    bats tests/test_bling_fastfetch.bats
    bats tests/test_changelog.bats
    bats tests/test_update_just.bats
    bats tests/test_ublue_fastfetch.bats
    bats tests/test_ublue_motd.bats
    bats tests/test_ublue_image_info.bats
    bats tests/test_profile_d.bats
    bats tests/test_dynamic_wallpaper.bats
    bats tests/test_geoclue_latitude.bats
    bats tests/test_brew_preinstall.bats

# Build the bluefin-common container locally
build:
    git submodule update --init bluefin-branding
    podman build -t localhost/bluefin-common:latest -f ./Containerfile .

_fmt mode verb:
    #!/usr/bin/bash
    failed=0
    while read -r file; do
      echo "{{ verb }} syntax: $file"
      {{ just }} --unstable --fmt {{ mode }} -f "$file" || failed=1
    done < <(find . -type f -name "*.just")
    echo "{{ verb }} syntax: Justfile"
    {{ just }} --unstable --fmt {{ mode }} -f Justfile || failed=1
    exit "$failed"

check: (_fmt "--check" "Checking")

fix: (_fmt "" "Fixing")

# Inspect the directory structure of an OCI image
tree IMAGE="localhost/bluefin-common:latest":
    #!/usr/bin/env bash
    cat > TreeContainerfile <<'EOF'
    FROM alpine:latest
    RUN apk add --no-cache tree
    COPY --from={{ IMAGE }} / /mnt/root
    CMD tree /mnt/root
    EOF
    podman build -t tree-temp -f TreeContainerfile .
    podman run --rm tree-temp
    rm -f TreeContainerfile
    podman rmi tree-temp

overlay $BLUEFIN_MERGE="1" $SOURCE="dir":
    #!/usr/bin/env bash
    ROOTFS_DIR="$(mktemp -d --tmpdir="${ROOTFS_BASE:-/tmp}")"
    trap 'rm -rf "${ROOTFS_DIR}"' EXIT
    NAME_TRIMMED=bfincommon

    if [ "$SOURCE" == "dir" ] ; then
        cp -a ./system_files/shared/. "${ROOTFS_DIR}"
        if [ "${BLUEFIN_MERGE}" == "1" ] ; then
            cp -a ./system_files/bluefin/. "${ROOTFS_DIR}"
        fi
    elif [ "$SOURCE" == "image" ] ; then
        podman export "$(podman create ghcr.io/projectbluefin/common:latest)" -o - | tar -xvf - -C "${ROOTFS_DIR}"
    fi

    install -d -m0755 "${ROOTFS_DIR}/usr/lib/extension-release.d"
    tee "${ROOTFS_DIR}/usr/lib/extension-release.d/extension-release.${NAME_TRIMMED}" <<EOF
    ID="_any"
    ARCHITECTURE="$(sed 's/_/-/g' <<< "$(arch)")"
    EOF

    if [ -e "${ROOTFS_DIR}/system_files" ] ; then
        cp -a "${ROOTFS_DIR}/system_files/shared/." "${ROOTFS_DIR}"
        if [ "${BLUEFIN_MERGE}" == "1" ] ; then
            cp -a "${ROOTFS_DIR}/system_files/bluefin/." "${ROOTFS_DIR}"
        fi
        rm -r "${ROOTFS_DIR}/system_files"
    fi

    if [ -d "${ROOTFS_DIR}/etc" ] ; then
        mv --no-clobber "${ROOTFS_DIR}/etc" "${ROOTFS_DIR}/usr/etc"
    fi

    for dir in "var" "run"; do
        if [ -d "${ROOTFS_DIR}"/"${dir}" ] ; then
            rm -r "${ROOTFS_DIR:?}/${dir}"
        fi
    done
    filecontexts="/etc/selinux/targeted/contexts/files/file_contexts"
    sudo setfiles -r "${ROOTFS_DIR}" "${filecontexts}" "${ROOTFS_DIR}"
    sudo chcon --user=system_u --recursive "${ROOTFS_DIR}"
    mkfs.erofs "${NAME_TRIMMED}.raw" "${ROOTFS_DIR}"
