"""
Command file for Sphinx documentation
"""

import gettext
import argparse
import subprocess
import os
import sys
import shutil

import importlib.metadata

from core_docs._version import __version__

# Set up gettext for internationalization
locale_path = os.path.join(os.path.dirname(__file__), "locale")
gettext.bindtextdomain("builder", locale_path)
gettext.textdomain("builder")
_ = gettext.gettext


def run_cmd(cmd: str) -> str:
    """
    Simple wrapper ot run an OS command and save the output of that command into a string.
    Used to run "sphinx" in this program
    :param cmd: The command to execute
    :return: the output of the execution
    """
    process = subprocess.Popen(
        cmd,
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        env=os.environ,
    )
    stdout, _ = process.communicate()
    data = stdout.decode("utf-8") if stdout else ""
    return data


def sphinx_command() -> str | None:
    """
    This function will return None if the python module is not found.

    :return:
    """
    cmd = os.getenv("SPHINXBUILD", None)
    if cmd:
        return cmd

    for pkg in importlib.metadata.distributions():
        if pkg.name == "Sphinx":
            return "sphinx-build"

    return None


# gen trading
def build(doc_name: str):
    cmd = sphinx_command()
    if cmd is None:
        print(
            "\nThe Sphinx python module was not found. Make sure you have Sphinx installed"
        )
        print('\nInstall sphinx with "pip install sphinx"')
        print("See: http://sphinx-doc.org/")
        return

    source_dir = os.path.abspath(
        os.path.join(os.path.dirname(__file__), "..", doc_name)
    )
    destination_dir = os.path.abspath(
        os.path.join(os.path.dirname(__file__), "..", "build", doc_name)
    )

    # if the desitination dir exists, delete it:
    if os.path.exists(destination_dir):
        print(f"Removing existing destination directory: {destination_dir}")
        # delete all files and folders in this subdirectory
        shutil.rmtree(destination_dir)

    lint_cmd = f"doc8 {source_dir}"

    result = run_cmd(lint_cmd)

    print(result)

    full_cmd = f"{cmd} -M html {source_dir} {destination_dir}"

    print(f"Running: {full_cmd}")

    result = run_cmd(full_cmd)

    print(result)


def docs():
    print("Building user documentation")
    build("docs")


def deploy():
    print("Deploying documentation")
    print("Not implemented yet")


CHOICES = {"docs": docs, "deploy": deploy}


def main():

    parser = argparse.ArgumentParser(
        description=f"Core-Docs v{__version__}\n\nBuild Sphinx documentation for core automation",
        formatter_class=argparse.RawTextHelpFormatter,
        epilog=f"Example: build user\n\nPython version: {sys.version}\n ",
    )

    parser.add_argument(
        "command",
        metavar="command",
        choices=CHOICES.keys(),
        nargs=1,
        type=str,
        help="Command to perform:\n"
        "   docs: build the docuenataton\n"
        "   deploy: deploy documentation to web site"
    )

    parser.add_argument(
        "-v", "--version", action="version", version=f"core-docs v{__version__}"
    )
    parms = parser.parse_args()

    if parms.command[0] in CHOICES:
        CHOICES.get(parms.command[0])()
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
