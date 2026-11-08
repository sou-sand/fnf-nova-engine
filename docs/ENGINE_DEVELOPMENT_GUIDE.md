# Nova Engine Development Guide

This guide is for changing the engine itself: adding or changing behavior written in Haxe. That is different from making a mod, which usually adds or overrides content without editing the engine source.

A useful first distinction is:

- **Haxe source** defines what the game does.
- **Assets and data** define what the game displays or loads.
- **`Project.xml`** controls how the game is configured and built.

## How The Game Starts

The usual startup path is:

1. [`source/Main.hx`](../source/Main.hx) creates the game and chooses its initial state, `TitleState`.
2. [`source/states/TitleState.hx`](../source/states/TitleState.hx) runs the title screen and transitions into the menus.
3. Menu states such as [`MainMenuState.hx`](../source/states/MainMenuState.hx), [`StoryMenuState.hx`](../source/states/StoryMenuState.hx), and [`FreeplayState.hx`](../source/states/FreeplayState.hx) handle navigation and song selection.
4. [`source/states/PlayState.hx`](../source/states/PlayState.hx) creates and runs a song: stage, characters, notes, input, scoring, HUD, events, and the end-of-song flow.

Many screens inherit from [`source/backend/MusicBeatState.hx`](../source/backend/MusicBeatState.hx). It provides beat- and step-based timing callbacks, which are useful for rhythm-game behavior.

## Project Map

| Location | What it is for | Start here when... |
| --- | --- | --- |
| [`Project.xml`](../Project.xml) | Application metadata, libraries, asset inclusion, platform settings, and compile-time feature flags | A library or platform feature must be enabled, or build/app settings need changing |
| [`source/Main.hx`](../source/Main.hx) | Game startup and initial state | You are investigating initialization or startup order |
| [`source/states/`](../source/states/) | Full screens, including title, menus, and gameplay | You are adding or changing a screen or game flow |
| [`source/states/PlayState.hx`](../source/states/PlayState.hx) | Song gameplay and coordination of gameplay systems | A feature affects song flow or connects multiple gameplay systems |
| [`source/objects/`](../source/objects/) | Reusable objects such as characters, notes, icons, and menu items | A change belongs to one reusable game object |
| [`source/backend/`](../source/backend/) | Shared systems and data services | You are changing timing, asset lookup, controls, preferences, mod loading, or song/week data |
| [`source/states/stages/`](../source/states/stages/) | Haxe code for individual stages | A stage needs custom behavior or scenery logic |
| [`source/states/editors/`](../source/states/editors/) | In-game chart, character, stage, dialogue, and other editors | A feature belongs to an editor workflow |
| [`source/substates/`](../source/substates/) | Overlays that run over another screen, such as pause and game over | You are changing a pause, confirmation, or game-over overlay |
| [`source/options/`](../source/options/) | Options screens and settings controls | You are adding a player-facing setting |
| [`source/psychlua/`](../source/psychlua/) | Lua/HScript runtimes and the functions they expose to scripts | You are exposing an engine feature to Lua or HScript |
| [`source/cutscenes/`](../source/cutscenes/) | Dialogue and cutscene logic | You are changing shared cutscene behavior |
| [`source/shaders/`](../source/shaders/) | Engine shader implementations | You are changing a built-in rendering effect |
| [`assets/`](../assets/) | Images, sounds, music, charts, character/stage/week data, and translations | You are adding or replacing game content |
| [`docs/scripts/`](../docs/scripts/) | Lua and HScript callback templates | You need to see the available script callbacks |
| [`setup/`](../setup/) and [`docs/BUILDING.md`](BUILDING.md) | Dependency setup and build instructions | You need to compile or fix a build environment |

`PlayState` is the coordinator for many gameplay systems, but it is a large file. Prefer putting a behavior in the class that owns it when that keeps the change local. For example, character animation behavior usually belongs in `objects/Character.hx`, while timing calculations belong in `backend/Conductor.hx`.

## Choosing The Right Place

### Gameplay rules

Start in `PlayState.hx` to find where the gameplay flow calls the relevant behavior. Then move the implementation to a smaller owning class if the behavior is reusable or belongs to one object.

For example, note creation and hitting involve both `PlayState` and `objects/Note.hx`. `PlayState` decides when notes spawn and applies gameplay results; `Note` stores and updates the properties of an individual note. Avoid changing hit timing in multiple places until you have traced how the current timing value is calculated and consumed.

### Stages

For a new stage with Haxe behavior, copy [`source/states/stages/Template.hx`](../source/states/stages/Template.hx), give the class a distinct name, and register it in the `switch (curStage)` section in `PlayState.hx`. `PlayState` has a short note near its class declaration describing this route. Put stage-specific behavior in the stage class instead of making general gameplay code depend on that stage.

Some stage setup is data-driven. Check the existing stage data and `backend/StageData.hx` before writing code; positions and other configuration may not need a new Haxe implementation.

### Events and note types

