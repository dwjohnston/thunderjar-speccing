# Storing and inspecting results

_Source: `docs/conversation_json.md` lines 409–486. See [README](README.md) for context._

**Covers:** Where summaries and preserved containers go after a run; metadata store + container registry + a middle tier for traces/transcripts; telemetry view vs full restore (VS Code Dev Containers).

**User:** So now let's talk about what happens after the test runs. Okay, so I'm in my project, and let's say it's a single test scenario where we're saying: this code commit, this prompt commit, and let's say we're comparing these two models, and it's a hundred iterations. It goes and spawns all of these Docker containers and runs them all. So now, on my local computer, I have 200 Docker containers that are all closed, and I have my JSON report about what percentage passed, etc. Now what do we do? What I'm thinking is that you want to be recording... Okay, in that scenario, this is me testing something locally, which is perfectly valid. The other thing is maybe this is running in a pipeline, right?

**User:** So that summary output probably just wants to be saved somewhere — where do you save it? And then importantly, those Docker containers need to be preserved somewhere.

**User:** Why do we have two minutes left?

**Agent:** We're doing fine time-wise, don't worry, keep going.

For the summary output, the natural home is wherever your other Thunderjar run metadata already lives, a database if you're building toward historical trend tracking, that "did this get worse since last week" comparison you described earlier, or even just a committed JSON file in the repo itself if you want dead-simple versioning tied to code changes. Given you explicitly want month-over-month regression detection, a proper database, even something lightweight like SQLite for local runs, probably pays off quickly, since querying "show me cost trend for this test case over time" against a folder of JSON files gets painful fast.

For the two hundred containers, push them to a registry, tagged with the run ID scheme we discussed, and treat that as your durable artifact store, then locally you'd just prune them immediately after push, since there's no reason to keep bulky container filesystems sitting on your laptop once they're safely uploaded and the summary numbers are extracted.

**User:** Yes, so basically what we want is for the Thunderjar configuration to have a mechanism for saying, hey, here's where to save the summary JSON, and here's where to save the preserved containers. That's one part of it. And then later on — probably from your developer machine makes sense, I don't think it really makes sense doing this in CI — you want to be able to say, hey, get me this specific run and this iteration of the run and pull that up for me, please. And when we say pull that up for me, there are two things. One is, hey, let's see the telemetry — so you could be running Grafana locally. The other thing is you go, all right, let's run that Docker container, let me have a look at the file system, please. Although I don't actually care about the Docker... I mean, it depends what it is, right?

_[Editor: omitted an interruption — a question about a system reminder, and an unrelated exchange with a child about durian. The user then re-typed the question below.]_

**User:** Now let's say that I'm running a test locally for code commit X, prompt commit Y, and I'm comparing 2 models, 100 iterations. So that goes off, creates the 200 Docker containers, and that completes.

Now it creates the JSON summary of the two things compared, and we also have these 200 closed containers.

Now, we need to preserve the JSON summary somewhere, and also those 200 containers.

The Thunderjar config needs to be configured to save this.

Later, on my development machine, I also want to be able to inspect a given run: be able to see high-level statistics generally, or be able to dive into a specific iteration.

I either want to be able to visualise just the telemetry type stuff, or I want to do a kind of 'full restore' where I get the full file system and then I can use my VSCode to poke around, looking at the commits etc.

**Agent:** Good, this is the piece that ties everything together. I'd split it into two separate concerns that happen to share an ID scheme: a **metadata/summary store** (small, queryable, cheap) and a **container artifact store** (large, blob-like, expensive). Your config needs a backend for each, and they can be the same provider or different ones.

**The metadata layer**

Every run gets a run ID, every iteration within it gets an iteration ID (run ID + index, or run ID + model + index in your two-model case). The JSON summary — pass/fail, cost, tokens, duration, per-model breakdown — gets written keyed by that run ID into whatever store you configure: locally that could just be SQLite, in CI it's probably Postgres or even just S3 with a manifest file. This is the thing your "high-level statistics" view queries — it should never require touching a container to answer "which iterations failed" or "what was the cost trend."

**The container layer**

Push all 200 committed images to a registry, tagged by iteration ID. Locally that could be a local registry container (`registry:2`) so you're not paying cloud costs for dev-time experimentation; in CI it's ECR/GHCR/whatever you already use. Prune the local Docker daemon's copies immediately after push — the registry is now the source of truth.

**The bit worth adding: a middle tier**

Don't make "visualize the telemetry" require a full container pull. At commit-time, before you push the image, extract the lightweight stuff — the OTel trace export and the session JSONL transcript — and stash those as their own artifact next to the JSON summary in the metadata store, keyed by iteration ID. They're small, text-based, and that's genuinely everything your "just show me the trace/reasoning for this iteration" view needs. Save yourself a multi-hundred-MB pull for the common case.

**Then your two inspection modes become:**

- *Telemetry view*: query metadata store by run ID → render stats table → click an iteration → fetch its trace + transcript blob → render in whatever dashboard you build (this is a good fit for a local web UI or even just a TUI).
- *Full restore*: `docker pull` that iteration's tagged image → `docker run` it → and this is where VSCode's Dev Containers / Remote-Containers extension is genuinely built for exactly this, attach to the running container and you're browsing the real filesystem, git log, node_modules, everything, in your normal editor.

The config for Thunderjar would then just need: a metadata backend connection string, a registry endpoint, and a retention policy (how long to keep container images vs. how long to keep the cheap metadata/trace blobs — probably very different TTLs, since the trace data is worth keeping forever and the containers aren't).
