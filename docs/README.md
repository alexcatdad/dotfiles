# Documentation

This directory contains comprehensive documentation for the dotfiles project.

## 📚 Available Guides

### [Migration Guide](./MIGRATION.md)
- Pre-migration checklist and backup procedures
- Multiple migration strategies (clean install, safe migration, gradual)
- Migrating from specific setups (Oh My Zsh, Bash, Fish, Vim)
- Preserving customizations and handling rollbacks
- Common migration issues and solutions

### [Customization Guide](./CUSTOMIZATION.md)
- Local override system for personalization
- Package customization and selective installation
- IDE and editor configuration overrides
- Git configuration customization
- Function and alias customization
- Environment-specific and machine-specific setups
- Theme and appearance customization
- External tool integration (Docker, cloud providers)

## 🎯 Quick Navigation

**New User?** Start with the main [README.md](../README.md) for installation options, then use the [Migration Guide](./MIGRATION.md) if you're coming from another setup.

**Existing User?** Check the [Customization Guide](./CUSTOMIZATION.md) to personalize your configuration without breaking updates.

**Developer?** See the main [README.md](../README.md) for the architecture overview and contribution guidelines.

## 📋 Common Use Cases

### I want to install on a fresh machine
1. Use `./bootstrap.sh` for complete setup
2. See [Quick Installation](../README.md#-quick-installation) in the main README

### I want to migrate from my existing setup
1. Read the [Migration Guide](./MIGRATION.md)
2. Start with the backup procedures
3. Choose appropriate migration strategy

### I want to add my personal customizations
1. Follow the [Customization Guide](./CUSTOMIZATION.md)
2. Use the local override system
3. Keep customizations in version control

### I want to customize package selection
1. See [Package Customization](./CUSTOMIZATION.md#package-customization)
2. Use the new YAML-based installer
3. Create custom package categories

### I want to add my own project templates
1. Review [Project Templates](./CUSTOMIZATION.md#function-and-alias-customization)
2. Create custom templates in your local overrides
3. Extend the `init-project` function

## 🔧 Advanced Topics

- **Performance Optimization**: Shell startup performance and lazy loading techniques
- **Security**: Handling credentials and sensitive information
- **Cross-Platform**: Managing differences between macOS and Linux
- **Testing**: Validating your dotfiles configuration
- **Automation**: CI/CD for dotfiles and automated updates

## 🆘 Getting Help

1. **Check existing documentation** in this directory
2. **Run diagnostics**: `./test/test-dotfiles.sh`
3. **Check logs**: `tail -f ~/.dotfiles/.install.log`
4. **Create an issue** with your OS, shell version, and error details
5. **Search existing issues** for similar problems

## 🤝 Contributing to Documentation

Documentation improvements are welcome! Please:

1. Keep guides practical and example-heavy
2. Test all commands and code examples
3. Update this README when adding new guides
4. Follow the existing structure and formatting

---

**Remember**: These dotfiles are designed to be customizable without modification. Use the override system to make them truly yours!
