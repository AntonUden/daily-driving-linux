# Some notes on running VSeeFace on linux

Running the tracker: `python facetracker.py -c 0 -W 1280 -H 720 --discard-after 0 --scan-every 0 --no-3d-adapt 1 --max-feature-updates 900`

Running the application: `wine VSeeFace.exe --background-color '#00FF00'`

To get transparency in obs add chroma key effect to window capture
