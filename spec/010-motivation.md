
# Motivation

## Motivating scenarios

- **Slow drift.** My prompts seem to be working fine, but over several months performance quietly degrades and I don't notice until it's bad. Is it because my prompts (or CLAUDE.md/skills) have become bloated, because my codebase has grown in ways that make the same tasks harder, or because the underlying models have actually gotten worse? 
- **Model nerfing around launches.** There's a suspicion that providers quietly degrade a model's quality shortly before launching its successor (to make the new one look better by contrast). But how can we prove this? 
- **Switching harness or model with confidence.** Before migrating from one coding harness to another, or from one model to another, I want evidence that the new combination performs at least as well on _my actual tasks_ — not just on public benchmarks — before committing to the switch.


## Verification

- *Model nerfing around launches* is a suspicion, not a claim of fact. For context, Anthropic's [postmortem of three recent issues](https://www.anthropic.com/engineering/a-postmortem-of-three-recent-issues) states "We never reduce model quality due to demand, time of day, or server load", and attributes reported degradations to infrastructure bugs (request misrouting, output corruption, a compiler bug). Unintentional regressions of that kind are the sort of thing Thunderjar could detect. Nothing found there supports or refutes launch-time degradation specifically.
- The other scenarios are design motivations with no external-tool claims; no demo applies.
