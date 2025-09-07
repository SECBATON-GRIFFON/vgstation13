#!/usr/bin/env python3
import os
import distutils.spawn
import asyncio

import travis_utils

def main():
    dmb = "vgstation13.dmb"

    executable = "DreamDaemon"
    dreamdaemon = distutils.spawn.find_executable(executable)
    if not dreamdaemon:
        print("Unable to find {}.".format(executable))
        exit(1)

    loop = travis_utils.get_platform_event_loop()
    code = loop.run_until_complete(travis_utils.run_with_timeout_guards([dreamdaemon, dmb, "-close", "-trusted"]))
    exit(code)

if __name__ == "__main__":
    main()
