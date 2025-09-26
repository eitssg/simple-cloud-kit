from typing import Any
import os
import json
import sys
import subprocess
import argparse
import tomlkit
from tomlkit.toml_document import TOMLDocument


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

    finally:
        os.chdir(cur_dir)


def set_project_version(poetry_content, data: dict):

    # as we use poetry-dynamic-versioning, this isn't required, it's just fun!
    project_version = data["project"]["version"]

    poetry_content["version"] = project_version
    poetry_content["keywords"] = ["sck", "core", "aws", "cloud", "automation"]


def get_module(project: str, data: dict) -> dict:

    for module in data["modules"]:
        if module["name"] == project:
            return module

    raise Exception(f"   No module found for {project}")


def update_project_dependencies(poetry_content, module: str, data: dict):

    project_version = data["project"].get("version", "0.0.1")
    develop = data["project"].get("develop", False)

    module_data = get_module(module, data)

    dependson = module_data["dependsOn"]

    # Make sure that all project dependencies are listed in the TOML with the right version
    dependencies = poetry_content["dependencies"]
    for depend in dependson:
        if develop:
            dependencies[depend] = {"path": f"../{depend}", "develop": True}
        else:
            dependencies[depend] = f"^{project_version}"

    # If this project has a listed depency, then get it's version and update the TOML
    for dependency in dependencies.keys():
        version = data["dependencies"].get(dependency)
        if version:
            dependencies[dependency] = version

    poetry_groups = poetry_content["group"]
    dev_group = poetry_groups.get("dev")
    if not dev_group:
        poetry_groups["dev"] = tomlkit.table()
        poetry_groups["dev"]["dependencies"] = tomlkit.table()

    dev_dependencies = poetry_content["group"]["dev"]["dependencies"]
    for dependency in dev_dependencies.keys():
        version = data["dev-dependencies"].get(dependency)
        if version:
            dev_dependencies[dependency] = version


def update_toml_dependencies(module: str, data: dict):

    try:
        toml_file = f"{module}/pyproject.toml"

        if not os.path.exists(toml_file):
            raise Exception(f"   No pyproject.toml file found in {module}")

        with open(toml_file, "r") as f:
            toml_content: TOMLDocument = tomlkit.parse(f.read())

        tool_content = toml_content["tool"]  # type: ignore
        if not tool_content:
            raise Exception("   No tool section found in pyproject.toml")

        poetry_content: Any = tool_content["poetry"]  # type: ignore
        if not poetry_content:
            raise Exception("   No poetry section found in pyproject.toml")

        set_project_version(poetry_content, data)
        update_project_dependencies(poetry_content, module, data)

        with open(toml_file, "w") as f:
            f.write(toml_content.as_string())
    except Exception as e:
        print(e)


def load_requirement() -> dict:

    if not os.path.exists("versions.json"):
        raise Exception("No versions.json file found")

    with open("versions.json", "r") as f:
        return json.loads(f.read())


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
        print(f"Updating {module}")
        update_toml_dependencies(module, data)
        ensure_git_tag_exists(module, data)


def main():
    global move_tag

    try:
        p = argparse.ArgumentParser()
        p.add_argument("--move-tag", action="store_true", required=False)
        args = p.parse_args()
        if args.move_tag:
            move_tag = True

        update_requirements()

    except Exception as e:
        print(e)
        sys.exit(1)


if __name__ == "__main__":
    main()
