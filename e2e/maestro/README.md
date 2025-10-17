# Maestro E2E Tests

## Maestro MCP Setup

### What is Maestro MCP?
Maestro MCP (Model Context Protocol) exposes Maestro device and automation commands as MCP tools over STDIO for LLM agents and automation clients.

### Starting the MCP Server

You can start the Maestro MCP server using:

```bash
npm run mcp
```

Or directly:

```bash
maestro mcp
```

### Configuring MCP in Your IDE

To use Maestro MCP with your IDE or AI assistant, add the following configuration to your MCP settings:

```json
{
  "mcpServers": {
    "maestro": {
      "command": "maestro",
      "args": ["mcp"],
      "cwd": "/Users/lucian.cernauteanuthinslices.com/Documents/Repos/Ivory_Clone/Ivory/e2e/maestro"
    }
  }
}
```

For Windsurf or other IDEs, you may need to add this to your IDE's MCP configuration file.

### Running Tests

Run your Maestro tests with environment variables:

```bash
maestro test -e APP_ID=com.thinslices.solarisdemo -e EMAIL=lifebloom77@yahoo.com -e PASSWORD=TestPass1 login.yaml
```

Or using the environment file syntax:

```bash
maestro test login.yaml @.maestro.env.dev
```

### Environment Variables

Environment variables are defined in `.maestro.env.dev`:

- `APP_ID`: The bundle identifier of your app
- `EMAIL`: Test user email
- `PASSWORD`: Test user password

Note: When using the `@` syntax to load env files, the format should be:
```
-e APP_ID=com.thinslices.solarisdemo
-e EMAIL=lifebloom77@yahoo.com
-e PASSWORD=TestPass1
```
