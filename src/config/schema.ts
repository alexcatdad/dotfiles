import { z } from "zod";

const packageDefinitionSchema = z.object({
  name: z.string(),
  macos: z.string().nullable().optional(),
  ubuntu: z.string().nullable().optional(),
  global_npm: z.string().optional(),
  description: z.string().optional(),
  version_constraint: z.string().optional(),
  required: z.boolean().optional(),
  optional: z.boolean().optional(),
  platform_specific: z.boolean().optional(),
  post_install: z.array(z.string()).optional(),
  fallback: z
    .object({
      macos: z.string().optional(),
      ubuntu: z.string().optional(),
    })
    .optional(),
});

const categorySchema = z.object({
  description: z.string(),
  priority: z.number().optional(),
  condition: z.enum(["desktop_environment"]).optional(),
  packages: z.array(packageDefinitionSchema),
});

const symlinkConfigSchema = z.object({
  defaults: z.object({
    relink: z.boolean(),
    create: z.boolean(),
    force: z.boolean(),
  }),
  clean: z.array(z.string()),
  links: z.record(z.string(), z.string()),
  directories: z.array(z.string()),
  shell_commands: z.array(
    z.object({
      command: z.string(),
      description: z.string(),
    })
  ),
});

export const configSchema = z.object({
  metadata: z.object({
    version: z.string(),
    last_updated: z.string(),
    supported_platforms: z.array(z.string()),
  }),
  symlinks: symlinkConfigSchema,
  categories: z.record(z.string(), categorySchema),
});

export type Config = z.infer<typeof configSchema>;
export type PackageDefinition = z.infer<typeof packageDefinitionSchema>;
export type Category = z.infer<typeof categorySchema>;
export type SymlinkConfig = z.infer<typeof symlinkConfigSchema>;


