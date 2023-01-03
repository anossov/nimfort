A basic deferred physically-based renderer in Nim.
Includes shadowmapping for all lights (with cube maps for point lights), SMAA, SSAO, tonemapping, bloom and a text renderer with variable-width fonts with kerning.


There is a rudimentary "game engine" around it with an ECS, scheduling, message passing system, input processing, camera, etc.

Depends on GLFW3.
