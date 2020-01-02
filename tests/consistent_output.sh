#!/bin/bash

make png/ug-map-adriatic_sea.png
make png/ug-map-aral_sea.png
make png/150/ug-map-coral_sea.png

diff png/ug-map-adriatic_sea.png tests/samples/
diff png/ug-map-aral_sea.png tests/samples/
diff png/150/ug-map-coral_sea.png tests/samples/
