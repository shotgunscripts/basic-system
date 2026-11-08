"""Build the GitHub bundle and its matching Roblox model with Python 3 and Rojo."""

import argparse
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

SOURCE = Path(__file__).resolve().parent.parent
OUTPUT = SOURCE.parent
BUNDLE = "Basic-System.server.json"
MODEL = "Basic-System-GitHub.rbxm"
FORMAT = "basic-system-server-v1"
MAX_BYTES = 900_000
DISABLED_COMMAND = "IncludedCommands/BuildUtility/s.luau"


def server_sources():
    modules = {}
    for file in sorted((SOURCE / "src").rglob("*.luau")):
        key = file.relative_to(SOURCE / "src").as_posix()
        included = key.startswith(("Server/", "Common/", "IncludedCommands/"))
        if key == DISABLED_COMMAND or key.startswith("IncludedCommands/Local/"):
            continue
        if key == "init.luau" or included:
            if key.endswith((".server.luau", ".client.luau")):
                continue
            modules[key] = file.read_text(encoding="utf-8-sig")
    return modules


def write_bundle(modules):
    project = json.loads((SOURCE / "default.project.json").read_text(encoding="utf-8"))
    notices = project["tree"]["BasicSystemLicenses"]["$properties"]["Value"]
    data = json.dumps(
        {"format": FORMAT, "modules": modules, "notices": notices},
        ensure_ascii=False, separators=(",", ":"),
    ).encode("utf-8") + b"\n"
    if len(data) > MAX_BYTES:
        raise SystemExit(f"{BUNDLE} is {len(data)} bytes. The limit is {MAX_BYTES}.")
    (OUTPUT / BUNDLE).write_bytes(data)
    print(f"Wrote {BUNDLE} with {len(modules)} modules ({len(data):,} bytes).")


def proxy_source(key, client_source):
    core = 'script' if key == "init.luau" else 'script:FindFirstAncestor("BasicSystem")'
    proxy = (
        f"local Core = {core}\n"
        'local Runtime = require(Core:WaitForChild("GitHubRuntime"))\n'
        f"return Runtime.Run({json.dumps(key)}, script)\n"
    )
    if client_source is None:
        return "--Server module loaded from GitHub.\n" + proxy

    server_branch = "".join(f"    {line}\n" for line in proxy.splitlines())
    return (
        '--The native module remains available to the Roblox client.\n'
        'if game:GetService("RunService"):IsServer() then\n'
        f"{server_branch}end\n\n{client_source}"
    )


def build_model(modules, rojo):
    with tempfile.TemporaryDirectory(prefix="basic-system-github-") as temp:
        project = Path(temp)
        for folder in ("src", "Packages", "module"):
            shutil.copytree(SOURCE / folder, project / folder)
        for name in ("module.project.json", "BasicSystemMain.luau", "BasicSystemSettings.luau"):
            shutil.copyfile(SOURCE / name, project / name)
        for name in ("BasicSystemGitHubLoader.server.luau", "BasicSystemGitHubSettings.luau"):
            shutil.copyfile(SOURCE / "github" / name, project / name)

        (project / "src" / DISABLED_COMMAND).unlink(missing_ok=True)
        for key, source in modules.items():
            # Common modules and included commands can be cloned into the client.
            client_source = None if key == "init.luau" or key.startswith("Server/") else source
            (project / "src" / key).write_text(proxy_source(key, client_source), encoding="utf-8")
        shutil.copyfile(SOURCE / "github" / "GitHubRuntime.luau", project / "src" / "GitHubRuntime.luau")
        names = ",\n".join(f"    {json.dumps(key)}" for key in modules)
        (project / "src" / "GitHubModuleList.luau").write_text("return {\n" + names + "\n}\n", encoding="utf-8")

        config = json.loads((SOURCE / "default.project.json").read_text(encoding="utf-8"))
        config["name"] = "Basic System GitHub"
        tree = config["tree"]
        tree["$className"] = "Model"
        del tree["BasicSystemLoader"]
        tree["BasicSystemGitHubLoader"] = {"$path": "BasicSystemGitHubLoader.server.luau"}
        tree["BasicSystemGitHubSettings"] = {"$path": "BasicSystemGitHubSettings.luau"}
        (project / "default.project.json").write_text(json.dumps(config), encoding="utf-8")
        subprocess.run([rojo, "build", str(project / "default.project.json"), "-o", str(OUTPUT / MODEL)], check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bundle-only", action="store_true", help="Skip rebuilding the Roblox model")
    parser.add_argument("--rojo", default="rojo", help="Path to the Rojo executable")
    args = parser.parse_args()
    modules = server_sources()
    write_bundle(modules)
    if not args.bundle_only:
        build_model(modules, args.rojo)


if __name__ == "__main__":
    main()
