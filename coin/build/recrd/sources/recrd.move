/// @notice The UpgradeCap will be burnt to make this contract immutable.
module recrd::recrd;

use sui::{coin_registry::CoinRegistry, package};

// === Constants ===

const TOTAL_SUPPLY: u64 = 1_000_000_000__000_000;

const DECIMALS: u8 = 6;

const SYMBOL: vector<u8> = b"RECRD";

const NAME: vector<u8> = b"Recrd";

// === Structs ===

public struct RECRD() has drop;

public struct Recrd has key {
    id: UID,
}

// === Initializer ===

fun init(otw: RECRD, ctx: &mut TxContext) {
    let publisher = package::claim(otw, ctx);

    transfer::public_transfer(publisher, @multisig);

    let recrd = Recrd {
        id: object::new(ctx),
    };

    transfer::share_object(recrd);
}

// === Create Recrd Coin ===

public fun new(recrd: Recrd, coin_registry: &mut CoinRegistry, ctx: &mut TxContext) {
    let (mut current_initializer, mut treasury_cap) = coin_registry.new_currency<Recrd>(
        DECIMALS,
        SYMBOL.to_string(),
        NAME.to_string(),
        b"".to_string(),
        b"".to_string(),
        ctx,
    );

    treasury_cap.mint_and_transfer(TOTAL_SUPPLY, @multisig, ctx);

    current_initializer.make_supply_fixed(treasury_cap);

    let metadata_cap = current_initializer.finalize(ctx);

    transfer::public_transfer(metadata_cap, @multisig);

    let Recrd { id } = recrd;

    id.delete();
}

// === Test Only Functions ===

#[test_only]
public fun init_for_test(ctx: &mut TxContext) {
    init(RECRD(), ctx);
}

#[test_only]
public fun decimals(): u8 {
    DECIMALS
}

#[test_only]
public fun symbol(): vector<u8> {
    SYMBOL
}

#[test_only]
public fun name(): vector<u8> {
    NAME
}

#[test_only]
public fun total_supply(): u64 {
    TOTAL_SUPPLY
}
