const { spawn } = require('child_process');
const readline = require('readline');

async function callMcpTool(toolName, args = {}) {
    return new Promise((resolve, reject) => {
        const proc = spawn('cmd', ['/c', 'npx', '-y', '@npgamedev/godot-mcp-server@1.1.0'], {
            env: {
                ...process.env,
                GODOT_MCP_CONFIG_VERSION: "1",
                npm_config_prefer_offline: "true"
            }
        });

        const rl = readline.createInterface({ input: proc.stdout });
        let idCounter = 1;

        proc.stderr.on('data', (d) => {
            const str = d.toString();
            // log bridge messages
            if (str.includes('[bridge]') || str.includes('[godot-mcp]')) {
                console.error(str.trim());
            }
        });

        rl.on('line', (line) => {
            try {
                const msg = JSON.parse(line);
                if (msg.id === 1) {
                    // Send initialized notification
                    proc.stdin.write(JSON.stringify({
                        jsonrpc: "2.0",
                        method: "notifications/initialized"
                    }) + '\n');

                    // Call the requested tool
                    proc.stdin.write(JSON.stringify({
                        jsonrpc: "2.0",
                        id: 2,
                        method: "tools/call",
                        params: {
                            name: toolName,
                            arguments: args
                        }
                    }) + '\n');
                } else if (msg.id === 2) {
                    proc.stdin.end();
                    resolve(msg.result);
                }
            } catch (e) {
                // Ignore non-json lines
            }
        });

        proc.on('error', reject);
        proc.on('close', () => {
            // proc closed
        });

        // Send initialize
        proc.stdin.write(JSON.stringify({
            jsonrpc: "2.0",
            id: 1,
            method: "initialize",
            params: {
                protocolVersion: "2024-11-05",
                capabilities: {},
                clientInfo: { name: "antigravity-test", version: "1.0" }
            }
        }) + '\n');
    });
}

// Run with args from command line: node mcp_client.js <toolName> <jsonArgs>
const toolName = process.argv[2] || "scene_get_tree";
const toolArgs = process.argv[3] ? JSON.parse(process.argv[3]) : {};

callMcpTool(toolName, toolArgs).then(result => {
    console.log(JSON.stringify(result, null, 2));
    process.exit(0);
}).catch(err => {
    console.error("Error:", err);
    process.exit(1);
});

