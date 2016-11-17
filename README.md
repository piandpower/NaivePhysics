# NaivePhysics
#### Data generation for the Naive Physics project using Unreal Engine

Developed
with
[Unreal Engine](https://www.unrealengine.com/what-is-unreal-engine-4)
4.8 and our [UETorch](https://github.com/marioyc/UETorch) fork.

## Installation details

This installation process succeeded on Debian stable (Jessie) and
Ubuntu 14.04. It may be fine for other Unices as well, but this have
not been tested.

* First of all setup an Epic Games account at
  https://github.com/EpicGames/Signup/, needed to clone the Unreal
  Engine repository from github. UETorch currently only works with the
  source distribution of UE4 in the version 4.8, not the binary
  download.

* The clone the NaivePhysics repository from github, go in its root
  directory and run the `Setup.sh` script:

        git clone git@github.com:bootphon/NaivePhysics.git
        cd NaivePhysics
        ./Setup.sh

  This takes a while: it downloads and installs Lua, Torch, Unreal
  Engine and UETorch in the `NaivePhysics`. It finally activates the
  project environment in your `~/.bashrc`.

* The final step is to package the `NaivePhysics` project into a
  standalone binary. We provide the `build_package.sh` for doing that,
  but the first time (i.e. right after a compilation from scratch) it
  seems not to work.

  So you need a manual intervention in the editor. Open it with:

        ./naivedata.py exemple.json ./data --editor

  In the *File/Package Project* menu, select the *Linux* target and
  `./NaivePhysics/Package` as the package directory. This operation
  takes a while.

  ![Packaging menu](https://docs.unrealengine.com/latest/images/Engine/Basics/Projects/Packaging/packaging_menu.jpg)


## Usage

Once installed and packaged, use the `naivedata.py` program to
generate data. To discover it, have a:

    naivedata.py --help

## Potential issue

If the 3D scene generated seems to be frozen (the spheres are moving
but the wall remains in the 'down' position for a while), there is a
problem with the packaged `NaivePhysics` binary.

Try to repackage it with the `build_package.sh` script or within the
UnrealEngine editor.

If the problem persists, launch the editor (with the *--editor* option
of `naivedata.py`), click on the *Play* button (in the top panel) and
repackage the game from the *File/Package Project* menu.


## Lua scripts in UnrealProject/Scripts

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


## License

**Copyright 2016 Mario Ynocente Castro, Mathieu Bernard**


This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
