# Demo WSL Chrome-DevTools Agent

This is a POC (proof of concept) project to demonstrate how to run Chrome DevTools MCP (Multi-Client Proxy) inside WSL2 (Windows Subsystem for Linux 2) and connect it to a Chrome instance running on Windows.

## Environment Variables

Create a groq account to get your API key at https://console.groq.com/keys, it's free and no credit card is required.

## Clone this repository

Run in your WSL terminal:
```bash
git clone https://github.com/bispo/demo-chrome-devtools-agent-into-wsl.git
cd demo-chrome-devtools-agent-into-wsl/
# Create a `.env` in the project root with the following content:
echo "LOG_LEVEL=DEBUG" > .env
echo "GROQ_API_KEY=your_key" >> .env
./run.sh
```

## Dependencies

The script `run.sh` will check and install all dependencies needed to run this project. But you can install them manually if you prefer.

### Node dependencies

This project need node.js and npm to run chrome-devtools-mcp@latest installed in WSL2, only the chrome browser will run in Windows.

run in WSL2 terminal:

```bash
# install Volta
curl https://get.volta.sh | bash

# install Node
volta install node@22.20.0

# start using Node
node -v
v22.20.0

# install chrome-devtools-mcp globally
npm install -g chrome-devtools-mcp@latest
```

### python dependencies

This project needs a Python environment because it uses the Agno framework to create the agent that will perform the task using Chrome.

run in WSL2 terminal:

```bash
# install astral uv tool
curl -LsSf https://astral.sh/uv/install.sh | sh
```

on project folder, run:

```bash
cd ~/demo-chrome-devtools-agent-into-wsl/  # go to project folder
uv sync
```

## WSL and Chrome DevTools

you need to configure WSL2 and Chrome DevTools MCP to work together.

### WSL2 Configuration for Chrome DevTools MCP
Requires mirrored networking in WSL2.

Check if the file `%USERPROFILE%\.wslconfig` exists; if it doesn't, create it. Example:

```bash
code %USERPROFILE%\.wslconfig
```

Example content:
```powershell
C:\Users\Bispo>type .wslconfig
[wsl2]
networkingMode=mirrored
firewall=true
```

My complete file .wslconfig (example):
```toml
[wsl2]
networkingMode=mirrored
firewall=true
memory=12GB
swapFile=D:/wsl/swap
debugConsole=true
processors=8
```

### Chrome DevTools MCP Configuration
Start a Chrome service listening on port 9222. Run the following in Command Prompt (CMD):

```powershell
"C:\Program Files\Google\Chrome\Application\chrome.exe" --remote-debugging-port=9222 --user-data-dir=%TEMP%\chrome-debug --no-first-run --no-default-browser-check --disable-extensions
```

Check if Chrome DevTools MCP is working correctly.
In the WSL2 terminal, run:
```bash
curl http://localhost:9222/json
[
    {
        "description": "",
        "devtoolsFrontendUrl": "https://chrome-devtools-frontend.appspot.com/serve_rev/@d481d06001dcd27831133efb4ac647fb6dd76073/inspector.html?ws=localhost:9222/devtools/page/80A28DE7AD6E2233DFF8B88268ABBBD8",
        "id": "80A28DE7AD6E2233DFF8B88268ABBBD8",
        "title": "New Tab",
        "type": "page",
        "url": "chrome://newtab/",
        "webSocketDebuggerUrl": "ws://localhost:9222/devtools/page/80A28DE7AD6E2233DFF8B88268ABBBD8"
    },
    ...
]
```

Chrome DevTools MCP settings:
```json
    "chrome-devtools": {
      "command": "npx",
      "args": [
        "-y",
        "chrome-devtools-mcp@latest",
        "--browserUrl",
        "http://localhost:9222"
      ]
    },
```
