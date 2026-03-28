# chicken-dev — Workspace Automation
default:
    @just --list --unsorted

# Full bootstrap (all apps)
bootstrap:
    bash bootstrap.sh

# Bootstrap specific apps
bootstrap-apps *apps:
    bash bootstrap.sh --apps {{apps}}

# Verify environment
doctor:
    @source scripts/common.sh && source scripts/doctor.sh && doctor

# Update all repos
update:
    @echo "Updating chicken..." && git -C "$HOME/GitHub-Projekte/chicken" pull --ff-only
    @echo "Updating campfire..." && git -C "$HOME/GitHub-Projekte/fos/campfire" pull --ff-only
    @echo "Updating bastion..." && git -C "$HOME/GitHub-Projekte/fos/bastion" pull --ff-only
    @echo "Done."
