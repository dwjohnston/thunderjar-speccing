# Terminology renaming

_Source: `docs/conversation_json.md` lines 1159–1407. See [README](README.md) for context._

**Covers:** Terminology session (a conversation fork): harness version pinning; naming the hashed things (experiment parameter definition); experiment definition vs execution; permutation; container run; measurement not pass/fail; measurer renamed to measuring instrument.

**User:** try again

**Agent:** Hey David — what would you like to pick up on? I can pull up context on Thunderjar or anything else if you point me at it.

**User:** I'm just creating a conversation fork from here.

**Agent:** Got it — go ahead whenever you're ready, I'm here.

**User:** So let's talk about this concept of — let's call them test case parameters. We're talking about things like the prompt set you're using, the task prompt, the model that you're using, etc. We had this concept of using a file hash to actually enforce uniqueness. And then possibly, maybe as a future thing, you could have the ability to compare runs of prompt sets with mismatching hashes. It'd sort of be

**User:** up to the user to make that determination.

**Agent:** Right, so basically flagging when someone's comparing runs where the under...

**User:** So the thing here is, I think what we want is a name, a first-class

**Agent:** Yeah, a first-class named concept for this whole bundle, so it's not just "prompt set" or "model" floating around separately but a proper entity you can reference.

Something like a "run configuration" or "test parameters" object that bundles prompt set, task, model, harness, all with their hashes, and identity is derived from the combination. What's the use case pushing you toward wanting it named though, is it for the comparison warning, or something else?

**User:** terminology name. Differences.

**Agent:** Ah, got it — so purely the naming question itself, not new mechanics. So we need one clean term for the bundle of things that define a test case: prompt set, model, harness, task, and so on.

What's your gut reaction to something like "run spec" or "run definition"? Or were you leaning toward "parameters" as the actual word?

**User:** Sorry, my microphone was playing up. No, what we're talking about is the prompt sets: you've got the snerk prompt set and the glurk prompt set, and that's a file, and then we have the hash of that. And now the harness — when you register a harness, that's going to be in a harnesses folder, and then you've got the... actually, sorry, let's pause here a bit. Because you can vary the model, you can vary the harness, you can vary the harness version, and that's an important thing we need to think about. Let's say we're talking about Claude Code. I'm saying, all right, I'm comparing prompt set A and prompt set B, here's the task, and we're using Claude Code and we're using Haiku, and we run this in a Docker container. But actually we need to (want to) be able to specify the exact version of Claude Code, because that is something we might want to change. Is the reason I've got some kind of regression because the version of Claude Code changed, not the version of the model? So the way I'm thinking about this is that you would have your harnesses folder, and inside each harness file — so you have Claude Code — you have various configuration things, including the exact version of Claude Code you're using. Now, if you wanted to compare two versions of Claude Code, then you could just have Claude Code v1.1 and Claude Code v1.2.

**Agent:** Right, so — two separate harness entries, each pinned to its own CLI version, sitting side by side in the harnesses folder. So comparing versions is just comparing two named harnesses, same mechanism as comparing two prompt sets, nothing new needed.

That actually already fits what's in the spec — harness identity is name plus folder hash plus CLI version string. So "harness" already captures version pinning; you'd just register `claude-code-1-1` and `claude-code-1-2` as two distinct harnesses if you wanted a side by side. Is the open question then just what to call the bundle of harness plus prompt set plus model plus task together, as one comparable unit?

**User:** No, no, no. The terminology question is what you call these concepts — these files that get hashed.

**Agent:** Ah, right — so purely the term for "a thing that gets hashed to derive identity." Prompt sets, harnesses, measurers... what do you call that category as a whole?

My instinct is "versioned asset" or "content-addressed unit" — but those feel a bit dry for a spec someone actually reads. What's your gut sense, are you after something punchy or just precise?

**User:** Yeah, okay, so I think this segues into another conversation we're having, which is around the terminology itself. In the original project I have the terminology.md, and that is something I absolutely stand by. It's well worth having in any of these vibe-coded projects. The idea is to generally enforce a common sense of terminology, but it's also very much for the human to follow. Something you see in real human life, in corporate environments, is that terminology often gets misused or mixed, and it just adds a lot of confusion about the project. So, TL;DR: a clear sense of terminology that you use consistently is very important. Now, that terminology.md I wrote a while back, and I myself have forgotten things, which suggests to me that it's not particularly well named. So that's an exercise we're going to go over — not right now, but just for your own context — to review the existing terminology and maybe come up with new names. Now, to answer your question: it needs to be something that is very clear about what it is. We don't want to do something too clever, where you're going to have to think, oh, what was that thing again? I was thinking, does the term artifact... versioned artifact — "versioned" doesn't really work, because that sounds more like git versioning.

