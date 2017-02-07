## MoveIt! ABI/API Stability Test

This repository aims to simplify testing the main MoveIt projects for ABI/API stability.

To get started you need

- abi-dumper
- abi-compliance-checker

as well as a bit of time.

To get started make sure the checkout of this package becomes a catkin workspace.
E.g.:

    . /opt/ros/indigo/setup.bash
    catkin_init_workspace src

Next, pull the listed repositories into the workspace and checkout your preferred branches. E.g.

    cd src
    wstool update
    <switch branches of all repositories to "indigo-devel">

Now you should be able to run the main script:

    cd ..
    ./abi-check.sh

This will build the current workspace in Debug mode with the additional compile flag `-Og`.
This is required by the abi-dumper.
After building finished, it will generate ABI-dumps of all installed libraries and put them into a subfolder `new.dumps`.

Then, it will checkout the first tag reachable from the current checkouts (this should be the latest release)
and reruns the above step. The new (or as a matter of fact older) ABI-dumps are stored in `old.dumps`.

As a final step, the script runs the abi-compliance-checker on all libraries and reports detected incompatibilities.
The full reports for all comparisons are stored in `compat_report` and can be reviewed via your favorite web browser.
