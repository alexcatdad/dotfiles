/** Real-tool checks in a disposable, disconnected home; synthetic data only. */
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdirSync, writeFileSync, unlinkSync, closeSync, openSync } from "node:fs";
import { homedir, arch } from "node:os";
import { join } from "node:path";

const HOME = homedir();
const FIXTURES = join(HOME, "fixtures");
mkdirSync(FIXTURES, { recursive: true });
type Result = {name: string; passed: boolean; detail?: string; error?: string};
const RESULTS: Result[] = [];
type Options = {env?: NodeJS.ProcessEnv; cwd?: string; timeout?: number; check?: boolean};
function run(args: string[], options: Options = {}) {
  const { check, ...settings } = options;
  const r = spawnSync(args[0], args.slice(1), { encoding: "utf8", timeout: 30000, maxBuffer: 4 * 1024 * 1024, ...settings });
  assert(!r.error, r.error?.message);
  if (check) assert.equal(r.status, 0, r.stderr);
  return { returncode: r.status, stdout: r.stdout ?? "", stderr: r.stderr ?? "" };
}
function shell(code: string, mode = "-ic", options: Options = {}) {
  const r = run(["zsh", mode, code], options);
  assert.equal(r.returncode, 0, JSON.stringify(r));
  assert.equal(r.stderr.trim(), "", r.stderr);
  return r.stdout;
}
function directory(name: string) { const p = join(FIXTURES, name); mkdirSync(p, { recursive: true }); return p; }
function touch(p: string) { closeSync(openSync(p, "a")); }
function check(name: string, fn: () => string) {
  try { const detail = fn(); RESULTS.push({name, passed: true, detail}); console.log("PASS", name); }
  catch (error) { const message = String(error); RESULTS.push({name, passed: false, error: message}); console.log("FAIL", name, message); }
}
function startup() {
  for (const mode of ["-ic", "-lic", "-c", "-lc"]) assert.equal(shell("print READY", mode).trim(), "READY");
  return "Interactive login, interactive non-login, and both non-interactive modes start quietly.";
}
function aliases() {
  const expected = {ls:"eza --icons --group-directories-first", ll:"eza -lag --icons --group-directories-first --git", lt:"eza -T --icons --level=2", la:"eza -a --icons --group-directories-first", tree:"eza -T --icons=auto", grep:"rg --smart-case", find:"fd"};
  for (const [name, expansion] of Object.entries(expected)) assert.equal(shell(`print -r -- $aliases[${name}]`).trim(), expansion);
  assert.equal(shell("for n in g gs gd gc gp gl gco yolo claude-mem zsh-time zsh-trace; do (( ${+aliases[$n]} )) && print PRESENT:$n; done; true").trim(), "");
  return "Seven retained aliases match; ten omitted shell aliases are absent.";
}
function pluginLoading() {
  assert.equal(shell(`
    (( $+functions[_zsh_autosuggest_start] )) || exit 11
    (( $+functions[_alias_tips__preexec] )) || exit 12
    (( $+functions[_zsh_highlight] )) || exit 13
    (( $+functions[compdef] )) || exit 14
    [[ -n \${widgets[complete-word]} ]] || exit 15
    print LOADED
  `).trim(), "LOADED");
  return "Autosuggestions, fast syntax highlighting, alias tips, and native completion load synchronously.";
}
function listing() {
  const p = directory("listing"); touch(join(p, ".hidden")); touch(join(p, "visible file")); mkdirSync(join(p, "folder"), {recursive:true});
  const out = shell('cd "$HOME/fixtures/listing"; ll; la; lt; tree');
  for (const name of [".hidden", "visible file", "folder"]) assert(out.includes(name), out);
  return "All listing modes execute against hidden files, spaced names, and directories.";
}
function functions() {
  assert.equal(shell("for n in duf suggest-aliases; do (( ${+functions[$n]} )) || exit 1; done; for n in extract mkcd serve myip localip note zf weather cheat calc killnamed backup gcof gshow git-cleanup git-amend gadd gstash glog gfind gblame paw-sync paw-sync-bg paw-sync-full-bg; do (( ${+functions[$n]} )) && print PRESENT:$n; done; true").trim(), "");
  assert(shell('duf "$HOME/fixtures/listing"').includes("visible file")); directory("empty");
  assert.equal(shell('duf "$HOME/fixtures/empty"').trim(), "");
  return "Only the two selected custom utilities remain; duf handles spaced names and empty directories.";
}
function environment() {
  assert(shell("source ~/.config/shell/path.zsh; source ~/.config/shell/path.zsh; typeset -a unique_path; unique_path=( ${(u)path} ); (( $#path == $#unique_path )) || exit 1; print ${(j.:.)path}").length > 0);
  assert(!shell("print -r -- ${(k)parameters[(R)*export*]}").includes("LC_ALL"));
  assert(!shell("print ${(k)functions}", "-c").includes("_alias_tips__preexec"));
  return "PATH remains unique; optional runtimes and interactive plugins are not required by the baseline.";
}
function gitPreferences() {
  const expected = {"init.defaultBranch":"main", "pull.rebase":"true", "push.default":"current", "push.autoSetupRemote":"true", "fetch.prune":"true", "merge.conflictstyle":"zdiff3", "rerere.enabled":"true", "rerere.autoupdate":"false", "rebase.autoSquash":"true", "diff.algorithm":"histogram", "core.autocrlf":"input"};
  for (const [key,value] of Object.entries(expected)) assert.equal(run(["git","config","--get",key]).stdout.trim(),value);
  assert.equal(run(["git","config","--get-regexp","^alias\\."]).returncode,1);
  const p = directory("git-ignore"); run(["git","init",p],{check:true}); touch(join(p,".DS_Store"));
  assert.equal(run(["git","-C",p,"check-ignore",".DS_Store"]).returncode,0);
  assert.equal(run(["git-lfs","version"]).returncode,0);
  return "Shared Git settings, global ignore, no custom aliases, and LFS availability verified in a fixture repository.";
}
function fnmSwitching() {
  for (const [name,version] of [["node22","22.23.3"],["node24","24.21.0"]]) writeFileSync(join(directory(name),".node-version"),version+"\n");
  const out = shell('cd "$HOME/fixtures/node22"; node --version; cd "$HOME/fixtures/node24"; node --version; bun --version', '-ic', {env:{...process.env,DOTFILES_RUNTIMES:'bun,fnm'}});
  for (const version of ["v22.23.3","v24.21.0","1.4.2"]) assert(out.includes(version),out);
  return "Explicit opt-in runtime fixture switches Node 22→24 offline; Bun remains a test/runtime option.";
}
function direnvEnvironment() {
  const p = directory("direnv-project"); writeFileSync(join(p,".envrc"),"export DOTFILES_FIXTURE_FLAG=project-only\n");
  assert.equal(run(["direnv","allow",p]).returncode,0);
  const code = `cd "$HOME/fixtures/direnv-project"
    eval "$(direnv export zsh 2>/dev/null)"
    [[ $DOTFILES_FIXTURE_FLAG == project-only ]] || exit 1
    cd "$HOME"
    eval "$(direnv export zsh 2>/dev/null)"
    (( ! \${+DOTFILES_FIXTURE_FLAG} )) || exit 2
    print RESTORED`;
  assert(shell(code,"-ic",{env:{...process.env,DIRENV_LOG_FORMAT:""}}).includes("RESTORED"));
  return "Approved project environment loads and unloads without leaking into the next directory.";
}
function historyAndSuggestions() {
  const out = shell(`for i in 1 2 3; do
    fixture_id=$(atuin history start 'echo fixture-repeated-command')
    atuin history end --exit 0 "$fixture_id"
  done
  suggest-aliases 2 5
  bindkey '^R'
  [[ $precmd_functions == *atuin* ]] || exit 3`);
  for (const text of ["fixture-repeated-command","alias ef=","atuin-search"]) assert(out.includes(text),out);
  return "Real Atuin fixture history feeds suggest-aliases; Ctrl-R is bound to Atuin search.";
}
function aliasTip() {
  const full = "eza -lag --icons --group-directories-first --git";
  assert.equal(shell(`_alias_tips__preexec '${full}'`).trim(), "Alias tip: ll");
  assert.equal(shell(`_alias_tips__preexec '${full} private-looking-fixture'`).trim(), "Alias tip: ll");
  for (const text of ["ll", "ll synthetic-argument", "no-such-fixture-command", "ezalphabet --icons --group-directories-first", "eza -lag --icons --group-directories-first --git-extra"]) {
    assert.equal(shell(`_alias_tips__preexec '${text}'`).trim(), "", text);
  }
  const marker = join(FIXTURES, "alias-substitution-must-not-execute");
  // The hook receives literal shell syntax as data, as it does from preexec.
  assert.equal(shell(`_alias_tips__preexec '${full} $(touch "${marker}")'; [[ ! -e '${marker}' ]] || exit 31`).trim(), "Alias tip: ll");
  return "Native Zsh reminders select ll with arguments, stay silent for aliases/nonmatches/token prefixes, print only the alias name, and never execute command-substitution text.";
}
function prompt() {
  const r = run(["starship","prompt","--status","0","--path",HOME],{env:{...process.env,STARSHIP_LOG:"error"}});
  assert.equal(r.returncode,0,r.stderr); assert.equal(r.stderr.trim(),"",r.stderr);
  assert(r.stdout.length>30 && r.stdout.includes("\x1b["),JSON.stringify(r.stdout));
  return "Preserved prompt renders colored segments without configuration errors. Font appearance is outside container scope.";
}
function completions() {
  assert.equal(shell("[[ ${fpath[(r)*/zsh-completions]} != '' ]] || exit 2; print COMPLETE").trim(),"COMPLETE");
  assert.equal(shell("(( $+functions[_bun] )) || exit 1; print OPTIONAL_BUN", "-ic", {env:{...process.env,DOTFILES_RUNTIMES:'bun'}}).trim(), "OPTIONAL_BUN");
  return "Native additional completions load; Bun completion loads only in the explicitly selected runtime fixture.";
}
function privateOverrides() {
  let p = join(HOME,".zshrc.local"); writeFileSync(p,"alias fixture-local='print local-ok'\n");
  try { assert.equal(shell("fixture-local").trim(),"local-ok"); } finally { unlinkSync(p); }
  p = join(HOME,".gitconfig.local"); writeFileSync(p,"[user]\n name = Container Fixture\n");
  try { assert.equal(run(["git","config","user.name"]).stdout.trim(),"Container Fixture"); } finally { unlinkSync(p); }
  return "Local overrides load without placing personal identity in shared files.";
}
function terminalHistoryUI() {
  const r = run(["/tests/history-pty"],{timeout:40000}); assert.equal(r.returncode,0,r.stderr);
  return "Actual pseudo-terminal Ctrl-R search displays fixture history and cancels without executing it.";
}
function goRuntime() {
  const p = directory("go-offline"); writeFileSync(join(p,"main.go"),'package main\nimport "fmt"\nfunc main() { fmt.Println("GO_READY") }\n');
  const r = run(["go","run","main.go"],{cwd:p,env:{...process.env,GOTOOLCHAIN:"local",GOPROXY:"off",GOSUMDB:"off"},timeout:120000});
  assert.equal(r.returncode,0,r.stderr); assert.equal(r.stdout.trim(),"GO_READY");
  return "Installed Go compiles and runs a synthetic program offline without fetching a toolchain or modules.";
}
function connectivityTools() {
  for (const args of [["ssh","-V"],["jq","-n",'{"available":true}']]) assert.equal(run(args).returncode,0);
  return "SSH and jq execute. Tailscale remains an optional native integration; no enrollment or remote access is attempted.";
}
function noPythonDependency() {
  assert.equal(shell("(( ! $+commands[python] && ! $+commands[python3] )) || exit 32; print PYTHON_FREE").trim(), "PYTHON_FREE");
  return "Neither Python nor Python 3 is installed in the validation container; runner and alias tips work without them.";
}
const checks: [string,()=>string][] = [
  ["shell startup modes",startup],["retained and omitted aliases",aliases],
  ["plugin and completion loading",pluginLoading],["listing behavior",listing],
  ["custom functions",functions],["PATH and non-interactive isolation",environment],
  ["Git preferences",gitPreferences],["fnm project switching and Bun",fnmSwitching],
  ["direnv project isolation",direnvEnvironment],["Atuin history and alias suggestions",historyAndSuggestions],
  ["alias tips reminder",aliasTip],["Starship prompt",prompt],
  ["Bun and additional completions",completions],["private override boundaries",privateOverrides],
  ["interactive Ctrl-R history UI",terminalHistoryUI],["connectivity clients and jq",connectivityTools],
  ["Go offline compilation",goRuntime],
  ["Python-free baseline",noPythonDependency],
];
for (const [name,fn] of checks) check(name,fn);
const versions: Record<string,string[]> = {};
for (const [tool,args] of Object.entries({zsh:["--version"],git:["--version"],jq:["--version"],eza:["--version"],atuin:["--version"],fnm:["--version"],bun:["--version"],go:["version"],starship:["--version"]})) {
  try { versions[tool] = run([tool,...args]).stdout.trim().split("\n"); }
  catch(error) { versions[tool] = [String(error)]; }
}
const report = {uid:process.getuid?.(),architecture:arch()==="arm64"?"aarch64":arch(),checks:RESULTS,versions,passed:RESULTS.every(r=>r.passed)};
writeFileSync("/results/report.json",JSON.stringify(report,null,2)+"\n");
console.log(JSON.stringify(report,null,2));
process.exit(report.passed?0:1);
