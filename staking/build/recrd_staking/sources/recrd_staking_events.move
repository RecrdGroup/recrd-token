module recrd_staking::recrd_staking_events;

use sui::event::emit;

// === Structs ===

public struct Event<T: copy + drop>(T) has copy, drop;

public struct NewAccount has copy, drop {
    account: address,
    owner: address,
}

public struct Stake has copy, drop {
    amount: u64,
    account: address,
    owner: address,
    staked: u64,
}

public struct Unstake has copy, drop {
    amount: u64,
    account: address,
    owner: address,
    staked: u64,
}

// === Package Only Functions ===

public(package) fun new_account(account: address, owner: address) {
    emit(Event(NewAccount { account, owner }));
}

public(package) fun stake(amount: u64, account: address, owner: address, staked: u64) {
    emit(Event(Stake { amount, account, owner, staked }));
}

public(package) fun unstake(amount: u64, account: address, owner: address, staked: u64) {
    emit(Event(Unstake { amount, account, owner, staked }));
}

// === Test Only Functions ===

#[test_only]
public fun new_account_event(account: address, owner: address): Event<NewAccount> {
    Event(NewAccount { account, owner })
}

#[test_only]
public fun stake_event(amount: u64, account: address, owner: address, staked: u64): Event<Stake> {
    Event(Stake { amount, account, owner, staked })
}

#[test_only]
public fun unstake_event(
    amount: u64,
    account: address,
    owner: address,
    staked: u64,
): Event<Unstake> {
    Event(Unstake { amount, account, owner, staked })
}
