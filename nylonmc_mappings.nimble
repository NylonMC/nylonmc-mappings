# Package

version     = "0.0.1"
author      = "NylonMC Mappings"
description = "Mappings based on FabricMC's Yarn for use in NylonMC"
license     = "CC0-1.0"

# Deps

requires "nim >= 1.2.2"
requires "zip >= 0.3.1"
requires "msgpack >= 0.1.0"

import os
task genMappings, "Creates a .nylonnano based on the latest yarn":
    mkdir "build"
    exec "nim c -d:ssl -r src/nylonmc_mappings.nim"