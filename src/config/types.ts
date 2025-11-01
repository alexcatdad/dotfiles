export interface PackageDefinition {
  name: string;
  macos?: string | null;
  ubuntu?: string | null;
  global_npm?: string;
  description?: string;
  version_constraint?: string;
  required?: boolean;
  optional?: boolean;
  platform_specific?: boolean;
  post_install?: string[];
  fallback?: {
    macos?: string;
    ubuntu?: string;
  };
}

export interface Category {
  description: string;
  priority?: number;
  condition?: "desktop_environment";
  packages: PackageDefinition[];
}

export interface SymlinkConfig {
  defaults: {
    relink: boolean;
    create: boolean;
    force: boolean;
  };
  clean: string[];
  links: Record<string, string>;
  directories: string[];
  shell_commands: Array<{
    command: string;
    description: string;
  }>;
}

export interface Config {
  metadata: {
    version: string;
    last_updated: string;
    supported_platforms: string[];
  };
  symlinks: SymlinkConfig;
  categories: Record<string, Category>;
}


