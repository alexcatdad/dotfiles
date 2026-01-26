# Changelog

## [1.2.0](https://github.com/alexcatdad/dotfiles/compare/v1.1.4...v1.2.0) (2026-01-26)


### Features

* add sync and update commands for multi-device dotfiles ([4f7e697](https://github.com/alexcatdad/dotfiles/commit/4f7e6978c4746f4c091ea7c8553815eaf086bc29))
* enhance shell, terminal, and Claude Code configurations ([6ab195b](https://github.com/alexcatdad/dotfiles/commit/6ab195b57808b56f8232985e26c9dd8775d73035))
* update Claude plugins and optimize Ghostty for OLED ([cef7f7a](https://github.com/alexcatdad/dotfiles/commit/cef7f7a34859c86f9af54fbd8aa10dd7416436e9))

## [1.1.4](https://github.com/alexcatdad/dotfiles/compare/v1.1.3...v1.1.4) (2026-01-13)


### Bug Fixes

* simplify install script to only install paw binary ([#15](https://github.com/alexcatdad/dotfiles/issues/15)) ([288a226](https://github.com/alexcatdad/dotfiles/commit/288a2263ea0208ed554205cd69cc871b1139c22f))

## [1.1.3](https://github.com/alexcatdad/dotfiles/compare/v1.1.2...v1.1.3) (2026-01-13)


### Bug Fixes

* make postInstall hook fail gracefully when statusline file not created ([#13](https://github.com/alexcatdad/dotfiles/issues/13)) ([ba3f762](https://github.com/alexcatdad/dotfiles/commit/ba3f762f79dc04f8e1971fd1c5a1176d125937d2))

## [1.1.2](https://github.com/alexcatdad/dotfiles/compare/v1.1.1...v1.1.2) (2026-01-13)


### Bug Fixes

* install script fallback, ripgrep config, and release workflow ([#11](https://github.com/alexcatdad/dotfiles/issues/11)) ([3cdfe4d](https://github.com/alexcatdad/dotfiles/commit/3cdfe4da95c8d8f77ea8712ec4f879cdae8e2a55))

## [1.1.1](https://github.com/alexcatdad/dotfiles/compare/v1.1.0...v1.1.1) (2026-01-13)


### Bug Fixes

* ensure repo is cloned before running paw install ([#9](https://github.com/alexcatdad/dotfiles/issues/9)) ([5e7ead7](https://github.com/alexcatdad/dotfiles/commit/5e7ead7c8731e4ab0fb62bf12ff3d80f5f45ddd1))

## [1.1.0](https://github.com/alexcatdad/dotfiles/compare/v1.0.0...v1.1.0) (2026-01-12)


### Features

* add CLI completions for claude and gh ([0ac2780](https://github.com/alexcatdad/dotfiles/commit/0ac278042c38df829e6d35e33c97a95b1ceb6642))
* add dust and atuin to package list ([#7](https://github.com/alexcatdad/dotfiles/issues/7)) ([6b983d5](https://github.com/alexcatdad/dotfiles/commit/6b983d58c2ffc28c522c2b5e676b5f222cacb6e8))
* add self-update capability with desktop notifications ([e8817e1](https://github.com/alexcatdad/dotfiles/commit/e8817e167653b957a1a86390be17b159b46d2a0a))
* auto-migrate SSH hosts to config.local on install ([4a2e17a](https://github.com/alexcatdad/dotfiles/commit/4a2e17ade3d8cceab2432d2029a0a6fbc47da8fd))
* non-destructive config suggestions instead of SSH symlinks ([a638f28](https://github.com/alexcatdad/dotfiles/commit/a638f287658006c851e5eab4b24be37ee5011fbd))
* show hostname instead of username in prompts ([f53b1bc](https://github.com/alexcatdad/dotfiles/commit/f53b1bcd070a10de1c67cc572f76bea7b5c9c5da))
* version-aware install script with upgrade protection ([bff726e](https://github.com/alexcatdad/dotfiles/commit/bff726e8809af943a8ebf27aa1b04920b39bdf45))


### Bug Fixes

* check current directory for config in CI ([ca58837](https://github.com/alexcatdad/dotfiles/commit/ca58837a2a69f3a42d5e675b7a714addd7401782))
* remove SSH config from managed symlinks ([3dd6f3e](https://github.com/alexcatdad/dotfiles/commit/3dd6f3ede54865033b31fe15ca1f5d77451b1c76))


### Reverts

* remove CLI completions and self-update features ([ebf445a](https://github.com/alexcatdad/dotfiles/commit/ebf445a63be4ec8a302b3de77105dd66e3c8eeb1))
