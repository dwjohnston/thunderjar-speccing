# AGENTS.md

## General Agent instructions

### AI Generated Content Headers

#### Commit messages

Add the following message the bottom of commit messages: 

```
🤖 Commit message created by AI. <harness>/<model>
```

Populate the `<harness>/<model` part with appropriate values. 

## What this repo is

We are speccing out the Thunderjar application, as described in
[docs/conversation_json.md](docs/conversation_json.md) (the source design conversation).
This repo does not contain Thunderjar's implementation — just the spec.

## Folder structure

- `docs/` — source material: the raw and extracted design conversation(s) this spec is derived from.
- `spec/` — the spec itself, one file per concern. See `spec/README.md` for the index and reading order.

## Working style

- Err on the side of brevity in spec pages. If more detail is needed, the user will ask for it.
- Update this file as we go. If the user gives a nudge or piece of guidance that reflects a
  general principle (not a one-off), suggest the AGENTS.md update and ask before adding it.
  Never update this file automatically/silently.