**Agent:** Yeah, "versioned" definitely pulls toward git-style version numbers, which isn't the model here. "Artifact" alone I actually like though — it's a real word people already have an intuition for, and "content-addressed artifact" or just "artifact" for the category, with "artifact hash" for the identity, reads clearly without being clever.

So the pattern would be: prompt sets, harnesses, and measurers are all artifacts, each with an artifact hash. Does that sit right, or does "artifact" clash with anything else already in the doc?

**User:** Yeah, okay. So the way you are framing it — where you said, I can't remember, was it prompt sets, harnesses, tasks — are all artifacts. The way you're framing it, you're nailing it there. What I'm thinking is something like a run parameter. Now, that is maybe munging it a little bit, because we might need to drill into this: there could be some run parameters that are not these artifact-type things. For example, the code commit is not a run parameter — although technically it could be. You could move away from this idea of the code commit being the first-class run parameter, and actually you would have this — oh, no — the code state artifact. Its configuration is basically just a hash, but the code state could be determined a different way. Maybe it's some scripts that run.

**Agent:** Right, so pulling on that thread — if code state itself became an artifact, you'd get real uniformity: prompt set, harness, measurer, code state, all just named things with a hash, and a run is simply a specific combination of artifacts plus whatever true scalars are left, like the model name or an experiment's variables.

That's a nice unification, but it sounds like a bigger structural change, not just a naming one. Do you want to actually fold code commit into the artifact concept, or keep that as a separate future exercise and just settle "artifact" as the term for this session?

**User:** The thing that's tempting about doing it for the code commit is that then you have this very clear, consistent idea that a given run is a matrix of these different variables, right?

**Agent:** Yeah, exactly — every axis of variation becomes the same shape: named artifact, content hash, done. No special-casing "commit is a git thing, everything else is a hash of a folder" — it's all just artifacts under one mental model, which is exactly the kind of consistency your terminology-doc instinct is chasing.

Do you want to actually commit to that generalization now, or flag it as a strong candidate and keep working through today's session with "artifact" as the umbrella term first?

**User:** So, two things. Firstly, we need to examine whether this mental model actually works — whether all of the parameters can be expressed as a folder. I'll make clear: initially I had thought of it being a file, but I think a folder is better, because there's a potential that you would want other scripts or something living alongside the individual configuration object. So we still need to tease apart whether that's going to work, but that's not a task for right now. The other thing is that I'm not completely sold on the term artifact, although it does seem to be working for this conversation. Really, it's a run parameter or something like that. You got anything else? A run parameter artifact? I don't know.

**Agent:** Yeah, I get the hesitation — "artifact" describes what the thing *is* structurally, but "run parameter" describes the *role* it plays, and you might want a term that captures both. Two honest options as I see it: keep them separate, "artifact" for the folder-plus-hash structure and "run parameter" for the role it plays when it's an axis of a run, since not every artifact use necessarily has to be a run parameter. Or collapse them if you're confident every artifact only ever exists to be a run parameter.

My gut says keep them separate for now, since you're not even sure yet whether code commit fits the artifact mold. Does that split feel right, or too many moving pieces?

**User:** No, that doesn't work. No, no. Let's just continue on this idea of alternatives to artifact. So, run parameter — that's a candidate. Or "hashable parameter" — oh, that's not terrible. Anything else?

**Agent:** Let me think out loud with you here. There's a family around "config" — configuration unit, config module. There's a family around "component" — run component, test component. And there's one I like the sound of: "definition," as in prompt set definition, harness definition, so the umbrella term would just be "definition."

Out of run parameter, hashable parameter, config unit, component, or definition, which one's closest to clicking for you?

**User:** Hang on — yes, the concept of calling them definitions, I like that. Definition is good, but definition by itself is far too broad. There needs to be some kind of prefix. Even "parameter" is too broad — that concept can be applied generally across any sort of project. It starts getting a bit complicated if you're trying to do some Terraform stuff or something: are we talking about a Thunderjar parameter, or a Terraform parameter type thing?

**Agent:** Right, so you want something with a prefix that's clearly Thunderjar's own vocabulary, not a word that's already overloaded elsewhere. So building on "definition" — what about "run definition" for the umbrella term itself? Prompt sets, harnesses, measurers would each be a kind of run definition.

