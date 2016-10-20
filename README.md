# NaivePhysics
#### Data generation for the Naive Physics project using Unreal Engine

Developed with
[Unreal Engine](https://www.unrealengine.com/what-is-unreal-engine-4)
4.8 and the [UETorch](https://github.com/marioyc/UETorch) plugin,
some additional functionalities (like functions for agents to handle
objects or calls Unreal's commandline commands) that are particular to
the project are available at
[this fork](https://github.com/marioyc/UETorch).

## Installation details

See the
[installation page](https://github.com/bootphon/NaivePhysics/blob/master/INSTALL.md).

## Main script

The **naive_physics.lua** file contains the parts that are common to
all different blocks, like setting the scenario and providing some
functions that will be called from Unreal's blueprints through
UETorch:

* **SetCurrentIteration**: gets the number of the iteration that will
  be simulated and imports the corresponding block, and also deals
  with some block-independent details like:
  * make globally available the RunBlock function of the correponding
    block so that it can be called from the blueprints.
  * adding the hooks that are going to save the actors' data, screen
    captures and final verification of the resulting scene.
* **SaveData**: is called at the end of each iteration and records the
  information accumulated during the simulation.
* **GetCurrentIteration**: taken from utils.lua
* **Tick**: replaces UETorch's Tick function, taken from utils.lua.

## Configuration script

The **config.lua** file gives an easy way to configure the following
properties of the simulations:

* Location where the data will be stored (**data_path**)
* A flag that can be enabled to generate an scene with previously
  saved parameters (**loadParams**), can be useful to regenerate the
  scene if something failed.
* A flag that enables stitching of all the resulting images
  (**stitch**)
* Number of ticks between each screen capture (**captureInterval**)
* Length of an scene in number of ticks (**sceneTicks**)
* Number of visibility check steps for each block
  (**visibilityCheckSize**)
* Number of elements in the tuple for each block (**tupleSize**),
  which can be useful when you want to generate multiple scenarios
  with the same parameters.
* Amount of iterations that will be generated for each block
  (**blocks**), all the necessary folders will need to be created
  previously.

Also provides some functions that allow access to these properties.

## Blocks' scripts

Each block script independently sets the scenario for the simulation and should provide:

* A **SetBlock()** function which will be called from the main script
  and precalculate some parameters or load them if they have been
  precalculated already.
* A **RunBlock()** function which will be called from the Lua
  blueprint in order to start running the scenario.
* An **actors** table which contains the actors for which data will be
  stored.
* A **MainActor()** function which returns the main actor which should
  be kept during the visibility check steps.
* The functions **SaveCheckInfo()** and **Check()** which check the
  integrity of scene after it has been generated.
  * If the check function finds an error a new scene will be generated.
  * The check function can fail and restart during any of the
    different parts of the block, as done for example in
    blockC1_dynamic_2
  * **Warning**: this could cause an infinite loop if the loadParams
    flag is true, but the scene generated with these parameters isn't
    valid.
* A **IsPossible()** function which says whether the sequence is
  possible.

## Utils' script (**utils.lua**)

* **SetActorMaterial** sets the material of a given actor from a fixed
  list of available materials.
* **GetCurrentIteration** reads the iteration counter from a file.
* **UpdateIterationsCounter** updates the iteration counter after the
  **Check** function concluded and depending on the result decides
  whether to go on or restart.
* **Tick** replaces UETorch's Tick function, allowing to set the
  maximum number of ticks in the scene and run some hooks at the end
  of it.

## Additional utils

* **imageseq_to_video.py** : takes the obtained screen captures and
  ouputs videos.
* **clean.sh** : deletes directories which aren't necessary to rebuild
  the game.
* **copy_training.sh** : goes through some of the generated scenarios
  and copy the possible cases.
* **copy_testing.sh** : goes throught some of the generated scenarios
  and copy the possible and impossible cases.
