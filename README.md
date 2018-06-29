# SIMP builder GitLab CI pipeline


<!-- vim-markdown-toc GFM -->

* [Description](#description)
  * [What this branch does](#what-this-branch-does)
* [Setup](#setup)
  * [GitLab Project](#gitlab-project)
  * [GitLab Runners](#gitlab-runners)
  * [Project variables](#project-variables)
* [Reference](#reference)
  * [Local setup script](#local-setup-script)
  * [Local finish script](#local-finish-script)

<!-- vim-markdown-toc -->


## Description

This repository contains [Gitlab CI][gitlab_ci] pipelines to build assets to support
automated SIMP integration testing.

* Each branch contains its own pipeline.
* The pipelines are meant to simplify automated tasks, like nightly builds.

### What this branch does

The pipeline in this branch builds a fresh **simp-builder VM**, which builds
a **SIMP ISO.**  It will:

1. Clone an [insta-simpdev][insta_simpdev] repo into `simp-builder/`
2. _(optional)_ source a [local setup script](#local-setup-script)
3. Provision (`vagrant up`) a fresh VirtualBox VM and use it to build a SIMP ISO
4. Copy build artifacts (`.iso`, `.json`, logs, `Puppetfile.*`) back from the VM into `simp-builder/`
5. _(optional)_ source a [local finish script](#local-finish-script)
6. Destroy the VM



## Setup

### GitLab Project

1. Fork this repo into your own GitLab project.
2. Ensure your GitLab project has the following:
   * The pipeline must be configured to use a GitLab Runner that has
   * Set any [project variables](#project-variables) needed in **Settings > CI/CD > Variables** (or during a trigger)

### GitLab Runners

1. Ensure this pipeline has access to GitLab Runners that are [**"shell"**
   executors][shell_exec] and use the tags `vagrant` and `virtualbox`.
2. (optional) Ensure that the relevant Gitlab Runners have local
   [setup](#local-setup-script) and [finish](#local-finish-script) scripts on
   the local filesystem:

### Project variables

|  Name | Example | Purpose |
| ----- | ------- | --- |
| **LOCAL_SETUP_SCRIPT**  | `/path/to/setup_script` | The path to a [local setup script](#local-setup-script) on the GitLab Runner |
| **LOCAL_FINISH_SCRIPT** | `/path/to/finish_script` | The path to a [local finish script](#local-finish-script) on the GitLab Runner |
| VAGRANT_BUILDER_REPO | `https://github.com/op-ct/insta-simpdev.git` | git URL to [insta-simpdev][insta_simpdev] repo |
| VAGRANT_BUILDER_REF  | `werk` | ref/branch to check out from [insta-simpdev][insta_simpdev] repo |

In addition to the pipeline-specific variables, you can set;

* Any build-relevant variables (e.g., `SIMP_*`, `NO_SELINUX_DEPS`,`BEAKER_*`,`PUPPET_*`,`FACTER_*`)
* Any `SIMP_BUILDER_*` variables from [insta-simpdev][insta_simpdev].  Of particular interest:

  |  Name | Example | Purpose |
  | ----- | ------- | --- |
  | **SIMP_BUILDER_download_iso** | `no` | Prevent the `simp-builder` VM from trying to download its own ISOs (recommended) |
  | **SIMP_BUILDER_debug**   | `1`    | Turn on extra information during the `simp-builder` ISO build |


## Reference

### Local setup script

* If `$LOCAL_SETUP_SCRIPT` is the path of a local
shell script, the pipeline will `source` it before running `vagrant up`.

* **IMPORTANT:** The script **should** ensure that any OS ISOs required for the
  build are present under `${CI_PROJECT_DIR}/simp-builder/downloads/isos/`

### Local finish script

If `$LOCAL_FINISH_SCRIPT` is the path of
a local shell script, the pipeline will `source` it before running `vagrant
up`.

This script is optional, but is provided as a hook to archive/publish any
artifacts the pipeline has built.  This is particularly useful if your GitLab
CI doesn't use [job artifacts][job_artifacts].

[shell_exec]: https://docs.gitlab.com/runner/executors/#shell-executor
[job_artifacts]: https://docs.gitlab.com/ce/user/project/pipelines/job_artifacts.html
[gitlab_ci]: https://about.gitlab.com/features/gitlab-ci-cd/
[insta_simpdev]: https://github.com/op-ct/insta-simpdev.git
