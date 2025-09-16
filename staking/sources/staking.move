module recrd_staking::recrd_staking;

use recrd::recrd::RECRD;
use sui::{balance::{Self, Balance}, coin::Coin, display, package, table::{Self, Table}};

// === Structs ===

public struct RECRD_STAKING() has drop;

public struct RecrdStakingAccount has key {
    id: UID,
    owner: address,
    stake: Balance<RECRD>,
}

public struct RecrdStaking has key {
    id: UID,
    /// ctx.sender() -> RecrdStakingAccount.id.to_address()
    accounts: Table<address, address>,
}

// === Initializer ===

fun init(otw: RECRD_STAKING, ctx: &mut TxContext) {
    let recrd_staking = RecrdStaking {
        id: object::new(ctx),
        accounts: table::new(ctx),
    };

    let publisher = package::claim(otw, ctx);

    let display = display::new<RecrdStakingAccount>(&publisher, ctx);

    transfer::share_object(recrd_staking);
    transfer::public_transfer(display, @multisig);
    transfer::public_transfer(publisher, @multisig);
}

// === Public Mutative Functions ===

public fun new(
    staking: &mut RecrdStaking,
    owner: address,
    ctx: &mut TxContext,
): RecrdStakingAccount {
    assert!(
        !staking.accounts.contains(owner),
        recrd_staking::recrd_staking_errors::account_already_exists!(),
    );

    let account = RecrdStakingAccount {
        id: object::new(ctx),
        owner,
        stake: balance::zero(),
    };

    staking.accounts.add(owner, account.id.to_address());

    recrd_staking::recrd_staking_events::new_account(account.id.to_address(), owner);

    account
}

public fun transfer_to_owner(account: RecrdStakingAccount) {
    let owner = account.owner;

    transfer::transfer(account, owner);
}

public fun stake(account: &mut RecrdStakingAccount, stake: Coin<RECRD>, _ctx: &mut TxContext) {
    let stake_value = stake.value();

    assert!(stake_value != 0, recrd_staking::recrd_staking_errors::zero_stake!());

    account.stake.join(stake.into_balance());

    recrd_staking::recrd_staking_events::stake(
        stake_value,
        account.id.to_address(),
        account.owner,
        account.stake.value(),
    );
}

public fun unstake(
    account: &mut RecrdStakingAccount,
    amount: u64,
    ctx: &mut TxContext,
): Coin<RECRD> {
    assert!(
        account.stake.value() >= amount && amount != 0,
        recrd_staking::recrd_staking_errors::invalid_unstake!(),
    );

    let unstake = account.stake.split(amount).into_coin(ctx);

    recrd_staking::recrd_staking_events::unstake(
        amount,
        account.id.to_address(),
        account.owner,
        account.stake.value(),
    );

    unstake
}

// === View Functions ===

public fun staking_account_of(staking: &RecrdStaking, owner: address): Option<address> {
    if (staking.accounts.contains(owner)) {
        option::some(staking.accounts[owner])
    } else {
        option::none()
    }
}

// === Test Only Functions ===

#[test_only]
public fun init_for_test(ctx: &mut TxContext) {
    init(RECRD_STAKING(), ctx);
}

#[test_only]
public fun owner(account: &RecrdStakingAccount): address {
    account.owner
}

#[test_only]
public fun stake_amount(account: &RecrdStakingAccount): u64 {
    account.stake.value()
}
