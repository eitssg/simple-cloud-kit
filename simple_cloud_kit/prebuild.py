import os
import json
import sys
import subprocess
import argparse
from packaging.specifiers import SpecifierSet
from packaging.version import Version
from rich.console import Console

console = Console(file=sys.stdout, force_terminal=True)


class RichConsoleStream:
    def __init__(self, console: Console, err: bool = False):
        self.console = console
        self.err = err

    def write(self, text: str):
        if self.err:
            self.console.print(text, end="", style="red")  # Use Rich Console for error output
        else:
            self.console.print(text, end="")  # Use Rich Console for normal output

    def flush(self):
        pass  # No-op; Rich Console handles flushing


sys.stdout = RichConsoleStream(console)
sys.stderr = RichConsoleStream(console, err=True)

move_tag = False


def ensure_git_tag_exists(module: str, data: dict):

    project_version = data["project"].get("version", "0.0.1")
    git_tag = f"v{project_version}"

    cur_dir = os.getcwd()

    # change working dierectory to the module directiry
    os.chdir(module)

    try:
        # Commit all changes
        try:
            # Call black formatter
            subprocess.run(["black", "."], check=True)

            # Commit all changes
            subprocess.run(["git", "add", "--all"], check=True)
            subprocess.run(["git", "commit", "-m", f"Version {project_version}"], check=True)

            # push the changes
            subprocess.run(["git", "push"], check=True)
        except subprocess.CalledProcessError:
            pass

        # check if the git tag exists
        # get all of the git tags into a result
        result = subprocess.run(["git", "tag", "-l"], capture_output=True, text=True, check=True)
        git_tags = result.stdout.splitlines()

        if git_tag in git_tags:
            print(f"   Git tag {git_tag} exists")
            if not move_tag:
                return

            # delete the tag from the origin
            subprocess.run(["git", "push", "--delete", "origin", git_tag], check=True)

            # delete the tag from the local
            subprocess.run(["git", "tag", "-d", git_tag], check=True)

        # create a git tag
        subprocess.run(["git", "tag", git_tag], check=True)
        print(f"   Git tag {git_tag} created")

        # push the git tag
        subprocess.run(["git", "push", "origin", git_tag], check=True)
        print(f"   Git tag {git_tag} pushed")

    except subprocess.CalledProcessError as e:
        print(f"[bold red]Failed to ensure git tag exists: {e.stderr}[/]")
        sys.exit(1)
    finally:
        os.chdir(cur_dir)


def set_project_version(module: str, data: dict):

    try:

        project_version = data["project"]["version"]
        result = subprocess.run(f"uv -q sync --all-extras", check=True)
        result = subprocess.run(f"uv -q version {project_version} --no-sync ", check=True)
        if result.returncode != 0:
            raise Exception(f"   Failed to set project version to {project_version}")

    except Exception as e:
        print(f"[bold red]{e}[/]")
        sys.exit(1)


def get_module(project: str, data: dict) -> dict:

    for module in data["modules"]:
        if module["name"] == project:
            return module

    raise Exception(f"   No module found for {project}")


def get_module_dependencies() -> dict:

    try:
        versions = {}

        cmd = "uv export --format requirements.txt --no-hashes --no-header --no-annotate"
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, check=True)
        if result.returncode != 0:
            raise Exception(f"   Failed to get module dependencies: {result.stderr}")
        dependencies = result.stdout.splitlines()
        dependencies.pop(0)  # remove the "'-e .' line"
        for line in dependencies:
            parts = line.split("==")
            if len(parts) < 2:
                continue
            name = parts[0].strip("'")
            version = parts[1].split(" ")[0].strip("'")
            versions[name] = version
        return versions
    except subprocess.CalledProcessError as e:
        print(f"[bold red]Failed to get module dependencies: {e.stderr}[/]")
        sys.exit(1)
    except Exception as e:
        print(f"[bold red]{e}[/]")
        sys.exit(1)


def matches(version_str: str, requirement_str: str) -> bool:
    spec = SpecifierSet(requirement_str)  # e.g. ">=1.0.0,<3.0"
    v = Version(version_str)  # e.g. "1.2.3"
    return v in spec


def update_project_dependencies(module: str, data: dict):

    try:
        cur_dir = os.getcwd()
        os.chdir(module)

        project_version = data["project"]["version"]
        print(f"   Setting project version to: [bold red]{project_version}[/]. [bold yellow]Please wait[/]...", end="")

        set_project_version(module, data)

        module_data = get_module(module, data)

        for depend in module_data["dependsOn"]:
            subprocess.run(f"uv -q add ../{depend} --editable", check=True)

        installed_dependencies = get_module_dependencies()

        print(f"[bold green]done.[/]")

        for dependency, common_version in data["dependencies"].items():

            installed_version = installed_dependencies.get(dependency)
            if installed_version is None:
                continue

            if matches(installed_version, common_version):
                print(
                    f"   Dependency: [bold green]{dependency}[/] is up to date [green]{installed_version}[/] is in ([green]{common_version}[/])"
                )
                continue

            print(
                f"   Updating dependency: [bold red]{dependency}[/] [green]{installed_version}[/] to version ([green]{common_version}[/])...",
                end="",
            )
            # subprocess.run(f"uv -q add {dependency}@{common_version}", check=True)
            print(f"[bold green]done.[/]")

        print(f"[bold green]All dependencies updated.[/]")

    except Exception as e:
        print(f"[bold red]{e}[/]")
        sys.exit(1)

    finally:
        os.chdir(cur_dir)


def update_toml_dependencies(module: str, data: dict):

    try:
        toml_file = f"{module}/pyproject.toml"

        if not os.path.exists(toml_file):
            raise Exception(f"   No pyproject.toml file found in {module}")

        update_project_dependencies(module, data)

    except Exception as e:
        print(f"[bold red]{e}[/]")


def load_requirement() -> dict:

    try:
        versions_file = os.path.join(os.path.abspath(os.path.dirname(__file__)), "data", "versions.json")

        print(f"[bright_black]Loading {versions_file}[/]")

        if not os.path.exists(versions_file):
            raise Exception("No versions.json file found")

        with open(versions_file, "r") as f:
            return json.loads(f.read())
    except Exception as e:
        print(f"[bold red]Failed to load versions.json file: {e}[/]")
        sys.exit(1)


def get_modules_list(modules: list) -> list:
    modules_list = []
    for module in modules:
        dependsOn = module.get("dependsOn")
        for depend in dependsOn:
            if depend not in modules_list:
                modules_list.append(depend)
        modules_list.append(module.get("name"))
    return modules_list


def update_requirements():

    data = load_requirement()
    modules_list = get_modules_list(data["modules"])

    for module in modules_list:
        print(f"[green bold]Updating:[/] [white]{module}[/]")
        update_toml_dependencies(module, data)
        # ensure_git_tag_exists(module, data)


def main():
    global move_tag

    print("[green]Starting prebuild process")

    try:
        p = argparse.ArgumentParser(description="Prebuild script for Simple Cloud Kit")
        p.add_argument(
            "--move-tag", action="store_true", required=False, default=False, help="[yellow]Move the git tag to the new version[/]"
        )
        args = p.parse_args()
        if args.move_tag:
            move_tag = True

        update_requirements()

    except Exception as e:
        print(f"[bold red]{e}[/]")
        sys.exit(1)


if __name__ == "__main__":
    main()
