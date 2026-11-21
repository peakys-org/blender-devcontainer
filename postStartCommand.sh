#!/usr/bin/env bash
python -m pip install --break-system-packages ruamel.yaml
python blender_services.py
cp blender_services.json .devcontainer/

cat gitignore_preset.txt > .gitignore
rm gitignore_preset.txt
