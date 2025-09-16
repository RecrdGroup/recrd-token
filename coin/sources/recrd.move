/// @notice The UpgradeCap will be burnt to make this contract immutable to ensure that Recrd coin can never be minted or burnt.
module recrd::recrd;

use std::{ascii, string};
use sui::{coin::{Self, CoinMetadata, TreasuryCap}, dynamic_object_field as dof};

// === Constants ===

const TOTAL_SUPPLY: u64 = 1_000_000_000__000_000;

const DECIMALS: u8 = 6;

const SYMBOL: vector<u8> = b"RECRD";

const NAME: vector<u8> = b"Recrd";

// === Structs ===

public struct RECRD() has drop;

public struct RecrdAdmin has key, store {
    id: UID,
}

public struct Key() has copy, drop, store;

public struct RecrdTreasury has key {
    id: UID,
}

// === Initializer ===

fun init(otw: RECRD, ctx: &mut TxContext) {
    let (mut treasury_cap, coin_metadata) = coin::create_currency(
        otw,
        DECIMALS,
        SYMBOL,
        NAME,
        b"",
        option::none(),
        ctx,
    );

    treasury_cap.mint_and_transfer(TOTAL_SUPPLY, @multisig, ctx);

    let mut recrd_treasury = RecrdTreasury {
        id: object::new(ctx),
    };

    dof::add(&mut recrd_treasury.id, Key(), treasury_cap);

    let recrd_admin = RecrdAdmin {
        id: object::new(ctx),
    };

    transfer::public_transfer(recrd_admin, @multisig);
    transfer::share_object(recrd_treasury);
    transfer::public_share_object(coin_metadata);
}

// === View Functions ===

public fun total_supply(self: &RecrdTreasury): u64 {
    self.treasury_cap().total_supply()
}

// === Admin Only Functions ===

/// Update name of the coin in `CoinMetadata`
public fun update_name(
    self: &RecrdTreasury,
    metadata: &mut CoinMetadata<RECRD>,
    _: &RecrdAdmin,
    name: string::String,
) {
    self.treasury_cap().update_name(metadata, name);
}

/// Update the symbol of the coin in `CoinMetadata`
public fun update_symbol(
    self: &RecrdTreasury,
    metadata: &mut CoinMetadata<RECRD>,
    _: &RecrdAdmin,
    symbol: ascii::String,
) {
    self.treasury_cap().update_symbol(metadata, symbol);
}

/// Update the description of the coin in `CoinMetadata`
public fun update_description(
    self: &RecrdTreasury,
    metadata: &mut CoinMetadata<RECRD>,
    _: &RecrdAdmin,
    description: string::String,
) {
    self.treasury_cap().update_description(metadata, description);
}

/// Update the url of the coin in `CoinMetadata`
public fun update_icon_url(
    self: &RecrdTreasury,
    metadata: &mut CoinMetadata<RECRD>,
    _: &RecrdAdmin,
    url: ascii::String,
) {
    self.treasury_cap().update_icon_url(metadata, url);
}

// === Private Function ===

fun treasury_cap(self: &RecrdTreasury): &TreasuryCap<RECRD> {
    dof::borrow(&self.id, Key())
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
public fun total_supply_for_test(): u64 {
    TOTAL_SUPPLY
}

#[test_only]
public fun treasury_cap_for_test(self: &RecrdTreasury): &TreasuryCap<RECRD> {
    self.treasury_cap()
}