Or if you want it even more distinctly Thunderjar's own, something like "jar definition," playing off the project name. Does either of those land, or still hunting?

**User:** So in this concept, you're saying that a jar definition is the umbrella term for any of these things. Right.

**Agent:** Exactly, yeah. Jar definition would be the umbrella, and prompt sets, harnesses, measurers, and possibly code state down the line would each be a specific kind of jar definition, each with its own jar definition hash.

How does that sit? Distinct enough to be clearly Thunderjar's own term, without being so cute it's confusing.

**User:** Look, I think a run parameter definition — I think that's what we're landing on. So to be clear, a run parameter is an abstract term, a conceptual term, which is to say that — actually, let me just pause here and check that I'm using the term correctly. I know "run" is in the terminology MD. Now, is a run the full permutation of all of the parameters? So that's all of the

**Agent:** Let me check that against what's actually written down rather than going from memory.

That one's light on the exact terminology table — let me check the actual spec doc for the current definition of "run."

Yep, confirmed — in the doc, "run" is defined exactly as you said: one execution of a task under one permutation of variables, so it's the full combination, not a single piece of it.

So going back to your question, a "run parameter" would be one axis of that combination — the prompt set, harness, model, and so on — and "run" stays the umbrella result of setting all of them.

**User:** No, no, no. Okay, no, that is the opposite of what I was thinking. In that definition you just gave me, a run is one combination out of all of the possible permutations, right? And this comes back to the unclear terminology thing. As opposed to all of the combinations — what's that called in the terminology.md?

**Agent:** Right, so you want the word for the whole sweep — all combinations together — as opposed to one instance of it. Looking at the doc's own table, that's what "experiment" is defined as: a named comparison of one task plus variables, producing one run per permutation.

So the hierarchy as written is experiment contains many runs, each run contains many iterations. Is "experiment" the word you were reaching for, or were you after something else entirely for that top level?

**User:** Yeah, okay. We can stay on this. Possibly we want to rename run, but yep, sure. So we've got experiment: that is the collection of all the permutations. So in that case, the parameters would be experiment parameter definitions. That's working for me. Now, I think the question is whether experiment is the right term. Basically you need to have a distinction between an experiment as you've written it down in code, and the fact that you might run the experiment multiple times, right?

**Agent:** Ah, right — I see the gap. So "experiment" as currently defined is the static, written-down thing, the config file itself. But you also need a word for a specific execution of that config over time — because you might run the same experiment today and again next month after a model update, and those are two separate executions of the same definition.

Is that the distinction you're after — experiment-as-definition versus experiment-as-execution? Because right now "run" is sitting in the execution slot for a single permutation, but there's no word for "one full execution of the whole experiment, all permutations together, on a given day."

**User:** Yes, okay. Now let me just catch you on something you just said. You said that you might run the experiment again a month later because the model has changed. But remember, the whole concept here is that the idea is to fix the model. When you run the experiment, it's running against a fixed version of the model. So even if there was a model update, we shouldn't expect to see any differences. Now, the point of Thunderjar is to be testing for those kinds of things. So we're trying to hold everything steady, and we might see regressions regardless — and that might be because they're changing the model in the background, or they're changing their system prompts or something like that, which gives us different behavior regardless of our trying to keep this consistent.

**Agent:** Ah, good catch, that's fair — the model ID is pinned as part of the experiment's identity, so re-running shouldn't be "because the model changed," it's more that you're re-running the exact same pinned config later in time as a check, and any drift you see is either provider-side sneakiness or genuine non-determinism, not an intentional variable change on your end.

So the underlying point still stands though — you still need a word for "this experiment definition, executed as a batch, on this date," distinct from the definition itself. Does that framing hold, or does pinning change what you think that word should capture?

**User:** No, no. We're just ideating on terminology now. So I think "experiment definition" and "experiment execution". And then underneath, those parameters become "experiment parameter definitions". I'm liking that. Now, the individual run of a single permutation — I think "run" is not working here. What have you got for me there?

**Agent:** Right, so we've got experiment definition, experiment execution, experiment parameter definition... and now the single-permutation slot needs its own word since "run" is being freed up.

Couple of directions: you could go with "trial" — that's got a nice scientific-experiment ring to it, pairs naturally with "experiment." Or "permutation run" if you want to keep "run" but make it explicit. Or "variant" if you want to emphasize it's one combination of the variables. Which direction feels right, the scientific framing or the more literal one?

**User:** I mean, permutation, that might work. Now, when we say a permutation, a permutation is a single instance, right?

