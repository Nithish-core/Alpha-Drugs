fx_version 'cerulean'
game 'gta5'

author 'Nithish'
description 'Advanced Drug Lab System for FiveM'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/*.lua'
}

client_scripts {
    'client/main.lua',
    'client/airdrop.lua',
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/airdrop.lua',
    'server/*.lua',
    'server/labs/*.lua'
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'

dependencies {
    'ox_lib',
    'ox_inventory',
    'ox_target',
    'oxmysql'
}
