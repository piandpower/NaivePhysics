# NaivePhysics
#### Data generation for the Naive Physics project using Unreal Engine

Developed with [Unreal Engine](https://www.unrealengine.com/what-is-unreal-engine-4) 4.8 and the [UETorch](https://github.com/facebook/UETorch) plugin.

## Installation details

The **Scripts** folder must be added to the Lua path.

## Main script

The **naive_physics.lua** file contains two main functions which are called from Unreal's blueprints:

* **SetCurrentIteration**: gets the number of the iteration that will be simulated and imports the corresponding block, and also deals with some block-independent details like setting the ground material and adding the hooks that are going to save the actors' data and screen captures.
* **SaveData**: is called at the end of each iteration and records the information accumulated during the simulation.

## Configuration script

The **config.lua** file gives an easy way to configure the following aspects of the simulations:

* Location where the data will be stored (**data_path**)
* Interval of time between each screen capture (**screenCaptureInterval**)
* Length of an scene for each different block (**sceneTime**)
* Number of elements in the tuple for each block (**tupleSize**), which can be useful when you want to generate multiple scenarios with the same parameters.
* Enable/disable recording of data (**save**)
* Amount of iterations for each block (**blocks**)

## Blocks' scripts

Each block script independently sets the scenario for the simulation and should provide:

* A **SetBlock()** function which will be called from the main script and precalculate some parameters or load them if they have been precalculated already.
* A **RunBlock()** function which will be called from the Lua blueprint in order to start running the scenario.
* An **actors** table which contains the actors for which data will be stored.
* A **IsPossible()** function which says whether the sequence is possible.

## Additional utils

* **imageseq_to_video.py** : takes the obtained screen captures and ouputs videos.
* **clean.sh** : deletes directories which aren't necessary to rebuild the game.
