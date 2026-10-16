# CLI development/package environment; pin nixpkgs in the consuming system.
{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  packages = with pkgs; [ git git-lfs jq go eza ripgrep fd zoxide atuin starship direnv zsh fish ];
}
