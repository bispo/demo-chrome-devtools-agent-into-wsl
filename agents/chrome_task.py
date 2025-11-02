import asyncio
import os
import logging

from agno.agent import Agent
from agno.tools.mcp import MCPTools
from agno.models.groq import Groq
from dotenv import load_dotenv

# Detailed logger configuration
logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("chrome_task")

# Load environment variables from .env file
load_dotenv(".env")

use_model = Groq(
    id="openai/gpt-oss-20b", max_tokens=2048, api_key=os.getenv("GROQ_API_KEY")
)


async def run_agent(message: str) -> None:
    """Run the chrome devtools agent with the given message."""
    logger.debug("Starting run_agent with message: %s", message)

    # Initialize and connect to multiple MCP servers
    chrome_devtools_tools = MCPTools(
        command="npx -y chrome-devtools-mcp@latest --browserUrl http://localhost:9222"
    )
    logger.debug("Instantiated MCPTools, connecting...")
    await chrome_devtools_tools.connect()
    logger.debug("Connection to MCPTools established.")

    try:
        agent = Agent(
            instructions="Use Chrome DevTools to perform the required web interactions.",
            tools=[chrome_devtools_tools],
            model=use_model,
            markdown=True,
        )
        logger.debug("Agent initialized. Sending message for processing.")
        await agent.aprint_response(message, stream=True)
        logger.debug("Agent response printed.")
    except Exception as e:
        logger.exception("Error during agent execution: %s", e)
        raise
    finally:
        logger.debug("Closing connection to MCPTools.")
        await chrome_devtools_tools.close()
        logger.debug("Connection to MCPTools closed.")


# Example usage
if __name__ == "__main__":
    logger.debug("Running chrome_task.py as main script.")
    asyncio.run(
        run_agent(
            "Open www.geomk.com.br and find the phone number and the name of the CTO?"
        )
    )
