# Merry Scary Christmas

Cooperative Christmas escape room for the Introduction to Programming group project.

## Run locally

1. Install Python 3.11 or newer.
2. Open a terminal in this repository.
3. Install the app dependency and start Streamlit:

   ```powershell
   py -m pip install -r requirements.txt
   py -m streamlit run streamlit_app.py
   ```

The app opens at `http://localhost:8501`. Stop it with `Ctrl+C` in the terminal.

## Deploy on Streamlit Community Cloud

The repository is prepared for Streamlit Community Cloud. Sign in at [share.streamlit.io](https://share.streamlit.io/) with the GitHub account that has admin access to this repository, choose **Create app**, and select:

- Repository: `laraglueck/Merry-Scary-Christmas`
- Branch: `main`
- Main file path: `streamlit_app.py`

Choose **Deploy**. Community Cloud installs packages from `requirements.txt` and gives the app a `*.streamlit.app` URL. Commits pushed to `main` are published automatically. No API keys or secrets are needed for this starter page.

## Current state

This is the deployment-ready app shell. The playable rooms, fuse puzzle, gifts, attic, and Santa Scare sequence still need to be implemented. The first version is intended for three-player local co-op on one shared screen; it does not synchronize separate devices.

## Files

- `streamlit_app.py` - Streamlit entry point and current placeholder screen.
- `requirements.txt` - Python packages installed by the host.
- `.streamlit/config.toml` - visual defaults for the Streamlit page.

