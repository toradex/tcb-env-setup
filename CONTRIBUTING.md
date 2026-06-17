# Contributing

Contributions should keep the setup script portable and shell-friendly, with attention to POSIX compatibility, backward compatibility, and automation use cases.

## General Expectations

- Keep the setup script compatible with pure POSIX shell environments where practical.
- Prefer changes that work well in interactive shells, CI jobs, and wrapper scripts.
- Keep the documentation aligned with the actual behavior of `tcb-env-setup.sh`.
- When changing behavior, update `README.md` examples and option descriptions accordingly.

## Design Guidelines

- The setup script must remain backward compatible when setting up older TorizonCore Builder versions.
- Auto-completion should be made available whenever possible, unless disabled by the user. Newer images of TorizonCore Builder contain the completion script inside them allowing the setup script to source it fom there.
- There must be no dependency from the auto-completion script back to the setup script. The setup script may only retrieve and source the latest completion script. An exception to this is the name of the `torizoncore-builder` command, which might be overriden when the completion script is sourced.

## Before Submitting Changes

- Verify that the updated behavior still works in the intended shell environments.
- Re-check any user-facing command examples after editing flags, defaults, or generated command names.
- Keep documentation changes concise and end-user focused in `README.md`; put contributor-oriented guidance here.

## Commit Messages

- Format the commit subject as `scope: Short description`.
  * `scope` is usually the main artifact being affected.
  * The first word in the short description should be capitalized.
  * See previous commits for examples.
- Limit commit subject length to 68 columns.
- Limit commit message body lines to 72 columns.
- Include a sign-off in every commit.
