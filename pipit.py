"""
This script is used to update the global requirements file with the latest versions of the packages in the local requirements file.
"""
import os
import subprocess
from packaging.version import Version


def compare_versions(version1: str, version2: str) -> int:
    """
    Compare two version numbers in major.minor.patch format.

    Args:
        version1 (str): The first version number.
        version2 (str): The second version number.

    Returns:
        int: -1 if version1 < version2, 0 if version1 == version2, 1 if version1 > version2
    """
    v1 = Version(version1)
    v2 = Version(version2)

    if v1 < v2:
        return -1
    elif v1 > v2:
        return 1
    else:
        return 0


def greater_of(a: str, b: str) -> str:
    """ return the greater of the two versions """
    if compare_versions(a, b) == 1:
        return a
    else:
        return b


def read_requirements(file_path: str) -> dict[str, str]:
    """ read the requirements file and return a dictionary indexed by package name with an attribute "version" """
    r: dict[str, str] = {}
    if not os.path.exists(file_path):
        return r
    with open(file_path, "r", encoding="utf-8") as f:
        for line in f.readlines():
            parts = line.split("==")
            if len(parts) == 2:
                r[parts[0].strip()] = parts[1].strip()
    return r


def write_requirements(file_path: str, requirements: dict[str, str]):
    """ write the requirements to a file """
    array = []
    for requirement, version in requirements.items():
        array.append(f"{requirement.strip()}=={version.strip()}".strip())
    sorted_array = sorted(array)
    with open(file_path, "w", encoding="utf-8") as f:
        for line in sorted_array:
            f.write(line + "\n")


def generate_local_requirements(filename: str):
    """ generate the local requirements file """
    result = subprocess.run(["python3", "-m", "pip", "freeze"], env=os.environ, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode != 0:
        raise subprocess.SubprocessError(f"Failed to generate local requirements: {result.stderr.decode('utf-8')}")
    with open(filename, "w", encoding="utf-8") as f:
        f.write(result.stdout.decode("utf-8"))
    return read_requirements(filename)


def main():
    """ main function """

    global_requirements_file = os.path.join(os.path.abspath(".."), "requirements.txt")

    # Read the current "requirements.txt" file
    global_requirements = read_requirements(global_requirements_file)

    # read the local requirements file
    local_requirements_file = os.path.join(os.path.abspath("."), "requirements.txt")
    local_requirements = generate_local_requirements(local_requirements_file)

    # The global requirements index value may be "^1.0.0" format or "==1.0.0" format or ">=1.0.0" format or "~=1.0.0" format or "~1.0.0" format or other format recognized by the pip install command.  iterate through the local_requirments index and if the local_requirments is a later vrrson thatn global requrements or the globl requrements do not exist, then add the local rqurements to the glboal requirements
    for local_requirement, local_version in local_requirements.items():
        global_requirements[local_requirement] = greater_of(local_version, global_requirements.get(local_requirement, local_version))

    write_requirements(global_requirements_file, global_requirements)


if __name__ == "__main__":
    main()
