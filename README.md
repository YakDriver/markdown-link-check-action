# GitHub Action - Markdown link check 🔗✔️
[![GitHub Marketplace](https://img.shields.io/badge/GitHub%20Marketplace-MD%20Link%20Check-brightgreen?style=for-the-badge)](https://github.com/marketplace/actions/md-check-links)

**md-check-links** checks Markdown files for broken links using [tcort/markdown-link-check](https://github.com/tcort/markdown-link-check).

You can use **md-check-links** as a Docker image from the command line or as a GitHub Action, giving you parity between the two approaches. This is useful for having a command line check that is equivalent to the GitHub Action.

## How to use
1. Create a new file in your repository `.github/workflows/action.yml`.
1. Copy-paste the following workflow in your `action.yml` file:

```yml
name: Documentation Checks

on:
  push:
    branches:
      main
pull_request:
  paths:
    - docs/**

jobs:
  md-check-links:
    runs-on: ubuntu-latest
    env:
      UV_THREADPOOL_SIZE: 128
    steps:
      - uses: actions/checkout@a5ac7e51b41094c92402da3b24376905380afc29 # v4.1.6
      - uses: YakDriver/md-check-links@latest
        with:
          quiet: 'yes'
          verbose: 'yes'
          config: '.ci/.markdownlinkcheck.json'
          directory: 'docs'
          extension: '.md'
          branch: "main"
          modified: "yes"
   ```

## Configuration

- [Custom variables](#custom-variables)
- [Scheduled runs](#scheduled-runs)
- [Disable check for some links](#disable-check-for-some-links)
- [Check only modified files in a pull request](#check-only-modified-files-in-a-pull-request)
- [Check multiple directories and files](#check-multiple-directories-and-files)
- [Status code 429: Too many requests](#too-many-requests)
- [GitHub links failure fix](#github-links-failure-fix)

### Custom variables
You customize the action by using the following variables:

| Variable | Description | Default value |
|:----------|:--------------|:-----------|
|`quiet`| Specify `yes` to only show errors in output.| `no`|
|`verbose`|Specify `yes` to show detailed HTTP status for checked links. |`no` |
|`config`|Specify a [custom configuration file](https://github.com/tcort/markdown-link-check#config-file-format) for markdown-link-check. You can use it to remove false-positives by specifying replacement patterns and ignore patterns. The filename is interpreted relative to the repository root.|`mlc_config.json`|
|`directory` |By default the `github-action-markdown-link-check` action checks for all markdown files in your repository. Use this option to limit checks to only specific folders. Use comma separated values for checking multiple folders. |`.` |
|`depth` |Specify how many levels deep you want to check in the directory structure. The default value is `-1` which means check all levels.|`-1` |
|`modified` |Use this variable to only check modified markdown files instead of checking all markdown files. The action uses `git` to find modified markdown files. Only use this variable when you run the action to check pull requests.|`no`|
|`branch`|Use this variable to specify the branch to compare when finding modified markdown files. |`main`|
|`extension`|By default the `github-action-markdown-link-check` action checks files in your repository with the `.md` extension. Use this option to specify a different file extension such as `.markdown` or `.mdx`.|`.md`|
|`file` | Specify additional files (with complete path and extension) you want to check. Use comma separated values for checking multiple files. See [Check multiple directories and files](#check-multiple-directories-and-files) section for usage.| - |
|`prefix` | Prefix of files to check. | - |

#### Sample workflow with variables

```yml
name: Check Markdown links

on: push

jobs:
  markdown-link-check:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master
    - uses: yakdriver/md-check-links@v2
      with:
        quiet: 'yes'
        verbose: 'yes'
        config: 'mlc_config.json'
        directory: 'docs/markdown_files'
        depth: 2
```

### Scheduled runs
In addition to checking links on every push, or pull requests, its also a good
hygiene to check for broken links regularly as well. See
[Workflow syntax for GitHub Actions - on.schedule](https://help.github.com/en/actions/reference/workflow-syntax-for-github-actions#onschedule)
for more details.

#### Sample workflow with scheduled job

```yml
name: Check Markdown links

on:
  push:
    branches:
    - main
  schedule:
  # Run everyday at 9:00 AM (See https://pubs.opengroup.org/onlinepubs/9699919799/utilities/crontab.html#tag_20_25_07)
  - cron: "0 9 * * *"

jobs:
  markdown-link-check:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master
    - uses: yakdriver/md-check-links@v2
      with:
        quiet: 'yes'
        verbose: 'yes'
        config: 'mlc_config.json'
        directory: 'docs/markdown_files'
```

### Disable check for some links
You can include the following HTML comments into your markdown files to disable
checking for certain links in a markdown document.

1. `<!-- markdown-link-check-disable -->` and `<!-- markdown-link-check-enable-->`: Use these to disable links for all links appearing between these
    comments.
   - Example:
     ```md
     <!-- markdown-link-check-disable -->
     ## Section

     Disbale link checking in this section. Ignore this [Bad Link](https://exampleexample.cox)
     <!-- markdown-link-check-enable -->
     ```
2. `<!-- markdown-link-check-disable-next-line -->` Use this comment to disable link checking for the next line.
3. `<!-- markdown-link-check-disable-line -->` Use this comment to disable link
   checking for the current line.

### Check only modified files in a pull request

Use the following workflow to only check links in modified markdown files in a pull request.

When you use this variable, the action finds modified files between two commits:
- latest commit in you PR
- latest commit in the `main` branch. If you are using a different branch to merge PRs, specify the branch using `branch`.

```yml
on: [pull_request]
name: Check links for modified files
jobs:
  markdown-link-check:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master
    - uses: yakdriver/md-check-links@v2
      with:
        quiet: 'yes'
        verbose: 'yes'
        modified: 'yes'
```

### Check multiple directories and files

```yml
on: [pull_request]
name: Check links for modified files
jobs:
  markdown-link-check:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master
    - uses: yakdriver/md-check-links@v2
      with:
        quiet: 'yes'
        directory: 'md/dir1, md/dir2'
        file: './README.md, ./LICENSE, ./md/file4.markdown'
```

### Too many requests

Use `retryOn429`, `retry-after`, `retryCount`, and `fallbackRetryDelay` in your custom configuration file. See https://github.com/tcort/markdown-link-check#config-file-format for details.

Or mark 429 status code as alive:
```json
{
  "aliveStatusCodes": [429, 200]
}
```

### GitHub links failure fix
Use the following `httpHeaders` in your custom configuration file to fix GitHub links failure.

```json
{
  "httpHeaders": [
    {
      "urls": ["https://github.com/", "https://guides.github.com/", "https://help.github.com/", "https://docs.github.com/"],
      "headers": {
        "Accept-Encoding": "zstd, br, gzip, deflate"
      }
    }
  ]
}
```

## Example Usage

Consider a workflow file that checks for the status of hyperlinks on push to the main branch,

``` yml
name: Check .md links

on:
  push: [main]

jobs:
  markdown-link-check:
    runs-on: ubuntu-latest
    # check out the latest version of the code
    steps:
    - uses: actions/checkout@v3

    # Checks the status of hyperlinks in .md files in verbose mode
    - name: Check links
      uses: yakdriver/md-check-links@v2
      with:
        verbose: 'yes'
```

## Versioning
GitHub Action - Markdown link check follows the [GitHub recommended versioning strategy](https://github.com/actions/toolkit/blob/master/docs/action-versioning.md).

1. To use a specific released version of the action ([Releases](https://github.com/yakdriver/md-check-links/releases)):
   ```yml
   - uses: yakdriver/md-check-links@1.0.1
   ```
1. To use a major version of the action:
   ```yml
   - uses: yakdriver/md-check-links@v2
   ```
1. You can also specify a [specific commit SHA](https://github.com/yakdriver/md-check-links/commits/master) as an action version:
   ```yml
   - uses: yakdriver/md-check-links@44a942b2f7ed0dc101d556f281e906fb79f1f478
   ```
