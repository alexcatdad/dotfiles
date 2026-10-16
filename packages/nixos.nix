# Import deliberately into a NixOS configuration. No user identity or services.
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    git git-lfs jq go eza ripgrep fd zoxide atuin starship direnv zsh fish
  ];
  programs.zsh.enable = true;
  programs.fish.enable = true;
  # User configuration remains managed by the per-file lifecycle tool.
  # Do not combine this with competing Home Manager ownership of those files.
}
