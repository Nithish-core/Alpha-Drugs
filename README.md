# Alpha Drugs

An advanced drug production system for FiveM, featuring customizable drug labs, airdrops, and supplier NPCs.

## Features

- **Multiple Drug Types**: Weed, Meth, and Cocaine production systems
- **Customizable Labs**: Create and manage your own drug labs
- **Airdrop System**: Random airdrops with valuable loot
- **Supplier NPCs**: Purchase supplies from specialized dealers
- **Framework Support**: Compatible with ESX, QBCore, and standalone

## Installation

1. Download the latest release
2. Place the `alpha_drugs` folder in your server's `resources` directory
3. Add `ensure alpha_drugs` to your server.cfg
4. Configure the `config.lua` file to your liking

## Dependencies

- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_target](https://github.com/overextended/ox_target) or qb-target
- [ox_inventory](https://github.com/overextended/ox_inventory) or your preferred inventory
- oxmysql (for database operations)

## Configuration

### Lab Types

- **Weed Lab**: Grow and harvest weed plants
- **Meth Lab**: Cook meth with various chemicals
- **Cocaine Lab**: Process coca leaves into cocaine

### Store PEDs

Supplier NPCs are available to purchase necessary items:

| Location | Type | Items Available |
|----------|------|-----------------|
| City (380.0, -823.0) | Weed Supplier | Seeds, Fertilizer, Pots, Water |
| Lab (1000.0, -3200.0) | Meth Supplier | Chemicals and equipment |
| Lab (1090.0, -3190.0) | Cocaine Supplier | Ingredients and tools |

## Usage

### Creating a Lab
1. Obtain a lab item (e.g., `weed_lab`)
2. Use the item to place your lab
3. Gather required materials
4. Start production

### Airdrops
- Random airdrops occur periodically
- Check your map for drop locations
- Be the first to reach the drop for valuable loot

## Commands

- `/createdruglab [type]` - Create a drug lab (admin only)
- `/deletedruglab` - Remove the nearest drug lab (admin only)

## Support

For support, please open an issue on our [GitHub repository](https://github.com/yourusername/alpha_drugs). or contact at Alpha07 discord

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Credits

- Developed by [Alpha07]
- Special thanks to the FiveM community
