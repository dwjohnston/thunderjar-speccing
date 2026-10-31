# 1150: Hello world

`npx thunderjar` prints "hello world!", and the package, documentation page and release pipeline exist.

Areas: F

## Artifacts

- `thunderjar` package published to npm
- Documentation page, live at a public URL
- Release pipeline that publishes on merge (tests run in the CI pipeline from [1100](1100_base-tooling.md))

## How to test

Verified by a human.

1. 👷‍♂️ Run `npx thunderjar`.
2. Expect the output `hello world!`.
3. 👷‍♂️ Open the documentation page and expect it to load.
4. 👷‍♂️ Merge a trivial change and expect CI to pass and the release pipeline to run.

## Human interventions

- 👷‍♂️ Create the npm account (or org) and publish token, and add the token as a CI secret.
- 👷‍♂️ Choose a docs host, and configure it in its web console (site, domain, deploy
  from the repo).
- 👷‍♂️ Verify the docs page by eye.