**Agent:** Yeah, exactly — a permutation is one specific combination of the variables. Harness A with model X and prompt set Y, say, as opposed to the full set of every possible combination.

So "permutation" itself could actually be the noun for the thing, and then its execution is what used to be called "run." Are you thinking permutation as the standalone term, or were you leaning toward pairing it with something like "permutation run"?

**User:** Yeah, okay.

**Agent:** So to recap where we've landed: experiment definition is the written-down config, experiment execution is running that whole thing on a given occasion, experiment parameter definition is what used to be just "parameter," and permutation is the single combination of variables within it.

That leaves one gap though — do you still want a distinct word for actually executing one permutation, or does "permutation" alone now cover both the concept and its execution?

**User:** Yeah, I mean, it could be "experiment permutation". Or "experiment permutation execution" — it's a bit of a mouthful.

**Agent:** Right, that is a mouthful. You could shorten it in practice though — permutation could stand alone as the concept, and then just say "permutation run" or "executing the permutation" when you specifically mean the act of running it, similar to how "experiment" and "experiment execution" split.

Does that parallel structure feel consistent enough, or do you want a tighter single word for the execution side, like "trial" just for that layer?

**User:** So I think the thing to be thinking about here is that there are different use cases where we are interested in these permutations. One would be: when I start an experiment execution, it's going to spin up eight different permutations and execute them simultaneously. And then there's going to be a Docker container for each permutation, and a result for each permutation. Do you get what I'm saying here? There's definitely this concept of a for-each-permutation in the experiment execution — I should be clear there. There is going to be a thing, or this thing is going to happen, right?

**Agent:** Yeah, I get it. So within one experiment execution, you're fanning out into eight permutations, and for each of those there's a concrete, physical thing happening: a Docker container sp...

**User:** But then you've got the actual run itself, which... I guess, I don't know... I guess that's a thing,

**Agent:** Right, so that container-spin-up-and-execute-one-permutation event, that's the actual candidate for keeping the word "run." So the structure would land as experiment execution fans out into permutation runs, each one a container instance producing a result, and iterations still sit underneath a permutation run as repeats for stats.

Does "permutation run" feel right as that concrete unit, or still too clunky said aloud repeatedly?

**User:** Okay, so "container run". A container run might be what we want, because that's actually quite clear: you're talking about a single container, and you're executing some stuff in it. That works quite well for me.

**Agent:** Yeah, container run is nice, it's concrete and it maps directly to the physical thing happening, one Docker container doing one job. So then the layers become experiment definition, experiment execution fanning out into container runs, and iterations as repeats underneath each container run.

Does that full stack feel settled now, or is there still a wrinkle somewhere in there for you?

**User:** Yeah, no, that works. I think we'll just flag this: one of the problems with the concept of "container run" is that in the future, it might be the case that you're not actually doing the AI evaluation inside Docker containers, and then it will be a bit clumsy. But I'm happy to move on.

**Agent:** Fair flag, that's a real risk if you ever move to a lighter-weight sandboxing model instead of full containers. Worth a quick note in the doc as a known naming debt, but sounds like you're happy to run with it for now.

So, want me to keep going through the rest of the terminology stack with this new structure, or pause here and let this settle for a bit?

**User:** No, all right, so let's move on to measurers and measurements. We might have already talked about it, or it might be in a different chat. That's quite clumsy; I think that's going to be really confusing. So, the concept here is that after a container run has finished, there is a certain set of measurements, tests, something. Now, one of the things I want to be really clear about here is that we're not doing tests in a pass-fail sense. I want you to really highlight that. The concept here is to just be measuring, without saying good or bad. Of course, as a user you absolutely could use that to say good or bad, but I very much don't want this to be a testing framework like something like Vitest would be. Although I probably am going to call it a testing framework — a prompt testing framework — but anyway. The point is you're going to do these measurements. It's not really about pass-fail. They could be: does the thing exist? It could be a yes/no, or a statistical number or whatever, but

**Agent:** Got it, so measurers and measurements deliberately steer away from pass-fail framing, they're just producing observations or data points after a container run finishes. And I recall from the terminology session that we'd landed on "measurer" as the thing that does the measuring and "measurement" as the output it produces, with things like exists-checks or statistical scores as examples, does that match what you'...

**User:** And so that's where the term measurement comes from. That makes it quite clear that we're just measuring things, we're not testing things.

