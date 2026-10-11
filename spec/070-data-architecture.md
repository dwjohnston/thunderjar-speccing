# Data Architecture

Where Thunderjar keeps what a container run produces: two stores, one small and
queryable, one large.

## The two stores

1. **Run data store** — small, queryable metadata: date, test case parameters and
   permutation hash, measurements, cost, tokens, duration. See
   [030-terminology.md](030-terminology.md#storage) and
   [085-test-case-results.md](085-test-case-results.md).
2. **Image store** — a single Docker registry repository holding both prerun and postrun
   images together, discriminated by tag prefix (`prerun-` / `postrun-`) rather than by
   separate repositories. See [081-docker-tagging.md](081-docker-tagging.md) for the tag
   scheme.

**Future:** OTel traces and session transcripts, and a trace store to hold them. See
[020-goals-non-goals.md](020-goals-non-goals.md#soon-to-follow).

## Open questions

_TBD_
