# Demo WSL Chrome-DevTools Agent

This is a Proof of Concept (POC) project to demonstrate how to run Chrome DevTools MCP (Multi-Client Proxy) inside WSL2 (Windows Subsystem for Linux 2) and connect it to a Chrome instance running on Windows. This setup enables seamless debugging and automation of Chrome tasks across environments.

## Table of Contents

1. [Introduction](#demo-wsl-chrome-devtools-agent)
2. [Environment Variables](#environment-variables)
3. [Clone this Repository](#clone-this-repository)
4. [Dependencies](#dependencies)
   - [Node Dependencies](#node-dependencies)
   - [Python Dependencies](#python-dependencies)
5. [WSL and Chrome DevTools](#wsl-and-chrome-devtools)
   - [WSL2 Configuration for Chrome DevTools MCP](#wsl2-configuration-for-chrome-devtools-mcp)
   - [Chrome DevTools MCP Configuration](#chrome-devtools-mcp-configuration)
6. [Contributing](#contributing)
7. [License](#license)

## Environment Variables

Create a Groq account to get your API key at [Groq API Keys](https://console.groq.com/keys). It's free and no credit card is required.

## Clone this Repository

Run the following commands in your WSL terminal:

```bash
# Clone the repository
git clone https://github.com/bispo/demo-chrome-devtools-agent-into-wsl.git
cd demo-chrome-devtools-agent-into-wsl/

# Create a `.env` file in the project root with the following content:
echo "LOG_LEVEL=DEBUG" > .env
echo "GROQ_API_KEY=your_key" >> .env

# Run the setup script
./run.sh
```

## Dependencies

The script `run.sh` will check and install all dependencies needed to run this project. However, you can install them manually if you prefer.

### Node Dependencies

Run the following commands in your WSL2 terminal:

```bash
# Install Volta
curl https://get.volta.sh | bash

# Install Node.js
volta install node@22.20.0

# Verify Node.js installation
node -v
v22.20.0

# Install chrome-devtools-mcp globally
npm install -g chrome-devtools-mcp@latest
```

### Python Dependencies

This project requires a Python environment because it uses the Agno framework to create the agent that will perform tasks using Chrome.

Run the following commands in your WSL2 terminal:

```bash
# Install Astral UV tool
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Navigate to the project folder and synchronize dependencies:

```bash
cd ~/demo-chrome-devtools-agent-into-wsl/  # Go to the project folder
uv sync
```

## WSL and Chrome DevTools

You need to configure WSL2 and Chrome DevTools MCP to work together.

### WSL2 Configuration for Chrome DevTools MCP

Ensure mirrored networking is enabled in WSL2. Check if the file `%USERPROFILE%\.wslconfig` exists; if it doesn't, create it. Example:

```bash
code %USERPROFILE%\.wslconfig
```

Example content:

```powershell
[wsl2]
networkingMode=mirrored
firewall=true
```

A complete example of `.wslconfig`:

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

Verify if Chrome DevTools MCP is working correctly. In the WSL2 terminal, run:

```bash
curl http://localhost:9222/json
```

Expected output:

```json
[
    {
        "description": "",
        "devtoolsFrontendUrl": "https://chrome-devtools-frontend.appspot.com/serve_rev/@d481d06001dcd27831133efb4ac647fb6dd76073/inspector.html?ws=localhost:9222/devtools/page/80A28DE7AD6E2233DFF8B88268ABBBD8",
        "id": "80A28DE7AD6E2233DFF8B88268ABBBD8",
        "title": "New Tab",
        "type": "page",
        "url": "chrome://newtab/",
        "webSocketDebuggerUrl": "ws://localhost:9222/devtools/page/80A28DE7AD6E2233DFF8B88268ABBBD8"
    }
]
```

Chrome DevTools MCP settings:

```json
{
  "chrome-devtools": {
    "command": "npx",
    "args": [
      "-y",
      "chrome-devtools-mcp@latest",
      "--browserUrl",
      "http://localhost:9222"
    ]
  }
}
```

## Contributing

Contributions are welcome! To contribute:

1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Commit your changes with clear messages.
4. Submit a pull request.

For major changes, please open an issue first to discuss what you would like to change.

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.
