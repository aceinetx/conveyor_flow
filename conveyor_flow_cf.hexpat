import std.io;

enum ConveyorDirection : u8 {
    up = 0,
    down,
    left,
    right,
};

enum TileType : u8 {
    stone,
    conveyor,
    miner,
    collector,
};

struct Item {
    le u8 count;
    le u8 kind;
};

struct Tile {
    le s64 x, y;
    le TileType id;
    
    if(id == 0x01){
        le ConveyorDirection direction;
        le bool has_item;
        if(has_item){
            Item item;
        }
        le float move_progress;
    } else if(id == 0x02){
        le float base_cooldown;
        le float cooldown;
    }
};

struct File {
    le u32 tile_count;
    le Tile tiles[tile_count];
};

File file @ 0x00;