**Agent:** Yeah, that tracks, "measurement" carries exactly the neutral, observational tone you want, no implicit verdict the way "test" or "assertion" would. It keeps the framing honest: you're capturing data, and whatever judgment gets applied to that data is on the user, not baked into the tool.

So, measurer produces a measurement, off the back of a container run. Is there a next layer you want to work through, like how measurements roll up across iterations or permutations into some kind of summary?

**User:** So I do quite like measurement. Maybe we want to rename measurer.

**Agent:** Sure, what's bugging you about "measurer"? Is it the word itself sounding clunky said aloud, or does it feel like it's not quite capturing what the thing does?

**User:** If we talk about it, it's a bit confusing what a measurer is versus a measurement. Those could probably get conflated.

**Agent:** Ah yeah, "measurer" and "measurement" are close enough that they could easily get mixed up mid-sentence, especially spoken aloud. What if the thing that does the measuring was called something like "gauge" or "probe" instead, keeping "measurement" as the output? Or were you thinking of a completely different pair of words entirely?

**User:** Yeah, actually, let's talk about probes, because I'm sure that's come up before. I think that feels like a fairly standard bit of terminology. So tell me about probes; it's not something I'm familiar with.

**Agent:** Let me have a quick look at where that term gets used elsewhere, so I'm not just guessing.

So "probe" does show up in the LLM eval space, but mostly as a loose verb, "probing for X behavior", not as an established noun for a discrete measurement component the way you'd want it here. It's not a standardized term with the precise meaning you're after, more just eval-speak for prodding a model to see what happens.

Given that, do you want to stick with the probe direction anyway since it's evocative, or go back to something like "gauge" which is unambiguous and doesn't carry that association?

**User:** So a measurer produces a measurement. That's the whole thing, right? Now, the measurers are — I want to say they're not that important. The idea with them is that they are helpful functions to get some information that you want. The user should always be able to just write whatever arbitrary script to produce measurements. They could just go, here's my script that does some git stuff, here's my script to do some grepping, etc. — and do anything they want. But of course, that's going to be a bit clunky when actually using this tool. So the idea with the measurers is to provide convenience in producing measurements. You could call it a "measurement provider". That's not crazy.

**Agent:** Right, so they're really just convenience wrappers, the user's always free to write raw scripts, but a measurer packages up a common pattern so you're not reinventing "check if a file exists" every time. "Measurement provider" does dodge the confusion with "measurement" nicely since the shared root actually helps rather than hurts there.

Would you want to shorten it in casual use though, like just calling them "providers" in conversation, or does the full "measurement provider" feel comfortable to say repeatedly?

**User:** Is "measurement provider"... even the term provider might be a bit ambiguous here. Because it doesn't... a

**User:** provider — when we think about it, does the concept of provider exist in Terraform? And it exists in things like telemetry, where it's a tracer provider, but you still pass the data into the tracer. So, keeping up this analogy: in the current architecture, you pass the data into the measurer. Are you following that analogy there?

**Agent:** Yeah, I'm following. So in something like OpenTelemetry, a "provider" is more of a factory or configuration object, it hands you back a tracer, and then you feed data into that tracer. Whereas here the measurer itself is the thing you hand the container run's output to, it's doing the work directly, not handing you back some other object to do the work.

So "provider" implies a layer of indirection that doesn't actually exist in your architecture, which could genuinely mislead someone coming from Terraform or OTel. Does that mean you'd rather drop "provider" and look for a word that says "this is the thing you directly hand data to and it does the measuring"?

**User:** Yes, okay, absolutely. You nailed that.

**Agent:** Glad that landed. So we're back to wanting a word for "the thing you hand container output to, which does the measuring", without colliding with "measurement" and without the provider indirection problem.

A few options: "evaluator" is common in this space but risks pulling back in the pass-fail connotation you're avoiding. "Analyzer" is neutral and describes exactly the action, taking data and processing it. Or "inspector", which has that same direct, hands-on feel without any judgment baked in. Do any of those feel right, or are they missing something?

**User:** Yeah, I mean, analyzer is fine. It's nice and neutral. It's not a term that gets used elsewhere or whatever, so that's fine. What about — what do you call a thermometer? A ruler? A set of scales? An instrument?

**Agent:** Ooh, "instrument" is nice, it's got that literal scientific-measurement flavor built right in, a thermometer or a sc...

**User:** What else is there?

**Agent:** Sticking with that physical-tool metaphor, you could also go with "gauge", or "meter" like a voltmeter, or "sensor" if you want to emphasize it's picking something up rather than computing it. Do any of those feel closer than "instrument", or is "instrument" still the frontrunner?

