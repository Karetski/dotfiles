#!/usr/bin/env bash
ensure_dir "$HOME/.config/micro"
deploy_file "$DOTFILES_DIR/micro/files/settings.json" "$HOME/.config/micro/settings.json"
deploy_file "$DOTFILES_DIR/micro/files/bindings.json" "$HOME/.config/micro/bindings.json"