`PlayState.hx` contains the event flow. Search for `eventPushed`, `eventPushedUnique`, `eventEarlyTrigger`, and `triggerEvent` to see the different stages of event handling. Stage-specific event behavior can often live in the stage class; behavior that applies generally belongs in `PlayState` or a smaller shared system.

Note types also cross several boundaries: note data/configuration, `objects/Note.hx`, and the hit/miss handling in `PlayState.hx`. If the feature should be available to charts or scripts, check the chart editor and Lua/HScript APIs too.

### Settings and controls

A persistent player preference typically needs three pieces:

1. A stored field and save/load handling in [`source/backend/ClientPrefs.hx`](../source/backend/ClientPrefs.hx).
2. A control in the appropriate screen under `source/options/`.
3. Code that reads the preference where it changes behavior, often in `PlayState` or the object it affects.

Input bindings and key handling are shared systems. Look at [`source/backend/Controls.hx`](../source/backend/Controls.hx) and [`source/options/ControlsSubState.hx`](../source/options/ControlsSubState.hx) before adding a new configurable binding.

### Screens and overlays

A new full screen usually belongs under `source/states/`; a temporary overlay usually belongs under `source/substates/`. Follow a nearby state for its `create`, `update`, transitions, and cleanup. Use `MusicBeatState` if the screen needs beat/step callbacks.

### Lua and HScript support

Gameplay calls script callbacks from `PlayState`, and [`source/psychlua/`](../source/psychlua/) implements the script runtime and helper functions. To add a script-accessible feature, identify both sides: where the engine performs the feature, and where the scripting layer registers or forwards the new function. Check [`docs/scripts/TemplateScript.lua`](scripts/TemplateScript.lua) for callback names and shapes.

If a feature is only for engine code, it does not automatically need a Lua API. Add script access when modders should be able to call or respond to it.

## Assets, Data, And Mods

The `assets` tree contains runtime content. Common content is under `assets/shared/`; base-game content is under `assets/base_game/`. Inside those are familiar categories such as `images`, `sounds`, `music`, `data`, `characters`, `stages`, and `weeks`.

[`source/backend/Paths.hx`](../source/backend/Paths.hx) is the central asset lookup helper. Use it rather than hard-coding asset paths where the existing code does so; it accounts for shared content and mod overrides.

A mod is a good way to test an asset or script idea before making it an engine feature. The starter archive is [`example_mods/modTemplate.zip`](../example_mods/modTemplate.zip). A song-specific Lua script is normally placed at `mods/<mod-name>/data/<song-folder>/<script-name>.lua`; `PlayState` loads Lua/HScript files from the song's data folder. The `mods` folder can also provide replacement assets at matching paths. See [`example_mods/readme.txt`](../example_mods/readme.txt) for the repository's starter guidance.

Use a mod when the change is content for a particular song, character, or stage. Change Haxe source when you are adding a capability or rule that should be part of Nova Engine itself.

## A Safe Development Loop

1. **Describe the behavior.** Write down what the player should see or be able to do, and when it should happen.
2. **Find the owner.** Search for the existing behavior or callback, then read the nearby code and its callers. Search terms such as `goodNoteHit`, `triggerEvent`, `onBeatHit`, or `ClientPrefs.data` can lead to the relevant gameplay path.
3. **Make one focused change.** Keep state-specific code in the state, reusable behavior in its object/system, and content in assets/data.
4. **Build.** Follow [`docs/BUILDING.md`](BUILDING.md). Once dependencies are installed, the documented desktop build command is `lime test cpp` from the repository root.
5. **Try the behavior in-game.** A successful compile does not prove that the timing, input, or state transition works as intended.
6. **Review the change.** Check the diff and test the case you changed, plus one nearby case that could be affected.

When a build fails, fix the first relevant compiler error and rebuild before making more changes. If a change touches note timing, scoring, input, or save data, test those paths deliberately because they affect more than what is drawn on screen.

## Example: Add A Player Setting

Suppose you want an option that hides a new gameplay indicator. A likely route is:

1. Add a default value and persistence in `backend/ClientPrefs.hx`.
2. Add a toggle in the appropriate options menu under `source/options/`.
3. Create and add the indicator in the gameplay code, then read the preference to control its visibility.
4. Build and check both settings states: enabled and disabled. Also check that changing screens or restarting does not leave a stale indicator behind.

The exact files depend on the feature, but this illustrates the usual path from a player-facing setting to saved state to gameplay behavior.

## Example: Rename Or Rebrand The Engine

Application identity is configured in `Project.xml`: its app title, output filename, package ID, version, and company. Screen labels are in their owning state files; for example, the main menu's engine version label is in `source/states/MainMenuState.hx`, and title-screen attribution is in `source/states/TitleState.hx`.

Do not replace every occurrence of the old engine name blindly. Some strings identify chart formats, script APIs, historical credits, or upstream links. Those may be compatibility-sensitive or should remain as attribution. Platform launcher metadata and logo images are separate assets and need their own updates.