**User:** Yeah, I think gauge or meter are also sounding reasonable. My problem with both of those is that they give the connotation of monitoring a live metric, which isn't really what they do. With a gauge or a meter, I'm thinking of those dials going up and down, which is what you would get from metrics. Really what we're talking about here is something like a ruler, which is a one-time thing: you use it once, in a deliberate action. A ruler isn't really giving you information unless you're actively using it.

**Agent:** Ah, that's a sharp distinction, yeah, a gauge or meter implies continuous, passive monitoring, whereas what you want is a deliberate, discrete act of measurement, you pick up the ruler, you apply it once, you get a number, and it's inert otherwise. "Instrument" still holds up well under that lens actually, since a ruler, thermometer, and scale are all instruments used in that same deliberate one-shot way.

Are you drawn toward "instrument" as the actual term now, or still turning it over?

**User:** Okay, now I'm thinking about ruler. Is there anything else? Maybe we could use a metaphorical term. So something like ruler — although that could also sound like a king or something like that. Is there anything else? Tools like a ruler that we could use?

**Agent:** Fair, "ruler" does have that awkward monarch homophone problem said aloud. Other deliberate, one-shot measuring tools: "caliper", "scale" as in a weighing scale, "yardstick" though that's a bit folksy and US-flavored, or "tape measure". Do any of those dodge the ambiguity better?

**User:** Yeah, I don't hate yardstick. That has the advantage of saying, well, look, these aren't precise measurements, it's finger-in-the-air type stuff — which is kind of what I'm going for, at least for now. But it sounds a bit out of left field. I don't know. This is a good, productive conversation.

**Agent:** Ha, yeah, "yardstick" does carry that nice rough-and-ready honesty to it, "measuring up against something" rather than precision instrumentation, which actually fits your whole pass-fail-avoidance philosophy well. But you're right that it might feel a bit folksy dropped into a technical spec next to words like "permutation" and "container run."

Want to sit with "yardstick" for now and revisit if it feels off once it's in context, or keep turning over the tool-metaphor angle a bit more?

**User:** Okay, so what are our current front runners? I don't like instrument. Meter is still a candidate. And analyzer was another one. Was there anything else that was standing out?

**Agent:** So the frontrunners on the table are analyzer, which is clean and neutral but maybe a bit generic, meter, which has that measurement flavor but risks the live-dial connotation you flagged, and yardstick, which nails the deliberate one-shot rough-measurement feel but might read as a bit folksy. Caliper and tape measure got a mention too but didn't seem to catch.

Of those, which one are you leaning toward right now, or do you want me to throw a couple more at the wall?

**User:** Yeah, try a couple more.

**Agent:** A few more angles: "assessor" leans slightly evaluative but stays fairly neutral. "Checker" is plain and direct, though maybe too test-flavored for what you want to avoid. "Reader", like a gauge-reader, emphasizes just taking a reading off something. "Detector" if you want to emphasize spotting a specific thing. Or "surveyor", which has that deliberate, one-time, methodical measuring connotation like land surveying.

Do any of those spark something, or shall I try yet another angle?

**User:** Yeah, I like the thinking there, but the thing to consider is that, at least in the current conception, the thing we're currently calling a measurer provides a measurement of a specific type. The problem with surveyor is it sounds like it provides a bunch of different measurements. But really we're talking about how a ruler provides a specific measurement of length, and a thermometer provides a specific measurement of temperature,

**Agent:** Ah, right, that's the key constraint, it's a single-purpose tool for one specific kind of measurement, not a general-purpose survey. That actually pulls you back toward instrument-family words since each real-world instrument does exactly one job, a thermometer only does temperature, a scale only does weight.

Given that constraint, does "analyzer" still hold up for you, since a specific analyzer could imply a narrow single-purpose tool too, or does the ruler-thermometer physical metaphor feel more true to that single-purpose nature?

**User:** I mean, we could call it a measuring instrument. It's a bit of a mouthful, but it kind of works. I think let's go with measuring instrument.

**Agent:** Measuring instrument it is, that's clear, single-purpose, and dodges the live-monitoring connotation. Happy to shorten to "instrument" in casual conversation, or do you want the full "measuring instrument" used consistently even in shorthand?

**User:** I think for now we'll spec it as measuring instrument, and if we need to, we can update the documentation to mention what acceptable shorthands are.

**Agent:** Sounds good, measuring instrument it is, with a note in the docs for shorthand if you want one later. Want to keep going through the rest of the stack, or pause the terminology sweep here?
