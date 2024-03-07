# Linters

This project provides a set of linters to help developers to follow the best practices and guidelines defined in the project.
These linters are available as GitHub workflows and are automatically run to check the code at the time we submit a PR.


Linter | Description | Branch | File
---------|----------|---------|--------
 Megalinter | Even though Megalinter provides verification for a variety of code and documentation files, we are using Megalinter to verify: yaml, markdown,and json files. | main, dev | [.github/workflows/mega-linter.yml](../../.github/workflows/mega-linter.yml)

## YAML

Megalinter uses [yamllint](https://megalinter.io/latest/descriptors/yaml_yamllint/) to lint for YAML syntax and [prettier](https://megalinter.io/latest/descriptors/yaml_prettier/) for enforcing consistent code formatting in YAML files. While yamllint checks for correct YAML syntax, prettier focuses on code style and formatting, ensuring that YAML code follows a more readable structure.
We disabled Prettier in this repository, as we reuse solutions from AIO Product Group and Edge Computing Tech Domain. We will use the YAML format from the source where we based our own YAML customized version.

## Markdown

Megalinter uses [markdownlint](https://megalinter.io/latest/descriptors/markdown_markdownlint/) to perform comprehensive linting on markdown files. We use [markdown-link-check](https://megalinter.io/latest/descriptors/markdown_markdown_link_check/) to check the links within markdown files, ensuring that all references and URLs are accurate.

## Manual Linting

In case you want to locally run the linters, follow the steps below. Make sure to use the same configuration files used in the GitHub workflows to ensure the same results.

### Megalinter

For the Megalinter, follow the steps provided in the [megalinter.io-run locally](https://megalinter.io/latest/mega-linter-runner/).

If you want to fix a non-blocking error via prettier on a YAML file when running megalinter or you want to use prettier in your YAML file, you can execute the following commands to apply the improvement to your file:

```bash
npm install --global prettier

prettier --write <path-to-file>
```