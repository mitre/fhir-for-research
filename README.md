# FHIR for Research

**The content in this repository is under active development. Please proceed with caution.**

GitHub Actions automatically builds commits to the `main` branch to <https://mitre.github.io/fhir-for-research>.

----

## Dependencies

- [Quarto](https://quarto.org/docs/get-started/)
- R
- Jupyter and Python3 (if you use embedded Python)

Python uses `venv` (https://quarto.org/docs/projects/virtual-environments.html):

You will need to create a `venv` in `python_env/`:

    python3 -m venv python_env

Then run `source python_env/bin/activate` to activate the `venv`, and the following command to install dependencies:

    pip install -r requirements.txt

If you add a dependency, run `pip freeze > requirements.txt` to update the requirements file.

Better git support for Jupyter Notebooks is provided by [`nbdime`](https://nbdime.readthedocs.io/) and configured via the `.gitattributes` file. For more information, see [here](https://nbdime.readthedocs.io/en/latest/vcs.html).

## Quick start

- Clone this repository
- Run `quarto preview` (this will compile everything, start a local web server, and launch web browser to show the content form the server)

----

## License

Copyright 2023 The MITRE Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

----

MITRE: Approved for Public Release / Case #23-0966