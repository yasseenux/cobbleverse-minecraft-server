# Cobbleverse Minecraft Server

A Dockerized Minecraft server running the Cobbleverse modpack v1.5.2 with Fabric 1.21.1, optimized for deployment on Railway.

## Features

- **Cobbleverse 1.5.2**: Complete Pokemon adventure modpack with Cobblemon
- **Fabric 1.21.1**: Latest stable Minecraft with Fabric mod loader
- **Railway Optimized**: Configured for seamless deployment on Railway
- **Auto-updating**: Automatically downloads and sets up the modpack
- **Performance Tuned**: Optimized JVM flags for better server performance

## Quick Deploy to Railway

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/template/cobbleverse-minecraft)

## Manual Deployment

### Prerequisites

- Docker installed on your system
- At least 4GB of available RAM
- Internet connection for downloading modpack and dependencies

### Local Development

1. Clone this repository:
```bash
git clone <your-repo-url>
cd cobbleverse-server
```

2. Build and run with Docker Compose:
```bash
docker-compose up --build
```

3. The server will be available on `localhost:25565`

### Railway Deployment

1. Fork this repository to your GitHub account

2. Connect your GitHub repository to Railway:
   - Go to [Railway](https://railway.app)
   - Click "New Project"
   - Select "Deploy from GitHub repo"
   - Choose your forked repository

3. Configure environment variables in Railway:
   - `PORT`: `25565` (automatically set by Railway)
   - `MAX_PLAYERS`: `20` (adjust as needed)
   - `ONLINE_MODE`: `true` (set to `false` for offline mode)
   - `MIN_RAM`: `2G`
   - `MAX_RAM`: `4G` (adjust based on your Railway plan)

4. Railway will automatically build and deploy your server

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `25565` | Server port (set by Railway) |
| `MAX_PLAYERS` | `20` | Maximum number of players |
| `ONLINE_MODE` | `true` | Enable Mojang authentication |
| `MIN_RAM` | `2G` | Minimum RAM allocation |
| `MAX_RAM` | `4G` | Maximum RAM allocation |
| `WORLD_SEED` | _(empty)_ | World generation seed |

## Resource Requirements

### Minimum Requirements
- **RAM**: 2GB
- **CPU**: 1 vCPU
- **Storage**: 2GB

### Recommended for 10+ Players
- **RAM**: 4-6GB
- **CPU**: 2 vCPU
- **Storage**: 5GB

## Modpack Information

**Cobbleverse v1.5.2** includes:
- **1015+ Real Pokémon**: All Legendary and Mythical included
- **Gym Leaders & Badges**: Complete Pokemon adventure experience
- **Custom Structures**: Unique Pokemon-themed buildings and areas
- **Optimized Performance**: Carefully selected mods for smooth gameplay
- **Shaders Support**: Beautiful graphics with Complementary Shaders

### Key Mods Included
- Cobblemon (core Pokemon mod)
- Terralith (world generation)
- Sodium & Iris (performance & shaders)
- Waystones (fast travel)
- And many more Pokemon-themed additions!

## Server Management

### Accessing Server Console
If deploying locally with Docker:
```bash
docker-compose logs -f cobbleverse-server
```

### Server Commands
Connect to your server and use standard Minecraft commands:
- `/op <username>` - Give operator permissions
- `/gamemode creative <username>` - Set creative mode
- `/weather clear` - Clear weather
- `/time set day` - Set time to day

### Cobblemon Specific Commands
- `/pokemonedit` - Edit Pokemon properties (OP only)
- `/pokegive <player> <pokemon>` - Give Pokemon to player
- `/pokebattlestats` - View battle statistics

## Troubleshooting

### Server Won't Start
1. Check RAM allocation in environment variables
2. Ensure Railway has enough resources allocated
3. Check build logs for dependency issues

### Connection Issues
1. Verify server is running (check Railway logs)
2. Ensure `ONLINE_MODE` is set correctly
3. Check if Railway port is properly exposed

### Performance Issues
1. Increase `MAX_RAM` environment variable
2. Reduce `MAX_PLAYERS` if needed
3. Consider upgrading Railway plan for more resources

## File Structure

```
cobbleverse-server/
├── Dockerfile              # Multi-stage Docker build
├── docker-compose.yml      # Local development setup
├── railway.json           # Railway deployment config
├── README.md              # This file
└── .gitignore            # Git ignore rules
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally with Docker
5. Submit a pull request

## License

This project is provided as-is for educational and personal use. The Cobbleverse modpack and its constituent mods have their own licenses. Please respect the original creators' licensing terms.

## Credits

- **Cobbleverse Modpack**: Created by LUMYVERSE
- **Cobblemon**: The core Pokemon mod for Minecraft
- **Fabric**: Minecraft modding framework
- **Railway**: Cloud deployment platform

## Support

For issues with:
- **This Docker setup**: Open an issue in this repository
- **Cobbleverse modpack**: Visit [Cobbleverse on Modrinth](https://modrinth.com/modpack/cobbleverse)
- **Railway deployment**: Check [Railway documentation](https://docs.railway.app)

---

**Note**: This is not affiliated with Mojang Studios, Nintendo, or The Pokémon Company. Minecraft and Pokémon are trademarks of their respective owners.
